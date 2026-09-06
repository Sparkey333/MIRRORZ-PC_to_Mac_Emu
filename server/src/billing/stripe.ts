import { createHmac, timingSafeEqual } from 'node:crypto';
import type { Db } from '../db.js';
import { logEvent } from '../db.js';
import type { LicenseService } from '../license/service.js';
import { HttpError, emailHash, nowSec } from '../util.js';
import type { Mailer } from './mailer.js';
import { DEFAULT_PRODUCTS, type ProductMapping } from './products.js';

/** Verifies a `Stripe-Signature` header (t=...,v1=...) against the raw request body. */
export function verifyStripeSignature(rawBody: string, header: string | undefined, secret: string, toleranceSec = 300, now = nowSec()): boolean {
  if (!header) return false;
  const parts = Object.fromEntries(
    header.split(',').map((kv) => {
      const i = kv.indexOf('=');
      return [kv.slice(0, i).trim(), kv.slice(i + 1).trim()];
    }),
  ) as Record<string, string>;
  const t = Number(parts['t']);
  const v1s = header
    .split(',')
    .map((kv) => kv.trim())
    .filter((kv) => kv.startsWith('v1='))
    .map((kv) => kv.slice(3));
  if (!Number.isFinite(t) || v1s.length === 0) return false;
  if (Math.abs(now - t) > toleranceSec) return false;
  const expected = createHmac('sha256', secret).update(`${t}.${rawBody}`).digest('hex');
  const exp = Buffer.from(expected, 'utf8');
  return v1s.some((sig) => {
    const got = Buffer.from(sig, 'utf8');
    return got.length === exp.length && timingSafeEqual(got, exp);
  });
}

export interface StripeEvent {
  id: string;
  type: string;
  data: { object: Record<string, unknown> };
}

export interface StripeBillingOptions {
  webhookSecret?: string;
  products?: Record<string, ProductMapping>;
  clock?: () => number;
}

/**
 * Direct-sales path (website checkout). Product identity comes from the Price `lookup_key`
 * or `metadata.product_id`, which must equal the store product ids in products.ts.
 */
export class StripeBilling {
  private readonly products: Record<string, ProductMapping>;
  private readonly clock: () => number;
  constructor(
    private readonly db: Db,
    private readonly licenses: LicenseService,
    private readonly mailer: Mailer,
    private readonly opts: StripeBillingOptions,
  ) {
    this.products = opts.products ?? DEFAULT_PRODUCTS;
    this.clock = opts.clock ?? nowSec;
  }

  async handleWebhook(rawBody: string, signatureHeader: string | undefined): Promise<{ handled: boolean; action: string; licenseId?: string }> {
    if (this.opts.webhookSecret && !verifyStripeSignature(rawBody, signatureHeader, this.opts.webhookSecret, 300, this.clock())) {
      throw new HttpError(401, 'bad stripe signature', 'unauthorized');
    }
    let event: StripeEvent;
    try {
      event = JSON.parse(rawBody) as StripeEvent;
    } catch {
      throw new HttpError(400, 'invalid JSON', 'bad_request');
    }
    const now = this.clock();
    const dedupeId = `stripe:${event.id}`;
    if (this.db.prepare('SELECT 1 FROM processed_notifications WHERE id = ?').get(dedupeId)) return { handled: true, action: 'duplicate' };
    const result = await this.apply(event);
    logEvent(this.db, 'stripe.event', result.licenseId ?? null, { type: event.type, id: event.id }, now);
    this.db.prepare('INSERT OR IGNORE INTO processed_notifications (id, source, at) VALUES (?, ?, ?)').run(dedupeId, 'stripe', now);
    return { handled: true, ...result };
  }

  private productIdOf(obj: Record<string, unknown>): string | undefined {
    const meta = obj['metadata'] as Record<string, string> | undefined;
    if (meta?.['product_id']) return meta['product_id'];
    // subscription.items.data[0].price.lookup_key
    const items = (obj['items'] as { data?: Array<{ price?: { lookup_key?: string; metadata?: Record<string, string> } }> } | undefined)?.data;
    const price = items?.[0]?.price;
    return price?.lookup_key ?? price?.metadata?.['product_id'];
  }

