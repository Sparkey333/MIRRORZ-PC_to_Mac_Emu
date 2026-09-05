# MirrorzKit

Swift package shared by the MIRRORZ macOS app (`apps/macos`) and the iOS companion (`apps/ios`).
It implements the client side of `docs/spec/platform-contracts.md` against the reference server in
`server/`: licensing, StoreKit 2 purchases, the Compatibility Database, the companion remote
protocol, and the design system.

- Swift tools 5.9 · platforms macOS 14 / iOS 17 · Swift 5 language mode with strict-concurrency diagnostics on
- Dependencies: none (Foundation, CryptoKit, Security, IOKit, StoreKit, SwiftUI, Observation)
- Resources: `Sources/MirrorzKit/Resources/compat-seed.json` (byte-identical copy of `server/src/compat/seed.json`)

## Layout

```
Sources/MirrorzKit/
  MirrorzKit.swift            MirrorzIdentity (bundle ids, URLs, keychain service), BuildInfo (version + build date)
  Models/                     Plan, LicenseKind, PurchaseTerm, LicenseStatus, Feature, StoreProductID, Platform
  Licensing/
    LicenseKey.swift          normalize / isValid / format / canonical / formatPartial / validation (mirror of keyformat.ts)
    LicenseToken.swift        LicenseClaims, TrustedKey(s), LicenseToken.verify, LicenseTokenError, Base64URL
    Entitlements.swift        @MainActor @Observable Entitlements — the single observable the UI consults
    LicenseClient.swift       actor LicenseClient + wire types (DeviceRecord, LicenseView, …), APIError/APIErrorCode
    KeychainStore.swift       SecureStore protocol, KeychainStore (service com.mirrorz.license), InMemorySecureStore
    DeviceIdentity.swift      device id (§3.1) and the device record (§3.2)
  Networking/HTTPTransport.swift  HTTPTransport protocol, URLSessionTransport, request builder, error-envelope decoding
  Store/StoreKitManager.swift @MainActor @Observable StoreKit 2 manager (products, purchase, updates, restore, link)
  Compat/CompatModels.swift   Codable mirror of seed.json / compat service (apps, fix-ups, presets, community, reports, routing)
  Compat/CompatClient.swift   actor CompatClient — 24 h disk cache, bundled seed fallback, search, detail, route, report
  Remote/RemoteProtocol.swift pairing codes/links, MZP1 grants, socket handshake, close codes, messages, input events, ICE, Bonjour
  Remote/RemoteClient.swift   actor RemoteClient — POST /v1/remote/pairings, GET /v1/remote/ice, WebSocket URLRequest
  DesignSystem/               MZColor, MZTypography, MZSpacing (+ MZRadius, MZMotion, MZClipboard), MZCard, MZBadge,
                              RatingChip, MZPrimaryButton (+ button styles), MZEmptyState, PlanCard, PaywallView,
                              LicenseKeyField, DeviceRow
Tests/MirrorzKitTests/        LicenseKeyTests, LicenseTokenTests, EntitlementsTests, CompatClientTests, RemoteProtocolTests
  Resources/license-fixtures.json   copy of core/tests/fixtures/license-fixtures.json
```

## API overview

### Licensing

```swift
// Keys (spec §3.3)
LicenseKey.normalize("mz bpj2w f5c8d 4nldj koyzz m7e8v")  // "BPJ2WF5C8D4N1DJK0YZZM7E8V" or nil
LicenseKey.isValid(key); LicenseKey.canonical(key)        // "MZ-BPJ2W-F5C8D-4N1DJ-K0YZZ-M7E8V"
LicenseKey.formatPartial(typed); LicenseKey.validation(of: typed)  // live feedback for the text field

// Tokens (spec §3.4)
let claims = try LicenseToken.verify(token, trustedKeys: TrustedKeys.embedded(), deviceID: deviceID)
// throws LicenseTokenError: malformed · unsupportedVersion · unknownKid · badPublicKey · badSignature · deviceMismatch

// Entitlements (spec §3.4 rules 1–5)
let store = KeychainStore()                                   // service com.mirrorz.license
let deviceID = try DeviceIdentity.deviceID(store: store)      // macOS: sha256(IOPlatformUUID + "com.mirrorz.app"); iOS: UUID in keychain
let device = DeviceIdentity.deviceRecord(id: deviceID, appVersion: BuildInfo.current().version)   // @MainActor
let client = LicenseClient(configuration: .init(appVersion: "1.0.0"))                             // User-Agent "MIRRORZ/1.0.0 (macos)"
let entitlements = Entitlements(configuration: .init(trustedKeys: TrustedKeys.embedded(), device: device, buildInfo: .current()),
                                client: client, store: store)
entitlements.bootstrap()          // synchronous keychain read + local evaluation; schedules the daily refresh; never touches the network
entitlements.mode                 // .none | .full | .updatesExpired | .expired
entitlements.isEntitled; entitlements.plan; entitlements.kind; entitlements.features; entitlements.has(.cadPresets)
try await entitlements.activate(key:) / startTrial() / deactivate(deviceID:) / refreshNow(); await entitlements.refreshIfNeeded()
Entitlements.evaluate(claims:now:buildDate:dropped:)   // pure rule engine, used by the tests

// Server (spec §3.2) — all methods on `actor LicenseClient`
startTrial(device:) · activate(key:device:) · refresh(token:) · deactivate(key:deviceID:) · status(key:)
linkApple(signedTransaction:device:) · linkGoogle(purchaseToken:productId:device:) · publicKeys()
// errors: APIClientError.invalidKey | .api(APIError{status, code: APIErrorCode, message}) | .network | .decoding | .unexpectedStatus
```

