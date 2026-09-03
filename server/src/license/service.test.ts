import assert from 'node:assert/strict';
import { test } from 'node:test';
import { DAY, HttpError } from '../util.js';
import { makeEnv } from '../test/helpers.js';
import { verifyLicenseToken } from './token.js';

const dev = (n: number) => ({ id: `device-${n}-abcdef`, name: `Mac ${n}`, platform: 'macos' as const });

test('perpetual license: activation, device limit, deactivate, token claims', () => {
  const { licenses, keys, clock } = makeEnv();
  const { license, key } = licenses.issue({ kind: 'perpetual', plan: 'standard', source: 'manual' });
  assert.equal(license.max_devices, 3);
  assert.equal(license.updates_until, clock.now + 365 * DAY);

  const a1 = licenses.activate(key, dev(1));
  const claims = verifyLicenseToken(a1.token, keys.publicKey);
  assert.equal(claims.kind, 'perpetual');
  assert.equal(claims.dev, dev(1).id);
  assert.equal(claims.upd, license.updates_until);
  assert.ok(claims.features.includes('no-ads'));
  assert.equal(claims.exp, clock.now + 30 * DAY);

  licenses.activate(key, dev(2));
  licenses.activate(key, dev(3));
  // re-activating an existing device is idempotent and does not consume a slot
  licenses.activate(key, dev(2));
  assert.throws(() => licenses.activate(key, dev(4)), (e: unknown) => e instanceof HttpError && e.status === 409 && e.code === 'device_limit');

  assert.equal(licenses.deactivate(license.id, dev(2).id), true);
  assert.equal(licenses.deactivate(license.id, dev(2).id), false);
  licenses.activate(key, dev(4));
  assert.equal(licenses.view(license).devices.length, 3);
});

test('subscription: entitled through grace, then expired; refresh follows the DB', () => {
  const { licenses, clock } = makeEnv({ graceDays: 7 });
  const periodEnd = clock.now + 30 * DAY;
  const { license, key } = licenses.issue({ kind: 'subscription', plan: 'pro', source: 'stripe', sourceRef: 'sub_1', expiresAt: periodEnd, autoRenew: true });
  const a = licenses.activate(key, dev(1));
  assert.equal(licenses.entitlement(license).subscriptionEndsAt, periodEnd + 7 * DAY);

  clock.advance(33 * DAY); // inside grace
  const r = licenses.refresh(a.token);
  assert.ok(r.license.entitlement.entitled);
  assert.equal(r.license.entitlement.reason, 'subscription');

  clock.advance(10 * DAY); // past grace
  assert.throws(() => licenses.refresh(r.token), (e: unknown) => e instanceof HttpError && e.code === 'expired');
  assert.throws(() => licenses.activate(key, dev(2)), (e: unknown) => e instanceof HttpError && e.status === 403);

  // renewal arrives from billing
  licenses.upsertFromBilling({ kind: 'subscription', plan: 'pro', source: 'stripe', sourceRef: 'sub_1', expiresAt: clock.now + 30 * DAY, autoRenew: true, status: 'active' });
  assert.ok(licenses.refresh(r.token).license.entitlement.entitled);
});

test('revoke/refund kills activations and tokens', () => {
  const { licenses } = makeEnv();
  const { license, key } = licenses.issue({ kind: 'perpetual', plan: 'pro', source: 'manual' });
  const a = licenses.activate(key, dev(1));
  licenses.revoke(license.id, 'chargeback', 'refunded');
  assert.equal(licenses.view(license).devices.length, 0);
  assert.throws(() => licenses.refresh(a.token), (e: unknown) => e instanceof HttpError && e.status === 403);
  assert.throws(() => licenses.activate(key, dev(1)), (e: unknown) => e instanceof HttpError && e.code === 'refunded');
});

test('upsertFromBilling is idempotent per (source, ref) and updates plan/expiry', () => {
  const { licenses, clock } = makeEnv();
  const first = licenses.upsertFromBilling({ kind: 'subscription', plan: 'standard', source: 'apple', sourceRef: 'otx_1', expiresAt: clock.now + DAY });
  assert.ok(first.created && first.key);
  const second = licenses.upsertFromBilling({ kind: 'subscription', plan: 'pro', source: 'apple', sourceRef: 'otx_1', expiresAt: clock.now + 2 * DAY });
  assert.equal(second.created, false);
  assert.equal(second.key, null);
  assert.equal(second.license.id, first.license.id);
  assert.equal(second.license.plan, 'pro');
  assert.equal(second.license.expires_at, clock.now + 2 * DAY);
});

test('bad device ids and unknown keys are rejected', () => {
  const { licenses } = makeEnv();
  const { key } = licenses.issue({ kind: 'perpetual', plan: 'standard', source: 'manual' });
  assert.throws(() => licenses.activate(key, { id: 'short' }), (e: unknown) => e instanceof HttpError && e.status === 400);
  assert.throws(() => licenses.activate('MZ-00000-00000-00000-00000-00000', dev(1)), (e: unknown) => e instanceof HttpError && e.status === 404);
});
