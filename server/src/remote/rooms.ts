import { randomBytes } from 'node:crypto';
import { KEY_ALPHABET } from '../license/keyformat.js';
import { nowSec } from '../util.js';
import type { AuthedDevice } from './auth.js';
import {
  ALLOWED_BY_ROLE,
  CloseCode,
  DEFAULT_MAX_CLIENTS,
  HOST_PEER_ID,
  HOST_TO_REQUIRED,
  MAX_CONSECUTIVE_DROPS,
  PAIRING_CODE_LEN,
  PAIRING_TTL_SEC,
  PeerMessageSchema,
  RATE_APPS,
  RATE_INPUT,
  RATE_SIGNAL,
  issuesToMessage,
  rateClassOf,
  type ByeReason,
  type ErrorCode,
  type PeerDescriptor,
  type PeerLeftReason,
  type PeerMessage,
  type PeerRole,
  type ServerMessage,
} from './protocol.js';

/** Transport abstraction so the room logic is testable without a real WebSocket. */
export interface PeerSocket {
  send(data: string): void;
  close(code: number, reason: string): void;
}

class Bucket {
  private tokens: number;
  private updated: number;
  constructor(
    private readonly capacity: number,
    private readonly refillPerSec: number,
    private readonly clock: () => number,
  ) {
    this.tokens = capacity;
    this.updated = clock();
  }
  take(): boolean {
    const now = this.clock();
    this.tokens = Math.min(this.capacity, this.tokens + (now - this.updated) * this.refillPerSec);
    this.updated = now;
    if (this.tokens < 1) return false;
    this.tokens -= 1;
    return true;
  }
}

export interface Peer {
  peerId: string;
  role: PeerRole;
  device: AuthedDevice;
  name: string | null;
  platform: string | null;
  socket: PeerSocket;
  room: Room;
  joinedAt: number;
  /** @internal */
  buckets: { signal: Bucket; apps: Bucket; input: Bucket };
  /** @internal */
  drops: number;
  /** @internal */
  detached: boolean;
}

export interface Room {
  id: string;
  hostDeviceId: string;
  hostHash: string;
  hostLicenseId: string;
  host: Peer | null;
  clients: Map<string, Peer>;
  createdAt: number;
  closed: boolean;
  /** Outstanding (unused, unexpired) pairing codes for this room. */
  codes: Set<string>;
}

interface Pairing {
  code: string;
  roomId: string;
  createdAt: number;
  expiresAt: number;
  used: boolean;
}

export interface RoomsOptions {
  clock?: () => number;
  maxClients?: number;
  pairingTtlSec?: number;
  /** Upper bound on rooms held in memory (pending + live). */
  maxRooms?: number;
}

export type JoinFailure = Extract<ErrorCode, 'not_found' | 'code_used' | 'code_expired' | 'host_offline' | 'room_full' | 'device_mismatch'>;

export class JoinError extends Error {
  constructor(
    public readonly code: JoinFailure,
    message: string,
    public readonly closeCode: number,
  ) {
    super(message);
    this.name = 'JoinError';
  }
}

function randomCode(): string {
  // Rejection sampling keeps the distribution uniform over the 32-symbol alphabet (256 % 32 === 0, so plain modulo is fine too).
  const bytes = randomBytes(PAIRING_CODE_LEN);
  let s = '';
  for (let i = 0; i < PAIRING_CODE_LEN; i++) s += KEY_ALPHABET[bytes[i]! % KEY_ALPHABET.length];
  return s;
}

export function newPeerId(): string {
  return `p_${randomBytes(6).toString('base64url')}`;
}

function safeSend(peer: Peer, msg: ServerMessage): void {
  try {
    peer.socket.send(JSON.stringify(msg));
  } catch {
    // The transport is gone; the close handler will detach the peer.
  }
}

function safeClose(peer: Peer, code: number, reason: string): void {
  try {
    peer.socket.close(code, reason);
  } catch {
    // ignore
  }
}

/**
 * In-memory registry of rooms, pairings and peers. One room per host device; rooms die with
 * their host. Single-node by design (signaling state is ephemeral); put a sticky load balancer
 * in front for horizontal scale.
 */
export class RoomRegistry {
  private readonly rooms = new Map<string, Room>();
  private readonly byHostDevice = new Map<string, Room>();
  private readonly byHostHash = new Map<string, Room>();
  private readonly pairings = new Map<string, Pairing>();
  private readonly clock: () => number;
  readonly maxClients: number;
  readonly pairingTtlSec: number;
  private readonly maxRooms: number;

  constructor(opts: RoomsOptions = {}) {
    this.clock = opts.clock ?? nowSec;
    this.maxClients = opts.maxClients ?? DEFAULT_MAX_CLIENTS;
    this.pairingTtlSec = opts.pairingTtlSec ?? PAIRING_TTL_SEC;
    this.maxRooms = opts.maxRooms ?? 10_000;
  }

