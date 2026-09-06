import type { SigningKeys } from '../license/keys.js';
import type { LicenseService } from '../license/service.js';
import { nowSec } from '../util.js';
import { RemoteAuth } from './auth.js';
import { IceService, iceConfigFromEnv } from './ice.js';
import { DEFAULT_GRANT_DAYS, DEFAULT_MAX_CLIENTS } from './protocol.js';
import { RoomRegistry } from './rooms.js';
import type { RemoteDeps } from './ws.js';

export { RemoteAuth, deviceHash, GRANT_PREFIX, type AuthedDevice, type GrantClaims } from './auth.js';
export { IceService, iceConfigFromEnv, turnRestCredential, type IceConfig } from './ice.js';
export * from './protocol.js';
export { RoomRegistry, JoinError, type Peer, type PeerSocket, type Room } from './rooms.js';
export { registerRemote, type RemoteDeps } from './ws.js';

export interface CreateRemoteOptions {
  licenses: LicenseService;
  keys: SigningKeys;
  env?: NodeJS.ProcessEnv;
  clock?: () => number;
}

function int(v: string | undefined, dflt: number): number {
  if (v === undefined || v === '') return dflt;
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : dflt;
}

/**
 * Builds the Remote dependencies from the environment:
 *   REMOTE_MAX_CLIENTS   clients per room (default 8)
 *   REMOTE_GRANT_DAYS    reconnect grant lifetime (default 90)
 *   REMOTE_PUBLIC_WS_URL advertised WebSocket URL (default: derived from the request)
 *   STUN_URLS, TURN_URL, TURN_SECRET, TURN_USER, TURN_PASS, TURN_TTL_SECONDS  (see ice.ts)
 */
export function createRemote(opts: CreateRemoteOptions): RemoteDeps {
  const env = opts.env ?? process.env;
  const clock = opts.clock ?? nowSec;
  const deps: RemoteDeps = {
    auth: new RemoteAuth(opts.licenses, opts.keys, clock, int(env['REMOTE_GRANT_DAYS'], DEFAULT_GRANT_DAYS)),
    rooms: new RoomRegistry({ clock, maxClients: int(env['REMOTE_MAX_CLIENTS'], DEFAULT_MAX_CLIENTS) }),
    ice: new IceService(iceConfigFromEnv(env), clock),
    clock,
  };
  if (env['REMOTE_PUBLIC_WS_URL']) deps.wsUrl = env['REMOTE_PUBLIC_WS_URL'];
  return deps;
}
