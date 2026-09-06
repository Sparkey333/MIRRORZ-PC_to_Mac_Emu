import { z } from 'zod';
import { KEY_ALPHABET } from '../license/keyformat.js';

/**
 * MIRRORZ Remote protocol v1 — wire schemas and constants.
 * Normative description: docs/spec/remote-protocol.md. Every inbound message is validated here
 * before the server looks at it; relayed messages are re-serialized from the validated object so
 * unknown fields never pass through.
 */
export const PROTOCOL_VERSION = 1 as const;
export const MAX_MESSAGE_BYTES = 65_536;
export const MAX_SDP_BYTES = 61_440;
export const PAIRING_CODE_LEN = 6;
export const PAIRING_TTL_SEC = 600;
export const DEFAULT_MAX_CLIENTS = 8;
export const DEFAULT_GRANT_DAYS = 90;
export const MAX_APPS = 200;
export const MAX_INPUT_BATCH = 64;
export const MAX_TEXT_LEN = 4096;
export const MAX_ICON_CHARS = 8192;
export const MAX_NAME_LEN = 60;
export const REQUIRED_FEATURE = 'mobile-companion';
export const HOST_PEER_ID = 'host';
export const DATA_CHANNEL_INPUT = 'mz-input';

/** Rate limits per connection: [burst, sustained per second]. */
export const RATE_SIGNAL: readonly [number, number] = [60, 20];
export const RATE_APPS: readonly [number, number] = [10, 1];
export const RATE_INPUT: readonly [number, number] = [240, 120];
/** Consecutive rate-limited messages before the socket is closed with 4429. */
export const MAX_CONSECUTIVE_DROPS = 200;

export const CloseCode = {
  NORMAL: 1000,
  TOO_LARGE: 1009,
  BAD_REQUEST: 4400,
  UNAUTHORIZED: 4401,
  FORBIDDEN: 4403,
  NOT_FOUND: 4404,
  EXPIRED: 4408,
  CONFLICT: 4409,
  GONE: 4410,
  RATE_LIMITED: 4429,
  SHUTDOWN: 4503,
} as const;
export type CloseCodeValue = (typeof CloseCode)[keyof typeof CloseCode];

export type ErrorCode =
  | 'validation'
  | 'bad_token'
  | 'not_activated'
  | 'expired'
  | 'revoked'
  | 'refunded'
  | 'paused'
  | 'feature_required'
  | 'device_mismatch'
  | 'not_found'
  | 'code_used'
  | 'code_expired'
  | 'host_offline'
  | 'room_full'
  | 'room_closed'
  | 'replaced'
  | 'kicked'
  | 'rate_limited'
  | 'too_large'
  | 'unknown_peer'
  | 'not_allowed'
  | 'launch_failed'
  | 'server_shutdown'
  | 'internal';

export type PeerRole = 'host' | 'client';

// ---------- pairing codes ----------

/**
 * Normalizes a typed/scanned pairing code the same way license keys are normalized:
 * uppercase, strip separators and whitespace, O→0, I/L→1. Returns the 6-symbol code or null.
 */
export function normalizePairingCode(input: string): string | null {
  if (typeof input !== 'string') return null;
  let s = input.toUpperCase().replace(/[\s\-_.]/g, '');
  s = s.replace(/O/g, '0').replace(/[IL]/g, '1');
  if (s.length !== PAIRING_CODE_LEN) return null;
  for (const ch of s) if (!KEY_ALPHABET.includes(ch)) return null;
  return s;
}

/** `7K3MZP` → `7K3-MZP` for display. */
export function formatPairingCode(code: string): string {
  return `${code.slice(0, 3)}-${code.slice(3)}`;
}

// ---------- HTTP schemas ----------

const Token = z.string().min(20).max(4096);
const DisplayName = z.string().max(MAX_NAME_LEN);

export const CreatePairingSchema = z.object({
  token: Token,
  name: DisplayName.optional(),
});
export type CreatePairingBody = z.infer<typeof CreatePairingSchema>;

