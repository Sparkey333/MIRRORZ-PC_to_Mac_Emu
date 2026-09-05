import { sign, verify } from 'node:crypto';
import type { SigningKeys } from '../license/keys.js';
import type { LicenseService } from '../license/service.js';
import { TokenError, verifyLicenseToken, type LicenseClaims } from '../license/token.js';
import { b64urlDecode, b64urlEncode, DAY, HttpError, nowSec, sha256Hex } from '../util.js';
import { DEFAULT_GRANT_DAYS, REQUIRED_FEATURE } from './protocol.js';

/** Result of authenticating an MZL1 device token for MIRRORZ Remote. */
export interface AuthedDevice {
  claims: LicenseClaims;
  deviceId: string;
  /** sha256(device id) hex, first 16 chars — the only device identifier that goes on the wire between peers. */
  deviceHash: string;
  licenseId: string;
  plan: string;
  name: string | null;
  platform: string | null;
}

export const GRANT_PREFIX = 'MZP1';

/**
 * A grant lets a companion reconnect to a Mac it paired with once, without a new code.
 * Stateless: signed with the license signing key, so the Mac can verify it offline too.
 */
export interface GrantClaims {
  v: 1;
  kid: string;
  /** Host device hash. */
  host: string;
  /** Client device id (must equal the presenting token's `dev`). */
  dev: string;
  /** Client license id at issue time (informational). */
  lid: string;
  iat: number;
  exp: number;
}

export function deviceHash(deviceId: string): string {
  return sha256Hex(deviceId).slice(0, 16);
}

export class RemoteAuth {
  constructor(
    private readonly licenses: LicenseService,
    private readonly keys: SigningKeys,
    private readonly clock: () => number = nowSec,
    private readonly grantDays: number = DEFAULT_GRANT_DAYS,
  ) {}

  /**
   * Verifies an MZL1 token and checks — against the database, never the token alone — that the
   * device is activated, the license is entitled right now, and the plan includes Remote.
   */
  authenticate(token: string | undefined): AuthedDevice {
    if (!token) throw new HttpError(401, 'device token required', 'bad_token');
    let claims: LicenseClaims;
    try {
      claims = verifyLicenseToken(token, this.keys.publicKey, this.clock());
    } catch (e) {
      throw new HttpError(401, e instanceof TokenError ? `device token: ${e.message}` : 'invalid device token', 'bad_token');
    }
    if (typeof claims.dev !== 'string' || typeof claims.lid !== 'string') throw new HttpError(401, 'device token: missing claims', 'bad_token');
    const license = this.licenses.getById(claims.lid);
    if (!license) throw new HttpError(403, 'license no longer exists', 'not_activated');
    const activation = this.licenses.listActivations(license.id).find((a) => a.device_id === claims.dev);
    if (!activation) throw new HttpError(403, 'device is not activated on this license', 'not_activated');
    const ent = this.licenses.entitlement(license, this.clock());
    if (!ent.entitled) throw new HttpError(403, `license is not entitled: ${ent.reason}`, ent.reason);
    if (!ent.features.includes(REQUIRED_FEATURE)) {
      throw new HttpError(403, 'MIRRORZ Remote requires the mobile-companion feature (Standard plan or higher)', 'feature_required');
    }
    return {
      claims,
      deviceId: claims.dev,
      deviceHash: deviceHash(claims.dev),
      licenseId: license.id,
      plan: license.plan,
      name: activation.device_name,
      platform: activation.platform,
    };
  }

  issueGrant(hostHash: string, client: AuthedDevice): { grant: string; expiresAt: number } {
    const now = this.clock();
    const claims: GrantClaims = {
      v: 1,
      kid: this.keys.kid,
      host: hostHash,
      dev: client.deviceId,
      lid: client.licenseId,
      iat: now,
      exp: now + this.grantDays * DAY,
    };
    const payload = b64urlEncode(JSON.stringify(claims));
    const signingInput = `${GRANT_PREFIX}.${payload}`;
    const sig = sign(null, Buffer.from(signingInput, 'utf8'), this.keys.privateKey);
    return { grant: `${signingInput}.${b64urlEncode(sig)}`, expiresAt: claims.exp };
  }

  /** Verifies a grant presented by `client`; the grant must have been issued to the same device. */
  verifyGrant(grant: string, client: AuthedDevice): GrantClaims {
    const parts = grant.split('.');
    if (parts.length !== 3 || parts[0] !== GRANT_PREFIX) throw new HttpError(401, 'grant: malformed', 'bad_token');
    const signingInput = `${parts[0]}.${parts[1]}`;
    let ok = false;
    try {
      ok = verify(null, Buffer.from(signingInput, 'utf8'), this.keys.publicKey, b64urlDecode(parts[2]!));
    } catch {
      ok = false;
    }
    if (!ok) throw new HttpError(401, 'grant: bad signature', 'bad_token');
    let claims: GrantClaims;
    try {
      claims = JSON.parse(b64urlDecode(parts[1]!).toString('utf8')) as GrantClaims;
    } catch {
      throw new HttpError(401, 'grant: malformed payload', 'bad_token');
    }
    if (claims.v !== 1 || typeof claims.host !== 'string' || typeof claims.dev !== 'string' || typeof claims.exp !== 'number') {
      throw new HttpError(401, 'grant: unsupported', 'bad_token');
    }
    if (claims.exp < this.clock()) throw new HttpError(401, 'grant: expired, pair again', 'bad_token');
    if (claims.dev !== client.deviceId) throw new HttpError(403, 'grant was issued to a different device', 'device_mismatch');
    return claims;
  }
}
