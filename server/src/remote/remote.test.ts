import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import WebSocket from 'ws';
import { ConsoleMailer } from '../billing/mailer.js';
import { StripeBilling } from '../billing/stripe.js';
import { CompatService } from '../compat/service.js';
import { buildApp } from '../http/app.js';
import { KEY_ALPHABET } from '../license/keyformat.js';
import { makeEnv, type TestEnv } from '../test/helpers.js';
import { RemoteAuth, deviceHash } from './auth.js';
import { IceService, iceConfigFromEnv, turnRestCredential } from './ice.js';
import { InputEventSchema, PeerMessageSchema, formatPairingCode, normalizePairingCode } from './protocol.js';
import { RoomRegistry } from './rooms.js';
import type { RemoteDeps } from './ws.js';

// ---------- harness ----------

interface Harness {
  env: TestEnv;
  app: ReturnType<typeof buildApp>;
  remote: RemoteDeps;
  base: string;
  wsBase: string;
  close(): Promise<void>;
}

async function make(opts: { maxClients?: number } = {}): Promise<Harness> {
  const env = makeEnv();
  const clock = () => env.clock.now;
  const compat = new CompatService(env.db, undefined, clock);
  const stripe = new StripeBilling(env.db, env.licenses, new ConsoleMailer(() => {}), { webhookSecret: 'whsec_x', clock });
  const remote: RemoteDeps = {
    auth: new RemoteAuth(env.licenses, env.keys, clock),
    rooms: new RoomRegistry({ clock, maxClients: opts.maxClients ?? 8 }),
    ice: new IceService(
      { stunUrls: ['stun:stun.example.test:3478'], turnUrls: ['turn:turn.example.test:3478?transport=udp'], turnSecret: 'turn-secret', turnUser: 'mz', turnTtlSec: 3600 },
      clock,
    ),
    clock,
    pingIntervalMs: 60_000,
  };
  const app = buildApp({ licenses: env.licenses, keys: env.keys, compat, stripe, adminToken: 'admin-secret', remote });
  const base = await app.listen({ port: 0, host: '127.0.0.1' });
  return { env, app, remote, base, wsBase: base.replace(/^http/, 'ws'), close: () => app.close() };
}

/** Issues a license on `plan` and activates `deviceId` on it; returns the MZL1 device token. */
function tokenFor(env: TestEnv, deviceId: string, plan: 'standard' | 'pro' | 'trial' = 'standard', platform = 'macos', name = 'Test Mac'): string {
  const { key } = env.licenses.issue({ kind: plan === 'trial' ? 'trial' : 'perpetual', plan, source: 'manual', maxDevices: 5, expiresAt: env.clock.now + 86_400 * 14 });
  return env.licenses.activate(key, { id: deviceId, platform, name }).token;
}

type Msg = Record<string, unknown> & { t: string };

class Sock {
  readonly ws: WebSocket;
  readonly closed: Promise<{ code: number; reason: string }>;
  private readonly queue: Msg[] = [];
  private readonly waiters: Array<(m: Msg) => void> = [];

  constructor(url: string, headers: Record<string, string> = {}) {
    this.ws = new WebSocket(url, { headers });
    this.ws.on('message', (d) => {
      const m = JSON.parse(d.toString()) as Msg;
      const w = this.waiters.shift();
      if (w) w(m);
      else this.queue.push(m);
    });
    this.ws.on('error', () => {});
    this.closed = new Promise((resolve) => this.ws.on('close', (code, reason) => resolve({ code, reason: reason.toString() })));
  }

  open(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws.once('open', () => resolve());
      this.ws.once('error', reject);
    });
  }

  next(timeoutMs = 3000): Promise<Msg> {
    const queued = this.queue.shift();
    if (queued) return Promise.resolve(queued);
    return new Promise((resolve, reject) => {
      const t = setTimeout(() => reject(new Error('timeout waiting for a message')), timeoutMs);
      this.waiters.push((m) => {
        clearTimeout(t);
        resolve(m);
      });
    });
  }

  async expectNone(ms = 150): Promise<void> {
    let got: Msg | undefined;
    try {
      got = await this.next(ms);
    } catch {
      return;
    }
    assert.fail(`unexpected message ${JSON.stringify(got)}`);
  }

  send(o: unknown): void {
    this.ws.send(JSON.stringify(o));
  }

  close(): void {
    this.ws.close(1000, 'done');
  }
}

