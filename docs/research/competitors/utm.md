# UTM (macOS) and UTM SE (iOS) — Competitor Research

_Research date: 2026-09-03_

_Method note: the official getutm.app / docs.getutm.app / mac.getutm.app hosts and apps.apple.com were unreachable from the research sandbox (egress-blocked), so official documentation was read from its public GitHub source repositories (`utmapp/docs.getutm.app`, `utmapp/mac.getutm.app`, `utmapp/UTM`), release dates were taken from git tag timestamps in a bare clone of `utmapp/UTM`, and App Store pricing was confirmed from user reports in the UTM issue tracker. Facts that come only from search-engine snippets of pages we could not open are labelled "(snippet, unverified)"._

## TL;DR (5 bullets)

- **UTM is a free, Apache-2.0-licensed macOS/iOS front end over a GPL'd QEMU fork plus Apple's Virtualization.framework.** Latest stable is **v4.7.5 (tagged 2026-01-03, QEMU 10.0.2)**; a **5.0 beta line (v5.0.0 2026-01-11 → v5.0.5 2026-09-01)** is where all the interesting graphics work is happening. [S1][S2][S3][S6]
- **Pricing is "pay if you want":** the Mac App Store build is **$9.99** and is explicitly identical to the free GitHub DMG (the only App Store advantage is auto-update); UTM SE (iOS) and UTM Remote (iOS/visionOS) are free App Store apps. [S4][S5][S7][S8]
- **Windows 11 ARM64 guests virtualize at near-native CPU speed on Apple Silicon via the QEMU/Hypervisor.framework path**, with SPICE guest tools providing network, display-resize, clipboard and WebDAV shared folders — but **in every stable release to date there is no 3D GPU acceleration for Windows guests** (Windows falls back to Microsoft Basic Render Driver / WARP). [S9][S10][S11][S12][S13]
- **That is changing in the 5.0 betas**: v5.0.4 (2026-08-01) shipped an experimental **DirectX 11** path for Windows 11 via a new in-guest driver ("Triton") + a Direct3D-forwarding protocol ("Neptune") with DXMT on the host; v5.0.5 (2026-09-01) adds **DirectX 12 via D3DMetal** where available. Maintainer labels it "still experimental" with "limited" game compatibility. [S2][S3]
- **x86-64 Windows on Apple Silicon remains pure TCG emulation** — the official Windows guide defaults such VMs to a single core for memory-ordering correctness — and **UTM SE on iOS is JIT-less (threaded interpreter, "much slower")**, approved for the App Store in July 2024 after an initial rejection. [S9][S14][S15][S16]

## Current status (version, date, maintainer, momentum)

| Item | Finding | Source |
|---|---|---|
| Latest stable | **v4.7.5**, tag date 2026-01-03 (Pacific), announced same day; SourceForge mirror also lists "v4.7.5, January 3, 2026". Highlights: QEMU v10.0.2 backend, Liquid Glass UI on *OS 26, App Intents (Shortcuts), custom keyboard shortcuts (e.g. Ctrl+Alt+Del), improved wizard for emulated machines (RISC-V64 Ubuntu, classic Mac OS 8/9, Windows 95/98). | [S1][S6][S17][S18] |
| Prior stable line | v4.7.4 (2025-09-15): macOS 26 support, redesigned Settings, ASIF disk images by default for Apple Virtualization VMs on macOS 26, iOS 26 StikDebug JIT support. v4.6.2 (2024-11-27): QEMU 9.1.2, nested virtualization for Linux AVF guests on macOS 15 + M3, host-level TSO toggle for QEMU VMs on macOS 15. | [S1][S19][S20] |
| Beta line | v5.0.0 (2026-01-11, Vulkan 1.3 via Venus for Linux guests, Apple Core OpenGL 4.1 backend) → v5.0.4 (2026-08-01, experimental DirectX 11 for Windows 11; min macOS 13 / iOS 16) → **v5.0.5 (2026-09-01/02, DirectX 12 via D3DMetal on macOS, DirectX 11 via DXMT on iOS; minimum OS relaxed back to macOS 11.3 / iOS 14, but DirectX needs macOS 13 / iOS 16)**. All marked pre-release. | [S1][S2][S3][S21] |
| Maintainer | Primary developer "osy"; App Store seller is Turing Software, LLC (also maintains CrystalFetch). | [S17][S22] |
| Community size | GitHub README page showed **35.3k stars / 1.8k forks** on 2026-09-03. | [S4] |
| Cadence / quality signal | Roughly one stable point release every 1–3 months through 2025; 5.0 betas roughly bi-monthly in 2026. In the v4.7.5 announcement thread a user asked whether this was "the third and final release for this version," citing "quality control issues"; the maintainer replied "shhhh…". The v4.6 notes also warned that the QEMU 9.1.2 bump "will likely introduce other issues and regressions." | [S1][S18][S20] |
| Distribution | GitHub DMG/IPA/DEB, Mac App Store, TestFlight betas for UTM, UTM SE and UTM Remote; AltStore source `alt.getutm.app`; Cydia repo for jailbroken devices. | [S5][S15] |

