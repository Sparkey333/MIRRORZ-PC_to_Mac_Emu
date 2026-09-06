import assert from 'node:assert/strict';
import { test } from 'node:test';
import { makeEnv } from '../test/helpers.js';
import { DAY, HttpError } from '../util.js';
import { GoogleBilling, type PlayApi, type PlayProductPurchase, type PlaySubscriptionV2 } from './google.js';

class FakePlay implements PlayApi {
  subs = new Map<string, PlaySubscriptionV2>();
  products = new Map<string, PlayProductPurchase>();
  acked: string[] = [];
  async getSubscriptionV2(token: string) {
    const s = this.subs.get(token);
    if (!s) throw new HttpError(502, 'play api 404', 'google_api');
    return s;
  }
  async getProduct(_productId: string, token: string) {
    const p = this.products.get(token);
    if (!p) throw new HttpError(502, 'play api 404', 'google_api');
    return p;
  }
  async acknowledgeProduct(productId: string, token: string) {
    this.acked.push(`${productId}:${token}`);
  }
}

const PKG = 'com.mirrorz.companion';
function push(note: object, id = 'msg-1') {
  return { message: { data: Buffer.from(JSON.stringify({ version: '1.0', packageName: PKG, eventTimeMillis: '1', ...note })).toString('base64'), messageId: id } };
}

test('subscription RTDN: purchased → active; canceled keeps access; expired → expired; upgrade carries license', async () => {
  const env = makeEnv();
  const play = new FakePlay();
  const g = new GoogleBilling(env.db, env.licenses, play, { packageName: PKG, pushToken: 'secret', clock: () => env.clock.now });
  const expiry = new Date((env.clock.now + 30 * DAY) * 1000).toISOString();
  play.subs.set('tok1', { subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE', lineItems: [{ productId: 'com.mirrorz.standard.monthly', expiryTime: expiry, autoRenewingPlan: { autoRenewEnabled: true } }] });

  await assert.rejects(g.handleRtdn(push({ subscriptionNotification: { version: '1', notificationType: 4, purchaseToken: 'tok1', subscriptionId: 'x' } }), 'wrong'), (e: unknown) => e instanceof HttpError && e.status === 401);
  const r = await g.handleRtdn(push({ subscriptionNotification: { version: '1', notificationType: 4, purchaseToken: 'tok1', subscriptionId: 'x' } }), 'secret');
  assert.equal(r.action, 'subscription_active');
  const lic = env.licenses.findBySourceRef('google', 'tok1')!;
  assert.equal(lic.expires_at, env.clock.now + 30 * DAY);
  assert.equal((await g.handleRtdn(push({ subscriptionNotification: { version: '1', notificationType: 4, purchaseToken: 'tok1', subscriptionId: 'x' } }), 'secret')).action, 'duplicate');

  play.subs.set('tok1', { subscriptionState: 'SUBSCRIPTION_STATE_CANCELED', lineItems: [{ productId: 'com.mirrorz.standard.monthly', expiryTime: expiry, autoRenewingPlan: { autoRenewEnabled: false } }] });
  await g.handleRtdn(push({ subscriptionNotification: { version: '1', notificationType: 3, purchaseToken: 'tok1', subscriptionId: 'x' } }, 'msg-2'), 'secret');
  assert.equal(env.licenses.getById(lic.id)!.status, 'active');
  assert.equal(env.licenses.getById(lic.id)!.auto_renew, 0);

  // upgrade to pro issues a new token linked to the old one
  play.subs.set('tok2', { subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE', linkedPurchaseToken: 'tok1', lineItems: [{ productId: 'com.mirrorz.pro.monthly', expiryTime: expiry, autoRenewingPlan: { autoRenewEnabled: true } }] });
  await g.handleRtdn(push({ subscriptionNotification: { version: '1', notificationType: 4, purchaseToken: 'tok2', subscriptionId: 'y' } }, 'msg-3'), 'secret');
  const same = env.licenses.findBySourceRef('google', 'tok2')!;
  assert.equal(same.id, lic.id);
  assert.equal(same.plan, 'pro');

  play.subs.set('tok2', { subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED', lineItems: [{ productId: 'com.mirrorz.pro.monthly', expiryTime: expiry }] });
  await g.handleRtdn(push({ subscriptionNotification: { version: '1', notificationType: 13, purchaseToken: 'tok2', subscriptionId: 'y' } }, 'msg-4'), 'secret');
  assert.equal(env.licenses.getById(lic.id)!.status, 'expired');
});

test('one-time product: purchase → perpetual + acknowledge; voided → refunded; link activates device', async () => {
  const env = makeEnv();
  const play = new FakePlay();
  const g = new GoogleBilling(env.db, env.licenses, play, { packageName: PKG, clock: () => env.clock.now });
  play.products.set('ptok', { purchaseState: 0, purchaseTimeMillis: '1', acknowledgementState: 0 });
  const linked = await g.linkPurchase({ purchaseToken: 'ptok', productId: 'com.mirrorz.standard.perpetual', device: { id: 'android-device-1', platform: 'android' } });
  assert.ok(linked.token.startsWith('MZL1.'));
  assert.equal(linked.license.kind, 'perpetual');
  assert.deepEqual(play.acked, ['com.mirrorz.standard.perpetual:ptok']);
  assert.ok(linked.key, 'first link returns the key so the user can activate their Mac');

  const r = await g.handleRtdn(push({ voidedPurchaseNotification: { purchaseToken: 'ptok', orderId: 'o', productType: 2 } }, 'msg-v'), undefined);
  assert.equal(r.action, 'voided');
  assert.equal(env.licenses.getById(linked.license.id)!.status, 'refunded');
});

test('package mismatch and malformed pushes are rejected', async () => {
  const env = makeEnv();
  const g = new GoogleBilling(env.db, env.licenses, new FakePlay(), { packageName: PKG, clock: () => env.clock.now });
  await assert.rejects(g.handleRtdn({ message: { data: Buffer.from(JSON.stringify({ packageName: 'other' })).toString('base64'), messageId: 'm' } }, undefined), /packageName mismatch/);
  await assert.rejects(g.handleRtdn({ message: { data: 'not-json', messageId: 'm2' } }, undefined), (e: unknown) => e instanceof HttpError && e.status === 400);
});
