# VirtualBox on Apple Silicon, Boot Camp, Apple Game Porting Toolkit, and Rosetta 2 — status for MIRRORZ

_Research date: 2026-09-03_ (fetches completed 2026-09-03/04)

> Method note. The session's WebSearch budget was exhausted before this task started and several primary hosts (virtualbox.org, docs/blogs.oracle.com, support.apple.com, www.apple.com, codeweavers.com, parallels.com, wikipedia.org, web.archive.org) are blocked by the network egress proxy. Every fact below therefore comes from pages that *were* fetched: Apple developer docs (via the DocC JSON endpoints), Apple's and Oracle's GitHub repositories (raw files plus shallow git clones for dates), the Homebrew cask history, Microsoft Learn, and the Autodesk Product Help MCP. Where an official page could not be reached, this is stated explicitly rather than filled from memory.

## TL;DR

- **VirtualBox 7.2.16 (2026-08-18 cask bump) ships a native macOS/Arm64 build, but Apple-silicon hosts can only run Arm64 guests** — Oracle's 7.2 manual: "Running an x86-based guest operating system on an Arm host platform is not supported." Windows 11/Arm is a Premier-supported guest on macOS hosts only; graphics is VMSVGA-only. Zero x86-Windows relevance for AutoCAD on Apple silicon. [1][4][5]
- **Boot Camp is Intel-only and now on a hard clock.** Apple said at WWDC25 that "macOS Tahoe will be the final release for Intel Macs"; Microsoft's own guidance for Apple-silicon Macs lists only Windows 365 and Parallels (Arm Windows 11), not Boot Camp; Windows 10 (the Boot Camp era OS) left support on 2025-10-14 and AutoCAD 2027 requires Windows 11. Apple's Boot Camp KB itself could not be fetched. [6][7][11][26]
- **Game Porting Toolkit is now GPTK 4 (WWDC26, June 2026).** The public GitHub half (agent skills, metal-cpp, samples) is Apache-2.0; the "evaluation environment for Windows games" (the Wine+D3DMetal layer) is still a separate login-gated download from developer.apple.com, and Apple's own Homebrew tap refuses to fetch it for you. The license text governing D3DMetal redistribution could not be retrieved in this session — treat it as *not redistributable* until legal reads the actual agreement. [16][17][21]
- **Rosetta 2 ends as a general tool after macOS 27** (Apple Developer News, 2026-09-01: "macOS 27: Final release to support Rosetta"), with only a gaming-oriented subset kept afterwards. Counter-intuitively, Intel-binary translation *inside Linux VMs* is being promoted, not cut: "macOS 27 directly integrates support for Intel binary translation, without needing to install Rosetta … for Intel Linux binaries running in ARM virtual machines (VMs) as well as Intel Linux containers." [12][13][14]
- **Net for MIRRORZ:** none of these four Apple/Oracle pieces gives a supported path to run x86-64 Windows AutoCAD on Apple silicon. The only vendor-endorsed route is Arm Windows 11 in a VM with Microsoft's Prism x86/x64 emulation — and Autodesk says its Windows desktop products are x64-only and unsupported on Arm. That gap is MIRRORZ's opening and its biggest technical risk.

## Current status (version, date, maintainer, momentum)

