# MIRRORZ platform contracts (v1)

_Shared by the macOS app, iOS/Android companions, the website, and the server. Every client is built against this document. Server code under `server/` is the reference implementation._

## 1. Product identity

| Item | Value |
|---|---|
| Product name | **MIRRORZ** (all caps in marketing; "Mirrorz" in prose is acceptable) |
| One-liner | Run Windows and PC software on your Mac. AutoCAD-ready. No ads, ever. |
| Bundle ids | macOS `com.mirrorz.app` · iOS `com.mirrorz.companion` · Android `com.mirrorz.companion` |
| App Group (Apple) | `group.com.mirrorz` |
| Keychain service | `com.mirrorz.license` |
| Custom URL scheme | `mirrorz://` (deep links: `mirrorz://activate?key=…`, `mirrorz://pair?code=…`, `mirrorz://app/<compat-id>`) |
| Universal links domain | `https://mirrorz.app` (`/activate`, `/pair`, `/apps/<id>`) |
| Server base URL | `https://api.mirrorz.app` (dev: `http://localhost:8787`) |

### Vocabulary (use these words in UI, docs, code)
| Term | Meaning |
|---|---|
| **App** | A Windows/PC program the user wants to run. Apps are the primary object; the user launches Apps, not machines. |
| **Machine** | A full Windows/Linux virtual machine (VM). |
| **Bottle** | A lightweight Wine-based environment (no Windows license needed). |
| **Runtime** | Where an App runs: `vm`, `bottle`, or `either`. |
| **App Router** | The decision engine that picks a Runtime for an App and applies Fix-ups. |
| **Fix-up** | A per-App adjustment (env var, registry value, VM setting, preset). Sourced from the Compatibility Database. |
| **Mirror Mode** | Seamless windows: a Windows app window appears as a native macOS window (Parallels calls this Coherence). |
| **Preset** | A bundle of Machine/Bottle settings (`cad-graphics`, `office`, `gaming`). |
| **Pairing** | Linking a phone/tablet companion to a Mac for remote view/control and license sync. |

## 2. Plans, features, pricing

Plans: `standard`, `pro`, `business`, `trial`. Prices live in `pricing/pricing.json` (provisional). Feature flags (exact strings, shipped inside tokens; see `server/src/license/plans.ts`):

```
trial:    vm bottles coherence compat-db
standard: + snapshots cad-presets mobile-companion no-ads
pro:      + cli api nested-virt linked-clones pro-tools cloud-sync priority-support network-lab
business: + mdm sso volume-licensing golden-images audit-log
```

Store product ids (identical on App Store Connect, Google Play, Stripe `lookup_key`):
```
com.mirrorz.standard.monthly   com.mirrorz.standard.annual   com.mirrorz.standard.perpetual
com.mirrorz.pro.monthly        com.mirrorz.pro.annual        com.mirrorz.pro.perpetual
com.mirrorz.business.annual
```
Perpetual = non-consumable IAP (Apple) / one-time product (Google) / Stripe payment-mode checkout.

## 3. Licensing protocol

### 3.1 Device id
A stable, opaque, client-generated id, 32–64 chars, stored in the platform keychain so it survives reinstalls:
* macOS: `sha256(IOPlatformUUID + "com.mirrorz.app")` hex.
* iOS/iPadOS: random UUID generated once, stored in Keychain (identifierForVendor is not stable enough).
* Android: random UUID generated once, stored in EncryptedSharedPreferences (never `ANDROID_ID` alone).