## Pricing and licensing (table)

| Product / component | Price | License | Notes | Source |
|---|---|---|---|---|
| UTM for macOS (GitHub DMG) | Free | Apache 2.0 (app) | "UTM is and always will be completely free and open source." | [S5][S23] |
| UTM for macOS (Mac App Store) | **$9.99** (user reports, March 2025: "on macos if you look for it on the appstore it says its 9.99"; "The App Store version cost 10$") | Same | Official docs: "identical to the GitHub version and there are no features left out. The only advantage… is that you can get automatic updates. Purchasing… directly funds the development." | [S5][S7][S8] |
| UTM SE (iOS / iPadOS / visionOS App Store) | Free; optional in-app donations (added v4.5.4, Aug 2024) | Apache 2.0, but App Store build is "minified (some things removed to get it approved)" | No JIT; TestFlight beta available; also on "alternative marketplaces in supported locales" (EU). | [S15][S16][S24] |
| UTM Remote (iOS / visionOS) | Free | Apache 2.0 | Requires UTM for macOS 4.5.2+ acting as server. | [S25][S26] |
| CrystalFetch (Windows ISO builder) | Free (App Store + GitHub) | Apache 2.0 | Turing Software; "a valid license is required to install Windows 11." | [S22] |
| QEMU fork `utmapp/qemu` (branch `utm-edition`) | n/a | **GPLv2 / LGPL-2.1** | The engine UTM launches; UTM README: "parts of the code are taken from qemu." | [S4][S27] |
| Statically linked GStreamer plugins | n/a | (L)GPL | README: "Most [GPL components] are dynamically linked but the gstreamer plugins are statically linked." | [S4] |
| Windows guest drivers (virtio-win, osy fork used for Neptune/Triton) | n/a | BSD-3-Clause | Upstream note: pre-2018 GPL versions are "not compatible with WHQL." | [S28][S29] |
| Documentation repo | n/a | CC0-1.0 | Freely reusable text. | [S30] |

Parallels, by contrast, is a paid subscription (competitor page not fetched; see the separate Parallels report).

## How it works (architecture)

