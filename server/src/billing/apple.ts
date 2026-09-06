import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Db } from '../db.js';
import { logEvent } from '../db.js';
import type { DeviceInfo, LicenseService, PublicLicenseView } from '../license/service.js';
import { HttpError, nowSec } from '../util.js';
import { JwsError, verifyJwsWithX5c } from './jws.js';
import { DEFAULT_PRODUCTS, type ProductMapping } from './products.js';

export interface AppleTransaction {
  originalTransactionId: string;
  transactionId: string;
  productId: string;
  bundleId: string;
  environment: 'Sandbox' | 'Production';
  type: 'Auto-Renewable Subscription' | 'Non-Consumable' | 'Consumable' | 'Non-Renewing Subscription';
  purchaseDate: number;
  expiresDate?: number;
  revocationDate?: number;
  revocationReason?: number;
  appAccountToken?: string;
  inAppOwnershipType?: string;
  webOrderLineItemId?: string;
}

export interface AppleRenewalInfo {
  originalTransactionId: string;
  autoRenewStatus: 0 | 1;
  autoRenewProductId?: string;
  expirationIntent?: number;
  gracePeriodExpiresDate?: number;
  isInBillingRetryPeriod?: boolean;
}

export interface AppleNotificationV2 {
  notificationType: string;
  subtype?: string;
  notificationUUID: string;
  version: string;
  signedDate: number;
  data?: {
    bundleId: string;
    environment: 'Sandbox' | 'Production';
    signedTransactionInfo?: string;
    signedRenewalInfo?: string;
  };
}

export interface AppleBillingOptions {
  bundleId: string;
  environment: 'Sandbox' | 'Production' | 'any';
  rootCertsPem?: string[];
  products?: Record<string, ProductMapping>;
  clock?: () => number;
}

/**
 * Apple Root CA - G3 is the trust anchor for App Store Server API / StoreKit 2 JWS chains.
 * It is NOT vendored: fetch it at deploy time with `scripts/fetch-apple-root.sh`
 * (https://www.apple.com/certificateauthority/AppleRootCA-G3.cer) or pass APPLE_ROOT_CA_PEM.
 */
export function appleRootCaG3Pem(): string {
  const fromEnv = process.env['APPLE_ROOT_CA_PEM'];
  if (fromEnv) return fromEnv;
  const here = dirname(fileURLToPath(import.meta.url));
  const file = process.env['APPLE_ROOT_CA_FILE'] ?? join(here, 'certs', 'AppleRootCA-G3.pem');
  if (!existsSync(file)) {
    throw new Error(`Apple Root CA G3 PEM not found at ${file}; run scripts/fetch-apple-root.sh or set APPLE_ROOT_CA_PEM`);
  }
  return readFileSync(file, 'utf8');
}

/**
 * Apple in-app purchases: App Store Server Notifications V2 (server→server) and
 * StoreKit 2 signed transactions sent by the app (client→server "link").
 * Licenses are keyed by (source='apple', source_ref=originalTransactionId).
 */
export class AppleBilling {
  private readonly roots: string[];
  private readonly products: Record<string, ProductMapping>;
  private readonly clock: () => number;

  constructor(
    private readonly db: Db,
    private readonly licenses: LicenseService,
    private readonly opts: AppleBillingOptions,
  ) {
    this.roots = opts.rootCertsPem ?? [appleRootCaG3Pem()];
    this.products = opts.products ?? DEFAULT_PRODUCTS;
    this.clock = opts.clock ?? nowSec;
  }

  private verify<T>(jws: string): T {
    try {
      return verifyJwsWithX5c<T>(jws, { rootCertsPem: this.roots, now: new Date(this.clock() * 1000) }).payload;
    } catch (e) {
      if (e instanceof JwsError) throw new HttpError(401, `apple JWS rejected: ${e.message}`, `apple_${e.code}`);
      throw e;
    }
  }

  private checkScope(bundleId: string, environment: string): void {
    if (bundleId !== this.opts.bundleId) throw new HttpError(400, `bundleId mismatch: ${bundleId}`, 'bundle_mismatch');
    if (this.opts.environment !== 'any' && environment !== this.opts.environment) {
      throw new HttpError(400, `environment ${environment} not accepted`, 'env_mismatch');
    }
  }