  // ---------- pairing ----------

  /** Creates (or reuses) the host device's room and mints a fresh single-use code for it. */
  createPairing(host: AuthedDevice): { code: string; room: Room; expiresAt: number } {
    this.sweep();
    let room = this.byHostDevice.get(host.deviceId);
    if (!room) {
      if (this.rooms.size >= this.maxRooms) throw new JoinError('room_full', 'server is at capacity, try again later', CloseCode.RATE_LIMITED);
      room = {
        id: `room_${randomBytes(12).toString('base64url')}`,
        hostDeviceId: host.deviceId,
        hostHash: host.deviceHash,
        hostLicenseId: host.licenseId,
        host: null,
        clients: new Map(),
        createdAt: this.clock(),
        closed: false,
        codes: new Set(),
      };
      this.rooms.set(room.id, room);
      this.byHostDevice.set(host.deviceId, room);
      this.byHostHash.set(host.deviceHash, room);
    }
    let code = randomCode();
    while (this.pairings.has(code)) code = randomCode();
    const now = this.clock();
    const pairing: Pairing = { code, roomId: room.id, createdAt: now, expiresAt: now + this.pairingTtlSec, used: false };
    this.pairings.set(code, pairing);
    room.codes.add(code);
    return { code, room, expiresAt: pairing.expiresAt };
  }

  getRoom(roomId: string): Room | undefined {
    const r = this.rooms.get(roomId);
    return r && !r.closed ? r : undefined;
  }

  roomForHostHash(hostHash: string): Room | undefined {
    const r = this.byHostHash.get(hostHash);
    return r && !r.closed ? r : undefined;
  }

  /** Drops expired pairings and pending rooms nobody can join any more. */
  sweep(): void {
    const now = this.clock();
    for (const [code, p] of this.pairings) {
      // Used codes stay until they expire so a replay is answered with `code_used`, not `not_found`.
      if (p.expiresAt <= now) {
        this.pairings.delete(code);
        const room = this.rooms.get(p.roomId);
        if (room) {
          room.codes.delete(code);
          if (!room.host && room.codes.size === 0) this.forget(room);
        }
      }
    }
  }

  // ---------- attach / detach ----------

  /**
   * Attaches the host connection to its room. The token's device must own the room. A newer host
   * connection replaces an older one (stale socket after a network blip).
   */
  attachHost(roomId: string, device: AuthedDevice, socket: PeerSocket, name: string | undefined): Peer {
    const room = this.getRoom(roomId);
    if (!room) throw new JoinError('not_found', 'room not found or already closed; create a new pairing', CloseCode.NOT_FOUND);
    if (room.hostDeviceId !== device.deviceId) throw new JoinError('device_mismatch', 'this room belongs to a different device', CloseCode.FORBIDDEN);
    const peer = this.makePeer(HOST_PEER_ID, 'host', device, socket, room, name);
    const old = room.host;
    room.host = peer;
    if (old) {
      old.detached = true;
      safeSend(old, { t: 'bye', reason: 'replaced' });
      safeClose(old, CloseCode.CONFLICT, 'replaced');
    }
    return peer;
  }

  /** Atomically redeems a pairing code and attaches the client. The code is consumed only on success. */
  joinWithCode(code: string, device: AuthedDevice, socket: PeerSocket, name: string | undefined): Peer {
    const pairing = this.pairings.get(code);
    if (!pairing) throw new JoinError('not_found', 'unknown pairing code', CloseCode.NOT_FOUND);
    if (pairing.used) throw new JoinError('code_used', 'this pairing code was already used', CloseCode.CONFLICT);
    if (pairing.expiresAt <= this.clock()) {
      this.pairings.delete(code);
      throw new JoinError('code_expired', 'this pairing code has expired; ask the Mac for a new one', CloseCode.EXPIRED);
    }
    const room = this.getRoom(pairing.roomId);
    if (!room || !room.host) throw new JoinError('host_offline', 'the Mac is not connected', CloseCode.NOT_FOUND);
    if (room.clients.size >= this.maxClients) throw new JoinError('room_full', `room is full (${this.maxClients} devices)`, CloseCode.FORBIDDEN);
    pairing.used = true; // consumed atomically: no await between the checks above and this line
    room.codes.delete(code);
    return this.attachClient(room, device, socket, name);
  }

  /** Attaches a client that presents a verified grant for `hostHash`. */
  joinWithGrant(hostHash: string, device: AuthedDevice, socket: PeerSocket, name: string | undefined): Peer {
    const room = this.roomForHostHash(hostHash);
    if (!room || !room.host) throw new JoinError('host_offline', 'the Mac is not connected', CloseCode.NOT_FOUND);
    if (room.clients.size >= this.maxClients) throw new JoinError('room_full', `room is full (${this.maxClients} devices)`, CloseCode.FORBIDDEN);
    return this.attachClient(room, device, socket, name);
  }