- **Two backends, not a superset of each other.** (1) **QEMU** — built from `utmapp/qemu` (`utm-edition`), giving full-system emulation of "30+ processors" plus hardware-accelerated virtualization through **Hypervisor.framework** when guest and host ISAs match; (2) **Apple Virtualization.framework** (macOS 12+), used for Linux and for macOS-on-Apple-Silicon guests (macOS guests need Monterey or newer). The marketing site's exact claim: "Apple's Hypervisor virtualization framework to run ARM64 operating systems on Apple Silicon at near native speeds… x86/x64 operating system virtualization on Intel Macs… lower-performance emulation" otherwise. [S4][S31]
- **Windows 11 on Apple Silicon runs on the QEMU backend** (Virtualize → Windows in the wizard). On macOS 15 the QEMU backend can enable **Total Store Ordering at the hypervisor level**, which "greatly improves" Intel emulation *inside* a TSO-aware guest (e.g. Rosetta for Linux); Windows' Prism emulator is not named. [S9][S20]
- **Display/input path is SPICE.** All I/O goes through SPICE; the host side is **CocoaSpice**, a Metal renderer that composites the guest IOSurface and coalesces multiple guest draws per vblank. On macOS the QEMU process is a separate helper (`QEMULauncher`) and passes frames by `IOSurfaceID`. [S13]
- **GPU acceleration chain (Linux today, Windows in beta):** guest Mesa → `virtio-gpu` kernel driver → QEMU → **virglrenderer** (OpenGL) or **Venus** (Vulkan) → **ANGLE** (Metal, CGL on macOS, EAGL on iOS) → CocoaSpice. The repo doc states plainly that acceleration is unavailable when "the guest drivers for VirtIO GPU are not available or are incomplete (as is the case with Windows)"; a `-gl` display device still lowers latency for unaccelerated guests because QEMU blits straight to an EGL canvas. The doc also says MoltenVK "is currently not used" — that text predates the 5.0 betas, which explicitly ship MoltenVK and DXVK geometry-shader support. [S2][S3][S13]
- **Windows 3D in 5.0.x (experimental):** a new in-guest driver, **Triton**, implements the Windows **DDI** (the interface Microsoft's own `d3d11.dll` calls), reverse-translates DDI calls to D3D11 API calls, and serializes them over **Neptune**, a Direct3D-forwarding VirtIO protocol handled by a Neptune backend in `utmapp/virglrenderer`; on macOS the host renders via **DXMT** (D3D11→Metal) and, in v5.0.5, **D3DMetal** for DirectX 12 "when available". The guest kernel-mode piece is developed in `osy/kvm-guest-drivers-windows` (branch `neptune`) and the user-mode Mesa piece in `osy/virtio-win-mesa` (branch `neptune`). Upstream virtio-win PR #943 (the earlier community attempt at a Windows virtio-gpu 3D driver, opened 2023-07-18) is still open and, per mid-2026 comments, has been superseded by Triton. [S2][S3][S28][S29][S32] (Snippet, unverified: UTM's blog post "Introducing Triton" was published 2026-07-24 and credits AI assistance.)
- **UTM Remote / UTM Server (v4.5, 2024):** on macOS 13+ UTM can run a server that streams **QEMU-backend VMs only** to the free UTM Remote client (iOS/visionOS) — Bonjour discovery, fingerprint pairing, optional password, UPnP/NAT-PMP for external access. Over the network, the SPICE path sends pixel buffers, so **GPU acceleration is not supported remotely**. [S13][S25][S26][S33]
- **iOS variants:** `UTM.ipa` (sideload, JIT via AltStore/SideStore + a JIT enabler such as StikDebug), `UTM-HV.ipa` (TrollStore: adds hypervisor on M1+ iPads and USB), `UTM.deb` (jailbreak), and `UTM-SE.ipa` / App Store **UTM SE** (no JIT, no hypervisor, no USB). [S15]

## Feature checklist (table: feature | status | notes)

