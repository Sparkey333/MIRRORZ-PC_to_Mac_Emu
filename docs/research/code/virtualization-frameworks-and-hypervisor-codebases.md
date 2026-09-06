# Apple Virtualization/Hypervisor Frameworks and the Open-Source VM Codebases on Apple Silicon

_Research date: 2026-09-03_

Scope: Apple Virtualization.framework (VZ), Apple Hypervisor.framework (HVF), Tart, VirtualBuddy, UTM (QEMU + hvf), Lima, MacVM, Apple's Containerization package, and how Parallels boots Windows. Every version number, date, price and status below comes from a page fetched on 2026-09-03 unless explicitly marked "search snippet only" (page was egress-blocked in this environment and could not be opened directly).

## TL;DR (5 bullets)

- **Virtualization.framework officially runs only macOS and Linux guests.** Apple's own overview says "Create virtual machines and run macOS and Linux-based operating systems"; Windows is not mentioned anywhere in the framework docs, the WWDC26 session, or UTM's Apple-backend docs. There is no TPM device, no custom device model (Apple DTS, March 2023), and the new macOS 27 `VZCustomVirtioDevice` is aimed at Linux guests. **A Windows/AutoCAD product cannot be built on VZ.**
- **The only Apple-sanctioned path to a Windows 11 ARM guest is Hypervisor.framework plus your own device model.** UTM does it by embedding QEMU (GPLv2) with the `hvf` accelerator, UEFI, emulated TPM/Secure Boot and SPICE guest tools; Parallels does it with its own virtualization engine on top of "the Apple hypervisor" (the Parallels hypervisor "can't be used" on Apple silicon per Parallels KB). Both use the `com.apple.security.hypervisor` entitlement; Apple says apps built on HVF are "suitable for distribution on the Mac App Store", and UTM ships on the Mac App Store sandboxed.
- **Licensing landscape (checked 2026-09-03):** Tart is **FSL-1.1-ALv2** (Functional Source License, copyright "2022-2026 OpenAI", relicensed 2026-06-05 after Cirrus Labs joined OpenAI) — *not* Fair Source any more, and *not* Apache yet; VirtualBuddy **BSD-2-Clause**; UTM **Apache-2.0 with GPL/LGPL components (QEMU)**; Lima **Apache-2.0** (CNCF incubating); MacVM (KhaosT) **Apache-2.0**; Apple Containerization **Apache-2.0**; QEMU **GPLv2** as a whole.
- **Momentum in 2026 is strong on the VZ side (macOS 27: USB passthrough, DiskImageKit stacked disks, vmnet topologies, guest provisioning, custom Virtio devices) but nothing new for Windows.** UTM's 5.0 betas (latest v5.0.5, 2026-09-02) add D3DMetal-backed DirectX for Windows 11 guests — the first open-source route to accelerated DirectX in a Windows-on-ARM VM on a Mac, still experimental.
- **Recommendation:** build the MIRRORZ Swift app shell on Hypervisor.framework with a QEMU process out-of-process (UTM's proven, App-Store-compatible architecture, GPL-isolated), study VirtualBuddy/Apple samples for the Swift VM-window and lifecycle UX, and treat Tart as "read for ideas, do not copy" because FSL's Competing-Use clause covers a commercial VM product until each release's two-year Apache conversion.

## Current status (version, date, maintainer, momentum)

| Project | Latest release (date) | Maintainer | Momentum / notes |
|---|---|---|---|
| Apple Virtualization.framework | macOS 26 shipped ASIF disks, vmnet custom topologies, `queue` property (Apple "updates" page, June 2025); macOS 27 (WWDC26, June 2026, session 224) adds guest provisioning, USB passthrough, port forwarding, DiskImageKit, `VZCustomVirtioDevice` | Apple | Actively expanding for macOS/Linux; nothing for Windows |
| Apple Hypervisor.framework | June 2024: nested virtualization (EL2) + virtual GIC on Apple silicon; June 2025: IPA granularity down to 4 KB (Apple "updates" page) | Apple | Stable low-level C API since macOS 10.10 |
| Tart | 2.36.0 (2026-08-25); 2.35.0 built "on macOS 26 with Xcode 27"; 2.36.0 begins DiskImageKit integration | Cirrus Labs → **OpenAI** (Cirrus Labs announced joining OpenAI on 2026-04-07; Cirrus CI shut down 2026-06-01 — search snippets, cirruslabs.org blocked) | Still releasing monthly, but MacStadium/Cirrus said the dedicated team "is moving on to other projects at OpenAI" (snippet) |
| VirtualBuddy | 2.2 beta 4 (2026-08-27): USB passthrough "requires macOS 27 host and guest"; beta 2 installs macOS 27 guests on macOS 26 hosts | Guilherme Rambo (insidegui) | 8.7k stars; tracks Apple betas fast |
| UTM | Stable v4.7.5 (2026-01-03, QEMU v10.0.2, ASIF default on macOS 26); beta v5.0.5 (2026-09-02, DirectX via D3DMetal for Windows 11 guests, Vulkan 1.3 for Linux) | osy / utmapp | 35.4k stars, 1.8k forks; very active |
| Lima | v2.2.0 (2026-07-25) adds experimental Windows 11 / Windows Server 2025 guests and TPM emulation; v2.3.0-beta.0 (2026-09-01) | CNCF incubating project | 21.8k stars; Go, not Swift |
| MacVM (KhaosT) | 27 commits, no releases, "an example project"; macOS Monterey+ hosts, macOS guests only | Khaos Tian | 1.4k stars; effectively a proof of concept |
| Apple Containerization | Swift package; requires "Mac with Apple silicon, macOS 26, Xcode 26" | Apple | 8.9k stars; Linux containers only |
| QEMU (hvf backend) | `target/arm/hvf/hvf.c` — "Copyright 2020 Alexander Graf / Google LLC", GPLv2+; EL2 via `hv_vm_config_set_el2_enabled` on macOS 15+ | QEMU project | hvf listed for macOS x86 and Arm hosts |
| Parallels Desktop | Parallels Desktop 26 announced 2025-08-26 (search snippets; parallels.com blocked) | Parallels (Alludo) | Only "Microsoft-authorized" Windows 11 ARM solution (snippet) |

## Pricing and licensing (table)

| Project | License / price | Source date | Implication for MIRRORZ |
|---|---|---|---|
| Virtualization.framework, Hypervisor.framework | Part of macOS; free; entitlements `com.apple.security.virtualization` and `com.apple.security.hypervisor` (both macOS 11+) | Apple docs, fetched 2026-09-03 | No cost; HVF explicitly App-Store-suitable |
| Tart | **FSL-1.1-ALv2** since 2026-06-05 (PR #1238 by fkorotkov-oai; copyright "2022-2026 OpenAI"). History: initial license 2022-03-07 → "Relicensed under Fair Source License" 2023-02-28 → FSL 2026-06-05. FSL forbids "Competing Use" (offering a substitute product) until each version converts to Apache-2.0 on its second anniversary. Cirrus said licensing fees were stopped (snippet). | GitHub LICENSE + commit history, 2026-09-03 | Read-only reference for a commercial VM app until the 2-year clock passes per release |
| VirtualBuddy | BSD-2-Clause | GitHub README, 2026-09-03 | Freely reusable with attribution |
| UTM | Apache-2.0 "but incorporates GPL/LGPL components"; "gstreamer plugins are statically linked and parts of the code are taken from qemu". Mac App Store copy reported at $9.99 (search snippet; apps.apple.com blocked); mac.getutm.app says the App Store build has "no features left out of the free version" | GitHub README + mac.getutm.app source, 2026-09-03 | Architecture reusable; any file taken from QEMU is GPL |
| QEMU | "The QEMU emulator as a whole is released under the GNU General Public License, version 2"; TCG mostly BSD/MIT | qemu/qemu LICENSE, 2026-09-03 | Ship as separate GPL process/binaries with source offer; do not link into proprietary code |
| Lima | Apache-2.0 (CNCF) | GitHub README, 2026-09-03 | Go; ideas reusable (vz driver, port-forwarding) |
| MacVM (KhaosT) | Apache-2.0 | GitHub, 2026-09-03 | Minimal VZ sample |
| Apple Containerization | Apache-2.0 | GitHub, 2026-09-03 | Best large Swift VZ codebase from Apple |
| Parallels Desktop 26 | Standard $99.99/yr or $219.99 perpetual; Pro $119.99/yr; Business $149.99/yr (search snippets from parallels.com/products/desktop/buy and vendr; not directly fetchable) | 2026 pages (snippets) | Price ceiling MIRRORZ competes under |

## How it works (architecture)

**Hypervisor.framework (HVF)** is the base layer. Apple: "Hypervisor provides C APIs so you can interact with virtualization technologies in user space, without writing kernel extensions (KEXTs)"; it "abstracts virtual machines as processes, and virtual processors as threads", one VM per process, `hv_vm_create`/`hv_vcpu_create`/`hv_vcpu_run`, `hv_vm_map` for guest memory, and the app must "emulate memory-mapped hardware by emulating the memory access on exit". "All process must have the `com.apple.security.hypervisor` entitlement". Since June 2024 it exposes EL2 for nested virtualization and a virtual GIC; since June 2025, 4 KB IPA granularity. HVF gives you CPU and memory only — **every device (UEFI, disk, NIC, GPU, TPM, input) is your code.**

**Virtualization.framework (VZ)** sits on HVF and supplies Apple's device models: graphics, audio, network, storage, keyboard/pointing, serial, shared directories, sockets, memory balloon, RNG, multiport consoles, clipboard (SPICE agent port), USB (mass storage hot-plug since macOS 15; accessory passthrough in macOS 27), Rosetta directory share for x86_64 Linux binaries, and three boot loaders: `VZMacOSBootLoader`, `VZLinuxBootLoader`, and `VZEFIBootLoader` (macOS 13+) with `VZEFIVariableStore` and UEFI Secure Boot signature lists. There is **no TPM class** in the framework topics, and Apple DTS answered in March 2023 that "Virtualization framework only supports the virtualised devices that are documented in that list." macOS 27's `VZCustomVirtioDevice` (WWDC26 session 224) lets an app implement its own Virtio device — but Windows has no driver for such a device, and the session covered "macOS and Linux VMs only". macOS guest VMs get paravirtualized Metal; Linux guests get no GPU acceleration (Red Hat's 2025 article on libkrun exists precisely because VZ "doesn't expose GPU ... to Linux guests" — search snippet). Apple's license limits a host to **two concurrent macOS guests** (Eclectic Light / Parallels KB, search snippets).

**UTM (Windows 11 ARM path):** UTM is "based off of QEMU" and on macOS uses "Hardware accelerated virtualization using Hypervisor.framework" for arm64 guests, and "Apple Virtualization" only for "macOS guests and Linux guests when booting from UEFI". Its Windows guide: obtain the ARM64 ISO with CrystalFetch, boot UEFI, "Secure Boot and TPM should be enabled automatically" on current versions (older builds used the `LabConfig` `BypassTPMCheck` registry workaround), then install the SPICE guest tools/drivers or "Networking does not work". QEMU's `hvf.c` implements the vCPU run loop, system-register trapping, GIC and PSCI on Apple silicon. In UTM 5.0 betas, Windows 11 guests can get DirectX through QEMU's virglrenderer "Neptune" backend mapped to Apple's D3DMetal on macOS 13+ (experimental). The QEMU helper runs as a separate sandboxed process; Apple fixed sandbox-inheritance for HVF in macOS 11.3 beta 2 (March 2021) after UTM's report.

**Parallels (Windows 11 ARM path):** per Parallels KB (search snippets; kb.parallels.com blocked): "Parallels engineers created a new virtualization engine that uses the Apple silicon chip hardware-assisted virtualization", and "On Apple silicon Macs, the Parallels hypervisor can't be used and all VMs are booted via the Apple hypervisor" — i.e., Parallels' proprietary device model on Hypervisor.framework, with the Parallels/Apple hypervisor toggle "only available on Intel Macs". Nested virtualization/WSL2 remains unavailable in Windows guests on Apple silicon (KB 129497 snippet). x86 Windows emulation on Apple silicon arrived as a "technology preview" in Parallels Desktop 20.2 (January 2025; 1 vCPU, ≤8 GB RAM, no USB — snippets).

**Tart / VirtualBuddy / Lima / Containerization** are all VZ consumers: Tart is a Swift CLI (macOS 13+) that pushes/pulls VM images to OCI registries; VirtualBuddy is a Swift GUI (macOS 13+ host) for macOS 12+ guests and "some ARM-based Linux distros"; Lima is Go with `vz` and `qemu` drivers — its new Windows-guest support is **QEMU-only with swtpm TPM 2.0** (CNCF blog snippet, 2026-07-28), which independently confirms VZ cannot host Windows; Apple's Containerization spawns one VZ micro-VM per Linux container.

## Feature checklist (table: feature | status | notes)

| Feature | Status | Notes |
|---|---|---|
| Linux guest on VZ | Supported | `VZLinuxBootLoader` or EFI; Rosetta for x86_64 binaries; GUI sample requires macOS 13 |
| macOS guest on VZ | Supported (Apple silicon only) | `VZMacOSInstaller` from .ipsw; max two concurrent macOS VMs (snippet); iCloud from macOS 15 guests |
| Windows guest on VZ | **Not supported** | Not in docs, WWDC26, UTM or Lima's vz driver |
| TPM 2.0 device in VZ | Missing | No class; UTM/Lima use QEMU + swtpm instead |
| UEFI boot in VZ | Supported for Linux (macOS 13+) | `VZEFIBootLoader`, EFI NVRAM store, Secure Boot signature DB |
| Custom devices in VZ | macOS 27: `VZCustomVirtioDevice` | Linux-oriented; pre-27 impossible per DTS |
| USB passthrough in VZ | macOS 27 via AccessoryAccess | Mass-storage hot-plug since macOS 15 |
| GPU for Linux guests in VZ | Missing | libkrun/UTM use HVF + virtio-gpu/Venus instead |
| DirectX in Windows-on-ARM VM (open source) | UTM 5.0.5 beta (2026-09-02), experimental | D3DMetal on macOS 13+ |
| Nested virtualization | HVF: June 2024 (M3+, macOS 15); VZ Linux: June 2024 | Parallels Windows guests: not available (snippet) |
| Mac App Store distribution | HVF "suitable for distribution on the Mac App Store"; UTM sold there | Sandbox + inherit fixed in macOS 11.3 |
| Copy-on-write / snapshot disks | macOS 26 ASIF; macOS 27 DiskImageKit stacked layers | Tart 2.36.0 adopting |
| Swift sample code | Apple: macOS VM sample (Swift+ObjC, macOS 14 target, Xcode 26), GUI Linux sample (macOS 13) | Plus VirtualBuddy, Tart, Containerization |

## CAD / AutoCAD relevance

- AutoCAD is Windows x64 software; Autodesk's Windows-on-ARM KB (via Autodesk help API) still states ARM64 "is not compatible with Autodesk products, which are based on 64-bit (x64) software", while a 2026 search snippet claims AutoCAD 2026 "explicitly lists ARM64 operating systems as supported". **This conflict is unresolved** (autodesk.com was blocked); Autodesk's requirements index now lists AutoCAD 2027, so the current release must be checked directly. Either way, inside a Windows 11 ARM VM, x64 AutoCAD would rely on Microsoft's Prism translation.
- AutoCAD requires a DirectX 11-class GPU. No VZ path exists for Windows at all; among open-source stacks only UTM 5.0 beta offers DirectX (via D3DMetal), and it is experimental. Parallels' DirectX support for Windows-on-ARM guests was not verified in this pass.
- Autodesk's system-requirements pages carry a virtualization clause: "You may virtualize a product only if the applicable terms and conditions ... expressly permit virtualization" — a licensing risk MIRRORZ marketing must respect.

## Strengths (what to match)

- UTM: one app, two backends (HVF+QEMU for Windows, VZ for macOS/Linux), App Store presence, auto-TPM/Secure Boot, guest tools, CrystalFetch ISO pipeline, D3DMetal graphics work.
- VirtualBuddy: polished Swift UX around VZ — restore-image wizard, save/restore, guest app for clipboard and folder mounting, APFS cloning, fast adoption of macOS betas (USB passthrough within days of macOS 27 betas).
- Tart: image distribution via OCI registries, headless CLI, DiskImageKit adoption.
- Parallels: Microsoft-authorized Windows 11 ARM installer, proprietary device model with years of Windows driver work.

## Weaknesses (what MIRRORZ must beat)

- Every open-source Windows path is QEMU-based: no first-class Windows guest tools comparable to Parallels Tools, networking quirks ("ping will not work" via libslirp), display regressions (Windows 11 24H2 black-screen issue in UTM 4.6 notes), experimental 3D.
- VZ-based apps (Tart, VirtualBuddy, Lima-vz, Containerization) cannot run Windows at all.
- Tart is now FSL-encumbered and its team has moved to OpenAI; VirtualBuddy is a single-maintainer hobby project; MacVM is unmaintained.
- Parallels: no nested virtualization/WSL2 on Apple silicon, x86 emulation is a 1-vCPU preview, subscription pricing.

## Reusable code, ideas, and license implications for MIRRORZ

1. **Foundation: Hypervisor.framework + `com.apple.security.hypervisor`.** This is the only Apple API that can host Windows; it is App-Store-compatible by Apple's own statement. Add `com.apple.security.virtualization` too if MIRRORZ also offers Linux/macOS VMs through VZ.
2. **Device model choice.** (a) *Embed QEMU as a separate GPL process* (UTM's model): fastest to Windows 11 ARM with TPM, UEFI, virtio, SPICE, and now DirectX; must ship QEMU source/offer, keep the proprietary Swift app in a separate process with an IPC boundary, and avoid copying QEMU code into the app (UTM's README admits "parts of the code are taken from qemu", which is why UTM's Apache-2.0 label does not cover the whole product). (b) *Write a proprietary VMM on HVF* (Parallels' model): total control and no GPL, but you must implement UEFI (edk2 is BSD-licensed), virtio-blk/net/gpu, TPM, input and a Windows guest-tools suite — multi-year effort. A pragmatic roadmap is (a) first, (b) later for differentiating devices.
3. **Swift UX and lifecycle code to study/borrow:** Apple's two samples (macOS VM: `VZMacPlatformConfiguration`, `VZMacOSInstaller`, `VZVirtualMachineView`; GUI Linux: `VZEFIBootLoader`, SPICE agent clipboard, Rosetta), VirtualBuddy (BSD-2, reusable), Apple Containerization (Apache-2.0; VM spawning, vsock gRPC agent pattern, ext4 tooling), Lima (Apache-2.0; port-forwarding/file-sharing design), MacVM (Apache-2.0 minimal sample).
4. **Tart: ideas only.** FSL-1.1-ALv2 permits internal use but not "Competing Use"; each Tart release becomes Apache-2.0 two years after publication, so 2024-era Tart code is or soon will be Apache — verify per-commit dates before reuse.
5. **Adopt macOS 26/27 platform features** (ASIF, DiskImageKit overlays for instant VM clones, vmnet topologies, USB passthrough) in the VZ-based part of the product; for the Windows/HVF part these must be reimplemented (QEMU has its own qcow2/USB stack).

## Open questions

- Does AutoCAD 2026/2027 officially support Windows 11 ARM64 natively, and does Autodesk's EULA permit running it in a third-party VM? (Autodesk pages were egress-blocked; conflicting signals.)
- Exact DirectX 11/12 feature level Parallels provides to Windows-on-ARM guests today, and how it compares with UTM 5.0's D3DMetal path.
- Whether Apple will ever add a TPM/Windows boot path to VZ (nothing announced at WWDC25 or WWDC26).
- Current Mac App Store price of UTM and whether the App Store build has restrictions on QEMU JIT (snippet says $9.99 and feature-identical; not verified on apps.apple.com).
- Precise Tart maintenance commitment from OpenAI post-acquisition (releases continue monthly, but the announcement said the team is moving on).
- Status of Rust/Swift HVF VMMs (e.g., libkrun on macOS) as a middle path between QEMU and a from-scratch VMM.

## Sources (numbered list of URLs with dates)

1. Apple, Virtualization framework overview — https://developer.apple.com/documentation/virtualization (undated docs; fetched 2026-09-03 via data endpoint)
2. Apple, `com.apple.security.virtualization` — https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.virtualization (fetched 2026-09-03)
3. Apple, `com.apple.security.hypervisor` — https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.hypervisor (fetched 2026-09-03)
4. Apple, `com.apple.vm.hypervisor` (deprecated macOS 11) — https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.vm.hypervisor (fetched 2026-09-03)
5. Apple, Hypervisor framework overview — https://developer.apple.com/documentation/hypervisor (fetched 2026-09-03)
6. Apple, `VZEFIBootLoader` (macOS 13+) — https://developer.apple.com/documentation/virtualization/vzefibootloader (fetched 2026-09-03)
7. Apple, Virtualization updates (June 2024, June 2025) — https://developer.apple.com/documentation/updates/virtualization (fetched 2026-09-03)
8. Apple, Hypervisor updates (June 2024, June 2025) — https://developer.apple.com/documentation/updates/hypervisor (fetched 2026-09-03)
9. Apple, WWDC26 session 224 "Expand the capabilities of your Virtualization app" — https://developer.apple.com/videos/play/wwdc2026/224/ (June 2026)
10. Apple sample, Running macOS in a virtual machine on Apple silicon — https://developer.apple.com/documentation/virtualization/running-macos-in-a-virtual-machine-on-apple-silicon (fetched 2026-09-03)
11. Apple sample, Running GUI Linux in a virtual machine on a Mac — https://developer.apple.com/documentation/virtualization/running-gui-linux-in-a-virtual-machine-on-a-mac (fetched 2026-09-03)
12. Apple Developer Forums, "Can we add our own devices when using Virtualization.Framework" (DTS answer, March 2023) — https://developer.apple.com/forums/thread/726184
13. Apple Developer Forums, "Cannot use Hypervisor with inherited app sandbox" (Dec 2020; fixed macOS 11.3 beta 2, March 2021) — https://developer.apple.com/forums/thread/668496
14. Apple Developer Forums, community EFI-boot notes (June 2023) — https://developer.apple.com/forums/thread/731074
15. Tart README — https://github.com/cirruslabs/tart (fetched 2026-09-03)
16. Tart LICENSE (FSL-1.1-ALv2, "Copyright 2022-2026 OpenAI") — https://github.com/cirruslabs/tart/blob/main/LICENSE (fetched 2026-09-03)
17. Tart LICENSE commit history (2022-03-07, 2023-02-28, 2026-06-05) — https://github.com/cirruslabs/tart/commits/main/LICENSE
18. Tart PR #1238 "Relicense under FSL-1.1-ALv2" (merged 2026-06-05) — https://github.com/cirruslabs/tart/pull/1238
19. Tart releases feed (2.36.0 2026-08-25; 2.35.0 2026-08-04; 2.33.0 relicense notes) — https://github.com/cirruslabs/tart/releases.atom
20. Tart discussion #433 on Fair Source core counting (2023-03-01) — https://github.com/cirruslabs/tart/discussions/433
21. Cirrus Labs, "Cirrus Labs to join OpenAI" (2026-04-07; search snippet only, blocked) — https://cirruslabs.org/
22. MacStadium, "Cirrus Labs is joining OpenAI" (2026; search snippet only, blocked) — https://macstadium.com/blog/cirrus-labs-is-joining-openai
23. SPDX, FSL-1.1-ALv2 — https://spdx.org/licenses/FSL-1.1-ALv2.html
24. VirtualBuddy README (BSD-2-Clause) — https://github.com/insidegui/VirtualBuddy (fetched 2026-09-03)
25. VirtualBuddy releases feed (2.2-b4 2026-08-27) — https://github.com/insidegui/VirtualBuddy/releases.atom
26. UTM README (Apache-2.0 + GPL/LGPL parts) — https://github.com/utmapp/UTM (fetched 2026-09-03)
27. UTM releases feed (v4.7.5 2026-01-03; v5.0.5 2026-09-02) — https://github.com/utmapp/UTM/releases.atom
28. UTM v5.0.5 beta notes (2026-09-02) — https://github.com/utmapp/UTM/releases/tag/v5.0.5
29. UTM v4.7.5 notes (QEMU v10.0.2, ASIF) — https://github.com/utmapp/UTM/releases/tag/v4.7.5
30. UTM docs, Windows 11 guide (source) — https://github.com/utmapp/docs.getutm.app/blob/main/guides/windows.md (fetched 2026-09-03)
31. UTM docs, Apple Virtualization settings (source) — https://github.com/utmapp/docs.getutm.app/blob/main/settings-apple/virtualization.md
32. UTM docs, macOS guest support (source) — https://github.com/utmapp/docs.getutm.app/blob/main/guest-support/macos.md
33. UTM docs, v4.6 notes (source) — https://github.com/utmapp/docs.getutm.app/blob/main/updates/v4.6.md
34. mac.getutm.app site source (App Store build statement) — https://github.com/utmapp/mac.getutm.app/blob/main/index.html
35. Lima README (Apache-2.0, CNCF) — https://github.com/lima-vm/lima (fetched 2026-09-03)
36. Lima releases feed (v2.2.0 2026-07-25; v2.3.0-beta.0 2026-09-01) — https://github.com/lima-vm/lima/releases.atom
37. Lima v2.2.0 release notes — https://github.com/lima-vm/lima/releases/tag/v2.2.0
38. CNCF blog, "Lima v2.2: Windows guests and TPM 2.0 emulation" (2026-07-28; search snippet only, blocked) — https://www.cncf.io/blog/2026/07/28/lima-v2-2-windows-guests-and-tpm-2-0-emulation/
39. MacVM (Apache-2.0) — https://github.com/KhaosT/MacVM (fetched 2026-09-03)
40. Apple Containerization (Apache-2.0, macOS 26) — https://github.com/apple/containerization (fetched 2026-09-03)
41. QEMU LICENSE (GPLv2) — https://github.com/qemu/qemu/blob/master/LICENSE
42. QEMU `target/arm/hvf/hvf.c` — https://github.com/qemu/qemu/blob/master/target/arm/hvf/hvf.c
43. QEMU docs, accelerators table — https://github.com/qemu/qemu/blob/master/docs/system/introduction.rst
44. Parallels KB 125343 "About Parallels Desktop for Mac with Apple silicon" (search snippet only, blocked) — https://kb.parallels.com/125343
45. Parallels KB 128914 "Apple silicon limitations" (search snippet only, blocked) — https://kb.parallels.com/en/128914
46. Parallels KB 129497 "Limitations of running Windows 11 on Apple silicon" (search snippet only, blocked) — https://kb.parallels.com/en/129497
47. Parallels KB 130217 x86 emulator (search snippet only, blocked) — https://kb.parallels.com/130217
48. Parallels press release, Parallels Desktop 26 (2025-08-26; search snippet only, blocked) — https://www.parallels.com/newsroom/news/press-releases/20250826-parallels-desktop-26/
49. Parallels buy page pricing (2026; search snippet only, blocked) — https://www.parallels.com/products/desktop/buy/
50. Eclectic Light, "How Apple limits VMs" (2022-08-04; search snippet only, blocked) — https://eclecticlight.co/2022/08/04/virtualisation-on-apple-silicon-macs-8-how-apple-limits-vms/
51. Red Hat Developer, libkrun GPU on macOS (2025-06-05; search snippet only) — https://developers.redhat.com/articles/2025/06/05/how-we-improved-ai-inference-macos-podman-containers
52. Autodesk KB, Windows on ARM installation issues (via Autodesk help API, undated) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html
53. Autodesk KB, System requirements index (lists AutoCAD 2027/2026; via Autodesk help API) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD.html
