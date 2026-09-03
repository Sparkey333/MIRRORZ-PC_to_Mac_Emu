import { createSign } from 'node:crypto';
import type { Db } from '../db.js';
import { logEvent } from '../db.js';
import type { DeviceInfo, LicenseService, PublicLicenseView } from '../license/service.js';
import { HttpError, b64urlEncode, nowSec } from '../util.js';
import { DEFAULT_PRODUCTS, type ProductMapping } from './products.js';

/** Subset of Google Play Developer API v3 responses we rely on. */
export interface PlaySubscriptionV2 {
  subscriptionState:
    | 'SUBSCRIPTION_STATE_UNSPECIFIED' | 'SUBSCRIPTION_STATE_PENDING' | 'SUBSCRIPTION_STATE_ACTIVE'
    | 'SUBSCRIPTION_STATE_PAUSED' | 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' | 'SUBSCRIPTION_STATE_ON_HOLD'
    | 'SUBSCRIPTION_STATE_CANCELED' | 'SUBSCRIPTION_STATE_EXPIRED' | 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED';
  lineItems: Array<{ productId: string; expiryTime: string; autoRenewingPlan?: { autoRenewEnabled?: boolean } }>;
  linkedPurchaseToken?: string;
  acknowledgementState?: string;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
}

export interface PlayProductPurchase {
  purchaseState: number; // 0 purchased, 1 canceled, 2 pending
  purchaseTimeMillis: string;
  acknowledgementState: number; // 0 yet to be acknowledged, 1 acknowledged
  obfuscatedExternalAccountId?: string;
  orderId?: string;
}

export interface PlayApi {
  getSubscriptionV2(purchaseToken: string): Promise<PlaySubscriptionV2>;
  getProduct(productId: string, purchaseToken: string): Promise<PlayProductPurchase>;
  acknowledgeProduct?(productId: string, purchaseToken: string): Promise<void>;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** Real client: service-account JWT → OAuth2 access token → androidpublisher v3. */
export class GooglePlayApiClient implements PlayApi {
  private token: { value: string; exp: number } | null = null;
  constructor(
    private readonly packageName: string,
    private readonly sa: ServiceAccount,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  private async accessToken(): Promise<string> {
    const now = nowSec();
    if (this.token && this.token.exp - 60 > now) return this.token.value;
    const header = b64urlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
    const claim = b64urlEncode(
      JSON.stringify({
        iss: this.sa.client_email,
        scope: 'https://www.googleapis.com/auth/androidpublisher',
        aud: this.sa.token_uri ?? 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      }),
    );
    const sig = createSign('RSA-SHA256').update(`${header}.${claim}`).sign(this.sa.private_key);
    const assertion = `${header}.${claim}.${b64urlEncode(sig)}`;
    const res = await this.fetchImpl(this.sa.token_uri ?? 'https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }).toString(),
    });
    if (!res.ok) throw new HttpError(502, `google token endpoint ${res.status}`, 'google_auth');
    const json = (await res.json()) as { access_token: string; expires_in: number };
    this.token = { value: json.access_token, exp: now + json.expires_in };
    return json.access_token;
  }

