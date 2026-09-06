/**
 * Generates cross-language test fixtures so the Rust core, Swift kit and Android core
 * verify the exact same tokens/keys the server produces.
 * Usage: npx tsx src/tools/fixtures.ts [outFile]
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { KEY_ALPHABET, formatKey, generateLicenseKey, normalizeLicenseKey } from '../license/keyformat.js';
import { generateSigningKeys, publicKeyRawB64Url } from '../license/keys.js';
import { signLicenseToken, type LicenseClaims } from '../license/token.js';
import { DAY } from '../util.js';

const out = resolve(process.argv[2] ?? '../core/tests/fixtures/license-fixtures.json');
const keys = generateSigningKeys();
const other = generateSigningKeys();
const NOW = 1_800_000_000; // 2027-01-15T08:00:00Z, fixed so tests are deterministic
const DEVICE = 'device-fixture-0001';

const base = { v: 1 as const, kid: keys.kid, product: 'mirrorz', dev: DEVICE, iat: NOW, max_dev: 3 };
const tokens: Array<{ name: string; token: string; expect: Record<string, unknown> }> = [];
const add = (name: string, claims: LicenseClaims, signer = keys.privateKey, expect: Record<string, unknown>) => {
  tokens.push({ name, token: signLicenseToken(claims, signer), expect });
};

add('perpetual-standard', { ...base, lid: 'lic_perp', kind: 'perpetual', plan: 'standard', features: ['vm', 'bottles', 'no-ads'], exp: NOW + 30 * DAY, upd: NOW + 365 * DAY }, keys.privateKey,
  { valid: true, entitled_at_now: true, mode_at_now: 'full', mode_after_updates_window: 'updates_expired', entitled_after_updates_window: true });
add('subscription-pro-active', { ...base, lid: 'lic_sub', kind: 'subscription', plan: 'pro', features: ['vm', 'cli'], exp: NOW + 30 * DAY, sub_exp: NOW + 37 * DAY }, keys.privateKey,
  { valid: true, entitled_at_now: true, mode_at_now: 'full', entitled_at: { [NOW + 36 * DAY]: true, [NOW + 38 * DAY]: false } });
add('trial', { ...base, lid: 'lic_trial', kind: 'trial', plan: 'trial', features: ['vm'], exp: NOW + 14 * DAY, sub_exp: NOW + 14 * DAY }, keys.privateKey,
  { valid: true, entitled_at_now: true, entitled_at: { [NOW + 15 * DAY]: false } });
add('wrong-device', { ...base, lid: 'lic_dev', kind: 'perpetual', plan: 'standard', features: [], dev: 'device-other', exp: NOW + DAY, upd: NOW + DAY }, keys.privateKey,
  { valid: false, error: 'device_mismatch' });
add('unknown-kid', { ...base, kid: 'nope', lid: 'lic_kid', kind: 'perpetual', plan: 'standard', features: [], exp: NOW + DAY, upd: NOW + DAY }, keys.privateKey,
  { valid: false, error: 'unknown_kid' });
add('foreign-signer', { ...base, lid: 'lic_foreign', kind: 'perpetual', plan: 'standard', features: [], exp: NOW + DAY, upd: NOW + DAY }, other.privateKey,
  { valid: false, error: 'bad_signature' });

// tampered payload with the original signature
const t = tokens[0]!.token.split('.') as [string, string, string];
const forged = Buffer.from(JSON.stringify({ ...JSON.parse(Buffer.from(t[1], 'base64url').toString('utf8')), plan: 'pro' })).toString('base64url');
tokens.push({ name: 'tampered', token: `${t[0]}.${forged}.${t[2]}`, expect: { valid: false, error: 'bad_signature' } });
tokens.push({ name: 'malformed', token: 'MZL1.abc', expect: { valid: false, error: 'malformed' } });

const validKeys = Array.from({ length: 50 }, () => generateLicenseKey());
const invalidKeys: string[] = ['', 'MZ-AAAAA', 'MZ-UUUUU-UUUUU-UUUUU-UUUUU-UUUUU', 'not a key'];
for (const k of validKeys.slice(0, 16)) {
  const c = normalizeLicenseKey(k)!;
  const pos = validKeys.indexOf(k) % c.length;
  const alt = KEY_ALPHABET[(KEY_ALPHABET.indexOf(c[pos]!) + 1) % KEY_ALPHABET.length]!;
  invalidKeys.push(formatKey(c.slice(0, pos) + alt + c.slice(pos + 1)));
}
const sloppy = validKeys.slice(0, 10).map((k) => ({ input: k.toLowerCase().replace(/-/g, ' ').replace(/0/g, 'o').replace(/1/g, 'l'), normalized: normalizeLicenseKey(k) }));

const fixtures = {
  generated_by: 'server/src/tools/fixtures.ts',
  now: NOW,
  device_id: DEVICE,
  trusted_keys: [{ kid: keys.kid, x: publicKeyRawB64Url(keys.publicKey) }],
  untrusted_key: { kid: other.kid, x: publicKeyRawB64Url(other.publicKey) },
  tokens,
  license_keys: { valid: validKeys, invalid: invalidKeys, normalization: sloppy },
};
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(fixtures, null, 2) + '\n');
console.log(`wrote ${out}: ${tokens.length} tokens, ${validKeys.length} valid keys, ${invalidKeys.length} invalid keys`);
