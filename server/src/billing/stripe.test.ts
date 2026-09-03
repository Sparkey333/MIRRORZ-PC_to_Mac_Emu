import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import { makeEnv } from '../test/helpers.js';
import { DAY, HttpError } from '../util.js';
import type { LicenseEmail, Mailer } from './mailer.js';
import { StripeBilling, verifyStripeSignature } from './stripe.js';

const SECRET = 'whsec_test';
function sign(body: string, t: number): string {
  return `t=${t},v1=${createHmac('sha256', SECRET).update(`${t}.${body}`).digest('hex')}`;
}

class SpyMailer implements Mailer {
  sent: LicenseEmail[] = [];
  async sendLicenseKey(msg: LicenseEmail) {
    this.sent.push(msg);
  }
}

test('signature verification: valid, tampered, stale, multiple v1', () => {
  const body = '{"id":"evt_1"}';
  assert.ok(verifyStripeSignature(body, sign(body, 1000), SECRET, 300, 1100));
  assert.ok(!verifyStripeSignature(body + ' ', sign(body, 1000), SECRET, 300, 1100));
  assert.ok(!verifyStripeSignature(body, sign(body, 1000), SECRET, 300, 2000));
  assert.ok(!verifyStripeSignature(body, undefined, SECRET));
  assert.ok(verifyStripeSignature(body, `t=1000,v1=deadbeef,${sign(body, 1000).split(',')[1]}`, SECRET, 300, 1000));
});

test('checkout.session.completed (payment) issues a perpetual license and emails the key', async () => {
  const env = makeEnv();
  const mailer = new SpyMailer();
  const stripe = new StripeBilling(env.db, env.licenses, mailer, { webhookSecret: SECRET, clock: () => env.clock.now });
  const body = JSON.stringify({
    id: 'evt_pay_1', type: 'checkout.session.completed',
    data: { object: { id: 'cs_1', mode: 'payment', payment_intent: 'pi_1', customer_details: { email: 'Buyer@Example.com' }, metadata: { product_id: 'com.mirrorz.pro.perpetual' } } },
  });
  const r = await stripe.handleWebhook(body, sign(body, env.clock.now));
  assert.equal(r.action, 'perpetual_active');
  assert.equal(mailer.sent.length, 1);
  assert.equal(mailer.sent[0]!.plan, 'pro');
  const lic = env.licenses.findBySourceRef('stripe', 'pi_1')!;
  assert.equal(lic.kind, 'perpetual');
  assert.ok(lic.email_hash);
  // duplicate delivery is a no-op
  assert.equal((await stripe.handleWebhook(body, sign(body, env.clock.now))).action, 'duplicate');
  assert.equal(mailer.sent.length, 1);
  // refund revokes
  const refund = JSON.stringify({ id: 'evt_ref_1', type: 'charge.refunded', data: { object: { payment_intent: 'pi_1', refunded: true } } });
  assert.equal((await stripe.handleWebhook(refund, sign(refund, env.clock.now))).action, 'perpetual_refunded');
  assert.equal(env.licenses.getById(lic.id)!.status, 'refunded');
});

test('subscription lifecycle via customer.subscription.* with both period_end shapes', async () => {
  const env = makeEnv();
  const mailer = new SpyMailer();
  const stripe = new StripeBilling(env.db, env.licenses, mailer, { webhookSecret: SECRET, clock: () => env.clock.now });
  const end = env.clock.now + 30 * DAY;
  const checkout = JSON.stringify({ id: 'evt_cs', type: 'checkout.session.completed', data: { object: { id: 'cs_2', mode: 'subscription', subscription: 'sub_1', customer_details: { email: 'a@b.co' } } } });
  await stripe.handleWebhook(checkout, sign(checkout, env.clock.now));
  const created = JSON.stringify({ id: 'evt_sc', type: 'customer.subscription.created', data: { object: { id: 'sub_1', status: 'active', cancel_at_period_end: false, items: { data: [{ price: { lookup_key: 'com.mirrorz.standard.monthly' }, current_period_end: end }] } } } });
  const r1 = await stripe.handleWebhook(created, sign(created, env.clock.now));
  assert.equal(r1.action, 'subscription_active');
  assert.equal(mailer.sent.length, 1);
  const lic = env.licenses.findBySourceRef('stripe', 'sub_1')!;
  assert.equal(lic.expires_at, end);
  assert.equal(lic.auto_renew, 1);

  const updated = JSON.stringify({ id: 'evt_su', type: 'customer.subscription.updated', data: { object: { id: 'sub_1', status: 'active', cancel_at_period_end: true, current_period_end: end + 30 * DAY, items: { data: [{ price: { lookup_key: 'com.mirrorz.standard.monthly' } }] } } } });
  await stripe.handleWebhook(updated, sign(updated, env.clock.now));
  const lic2 = env.licenses.getById(lic.id)!;
  assert.equal(lic2.expires_at, end + 30 * DAY);
  assert.equal(lic2.auto_renew, 0);

  const deleted = JSON.stringify({ id: 'evt_sd', type: 'customer.subscription.deleted', data: { object: { id: 'sub_1', status: 'canceled', items: { data: [{ price: { lookup_key: 'com.mirrorz.standard.monthly' } }] } } } });
  assert.equal((await stripe.handleWebhook(deleted, sign(deleted, env.clock.now))).action, 'subscription_expired');
  assert.equal(env.licenses.getById(lic.id)!.status, 'expired');
});

test('bad signature is rejected when a secret is configured', async () => {
  const env = makeEnv();
  const stripe = new StripeBilling(env.db, env.licenses, new SpyMailer(), { webhookSecret: SECRET, clock: () => env.clock.now });
  await assert.rejects(stripe.handleWebhook('{"id":"x","type":"y","data":{"object":{}}}', 't=1,v1=00'), (e: unknown) => e instanceof HttpError && e.status === 401);
});
