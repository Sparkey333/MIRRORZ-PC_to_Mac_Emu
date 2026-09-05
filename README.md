# MIRRORZ

**Run Windows and PC software on your Mac. AutoCAD-ready. No ads, ever.**

MIRRORZ is a commercial macOS app (with iOS and Android companions) that runs Windows programs on Apple Silicon Macs two ways: full Windows 11 ARM **Machines** for heavyweight software such as AutoCAD, Revit, SolidWorks and QuickBooks, and lightweight Wine-based **Bottles** for everything that does not need a Windows license. An **App Router** picks the right runtime per app and applies per-app fix-ups from a curated compatibility database, and **Mirror Mode** shows Windows app windows as native Mac windows.

Product promises, derived from the research in `docs/research/`:

- No ads, no nag screens, no telemetry by default.
- Monthly or annual subscription **and** a perpetual license that never expires (12 months of feature updates, security updates forever).
- CAD-first: an AutoCAD graphics preset, pre-installed runtimes, stable virtual hardware identity for licensing-sensitive apps.
- Buy on the Mac App Store, the iOS App Store, Google Play, or direct; one license works on up to 3 Macs (Standard) or 5 (Pro).

## Repository map

| Path | What | Verified here |
|---|---|---|
| `docs/research/` | Competitor deep-dives (Parallels 27, VMware Fusion, CrossOver 26, UTM, Whisky/Kegworks, cloud PCs, mobile), Autodesk KB findings, reviews, policy, pricing | Fact-checked by independent agents |
| `docs/spec/platform-contracts.md` | The contract every client is built against | — |
| `docs/spec/remote-protocol.md` | Pairing + WebRTC signaling protocol | Implemented + tested in `server/` |
| `server/` | Node 22 licensing, billing (Apple/Google/Stripe), compatibility DB, remote signaling | `npm test` (36 tests) |
| `core/` | Rust `mirrorz-core` with UniFFI Swift/Kotlin bindings: license verification, entitlement, App Router | `cargo test` (54 tests), clippy clean |
| `apps/shared/MirrorzKit` | SwiftPM kit: licensing, StoreKit 2, compat client, design system | Needs Xcode (CI: `apple.yml`) |
| `apps/macos/` | macOS app + `MirrorzEngine` package (VZ, QEMU/HVF, Wine bottles, Mirror Mode) | Needs Xcode |
| `apps/ios/`, `apps/android/` | Companion apps: remote view/control, catalog, purchases, license | Needs Xcode / Android Studio |
| `store/` | App Store / Play listings, privacy labels, review notes, legal | — |
| `website/` | Marketing, pricing and docs site | `website.yml` |
| `pricing/pricing.json` | Single source of truth for prices | — |

## Build

```bash
make setup        # server deps; Rust via rustup
make test         # server + core (Linux/macOS)
make test-apple   # macOS + Xcode 16
make test-android # JDK 21 (+ Android SDK for the app module)
```

## License

Apache-2.0 for this repository. Bundled engines carry their own licenses (Wine LGPL-2.1+, QEMU GPL-2.0, DXMT LGPL-2.1+, MoltenVK Apache-2.0); see `store/legal/third-party-notices.md`.
