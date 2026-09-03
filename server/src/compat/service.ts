import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Db } from '../db.js';
import { HttpError, nowSec } from '../util.js';

export type CompatRuntime = 'vm' | 'bottle' | 'either';
export type CompatRating = 'gold' | 'silver' | 'bronze' | 'broken' | 'n/a';

export interface CompatFixup {
  type: string;
  key?: string;
  value?: string;
  reason?: string;
  optional?: boolean;
}

export interface CompatApp {
  id: string;
  name: string;
  vendor: string;
  category: string;
  runtime: CompatRuntime;
  rating: CompatRating;
  versions?: string[];
  arch?: string;
  vendor_support?: string;
  notes?: string;
  requirements?: Record<string, unknown>;
  fixups: CompatFixup[];
}

export interface CompatSeed {
  version: string;
  runtimes: Record<string, string>;
  apps: CompatApp[];
  presets: Record<string, unknown>;
}

export interface CompatReport {
  app_id: string;
  app_version?: string;
  runtime?: CompatRuntime;
  result: 'works' | 'works_with_fixups' | 'partial' | 'broken';
  mac_model?: string;
  macos_version?: string;
  mirrorz_version?: string;
  notes?: string;
}

export function loadSeed(path?: string): CompatSeed {
  const file = path ?? join(dirname(fileURLToPath(import.meta.url)), 'seed.json');
  return JSON.parse(readFileSync(file, 'utf8')) as CompatSeed;
}

/**
 * Compatibility database: curated app profiles (seed.json) plus opt-in community reports.
 * Reports are anonymous by construction: we never accept identifiers, only hardware class + result.
 */
export class CompatService {
  constructor(
    private readonly db: Db,
    private readonly seed: CompatSeed = loadSeed(),
    private readonly clock: () => number = nowSec,
  ) {}

  version(): string {
    return this.seed.version;
  }

  presets(): Record<string, unknown> {
    return this.seed.presets;
  }

  search(q?: string, category?: string, runtime?: string): CompatApp[] {
    const needle = q?.trim().toLowerCase();
    return this.seed.apps.filter((a) => {
      if (category && a.category !== category) return false;
      if (runtime && a.runtime !== runtime && a.runtime !== 'either') return false;
      if (!needle) return true;
      return a.id.includes(needle) || a.name.toLowerCase().includes(needle) || a.vendor.toLowerCase().includes(needle);
    });
  }

  get(id: string): CompatApp & { community: CommunityStats } {
    const app = this.seed.apps.find((a) => a.id === id);
    if (!app) throw new HttpError(404, `unknown app ${id}`, 'not_found');
    return { ...app, community: this.stats(id) };
  }

  stats(appId: string): CommunityStats {
    const rows = this.db
      .prepare('SELECT result, COUNT(*) AS n FROM compat_reports WHERE app_id = ? GROUP BY result')
      .all(appId) as Array<{ result: CompatReport['result']; n: number }>;
    const out: CommunityStats = { works: 0, works_with_fixups: 0, partial: 0, broken: 0, total: 0 };
    for (const r of rows) {
      out[r.result] = r.n;
      out.total += r.n;
    }
    return out;
  }

  report(r: CompatReport): { accepted: true } {
    if (!this.seed.apps.some((a) => a.id === r.app_id)) throw new HttpError(404, `unknown app ${r.app_id}`, 'not_found');
    for (const f of [r.app_version, r.mac_model, r.macos_version, r.mirrorz_version, r.notes]) {
      if (f !== undefined && (typeof f !== 'string' || f.length > 500)) throw new HttpError(400, 'field too long', 'bad_request');
    }
    this.db
      .prepare(
        'INSERT INTO compat_reports (at, app_id, app_version, runtime, result, mac_model, macos_version, mirrorz_version, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      )
      .run(this.clock(), r.app_id, r.app_version ?? null, r.runtime ?? null, r.result, r.mac_model ?? null, r.macos_version ?? null, r.mirrorz_version ?? null, r.notes ?? null);
    return { accepted: true };
  }

  /**
   * Heuristic used by the desktop "App Router" when a user drops an unknown installer:
   * pick a runtime from file metadata. Mirrors the Rust core implementation; kept here so the
   * mobile companions and the website can show the same decision.
   */
  routeUnknown(meta: { arch?: 'x86' | 'x64' | 'arm64'; needs_driver?: boolean; needs_service?: boolean; dotnet?: string; dx?: string }): { runtime: CompatRuntime; reason: string } {
    if (meta.needs_driver || meta.needs_service) return { runtime: 'vm', reason: 'kernel driver or Windows service required' };
    if (meta.dx === '12') return { runtime: 'vm', reason: 'DirectX 12 is more reliable in the VM path today' };
    if (meta.arch === 'arm64') return { runtime: 'vm', reason: 'ARM64-native Windows binaries run at full speed in the VM' };
    return { runtime: 'bottle', reason: 'Bottle first: fastest launch, no Windows license; VM fallback on failure' };
  }
}

export interface CommunityStats {
  works: number;
  works_with_fixups: number;
  partial: number;
  broken: number;
  total: number;
}