Refresh policy: at most one licensing call per day per device (`refreshIfNeeded` is throttled and the
throttle is persisted); a 403 on refresh drops the entitlement immediately; network errors keep the
entitlement until `sub_exp`; perpetual tokens are entitled forever and only refresh in the background.
`refreshNow()` is the user-initiated "check now" and bypasses the throttle.

### Store (spec §2, §3.5)

```swift
let storeKit = StoreKitManager(client: client, entitlements: entitlements, device: device)
await storeKit.start()            // Transaction.updates listener, Product.products(for:), Transaction.unfinished, Transaction.currentEntitlements
storeKit.offerings                // [Offering{ id: StoreProductID, product, displayPrice, monthlyEquivalentPrice }]
try await storeKit.purchase(plan: .standard, term: .annual)   // .linked(key:) | .pending | .cancelled
await storeKit.restore()          // AppStore.sync() then re-link current entitlements
```

After a successful `Product.purchase()` (or an unlinked current entitlement) the signed transaction
(`VerificationResult.jwsRepresentation`) is posted to `/v1/apple/link`; `transaction.finish()` is called
only after the server answered 2xx. Family Sharing transactions link like any other; offer codes surface
through `Transaction.updates`; the paywall shows the redemption sheet on iOS 16+/macOS 15+.

### Compatibility Database (spec §4)

```swift
let compat = CompatClient(configuration: .init(userAgent: client.configuration.userAgent))
let catalog = await compat.catalog()             // fresh cache → GET /v1/compat/apps → stale cache → bundled seed (never throws)
let apps = await compat.search("autocad", category: "cad", runtime: .vm)   // same matcher as the server
let detail = try await compat.app(id: "autocad") // adds community counts; local fallback offline
let decision = await compat.route(RouteRequest(arch: .x64, dx: "11"))      // remote, identical local heuristic offline
try await compat.report(CompatReport(appID: "autocad", result: .worksWithFixups))  // opt-in, anonymous by construction
```

The disk cache lives in `Application Support/MIRRORZ/compat-cache.json` and is valid for 24 h.

### Remote protocol (`docs/spec/remote-protocol.md`)

`Remote/RemoteProtocol.swift` implements the pairing + signaling protocol exactly as published:

```swift
// HTTP (RemoteClient actor)
let remote = RemoteClient(configuration: .init(userAgent: client.configuration.userAgent))
let pairing = try await remote.createPairing(token: token, name: "Studio")   // POST /v1/remote/pairings → code, room_id, deep_link
let ice = try await remote.iceServers(token: token)                           // GET /v1/remote/ice (Authorization: Bearer)

// WebSocket handshake (§4): URLRequest with the token in the Authorization header
let request = remote.webSocketRequest(.host(token: token, room: pairing.roomID, name: "Studio"))
let request = remote.webSocketRequest(.client(token: token, code: "7K3MZP"))          // first connection
let request = remote.webSocketRequest(.client(token: token, grant: storedGrant))      // reconnect

// Framing (§5): { "t": "<type>", …fields }, text frames ≤ 64 KiB
let data = try RemoteCodec.encode(.launch(LaunchMessage(appID: "app_autocad-2026")))
switch try RemoteCodec.decode(text: frame) { case .hello(let hello): … case .apps(let apps): … }
RemoteCodec.encodeApps(apps)                 // drops icons when the list would exceed the frame

// mz-input data channel (§5.4)
let bytes = try InputChannelCodec.encode(InputChannelCodec.coalescingMoves(events))   // ≤ 16 KiB
InputEvent.move(x:y:) · pointerDown/Up(x:y:button:) · keyDown/Up/keyPress(code) · scroll(…) · pinch(…) · text(…)

// Pairing codes and QR links (§3.1), grants (§3.3, §7.3), close codes (§4.2), Bonjour TXT (§7.1)
PairingCode.normalize("7k3-mzp")  →  "7K3MZP";  PairingCode.display  →  "7K3-MZP"
PairingLink(url:) parses mirrorz://pair?code=…&h=… and https://mirrorz.app/pair?…
try RemoteGrant.verify(grant, trustedKeys: keys, hostHash: myHash, deviceID: peerDevice, now: Date())
RemoteCloseCode(rawValue: 4409) == .conflict;  BonjourAdvertisement(txtRecord:)
```

