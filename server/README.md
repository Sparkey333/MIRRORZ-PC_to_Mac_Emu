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
| Remote (pairing + signaling) | `POST /v1/remote/pairings`, `GET /v1/remote/ice`, `GET /v1/remote/ws?role=host\|client&…` (WebSocket) | Spec: `docs/spec/remote-protocol.md`. Devices authenticate with their `MZL1` token; 6-symbol single-use pairing codes (10 min); rooms die with the host; SDP/ICE relayed as validated JSON (64 KiB max, rate limited); `MZP1` grants for reconnecting without a code; STUN/TURN with time-limited HMAC credentials. Code in `src/remote/`. |

## Entitlement model

* **Perpetual** — never expires. `updates_until` (default 365 days) gates *feature* updates; security updates are unlimited by policy. Default 3 Macs (Standard) / 5 (Pro).
* **Subscription** — entitled until `expires_at + GRACE_DAYS` (default 7). Billing retry / grace from Apple/Google extends `expires_at`.
* **Trial** — 1 device, no grace.
* Refund / revoke / void → all activations revoked, tokens refuse to refresh, offline clients lose entitlement when their token `exp` passes (30 days by default).

Store product ids are one table (`src/billing/products.ts`) and must match App Store Connect, Play Console and Stripe price `lookup_key`s.

## MIRRORZ Remote

`src/remote/` implements pairing and WebRTC signaling for the iOS/Android companions (protocol v1, `docs/spec/remote-protocol.md`):

| Endpoint | Purpose |
|---|---|
| `POST /v1/remote/pairings` `{ token, name? }` | Mac creates a room and a single-use 6-symbol code (`201 { code, display, room_id, host_hash, expires_at, ws_url, deep_link }`). |
| `GET /v1/remote/ice` (`Authorization: Bearer <MZL1>`) | `{ iceServers, ttl, expires_at }` — STUN plus TURN with time-limited HMAC-SHA1 credentials when `TURN_SECRET` is set. |
| `GET /v1/remote/ws?role=host&room=…` / `?role=client&code=…` or `&grant=…` | Signaling WebSocket. `hello`, `peer-joined`/`peer-left` (host), relayed `offer`/`answer`/`ice`/`apps`/`launch`/`input`/`error`/`bye` with a server-stamped `from`. Max 64 KiB per message; per-connection rate limits; one host + `REMOTE_MAX_CLIENTS` clients per room. |

Requires the `mobile-companion` feature (Standard and above). Environment: `REMOTE_MAX_CLIENTS` (8), `REMOTE_GRANT_DAYS` (90), `REMOTE_PUBLIC_WS_URL`, `STUN_URLS` (default `stun:stun.mirrorz.app:3478`), `TURN_URL`, `TURN_SECRET`, `TURN_USER`, `TURN_PASS`, `TURN_TTL_SECONDS` (21600). The media path (H.264 over WebRTC, `mz-input` data channel) is peer-to-peer; the server never sees pixels or input. Request logs omit query strings and client IPs.

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
