import websocket from '@fastify/websocket';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { RawData, WebSocket } from 'ws';
import { z } from 'zod';
import { RateLimiter } from '../http/ratelimit.js';
import { HttpError, nowSec } from '../util.js';
import type { RemoteAuth } from './auth.js';
import type { IceService } from './ice.js';
import {
  CloseCode,
  CreatePairingSchema,
  MAX_MESSAGE_BYTES,
  PROTOCOL_VERSION,
  RATE_INPUT,
  RATE_SIGNAL,
  WsQuerySchema,
  formatPairingCode,
  issuesToMessage,
  normalizePairingCode,
  type ErrorCode,
  type HelloMessage,
} from './protocol.js';
import { JoinError, type Peer, type RoomRegistry } from './rooms.js';

export interface RemoteDeps {
  auth: RemoteAuth;
  rooms: RoomRegistry;
  ice: IceService;
  /** Public WebSocket URL advertised in pairing responses; derived from the request when unset. */
  wsUrl?: string;
  clock?: () => number;
  /** WebSocket keepalive interval; a peer that misses one pong is terminated. */
  pingIntervalMs?: number;
  /** Pairing/room sweep interval. */
  sweepIntervalMs?: number;
}

function clientIp(req: FastifyRequest): string {
  const xff = req.headers['x-forwarded-for'];
  if (typeof xff === 'string' && xff.length > 0) return xff.split(',')[0]!.trim();
  return req.ip;
}

function bearer(req: FastifyRequest): string | undefined {
  const h = req.headers.authorization;
  if (typeof h === 'string' && h.startsWith('Bearer ')) return h.slice(7).trim() || undefined;
  return undefined;
}

function parse<T>(schema: z.ZodType<T>, input: unknown): T {
  const r = schema.safeParse(input);
  if (!r.success) throw new HttpError(400, issuesToMessage(r.error.issues), 'validation');
  return r.data;
}

function rawToString(data: RawData): string {
  if (Buffer.isBuffer(data)) return data.toString('utf8');
  if (Array.isArray(data)) return Buffer.concat(data).toString('utf8');
  return Buffer.from(data).toString('utf8');
}

/** Counts failures per key inside a sliding window; brute-force guard for pairing codes. */
class FailureWindow {
  private readonly hits = new Map<string, number[]>();
  constructor(
    private readonly max: number,
    private readonly windowSec: number,
  ) {}
  private prune(key: string, now: number): number[] {
    const list = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowSec);
    if (list.length === 0) this.hits.delete(key);
    else this.hits.set(key, list);
    if (this.hits.size > 50_000) this.hits.clear(); // crude memory bound
    return list;
  }
  blocked(key: string, now: number): boolean {
    return this.prune(key, now).length >= this.max;
  }
  record(key: string, now: number): void {
    this.prune(key, now).push(now);
    if (!this.hits.has(key)) this.hits.set(key, [now]);
  }
}

function httpStatusToClose(status: number): number {
  switch (status) {
    case 400:
      return CloseCode.BAD_REQUEST;
    case 401:
      return CloseCode.UNAUTHORIZED;
    case 403:
      return CloseCode.FORBIDDEN;
    case 404:
      return CloseCode.NOT_FOUND;
    case 429:
      return CloseCode.RATE_LIMITED;
    default:
      return CloseCode.BAD_REQUEST;
  }
}

/** Sends one `error` message and closes the socket with a 4xxx code. */
function reject(socket: WebSocket, closeCode: number, code: ErrorCode | string, message: string): void {
  try {
    socket.send(JSON.stringify({ t: 'error', code, message }));
  } catch {
    // ignore
  }
  try {
    socket.close(closeCode, code.slice(0, 120));
  } catch {
    // ignore
  }
}

/**
 * Registers MIRRORZ Remote on a Fastify app:
 *   POST /v1/remote/pairings   create a pairing code (host)
 *   GET  /v1/remote/ice        STUN/TURN servers with time-limited credentials
 *   GET  /v1/remote/ws         signaling WebSocket (role=host|client)
 * See docs/spec/remote-protocol.md.
 */