async function connect(url: string, headers?: Record<string, string>): Promise<Sock> {
  const s = new Sock(url, headers);
  await s.open();
  return s;
}

/** Opens a socket the server is expected to reject: returns the error message and close frame. */
async function expectRejected(url: string, headers?: Record<string, string>): Promise<{ error: Msg; code: number }> {
  const s = await connect(url, headers);
  const error = await s.next();
  const closed = await s.closed;
  assert.equal(error.t, 'error', JSON.stringify(error));
  return { error, code: closed.code };
}

async function createPairing(h: Harness, token: string): Promise<{ code: string; room_id: string; expires_at: number; deep_link: string; host_hash: string; display: string; ws_url: string }> {
  const r = await h.app.inject({ method: 'POST', url: '/v1/remote/pairings', payload: { token } });
  assert.equal(r.statusCode, 201, r.body);
  return r.json();
}

// ---------- protocol unit tests ----------

test('remote: pairing code normalization and input event schema', () => {
  assert.equal(normalizePairingCode('7k3-mzp'), '7K3MZP');
  assert.equal(normalizePairingCode(' 7K3 MZP '), '7K3MZP');
  assert.equal(normalizePairingCode('oil-l0o'), '011100');
  assert.equal(normalizePairingCode('7K3MZ'), null);
  assert.equal(normalizePairingCode('7K3MZPP'), null);
  assert.equal(normalizePairingCode('UUUUUU'), null); // U is not in the alphabet
  assert.equal(formatPairingCode('7K3MZP'), '7K3-MZP');

  assert.ok(InputEventSchema.safeParse({ k: 'mv', x: 0.5, y: 0.25 }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'mv', x: 0.5 }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'mv', x: 1.5, y: 0 }).success);
  assert.ok(InputEventSchema.safeParse({ k: 'dn', x: 0.1, y: 0.1, b: 0 }).success);
  assert.ok(InputEventSchema.safeParse({ k: 'up', code: 'KeyA', mods: 2 }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'dn', x: 0.1, y: 0.1, b: 0, code: 'KeyA' }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'dn', b: 0 }).success);
  assert.ok(InputEventSchema.safeParse({ k: 'sc', x: 0.5, y: 0.5, dx: 0, dy: -120, mods: 2 }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'sc', x: 0.5, y: 0.5 }).success);
  assert.ok(InputEventSchema.safeParse({ k: 'key', code: 'Enter' }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'key', code: 'Enter!' }).success);
  assert.ok(InputEventSchema.safeParse({ k: 'txt', s: 'LINE' }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'txt' }).success);
  assert.ok(!InputEventSchema.safeParse({ k: 'zoom' }).success);

  const relay = PeerMessageSchema.safeParse({ t: 'ice', candidate: { candidate: 'candidate:1 1 udp 2 192.0.2.1 5000 typ host', sdpMid: '0', sdpMLineIndex: 0 }, extra: 'dropped' });
  assert.ok(relay.success);
  assert.ok(!('extra' in relay.data));
  assert.ok(PeerMessageSchema.safeParse({ t: 'ice', candidate: null }).success);
  assert.ok(!PeerMessageSchema.safeParse({ t: 'nope' }).success);
  assert.ok(!PeerMessageSchema.safeParse({ t: 'input', evs: [] }).success);
});

