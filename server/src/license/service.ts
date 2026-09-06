import type { Db } from '../db.js';
import { logEvent } from '../db.js';
import { DAY, HttpError, emailHash, nowSec, randomId, sha256Hex } from '../util.js';
import { generateLicenseKey, normalizeLicenseKey } from './keyformat.js';
import type { SigningKeys } from './keys.js';
import { featuresFor } from './plans.js';
import { signLicenseToken, TokenError, verifyLicenseToken, type LicenseClaims, type LicenseKind } from './token.js';

export type LicenseStatus = 'active' | 'expired' | 'revoked' | 'refunded' | 'paused';
export type LicenseSource = 'stripe' | 'apple' | 'google' | 'manual' | 'trial';

export interface LicenseRow {
  id: string;
  key_hash: string;
  kind: LicenseKind;
  plan: string;
  product: string;
  status: LicenseStatus;
  source: LicenseSource;
  source_ref: string | null;
  email_hash: string | null;
  max_devices: number;
  issued_at: number;
  expires_at: number | null;
  updates_until: number | null;
  auto_renew: number;
  updated_at: number;
}

export interface ActivationRow {
  id: string;
  license_id: string;
  device_id: string;
  device_name: string | null;
  platform: string | null;
  os_version: string | null;
  app_version: string | null;
  activated_at: number;
  last_seen_at: number;
  revoked_at: number | null;
}

export interface DeviceInfo {
  id: string;
  name?: string;
  platform?: string;
  os_version?: string;
  app_version?: string;
}

export interface IssueInput {
  kind: LicenseKind;
  plan: string;
  source: LicenseSource;
  sourceRef?: string;
  email?: string;
  maxDevices?: number;
  expiresAt?: number;
  autoRenew?: boolean;
  product?: string;
}

export interface Entitlement {
  entitled: boolean;
  reason: string;
  kind: LicenseKind;
  plan: string;
  features: string[];
  subscriptionEndsAt?: number;
  updatesUntil?: number;
}

export interface ServiceOptions {
  graceDays: number;
  perpetualUpdateDays: number;
  tokenTtlDays: number;
  deviceLimits: Record<string, number>;
}

export interface PublicLicenseView {
  id: string;
  kind: LicenseKind;
  plan: string;
  status: LicenseStatus;
  max_devices: number;
  issued_at: number;
  expires_at: number | null;
  updates_until: number | null;
  auto_renew: boolean;
  devices: Array<{ device_id: string; device_name: string | null; platform: string | null; activated_at: number; last_seen_at: number }>;
  entitlement: Entitlement;
}

export class LicenseService {
  constructor(
    private readonly db: Db,
    private readonly keys: SigningKeys,
    private readonly opts: ServiceOptions,
    private readonly clock: () => number = nowSec,
  ) {}

  // ---------- issuance ----------