export const WsQuerySchema = z.object({
  role: z.enum(['host', 'client']),
  auth: Token.optional(),
  room: z.string().min(5).max(64).optional(),
  code: z.string().min(PAIRING_CODE_LEN).max(PAIRING_CODE_LEN * 2).optional(),
  grant: Token.optional(),
  v: z.coerce.number().int().optional(),
  name: DisplayName.optional(),
});
export type WsQuery = z.infer<typeof WsQuerySchema>;

// ---------- peer → server messages ----------

const PeerId = z.string().min(1).max(32);
const Ref = z.string().max(64).optional();
const Sdp = z.string().min(1).max(MAX_SDP_BYTES);
const Unit = z.number().finite().min(0).max(1);
const Delta = z.number().finite().min(-100_000).max(100_000);

export const IceCandidateSchema = z.object({
  candidate: z.string().max(2048),
  sdpMid: z.string().max(64).nullable().optional(),
  sdpMLineIndex: z.number().int().min(0).max(255).nullable().optional(),
  usernameFragment: z.string().max(256).nullable().optional(),
});
export type IceCandidate = z.infer<typeof IceCandidateSchema>;

export const AppEntrySchema = z.object({
  id: z.string().min(1).max(80),
  name: z.string().min(1).max(120),
  kind: z.enum(['app', 'machine']),
  runtime: z.enum(['vm', 'bottle']).optional(),
  state: z.enum(['stopped', 'starting', 'running']),
  compat_id: z.string().max(80).optional(),
  machine_id: z.string().max(80).optional(),
  icon: z
    .string()
    .max(MAX_ICON_CHARS)
    .regex(/^data:image\/png;base64,[A-Za-z0-9+/]+=*$/, 'icon must be a PNG data URI')
    .optional(),
});
export type AppEntry = z.infer<typeof AppEntrySchema>;

/**
 * Input events (pointer / keyboard / scroll / text). Coordinates are normalized 0..1 to the
 * streamed surface. `dn`/`up` carry either a pointer button `b` (with x, y) or a key `code`.
 * Same JSON on the "mz-input" data channel and in the `input` WebSocket fallback.
 */
export const InputEventSchema = z
  .object({
    k: z.enum(['mv', 'dn', 'up', 'sc', 'key', 'txt']),
    x: Unit.optional(),
    y: Unit.optional(),
    b: z.number().int().min(0).max(4).optional(),
    dx: Delta.optional(),
    dy: Delta.optional(),
    code: z.string().min(1).max(32).regex(/^[A-Za-z0-9]+$/, 'code must be a KeyboardEvent.code value').optional(),
    mods: z.number().int().min(0).max(15).optional(),
    s: z.string().max(MAX_TEXT_LEN).optional(),
    t: z.number().finite().min(0).optional(),
  })
  .superRefine((e, ctx) => {
    const need = (cond: boolean, message: string) => {
      if (!cond) ctx.addIssue({ code: z.ZodIssueCode.custom, message });
    };
    const hasXY = e.x !== undefined && e.y !== undefined;
    switch (e.k) {
      case 'mv':
        need(hasXY, 'mv requires x and y');
        break;
      case 'dn':
      case 'up':
        need((e.b !== undefined) !== (e.code !== undefined), `${e.k} requires exactly one of b or code`);
        if (e.b !== undefined) need(hasXY, `${e.k} with a button requires x and y`);
        break;
      case 'sc':
        need(hasXY && e.dx !== undefined && e.dy !== undefined, 'sc requires x, y, dx and dy');
        break;
      case 'key':
        need(e.code !== undefined, 'key requires code');
        break;
      case 'txt':
        need(e.s !== undefined, 'txt requires s');
        break;
    }
  });
export type InputEvent = z.infer<typeof InputEventSchema>;

export const SurfaceSchema = z.object({
  w: z.number().int().min(1).max(16_384),
  h: z.number().int().min(1).max(16_384),
});

