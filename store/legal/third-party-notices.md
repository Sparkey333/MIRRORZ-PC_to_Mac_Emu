# Third-party notices

MIRRORZ bundles or links the following open-source software. Each component is licensed under its own terms, reproduced in full in the `Licenses/` folder inside the app bundle. Copies of the corresponding source code for GPL and LGPL components, including MIRRORZ's modifications, are available at https://github.com/Sparkey333/MIRRORZ-PC_to_Mac_Emu and on request to source@mirrorz.app.

_Verify each license and version against the shipped build before release. Licenses below were checked against upstream repositories on 2026-09-05; DXMT changed from MIT to LGPL-2.1-or-later after v0.80._

## Engines (macOS app)

| Component | Use | License |
|---|---|---|
| Wine | Bottles compatibility layer | LGPL-2.1-or-later |
| Wine Mono | .NET Framework replacement inside Bottles | MIT and others (see upstream) |
| Wine Gecko | HTML rendering inside Bottles | MPL-2.0 / LGPL |
| DXMT | Direct3D 10/11 to Metal translation | LGPL-2.1-or-later (v0.81+); MIT up to v0.80 |
| DXVK | Direct3D 9/10/11 to Vulkan translation (optional backend) | zlib |
| vkd3d | Direct3D 12 to Vulkan translation (optional backend) | LGPL-2.1-or-later |
| MoltenVK | Vulkan on Metal | Apache-2.0 |
| QEMU (MIRRORZ build) | Windows 11 ARM Machines with Hypervisor.framework | GPL-2.0-only (with LGPL-2.1 parts) |
| EDK II / OVMF (AAVMF) | UEFI firmware for Machines | BSD-2-Clause-Patent |
| swtpm and libtpms | Virtual TPM 2.0 for Windows 11 | BSD-3-Clause |
| virglrenderer (MIRRORZ/UTM fork) | Guest graphics forwarding host side | MIT |
| virtio-win guest drivers | Windows guest drivers (VirtIO block, net, input, GPU) | BSD-3-Clause / GPL-2.0 (per driver) |
| SPICE protocol and libspice | Guest tools channel | LGPL-2.1-or-later |
| FreeType, GnuTLS, libpng, zlib, libjpeg-turbo | Wine dependencies | FreeType, LGPL-2.1, libpng, zlib, IJG |

Apple's Game Porting Toolkit / D3DMetal is **not** bundled: its license does not permit redistribution. MIRRORZ can use it only if you install it yourself under your own Apple developer agreement.

## Shared core and apps

| Component | Use | License |
|---|---|---|
| UniFFI | Rust bindings for Swift and Kotlin | MPL-2.0 |
| ed25519-dalek, curve25519-dalek | License token verification | BSD-3-Clause |
| serde, serde_json, base64, thiserror | Rust core | MIT / Apache-2.0 |
| Bouncy Castle | Ed25519 verification on Android | MIT-style (Bouncy Castle license) |
| WebRTC (libwebrtc; stasel/WebRTC on Apple, stream-webrtc-android on Android) | Remote companion transport | BSD-3-Clause |
| OkHttp, kotlinx.serialization, Jetpack Compose, AndroidX | Android companion | Apache-2.0 |
| Google Play Billing Library | Purchases on Android | Android SDK License |
| CameraX / ML Kit Barcode or ZXing | QR pairing on Android | Apache-2.0 |
| Inter | Website typeface (system fonts in apps) | SIL OFL 1.1 |

## Services

| Component | Use | License |
|---|---|---|
| Node.js | Licensing service runtime | MIT |
| Fastify, @fastify/websocket, ws | HTTP and WebSocket server | MIT |
| zod | Input validation | MIT |
| SQLite (via node:sqlite) | Storage | Public domain |

## Trademarks

AutoCAD, Revit, Civil 3D, Inventor, Navisworks and Fusion are trademarks of Autodesk, Inc. SOLIDWORKS is a trademark of Dassault Systèmes. Microsoft, Windows and DirectX are trademarks of Microsoft Corporation. Apple, Mac, macOS, Metal and App Store are trademarks of Apple Inc. Google Play and Android are trademarks of Google LLC. Parallels is a trademark of Parallels International GmbH. VMware is a trademark of Broadcom Inc. CrossOver is a trademark of CodeWeavers, Inc. MIRRORZ is not affiliated with, endorsed by or sponsored by any of these companies.
