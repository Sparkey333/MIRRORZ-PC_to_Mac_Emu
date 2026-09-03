import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

export type Db = DatabaseSync;

const SCHEMA = `
CREATE TABLE IF NOT EXISTS licenses (
  id TEXT PRIMARY KEY,
  key_hash TEXT UNIQUE NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('perpetual','subscription','trial')),
  plan TEXT NOT NULL,
  product TEXT NOT NULL DEFAULT 'mirrorz',
  status TEXT NOT NULL CHECK (status IN ('active','expired','revoked','refunded','paused')),
  source TEXT NOT NULL,
  source_ref TEXT,
  email_hash TEXT,
  max_devices INTEGER NOT NULL DEFAULT 3,
  issued_at INTEGER NOT NULL,
  expires_at INTEGER,
  updates_until INTEGER,
  auto_renew INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS licenses_source_ref ON licenses (source, source_ref);
CREATE INDEX IF NOT EXISTS licenses_email ON licenses (email_hash);

CREATE TABLE IF NOT EXISTS activations (
  id TEXT PRIMARY KEY,
  license_id TEXT NOT NULL REFERENCES licenses(id),
  device_id TEXT NOT NULL,
  device_name TEXT,
  platform TEXT,
  os_version TEXT,
  app_version TEXT,
  activated_at INTEGER NOT NULL,
  last_seen_at INTEGER NOT NULL,
  revoked_at INTEGER,
  UNIQUE (license_id, device_id)
);

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  at INTEGER NOT NULL,
  type TEXT NOT NULL,
  license_id TEXT,
  payload TEXT
);

CREATE TABLE IF NOT EXISTS processed_notifications (
  id TEXT PRIMARY KEY,
  source TEXT NOT NULL,
  at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS compat_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  at INTEGER NOT NULL,
  app_id TEXT NOT NULL,
  app_version TEXT,
  runtime TEXT,
  result TEXT NOT NULL CHECK (result IN ('works','works_with_fixups','partial','broken')),
  mac_model TEXT,
  macos_version TEXT,
  mirrorz_version TEXT,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS compat_reports_app ON compat_reports (app_id);
`;

export function openDb(path: string): Db {
  if (path !== ':memory:') mkdirSync(dirname(path), { recursive: true });
  const db = new DatabaseSync(path);
  db.exec('PRAGMA journal_mode = WAL;');
  db.exec('PRAGMA foreign_keys = ON;');
  db.exec(SCHEMA);
  return db;
}

export function logEvent(db: Db, type: string, licenseId: string | null, payload: unknown, at: number): void {
  db.prepare('INSERT INTO events (at, type, license_id, payload) VALUES (?, ?, ?, ?)').run(
    at,
    type,
    licenseId,
    payload === undefined ? null : JSON.stringify(payload),
  );
}