  private async get<T>(path: string): Promise<T> {
    const token = await this.accessToken();
    const res = await this.fetchImpl(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${this.packageName}/${path}`, {
      headers: { authorization: `Bearer ${token}` },
    });
    if (!res.ok) throw new HttpError(502, `play api ${res.status} for ${path}`, 'google_api');
    return (await res.json()) as T;
  }

  getSubscriptionV2(purchaseToken: string): Promise<PlaySubscriptionV2> {
    return this.get(`purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`);
  }

  getProduct(productId: string, purchaseToken: string): Promise<PlayProductPurchase> {
    return this.get(`purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`);
  }

  async acknowledgeProduct(productId: string, purchaseToken: string): Promise<void> {
    const token = await this.accessToken();
    const res = await this.fetchImpl(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${this.packageName}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`,
      { method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: '{}' },
    );
    if (!res.ok && res.status !== 400) throw new HttpError(502, `play acknowledge ${res.status}`, 'google_api');
  }
}

/** Real-time developer notification (Pub/Sub push) body. */
export interface RtdnPush {
  message: { data: string; messageId: string; publishTime?: string };
  subscription?: string;
}

export interface DeveloperNotification {
  version: string;
  packageName: string;
  eventTimeMillis: string;
  subscriptionNotification?: { version: string; notificationType: number; purchaseToken: string; subscriptionId: string };
  oneTimeProductNotification?: { version: string; notificationType: number; purchaseToken: string; sku: string };
  voidedPurchaseNotification?: { purchaseToken: string; orderId: string; productType: number; refundType?: number };
  testNotification?: { version: string };
}

export interface GoogleBillingOptions {
  packageName: string;
  pushToken?: string;
  products?: Record<string, ProductMapping>;
  clock?: () => number;
}

export class GoogleBilling {
  private readonly products: Record<string, ProductMapping>;
  private readonly clock: () => number;
  constructor(
    private readonly db: Db,
    private readonly licenses: LicenseService,
    private readonly api: PlayApi,
    private readonly opts: GoogleBillingOptions,
  ) {
    this.products = opts.products ?? DEFAULT_PRODUCTS;
    this.clock = opts.clock ?? nowSec;
  }

  /** Pub/Sub push handler. We never trust the message body: every event triggers a fresh API lookup. */
  async handleRtdn(body: RtdnPush, queryToken: string | undefined): Promise<{ handled: boolean; action: string; licenseId?: string }> {
    if (this.opts.pushToken && queryToken !== this.opts.pushToken) throw new HttpError(401, 'bad push token', 'unauthorized');
    if (!body?.message?.data) throw new HttpError(400, 'missing message.data', 'bad_request');
    const now = this.clock();
    const dedupeId = `google:${body.message.messageId}`;
    if (this.db.prepare('SELECT 1 FROM processed_notifications WHERE id = ?').get(dedupeId)) return { handled: true, action: 'duplicate' };

    let note: DeveloperNotification;
    try {
      note = JSON.parse(Buffer.from(body.message.data, 'base64').toString('utf8')) as DeveloperNotification;
    } catch {
      throw new HttpError(400, 'message.data is not base64 JSON', 'bad_request');
    }
    if (note.packageName !== this.opts.packageName) throw new HttpError(400, `packageName mismatch: ${note.packageName}`, 'package_mismatch');

    let result: { action: string; licenseId?: string } = { action: 'noop' };
    if (note.subscriptionNotification) {
      result = await this.syncSubscription(note.subscriptionNotification.purchaseToken);
    } else if (note.oneTimeProductNotification) {
      const n = note.oneTimeProductNotification;
      result = await this.syncOneTime(n.sku, n.purchaseToken, n.notificationType === 2 ? 'canceled' : undefined);
    } else if (note.voidedPurchaseNotification) {
      const v = note.voidedPurchaseNotification;
      const lic = this.licenses.findBySourceRef('google', v.purchaseToken);
      if (lic) {
        this.licenses.revoke(lic.id, 'google:voided', 'refunded');
        result = { action: 'voided', licenseId: lic.id };
      }
    }
    logEvent(this.db, 'google.rtdn', result.licenseId ?? null, { type: note.subscriptionNotification?.notificationType ?? note.oneTimeProductNotification?.notificationType, messageId: body.message.messageId }, now);
    this.db.prepare('INSERT OR IGNORE INTO processed_notifications (id, source, at) VALUES (?, ?, ?)').run(dedupeId, 'google', now);
    return { handled: true, ...result };
  }

