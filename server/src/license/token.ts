import { sign, verify, type KeyObject } from 'node:crypto';
import { b64urlDecode, b64urlEncode } from '../util.js';

export const TOKEN_PREFIX = 'MZL1';

export type LicenseKind = 'perpetual' | 'subscription' | 'trial';

/**
 * Claims embedded in a signed device token. Clients (macOS/iOS/Android) verify the
 * Ed25519 signature offline with the embedded public key, then apply these rules:
 *  - kind=perpetual: valid forever for builds whose release date <= `upd`; `exp` only
 *    governs when the client should try to refresh (heartbeat), not entitlement.
 *  - kind=subscription: entitled while now < `sub_exp` (period end + grace).
 *  - kind=trial: entitled while now < `sub_exp`.
 *  - `dev` must equal the local device id; `features` gates premium tools.
 */
export interface LicenseClaims {
  v: 1;
  kid: string;
  lid: string;
  kind: LicenseKind;
  plan: string;
  product: string;
  features: string[];
  dev: string;
  max_dev: number;
  iat: number;
  exp: number;
  sub_exp?: number;
  upd?: number;
}

export function signLicenseToken(claims: LicenseClaims, privateKey: KeyObject): string {
  const payload = b64urlEncode(JSON.stringify(claims));
  const signingInput = `${TOKEN_PREFIX}.${payload}`;
  const sig = sign(null, Buffer.from(signingInput, 'utf8'), privateKey);
  return `${signingInput}.${b64urlEncode(sig)}`;
}

export class TokenError extends Error {
  constructor(message: string, public readonly code: string) {
    super(message);
    this.name = 'TokenError';
  }
}

export function decodeLicenseTokenUnverified(token: string): LicenseClaims {
  const parts = token.split('.');
  if (parts.length !== 3 || parts[0] !== TOKEN_PREFIX) throw new TokenError('malformed token', 'malformed');
  try {
    return JSON.parse(b64urlDecode(parts[1]!).toString('utf8')) as LicenseClaims;
  } catch {
    throw new TokenError('malformed payload', 'malformed');
  }
}

export function verifyLicenseToken(token: string, publicKey: KeyObject, now?: number): LicenseClaims {
  const parts = token.split('.');
  if (parts.length !== 3 || parts[0] !== TOKEN_PREFIX) throw new TokenError('malformed token', 'malformed');
  const signingInput = `${parts[0]}.${parts[1]}`;
  const ok = verify(null, Buffer.from(signingInput, 'utf8'), publicKey, b64urlDecode(parts[2]!));
  if (!ok) throw new TokenError('bad signature', 'bad_signature');
  const claims = decodeLicenseTokenUnverified(token);
  if (claims.v !== 1) throw new TokenError('unsupported version', 'version');
  if (now !== undefined && claims.exp < now) throw new TokenError('token expired', 'expired');
  return claims;
}