test('remote: ICE credentials are time-limited HMAC-SHA1 (TURN REST API)', () => {
  const exp = 1_800_003_600;
  const cred = turnRestCredential('turn-secret', 'mz', exp);
  assert.equal(cred.username, `${exp}:mz`);
  assert.equal(cred.credential, createHmac('sha1', 'turn-secret').update(`${exp}:mz`).digest('base64'));

  const clock = () => 1_800_000_000;
  const withSecret = new IceService({ stunUrls: ['stun:s:3478'], turnUrls: ['turn:t:3478'], turnSecret: 'turn-secret', turnUser: 'mz', turnTtlSec: 3600 }, clock).servers();
  assert.equal(withSecret.ttl, 3600);
  assert.equal(withSecret.expires_at, 1_800_003_600);
  assert.deepEqual(withSecret.iceServers[0], { urls: ['stun:s:3478'] });
  assert.equal(withSecret.iceServers[1]?.username, '1800003600:mz');
  assert.equal(withSecret.iceServers[1]?.credential, cred.credential);

  const staticCreds = new IceService({ stunUrls: [], turnUrls: ['turn:t:3478'], turnUser: 'u', turnPass: 'p', turnTtlSec: 60 }, clock).servers();
  assert.deepEqual(staticCreds.iceServers, [{ urls: ['turn:t:3478'], username: 'u', credential: 'p' }]);
  assert.equal(staticCreds.expires_at, null);

  const stunOnly = new IceService({ stunUrls: ['stun:s:3478'], turnUrls: ['turn:t:3478'], turnTtlSec: 60 }, clock).servers();
  assert.equal(stunOnly.iceServers.length, 1, 'TURN without credentials is omitted');

  const cfg = iceConfigFromEnv({ STUN_URLS: 'stun:a:1, stun:b:2', TURN_URL: 'turn:c:3', TURN_SECRET: 's', TURN_TTL_SECONDS: '120' });
  assert.deepEqual(cfg.stunUrls, ['stun:a:1', 'stun:b:2']);
  assert.deepEqual(cfg.turnUrls, ['turn:c:3']);
  assert.equal(cfg.turnSecret, 's');
  assert.equal(cfg.turnTtlSec, 120);
  assert.deepEqual(iceConfigFromEnv({ STUN_URLS: '' }).stunUrls, []);
  assert.equal(iceConfigFromEnv({}).stunUrls.length, 1);
});

// ---------- end-to-end over real WebSockets ----------