| Item | Current state (2026-09) | Evidence |
|---|---|---|
| Oracle VirtualBox | 7.2.16 (build 174877); Homebrew cask bumped 2026-08-18 after 7.2.14 (2026-07-21) and 7.2.12 (2026-06-30). Separate `VirtualBox-7.2.16-174877-macOSArm64.dmg` and `-OSX.dmg` (Intel) installers. 7.1.0 (cask 2024-09-11, "supports arm64" 2024-09-12) was the first release "additionally for macOS/Arm"; 7.2.0 landed 2025-08-14. Maintainer: Oracle; source mirrored at github.com/VirtualBox/virtualbox (GPL-3.0, "Copyright (C) 2025 Oracle"). Cadence: roughly monthly maintenance releases through summer 2026. | [1][2][3] |
| Apple-silicon host status in the 7.2 manual | macOS/Apple Silicon hosts listed for macOS 13 Ventura through 26 Tahoe. macOS/Arm is **not** in the manual's "Experimental Features" list (which does contain "windows-arm-hosts-exp" and "macosxguests"), so Oracle no longer flags it as experimental; whether the 7.1.0 changelog used the word "beta" could not be verified (virtualbox.org blocked). | [4][5] |
| Boot Camp | Apple's KB unreachable in this session. Independent signals: WWDC25 "macOS Tahoe will be the final release for Intel Macs"; Autodesk's Inventor KB places "Bootcamp" under *Intel processors* and states "Apple processors were not tested on Bootcamp"; Microsoft's Apple-silicon guidance omits Boot Camp entirely. | [6][11][26] |
| Game Porting Toolkit | **GPTK 4**, announced WWDC26 (sessions 356 "Bringing Cyberpunk 2077 to Mac", 357 "Speedrun your game port with agentic coding"). Companion repo apple/game-porting-toolkit: "Initial commit" 2026-06-07, Apache-2.0, "We aren't accepting pull requests". Prerequisites: Apple-silicon Mac, macOS 27, Xcode 27, and the GPTK 4 download "provides latest versions of the evaluation environment for Windows games and Metal Shader Converter". | [16][17][18][19] |
| Rosetta 2 | Apple Developer News 2026-09-01: macOS 26.4+ shows notifications for Rosetta-dependent apps; "macOS 27: Final release to support Rosetta — Intel-only apps will no longer run on Mac computers with Apple silicon after this update." A subset survives "for older, unmaintained gaming titles". | [12][13] |
| Community wrappers | Whisky (GPL-3.0; CrossOver 22.1.1 + GPTK; Sonoma 14+, Apple silicon only) archived on GitHub 2025-05-11; last commit "Maintenance Notice" 2025-04-09; README: "Whisky is no longer actively maintained. Apps and games may break at any time." Gcenx's `game-porting-toolkit` cask is at 3.0-2, built from CrossOver Wine sources (latest tag crossover-wine-23.7.1, 2023-12-07). UTM v5.0.5 tagged 2026-09-01 (Apache-2.0; QEMU x86_64 emulation + Hypervisor.framework). | [22][23][25] |

## Pricing and licensing (table)

| Product | Price | License | Notes |
|---|---|---|---|
| VirtualBox platform package | Free | GPL-3.0 ("The VirtualBox Platform Package consists of all open source components and is licensed under the GNU General Public License") | Manual: Extension Pack is "an optional, separately licensed, installation package" adding VRDP, webcam passthrough, PXE ROM, AES disk encryption, cloud integration. The PUEL text and Oracle's enterprise price list could not be fetched (virtualbox.org / oracle.com blocked). [3][4] |
| Boot Camp | Free with macOS (Intel Macs) | Apple EULA | Requires a separately licensed Windows. Apple KB not fetchable. |
| Windows 11 Pro (needed for any VM route) | Not verified in this session | Microsoft: "A unique license is required for each instance of Windows 11 Pro, either on hardware or in a virtual machine. Windows 11 Pro product keys are platform agnostic (x64 vs Arm)." | [6] |
| Windows 10 ESU (if anyone insists on old Boot Camp installs) | Organisations: "$61 USD per device for Year One", doubling yearly, max three years; consumer program exists (page not fetched) | Microsoft | Windows 10 end of support 2025-10-14. [7][8] |
| Game Porting Toolkit 4 — GitHub repo (skills, metal-cpp, samples) | Free | Apache-2.0 (LICENSE file is unmodified Apache 2.0, "Copyright © 2026 Apple Inc.") | [17] |
| Game Porting Toolkit 4 — evaluation environment + Metal Shader Converter download | Free with Apple developer login | **Unknown** — gated behind developer.apple.com/download; license text not retrievable here | Apple's tap README: "Using the game-porting-toolkit formula requires downloading the Game Porting Toolkit from developer.apple.com". [21] |
| Rosetta 2 / Intel binary translation for Linux VMs | Free, part of macOS | Apple software license | From macOS 27 the Linux-VM translation is built in ("without needing to install Rosetta"). [14] |
| UTM | Free (open source) | Apache-2.0 with (L)GPL components | [25] |