  /** Handles a POSTed `{ signedPayload }` notification. Idempotent per notificationUUID. */
  handleNotification(signedPayload: string): { handled: boolean; action: string; licenseId?: string } {
    const note = this.verify<AppleNotificationV2>(signedPayload);
    const now = this.clock();
    const seen = this.db.prepare('SELECT 1 FROM processed_notifications WHERE id = ?').get(`apple:${note.notificationUUID}`);
    if (seen) return { handled: true, action: 'duplicate' };

    if (note.notificationType === 'TEST' || !note.data) {
      this.markProcessed(note.notificationUUID, now);
      return { handled: true, action: 'noop' };
    }
    this.checkScope(note.data.bundleId, note.data.environment);

    const tx = note.data.signedTransactionInfo ? this.verify<AppleTransaction>(note.data.signedTransactionInfo) : undefined;
    const renewal = note.data.signedRenewalInfo ? this.verify<AppleRenewalInfo>(note.data.signedRenewalInfo) : undefined;
    if (!tx) {
      this.markProcessed(note.notificationUUID, now);
      return { handled: true, action: 'no_transaction' };
    }
    const result = this.applyTransaction(tx, renewal, note.notificationType, note.subtype);
    logEvent(this.db, 'apple.notification', result.licenseId ?? null, { type: note.notificationType, subtype: note.subtype, uuid: note.notificationUUID }, now);
    this.markProcessed(note.notificationUUID, now);
    return { handled: true, ...result };
  }

  /** Client sends `Transaction.jwsRepresentation`; we verify, upsert the license and activate the device. */
  linkTransaction(signedTransaction: string, device: DeviceInfo): { token: string; license: PublicLicenseView; key: string | null } {
    const tx = this.verify<AppleTransaction>(signedTransaction);
    this.checkScope(tx.bundleId, tx.environment);
    const { licenseId, key } = this.applyTransaction(tx, undefined, 'LINK');
    if (!licenseId) throw new HttpError(400, 'transaction does not map to a MIRRORZ product', 'unknown_product');
    const lic = this.licenses.getById(licenseId)!;
    const ent = this.licenses.entitlement(lic);
    if (!ent.entitled) throw new HttpError(403, `purchase is not entitled: ${ent.reason}`, ent.reason);
    // Activation by license id (the user never sees a key for store purchases; the key is still
    // generated so support can look it up, and it is returned once here for "restore on another Mac").
    const activation = this.licenses.activateById(lic.id, device);
    return { ...activation, key };
  }

  private applyTransaction(tx: AppleTransaction, renewal: AppleRenewalInfo | undefined, type: string, subtype?: string): { action: string; licenseId?: string; key: string | null } {
    const mapping = this.products[tx.productId];
    if (!mapping) return { action: `ignored_product:${tx.productId}`, key: null };

    const revoked = tx.revocationDate !== undefined || type === 'REFUND' || type === 'REVOKE';
    if (mapping.kind === 'perpetual') {
      const r = this.licenses.upsertFromBilling({
        kind: 'perpetual',
        plan: mapping.plan,
        source: 'apple',
        sourceRef: tx.originalTransactionId,
        status: revoked ? 'refunded' : 'active',
      });
      if (revoked) this.licenses.revoke(r.license.id, `apple:${type}`, 'refunded');
      return { action: revoked ? 'perpetual_refunded' : 'perpetual_active', licenseId: r.license.id, key: r.key };
    }

    // Subscription
    let expiresAt = tx.expiresDate ? Math.floor(tx.expiresDate / 1000) : undefined;
    if (renewal?.gracePeriodExpiresDate) {
      expiresAt = Math.max(expiresAt ?? 0, Math.floor(renewal.gracePeriodExpiresDate / 1000));
    }
    let status: 'active' | 'expired' | 'refunded' = 'active';
    if (revoked) status = 'refunded';
    else if (type === 'EXPIRED' || type === 'GRACE_PERIOD_EXPIRED') status = 'expired';
    const autoRenew = renewal ? renewal.autoRenewStatus === 1 : type !== 'DID_CHANGE_RENEWAL_STATUS' || subtype !== 'AUTO_RENEW_DISABLED';
    const r = this.licenses.upsertFromBilling({
      kind: 'subscription',
      plan: mapping.plan,
      source: 'apple',
      sourceRef: tx.originalTransactionId,
      ...(expiresAt !== undefined ? { expiresAt } : {}),
      autoRenew,
      status,
    });
    if (status === 'refunded') this.licenses.revoke(r.license.id, `apple:${type}`, 'refunded');
    return { action: `subscription_${status}`, licenseId: r.license.id, key: r.key };
  }

  private markProcessed(uuid: string, now: number): void {
    this.db.prepare('INSERT OR IGNORE INTO processed_notifications (id, source, at) VALUES (?, ?, ?)').run(`apple:${uuid}`, 'apple', now);
  }
}
