import { createPrivateKey, createPublicKey, generateKeyPairSync, type KeyObject } from 'node:crypto';
import { sha256Hex } from '../util.js';

export interface SigningKeys {
  privateKey: KeyObject;
  publicKey: KeyObject;
  /** Key id derived from the raw public key; embedded in tokens so clients can rotate. */
  kid: string;
}

export function generateSigningKeys(): SigningKeys {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  return { privateKey, publicKey, kid: kidFor(publicKey) };
}

export function loadSigningKeys(pkcs8Pem: string): SigningKeys {
  const privateKey = createPrivateKey(pkcs8Pem);
  if (privateKey.asymmetricKeyType !== 'ed25519') {
    throw new Error(`LICENSE_SIGNING_KEY_PEM must be an Ed25519 key, got ${privateKey.asymmetricKeyType}`);
  }
  const publicKey = createPublicKey(privateKey);
  return { privateKey, publicKey, kid: kidFor(publicKey) };
}

export function exportPrivatePem(key: KeyObject): string {
  return key.export({ type: 'pkcs8', format: 'pem' }) as string;
}

export function exportPublicPem(key: KeyObject): string {
  return key.export({ type: 'spki', format: 'pem' }) as string;
}

/** Raw 32-byte Ed25519 public key, base64url (what the Swift/Kotlin clients embed). */
export function publicKeyRawB64Url(pub: KeyObject): string {
  const jwk = pub.export({ format: 'jwk' }) as { x?: string };
  if (!jwk.x) throw new Error('not an OKP key');
  return jwk.x;
}

export function publicKeyJwk(pub: KeyObject): Record<string, string> {
  return { kty: 'OKP', crv: 'Ed25519', x: publicKeyRawB64Url(pub), use: 'sig', alg: 'EdDSA', kid: kidFor(pub) };
}

export function publicKeyFromRawB64Url(x: string): KeyObject {
  return createPublicKey({ key: { kty: 'OKP', crv: 'Ed25519', x }, format: 'jwk' });
}

export function kidFor(pub: KeyObject): string {
  return sha256Hex(publicKeyRawB64Url(pub)).slice(0, 16);
}
