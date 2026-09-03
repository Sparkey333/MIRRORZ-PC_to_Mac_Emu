export type PlanId = 'standard' | 'pro' | 'business' | 'trial';

/** Feature flags gate premium tooling in the clients. Keep names stable; they ship in tokens. */
export const PLAN_FEATURES: Record<PlanId, string[]> = {
  trial: ['vm', 'bottles', 'coherence', 'compat-db'],
  standard: ['vm', 'bottles', 'coherence', 'snapshots', 'compat-db', 'cad-presets', 'mobile-companion', 'no-ads'],
  pro: [
    'vm', 'bottles', 'coherence', 'snapshots', 'compat-db', 'cad-presets', 'mobile-companion', 'no-ads',
    'cli', 'api', 'nested-virt', 'linked-clones', 'pro-tools', 'cloud-sync', 'priority-support', 'network-lab',
  ],
  business: [
    'vm', 'bottles', 'coherence', 'snapshots', 'compat-db', 'cad-presets', 'mobile-companion', 'no-ads',
    'cli', 'api', 'nested-virt', 'linked-clones', 'pro-tools', 'cloud-sync', 'priority-support', 'network-lab',
    'mdm', 'sso', 'volume-licensing', 'golden-images', 'audit-log',
  ],
};

export function isPlanId(p: string): p is PlanId {
  return p === 'standard' || p === 'pro' || p === 'business' || p === 'trial';
}

export function featuresFor(plan: string): string[] {
  return isPlanId(plan) ? PLAN_FEATURES[plan] : PLAN_FEATURES.standard;
}