## How it works (architecture)

**VirtualBox on Apple silicon.** VirtualBox is a type-2 hypervisor. On Arm64 hosts it virtualizes only Arm64 guests; there is no instruction-set translation layer. The 7.2 manual's Arm-host limitations are explicit: Arm guests only ("Arm 32 is not supported at present"), "Only VMSVGA is supported as a graphics controller", "Unattended installation isn't available", chipset/TPM and PAE/NX/nested-VT settings unavailable, and "Arm hosts have limitations with sound, storage, graphics, guest additions and unattended installation" with the troubleshooting page saying only "We're working on a resolution." Supported Arm guests: Windows 11 64-bit "Released versions only" (Premier support, macOS hosts only), Oracle/RHEL 8-10 (Premier), Debian 11/12, Ubuntu 18.04-24.10, SLES 12/15 (Limited). [4][5]

**Boot Camp.** Native dual-boot on Intel Macs (no hypervisor). It cannot exist on Apple silicon because there is no x86 CPU to boot, and Apple's Rosetta explicitly "doesn't translate … Virtual Machine apps that virtualize x86_64 computer platforms". Microsoft's Apple-silicon page describes the replacement model: Arm Windows 11 in Parallels (versions 18-20 "authorized") or a Windows 365 Cloud PC, with x64/x86 apps running under Windows' own emulator. [6][13]

**Windows-on-Arm x86 emulation (the piece any VM route depends on).** Microsoft Learn: "Windows 11 on Arm supports emulation of both x86 and x64 apps. Performance is enhanced with the introduction of the new emulator Prism in Windows 11 24H2." Prism is a JIT that translates blocks of x86 code to Arm64 with a per-module cache; "emulation only supports user mode code and doesn't support drivers." Microsoft also notes DirectX 12 limitations for Arm Windows on Macs and that nested virtualization (WSL, Sandbox, VBS) is unsupported there. [6][9]