export function registerRemote(app: FastifyInstance, deps: RemoteDeps): void {
  const clock = deps.clock ?? nowSec;
  const pairingPerDevice = new RateLimiter(10, 1 / 30); // 10 burst, one per 30 s sustained
  const pairingPerIp = new RateLimiter(30, 0.5);
  const handshakePerIp = new RateLimiter(20, 0.2); // 20 burst, 12 per minute
  const codeFailures = new FailureWindow(5, 600); // 5 failed redemptions per IP per 10 min
  const pingMs = deps.pingIntervalMs ?? 25_000;
  const awaitingPong = new WeakSet<WebSocket>();
  const timedOut = new WeakSet<WebSocket>();

  app.register(websocket, {
    options: { maxPayload: MAX_MESSAGE_BYTES },
    async preClose(this: FastifyInstance) {
      deps.rooms.closeAll();
      for (const s of this.websocketServer.clients) {
        try {
          s.close(CloseCode.SHUTDOWN, 'server_shutdown');
        } catch {
          // ignore
        }
      }
      await new Promise<void>((resolve) => this.websocketServer.close(() => resolve()));
    },
  });

  app.register(async (f) => {
    // ---------- pairing ----------
    f.post('/v1/remote/pairings', async (req, reply) => {
      if (!pairingPerIp.allow(clientIp(req))) throw new HttpError(429, 'too many pairing requests', 'rate_limited');
      const body = parse(CreatePairingSchema, req.body);
      const host = deps.auth.authenticate(body.token);
      if (!pairingPerDevice.allow(host.deviceId)) throw new HttpError(429, 'too many pairing requests for this device', 'rate_limited');
      const { code, room, expiresAt } = deps.rooms.createPairing(host);
      const wsUrl = deps.wsUrl ?? `${req.protocol === 'https' ? 'wss' : 'ws'}://${req.host}/v1/remote/ws`;
      return reply.status(201).send({
        code,
        display: formatPairingCode(code),
        room_id: room.id,
        host_hash: room.hostHash,
        expires_at: expiresAt,
        ws_url: wsUrl,
        deep_link: `mirrorz://pair?code=${code}&h=${room.hostHash}`,
      });
    });

    // ---------- ICE ----------
    f.get('/v1/remote/ice', async (req) => {
      const q = req.query as { auth?: string };
      deps.auth.authenticate(bearer(req) ?? q.auth);
      return deps.ice.servers();
    });

    // ---------- signaling ----------
    f.get('/v1/remote/ws', { websocket: true }, (socket, req) => {
      let peer: Peer | undefined;

      // Attach handlers synchronously (before any other work) so no frame is dropped.
      socket.on('message', (data: RawData, isBinary: boolean) => {
        if (!peer) return;
        if (isBinary) {
          reject(socket, CloseCode.BAD_REQUEST, 'validation', 'binary frames are not supported');
          return;
        }
        deps.rooms.handleMessage(peer, rawToString(data));
      });
      socket.on('close', () => {
        if (peer) deps.rooms.detach(peer, timedOut.has(socket) ? 'timeout' : 'closed');
      });
      socket.on('pong', () => awaitingPong.delete(socket));
      socket.on('error', () => {
        /* 'close' follows; nothing to do */
      });

      const ip = clientIp(req);
      if (!handshakePerIp.allow(ip)) {
        reject(socket, CloseCode.RATE_LIMITED, 'rate_limited', 'too many connections, slow down');
        return;
      }

      const qr = WsQuerySchema.safeParse(req.query ?? {});
      if (!qr.success) {
        reject(socket, CloseCode.BAD_REQUEST, 'validation', issuesToMessage(qr.error.issues));
        return;
      }
      const q = qr.data;
      if (q.v !== undefined && q.v !== PROTOCOL_VERSION) {
        reject(socket, CloseCode.BAD_REQUEST, 'validation', `unsupported protocol version ${q.v}`);
        return;
      }

      try {
        const device = deps.auth.authenticate(bearer(req) ?? q.auth);
        const transport = {
          send: (d: string) => {
            if (socket.readyState === socket.OPEN) socket.send(d);
          },
          close: (code: number, reason: string) => socket.close(code, reason),
        };

        if (q.role === 'host') {
          if (!q.room) {
            reject(socket, CloseCode.BAD_REQUEST, 'validation', 'room is required for role=host');
            return;
          }
          peer = deps.rooms.attachHost(q.room, device, transport, q.name);
        } else {
          if (!q.code && !q.grant) {
            reject(socket, CloseCode.BAD_REQUEST, 'validation', 'code or grant is required for role=client');
            return;
          }
          if (q.code) {
            const code = normalizePairingCode(q.code);
            if (!code) {
              reject(socket, CloseCode.BAD_REQUEST, 'validation', 'pairing code must be 6 symbols');
              return;
            }
            if (codeFailures.blocked(ip, clock())) {
              reject(socket, CloseCode.RATE_LIMITED, 'rate_limited', 'too many failed pairing attempts; wait a few minutes');
              return;
            }
            try {
              peer = deps.rooms.joinWithCode(code, device, transport, q.name);
            } catch (e) {
              if (e instanceof JoinError) codeFailures.record(ip, clock());
              throw e;
            }
          } else {
            const grant = deps.auth.verifyGrant(q.grant!, device);
            peer = deps.rooms.joinWithGrant(grant.host, device, transport, q.name);
          }
        }

        const room = peer.room;
        const hello: HelloMessage = {
          t: 'hello',
          v: PROTOCOL_VERSION,
          peer_id: peer.peerId,
          role: peer.role,
          room_id: room.id,
          host_hash: room.hostHash,
          self: deps.rooms.describe(peer, peer),
          peers: deps.rooms.peersVisibleTo(peer),
          ice_servers: deps.ice.servers().iceServers,
          limits: {
            max_message_bytes: MAX_MESSAGE_BYTES,
            signal_per_sec: RATE_SIGNAL[1],
            input_per_sec: RATE_INPUT[1],
            max_clients: deps.rooms.maxClients,
          },
        };
        if (peer.role === 'client') {
          const g = deps.auth.issueGrant(room.hostHash, device);
          hello.grant = g.grant;
          hello.limits.grant_expires_at = g.expiresAt;
        }
        socket.send(JSON.stringify(hello));
      } catch (e) {
        if (e instanceof JoinError) {
          reject(socket, e.closeCode, e.code, e.message);
        } else if (e instanceof HttpError) {
          reject(socket, httpStatusToClose(e.status), e.code, e.message);
        } else {
          req.log.error(e);
          reject(socket, CloseCode.BAD_REQUEST, 'internal', 'internal error');
        }
      }
    });
  });

  // ---------- keepalive + housekeeping ----------
  const pinger = setInterval(() => {
    const server = app.websocketServer;
    if (!server) return;
    for (const s of server.clients) {
      if (awaitingPong.has(s)) {
        timedOut.add(s);
        s.terminate();
        continue;
      }
      awaitingPong.add(s);
      try {
        s.ping();
      } catch {
        // ignore
      }
    }
  }, pingMs);
  pinger.unref();
  const sweeper = setInterval(() => deps.rooms.sweep(), deps.sweepIntervalMs ?? 30_000);
  sweeper.unref();
  app.addHook('onClose', async () => {
    clearInterval(pinger);
    clearInterval(sweeper);
  });
}
