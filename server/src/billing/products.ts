import type { LicenseKind } from '../license/token.js';

export interface ProductMapping {
  kind: LicenseKind;
  plan: 'standard' | 'pro' | 'business';
  /** Billing period for subscriptions; informational. */
  period?: 'monthly' | 'annual';
}

/**
 * Store product identifiers → license entitlement.
 * Keep the SAME ids across App Store Connect, Google Play Console and Stripe Price lookup keys
 * so the mapping stays one table.
 */
export const DEFAULT_PRODUCTS: Record<string, ProductMapping> = {
  // Subscriptions (auto-renewable)
  'com.mirrorz.standard.monthly': { kind: 'subscription', plan: 'standard', period: 'monthly' },
  'com.mirrorz.standard.annual': { kind: 'subscription', plan: 'standard', period: 'annual' },
  'com.mirrorz.pro.monthly': { kind: 'subscription', plan: 'pro', period: 'monthly' },
  'com.mirrorz.pro.annual': { kind: 'subscription', plan: 'pro', period: 'annual' },
  'com.mirrorz.business.annual': { kind: 'subscription', plan: 'business', period: 'annual' },
  // One-time (non-consumable) perpetual licenses
  'com.mirrorz.standard.perpetual': { kind: 'perpetual', plan: 'standard' },
  'com.mirrorz.pro.perpetual': { kind: 'perpetual', plan: 'pro' },
};

export function productFor(productId: string, map: Record<string, ProductMapping> = DEFAULT_PRODUCTS): ProductMapping | undefined {
  return map[productId];
}
