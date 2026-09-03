import { createHash, randomBytes } from 'node:crypto';

export const DAY = 86_400;

export function nowSec(): number {
  return Math.floor(Date.now() / 1000);
}

export function sha256Hex(input: string | Uint8Array): string {
  return createHash('sha256').update(input).digest('hex');
}

export function b64urlEncode(input: Uint8Array | string): string {
  return Buffer.from(input).toString('base64url');
}

export function b64urlDecode(input: string): Buffer {
  return Buffer.from(input, 'base64url');
}

export function randomId(prefix: string): string {
  return `${prefix}_${randomBytes(12).toString('base64url')}`;
}

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly code: string = 'error',
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export function assert(cond: unknown, status: number, message: string, code = 'bad_request'): asserts cond {
  if (!cond) throw new HttpError(status, message, code);
}

/** Normalizes an email for hashing: trim + lowercase. We never store raw emails. */
export function emailHash(email: string | undefined | null): string | null {
  if (!email) return null;
  return sha256Hex(email.trim().toLowerCase());
}
