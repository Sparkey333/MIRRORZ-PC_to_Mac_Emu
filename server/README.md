# MIRRORZ licensing & compatibility service

Single Node 22 service (no native dependencies) that backs every MIRRORZ client:

| Concern | Endpoint(s) | Notes |
|---|---|---|
| License keys | `POST /v1/licenses/activate`, `/refresh`, `/deactivate`, `GET /v1/licenses/status` | Human keys `MZ-XXXXX-…` (Crockford base32 + Luhn-mod-32 check). Server stores only `sha256(key)`. |
| Device tokens | returned by activate/refresh | `MZL1.<claims>.<sig>` signed with Ed25519. Clients verify offline with the embedded public key (`/.well-known/mirrorz-license-key.json`). Perpetual tokens never lose entitlement; `exp` is only a refresh hint. |
| Apple in-app purchases | `POST /v1/apple/notifications` (App Store Server Notifications V2), `POST /v1/apple/link` (StoreKit 2 `jwsRepresentation`) | JWS x5c chain verified against Apple Root CA G3 (fetch with `scripts/fetch-apple-root.sh`). |
| Google Play | `POST /v1/google/rtdn?token=…` (Pub/Sub push), `POST /v1/google/link` | Never trusts the push payload; re-reads state from the Play Developer API with a service account. |
| Direct sales | `POST /v1/stripe/webhook` | Signature verified over the raw body; keys are emailed (Resend) or logged in dev. |
| Compatibility DB | `GET /v1/compat/apps`, `/apps/:id`, `/presets`, `POST /v1/compat/route`, `POST /v1/compat/reports` | Curated profiles in `src/compat/seed.json` plus anonymous opt-in community reports. |
| Admin | `POST /v1/admin/licenses`, `/v1/admin/licenses/:id/revoke`, `GET /v1/admin/licenses/:id` | Bearer `ADMIN_TOKEN`. |

## Entitlement model

* **Perpetual** — never expires. `updates_until` (default 365 days) gates *feature* updates; security updates are unlimited by policy. Default 3 Macs (Standard) / 5 (Pro).
* **Subscription** — entitled until `expires_at + GRACE_DAYS` (default 7). Billing retry / grace from Apple/Google extends `expires_at`.
* **Trial** — 1 device, no grace.
* Refund / revoke / void → all activations revoked, tokens refuse to refresh, offline clients lose entitlement when their token `exp` passes (30 days by default).

Store product ids are one table (`src/billing/products.ts`) and must match App Store Connect, Play Console and Stripe price `lookup_key`s.

## Run

```bash
npm install
npm run keygen            # print an Ed25519 keypair; put the private PEM in LICENSE_SIGNING_KEY_PEM
cp .env.example .env
scripts/fetch-apple-root.sh   # needs network access to apple.com
npm run dev               # http://localhost:8787/healthz
npm test
```

## Privacy by construction

No raw emails (hashed), no IPs stored, no device fingerprints beyond the client-generated id, compatibility reports carry only hardware class + result. This is the "no telemetry surprises" promise from the research.
