import assert from 'node:assert/strict';
import { test } from 'node:test';
import { hasOpenssl, makeChain, makeEnv, signJws } from '../test/helpers.js';
import { DAY, HttpError } from '../util.js';
import { AppleBilling, type AppleNotificationV2, type AppleRenewalInfo, type AppleTransaction } from './apple.js';
import { verifyJwsWithX5c } from './jws.js';

const BUNDLE = 'com.mirrorz.app';
const skip = !hasOpenssl();

function tx(over: Partial<AppleTransaction>): AppleTransaction {
  return {
    originalTransactionId: 'otx-1', transactionId: 'tx-1', productId: 'com.mirrorz.standard.monthly', bundleId: BUNDLE,
    environment: 'Sandbox', type: 'Auto-Renewable Subscription', purchaseDate: 1_800_000_000_000, expiresDate: (1_800_000_000 + 30 * DAY) * 1000, ...over,
  };
}

function note(chain: ReturnType<typeof makeChain>, type: string, t: AppleTransaction, renewal?: AppleRenewalInfo, uuid = `u-${type}`): string {
  const n: AppleNotificationV2 = {
    notificationType: type, notificationUUID: uuid, version: '2.0', signedDate: 1,
    data: { bundleId: BUNDLE, environment: 'Sandbox', signedTransactionInfo: signJws(t, chain), ...(renewal ? { signedRenewalInfo: signJws(renewal, chain) } : {}) },
  };
  return signJws(n, chain);
}

test('x5c chain verification accepts a good chain and rejects a foreign root / tampered payload', { skip }, () => {
  const chain = makeChain('A');
  const foreign = makeChain('B');
  const jws = signJws({ hello: 'world' }, chain);
  assert.deepEqual(verifyJwsWithX5c(jws, { rootCertsPem: [chain.rootPem] }).payload, { hello: 'world' });
  assert.throws(() => verifyJwsWithX5c(jws, { rootCertsPem: [foreign.rootPem] }), /trusted root/);
  const [h, , s] = jws.split('.') as [string, string, string];
  const forged = Buffer.from('{"hello":"evil"}').toString('base64url');
  assert.throws(() => verifyJwsWithX5c(`${h}.${forged}.${s}`, { rootCertsPem: [chain.rootPem] }), /bad signature/);
  // chain without the root in x5c still anchors to the pinned root
  assert.ok(verifyJwsWithX5c(signJws({ x: 1 }, chain, chain.x5c.slice(0, 2)), { rootCertsPem: [chain.rootPem] }));
  // leaf alone signed by intermediate we don't have → chain break
  assert.throws(() => verifyJwsWithX5c(signJws({ x: 1 }, chain, [chain.x5c[0]!]), { rootCertsPem: [chain.rootPem] }), /trusted root/);
});

test('App Store Server Notifications V2 drive subscription state; duplicates ignored', { skip }, () => {
  const env = makeEnv();
  const chain = makeChain();
  const apple = new AppleBilling(env.db, env.licenses, { bundleId: BUNDLE, environment: 'any', rootCertsPem: [chain.rootPem], clock: () => env.clock.now });

  const r1 = apple.handleNotification(note(chain, 'SUBSCRIBED', tx({}), { originalTransactionId: 'otx-1', autoRenewStatus: 1 }));
  assert.equal(r1.action, 'subscription_active');
  const lic = env.licenses.findBySourceRef('apple', 'otx-1')!;
  assert.equal(lic.expires_at, 1_800_000_000 + 30 * DAY);
  assert.equal(apple.handleNotification(note(chain, 'SUBSCRIBED', tx({}), undefined, 'u-SUBSCRIBED')).action, 'duplicate');

  // billing retry with grace period extends expiry
  const grace = (1_800_000_000 + 46 * DAY) * 1000;
  apple.handleNotification(note(chain, 'DID_FAIL_TO_RENEW', tx({}), { originalTransactionId: 'otx-1', autoRenewStatus: 1, gracePeriodExpiresDate: grace, isInBillingRetryPeriod: true }));
  assert.equal(env.licenses.getById(lic.id)!.expires_at, 1_800_000_000 + 46 * DAY);

  apple.handleNotification(note(chain, 'EXPIRED', tx({}), { originalTransactionId: 'otx-1', autoRenewStatus: 0, expirationIntent: 1 }));
  assert.equal(env.licenses.getById(lic.id)!.status, 'expired');

  apple.handleNotification(note(chain, 'DID_RENEW', tx({ expiresDate: (1_800_000_000 + 90 * DAY) * 1000 }), { originalTransactionId: 'otx-1', autoRenewStatus: 1 }));
  assert.equal(env.licenses.getById(lic.id)!.status, 'active');

  apple.handleNotification(note(chain, 'REFUND', tx({ revocationDate: 1, revocationReason: 0 })));
  assert.equal(env.licenses.getById(lic.id)!.status, 'refunded');
});

test('non-consumable purchase → perpetual; link binds device; wrong bundle rejected', { skip }, () => {
  const env = makeEnv();
  const chain = makeChain();
  const apple = new AppleBilling(env.db, env.licenses, { bundleId: BUNDLE, environment: 'any', rootCertsPem: [chain.rootPem], clock: () => env.clock.now });
  const t = tx({ originalTransactionId: 'otx-perp', productId: 'com.mirrorz.pro.perpetual', type: 'Non-Consumable', expiresDate: undefined });
  delete (t as Partial<AppleTransaction>).expiresDate;
  const linked = apple.linkTransaction(signJws(t, chain), { id: 'mac-device-0001', platform: 'macos' });
  assert.equal(linked.license.kind, 'perpetual');
  assert.equal(linked.license.plan, 'pro');
  assert.ok(linked.token.startsWith('MZL1.'));
  assert.ok(linked.key);
  // linking again from a second Mac: no new key, second device slot used
  const again = apple.linkTransaction(signJws(t, chain), { id: 'mac-device-0002', platform: 'macos' });
  assert.equal(again.key, null);
  assert.equal(again.license.devices.length, 2);

  assert.throws(() => apple.linkTransaction(signJws({ ...t, bundleId: 'com.evil' }, chain), { id: 'mac-device-0003' }), (e: unknown) => e instanceof HttpError && e.code === 'bundle_mismatch');
  const foreign = makeChain('Evil');
  assert.throws(() => apple.linkTransaction(signJws(t, foreign), { id: 'mac-device-0003' }), (e: unknown) => e instanceof HttpError && e.status === 401);
});