**Game Porting Toolkit.** Two halves. (1) The *evaluation environment for Windows games*: an x86_64 Wine build from CrossOver sources (Apple's formula fetches `crossover-sources-22.1.1.tar.gz`, LGPL-2.1+, built `x86_64`-only so it runs under Rosetta) plus Apple's closed D3DMetal DirectX-to-Metal layer. WWDC23 described it as translating "your game's Intel instructions and its use of Windows APIs" and warned the observed baseline "includes all the overhead of the Game Porting Toolkit as well as API and instruction set translation." (2) Native porting tools: Metal Shader Converter (DXIL to metallib), Metal Developer Tools for Windows, Mac Remote Developer Tools for Windows, metal-cpp, and — new in GPTK 4 — agent skills for Claude Code/Codex/Gemini plus `gpucapture`/`gpudebug` CLIs that "ship with macOS 27 and later". [16][17][20][21]

**Rosetta 2.** User-space x86_64-to-Arm64 translation. Translates AVX/AVX2 but "doesn't support the execution of AVX512"; will not translate kernel extensions or x86_64 VM apps. In Linux VMs it is exposed via `VZLinuxRosettaDirectoryShare` over virtiofs, registered in the guest with `update-binfmts --install rosetta …`, with AOT-cache socket options from macOS 14 and a TSO kernel patch (`prctl(PR_SET_MEM_MODEL, PR_SET_MEM_MODEL_TSO)`, patch "applies cleanly to Linux 6.10") to speed it up. Apple: "The Virtualization framework doesn't support the bootstrapping or installation of Intel Linux distributions … Instead, it provides support for Intel apps that run in an ARM Linux distribution." Docker Desktop surfaces this as "Use Rosetta for x86_64/amd64 emulation on Apple Silicon", available only with the Apple Virtualization framework VMM, default off. [13][14][15][24]

## Feature checklist (table: feature | status | notes)

| Feature | Status | Notes |
|---|---|---|
| VirtualBox: native Apple-silicon host build | Yes (7.1+, current 7.2.16) | macOS 13-26 listed; not in experimental list. [1][4] |
| VirtualBox: x86/x64 Windows guest on Apple silicon | **No** | "x86-based guest operating systems will not run." [5] |
| VirtualBox: Windows 11 Arm guest on Apple silicon | Yes, Premier support | VMSVGA graphics only; no TPM setting; no unattended install. [4] |
| VirtualBox: 3D acceleration on Arm host | Limited | "limitations with … graphics"; only VMSVGA. [5] |
| Boot Camp on Apple silicon | **No** | Not in Microsoft's list of options; Autodesk: Boot Camp = Intel processors. [6][26] |
| Boot Camp on Intel Macs after macOS 26 | End-of-road | Tahoe is "the final release for Intel Macs". [11] |
| GPTK 4: run unmodified x86 Windows binary on Apple silicon | Yes, for evaluation | Wine (x86_64, under Rosetta) + D3DMetal. [20][21] |
| GPTK 4: DirectX 12 / modern GPU features | Yes (evaluation) | WWDC23: "GPU-driven pipelines and SIMD operations … tessellation and geometry shaders". [20] |
| GPTK 4: redistribution of D3DMetal | **Unverified; assume no** | License gated; Apple tap will not download it for you. [21] |
| GPTK 4: macOS requirement | macOS 27 for gpucapture/gpudebug; Gcenx cask needs Sonoma+ | [17][23] |
| Rosetta 2 for macOS apps | Available through macOS 27 only | Notifications from macOS 26.4. [12] |
| Rosetta/Intel translation in Linux VMs | Available macOS 13+; built-in from macOS 27 | "always returns installed" on 27. [14] |
| Rosetta AVX-512 | No | [13] |
| Rosetta for Windows VMs / x86 VM apps | No | "doesn't translate … Virtual Machine apps that virtualize x86_64". [13] |
| x86 Windows via QEMU/UTM | Possible, slow | UTM: "Full system emulation … using QEMU", 30+ CPUs incl. x86_64. No perf figures fetched. [25] |
| x86 Windows via Parallels/VMware on Apple silicon | Not verifiable here | Parallels/Broadcom hosts blocked; do not cite from memory. |

## CAD / AutoCAD relevance

- **Autodesk's Windows products are x64-only and Arm is unsupported.** KB: "AutoCAD 2025 is not supported on ARM x86 and x86 operating systems. And, AutoCAD products can only be supported on x64 operating systems." Install-error KB for Parallels: "ARM processors are not supported for a lot of desktop Autodesk products (for Windows environment)." Desktop Connector "does not work on macOS with Apple Silicon (ARM64 processor) chips when running Windows through Parallels." Fusion "crashes on startup in Windows on ARM or Parallels Virtual Machines" (software-renderer env var workaround). [26]
- **AutoCAD 2027 (Windows) requirements:** "64-bit Microsoft Windows 11", 16 GB RAM basic / 32 GB recommended, "DirectX 12 with Feature Level 12_0 is required for 'Fast' visual styles", recommended 8 GB DX12 GPU, .NET 10. Any MIRRORZ solution must therefore present a DX12-capable GPU to a Windows 11 x64 environment — exactly what Microsoft flags as limited for Arm Windows on Macs and what VirtualBox's VMSVGA cannot provide. [6][26]
- **AutoCAD 2027 for Mac** exists natively ("Apple M series CPU", macOS Sonoma 14 - Tahoe 26) but Autodesk's own KBs steer users to Windows/Boot Camp for missing features (Classic workspace, GEOMAP/Bing maps). That feature gap is MIRRORZ's demand driver. [26]
- **Support posture:** Autodesk "cannot offer technical support or troubleshooting for these configurations" (virtualization) and licensing terms must "expressly permit virtualization". MIRRORZ marketing must not imply Autodesk support. [26]
- **Boot Camp path is dead for new hardware** and even for Intel Macs the OS (Windows 10) is unsupported and AutoCAD 2027 needs Windows 11; the Apple KB confirming Boot Camp's Windows 11 stance could not be fetched.

## Strengths (what to match)

- **VirtualBox:** free, GPL, cross-platform VM format (OVF), monthly releases, Premier-supported Windows 11/Arm guest on macOS hosts, clean CLI (`VBoxManage`) and SDK. Its documentation is unusually explicit about limitations — MIRRORZ should match that candor.
- **Boot Camp:** native performance and driver access; the mental model "your Mac is also a PC" is what customers still ask for.
- **GPTK / D3DMetal:** proof that a DirectX 12 to Metal translation with usable performance exists on Apple silicon, and that Apple is willing to ship Wine-based tooling. GPTK 4 adds agentic porting skills, `gpucapture`/`gpudebug`, and a Cyberpunk 2077 case study — Apple is investing, not retreating.
- **Rosetta in Linux VMs:** Apple built a first-party, cached, TSO-accelerated x86_64 user-space translator and is baking it into macOS 27 for VMs/containers — a signal that per-process translation inside an Arm VM is the architecture Apple is comfortable supporting.

## Weaknesses (what MIRRORZ must beat)

- **No supported x86 Windows on Apple silicon from any of these:** VirtualBox refuses x86 guests on Arm; Boot Camp is Intel-only and sunsetting; Rosetta will not translate x86 VM apps and ends after macOS 27; GPTK's evaluation environment is explicitly "evaluation", x86_64-Wine-under-Rosetta, DirectX-focused and not a product.
- **Graphics:** VirtualBox Arm hosts are VMSVGA-only; Arm Windows on Macs has DirectX 12 caveats; AutoCAD wants DX12 FL 12_0.
- **Ecosystem fragility:** Whisky (the most popular GPTK wrapper) is archived; Gcenx's GPTK cask is pinned to 2023 CrossOver sources; Apple's tap formula is stuck at CrossOver 22.1.1.
- **Licensing opacity:** the GPTK download license and Oracle's Extension Pack PUEL/pricing were not retrievable; neither can be assumed commercial-friendly.
- **Rosetta deprecation risk:** anything MIRRORZ builds on Rosetta (including GPTK's x86_64 Wine) has a published expiry (macOS 27) unless it qualifies for the "older unmaintained gaming titles" subset — AutoCAD does not.

## Reusable code, ideas, and license implications for MIRRORZ

- **apple/game-porting-toolkit (Apache-2.0):** agent skills (D3D12-to-Metal 4 translation tables, synchronization, resource/descriptor mapping, MetalFX, shader-converter integration) and metal-cpp are directly reusable — both as engineering references for a D3D-to-Metal layer and, literally, as Claude Code/Codex plugins for MIRRORZ's own porting work. Apache-2.0 is commercial-friendly; keep NOTICE attribution.
- **D3DMetal itself:** closed, separately downloaded, license unread — do **not** bundle. If MIRRORZ wants a D3D12-on-Metal path it must license one (e.g., CodeWeavers' D3DMetal arrangement — site unreachable this session, verify separately) or build on open alternatives (DXVK/MoltenVK, both credited by Whisky).
- **Wine/CrossOver sources (LGPL-2.1+):** Apple's formula shows the exact recipe (crossover-sources 22.1.1, x86_64 build, mingw cross-compilation). LGPL permits commercial use with source-availability obligations for modified LGPL parts; a MIRRORZ Wine fork must publish its Wine changes.
- **Whisky (GPL-3.0, archived):** good SwiftUI reference for bottle management, Rosetta install (`softwareupdate --install-rosetta --agree-to-license`), and an updater that pulls `Libraries.tar.gz` from its own CDN. GPL-3.0 is viral — read, do not copy into a proprietary app.
- **VirtualBox (GPL-3.0):** the Arm-host limitations list is a ready-made checklist of what a hypervisor on Apple silicon must solve (graphics controller, guest additions, sound/storage, unattended install). Code reuse is GPL-constrained; the OVF import/export idea is free to copy.
- **Rosetta-in-Linux-VM pattern (Apple API):** `VZLinuxRosettaDirectoryShare` + binfmt + TSO prctl is an Apple-sanctioned per-process x86 translation design. MIRRORZ cannot use it for Windows guests, but the *shape* — Arm guest OS, native drivers, translate only the app's user-mode x86 code — is the same shape as Windows 11/Arm + Prism, which is the only vendor-endorsed route today.
- **UTM (Apache-2.0, QEMU inside):** viable fallback for full-system x86 emulation; QEMU's GPL/LGPL terms apply to the emulator core.

## Open questions

1. Exact wording of the GPTK 4 download license (evaluation-only clause, redistribution ban, any commercial carve-out) — must be read from the DMG by someone with an Apple developer login.
2. Does the GPTK 4 evaluation environment still require Rosetta (x86_64 Wine), and what happens to it after macOS 27 given Apple's Rosetta timeline?
3. Did Oracle ever label macOS/Arm "beta" in the 7.1.0 changelog, and has 7.2.x changed the Arm-host limitations (needs virtualbox.org/Changelog-7.2)?
4. Oracle Extension Pack PUEL terms and enterprise pricing on Apple-silicon hosts.
5. Apple's official Boot Camp KB text (Intel-only statement; Windows 10 vs 11 support) — support.apple.com unreachable.
6. Parallels' x86 emulation technology preview status and VMware Fusion's Apple-silicon guest matrix — vendor hosts unreachable; not stated here from memory.
7. Real-world Prism performance for AutoCAD-class x64 apps under Arm Windows on Apple silicon, and whether Microsoft's "DirectX 12" caveat blocks AutoCAD's "Fast" visual styles.

## Sources (numbered list of URLs with dates)

1. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/v/virtualbox.rb — cask 7.2.16,174877 with macOSArm64 and OSX dmg URLs (fetched 2026-09-03).
2. https://github.com/Homebrew/homebrew-cask — git history of Casks/v/virtualbox.rb: "virtualbox 7.1.0" 2024-09-11; "virtualbox: supports arm64" 2024-09-12; "virtualbox 7.2.0" 2025-08-14; 7.2.12 2026-06-30; 7.2.14 2026-07-21; 7.2.16 2026-08-18 (cloned 2026-09-04).
3. https://github.com/VirtualBox/virtualbox and https://raw.githubusercontent.com/VirtualBox/virtualbox/main/README.md — "for x86_64 hardware (with version 7.1 additionally for macOS/Arm)"; GPL-3.0 (fetched 2026-09-03).
4. https://github.com/VirtualBox/virtualbox/tree/main/doc/manual/en_US/dita/topics — Oracle VirtualBox 7.2 User Guide sources: host-guest-matrix.dita, arm-host-limitations.dita, guest-os-Arm.dita, installation-packages.dita, ExperimentalFeatures.dita, vbox-components.dita (docs commits 2025-08-04; read 2026-09-04).
5. Same repository, ts_macos-limitations.dita — "x86-based guest operating systems will not run. Arm(AArch64) guests only." (docs commit 2024-12-19; read 2026-09-04).
6. https://support.microsoft.com/en-us/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c — Windows 365 and Parallels 18/19/20 as the options; DirectX 12 and nested-virtualization limits (fetched via Microsoft Learn tool 2026-09-03; page undated).
7. https://learn.microsoft.com/en-us/lifecycle/products/windows-10-home-and-pro — end of support 2025-10-14 (fetched 2026-09-03).
8. https://learn.microsoft.com/en-us/windows/whats-new/extended-security-updates — ESU $61/device Year One (fetched 2026-09-03).
9. https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation — Prism emulator, Windows 11 24H2 (fetched 2026-09-03).
10. https://learn.microsoft.com/windows/arm/iso — Windows 11 Arm64 ISOs; "Arm64 VMs can be created using Mac computers built with Arm-based Apple Silicon" (fetched 2026-09-03).
11. https://developer.apple.com/videos/play/wwdc2025/102/ — WWDC25 Platforms State of the Union transcript: "macOS Tahoe will be the final release for Intel Macs" (June 2025; fetched 2026-09-03).
12. https://developer.apple.com/news/ — "Upcoming changes to Rosetta support for Intel-based macOS apps", 2026-09-01 (fetched 2026-09-03).
13. https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment — Rosetta through macOS 27; macOS 27 built-in Intel translation for Linux VMs/containers; no AVX-512; no x86_64 VM apps (DocC JSON fetched 2026-09-03).
14. https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms — macOS 13+, VZLinuxRosettaDirectoryShare, binfmt, macOS 14 caching, macOS 27 behavior (DocC JSON fetched 2026-09-03).
15. https://developer.apple.com/documentation/virtualization/accelerating-the-performance-of-rosetta — TSO prctl, Linux 6.10 patch (DocC JSON fetched 2026-09-03).
16. https://developer.apple.com/games/game-porting-toolkit/ — "Game Porting Toolkit 4"; evaluation environment, Metal shader converter, Windows tools (fetched 2026-09-03; footer © 2026).
17. https://github.com/apple/game-porting-toolkit — Apache-2.0; README prerequisites macOS 27 / Xcode 27 / GPTK 4; "Initial commit" 2026-06-07 (cloned 2026-09-04).
18. https://developer.apple.com/videos/play/wwdc2026/357/ — "Speedrun your game port with agentic coding": gpucapture/gpudebug need macOS 27; plugin install commands (fetched 2026-09-03).
19. https://developer.apple.com/videos/wwdc2026/ — WWDC26 session list incl. 356 "Bringing Cyberpunk 2077 to Mac" and 224 "Expand the capabilities of your Virtualization app" (fetched 2026-09-03).
20. https://developer.apple.com/videos/play/wwdc2023/10123/ — WWDC23 "Bring your game to Mac, Part 1": evaluation environment translates Intel instructions and Windows APIs; overhead caveat (fetched 2026-09-03).
21. https://github.com/apple/homebrew-apple — README: formula "requires downloading the Game Porting Toolkit from developer.apple.com"; Formula/game-porting-toolkit.rb v1.1, crossover-sources-22.1.1, LGPL-2.1+, x86_64 (fetched 2026-09-03).
22. https://github.com/Whisky-App/Whisky — archived 2025-05-11; README maintenance notice; Sonoma 14+/Apple silicon; GPL-3.0; source downloads https://data.getwhisky.app/Wine/Libraries.tar.gz (fetched/cloned 2026-09-03/04).
23. https://github.com/Gcenx/homebrew-wine (Casks/game-porting-toolkit.rb v3.0-2, depends_on macos :sonoma) and https://github.com/Gcenx/game-porting-toolkit (tag crossover-wine-23.7.1, 2023-12-07) (fetched 2026-09-03/04).
24. https://raw.githubusercontent.com/docker/docs/main/content/manuals/desktop/settings-and-maintenance/settings.md — "Use Rosetta for x86_64/amd64 emulation on Apple Silicon" requires Apple Virtualization framework VMM (fetched 2026-09-03).
25. https://github.com/utmapp/UTM — README (QEMU, x86_64 emulation, Hypervisor.framework, Apache-2.0); tag v5.0.5 dated 2026-09-01 (fetched/cloned 2026-09-03/04).
26. Autodesk Product Help (retrieved via Autodesk MCP 2026-09-03): "System requirements for AutoCAD 2027 including Specialized Toolsets" (https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html); "Is the Smart Block feature of AutoCAD 2025 available on ARM x86 or x86 operating systems?"; "Is Desktop Connector working on Windows running on iOS using Parallels with ARM64 processor?"; "Install options for Autodesk Inventor on a Mac"; "3ds Max support with Apple macOS"; "Are 3ds Max or Maya supported within a virtual environment?"; "Install error 10 … Parallels on macOS"; "Selection in AutoCAD products lags … Parallels"; "Autodesk Fusion crashes on startup on Windows on ARM"; AutoCAD for Mac 2027 "Apple Silicon Support" (https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-EA31738F-CDDE-4170-970A-745BC19C7674).
27. https://learn.microsoft.com/answers/a/12255214 — Microsoft Q&A community answer describing VirtualBox Apple-silicon support as "very limited"/"experimental" (community content, undated; fetched 2026-09-03).
