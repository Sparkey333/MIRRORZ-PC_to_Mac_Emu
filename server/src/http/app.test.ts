import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import { ConsoleMailer } from '../billing/mailer.js';
import { StripeBilling } from '../billing/stripe.js';
import { CompatService } from '../compat/service.js';
import { makeEnv } from '../test/helpers.js';
import { buildApp } from './app.js';

function make() {
  const env = makeEnv();
  const compat = new CompatService(env.db, undefined, () => env.clock.now);
  const stripe = new StripeBilling(env.db, env.licenses, new ConsoleMailer(() => {}), { webhookSecret: 'whsec_x', clock: () => env.clock.now });
  const app = buildApp({ licenses: env.licenses, keys: env.keys, compat, stripe, adminToken: 'admin-secret' });
  return { env, app };
}

test('health and public key discovery', async () => {
  const { app, env } = make();
  const h = await app.inject({ method: 'GET', url: '/healthz' });
  assert.equal(h.statusCode, 200);
  assert.equal(h.json().kid, env.keys.kid);
  const k = await app.inject({ method: 'GET', url: '/.well-known/mirrorz-license-key.json' });
  assert.equal(k.json().keys[0].crv, 'Ed25519');
});

test('admin issue → activate → status → refresh → deactivate; auth and validation errors', async () => {
  const { app } = make();
  assert.equal((await app.inject({ method: 'POST', url: '/v1/admin/licenses', payload: { kind: 'perpetual', plan: 'pro' } })).statusCode, 401);
  const issued = await app.inject({ method: 'POST', url: '/v1/admin/licenses', headers: { authorization: 'Bearer admin-secret' }, payload: { kind: 'perpetual', plan: 'pro', email: 'x@example.com' } });
  assert.equal(issued.statusCode, 201);
  const key = issued.json().key as string;

  const bad = await app.inject({ method: 'POST', url: '/v1/licenses/activate', payload: { key, device: { id: 'short' } } });
  assert.equal(bad.statusCode, 400);
  assert.equal(bad.json().error, 'validation');

  const act = await app.inject({ method: 'POST', url: '/v1/licenses/activate', payload: { key, device: { id: 'mac-0001-abcd', platform: 'macos', name: 'Studio' } } });
  assert.equal(act.statusCode, 200, act.body);
  const token = act.json().token as string;
  assert.ok(token.startsWith('MZL1.'));

  const st = await app.inject({ method: 'GET', url: `/v1/licenses/status?key=${encodeURIComponent(key)}` });
  assert.equal(st.json().devices.length, 1);
  assert.equal(st.json().entitlement.plan, 'pro');

  const rf = await app.inject({ method: 'POST', url: '/v1/licenses/refresh', payload: { token } });
  assert.equal(rf.statusCode, 200);
  assert.equal((await app.inject({ method: 'POST', url: '/v1/licenses/refresh', payload: { token: token.slice(0, -4) + 'AAAA' } })).statusCode, 401);

  const de = await app.inject({ method: 'POST', url: '/v1/licenses/deactivate', payload: { key, device_id: 'mac-0001-abcd' } });
  assert.equal(de.json().deactivated, true);
  assert.equal(de.json().license.devices.length, 0);

  const rv = await app.inject({ method: 'POST', url: `/v1/admin/licenses/${issued.json().license.id}/revoke`, headers: { authorization: 'Bearer admin-secret' }, payload: { reason: 'test' } });
  assert.equal(rv.json().status, 'revoked');
  assert.equal((await app.inject({ method: 'POST', url: '/v1/licenses/activate', payload: { key, device: { id: 'mac-0002-abcd' } } })).statusCode, 403);
});

test('activation endpoint is rate limited per IP', async () => {
  const { app } = make();
  let limited = 0;
  for (let i = 0; i < 25; i++) {
    const r = await app.inject({ method: 'POST', url: '/v1/licenses/activate', headers: { 'x-forwarded-for': '203.0.113.9' }, payload: { key: 'MZ-00000-00000-00000-00000-00000', device: { id: 'device-xyz-1234' } } });
    if (r.statusCode === 429) limited++;
  }
  assert.ok(limited >= 4, `expected some 429s, got ${limited}`);
  const other = await app.inject({ method: 'POST', url: '/v1/licenses/activate', headers: { 'x-forwarded-for': '203.0.113.10' }, payload: { key: 'MZ-00000-00000-00000-00000-00000', device: { id: 'device-xyz-1234' } } });
  assert.notEqual(other.statusCode, 429);
});

