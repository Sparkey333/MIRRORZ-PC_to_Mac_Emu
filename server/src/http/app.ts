import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { z } from 'zod';
import type { AppleBilling } from '../billing/apple.js';
import type { GoogleBilling, RtdnPush } from '../billing/google.js';
import type { StripeBilling } from '../billing/stripe.js';
import type { CompatService } from '../compat/service.js';
import { publicKeyJwk, publicKeyRawB64Url, type SigningKeys } from '../license/keys.js';
import type { LicenseService } from '../license/service.js';
import { HttpError } from '../util.js';
import { RateLimiter } from './ratelimit.js';

export interface AppDeps {
  licenses: LicenseService;
  keys: SigningKeys;
  compat: CompatService;
  apple?: AppleBilling;
  google?: GoogleBilling;
  stripe?: StripeBilling;
  adminToken?: string;
  logger?: boolean | object;
  googlePushToken?: string;
}

const DeviceSchema = z.object({
  id: z.string().min(8).max(200),
  name: z.string().max(120).optional(),
  platform: z.enum(['macos', 'ios', 'ipados', 'android', 'web']).optional(),
  os_version: z.string().max(40).optional(),
  app_version: z.string().max(40).optional(),
});

const ActivateSchema = z.object({ key: z.string().min(10).max(60), device: DeviceSchema });
const RefreshSchema = z.object({ token: z.string().min(20).max(4096) });
const DeactivateSchema = z.object({ key: z.string().min(10).max(60), device_id: z.string().min(8).max(200) });
const AppleNotificationSchema = z.object({ signedPayload: z.string().min(20) });
const AppleLinkSchema = z.object({ signedTransaction: z.string().min(20), device: DeviceSchema });
const GoogleLinkSchema = z.object({ purchaseToken: z.string().min(10), productId: z.string().min(3), device: DeviceSchema });
const ReportSchema = z.object({
  app_id: z.string().min(1).max(80),
  app_version: z.string().max(40).optional(),
  runtime: z.enum(['vm', 'bottle', 'either']).optional(),
  result: z.enum(['works', 'works_with_fixups', 'partial', 'broken']),
  mac_model: z.string().max(80).optional(),
  macos_version: z.string().max(40).optional(),
  mirrorz_version: z.string().max(40).optional(),
  notes: z.string().max(500).optional(),
});
const AdminIssueSchema = z.object({
  kind: z.enum(['perpetual', 'subscription', 'trial']),
  plan: z.enum(['standard', 'pro', 'business', 'trial']),
  email: z.string().email().optional(),
  max_devices: z.number().int().min(1).max(1000).optional(),
  expires_at: z.number().int().optional(),
  source_ref: z.string().max(200).optional(),
});

