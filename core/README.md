# mirrorz-core

The shared brain of MIRRORZ: one Rust crate used by the macOS app and the iOS
companion (Swift, via UniFFI) and by the Android companion (Kotlin, via UniFFI).
Everything in it is a pure function of its inputs: no I/O, no clock, no network,
no telemetry. Hosts pass in the current time, the local device id, the embedded
public keys and the compatibility catalog JSON; the core returns decisions.

Reference implementation of the wire formats: `server/`. Contract: `docs/spec/platform-contracts.md`.

## Modules

| Module | What it does | Mirrors |
|---|---|---|
| `license::key` | `MZ-XXXXX-…` keys: `normalize_license_key`, `is_valid_license_key`, `format_license_key`, `display_license_key`. Crockford base32, 24 symbols + Luhn mod 32 check, `O→0`, `I/L→1`, JavaScript-`\s` separator stripping | `server/src/license/keyformat.ts` (byte-for-byte) |
| `license::token` | `MZL1.<payload>.<sig>` device tokens: `TrustedKey`, `LicenseClaims`, `LicenseKind`, `verify_license_token` → `Result<LicenseClaims, LicenseError>`; also `decode_license_token_unverified`, `token_needs_refresh`, `trusted_key_is_valid` | `server/src/license/token.ts` |
| `license::entitlement` | Spec §3.4 rules: `evaluate(claims, now, build_date)` → `Entitlement{entitled, mode, features, seconds_remaining, plan, kind}`; `revoked_entitlement`, `has_feature`, `verify_and_evaluate`, `should_refresh` | spec §3.4 + `server/src/license/service.ts` |
| `license::plans` | `PlanId`, `plan_features`, `features_for_plan`, `is_plan_id` | `server/src/license/plans.ts` |
| `router` | App Router: `RouteInput` → `RouteDecision{runtime, reason, preset, fixups_json, requires_windows_machine}`. Catalog entry wins; otherwise the `routeUnknown` heuristic | `server/src/compat/service.ts` |
| `compat` | `CompatCatalog::from_json` (object) with `search`, `get`, `presets`, `preset`, `categories`, `runtime_description`, `route`; typed `CompatApp`/`CompatFixup`/`CompatRequirements`/`CompatPreset`; `bundled_compat_seed_json()` | `server/src/compat/service.ts` + `seed.json` |
| `machine` | `validate_machine_config` (messages) and `check_machine_config` (typed `MachineProblem` with severity + stable code) | — |

### Behaviour worth knowing

* **Verification is time-independent by design.** `verify_license_token` never rejects on
  `exp`: per spec §3.4 the token's `exp` only schedules a refresh, and subscription expiry is
  answered by `evaluate` with the same `now_unix`. The `now_unix` argument is part of the FFI
  signature so hosts thread one clock reading through `verify_and_evaluate`.
* Check order in `verify_license_token`: structure → `kid` lookup → Ed25519 (`verify_strict`)
  over the UTF-8 bytes of `"MZL1.<payload>"` → `v == 1` → typed claims → `dev == device_id`.
  Error variants map to the server codes via `LicenseError::code()`.
* Perpetual + missing `upd` evaluates to `UpdatesExpired` (conservative). Subscription/trial +
  missing `sub_exp` evaluates to `Expired`. The server always sets both, so this only matters
  for hand-made tokens.
* Base64url decoding is padding-indifferent; the URL-safe alphabet is required.
* `route` with a catalog runtime of `either` breaks the tie with the file heuristic (ARM64-only
  binaries, drivers/services and DX12 go to the Machine; everything else to a Bottle). A Bottle
  decision picks up `bottle_setting/dotnet_framework` and `bottle_setting/dxmt` fix-ups from the
  detected metadata. Malformed catalog fields fall back to the heuristic rather than failing.
* `bundled_compat_seed_json()` embeds `server/src/compat/seed.json` at compile time (single
  source of truth in the monorepo). Ship it for offline use; replace it with the server's
  catalog (cached 24 h) when online.
* Machine validation adds one input the task list omitted: `host_apple_silicon: bool`, needed
  for the "macOS guests only on Apple silicon" rule. Both machine functions take eight flat
  arguments on purpose (records would force every host to build a struct just to call them).

## Using it from Swift

```swift
import MirrorzCore

// Embedded keys from /.well-known/mirrorz-license-key.json (keys[].kid, keys[].x).
let trusted = [TrustedKey(kid: "53ba2c88782e6d05", xB64url: "OA65…")]

do {
    let entitlement = try verifyAndEvaluate(
        token: storedToken,
        trustedKeys: trusted,
        deviceId: DeviceId.current,           // spec §3.1
        nowUnix: Int64(Date().timeIntervalSince1970),
        buildDateUnix: BuildInfo.releaseDate)  // compare against `upd`
    if entitlement.mode == .updatesExpired { showUpgradeBanner() }
    let canUseCli = hasFeature(entitlement: entitlement, feature: "cli")
} catch LicenseError.DeviceMismatch {
    // token belongs to another device: re-activate
} catch {
    // .Malformed / .UnknownKid / .BadSignature / .UnsupportedVersion
}

let catalog = try CompatCatalog.fromJson(json: cachedCatalogJson ?? bundledCompatSeedJson())
let cadApps = catalog.search(query: "auto", category: "cad", runtime: nil)
let decision = catalog.route(appId: "autocad",
    detected: RouteInput(arch: .x64, needsDriver: false, needsService: false,
                         dotnet: nil, dx: "11", compatRuntime: nil, compatRating: nil,
                         compatFixupsJson: nil))
// decision.runtime == .vm, decision.preset == "cad-graphics", decision.requiresWindowsMachine == true

let problems = checkMachineConfig(cpus: 6, memoryMb: 16_384, diskGb: 128,
    hostCpus: 10, hostMemoryMb: 32_768, freeDiskGb: 400,
    hostAppleSilicon: true, guestOs: .windows11Arm)
```