The message set is `hello`, `peer-joined`, `peer-left`, `offer`, `answer`, `ice`, `apps`, `launch`,
`input`, `error`, `bye` with the spec's field names (`peer_id`, `room_id`, `host_hash`, `self`,
`ice_servers`, `app_id`, `compat_id`, explicit `null` for `apps.streaming` and `ice.candidate`).
Unknown `AppEntry` enum values fall back to their defaults and unknown fields are ignored (§10).
The WebRTC session itself (`RTCPeerConnection`, ScreenCaptureKit capture, VideoToolbox encode)
lives in the apps; this package provides the wire types and codecs only.

### Design system (spec §5.4)

`MZColor` carries the spec palette (dark) with a paired light palette as dynamic colors; `MZRadius.card = 12`,
`MZRadius.chip = 8`; `MZMotion.standard` is 200 ms ease-out. `PaywallView` is meant to be embedded in
Settings › License & Plans and in locked states only (no modal upsells); it shows Standard/Pro ×
monthly/annual/perpetual from StoreKit, the copy "No ads. Cancel anytime. Perpetual never expires.",
Restore Purchases, Enter license key, and the offer-code sheet where available. `LicenseKeyField`
auto-formats as you type and validates the check symbol live; `DeviceRow` confirms before deactivating.

## App integration checklist

1. **Trusted keys**: add `MZTrustedLicenseKeys` (array of `{ kid, x }` dictionaries, raw 32-byte Ed25519
   public key base64url) to each app's Info.plist. The values come from the production server's
   `/.well-known/mirrorz-license-key.json`. An empty list rejects every token. Never ship a private key.
2. **Build date**: write `MZBuildDate` (ISO-8601 date) into Info.plist from a build phase; it drives the
   perpetual "updates window" rule. Without it `BuildInfo.fallbackBuildDate` is used.
3. **Keychain**: `KeychainStore()` uses service `com.mirrorz.license`. Pass `accessGroup:` (and the
   Keychain Sharing capability) if the CLI helper or an extension must read the token; on macOS the
   data-protection keychain is used only when an access group is set.
4. **Startup order**: `entitlements.bootstrap()` first (synchronous, local), then `await storeKit.start()`
   in a detached task. Call `await entitlements.refreshIfNeeded()` when the app becomes active.
5. **Deep links**: `mirrorz://activate?key=…` → pre-fill `LicenseKeyField(initialText:)`;
   `mirrorz://pair?code=…` → `PairingInvitation(url:)`.
6. **Privacy**: the package contains no analytics or advertising code and sends nothing beyond the device
   record for licensing and the opt-in anonymous compatibility reports.

## Verification

Verified in this environment (Linux, no Swift toolchain):

- JSON fixtures parse: `compat-seed.json` and `license-fixtures.json` load and are byte-identical to
  their origins (`server/src/compat/seed.json`, `core/tests/fixtures/license-fixtures.json`).
- The key algorithm (Luhn mod 32, normalization, formatting) was ported to a reference script and checked
  against all 50 valid, 20 invalid and 10 normalization fixtures — all pass.
- Token verification and the §3.4 entitlement rules were checked with `node:crypto` Ed25519 against all
  8 fixture tokens (valid/invalid, error codes, `mode_at_now`, `mode_after_updates_window`, `entitled_at`) — all pass.
- The device-hash test vector (`sha256(device_id)` prefix 16) was computed independently in Python.
- Every `.swift` file parses with tree-sitter-swift (syntax only).
- Search counts asserted by `CompatClientTests` were recomputed from the seed with the server's matcher.

Still needs Xcode 16 (macOS 14 SDK or newer) or Android Studio equivalents:

- Swift compile requires Xcode 16: `swift build` / `swift test` for the type checker, strict-concurrency
  diagnostics, StoreKit/SwiftUI API availability, and running the XCTest suites.
- Keychain access-group behaviour and `IOPlatformUUID` need a signed macOS build on hardware.
- StoreKit flows (purchase, restore, Family Sharing, offer codes, Ask to Buy) need a StoreKit
  configuration file or sandbox account with the product ids from spec §2.
- SwiftUI previews / light-dark rendering of the design-system views.
