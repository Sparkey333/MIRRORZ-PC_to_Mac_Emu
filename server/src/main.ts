import { AppleBilling } from './billing/apple.js';
import { GoogleBilling, GooglePlayApiClient } from './billing/google.js';
import { ConsoleMailer, ResendMailer } from './billing/mailer.js';
import { StripeBilling } from './billing/stripe.js';
import { CompatService } from './compat/service.js';
import { loadConfig } from './config.js';
import { openDb } from './db.js';
import { buildApp } from './http/app.js';
import { generateSigningKeys, loadSigningKeys } from './license/keys.js';
import { LicenseService } from './license/service.js';
import { createRemote } from './remote/index.js';

const cfg = loadConfig();
const db = openDb(cfg.dbPath);
const keys = cfg.licenseSigningKeyPem ? loadSigningKeys(cfg.licenseSigningKeyPem) : generateSigningKeys();
if (!cfg.licenseSigningKeyPem) {
  console.warn('[mirrorz] LICENSE_SIGNING_KEY_PEM not set: using an EPHEMERAL signing key. Tokens will not survive a restart. Run `npm run keygen`.');
}
const licenses = new LicenseService(db, keys, cfg);
const compat = new CompatService(db);

const mailer = process.env['RESEND_API_KEY'] && process.env['MAIL_FROM']
  ? new ResendMailer(process.env['RESEND_API_KEY'], process.env['MAIL_FROM'])
  : new ConsoleMailer();

let apple: AppleBilling | undefined;
try {
  apple = new AppleBilling(db, licenses, { bundleId: cfg.apple.bundleId, environment: cfg.apple.environment, ...(cfg.apple.rootCaPem ? { rootCertsPem: [cfg.apple.rootCaPem] } : {}) });
} catch (e) {
  console.warn(`[mirrorz] Apple billing disabled: ${(e as Error).message}`);
}

let google: GoogleBilling | undefined;
if (cfg.google.serviceAccountJson) {
  const sa = JSON.parse(cfg.google.serviceAccountJson) as { client_email: string; private_key: string };
  google = new GoogleBilling(db, licenses, new GooglePlayApiClient(cfg.google.packageName, sa), { packageName: cfg.google.packageName, ...(cfg.google.pushToken ? { pushToken: cfg.google.pushToken } : {}) });
} else {
  console.warn('[mirrorz] Google Play billing disabled: GOOGLE_SERVICE_ACCOUNT_JSON not set');
}

const stripe = new StripeBilling(db, licenses, mailer, { ...(cfg.stripe.webhookSecret ? { webhookSecret: cfg.stripe.webhookSecret } : {}) });
if (!cfg.stripe.webhookSecret) console.warn('[mirrorz] STRIPE_WEBHOOK_SECRET not set: Stripe webhook signatures are NOT verified (dev only)');

const remote = createRemote({ licenses, keys });

const app = buildApp({
  licenses,
  keys,
  compat,
  ...(apple ? { apple } : {}),
  ...(google ? { google } : {}),
  stripe,
  ...(cfg.adminToken ? { adminToken: cfg.adminToken } : {}),
  remote,
  logger: {
    level: cfg.logLevel,
    // Privacy: never log query strings (device tokens / pairing codes travel there) or client IPs.
    serializers: {
      req: (req: { method?: string; url?: string }) => ({ method: req.method, url: String(req.url ?? '').split('?')[0] }),
    },
  },
});

app.listen({ port: cfg.port, host: cfg.host }).then((addr) => {
  console.log(`[mirrorz] licensing server listening on ${addr} (kid=${keys.kid}, compat=${compat.version()}, remote=on)`);
});
