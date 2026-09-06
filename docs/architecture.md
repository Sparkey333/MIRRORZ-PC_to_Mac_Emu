# MIRRORZ architecture decision record

_Status: accepted for v1 planning · 2026-09-06 · Sources: the verified reports under `docs/research/` (cited by file)._

## 1. Decisions in one screen

| # | Decision | Why (evidence) |
|---|---|---|
| D1 | **Two runtimes, one App Router.** Full Windows 11 ARM **Machines** for AutoCAD-class software; Wine-based **Bottles** for everything that does not need real Windows. | No competitor ships both with automatic routing (`competitors/*`). CAD needs Windows (installers, licensing, toolsets); utilities and games are faster and license-free in Wine (`code/wine-on-macos-codebases.md`). |
| D2 | **Windows Machines run on Hypervisor.framework with QEMU as an out-of-process, GPL-isolated sidecar** (the UTM model), not Virtualization.framework. | Virtualization.framework runs only macOS and Linux guests, has no TPM and no custom device model; Apple says HVF apps are suitable for the Mac App Store and UTM ships there (`code/virtualization-frameworks-and-hypervisor-codebases.md`). |
| D3 | **Linux and macOS Machines use Virtualization.framework** (VZ) directly from Swift. | Native, fast, gains macOS 27 features (USB passthrough, DiskImageKit clones, vmnet topologies) for free. |
| D4 | **Guest graphics = paravirtual D3D11 driver in the guest → DXMT on the host** (the Triton/Neptune shape UTM 5.0 proved), DXMT `d3d12` when it lands, **D3DMetal only if the user installs Apple's toolkit themselves**. | AutoCAD needs DX11 (DX12 FL12_0 only for "Fast" styles); D3DMetal's public license is non-commercial; DXMT is LGPL-2.1+ and actively maintained (`code/graphics-stack-directx-to-metal.md`). |
| D5 | **OpenGL 4.5 via Zink → Venus/VirtIO → MoltenVK** on the roadmap (SolidWorks), beating Parallels' 4.3. | Same report; UTM already ships Venus for Linux guests. |
| D6 | **x64 apps inside Windows Machines run on Microsoft Prism.** No whole-system x86 emulation in v1. | Prism is mature (AVX2 since 24H2 updates); Parallels' own x86 VM emulator is a 1-vCPU preview (`code/x86-on-arm-emulation.md`, `competitors/performance-benchmarks.md`). |
| D7 | **Bottles ship x86_64 Wine 11 on Rosetta for v1, with ARM64EC Wine + a macOS FEX port as the funded v2 engine.** | macOS 27 is the last release with general Rosetta; CodeWeavers already previewed the FEX route (`code/wine-on-macos-codebases.md`, `competitors/newcomers-2025-2026.md`). |
| D8 | **Shared logic lives in `mirrorz-core` (Rust, UniFFI)**; UI is native SwiftUI / Compose; the server (`server/`) is the contract. | Already built and tested (`core/`, `apps/shared/MirrorzKit`, `server/`). |
| D9 | **Two distributions: Mac App Store build (sandboxed, hypervisor + virtualization entitlements) and a notarized Developer ID build** with the full engine set. | Parallels' App Store edition shows the sandbox costs features (VPN sharing, printers, templates); the direct build keeps parity (`competitors/parallels-desktop.md`). |
| D10 | **Licensing posture: proprietary app, LGPL engines as replaceable dynamic libraries with a public source offer, GPL QEMU only as a separate process, no GPTK redistribution.** | LGPL §6 relink requirement; GPL boundary; Apple SLA (`code/wine-on-macos-codebases.md`). |

## 2. Hard constraints the research established

1. Apple's Virtualization.framework cannot host Windows (no TPM, no custom devices, docs list macOS/Linux only). Any Windows product is HVF + a device model.
2. Autodesk certifies neither virtual machines nor Windows on ARM for AutoCAD, Revit or Inventor; Revit lists a Parallels configuration but marks accelerated graphics unsupported. Marketing must say "works with", never "supported by" (`reviews/autodesk-kb-official-findings.md`).
3. The only mature DX11/DX12-to-Metal layer, Apple's D3DMetal, is licensed "solely for non-commercial purposes"; CodeWeavers ships it under a private arrangement. DXMT is the open DX10/11 path; DX12 in the open is early.
4. Rosetta 2 ends as a general tool after macOS 27; every free Wine tool today depends on it.
5. Microsoft's Windows-on-Apple-silicon authorization page names Parallels; Windows 11 ARM ISOs are downloadable from Microsoft, and the user must license Windows themselves.
6. The Mac App Store accepts hypervisor apps (UTM, Parallels App Store Edition) but the sandbox removes some integration features; GPL code must stay out of process and its source must be offered.

## 3. Options considered (judge-panel scoring)