function parse<T>(schema: z.ZodType<T>, body: unknown): T {
  const r = schema.safeParse(body);
  if (!r.success) throw new HttpError(400, r.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; '), 'validation');
  return r.data;
}

function clientIp(req: FastifyRequest): string {
  const xff = req.headers['x-forwarded-for'];
  if (typeof xff === 'string' && xff.length > 0) return xff.split(',')[0]!.trim();
  return req.ip;
}

declare module 'fastify' {
  interface FastifyRequest {
    rawBody?: string;
  }
}

export function buildApp(deps: AppDeps): FastifyInstance {
  const app = Fastify({ logger: deps.logger ?? false, trustProxy: true });
  const activateLimiter = new RateLimiter(20, 0.2); // 20 burst, 1 per 5 s sustained per IP
  const reportLimiter = new RateLimiter(30, 0.05);

  // Keep the raw body: Stripe signatures are computed over the exact bytes.
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
    req.rawBody = body as string;
    if ((body as string).length === 0) return done(null, {});
    try {
      done(null, JSON.parse(body as string));
    } catch {
      done(new HttpError(400, 'invalid JSON body', 'bad_json'), undefined);
    }
  });

  app.setErrorHandler((err, _req, reply) => {
    if (err instanceof HttpError) {
      return reply.status(err.status).send({ error: err.code, message: err.message });
    }
    const status = (err as { statusCode?: number }).statusCode ?? 500;
    app.log.error(err);
    return reply.status(status).send({ error: status === 500 ? 'internal' : 'error', message: status === 500 ? 'internal error' : (err as Error).message });
  });

  const requireAdmin = (req: FastifyRequest): void => {
    const auth = req.headers.authorization ?? '';
    if (!deps.adminToken || auth !== `Bearer ${deps.adminToken}`) throw new HttpError(401, 'admin token required', 'unauthorized');
  };

  app.get('/healthz', async () => ({ ok: true, compat_version: deps.compat.version(), kid: deps.keys.kid }));

  app.get('/.well-known/mirrorz-license-key.json', async () => ({
    keys: [publicKeyJwk(deps.keys.publicKey)],
    raw: publicKeyRawB64Url(deps.keys.publicKey),
    format: 'MZL1.<base64url(json claims)>.<base64url(ed25519 signature over "MZL1.<payload>")>',
  }));

  // ---------- licenses ----------
  app.post('/v1/licenses/activate', async (req) => {
    if (!activateLimiter.allow(clientIp(req))) throw new HttpError(429, 'too many activation attempts', 'rate_limited');
    const body = parse(ActivateSchema, req.body);
    return deps.licenses.activate(body.key, body.device);
  });

  app.post('/v1/trials', async (req, reply) => {
    if (!activateLimiter.allow(clientIp(req))) throw new HttpError(429, 'too many requests', 'rate_limited');
    const body = parse(z.object({ device: DeviceSchema }), req.body);
    const r = deps.licenses.startTrial(body.device);
    return reply.status(r.existing ? 200 : 201).send(r);
  });

  app.post('/v1/licenses/refresh', async (req) => {
    const body = parse(RefreshSchema, req.body);
    return deps.licenses.refresh(body.token);
  });

  app.post('/v1/licenses/deactivate', async (req) => {
    const body = parse(DeactivateSchema, req.body);
    const lic = deps.licenses.findByKey(body.key);
    if (!lic) throw new HttpError(404, 'license key not found', 'not_found');
    return { deactivated: deps.licenses.deactivate(lic.id, body.device_id), license: deps.licenses.view(lic) };
  });

  app.get('/v1/licenses/status', async (req) => {
    if (!activateLimiter.allow(clientIp(req))) throw new HttpError(429, 'too many requests', 'rate_limited');
    const key = (req.query as { key?: string }).key;
    if (!key) throw new HttpError(400, 'key query parameter required', 'validation');
    const lic = deps.licenses.findByKey(key);
    if (!lic) throw new HttpError(404, 'license key not found', 'not_found');
    return deps.licenses.view(lic);
  });

  // ---------- apple ----------
  app.post('/v1/apple/notifications', async (req, reply) => {
    if (!deps.apple) throw new HttpError(503, 'apple billing disabled', 'disabled');
    const body = parse(AppleNotificationSchema, req.body);
    const r = deps.apple.handleNotification(body.signedPayload);
    return reply.status(200).send(r);
  });

  app.post('/v1/apple/link', async (req) => {
    if (!deps.apple) throw new HttpError(503, 'apple billing disabled', 'disabled');
    if (!activateLimiter.allow(clientIp(req))) throw new HttpError(429, 'too many requests', 'rate_limited');
    const body = parse(AppleLinkSchema, req.body);
    return deps.apple.linkTransaction(body.signedTransaction, body.device);
  });

  // ---------- google ----------
  app.post('/v1/google/rtdn', async (req) => {
    if (!deps.google) throw new HttpError(503, 'google billing disabled', 'disabled');
    const token = (req.query as { token?: string }).token;
    return deps.google.handleRtdn(req.body as RtdnPush, token);
  });

  app.post('/v1/google/link', async (req) => {
    if (!deps.google) throw new HttpError(503, 'google billing disabled', 'disabled');
    if (!activateLimiter.allow(clientIp(req))) throw new HttpError(429, 'too many requests', 'rate_limited');
    const body = parse(GoogleLinkSchema, req.body);
    return deps.google.linkPurchase(body);
  });

  // ---------- stripe ----------
  app.post('/v1/stripe/webhook', async (req) => {
    if (!deps.stripe) throw new HttpError(503, 'stripe billing disabled', 'disabled');
    const sig = req.headers['stripe-signature'];
    return deps.stripe.handleWebhook(req.rawBody ?? JSON.stringify(req.body ?? {}), typeof sig === 'string' ? sig : undefined);
  });

  // ---------- compatibility database ----------
  app.get('/v1/compat/apps', async (req) => {
    const q = req.query as { q?: string; category?: string; runtime?: string };
    return { version: deps.compat.version(), apps: deps.compat.search(q.q, q.category, q.runtime) };
  });

  app.get('/v1/compat/apps/:id', async (req) => deps.compat.get((req.params as { id: string }).id));

  app.get('/v1/compat/presets', async () => deps.compat.presets());

  app.post('/v1/compat/route', async (req) => deps.compat.routeUnknown((req.body ?? {}) as Parameters<CompatService['routeUnknown']>[0]));

  app.post('/v1/compat/reports', async (req, reply) => {
    if (!reportLimiter.allow(clientIp(req))) throw new HttpError(429, 'too many reports', 'rate_limited');
    const body = parse(ReportSchema, req.body);
    return reply.status(202).send(deps.compat.report(body));
  });

  // ---------- admin ----------
  app.post('/v1/admin/licenses', async (req, reply) => {
    requireAdmin(req);
    const body = parse(AdminIssueSchema, req.body);
    const r = deps.licenses.issue({
      kind: body.kind,
      plan: body.plan,
      source: 'manual',
      ...(body.email ? { email: body.email } : {}),
      ...(body.max_devices !== undefined ? { maxDevices: body.max_devices } : {}),
      ...(body.expires_at !== undefined ? { expiresAt: body.expires_at } : {}),
      ...(body.source_ref ? { sourceRef: body.source_ref } : {}),
    });
    return reply.status(201).send({ key: r.key, license: deps.licenses.view(r.license) });
  });

  app.post('/v1/admin/licenses/:id/revoke', async (req) => {
    requireAdmin(req);
    const id = (req.params as { id: string }).id;
    const reason = ((req.body as { reason?: string } | undefined)?.reason ?? 'admin').slice(0, 200);
    return deps.licenses.view(deps.licenses.revoke(id, reason));
  });

  app.get('/v1/admin/licenses/:id', async (req) => {
    requireAdmin(req);
    const lic = deps.licenses.getById((req.params as { id: string }).id);
    if (!lic) throw new HttpError(404, 'license not found', 'not_found');
    return deps.licenses.view(lic);
  });

  return app;
}
