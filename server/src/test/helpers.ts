import { execFileSync } from 'node:child_process';
import { createSign } from 'node:crypto';
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { openDb, type Db } from '../db.js';
import { generateSigningKeys, type SigningKeys } from '../license/keys.js';
import { LicenseService } from '../license/service.js';
import { b64urlEncode } from '../util.js';

export interface TestEnv {
  db: Db;
  keys: SigningKeys;
  licenses: LicenseService;
  clock: { now: number; advance(sec: number): void };
}

export function makeEnv(opts: Partial<{ graceDays: number; perpetualUpdateDays: number; tokenTtlDays: number }> = {}): TestEnv {
  const db = openDb(':memory:');
  const keys = generateSigningKeys();
  const clock = {
    now: 1_800_000_000, // 2027-01-15T08:00:00Z
    advance(sec: number) {
      this.now += sec;
    },
  };
  const licenses = new LicenseService(
    db,
    keys,
    {
      graceDays: opts.graceDays ?? 7,
      perpetualUpdateDays: opts.perpetualUpdateDays ?? 365,
      tokenTtlDays: opts.tokenTtlDays ?? 30,
      deviceLimits: { standard: 3, pro: 5, business: 10, trial: 1 },
    },
    () => clock.now,
  );
  return { db, keys, licenses, clock };
}

export function hasOpenssl(): boolean {
  try {
    execFileSync('openssl', ['version'], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

export interface TestChain {
  rootPem: string;
  x5c: string[]; // leaf, intermediate, root (DER base64)
  leafKeyPem: string;
  dir: string;
}

/** Builds a 3-tier EC P-256 chain with the openssl CLI (root → intermediate → leaf). */
export function makeChain(cn = 'MIRRORZ Test'): TestChain {
  const dir = mkdtempSync(join(tmpdir(), 'mz-chain-'));
  const run = (args: string[]) => execFileSync('openssl', args, { cwd: dir, stdio: ['ignore', 'pipe', 'pipe'] });
  writeFileSync(join(dir, 'ca.ext'), 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid:always\n');
  writeFileSync(join(dir, 'leaf.ext'), 'basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid:always\n');

  run(['ecparam', '-name', 'prime256v1', '-genkey', '-noout', '-out', 'root.key']);
  run(['req', '-x509', '-new', '-key', 'root.key', '-sha256', '-days', '3650', '-subj', `/CN=${cn} Root CA`, '-out', 'root.pem',
    '-addext', 'basicConstraints=critical,CA:TRUE', '-addext', 'keyUsage=critical,keyCertSign,cRLSign', '-addext', 'subjectKeyIdentifier=hash']);
  run(['ecparam', '-name', 'prime256v1', '-genkey', '-noout', '-out', 'int.key']);
  run(['req', '-new', '-key', 'int.key', '-subj', `/CN=${cn} Intermediate`, '-out', 'int.csr']);
  run(['x509', '-req', '-in', 'int.csr', '-CA', 'root.pem', '-CAkey', 'root.key', '-CAcreateserial', '-days', '3650', '-sha256', '-extfile', 'ca.ext', '-out', 'int.pem']);
  run(['ecparam', '-name', 'prime256v1', '-genkey', '-noout', '-out', 'leaf.key']);
  run(['req', '-new', '-key', 'leaf.key', '-subj', `/CN=${cn} Leaf`, '-out', 'leaf.csr']);
  run(['x509', '-req', '-in', 'leaf.csr', '-CA', 'int.pem', '-CAkey', 'int.key', '-CAcreateserial', '-days', '3650', '-sha256', '-extfile', 'leaf.ext', '-out', 'leaf.pem']);

  const der = (name: string) => run(['x509', '-in', name, '-outform', 'der']).toString('base64');
  // Convert the SEC1 EC key to PKCS#8 so node:crypto accepts it uniformly.
  run(['pkcs8', '-topk8', '-nocrypt', '-in', 'leaf.key', '-out', 'leaf.pk8']);
  return {
    rootPem: readFileSync(join(dir, 'root.pem'), 'utf8'),
    x5c: [der('leaf.pem'), der('int.pem'), der('root.pem')],
    leafKeyPem: readFileSync(join(dir, 'leaf.pk8'), 'utf8'),
    dir,
  };
}

/** Produces an ES256 JWS with an x5c header, the way Apple signs notifications and transactions. */
export function signJws(payload: unknown, chain: TestChain, x5c: string[] = chain.x5c): string {
  const header = b64urlEncode(JSON.stringify({ alg: 'ES256', x5c }));
  const body = b64urlEncode(JSON.stringify(payload));
  const sig = createSign('SHA256').update(`${header}.${body}`).sign({ key: chain.leafKeyPem, dsaEncoding: 'ieee-p1363' });
  return `${header}.${body}.${b64urlEncode(sig)}`;
}