test('remote: pair host + client, relay offer/answer/ice, apps/launch/input, kick', async (t) => {
  const h = await make();
  t.after(() => h.close());
  const hostToken = tokenFor(h.env, 'mac-device-0001-xyz', 'standard', 'macos', 'Studio');
  const clientToken = tokenFor(h.env, 'phone-device-0001-xyz', 'standard', 'ios', 'Phone');

  const pairing = await createPairing(h, hostToken);
  assert.equal(pairing.code.length, 6);
  for (const ch of pairing.code) assert.ok(KEY_ALPHABET.includes(ch));
  assert.equal(pairing.display, formatPairingCode(pairing.code));
  assert.equal(pairing.expires_at, h.env.clock.now + 600);
  assert.equal(pairing.host_hash, deviceHash('mac-device-0001-xyz'));
  assert.equal(pairing.deep_link, `mirrorz://pair?code=${pairing.code}&h=${pairing.host_hash}`);
  assert.match(pairing.ws_url, /^ws:\/\/.+\/v1\/remote\/ws$/); // derived from the request host (inject → localhost)

  // Host attaches with the token in the Authorization header (preferred form).
  const host = await connect(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}`, { authorization: `Bearer ${hostToken}` });
  const hostHello = await host.next();
  assert.equal(hostHello.t, 'hello');
  assert.equal(hostHello.role, 'host');
  assert.equal(hostHello.peer_id, 'host');
  assert.equal(hostHello.room_id, pairing.room_id);
  assert.deepEqual(hostHello.peers, []);
  assert.equal((hostHello.self as { name: string }).name, 'Studio');

  // Client redeems a sloppily typed code via the query form.
  const typed = `${pairing.code.slice(0, 3).toLowerCase()}-${pairing.code.slice(3)}`;
  const client = await connect(`${h.wsBase}/v1/remote/ws?role=client&code=${typed}&auth=${clientToken}&name=Brandon%27s%20iPhone`);
  const clientHello = await client.next();
  assert.equal(clientHello.t, 'hello');
  assert.equal(clientHello.role, 'client');
  assert.match(String(clientHello.peer_id), /^p_[A-Za-z0-9_-]{8}$/);
  assert.equal(clientHello.host_hash, pairing.host_hash);
  assert.ok(String(clientHello.grant).startsWith('MZP1.'));
  const peers = clientHello.peers as Array<{ peer_id: string; same_license: boolean }>;
  assert.equal(peers.length, 1);
  assert.equal(peers[0]?.peer_id, 'host');
  assert.equal(peers[0]?.same_license, false); // separate licenses in this test
  const ice = clientHello.ice_servers as Array<{ urls: string[]; username?: string }>;
  assert.equal(ice.length, 2);
  assert.equal(ice[1]?.username, `${h.env.clock.now + 3600}:mz`);
  const limits = clientHello.limits as { max_message_bytes: number; max_clients: number; grant_expires_at: number };
  assert.equal(limits.max_message_bytes, 65_536);
  assert.equal(limits.max_clients, 8);
  assert.equal(limits.grant_expires_at, h.env.clock.now + 90 * 86_400);

  const joined = await host.next();
  assert.equal(joined.t, 'peer-joined');
  const peer = joined.peer as { peer_id: string; name: string; platform: string; device_hash: string };
  assert.equal(peer.peer_id, clientHello.peer_id);
  assert.equal(peer.name, "Brandon's iPhone");
  assert.equal(peer.platform, 'ios');
  assert.equal(peer.device_hash, deviceHash('phone-device-0001-xyz'));
  const cid = peer.peer_id;

  // offer → answer → ice both ways; `from` is stamped by the server, `to` is stripped.
  host.send({ t: 'offer', to: cid, sdp: 'v=0 offer', ref: 'o1' });
  const offer = await client.next();
  assert.deepEqual(offer, { t: 'offer', sdp: 'v=0 offer', ref: 'o1', from: 'host' });
  client.send({ t: 'answer', sdp: 'v=0 answer', to: 'host' });
  const answer = await host.next();
  assert.deepEqual(answer, { t: 'answer', sdp: 'v=0 answer', from: cid });
  client.send({ t: 'ice', candidate: { candidate: 'candidate:1 1 udp 2 192.0.2.1 5000 typ host', sdpMid: '0', sdpMLineIndex: 0 } });
  assert.equal((await host.next()).t, 'ice');
  host.send({ t: 'ice', to: cid, candidate: null });
  assert.deepEqual(await client.next(), { t: 'ice', candidate: null, from: 'host' });

  // apps broadcast (no `to`) → launch → apps to one peer; input fallback on the WebSocket.
  host.send({ t: 'apps', apps: [{ id: 'app_autocad', name: 'AutoCAD 2026', kind: 'app', runtime: 'vm', state: 'stopped', compat_id: 'autocad' }], streaming: null, surface: { w: 2560, h: 1440 } });
  const apps = await client.next();
  assert.equal(apps.t, 'apps');
  assert.equal(apps.from, 'host');
  assert.equal((apps.apps as unknown[]).length, 1);
  client.send({ t: 'launch', app_id: 'app_autocad', ref: 'l1' });
  assert.deepEqual(await host.next(), { t: 'launch', app_id: 'app_autocad', ref: 'l1', from: cid });
  host.send({ t: 'apps', to: cid, apps: [{ id: 'app_autocad', name: 'AutoCAD 2026', kind: 'app', runtime: 'vm', state: 'running' }], streaming: 'app_autocad' });
  assert.equal((await client.next()).streaming, 'app_autocad');
  client.send({ t: 'input', evs: [{ k: 'mv', x: 0.5, y: 0.5 }, { k: 'dn', x: 0.5, y: 0.5, b: 0 }, { k: 'up', x: 0.5, y: 0.5, b: 0 }, { k: 'txt', s: 'LINE' }] });
  const input = await host.next();
  assert.equal(input.t, 'input');
  assert.equal((input.evs as unknown[]).length, 4);
  host.send({ t: 'error', to: cid, code: 'launch_failed', message: 'installer still running', ref: 'l1' });
  assert.deepEqual(await client.next(), { t: 'error', code: 'launch_failed', message: 'installer still running', ref: 'l1', from: 'host' });

  // Validation and permission errors go back to the sender only.
  client.send({ t: 'apps', apps: [], streaming: null });
  assert.equal((await client.next()).code, 'not_allowed');
  client.send({ t: 'input', evs: [{ k: 'mv', x: 0.5 }], ref: 'bad1' });
  const bad = await client.next();
  assert.equal(bad.code, 'validation');
  assert.equal(bad.ref, 'bad1');
  client.send('{not json');
  assert.equal((await client.next()).code, 'validation');
  client.send({ t: 'offer', to: 'p_someoneelse', sdp: 'x' });
  assert.equal((await client.next()).code, 'not_allowed');
  host.send({ t: 'offer', sdp: 'x' });
  assert.equal((await host.next()).code, 'validation');
  host.send({ t: 'ice', to: 'p_nobody', candidate: null });
  assert.equal((await host.next()).code, 'unknown_peer');
  await client.expectNone();

  // Host kicks the client.
  host.send({ t: 'bye', to: cid });
  assert.deepEqual(await client.next(), { t: 'bye', reason: 'kicked', from: 'host' });
  assert.equal((await client.closed).code, 4410);
  assert.deepEqual(await host.next(), { t: 'peer-left', peer_id: cid, reason: 'kicked' });
  assert.equal(h.remote.rooms.stats().clients, 0);
  host.close();
  await host.closed;
});

test('remote: pairing codes are single-use, unknown codes are 4404, host must be online', async (t) => {
  const h = await make();
  t.after(() => h.close());
  const hostToken = tokenFor(h.env, 'mac-device-0002-xyz');
  const clientToken = tokenFor(h.env, 'phone-device-0002-xyz', 'standard', 'android');
  const pairing = await createPairing(h, hostToken);

  // Host not connected yet → the code is valid but nobody is home.
  const offline = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=${pairing.code}&auth=${clientToken}`);
  assert.equal(offline.error.code, 'host_offline');
  assert.equal(offline.code, 4404);

  const host = await connect(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}&auth=${hostToken}`);
  assert.equal((await host.next()).t, 'hello');

  const first = await connect(`${h.wsBase}/v1/remote/ws?role=client&code=${pairing.code}&auth=${clientToken}`);
  assert.equal((await first.next()).t, 'hello');
  assert.equal((await host.next()).t, 'peer-joined');

  const reuse = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=${pairing.code}&auth=${clientToken}`);
  assert.equal(reuse.error.code, 'code_used');
  assert.equal(reuse.code, 4409);

  const unknown = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=000000&auth=${clientToken}`);
  assert.equal(unknown.error.code, 'not_found');
  assert.equal(unknown.code, 4404);

  const malformed = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=UUUUUU&auth=${clientToken}`);
  assert.equal(malformed.error.code, 'validation');
  assert.equal(malformed.code, 4400);

  // A second code for the same host reuses the room.
  const again = await createPairing(h, hostToken);
  assert.equal(again.room_id, pairing.room_id);
  assert.notEqual(again.code, pairing.code);

  // Brute force guard: after 5 failures from one IP the next attempt is throttled.
  for (let i = 0; i < 3; i++) await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=00000${i}&auth=${clientToken}`);
  const throttled = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=${again.code}&auth=${clientToken}`);
  assert.equal(throttled.error.code, 'rate_limited');
  assert.equal(throttled.code, 4429);

  first.close();
  host.close();
  await Promise.all([first.closed, host.closed]);
});