| Feature | Status (2026-09) | Notes / source |
|---|---|---|
| Windows 11 ARM64 guest on Apple Silicon | Supported (stable) | Wizard "Virtualize → Windows"; Secure Boot + TPM 2.0 enabled automatically on newer UTM; build must be ≥ 21390. [S9] |
| Windows ISO acquisition | Supported | CrystalFetch (App Store/GitHub) builds ARM64 or x64 ISOs from Microsoft's UUP feeds; Microsoft direct links also listed. [S9][S22] |
| SPICE guest tools (network, display resize, clipboard, WebDAV shares) | Supported (stable) | Auto-installed during Windows Setup when "Install drivers and SPICE tools" is checked; manual `spice-guest-tools-xxx.exe` for XP+ (x86_64, i386, arm64). "Networking does not work" without them; `ping` never works (libslirp). [S9][S10] |
| 3D / DirectX acceleration for Windows guests | **Not in stable**; **experimental in 5.0.4+/5.0.5 beta** | Issue #3459 "3d acceleration on windows" tagged *wontfix* (2022); maintainer in 2022: "AFAIK nobody is working on it"; May 2026 issue #7732 shows Windows 11 ARM on stable using `d3d10warp.dll` (Basic Render Driver). Beta: DX11 via Triton/DXMT, DX12 via D3DMetal; "fresh Windows 11 installs recommended"; driver "could cause system instability". [S2][S3][S11][S12][S32] |
| OpenGL/Vulkan acceleration for Linux guests | Supported (VirGL stable; Venus/Vulkan 1.3 in 5.0 beta) | Display doc: "the drivers to support this feature are Linux only… experimental… some 3D games… may crash." [S21][S34] |
| x86-64 Windows on Apple Silicon | Supported but slow (TCG) | Guide: default is **one core** because "emulating multiple x86_64 cores on an ARM64 system will be done on a single core"; "Force multicore" available "at the cost of correctness". [S9][S14] |
| macOS guests on Apple Silicon | Supported (Apple Virtualization) | Monterey+; clipboard sync with macOS 15 guests; nested virtualization for Linux on M3+. [S20][S31] |
| Apple Virtualization backend features | Partial | No multiple displays for macOS guests (snippet); shared-directory stability fixes in 4.7.5. [S1] |
| Snapshots / suspend | Partial | (Not verified in fetched docs — see Open questions.) |
| USB passthrough | Supported on macOS QEMU backend | libusb stability fixes in 4.7.5; iOS only via TrollStore build. [S1][S15] |
| Automation | Supported | App Intents/Shortcuts (4.7); scripting interface replaced URI scheme (removed in 4.5 for security). [S17][S33] |
| Remote/VDI use | Supported (QEMU VMs only, no GPU) | UTM Server (macOS 13+) + UTM Remote. [S25][S26] |
| Windows 11 24H2 | Known issue | Guest-tools ISO graphics driver causes black screen at install; workaround: eject guest tools, install, remount. [S9][S20] |
| Enterprise management, volume licensing, Microsoft authorization | Not offered | (Parallels compare page snippet, unverified.) |

## CAD / AutoCAD relevance

- **AutoCAD's own requirements are hostile to this stack.** Autodesk's "System requirements for AutoCAD 2025 including Specialized Toolsets" state **"ARM Processors are not supported,"** require a **DirectX 11-compliant GPU (basic)** and **DirectX 12 Feature Level 12_0** for the "Fast" shaded/wireframe visual styles, and carry Autodesk's blanket virtualization disclaimer ("Autodesk makes no representations, warranties or other promises related to use of any product in any virtualization environment… you assume all risks"). A separate Autodesk KB about Parallels install failures repeats: "ARM processors are not supported for a lot of desktop Autodesk products (for Windows environment)." [S35][S36]
- **On stable UTM (4.7.5) the practical AutoCAD experience is x64 AutoCAD running under Windows 11 ARM's built-in x64 emulation, drawing through WARP software rendering** because the guest sees only the Basic Render Driver [S12]. Autodesk's own Parallels KB shows what that produces even on a GPU-accelerated VM: slow performance, choppy linework, cursor issues, and "hardware acceleration is turned off" errors, with the recommended mitigation being to disable AutoCAD hardware acceleration. [S37]
- **The 5.0.x betas are the first credible path to a DirectX 11/12 GPU in a UTM Windows guest.** If Triton matures, a Windows 11 ARM VM in UTM could present a DX11-capable adapter to AutoCAD; the v5.0.5 notes still require a fresh Windows 11 install and warn of instability, and the search-only coverage describes DX12 Feature Level 12_1 exposure as "experimental". Nothing in the fetched material shows CAD software tested. [S2][S3]
- **x86-64 emulation is not a viable AutoCAD path**: one emulated core by default, and community/maintainer statements that x86_64 guests are "impossible to use" for real work (2021) with TCG boot times in minutes even for Windows XP (2023). [S9][S14][S38]
- **Remote/VDI mode adds no value for CAD** because the SPICE network path drops GPU acceleration entirely. [S13]

## Strengths (what to match)