export const PeerMessageSchema = z.discriminatedUnion('t', [
  z.object({ t: z.literal('offer'), to: PeerId.optional(), sdp: Sdp, ref: Ref }),
  z.object({ t: z.literal('answer'), to: PeerId.optional(), sdp: Sdp, ref: Ref }),
  z.object({ t: z.literal('ice'), to: PeerId.optional(), candidate: IceCandidateSchema.nullable(), ref: Ref }),
  z.object({
    t: z.literal('apps'),
    to: PeerId.optional(),
    apps: z.array(AppEntrySchema).max(MAX_APPS),
    streaming: z.string().max(80).nullable(),
    surface: SurfaceSchema.optional(),
    ref: Ref,
  }),
  z.object({ t: z.literal('launch'), app_id: z.string().min(1).max(80), ref: Ref }),
  z.object({ t: z.literal('input'), evs: z.array(InputEventSchema).min(1).max(MAX_INPUT_BATCH), ref: Ref }),
  z.object({ t: z.literal('error'), to: PeerId.optional(), code: z.string().min(1).max(40), message: z.string().max(500), ref: Ref }),
  z.object({ t: z.literal('bye'), to: PeerId.optional(), reason: z.string().max(80).optional(), ref: Ref }),
]);
export type PeerMessage = z.infer<typeof PeerMessageSchema>;
export type PeerMessageType = PeerMessage['t'];

/** Which message types each role may send. */
export const ALLOWED_BY_ROLE: Record<PeerRole, ReadonlySet<PeerMessageType>> = {
  host: new Set<PeerMessageType>(['offer', 'answer', 'ice', 'apps', 'error', 'bye']),
  client: new Set<PeerMessageType>(['offer', 'answer', 'ice', 'launch', 'input', 'bye']),
};

/** Host messages that must name a recipient. */
export const HOST_TO_REQUIRED: ReadonlySet<PeerMessageType> = new Set(['offer', 'answer', 'ice', 'error']);

export function rateClassOf(t: PeerMessageType): 'signal' | 'apps' | 'input' {
  if (t === 'apps') return 'apps';
  if (t === 'input') return 'input';
  return 'signal';
}

// ---------- server → peer messages ----------

export interface PeerDescriptor {
  peer_id: string;
  role: PeerRole;
  device_hash: string;
  name?: string;
  platform?: string;
  same_license: boolean;
}

export interface IceServer {
  urls: string[];
  username?: string;
  credential?: string;
}

export interface HelloLimits {
  max_message_bytes: number;
  signal_per_sec: number;
  input_per_sec: number;
  max_clients: number;
  grant_expires_at?: number;
}

export interface HelloMessage {
  t: 'hello';
  v: typeof PROTOCOL_VERSION;
  peer_id: string;
  role: PeerRole;
  room_id: string;
  host_hash: string;
  self: PeerDescriptor;
  peers: PeerDescriptor[];
  grant?: string;
  ice_servers: IceServer[];
  limits: HelloLimits;
}

export interface PeerJoinedMessage {
  t: 'peer-joined';
  peer: PeerDescriptor;
}

export type PeerLeftReason = 'bye' | 'closed' | 'timeout' | 'kicked' | 'rate_limited';
export interface PeerLeftMessage {
  t: 'peer-left';
  peer_id: string;
  reason: PeerLeftReason;
}

export type ByeReason = 'host_left' | 'kicked' | 'replaced' | 'room_closed' | 'server_shutdown';
export interface ByeMessage {
  t: 'bye';
  reason: ByeReason;
  from?: string;
}

export interface ErrorMessage {
  t: 'error';
  code: ErrorCode | string;
  message: string;
  ref?: string;
  from?: string;
}

export type RelayedMessage = Omit<PeerMessage, 'to'> & { from: string };

export type ServerMessage = HelloMessage | PeerJoinedMessage | PeerLeftMessage | ByeMessage | ErrorMessage | RelayedMessage;

/** Formats zod issues the same way the HTTP layer does. */
export function issuesToMessage(issues: z.ZodIssue[]): string {
  return issues.map((i) => `${i.path.join('.') || '$'}: ${i.message}`).join('; ');
}