test('remote: pairing codes expire after 10 minutes (fake clock) and pending rooms are swept', async (t) => {
  const h = await make();
  t.after(() => h.close());
  const hostToken = tokenFor(h.env, 'mac-device-0003-xyz');
  const clientToken = tokenFor(h.env, 'phone-device-0003-xyz');
  const pairing = await createPairing(h, hostToken);
  const host = await connect(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}&auth=${hostToken}`);
  assert.equal((await host.next()).t, 'hello');

  h.env.clock.advance(599);
  const stillValid = await createPairing(h, hostToken); // a fresh code minted just before the first expires
  h.env.clock.advance(2);

  const expired = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=${pairing.code}&auth=${clientToken}`);
  assert.equal(expired.error.code, 'code_expired');
  assert.equal(expired.code, 4408);

  const ok = await connect(`${h.wsBase}/v1/remote/ws?role=client&code=${stillValid.code}&auth=${clientToken}`);
  assert.equal((await ok.next()).t, 'hello');
  ok.close();
  host.close();
  await Promise.all([ok.closed, host.closed]);

  // A room that never got a host disappears once its codes expire.
  const idleToken = tokenFor(h.env, 'mac-device-0004-xyz');
  await createPairing(h, idleToken);
  assert.equal(h.remote.rooms.stats().pending_codes, 1);
  h.env.clock.advance(601);
  h.remote.rooms.sweep();
  assert.deepEqual(h.remote.rooms.stats(), { rooms: 0, live_rooms: 0, clients: 0, pending_codes: 0 });
});

test('remote: endpoints answer 503 disabled when Remote is not configured', async () => {
  const env = makeEnv();
  const compat = new CompatService(env.db, undefined, () => env.clock.now);
  const stripe = new StripeBilling(env.db, env.licenses, new ConsoleMailer(() => {}), { webhookSecret: 'whsec_x', clock: () => env.clock.now });
  const app = buildApp({ licenses: env.licenses, keys: env.keys, compat, stripe });
  const r = await app.inject({ method: 'POST', url: '/v1/remote/pairings', payload: { token: 'x'.repeat(30) } });
  assert.equal(r.statusCode, 503);
  assert.equal(r.json().error, 'disabled');
  assert.equal((await app.inject({ method: 'GET', url: '/v1/remote/ice' })).statusCode, 503);
  await app.close();
});