1. **Zero-cost, zero-lock-in entry point** with an honest "App Store = donation" model; the same binary is on GitHub. [S5]
2. **Near-native ARM64 virtualization** on Apple Silicon using Apple's hypervisor, plus a wizard that handles Secure Boot/TPM, downloads guest tools automatically, and mounts a shared folder. [S9][S31]
3. **Breadth:** 30+ emulated architectures, retro OS presets (Mac OS 8/9, Windows 95/98, RISC-V Ubuntu), Linux GPU acceleration, macOS guests, iOS/visionOS clients. [S4][S17]
4. **Real open-source graphics R&D**: the Venus/Vulkan, DXMT, D3DMetal and Triton/Neptune work is the only open DirectX-in-QEMU path on macOS and is shipping in public betas today. [S2][S3][S28]
5. **Platform polish signals:** Liquid Glass adoption within months of macOS 26, App Intents, TSO toggle, nested virtualization, ASIF images — the maintainer tracks Apple platform features quickly. [S17][S19][S20]
6. **Remote/VDI story** (UTM Server + free UTM Remote) with sane security (fingerprint pairing, per-client approval). [S25][S26]

## Weaknesses (what MIRRORZ must beat)

1. **No GPU for Windows in any stable release, four-plus years after the request was closed as wontfix**; CAD/DirectX apps fall to WARP. [S11][S12][S13]
2. **x86-64 on Apple Silicon is single-core TCG by default**; "Force multicore" trades correctness for speed. Nobody should run x64 Windows this way. [S9]
3. **Setup friction and fragility:** manual ISO building, guest-tools ISO breaking Windows 11 24H2 installs, `ping` never working, occasional regressions acknowledged by the maintainer after each QEMU bump. [S9][S20][S18]
4. **No application-level integration:** no "run this .exe as a Mac window" experience; you always operate a whole Windows desktop (the SPICE frontend is a full-VM console). [S13]
5. **Support model:** community Discord + GitHub issues; no SLA, no enterprise licensing, no Microsoft authorization (snippet). [S30]
6. **Licensing complexity for anyone who forks:** Apache app, GPL QEMU engine, statically linked LGPL GStreamer, "minified" App Store SE build, Windows drivers that must be re-signed (WHQL) to load on Secure-Boot Windows. [S4][S16][S29]
7. **iOS story is capped by Apple policy:** UTM SE is JIT-less and "much slower"; full UTM needs sideloading + JIT enablers; Apple's background-GPU entitlement request was closed "not planned". [S15][S39]

## Reusable code, ideas, and license implications for MIRRORZ

- **Apache-2.0 pieces (safe to reuse in a commercial closed-source product with attribution and NOTICE preservation):** UTM's Swift/Obj-C front end and configuration model, **CocoaSpice** (Metal SPICE renderer), the VM wizard logic (Secure Boot/TPM defaults, guest-tools download flow), the App Intents/scripting surface, **CrystalFetch** (ISO building from UUP — directly reusable for a "download Windows 11 ARM" onboarding step), and the CC0 documentation. [S13][S22][S23][S30]
- **GPL-2.0 pieces (do not link into proprietary code; ship as a separate process and publish your modifications):** `utmapp/qemu` (`utm-edition`) and its TCG/TCTI work. UTM's own architecture — QEMU in a separate `QEMULauncher` process talking over SPICE/IOSurface — is the pattern to copy if MIRRORZ uses QEMU at all. Note the README's warning that GStreamer plugins are **statically linked (L)GPL**, which MIRRORZ should avoid. [S4][S13][S27]
- **Windows guest drivers:** virtio-win is BSD-3-Clause post-2018, but the README notes that GPL-era code "is not compatible with WHQL" and that shipping drivers requires either test-signing or your own code-signing certificate and a WHQL submission; Secure Boot Windows will not load cross-signed drivers. This is a real cost line-item for any MIRRORZ GPU driver. [S29]
- **Ideas worth borrowing regardless of code:** (a) the DDI-level driver design of Triton (implement the Windows DDI, forward D3D11 calls over VirtIO, render with DXMT/D3DMetal) — the only known open path to DX11/DX12 for Windows-on-ARM guests on Apple Silicon [S2][S3]; (b) enabling TSO at the hypervisor level for x86 emulation inside the guest [S20]; (c) the "-gl display device even without guest drivers" latency trick [S13]; (d) the free-client / paid-convenience distribution split [S5].
- **Differentiation MIRRORZ can claim today:** app-level (not VM-level) UX, guaranteed GPU path for CAD, a supported/QA'd Windows 11 ARM image pipeline, and vendor support — none of which UTM offers in stable.

