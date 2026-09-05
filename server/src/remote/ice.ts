import { createHmac } from 'node:crypto';
import { nowSec } from '../util.js';
import type { IceServer } from './protocol.js';

export interface IceConfig {
  stunUrls: string[];
  turnUrls: string[];
  /** Enables time-limited credentials (coturn `use-auth-secret` / TURN REST API). */
  turnSecret?: string;
  /** Static username (no secret) or the suffix of time-limited usernames. */
  turnUser?: string;
  /** Static password; only used when no secret is configured. */
  turnPass?: string;
  turnTtlSec: number;
}

export const DEFAULT_STUN_URLS = ['stun:stun.mirrorz.app:3478'];
export const DEFAULT_TURN_TTL_SEC = 21_600; // 6 h

function list(v: string | undefined, dflt: string[]): string[] {
  if (v === undefined) return dflt;
  return v
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

export function iceConfigFromEnv(env: NodeJS.ProcessEnv = process.env): IceConfig {
  const ttl = Number(env['TURN_TTL_SECONDS']);
  return {
    stunUrls: list(env['STUN_URLS'], DEFAULT_STUN_URLS),
    turnUrls: list(env['TURN_URL'], []),
    ...(env['TURN_SECRET'] ? { turnSecret: env['TURN_SECRET'] } : {}),
    ...(env['TURN_USER'] ? { turnUser: env['TURN_USER'] } : {}),
    ...(env['TURN_PASS'] ? { turnPass: env['TURN_PASS'] } : {}),
    turnTtlSec: Number.isFinite(ttl) && ttl > 0 ? Math.floor(ttl) : DEFAULT_TURN_TTL_SEC,
  };
}

/**
 * TURN REST API credentials (draft-uberti-behave-turn-rest): username is "<expiry>:<user>",
 * credential is base64(HMAC-SHA1(secret, username)). coturn verifies these with `use-auth-secret`.
 */
export function turnRestCredential(secret: string, user: string, expiresAt: number): { username: string; credential: string } {
  const username = `${expiresAt}:${user}`;
  const credential = createHmac('sha1', secret).update(username).digest('base64');
  return { username, credential };
}

export interface IceServersResponse {
  iceServers: IceServer[];
  /** Seconds the TURN credentials stay valid (0 when there are none). */
  ttl: number;
  expires_at: number | null;
}

export class IceService {
  constructor(
    private readonly cfg: IceConfig,
    private readonly clock: () => number = nowSec,
  ) {}

  servers(): IceServersResponse {
    const iceServers: IceServer[] = [];
    if (this.cfg.stunUrls.length > 0) iceServers.push({ urls: [...this.cfg.stunUrls] });
    let ttl = 0;
    let expiresAt: number | null = null;
    if (this.cfg.turnUrls.length > 0) {
      if (this.cfg.turnSecret) {
        expiresAt = this.clock() + this.cfg.turnTtlSec;
        ttl = this.cfg.turnTtlSec;
        const { username, credential } = turnRestCredential(this.cfg.turnSecret, this.cfg.turnUser ?? 'mirrorz', expiresAt);
        iceServers.push({ urls: [...this.cfg.turnUrls], username, credential });
      } else if (this.cfg.turnUser && this.cfg.turnPass) {
        iceServers.push({ urls: [...this.cfg.turnUrls], username: this.cfg.turnUser, credential: this.cfg.turnPass });
      }
      // TURN URLs without any credentials are useless to WebRTC; omit them.
    }
    return { iceServers, ttl, expires_at: expiresAt };
  }
}