test('remote: bad or unentitled tokens are rejected everywhere', async (t) => {
  const h = await make();
  t.after(() => h.close());
  const good = tokenFor(h.env, 'mac-device-0005-xyz');
  const tampered = good.slice(0, -4) + 'AAAA';

  assert.equal((await h.app.inject({ method: 'POST', url: '/v1/remote/pairings', payload: { token: tampered } })).statusCode, 401);
  assert.equal((await h.app.inject({ method: 'POST', url: '/v1/remote/pairings', payload: {} })).statusCode, 400);
  assert.equal((await h.app.inject({ method: 'GET', url: '/v1/remote/ice' })).statusCode, 401);
  const ice = await h.app.inject({ method: 'GET', url: '/v1/remote/ice', headers: { authorization: `Bearer ${good}` } });
  assert.equal(ice.statusCode, 200);
  assert.equal(ice.json().iceServers.length, 2);
  assert.equal(ice.json().ttl, 3600);

  const pairing = await createPairing(h, good);
  const badSig = await expectRejected(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}&auth=${tampered}`);
  assert.equal(badSig.error.code, 'bad_token');
  assert.equal(badSig.code, 4401);
  const missing = await expectRejected(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}`);
  assert.equal(missing.code, 4401);
  const badRole = await expectRejected(`${h.wsBase}/v1/remote/ws?role=admin&auth=${good}`);
  assert.equal(badRole.code, 4400);
  const noRoom = await expectRejected(`${h.wsBase}/v1/remote/ws?role=host&auth=${good}`);
  assert.equal(noRoom.error.code, 'validation');
  const badVersion = await expectRejected(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}&auth=${good}&v=2`);
  assert.equal(badVersion.code, 4400);

  // Trials do not include mobile-companion.
  const trial = tokenFor(h.env, 'mac-device-trial-xyz', 'trial');
  const trialRes = await h.app.inject({ method: 'POST', url: '/v1/remote/pairings', payload: { token: trial } });
  assert.equal(trialRes.statusCode, 403);
  assert.equal(trialRes.json().error, 'feature_required');

  // Another device's token cannot host this room.
  const other = tokenFor(h.env, 'mac-device-0006-xyz');
  const mismatch = await expectRejected(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}&auth=${other}`);
  assert.equal(mismatch.error.code, 'device_mismatch');
  assert.equal(mismatch.code, 4403);

  // Deactivated device → token still verifies but the activation is gone.
  const lic = h.env.licenses.findByKey(h.env.licenses.issue({ kind: 'perpetual', plan: 'pro', source: 'manual' }).key)!;
  const deact = h.env.licenses.activateById(lic.id, { id: 'mac-device-0007-xyz' }).token;
  h.env.licenses.deactivate(lic.id, 'mac-device-0007-xyz');
  const notActivated = await h.app.inject({ method: 'POST', url: '/v1/remote/pairings', payload: { token: deact } });
  assert.equal(notActivated.statusCode, 403);
  assert.equal(notActivated.json().error, 'not_activated');

  // Expired token (exp in the past) → 401.
  h.env.clock.advance(31 * 86_400);
  const expired = await expectRejected(`${h.wsBase}/v1/remote/ws?role=host&room=${pairing.room_id}&auth=${good}`);
  assert.equal(expired.error.code, 'bad_token');
  assert.equal(expired.code, 4401);
});