### 3.2 Endpoints (JSON; all `POST` bodies are JSON)
| Endpoint | Body | Returns |
|---|---|---|
| `POST /v1/trials` | `{ device }` | `{ token, license, existing }` — 14-day trial, one per device |
| `POST /v1/licenses/activate` | `{ key, device }` | `{ token, license }` · 404 unknown key · 403 not entitled · 409 device limit |
| `POST /v1/licenses/refresh` | `{ token }` | `{ token, license }` · 401 bad token · 403 revoked/expired |
| `POST /v1/licenses/deactivate` | `{ key, device_id }` | `{ deactivated, license }` |
| `GET /v1/licenses/status?key=` | — | `license` view (devices, entitlement) |
| `POST /v1/apple/link` | `{ signedTransaction, device }` | `{ token, license, key }` (key non-null only on first link) |
| `POST /v1/google/link` | `{ purchaseToken, productId, device }` | `{ token, license, key }` |
| `GET /.well-known/mirrorz-license-key.json` | — | `{ keys:[{kty:"OKP",crv:"Ed25519",x,kid}], raw }` |

`device` = `{ id, name?, platform: macos|ios|ipados|android|web, os_version?, app_version? }`.
Errors: `{ error: <code>, message }`. Codes: `validation`, `not_found`, `device_limit`, `expired`, `revoked`, `refunded`, `paused`, `bad_token`, `not_activated`, `rate_limited`, `trial_used`.

### 3.3 Human license key
`MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`, Crockford base32 alphabet `0123456789ABCDEFGHJKMNPQRSTVWXYZ`, 24 random symbols + 1 Luhn-mod-32 check symbol. Clients MUST normalize before sending: uppercase, strip `- _ .` and whitespace, map `O→0`, `I→1`, `L→1`, strip leading `MZ`. Clients SHOULD validate the check symbol locally to give instant feedback.

### 3.4 Device token (offline entitlement)
```
MZL1.<base64url(JSON claims)>.<base64url(Ed25519 signature over UTF-8 "MZL1.<payload>")>
claims: { v:1, kid, lid, kind: perpetual|subscription|trial, plan, product:"mirrorz",
          features:[...], dev, max_dev, iat, exp, sub_exp?, upd? }   // all times = Unix seconds
```
Client rules:
1. Verify the signature with an embedded list of public keys `[{kid, x}]` (raw 32-byte Ed25519, base64url). Reject if `kid` unknown or `dev` ≠ local device id.
2. `kind=perpetual`: entitled forever. Feature updates allowed for builds whose `buildDate <= upd`; newer builds run in "updates expired" mode: fully functional, no new-feature gating, banner offering the upgrade price. `exp` only schedules a background refresh.
3. `kind=subscription|trial`: entitled while `now < sub_exp`. Refresh every 24 h when online (silently). If refresh fails with 403, drop entitlement immediately; on network errors keep working until `sub_exp`.
4. Never phone home more than once per day per device for licensing. Never block app launch on the network.
5. Store the token in the keychain; expose `features` to the UI via a single `Entitlements` observable.

### 3.5 In-app purchase flow
* Apple: StoreKit 2. After `Product.purchase()` succeeds (or on `Transaction.currentEntitlements` at launch), send `transaction.jwsRepresentation` to `/v1/apple/link`. Always call `transaction.finish()` only after the server responds 2xx. Offer "Restore Purchases".
* Google: Play Billing Library 7+. After purchase, send `purchaseToken` + `productId` to `/v1/google/link`; the server acknowledges the purchase. Do not acknowledge on the client.
* Direct (Stripe): the website checkout emails a key; the app's "Enter license key" screen accepts it (and `mirrorz://activate?key=`).
* A user who bought on a phone gets a key back on first link; the Mac app shows "Enter key" and an "I bought on iPhone/Android" hint.

## 4. Compatibility Database
`GET /v1/compat/apps?q=&category=&runtime=` → `{ version, apps:[CompatApp] }`; `GET /v1/compat/apps/:id` (adds `community` counts); `GET /v1/compat/presets`; `POST /v1/compat/route { arch, needs_driver, needs_service, dotnet, dx }` → `{ runtime, reason }`; `POST /v1/compat/reports` (opt-in, anonymous). Schema in `server/src/compat/service.ts`; seed in `server/src/compat/seed.json`. Clients cache the catalog for 24 h and ship a bundled copy of the seed for offline use.