Records are immutable structs (`Equatable, Hashable, Codable`); enums are `CaseIterable`;
errors are Swift `Error` enums with cases named after the Rust variants
(`LicenseError.Malformed`, `CompatError.InvalidJson(message:)`).

## Using it from Kotlin

```kotlin
import com.mirrorz.core.*

val claims = try {
    verifyLicenseToken(token, trustedKeys, deviceId, nowUnix)
} catch (e: LicenseException.DeviceMismatch) { null }

val entitlement = evaluate(claims, nowUnix, buildDateUnix)
val catalog = CompatCatalog.fromJson(bundledCompatSeedJson())
val office = catalog.get("ms-office-windows")
```

`CompatCatalog` is a UniFFI object: keep one instance per catalog and `close()` it (or use
`use {}`) when done. Kotlin needs JNA on the classpath (`net.java.dev.jna:jna:<version>@aar`).

## Building

```sh
cargo test                                    # unit + fixture tests
cargo clippy --all-targets --features cli -- -D warnings
scripts/generate-bindings.sh                  # Swift + Kotlin sources from a host build
scripts/build-apple.sh                        # macOS: XCFramework + MirrorzCore.swift
scripts/build-android.sh                      # jniLibs (arm64-v8a, x86_64) + Kotlin
```

* `scripts/generate-bindings.sh` builds the host library and runs `uniffi-bindgen` in library
  mode (bindings are generated from the metadata inside the compiled artifact, so they always
  match the code). Output: `bindings/generated/{swift,kotlin}` (gitignored).
* `scripts/build-apple.sh` (macOS only) builds `aarch64-apple-darwin`, `aarch64-apple-ios`,
  `aarch64-apple-ios-sim`, generates the Swift file, header and modulemap, and packages
  `bindings/generated/apple/MirrorzCoreFFI.xcframework` plus `MirrorzCore.swift`.
  `MIRRORZ_UNIVERSAL=1` adds the `x86_64` macOS / simulator slices via `lipo`.
* `scripts/build-android.sh` uses `cargo-ndk` (`-t arm64-v8a -t x86_64 -P 29`, Android 10+)
  and writes `bindings/generated/android/jniLibs` and `bindings/generated/kotlin`.
* The `uniffi-bindgen` binary is feature-gated (`--features cli`) so library consumers never
  compile clap and friends.

Wiring into the apps: add the XCFramework as a binary dependency and `MirrorzCore.swift` as a
source of the SwiftPM package in `apps/macos` / `apps/ios`; on Android put `jniLibs` under
`src/main/jniLibs` and the Kotlin file under `src/main/kotlin`.

## Dependencies

`uniffi 0.32` (proc-macro style, `uniffi::setup_scaffolding!`), `ed25519-dalek 2.2`
(`std` only), `base64 0.22`, `serde` / `serde_json`, `thiserror 2`. No network, no logging, no
analytics, nothing that runs at load time. `publish = false`.

## Verification status

Verified in the Linux CI container (rustc 1.94.1):

* `cargo test`: 48 unit tests + 6 cross-language fixture tests
  (`tests/fixtures_test.rs` over `tests/fixtures/license-fixtures.json`: every token's
  valid/error/entitled-at outcome, every valid/invalid key, every normalization case, plus
  wrong-key/impostor-key negatives) — all passing.
* `cargo clippy --all-targets --features cli -- -D warnings`, `cargo fmt --check`,
  `RUSTDOCFLAGS=-D warnings cargo doc --no-deps` — clean.
* `cargo build --release --lib` with fat LTO — builds (`libmirrorz_core.so` ≈ 1.1 MB).
* `uniffi-bindgen generate --language swift|kotlin` from both the debug and the release
  library — generates `MirrorzCore.swift`, `MirrorzCoreFFI.h`, `MirrorzCoreFFI.modulemap`
  and `com/mirrorz/core/mirrorz_core.kt` with the names shown above (the only warnings are the
  missing `swift-format` / `ktlint` formatters). `uniffi.toml` keys were checked against the
  uniffi 0.32 config structs.

Still needs a Mac / Android Studio:

* Compiling the generated Swift against the XCFramework (`scripts/build-apple.sh`) and the
  Kotlin against JNA on a device or emulator (`scripts/build-android.sh`). The Apple targets
  and `xcodebuild -create-xcframework` cannot run here.
* Running the same fixture file through the Swift and Kotlin layers (the bindings are
  generated code; the intent is that `MirrorzCoreTests` in `apps/macos` and the Android unit
  tests load `core/tests/fixtures/license-fixtures.json` too).

## Layout

```
Cargo.toml                 lib (rlib + staticlib + cdylib) + feature-gated uniffi-bindgen bin
uniffi.toml                Swift module MirrorzCore / Kotlin package com.mirrorz.core
src/lib.rs                 re-exports, core_version(), uniffi::setup_scaffolding!
src/license/{key,token,entitlement,plans}.rs
src/router.rs  src/compat.rs  src/machine.rs
src/bin/uniffi-bindgen.rs
tests/fixtures_test.rs     tests/fixtures/license-fixtures.json (generated by the server)
scripts/generate-bindings.sh  scripts/build-apple.sh  scripts/build-android.sh
```