  private attachClient(room: Room, device: AuthedDevice, socket: PeerSocket, name: string | undefined): Peer {
    let id = newPeerId();
    while (room.clients.has(id)) id = newPeerId();
    const peer = this.makePeer(id, 'client', device, socket, room, name);
    room.clients.set(id, peer);
    if (room.host) safeSend(room.host, { t: 'peer-joined', peer: this.describe(peer, room.host) });
    return peer;
  }

  /** Called when a peer's transport closes (or after the registry closed it). Idempotent. */
  detach(peer: Peer, reason: PeerLeftReason): void {
    if (peer.detached) return;
    peer.detached = true;
    const room = peer.room;
    if (room.closed) return;
    if (peer.role === 'host') {
      if (room.host === peer) this.closeRoom(room, 'host_left');
      return;
    }
    if (room.clients.get(peer.peerId) === peer) {
      room.clients.delete(peer.peerId);
      if (room.host) safeSend(room.host, { t: 'peer-left', peer_id: peer.peerId, reason });
    }
  }

  /** Closes a room: every client gets `bye` + close 4410, outstanding codes are invalidated. */
  closeRoom(room: Room, reason: ByeReason): void {
    if (room.closed) return;
    room.closed = true;
    for (const client of room.clients.values()) {
      client.detached = true;
      safeSend(client, { t: 'bye', reason });
      safeClose(client, CloseCode.GONE, 'room_closed');
    }
    room.clients.clear();
    room.host = null;
    this.forget(room);
  }

  /** Server shutdown: tell everyone and close every socket. */
  closeAll(): void {
    for (const room of [...this.rooms.values()]) {
      const host = room.host;
      room.closed = true;
      for (const client of room.clients.values()) {
        client.detached = true;
        safeSend(client, { t: 'bye', reason: 'server_shutdown' });
        safeClose(client, CloseCode.SHUTDOWN, 'server_shutdown');
      }
      room.clients.clear();
      if (host) {
        host.detached = true;
        safeSend(host, { t: 'bye', reason: 'server_shutdown' });
        safeClose(host, CloseCode.SHUTDOWN, 'server_shutdown');
      }
      room.host = null;
      this.forget(room);
    }
  }

  private forget(room: Room): void {
    for (const code of room.codes) this.pairings.delete(code); // outstanding codes die with the room
    room.codes.clear();
    this.rooms.delete(room.id);
    if (this.byHostDevice.get(room.hostDeviceId) === room) this.byHostDevice.delete(room.hostDeviceId);
    if (this.byHostHash.get(room.hostHash) === room) this.byHostHash.delete(room.hostHash);
  }

  // ---------- messages ----------

  /** Validates and routes one inbound text frame from `peer`. Never throws. */
  handleMessage(peer: Peer, text: string): void {
    if (peer.detached) return;
    let raw: unknown;
    try {
      raw = JSON.parse(text);
    } catch {
      this.sendError(peer, 'validation', 'message is not valid JSON');
      return;
    }
    const ref = typeof raw === 'object' && raw !== null && typeof (raw as { ref?: unknown }).ref === 'string' ? ((raw as { ref: string }).ref).slice(0, 64) : undefined;
    const parsed = PeerMessageSchema.safeParse(raw);
    if (!parsed.success) {
      this.sendError(peer, 'validation', issuesToMessage(parsed.error.issues), ref);
      return;
    }
    const msg = parsed.data;
    if (!ALLOWED_BY_ROLE[peer.role].has(msg.t)) {
      this.sendError(peer, 'not_allowed', `${peer.role} may not send ${msg.t}`, msg.ref);
      return;
    }
    if (!peer.buckets[rateClassOf(msg.t)].take()) {
      peer.drops += 1;
      if (peer.drops >= MAX_CONSECUTIVE_DROPS) {
        this.kick(peer, 'rate_limited', CloseCode.RATE_LIMITED, 'rate_limited');
        return;
      }
      this.sendError(peer, 'rate_limited', `too many ${msg.t} messages`, msg.ref);
      return;
    }
    peer.drops = 0;
    if (peer.role === 'host') this.routeFromHost(peer, msg);
    else this.routeFromClient(peer, msg);
  }

