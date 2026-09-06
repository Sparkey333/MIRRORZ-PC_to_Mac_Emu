export type AppleEnvironment = 'Sandbox' | 'Production' | 'any';

export interface Config {
  port: number;
  host: string;
  dbPath: string;
  /** PKCS#8 PEM for the Ed25519 license-signing key. Undefined = ephemeral dev key. */
  licenseSigningKeyPem: string | undefined;
  apple: {
    bundleId: string;
    environment: AppleEnvironment;
    /** Optional override of the pinned Apple Root CA G3 PEM (tests). */
    rootCaPem: string | undefined;
  };
  google: {
    packageName: string;
    serviceAccountJson: string | undefined;
    /** Shared secret expected as ?token= on the Pub/Sub push endpoint. */
    pushToken: string | undefined;
  };
  stripe: {
    webhookSecret: string | undefined;
  };
  adminToken: string | undefined;
  /** Days a subscription keeps working after its paid period ends (billing retry / grace). */
  graceDays: number;
  /** Days of feature updates included with a perpetual license. */
  perpetualUpdateDays: number;
  /** Lifetime of an issued device token before the client must refresh (offline allowance). */
  tokenTtlDays: number;
  /** Default device limits per plan. */
  deviceLimits: Record<string, number>;
  logLevel: string;
}

function int(v: string | undefined, dflt: number): number {
  if (v === undefined || v === '') return dflt;
  const n = Number(v);
  return Number.isFinite(n) ? n : dflt;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const appleEnv = (env['APPLE_ENVIRONMENT'] ?? 'any') as AppleEnvironment;
  return {
    port: int(env['PORT'], 8787),
    host: env['HOST'] ?? '0.0.0.0',
    dbPath: env['DB_PATH'] ?? './data/mirrorz.sqlite',
    licenseSigningKeyPem: env['LICENSE_SIGNING_KEY_PEM'] || undefined,
    apple: {
      bundleId: env['APPLE_BUNDLE_ID'] ?? 'com.mirrorz.app',
      environment: appleEnv,
      rootCaPem: env['APPLE_ROOT_CA_PEM'] || undefined,
    },
    google: {
      packageName: env['GOOGLE_PACKAGE_NAME'] ?? 'com.mirrorz.companion',
      serviceAccountJson: env['GOOGLE_SERVICE_ACCOUNT_JSON'] || undefined,
      pushToken: env['GOOGLE_PUSH_TOKEN'] || undefined,
    },
    stripe: {
      webhookSecret: env['STRIPE_WEBHOOK_SECRET'] || undefined,
    },
    adminToken: env['ADMIN_TOKEN'] || undefined,
    graceDays: int(env['GRACE_DAYS'], 7),
    perpetualUpdateDays: int(env['PERPETUAL_UPDATE_DAYS'], 365),
    tokenTtlDays: int(env['TOKEN_TTL_DAYS'], 30),
    deviceLimits: {
      standard: int(env['DEVICE_LIMIT_STANDARD'], 3),
      pro: int(env['DEVICE_LIMIT_PRO'], 5),
      business: int(env['DEVICE_LIMIT_BUSINESS'], 10),
      trial: 1,
    },
    logLevel: env['LOG_LEVEL'] ?? 'info',
  };
}