Ratings: `gold` (works out of the box) · `silver` (works with fix-ups) · `bronze` (usable, known issues) · `broken` · `n/a` (use the native Mac version).

## 5. Client architecture

### 5.1 Repository layout
```
core/            Rust crate `mirrorz-core` (uniffi): license verification, key normalization, App Router, models
apps/macos/      SwiftUI macOS app (XcodeGen project.yml, SwiftPM local packages)
apps/ios/        SwiftUI companion (XcodeGen)
apps/android/    Kotlin + Jetpack Compose companion (Gradle KTS)
server/          Node 22 TypeScript service (reference implementation of this spec)
website/         Static marketing/pricing/docs site
store/           App Store Connect / Play Console listing metadata, privacy labels, review notes
docs/            research, spec, architecture
```

### 5.2 macOS app (SwiftUI, macOS 14+, Apple Silicon first; Intel via Rosetta-free universal build where feasible)
Sidebar sections: **Home**, **Apps**, **Machines**, **Bottles**, **Compatibility**, **Remote**, **Settings**.
* Home: "Drop an installer or .exe here" hero; recent Apps; health (Rosetta, disk, memory); one-click "Set up Windows".
* Apps: grid of installed Apps (icon extracted from the .exe), each launches directly into Mirror Mode; per-App settings (Runtime, Preset, Fix-ups, Dock icon, file associations).
* Machines: list + detail (CPU/RAM/disk/GPU/shared folders/snapshots/clones), console window, Mirror Mode toggle, Windows setup wizard (downloads Windows 11 ARM ISO/ESD from Microsoft after the user accepts Microsoft's terms; never redistributes Windows).
* Bottles: list + detail (Windows version, DXMT/D3DMetal toggle, runtimes installed, winetricks-style components), "Install app into bottle" flow.
* Compatibility: searchable catalog from §4 with rating chips and "Install this" actions.
* Remote: pairing QR code, connected devices, stream quality.
* Settings: General · License & Plans (plan, devices, buy/restore, enter key) · Engines (VM backend, Bottle engine versions) · Privacy (all telemetry OFF by default; a single "Send anonymous compatibility reports" toggle) · Advanced (CLI install for Pro, logs).
Engines are behind protocols: `VMEngine` (implementations: `VZEngine` for Linux/macOS guests on Virtualization.framework; `QEMUEngine` for Windows-on-ARM via QEMU+HVF, spawned as a helper process), `BottleEngine` (Wine). The App Router sits above both.

### 5.3 Companions (iOS 17+ / Android 10+)
Tabs: **Remote** (view/control a paired Mac's Apps and Machines; WebRTC H.264, Bonjour/LAN first, relay fallback), **Apps** (Compatibility catalog + "send install to Mac"), **License** (plan, devices, buy/restore, show key, deactivate a Mac), **Settings**. Purchases made on the phone entitle the Mac via §3.5.

### 5.4 Design language
Dark-first with full light mode. Background `#0B0F1A`, surface `#121826`, border `#1F2937`, text `#E5E7EB`/`#9CA3AF`, accent cyan `#22D3EE`, accent violet `#8B5CF6`, success `#34D399`, warning `#FBBF24`, danger `#F87171`. Corner radius 12, 8 for chips. Typography: SF Pro (Apple), Roboto (Android), Inter (web). Icons: SF Symbols / Material Symbols. Motion: 200 ms ease-out. Every destructive action confirms. No modal upsells; plan upgrades live only in Settings › License and on a feature's locked state.

## 6. Privacy & telemetry
No analytics SDKs. No crash reporting unless the user opts in. Compatibility reports (§4) are the only outbound data beyond licensing, and they contain no identifiers. Licensing calls send only the device record from §3.2. Documented in `store/privacy-policy.md`.

## 7. Versioning
Semantic versions, shared across all apps (`1.0.0`). Client `app_version` in the device record uses this. Server compat catalog `version` is a date string.