Criteria weighted for a 12-month v1: time to market (25%), CAD viability (25%), App Store viability (15%), licensing risk (15%), post-Rosetta durability (10%), differentiation (10%). Scores 1–5.

| Option | TTM | CAD | Store | License | Durability | Diff | Weighted |
|---|---|---|---|---|---|---|---|
| A. Wine-only product (Whisky successor with DXMT) | 5 | 1 | 4 | 4 | 2 | 2 | 2.85 |
| B. Proprietary VMM on Hypervisor.framework (Parallels model) | 1 | 4 | 4 | 5 | 5 | 4 | 3.35 |
| C. QEMU sidecar on HVF + paravirtual D3D11 + Wine Bottles + App Router (**chosen**) | 4 | 4 | 4 | 4 | 4 | 5 | **4.15** |
| D. Cloud-streamed Windows (Windows 365 / own GPU cloud) | 4 | 3 | 5 | 5 | 5 | 2 | 3.85 |
| E. Linux VM + Hangover (Wine ARM64EC + FEX) for everything | 3 | 2 | 4 | 4 | 5 | 3 | 3.30 |

Notes. A fails the flagship (AutoCAD's installer, licensing and toolsets do not run under Wine and Autodesk says so). B is the long-term shape but is multi-year before a first sale. D is a strong add-on (hybrid local + cloud for MacBook Air users) and stays on the roadmap. E is the right engine for Bottles later, not a Windows replacement.

## 4. Chosen architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│ MIRRORZ.app (Swift/SwiftUI, proprietary)                                  │
│  Views ─ AppState ─ Entitlements (MirrorzKit) ─ StoreKit ─ Compat client  │
│  App Router ───────────────┐                                              │
│  Engine facade (protocols in apps/macos/Packages/MirrorzEngine)          │
│   ├─ VZEngine  (Virtualization.framework, in-process)  → Linux/macOS      │
│   ├─ QEMUEngine (XPC to helper) ───────────────┐                          │
│   └─ BottleEngine (spawns wine processes) ─────┼───────────┐              │
│  Mirror Mode compositor (NSWindow per guest window)        │              │
│  Remote host (ScreenCaptureKit → VideoToolbox → WebRTC)    │              │
└───────────────┬──────────────────────────────────┬─────────┼──────────────┘
                │ XPC                              │ argv/env│ (separate processes)
   ┌────────────▼───────────────┐      ┌───────────▼─────────▼──────────────┐
   │ mirrorz-vmm helper (GPL)   │      │ Wine 11 engine (LGPL, dyn. libs)   │
   │ QEMU aarch64 + HVF, UEFI,  │      │ winemac.drv, DXMT (LGPL),          │
   │ swtpm, virtio-*, Neptune   │      │ optional D3DMetal (user-installed) │
   │ host backend → DXMT/Metal  │      │ x86_64 on Rosetta (v1) →           │
   └────────────┬───────────────┘      │ ARM64EC + FEX (v2)                 │
                │ virtio-serial / vsock └────────────────────────────────────┘
   ┌────────────▼───────────────────────────────────────┐
   │ Windows 11 ARM guest                                │
   │  MIRRORZ Guest Tools (service + shell hook):        │
   │   window enumeration, launch, clipboard, env/reg,   │
   │   Triton-style D3D11 UMD + virtio-gpu KMD (signed)  │
   │  x64 apps via Prism                                 │
   └─────────────────────────────────────────────────────┘
      mirrorz-core (Rust, UniFFI) is linked into the app, the iOS/Android companions
      and the CLI: license verification, entitlement, routing, catalog, validation.
```

### 4.1 Process and trust boundaries
- The app never links GPL code. The helper is launched as an XPC service (Developer ID build) or a bundled helper executable (App Store build) and speaks a small JSON-over-XPC API: create/start/stop/pause, QMP passthrough, display surface handoff (IOSurface), guest-tools channel.
- Wine runs as child processes; MIRRORZ's only in-Wine code is a thin LGPL-compatible shim DLL (window enumeration hooks), published with source.
- The Rust core is MPL/MIT/BSD dependencies only.

### 4.2 Machines (Windows)
- Media: official Windows 11 ARM64 ISO from Microsoft after the user accepts Microsoft's terms; MIRRORZ never redistributes Windows. The setup wizard sizes CPU/RAM from host resources (half the cores, at most half the RAM, per the benchmark report's vendor guidance) and pre-installs VC++ x64/x86/ARM64 and .NET runtimes for Autodesk installers.
- Devices: UEFI (edk2 AAVMF, BSD), swtpm TPM 2.0 (BSD), virtio-blk/net/input/fs, virtio-gpu with the Neptune D3D11 forwarding backend, SPICE agent channel for clipboard, stable SMBIOS/UUID/MAC for licensing-sensitive apps.
- Snapshots: qcow2 internal snapshots via QMP; linked clones via backing files (Pro).
- Guest Tools: a signed Windows service (needs Microsoft attestation signing for the kernel-mode virtio-gpu driver; budgeted) that exposes windows, launches apps, applies fix-ups (env, registry, AutoCAD system variables) and reports DirectX level so the CAD preset can toggle hardware acceleration correctly.

### 4.3 Bottles (Wine)
- Engine directory per version (`~/Library/Application Support/MIRRORZ/Engines/<version>`), WINEPREFIX per bottle, renderer selectable per bottle (DXMT default; D3DMetal if the user installed GPTK; wined3d fallback).
- Installer flow diffs Start Menu shortcuts to produce Apps; icons extracted from PE resources; windows enumerated through the host's window list (winemac.drv creates real NSWindows), which makes Mirror Mode nearly free for Bottles.
- v2 engine: Wine ARM64EC + FEX (macOS port) so Bottles survive the end of Rosetta.

### 4.4 App Router
Inputs: PE header (arch, CLR, imports of d3d11/d3d12/ntoskrnl/service APIs), MSI detection, catalog match by product/company. Rules mirror `server/src/compat/service.ts` and `core/src/router.rs`: drivers/services → Machine; DX12 → Machine; known CAD → Machine with `cad-graphics` preset; everything else → Bottle first, automatic fallback to Machine on launch failure. Decisions are explained in the UI and can be overridden per App.

### 4.5 Mirror Mode
v1: full-framebuffer capture from the guest display surface, per-window cropping using guest-tools window rectangles, one borderless NSWindow per guest window, input forwarded with coordinate mapping. v2: per-window surfaces from the paravirtual display driver (the Parallels Coherence approach) for occlusion-correct compositing.

### 4.6 Remote companions
Pairing and signaling per `docs/spec/remote-protocol.md` (implemented in `server/src/remote`). Host captures with ScreenCaptureKit, encodes H.264 with VideoToolbox, streams over WebRTC (LAN direct, TURN relay fallback); input events over the `mz-input` data channel.

## 5. Licensing compliance plan
- Ship `Licenses/` in the bundle; publish `mirrorz-wine-<ver>-src.tar.xz`, `mirrorz-dxmt-<ver>-src.tar.xz` and `mirrorz-qemu-<ver>-src.tar.xz` alongside each release plus a written offer (`store/legal/eula.md` §6).
- LGPL libraries stay separate dylibs; the Developer ID build disables library validation for the engine directories so users can relink; the App Store build documents which engines it bundles.
- No D3DMetal in any build. The optional "Use Apple Game Porting Toolkit" toggle only activates a copy the user installed under Apple's agreement.
- Trademark rules in `store/legal/trademarks.md`.

## 6. Roadmap
| Release | Scope |
|---|---|
| **v1.0 (MVP, 6–8 months)** | Windows 11 ARM Machines (QEMU/HVF), Bottles (Wine 11 x86_64 on Rosetta, DXMT), App Router, catalog with AutoCAD/Revit/QuickBooks/Office profiles, CAD graphics preset, Mirror Mode v1, snapshots, licensing/trial/store purchases, iOS + Android companions (remote view, license, catalog), website and stores. Guest D3D11 acceleration marked beta. |
| **v1.1** | Guest Tools 1.0 with signed drivers, D3D11 out of beta, per-window Mirror Mode for Machines, linked clones and CLI (Pro), Windows setup automation improvements, community compatibility reports. |
| **v2.0** | ARM64EC Wine + FEX engine (Rosetta-free Bottles), DXMT D3D12 path (AutoCAD Fast styles), OpenGL 4.5 via Zink/Venus/MoltenVK (SolidWorks), hybrid cloud Machines, Business features (MDM, SSO, golden images). |

## 7. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Microsoft driver signing for the guest display driver | Start attestation signing early; ship unsigned-driver-free fallback (ramfb / Basic Render Driver) so Machines work on day one. |
| DXMT DX12 timeline | Track upstream; offer user-installed GPTK path; be explicit that Fast visual styles are roadmap. |
| Mac App Store review of a hypervisor app bundling QEMU | Follow UTM's precedent; keep the App Store build's engine set minimal; keep the Developer ID build as the full product. |
| Autodesk stance | Publish our own per-release test matrix; pursue an Autodesk relationship; never claim support. |
| Rosetta end | Fund the FEX port in v1 timeframe; keep the emulator behind an interface. |
| Session/usage-limit style single points of failure in ops | Licensing works offline for 30 days; final "keep-alive" update promised in terms if the service ever ends. |

## 8. Open questions for the founder
1. Negotiate a D3DMetal commercial license with Apple, or license via CodeWeavers, or ship DXMT-only at launch?
2. Seek Microsoft's Windows-on-Apple-silicon authorization (Parallels holds it) before launch?
3. Budget for Microsoft attestation signing and a Windows driver developer (Guest Tools).
4. Intel Macs: skip entirely (Parallels 27 and CrossOver 27 both dropped Intel) — recommended.