  private periodEndOf(sub: Record<string, unknown>): number | undefined {
    // API versions before 2025-03-31 expose current_period_end at the top level; later versions on items.
    const top = sub['current_period_end'];
    if (typeof top === 'number') return top;
    const items = (sub['items'] as { data?: Array<{ current_period_end?: number }> } | undefined)?.data;
    const v = items?.[0]?.current_period_end;
    return typeof v === 'number' ? v : undefined;
  }

  private async apply(event: StripeEvent): Promise<{ action: string; licenseId?: string }> {
    const obj = event.data.object;
    switch (event.type) {
      case 'checkout.session.completed': {
        const mode = obj['mode'];
        const email = (obj['customer_details'] as { email?: string } | undefined)?.email ?? (obj['customer_email'] as string | undefined);
        if (mode === 'payment') {
          const productId = this.productIdOf(obj);
          const mapping = productId ? this.products[productId] : undefined;
          if (!mapping || mapping.kind !== 'perpetual') return { action: `ignored_product:${productId ?? 'none'}` };
          const ref = (obj['payment_intent'] as string | undefined) ?? (obj['id'] as string);
          const r = this.licenses.upsertFromBilling({ kind: 'perpetual', plan: mapping.plan, source: 'stripe', sourceRef: ref, ...(email ? { email } : {}) });
          if (r.created && r.key && email) await this.mailer.sendLicenseKey({ email, key: r.key, plan: mapping.plan, kind: 'perpetual' });
          return { action: 'perpetual_active', licenseId: r.license.id };
        }
        if (mode === 'subscription') {
          // The subscription object arrives via customer.subscription.created/updated; remember the email now.
          const subId = obj['subscription'] as string | undefined;
          if (subId && email) {
            const lic = this.licenses.findBySourceRef('stripe', subId);
            if (lic && !lic.email_hash) this.db.prepare('UPDATE licenses SET email_hash = ? WHERE id = ?').run(emailHash(email), lic.id);
            this.pendingEmails.set(subId, email);
          }
          return { action: 'subscription_checkout' };
        }
        return { action: 'ignored_mode' };
      }
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.resumed':
      case 'customer.subscription.paused':
      case 'customer.subscription.deleted': {
        const subId = obj['id'] as string;
        const productId = this.productIdOf(obj);
        const mapping = productId ? this.products[productId] : undefined;
        if (!mapping || mapping.kind !== 'subscription') return { action: `ignored_product:${productId ?? 'none'}` };
        const stripeStatus = obj['status'] as string;
        const expiresAt = this.periodEndOf(obj);
        let status: 'active' | 'expired' | 'paused' = 'active';
        if (event.type === 'customer.subscription.deleted' || stripeStatus === 'canceled' || stripeStatus === 'incomplete_expired' || stripeStatus === 'unpaid') status = 'expired';
        else if (stripeStatus === 'paused') status = 'paused';
        const autoRenew = !(obj['cancel_at_period_end'] as boolean | undefined) && status === 'active';
        const email = this.pendingEmails.get(subId);
        const r = this.licenses.upsertFromBilling({ kind: 'subscription', plan: mapping.plan, source: 'stripe', sourceRef: subId, ...(expiresAt !== undefined ? { expiresAt } : {}), autoRenew, status, ...(email ? { email } : {}) });
        if (r.created && r.key && email) {
          await this.mailer.sendLicenseKey({ email, key: r.key, plan: mapping.plan, kind: 'subscription' });
          this.pendingEmails.delete(subId);
        }
        return { action: `subscription_${status}`, licenseId: r.license.id };
      }
      case 'charge.refunded': {
        const pi = obj['payment_intent'] as string | undefined;
        const lic = pi ? this.licenses.findBySourceRef('stripe', pi) : undefined;
        if (!lic) return { action: 'refund_unmatched' };
        const fully = (obj['refunded'] as boolean | undefined) === true;
        if (!fully) return { action: 'partial_refund_ignored', licenseId: lic.id };
        this.licenses.revoke(lic.id, 'stripe:refund', 'refunded');
        return { action: 'perpetual_refunded', licenseId: lic.id };
      }
      default:
        return { action: `ignored:${event.type}` };
    }
  }

  private readonly pendingEmails = new Map<string, string>();
}