  private routeFromClient(peer: Peer, msg: PeerMessage): void {
    const room = peer.room;
    if ('to' in msg && msg.to !== undefined && msg.to !== HOST_PEER_ID) {
      this.sendError(peer, 'not_allowed', 'clients can only address the host', msg.ref);
      return;
    }
    if (msg.t === 'bye') {
      peer.detached = true;
      room.clients.delete(peer.peerId);
      if (room.host) safeSend(room.host, { t: 'peer-left', peer_id: peer.peerId, reason: 'bye' });
      safeClose(peer, CloseCode.NORMAL, 'bye');
      return;
    }
    if (!room.host) {
      this.sendError(peer, 'host_offline', 'the Mac is not connected', msg.ref);
      return;
    }
    safeSend(room.host, this.relayed(peer, msg));
  }

  private routeFromHost(peer: Peer, msg: PeerMessage): void {
    const room = peer.room;
    const to = 'to' in msg ? msg.to : undefined;
    if (msg.t === 'bye') {
      if (to === undefined) {
        this.closeRoom(room, 'room_closed');
        peer.detached = true;
        safeClose(peer, CloseCode.NORMAL, 'bye');
        return;
      }
      const target = room.clients.get(to);
      if (!target) {
        this.sendError(peer, 'unknown_peer', `no client ${to}`, msg.ref);
        return;
      }
      this.kick(target, 'kicked', CloseCode.GONE, 'kicked');
      return;
    }
    if (to === undefined) {
      if (HOST_TO_REQUIRED.has(msg.t)) {
        this.sendError(peer, 'validation', `${msg.t} from the host requires "to"`, msg.ref);
        return;
      }
      // apps without `to` = broadcast
      const out = this.relayed(peer, msg);
      for (const client of room.clients.values()) safeSend(client, out);
      return;
    }
    const target = room.clients.get(to);
    if (!target) {
      this.sendError(peer, 'unknown_peer', `no client ${to}`, msg.ref);
      return;
    }
    safeSend(target, this.relayed(peer, msg));
  }

  /** Server-initiated removal of a client: `bye` to the client, `peer-left` to the host. */
  private kick(target: Peer, reason: Extract<PeerLeftReason, 'kicked' | 'rate_limited'>, closeCode: number, closeReason: string): void {
    const room = target.room;
    target.detached = true;
    room.clients.delete(target.peerId);
    safeSend(target, { t: 'bye', reason: 'kicked', from: HOST_PEER_ID });
    safeClose(target, closeCode, closeReason);
    if (room.host) safeSend(room.host, { t: 'peer-left', peer_id: target.peerId, reason });
  }

  private relayed(from: Peer, msg: PeerMessage): ServerMessage {
    const { to: _to, ...rest } = msg as PeerMessage & { to?: string };
    void _to;
    return { ...rest, from: from.peerId } as ServerMessage;
  }

  sendError(peer: Peer, code: ErrorCode, message: string, ref?: string): void {
    safeSend(peer, { t: 'error', code, message, ...(ref !== undefined ? { ref } : {}) });
  }

  // ---------- views ----------

  describe(peer: Peer, viewer: Peer): PeerDescriptor {
    return {
      peer_id: peer.peerId,
      role: peer.role,
      device_hash: peer.device.deviceHash,
      ...(peer.name ? { name: peer.name } : {}),
      ...(peer.platform ? { platform: peer.platform } : {}),
      same_license: peer.device.licenseId === viewer.device.licenseId,
    };
  }

  /** Peers visible to `peer` in its `hello`: the host sees its clients; a client sees the host. */
  peersVisibleTo(peer: Peer): PeerDescriptor[] {
    if (peer.role === 'host') return [...peer.room.clients.values()].map((c) => this.describe(c, peer));
    return peer.room.host ? [this.describe(peer.room.host, peer)] : [];
  }

  stats(): { rooms: number; live_rooms: number; clients: number; pending_codes: number } {
    let live = 0;
    let clients = 0;
    for (const r of this.rooms.values()) {
      if (r.host) live++;
      clients += r.clients.size;
    }
    const now = this.clock();
    let pending = 0;
    for (const p of this.pairings.values()) if (!p.used && p.expiresAt > now) pending++;
    return { rooms: this.rooms.size, live_rooms: live, clients, pending_codes: pending };
  }

  private makePeer(peerId: string, role: PeerRole, device: AuthedDevice, socket: PeerSocket, room: Room, name: string | undefined): Peer {
    const clock = () => Date.now() / 1000; // rate limiting is wall-clock even when the pairing clock is faked
    return {
      peerId,
      role,
      device,
      name: (name && name.trim()) || device.name,
      platform: device.platform,
      socket,
      room,
      joinedAt: this.clock(),
      buckets: {
        signal: new Bucket(RATE_SIGNAL[0], RATE_SIGNAL[1], clock),
        apps: new Bucket(RATE_APPS[0], RATE_APPS[1], clock),
        input: new Bucket(RATE_INPUT[0], RATE_INPUT[1], clock),
      },
      drops: 0,
      detached: false,
    };
  }
}
