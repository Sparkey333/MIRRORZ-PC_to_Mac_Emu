import assert from 'node:assert/strict';
import { test } from 'node:test';
import { generateSigningKeys, publicKeyFromRawB64Url, publicKeyRawB64Url } from './keys.js';
import { decodeLicenseTokenUnverified, signLicenseToken, verifyLicenseToken, type LicenseClaims } from './token.js';

const claims: LicenseClaims = {
  v: 1, kid: 'k', lid: 'lic_1', kind: 'perpetual', plan: 'standard', product: 'mirrorz',
  features: ['vm'], dev: 'device-1234', max_dev: 3, iat: 1000, exp: 2000, upd: 5000,
};

test('sign/verify roundtrip with the raw public key a client would embed', () => {
  const keys = generateSigningKeys();
  const token = signLicenseToken(claims, keys.privateKey);
  assert.ok(token.startsWith('MZL1.'));
  const clientKey = publicKeyFromRawB64Url(publicKeyRawB64Url(keys.publicKey));
  assert.deepEqual(verifyLicenseToken(token, clientKey, 1500), claims);
  assert.deepEqual(decodeLicenseTokenUnverified(token), claims);
});

test('tampering and wrong keys are rejected', () => {
  const keys = generateSigningKeys();
  const other = generateSigningKeys();
  const token = signLicenseToken(claims, keys.privateKey);
  assert.throws(() => verifyLicenseToken(token, other.publicKey), /bad signature/);
  const [h, p, s] = token.split('.') as [string, string, string];
  const forged = Buffer.from(JSON.stringify({ ...claims, plan: 'pro' })).toString('base64url');
  assert.throws(() => verifyLicenseToken(`${h}.${forged}.${s}`, keys.publicKey), /bad signature/);
  assert.throws(() => verifyLicenseToken(`X.${p}.${s}`, keys.publicKey), /malformed/);
  assert.throws(() => verifyLicenseToken(token, keys.publicKey, 3000), /expired/);
});