test('remote: room dies with the host, grants reconnect, newer host replaces older, room capacity', async (t) => {
  const h = await make({ maxClients: 2 });
  t.after(() => h.close());
  const hostToken = tokenFor(h.env, 'mac-device-0008-xyz');
  const clientToken = tokenFor(h.env, 'phone-device-0008-xyz');
  const otherClient = tokenFor(h.env, 'phone-device-0009-xyz');
  const thirdClient = tokenFor(h.env, 'phone-device-0010-xyz');

  const p1 = await createPairing(h, hostToken);
  const host1 = await connect(`${h.wsBase}/v1/remote/ws?role=host&room=${p1.room_id}&auth=${hostToken}`);
  assert.equal((await host1.next()).t, 'hello');
  const client = await connect(`${h.wsBase}/v1/remote/ws?role=client&code=${p1.code}&auth=${clientToken}`);
  const hello = await client.next();
  const grant = String(hello.grant);
  assert.equal((await host1.next()).t, 'peer-joined');

  // Newer host connection for the same device replaces the stale one; clients stay attached.
  const host2 = await connect(`${h.wsBase}/v1/remote/ws?role=host&room=${p1.room_id}&auth=${hostToken}`);
  const hello2 = await host2.next();
  assert.equal(hello2.t, 'hello');
  assert.equal((hello2.peers as unknown[]).length, 1);
  assert.deepEqual(await host1.next(), { t: 'bye', reason: 'replaced' });
  assert.equal((await host1.closed).code, 4409);

  // Capacity: 2 clients max.
  const p2 = await createPairing(h, hostToken);
  const second = await connect(`${h.wsBase}/v1/remote/ws?role=client&code=${p2.code}&auth=${otherClient}`);
  assert.equal((await second.next()).t, 'hello');
  assert.equal((await host2.next()).t, 'peer-joined');
  const p3 = await createPairing(h, hostToken);
  const full = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&code=${p3.code}&auth=${thirdClient}`);
  assert.equal(full.error.code, 'room_full');
  assert.equal(full.code, 4403);
  // The unused code survives the failed attempt (it was not consumed).
  second.send({ t: 'bye' });
  assert.equal((await second.closed).code, 1000);
  const left = await host2.next();
  assert.equal(left.t, 'peer-left');
  assert.equal(left.reason, 'bye');
  const third = await connect(`${h.wsBase}/v1/remote/ws?role=client&code=${p3.code}&auth=${thirdClient}`);
  assert.equal((await third.next()).t, 'hello');
  assert.equal((await host2.next()).t, 'peer-joined');
  third.close();
  await third.closed;
  assert.equal((await host2.next()).t, 'peer-left');

  // Host leaves → every client gets bye + 4410, and the room is gone.
  host2.close();
  assert.deepEqual(await client.next(), { t: 'bye', reason: 'host_left' });
  assert.equal((await client.closed).code, 4410);
  assert.equal(h.remote.rooms.getRoom(p1.room_id), undefined);
  assert.equal(h.remote.rooms.stats().rooms, 0);

  // Grant while the Mac is offline → host_offline; after the Mac comes back (new room) it works without a code.
  const offline = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&grant=${grant}&auth=${clientToken}`);
  assert.equal(offline.error.code, 'host_offline');
  const p4 = await createPairing(h, hostToken);
  assert.notEqual(p4.room_id, p1.room_id);
  const host3 = await connect(`${h.wsBase}/v1/remote/ws?role=host&room=${p4.room_id}&auth=${hostToken}`);
  assert.equal((await host3.next()).t, 'hello');
  h.env.clock.advance(5); // grants are deterministic signatures over (host, dev, iat, exp); move time so a new one differs
  const back = await connect(`${h.wsBase}/v1/remote/ws?role=client&grant=${grant}&auth=${clientToken}`);
  const backHello = await back.next();
  assert.equal(backHello.t, 'hello');
  assert.equal(backHello.room_id, p4.room_id);
  assert.notEqual(backHello.grant, grant, 'a fresh grant is issued on every connection');
  assert.equal((await host3.next()).t, 'peer-joined');

  // A grant presented by a different device is refused; a tampered grant is refused.
  const stolen = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&grant=${grant}&auth=${otherClient}`);
  assert.equal(stolen.error.code, 'device_mismatch');
  assert.equal(stolen.code, 4403);
  const forged = await expectRejected(`${h.wsBase}/v1/remote/ws?role=client&grant=${grant.slice(0, -4)}AAAA&auth=${clientToken}`);
  assert.equal(forged.error.code, 'bad_token');
  assert.equal(forged.code, 4401);

  // Frames over 64 KiB are dropped at the transport (1009).
  back.send({ t: 'offer', sdp: 'x'.repeat(70_000) });
  assert.equal((await back.closed).code, 1009);
  assert.deepEqual(await host3.next(), { t: 'peer-left', peer_id: backHello.peer_id, reason: 'closed' });

  // Host closes the whole room with a bare bye.
  host3.send({ t: 'bye' });
  assert.equal((await host3.closed).code, 1000);
  assert.equal(h.remote.rooms.stats().rooms, 0);
});