  /** Client → server: bind a purchase to this device and get a token. */
  async linkPurchase(input: { purchaseToken: string; productId: string; device: DeviceInfo }): Promise<{ token: string; license: PublicLicenseView; key: string | null }> {
    const mapping = this.products[input.productId];
    if (!mapping) throw new HttpError(400, `unknown product ${input.productId}`, 'unknown_product');
    const r = mapping.kind === 'perpetual'
      ? await this.syncOneTime(input.productId, input.purchaseToken)
      : await this.syncSubscription(input.purchaseToken);
    if (!r.licenseId) throw new HttpError(403, 'purchase is not in a valid state', 'not_entitled');
    const lic = this.licenses.getById(r.licenseId)!;
    const ent = this.licenses.entitlement(lic);
    if (!ent.entitled) throw new HttpError(403, `purchase is not entitled: ${ent.reason}`, ent.reason);
    const act = this.licenses.activateById(lic.id, input.device);
    return { ...act, key: r.key ?? null };
  }

  private async syncSubscription(purchaseToken: string): Promise<{ action: string; licenseId?: string; key?: string | null }> {
    const sub = await this.api.getSubscriptionV2(purchaseToken);
    const item = sub.lineItems?.[0];
    if (!item) return { action: 'no_line_items' };
    const mapping = this.products[item.productId];
    if (!mapping) return { action: `ignored_product:${item.productId}` };
    const expiresAt = Math.floor(new Date(item.expiryTime).getTime() / 1000);
    const autoRenew = item.autoRenewingPlan?.autoRenewEnabled ?? false;
    let status: 'active' | 'expired' | 'paused' | 'refunded' = 'active';
    switch (sub.subscriptionState) {
      case 'SUBSCRIPTION_STATE_ACTIVE':
      case 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD':
      case 'SUBSCRIPTION_STATE_CANCELED': // paid through expiry
        status = 'active';
        break;
      case 'SUBSCRIPTION_STATE_ON_HOLD':
      case 'SUBSCRIPTION_STATE_PAUSED':
        status = 'paused';
        break;
      case 'SUBSCRIPTION_STATE_EXPIRED':
      case 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED':
        status = 'expired';
        break;
      default:
        return { action: `pending:${sub.subscriptionState}` };
    }
    // Upgrades/downgrades issue a new token; carry the license over from linkedPurchaseToken.
    if (sub.linkedPurchaseToken) {
      const prev = this.licenses.findBySourceRef('google', sub.linkedPurchaseToken);
      if (prev && !this.licenses.findBySourceRef('google', purchaseToken)) {
        this.db.prepare('UPDATE licenses SET source_ref = ?, updated_at = ? WHERE id = ?').run(purchaseToken, this.clock(), prev.id);
      }
    }
    const r = this.licenses.upsertFromBilling({ kind: 'subscription', plan: mapping.plan, source: 'google', sourceRef: purchaseToken, expiresAt, autoRenew, status });
    return { action: `subscription_${status}`, licenseId: r.license.id, key: r.key };
  }

  private async syncOneTime(productId: string, purchaseToken: string, forced?: 'canceled'): Promise<{ action: string; licenseId?: string; key?: string | null }> {
    const mapping = this.products[productId];
    if (!mapping || mapping.kind !== 'perpetual') return { action: `ignored_product:${productId}` };
    const p = await this.api.getProduct(productId, purchaseToken);
    const canceled = forced === 'canceled' || p.purchaseState === 1;
    if (p.purchaseState === 2) return { action: 'pending' };
    const r = this.licenses.upsertFromBilling({ kind: 'perpetual', plan: mapping.plan, source: 'google', sourceRef: purchaseToken, status: canceled ? 'refunded' : 'active' });
    if (canceled) this.licenses.revoke(r.license.id, 'google:canceled', 'refunded');
    else if (p.acknowledgementState === 0 && this.api.acknowledgeProduct) await this.api.acknowledgeProduct(productId, purchaseToken);
    return { action: canceled ? 'perpetual_refunded' : 'perpetual_active', licenseId: r.license.id, key: r.key };
  }
}
