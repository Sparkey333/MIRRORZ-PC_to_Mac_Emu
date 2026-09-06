import assert from 'node:assert/strict';
import { test } from 'node:test';
import { KEY_ALPHABET, formatKey, generateLicenseKey, isValidLicenseKey, normalizeLicenseKey } from './keyformat.js';

test('generated keys are well-formed and validate', () => {
  for (let i = 0; i < 200; i++) {
    const key = generateLicenseKey();
    assert.match(key, /^MZ(-[0-9A-HJKMNP-TV-Z]{5}){5}$/);
    assert.ok(isValidLicenseKey(key), key);
  }
});

test('normalization tolerates case, separators and look-alike characters', () => {
  const key = generateLicenseKey();
  const canonical = normalizeLicenseKey(key)!;
  const sloppy = key.toLowerCase().replace(/-/g, ' ').replace(/0/g, 'o').replace(/1/g, 'l');
  assert.equal(normalizeLicenseKey(sloppy), canonical);
  assert.equal(normalizeLicenseKey(`  ${key.replace(/-/g, '_')} `), canonical);
});

test('a single wrong symbol is rejected by the check digit', () => {
  const key = generateLicenseKey();
  const canonical = normalizeLicenseKey(key)!;
  let rejected = 0;
  for (let pos = 0; pos < canonical.length; pos++) {
    const orig = canonical[pos]!;
    const alt = KEY_ALPHABET[(KEY_ALPHABET.indexOf(orig) + 1) % KEY_ALPHABET.length]!;
    const mutated = canonical.slice(0, pos) + alt + canonical.slice(pos + 1);
    if (!isValidLicenseKey(formatKey(mutated))) rejected++;
  }
  assert.equal(rejected, canonical.length);
});

test('garbage is rejected', () => {
  assert.equal(normalizeLicenseKey(''), null);
  assert.equal(normalizeLicenseKey('MZ-AAAAA'), null);
  assert.equal(normalizeLicenseKey('MZ-UUUUU-UUUUU-UUUUU-UUUUU-UUUUU'), null);
  assert.equal(normalizeLicenseKey((123 as unknown) as string), null);
});