## Open questions

1. Will Triton/DXMT/D3DMetal graduate to a stable UTM 5.0 release in 2026, and does it pass AutoCAD's DirectX feature checks (FL 12_0 for "Fast" visual styles)? No CAD testing found.
2. What exactly did Apple require removed from the "minified" UTM SE App Store build, and is UTM SE still being updated in 2026? (Docs still link it; the last fetched SE-specific change is 2024's donation IAP.)
3. Snapshot/suspend-resume parity between the QEMU and Apple Virtualization backends was not verifiable from fetched docs.
4. Windows-on-ARM licensing: UTM ships no Windows license; how Microsoft's retail-key stance on ARM VMs affects UTM users was not researched here.
5. The July 2026 UTM blog post on Triton (and its AI-assistance credit) could not be fetched; details above beyond the release notes are labelled as snippets.
6. Mac App Store rating/review counts and Turing Software's revenue signal could not be retrieved (App Store blocked).

## Sources (numbered list of URLs with dates)

1. [S1] Git tag timestamps from a bare clone of https://github.com/utmapp/UTM (clone made 2026-09-03; e.g. v5.0.5 2026-09-01, v5.0.4 2026-08-01, v5.0.0 2026-01-11, v4.7.5 2026-01-03, v4.7.4 2025-09-15, v4.6.2 2024-11-27, v4.5.4 2024-08-24, v4.5.0 2024-02-27).
2. [S2] https://github.com/utmapp/UTM/releases/tag/v5.0.4 — "v5.0.4 (Beta)", tagged 2026-08-01.
3. [S3] https://github.com/utmapp/UTM/releases/tag/v5.0.5 — "v5.0.5 (Beta)", tagged 2026-09-01 (published Sept 2 UTC).
4. [S4] https://github.com/utmapp/UTM — README and repo stats, fetched 2026-09-03 (35.3k stars, 1.8k forks; license paragraph).
5. [S5] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/installation/macos.md — official docs source (App Store vs GitHub statement), fetched 2026-09-03.
6. [S6] https://sourceforge.net/projects/utm.mirror/ — mirror listing "v4.7.5, January 3, 2026", fetched 2026-09-03.
7. [S7] https://github.com/utmapp/UTM/issues/7046 — user report of $9.99 App Store price, 2025-03-04.
8. [S8] https://github.com/utmapp/UTM/discussions/7076 — "The App Store version cost 10$… the free version is on GitHub", 2025-03-04/06.
9. [S9] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/guides/windows.md — Windows 11 guide (CrystalFetch, SPICE tools, single-core x86_64 default, 24H2 issue), fetched 2026-09-03.
10. [S10] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/guest-support/windows.md — Windows guest tools doc, fetched 2026-09-03.
11. [S11] https://github.com/utmapp/UTM/issues/3459 — "3d acceleration on windows", opened 2022-01-08, labels enhancement + wontfix.
12. [S12] https://github.com/utmapp/UTM/issues/7732 — Windows 11 ARM guest on Basic Render Driver (d3d10warp.dll), opened 2026-05-31.
13. [S13] https://raw.githubusercontent.com/utmapp/UTM/main/Documentation/Graphics.md — in-repo graphics architecture doc, fetched 2026-09-03.
14. [S14] https://github.com/utmapp/UTM/issues/5468 — TCG timing comparison (Windows XP, M1 Max: ~21 s direct QEMU vs ~1 min in UTM), opened 2023-07-16.
15. [S15] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/installation/ios.md — iOS install doc (UTM SE description, sideload/JIT matrix), fetched 2026-09-03.
16. [S16] https://github.com/utmapp/UTM/discussions/6257 — "UTM SE on the iOS App Store", opened 2024-04-05; "officially published on the App Store" 2024-07-14; App Store build "minified".
17. [S17] https://github.com/utmapp/UTM/releases/tag/v4.7.5 and https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/updates/v4.7.md — v4.7 highlights (QEMU 10.0.2, Liquid Glass, App Intents).
18. [S18] https://github.com/utmapp/UTM/discussions/7558 — v4.7.5 announcement thread, 2026-01-03.
19. [S19] https://github.com/utmapp/UTM/releases/tag/v4.7.4 — v4.7.4 (macOS 26 settings redesign, ASIF images, iOS 26 StikDebug), tagged 2025-09-15.
20. [S20] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/updates/v4.6.md — v4.6 notes (QEMU 9.1.2, nested virt, TSO, 24H2 issue).
21. [S21] https://github.com/utmapp/UTM/releases/tag/v5.0.0 — "v5.0.0 (Beta)", tagged 2026-01-11.
22. [S22] https://github.com/TuringSoftware/CrystalFetch — Apache-2.0 ISO builder, fetched 2026-09-03.
23. [S23] https://raw.githubusercontent.com/utmapp/UTM/main/LICENSE — Apache License 2.0 text, fetched 2026-09-03.
24. [S24] https://github.com/utmapp/UTM/releases/tag/v4.5.4 — v4.5.4 (SE donations via IAP), 2024-08-24.
25. [S25] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/remote/remote.md — UTM Remote doc (free App Store, Bonjour, fingerprint pairing).
26. [S26] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/remote/server.md — UTM Server doc (requires 4.5.2+, QEMU VMs only).
27. [S27] https://github.com/utmapp/qemu — QEMU fork, branch `utm-edition`, GPLv2/LGPL-2.1, fetched 2026-09-03.
28. [S28] https://github.com/osy/kvm-guest-drivers-windows — Neptune branch fork, BSD-3-Clause, fetched 2026-09-03.
29. [S29] https://raw.githubusercontent.com/osy/kvm-guest-drivers-windows/neptune/README.md — virtio-win signing/WHQL notes, fetched 2026-09-03.
30. [S30] https://github.com/utmapp/docs.getutm.app — docs repo (CC0-1.0), fetched 2026-09-03; https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/index.md (community Discord/GitHub support model).
31. [S31] https://github.com/utmapp/mac.getutm.app/blob/main/index.html — source of the mac.getutm.app marketing page, fetched 2026-09-03.
32. [S32] https://github.com/virtio-win/kvm-guest-drivers-windows/pull/943 — "[viogpu3d] Virtio GPU 3D acceleration for windows", opened 2023-07-18, still open; 2026 comments reference Triton.
33. [S33] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/updates/v4.5.md and https://github.com/utmapp/UTM/releases/tag/v4.5.0 — UTM Remote/Server introduction (beta 2024-02-27; stable v4.5.3 2024-05-23).
34. [S34] https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/settings-qemu/devices/display.md — "(GPU Supported)… drivers… are Linux only".
35. [S35] https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html — via Autodesk Product Help MCP, 2026-09-03.
36. [S36] https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html — Autodesk KB (ARM not supported for many desktop products), via MCP 2026-09-03.
37. [S37] https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html — Autodesk KB, via MCP 2026-09-03.
38. [S38] https://github.com/utmapp/UTM/discussions/2533 — "On MacBook Air M1 it is extremely slow", 2021-05-15; maintainer: "x86_64 is being emulated".
39. [S39] https://github.com/utmapp/UTM/issues/7220 — iPadOS 26 background-GPU entitlement request, opened 2025-06-09, closed as not planned.
40. [S40] https://gitlab.com/qemu-project/qemu/-/issues/2295 — QEMU feature request for Apple Silicon x86 acceleration (TSO), undated in fetch; no acceleration exists upstream.
41. [S41] https://raw.githubusercontent.com/tctiSH/qemu/with_tcti/tcg/aarch64-tcti/README.md — TCTI ("threaded interpreter… usable when JIT isn't available"), fetched 2026-09-03.
42. [S42] https://github.com/jameskaois/windows-11-on-mac-apple-silicon — community Windows 11 on UTM guide (4 GB RAM / 64 GB disk defaults), fetched 2026-09-03.

Snippet-only (pages could not be opened; treat as unverified): Macworld best-VM roundup and UTM review ($9.99/£9.99, "quirky" vs Parallels); Parallels' "UTM compare" page (no DirectX, no enterprise features); TechSpot/Neowin/Slashdot coverage of the June 2024 rule-4.7 rejection and 2024-07-13 approval of UTM SE; Phoronix/linuxcompatible coverage of the 2026-07-24 Triton blog post.