test('compatibility database: search, get, presets, route, reports', async () => {
  const { app } = make();
  const s = await app.inject({ method: 'GET', url: '/v1/compat/apps?q=autocad' });
  assert.ok(s.json().apps.length >= 3);
  const g = await app.inject({ method: 'GET', url: '/v1/compat/apps/autocad' });
  assert.equal(g.statusCode, 200);
  assert.equal(g.json().runtime, 'vm');
  assert.ok(g.json().fixups.some((f: { value?: string }) => f.value === 'rosetta2'));
  assert.equal(g.json().community.total, 0);
  assert.equal((await app.inject({ method: 'GET', url: '/v1/compat/apps/nope' })).statusCode, 404);
  const p = await app.inject({ method: 'GET', url: '/v1/compat/presets' });
  assert.ok(p.json()['cad-graphics']);
  const rt = await app.inject({ method: 'POST', url: '/v1/compat/route', payload: { arch: 'x64', needs_driver: true } });
  assert.equal(rt.json().runtime, 'vm');
  const rep = await app.inject({ method: 'POST', url: '/v1/compat/reports', payload: { app_id: 'autocad', result: 'works_with_fixups', mac_model: 'Mac16,6', macos_version: '26.0' } });
  assert.equal(rep.statusCode, 202);
  assert.equal((await app.inject({ method: 'GET', url: '/v1/compat/apps/autocad' })).json().community.works_with_fixups, 1);
  assert.equal((await app.inject({ method: 'POST', url: '/v1/compat/reports', payload: { app_id: 'autocad', result: 'meh' } })).statusCode, 400);
});

test('stripe webhook uses the raw body for signatures; disabled providers return 503', async () => {
  const { app, env } = make();
  const body = JSON.stringify({ id: 'evt_http_1', type: 'checkout.session.completed', data: { object: { mode: 'payment', payment_intent: 'pi_http', metadata: { product_id: 'com.mirrorz.standard.perpetual' } } } });
  const t = env.clock.now;
  const sig = `t=${t},v1=${createHmac('sha256', 'whsec_x').update(`${t}.${body}`).digest('hex')}`;
  const ok = await app.inject({ method: 'POST', url: '/v1/stripe/webhook', headers: { 'content-type': 'application/json', 'stripe-signature': sig }, payload: body });
  assert.equal(ok.statusCode, 200, ok.body);
  assert.equal(ok.json().action, 'perpetual_active');
  const badSig = await app.inject({ method: 'POST', url: '/v1/stripe/webhook', headers: { 'content-type': 'application/json', 'stripe-signature': 't=1,v1=00' }, payload: body });
  assert.equal(badSig.statusCode, 401);
  assert.equal((await app.inject({ method: 'POST', url: '/v1/apple/notifications', payload: { signedPayload: 'a'.repeat(30) } })).statusCode, 503);
  assert.equal((await app.inject({ method: 'POST', url: '/v1/google/rtdn', payload: {} })).statusCode, 503);
  const badJson = await app.inject({ method: 'POST', url: '/v1/licenses/refresh', headers: { 'content-type': 'application/json' }, payload: '{not json' });
  assert.equal(badJson.statusCode, 400);
});

test('trial endpoint issues a device-bound trial and is idempotent', async () => {
  const { app } = make();
  const a = await app.inject({ method: 'POST', url: '/v1/trials', payload: { device: { id: 'trial-device-0001', platform: 'macos' } } });
  assert.equal(a.statusCode, 201, a.body);
  assert.equal(a.json().license.kind, 'trial');
  const b = await app.inject({ method: 'POST', url: '/v1/trials', payload: { device: { id: 'trial-device-0001', platform: 'macos' } } });
  assert.equal(b.statusCode, 200);
  assert.equal(b.json().license.id, a.json().license.id);
});
