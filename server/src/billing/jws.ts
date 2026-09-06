import { createVerify, X509Certificate } from 'node:crypto';
import { b64urlDecode } from '../util.js';

export interface JwsHeader {
  alg: string;
  x5c?: string[];
  kid?: string;
  typ?: string;
}

export interface VerifiedJws<T> {
  header: JwsHeader;
  payload: T;
  leaf: X509Certificate;
}

export class JwsError extends Error {
  constructor(message: string, public readonly code: string) {
    super(message);
    this.name = 'JwsError';
  }
}

export function decodeJwsUnverified<T = unknown>(jws: string): { header: JwsHeader; payload: T } {
  const parts = jws.split('.');
  if (parts.length !== 3) throw new JwsError('malformed JWS', 'malformed');
  try {
    return {
      header: JSON.parse(b64urlDecode(parts[0]!).toString('utf8')) as JwsHeader,
      payload: JSON.parse(b64urlDecode(parts[1]!).toString('utf8')) as T,
    };
  } catch {
    throw new JwsError('malformed JWS segments', 'malformed');
  }
}

export interface X5cVerifyOptions {
  /** PEM-encoded trust anchors. The last cert in x5c must chain to one of these. */
  rootCertsPem: string[];
  now?: Date;
  /** Expected leaf OID marker (Apple uses 1.2.840.113635.100.6.11.1 for receipt/notification signing). Optional. */
  requiredLeafOid?: string;
}

/**
 * Verifies a JWS whose header carries an x5c certificate chain (Apple App Store Server
 * Notifications v2, StoreKit 2 signed transactions). Steps:
 *   1. parse chain, check validity windows;
 *   2. each cert must be signed by the next; last must be signed by a pinned root;
 *   3. ES256 signature over `header.payload` verified with the leaf's public key.
 */
export function verifyJwsWithX5c<T = unknown>(jws: string, opts: X5cVerifyOptions): VerifiedJws<T> {
  const parts = jws.split('.');
  if (parts.length !== 3) throw new JwsError('malformed JWS', 'malformed');
  const { header, payload } = decodeJwsUnverified<T>(jws);
  if (header.alg !== 'ES256') throw new JwsError(`unsupported alg ${header.alg}`, 'alg');
  if (!header.x5c || header.x5c.length === 0) throw new JwsError('missing x5c', 'x5c');

  const chain = header.x5c.map((b64) => {
    try {
      return new X509Certificate(Buffer.from(b64, 'base64'));
    } catch {
      throw new JwsError('bad certificate in x5c', 'x5c');
    }
  });
  const roots = opts.rootCertsPem.map((pem) => new X509Certificate(pem));
  const now = opts.now ?? new Date();

  for (const cert of chain) {
    if (now < new Date(cert.validFrom) || now > new Date(cert.validTo)) {
      throw new JwsError(`certificate not valid at ${now.toISOString()}: ${cert.subject}`, 'cert_expired');
    }
  }
  for (let i = 0; i < chain.length - 1; i++) {
    const cert = chain[i]!;
    const issuer = chain[i + 1]!;
    if (!cert.checkIssued(issuer) || !cert.verify(issuer.publicKey)) {
      throw new JwsError(`chain break at index ${i}`, 'chain');
    }
  }
  const last = chain[chain.length - 1]!;
  const anchored = roots.some((root) => {
    if (root.fingerprint256 === last.fingerprint256) return true; // chain includes the root itself
    return last.checkIssued(root) && last.verify(root.publicKey);
  });
  if (!anchored) throw new JwsError('chain does not anchor to a trusted root', 'untrusted_root');

  const leaf = chain[0]!;
  if (opts.requiredLeafOid) {
    const text = leaf.toString();
    if (!text.includes(opts.requiredLeafOid)) {
      // Node prints unknown extensions by OID; Apple's marker OID appears in the textual dump.
      throw new JwsError('leaf certificate lacks required OID', 'leaf_oid');
    }
  }
  const signingInput = Buffer.from(`${parts[0]}.${parts[1]}`, 'utf8');
  const ok = createVerify('SHA256')
    .update(signingInput)
    .verify({ key: leaf.publicKey, dsaEncoding: 'ieee-p1363' }, b64urlDecode(parts[2]!));
  if (!ok) throw new JwsError('bad signature', 'bad_signature');
  return { header, payload, leaf };
}
