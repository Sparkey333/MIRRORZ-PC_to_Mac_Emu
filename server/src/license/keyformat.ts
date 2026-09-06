import { randomBytes } from 'node:crypto';

/**
 * Human-typed license keys.
 *
 * Format:  MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
 * Alphabet: Crockford base32 (no I, L, O, U) — unambiguous when read aloud or typed.
 * 24 random symbols (120 bits of entropy) + 1 check symbol (Luhn mod N, N = 32).
 * Keys are never stored in clear: the server keeps sha256(normalized key).
 */
export const KEY_ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const N = KEY_ALPHABET.length; // 32
const BODY_LEN = 24;
export const KEY_PREFIX = 'MZ';

function luhnModNCheck(body: string): string {
  // Standard Luhn mod N over the body, computing the check character.
  let factor = 2;
  let sum = 0;
  for (let i = body.length - 1; i >= 0; i--) {
    const code = KEY_ALPHABET.indexOf(body[i]!);
    let addend = factor * code;
    factor = factor === 2 ? 1 : 2;
    addend = Math.floor(addend / N) + (addend % N);
    sum += addend;
  }
  const remainder = sum % N;
  const checkCode = (N - remainder) % N;
  return KEY_ALPHABET[checkCode]!;
}

function luhnModNValid(full: string): boolean {
  let factor = 1;
  let sum = 0;
  for (let i = full.length - 1; i >= 0; i--) {
    const code = KEY_ALPHABET.indexOf(full[i]!);
    if (code < 0) return false;
    let addend = factor * code;
    factor = factor === 2 ? 1 : 2;
    addend = Math.floor(addend / N) + (addend % N);
    sum += addend;
  }
  return sum % N === 0;
}

export function generateLicenseKey(): string {
  const bytes = randomBytes(BODY_LEN);
  let body = '';
  for (let i = 0; i < BODY_LEN; i++) body += KEY_ALPHABET[bytes[i]! % N];
  const full = body + luhnModNCheck(body);
  return formatKey(full);
}

export function formatKey(symbols: string): string {
  const groups = symbols.match(/.{1,5}/g) ?? [];
  return `${KEY_PREFIX}-${groups.join('-')}`;
}

/**
 * Normalizes user input: uppercases, drops separators/whitespace, maps look-alikes
 * (O->0, I/L->1), strips the MZ prefix. Returns the 25-symbol canonical body or null.
 */
export function normalizeLicenseKey(input: string): string | null {
  if (typeof input !== 'string') return null;
  let s = input.toUpperCase().replace(/[\s\-_.]/g, '');
  s = s.replace(/O/g, '0').replace(/[IL]/g, '1');
  if (s.startsWith(KEY_PREFIX)) s = s.slice(KEY_PREFIX.length);
  if (s.length !== BODY_LEN + 1) return null;
  for (const ch of s) if (!KEY_ALPHABET.includes(ch)) return null;
  if (!luhnModNValid(s)) return null;
  return s;
}

export function isValidLicenseKey(input: string): boolean {
  return normalizeLicenseKey(input) !== null;
}