  issue(input: IssueInput): { license: LicenseRow; key: string } {
    const now = this.clock();
    const key = generateLicenseKey();
    const normalized = normalizeLicenseKey(key)!;
    const id = randomId('lic');
    const maxDevices = input.maxDevices ?? this.opts.deviceLimits[input.plan] ?? 3;
    const updatesUntil = input.kind === 'perpetual' ? now + this.opts.perpetualUpdateDays * DAY : null;
    const expiresAt = input.kind === 'perpetual' ? null : (input.expiresAt ?? null);
    this.db
      .prepare(
        `INSERT INTO licenses (id, key_hash, kind, plan, product, status, source, source_ref, email_hash, max_devices,
           issued_at, expires_at, updates_until, auto_renew, updated_at)
         VALUES (?, ?, ?, ?, ?, 'active', ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(
        id,
        sha256Hex(normalized),
        input.kind,
        input.plan,
        input.product ?? 'mirrorz',
        input.source,
        input.sourceRef ?? null,
        emailHash(input.email),
        maxDevices,
        now,
        expiresAt,
        updatesUntil,
        input.autoRenew ? 1 : 0,
        now,
      );
    logEvent(this.db, 'license.issued', id, { kind: input.kind, plan: input.plan, source: input.source }, now);
    return { license: this.getById(id)!, key };
  }

  /** Idempotent upsert keyed by (source, sourceRef) — used by billing webhooks. */
  upsertFromBilling(input: IssueInput & { sourceRef: string; status?: LicenseStatus }): { license: LicenseRow; key: string | null; created: boolean } {
    const existing = this.findBySourceRef(input.source, input.sourceRef);
    if (!existing) {
      const { license, key } = this.issue(input);
      if (input.status && input.status !== 'active') this.update(license.id, { status: input.status });
      return { license: this.getById(license.id)!, key, created: true };
    }
    this.update(existing.id, {
      status: input.status ?? existing.status,
      expiresAt: input.expiresAt ?? existing.expires_at ?? undefined,
      autoRenew: input.autoRenew,
      plan: input.plan,
    });
    return { license: this.getById(existing.id)!, key: null, created: false };
  }

  update(licenseId: string, patch: { status?: LicenseStatus; expiresAt?: number | null; autoRenew?: boolean; plan?: string; maxDevices?: number }): LicenseRow {
    const cur = this.getById(licenseId);
    if (!cur) throw new HttpError(404, 'license not found', 'not_found');
    const now = this.clock();
    const status = patch.status ?? cur.status;
    const expiresAt = patch.expiresAt === undefined ? cur.expires_at : patch.expiresAt;
    const autoRenew = patch.autoRenew === undefined ? cur.auto_renew : patch.autoRenew ? 1 : 0;
    const plan = patch.plan ?? cur.plan;
    const maxDevices = patch.maxDevices ?? cur.max_devices;
    this.db
      .prepare('UPDATE licenses SET status = ?, expires_at = ?, auto_renew = ?, plan = ?, max_devices = ?, updated_at = ? WHERE id = ?')
      .run(status, expiresAt, autoRenew, plan, maxDevices, now, licenseId);
    if (status !== cur.status) logEvent(this.db, `license.${status}`, licenseId, patch, now);
    return this.getById(licenseId)!;
  }

  revoke(licenseId: string, reason: string, status: LicenseStatus = 'revoked'): LicenseRow {
    const now = this.clock();
    this.db.prepare('UPDATE activations SET revoked_at = ? WHERE license_id = ? AND revoked_at IS NULL').run(now, licenseId);
    const row = this.update(licenseId, { status });
    logEvent(this.db, 'license.revoked', licenseId, { reason, status }, now);
    return row;
  }

  /**
   * Free trial: one per device id, ever. Bound to the device so a reinstall does not reset it.
   * The synthetic key is derived from the device id so the client can re-activate without storing it.
   */
  startTrial(device: DeviceInfo, days = 14): { token: string; license: PublicLicenseView; existing: boolean } {
    const ref = `trial:${sha256Hex(device.id)}`;
    const existing = this.findBySourceRef('trial', ref);
    if (existing) {
      const ent = this.entitlement(existing);
      if (!ent.entitled) throw new HttpError(403, `trial already used on this device (${ent.reason})`, 'trial_used');
      return { ...this.activateById(existing.id, device), existing: true };
    }
    const now = this.clock();
    const { license } = this.issue({ kind: 'trial', plan: 'trial', source: 'trial', sourceRef: ref, maxDevices: 1, expiresAt: now + days * DAY });
    return { ...this.activateById(license.id, device), existing: false };
  }

  // ---------- lookup ----------

  getById(id: string): LicenseRow | undefined {
    return this.db.prepare('SELECT * FROM licenses WHERE id = ?').get(id) as LicenseRow | undefined;
  }

  findByKey(key: string): LicenseRow | undefined {
    const normalized = normalizeLicenseKey(key);
    if (!normalized) return undefined;
    return this.db.prepare('SELECT * FROM licenses WHERE key_hash = ?').get(sha256Hex(normalized)) as LicenseRow | undefined;
  }

  findBySourceRef(source: LicenseSource, ref: string): LicenseRow | undefined {
    return this.db.prepare('SELECT * FROM licenses WHERE source = ? AND source_ref = ?').get(source, ref) as LicenseRow | undefined;
  }

  listActivations(licenseId: string): ActivationRow[] {
    return this.db
      .prepare('SELECT * FROM activations WHERE license_id = ? AND revoked_at IS NULL ORDER BY activated_at ASC')
      .all(licenseId) as unknown as ActivationRow[];
  }

  // ---------- entitlement ----------

  entitlement(license: LicenseRow, now = this.clock()): Entitlement {
    const features = featuresFor(license.plan);
    const base = { kind: license.kind, plan: license.plan, features };
    if (license.status === 'revoked' || license.status === 'refunded') {
      return { entitled: false, reason: license.status, ...base, features: [] };
    }
    if (license.status === 'paused') {
      return { entitled: false, reason: 'paused', ...base, features: [] };
    }
    if (license.kind === 'perpetual') {
      return { entitled: true, reason: 'perpetual', ...base, updatesUntil: license.updates_until ?? undefined };
    }
    const grace = license.kind === 'subscription' ? this.opts.graceDays * DAY : 0;
    const endsAt = (license.expires_at ?? 0) + grace;
    if (now < endsAt) {
      return { entitled: true, reason: license.kind, ...base, subscriptionEndsAt: endsAt };
    }
    return { entitled: false, reason: 'expired', ...base, features: [], subscriptionEndsAt: endsAt };
  }

  // ---------- activation / tokens ----------

  activate(key: string, device: DeviceInfo): { token: string; license: PublicLicenseView } {
    const license = this.findByKey(key);
    if (!license) throw new HttpError(404, 'license key not found', 'not_found');
    return this.activateLicense(license, device);
  }

  /** Store purchases (Apple/Google) are bound without a typed key: activate by verified license id. */
  activateById(licenseId: string, device: DeviceInfo): { token: string; license: PublicLicenseView } {
    const license = this.getById(licenseId);
    if (!license) throw new HttpError(404, 'license not found', 'not_found');
    return this.activateLicense(license, device);
  }

  private activateLicense(license: LicenseRow, device: DeviceInfo): { token: string; license: PublicLicenseView } {
    if (!device?.id || typeof device.id !== 'string' || device.id.length < 8 || device.id.length > 200) {
      throw new HttpError(400, 'device.id is required (8-200 chars)', 'bad_device');
    }
    const ent = this.entitlement(license);
    if (!ent.entitled) throw new HttpError(403, `license is not entitled: ${ent.reason}`, ent.reason);

    const now = this.clock();
    const existing = this.db
      .prepare('SELECT * FROM activations WHERE license_id = ? AND device_id = ?')
      .get(license.id, device.id) as ActivationRow | undefined;

    if (existing && existing.revoked_at === null) {
      this.touch(existing.id, device, now);
    } else {
      const active = this.listActivations(license.id).length;
      if (active >= license.max_devices) {
        throw new HttpError(409, `device limit reached (${license.max_devices}); deactivate another device first`, 'device_limit');
      }
      if (existing) {
        this.db
          .prepare('UPDATE activations SET revoked_at = NULL, activated_at = ?, last_seen_at = ?, device_name = ?, platform = ?, os_version = ?, app_version = ? WHERE id = ?')
          .run(now, now, device.name ?? null, device.platform ?? null, device.os_version ?? null, device.app_version ?? null, existing.id);
      } else {
        this.db
          .prepare(
            'INSERT INTO activations (id, license_id, device_id, device_name, platform, os_version, app_version, activated_at, last_seen_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          )
          .run(randomId('act'), license.id, device.id, device.name ?? null, device.platform ?? null, device.os_version ?? null, device.app_version ?? null, now, now);
      }
      logEvent(this.db, 'device.activated', license.id, { device_id: device.id, platform: device.platform }, now);
    }
    return { token: this.mintToken(license, device.id, now), license: this.view(license) };
  }

  refresh(token: string): { token: string; license: PublicLicenseView } {
    let claims: LicenseClaims;
    try {
      // Allow refreshing an expired token: entitlement is re-checked against the DB below.
      claims = verifyLicenseToken(token, this.keys.publicKey);
    } catch (e) {
      throw new HttpError(401, e instanceof TokenError ? e.message : 'invalid token', 'bad_token');
    }
    const license = this.getById(claims.lid);
    if (!license) throw new HttpError(404, 'license not found', 'not_found');
    const act = this.db
      .prepare('SELECT * FROM activations WHERE license_id = ? AND device_id = ? AND revoked_at IS NULL')
      .get(license.id, claims.dev) as ActivationRow | undefined;
    if (!act) throw new HttpError(403, 'device is not activated on this license', 'not_activated');
    const ent = this.entitlement(license);
    if (!ent.entitled) throw new HttpError(403, `license is not entitled: ${ent.reason}`, ent.reason);
    const now = this.clock();
    this.touch(act.id, { id: claims.dev }, now);
    return { token: this.mintToken(license, claims.dev, now), license: this.view(license) };
  }

  deactivate(licenseId: string, deviceId: string): boolean {
    const now = this.clock();
    const res = this.db
      .prepare('UPDATE activations SET revoked_at = ? WHERE license_id = ? AND device_id = ? AND revoked_at IS NULL')
      .run(now, licenseId, deviceId);
    if (res.changes > 0) logEvent(this.db, 'device.deactivated', licenseId, { device_id: deviceId }, now);
    return res.changes > 0;
  }

  view(license: LicenseRow): PublicLicenseView {
    const fresh = this.getById(license.id) ?? license;
    return {
      id: fresh.id,
      kind: fresh.kind,
      plan: fresh.plan,
      status: fresh.status,
      max_devices: fresh.max_devices,
      issued_at: fresh.issued_at,
      expires_at: fresh.expires_at,
      updates_until: fresh.updates_until,
      auto_renew: fresh.auto_renew === 1,
      devices: this.listActivations(fresh.id).map((a) => ({
        device_id: a.device_id,
        device_name: a.device_name,
        platform: a.platform,
        activated_at: a.activated_at,
        last_seen_at: a.last_seen_at,
      })),
      entitlement: this.entitlement(fresh),
    };
  }

  private touch(activationId: string, device: DeviceInfo, now: number): void {
    this.db
      .prepare(
        'UPDATE activations SET last_seen_at = ?, device_name = COALESCE(?, device_name), platform = COALESCE(?, platform), os_version = COALESCE(?, os_version), app_version = COALESCE(?, app_version) WHERE id = ?',
      )
      .run(now, device.name ?? null, device.platform ?? null, device.os_version ?? null, device.app_version ?? null, activationId);
  }

  private mintToken(license: LicenseRow, deviceId: string, now: number): string {
    const ent = this.entitlement(license, now);
    const claims: LicenseClaims = {
      v: 1,
      kid: this.keys.kid,
      lid: license.id,
      kind: license.kind,
      plan: license.plan,
      product: license.product,
      features: ent.features,
      dev: deviceId,
      max_dev: license.max_devices,
      iat: now,
      exp: now + this.opts.tokenTtlDays * DAY,
    };
    if (ent.subscriptionEndsAt !== undefined) claims.sub_exp = ent.subscriptionEndsAt;
    if (ent.updatesUntil !== undefined) claims.upd = ent.updatesUntil;
    return signLicenseToken(claims, this.keys.privateKey);
  }
}
