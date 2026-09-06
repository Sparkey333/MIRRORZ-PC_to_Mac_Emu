# x86/x64-on-ARM Emulation Landscape: Prism, Rosetta 2, Box64, FEX-Emu, QEMU TCG, Hangover

_Research date: 2026-09-03_

Scope note: the session proxy allowed only github.com, raw.githubusercontent.com, developer.apple.com and the Microsoft Learn / Autodesk Help MCP backends; every version, date, license and support statement below comes from one of those. Claims seen only in search snippets are labelled **[snippet-only]** and need re-verification.

## TL;DR (5 bullets)

- **Rosetta 2 has a hard end date.** Apple's developer news states macOS 27 is the "final release to support Rosetta — Intel-only apps will no longer run on Mac computers with Apple silicon after this update," with only "older, unmaintained gaming titles" kept alive [1]. Apple's Rosetta doc confirms it translates all x86_64 including AVX/AVX2 but not AVX-512, and never translates "Virtual Machine apps that virtualize x86_64 computer platforms" [2].
- **On a macOS host, the only open-source, actively maintained x86-64 user-mode JIT that could be embedded is FEX (MIT) — and upstream explicitly does not target macOS** (Linux-only, 4 KB pages, SVE2 for AVX) [3][4][5]. Box64 (MIT) is Linux-only too [6]. Press reports say CodeWeavers shipped a custom FEX port for macOS in a CrossOver ARM64 Preview on 2026-07-31 **[snippet-only]**, which is the strongest signal that a macOS FEX port is feasible.
- **Inside a Windows 11 Arm guest, Prism is mature**: 24H2+ JIT-translates x86/x64 blocks, caches translations per module, runs x64 without WOW64 via Arm64X system binaries, and (24H2 and newer) exposes AVX/AVX2/BMI/FMA/F16C to 64-bit apps by default; kernel drivers are never emulated [7][8]. Microsoft's own support page says Parallels 18–20 are the authorized way to run Arm Windows 11 on M-series Macs, with DirectX 12 and nested-virtualization limitations [9].
- **Inside a Linux ARM64 guest, Hangover (LGPL-2.1) = Wine ARM64EC + FEX/Box64 is the state of the art**: Hangover 11.0 (2026-01-13) dropped QEMU entirely, and 11.16 (2026-08-30) bundles FEX-2608 and Box64 v0.4.4 [10][11][12]. Wine 10.0's ARM64EC mode runs "all of the Wine code as native, with only the application's x86-64 code requiring emulation" [13].
- **Autodesk still does not support ARM for AutoCAD/Revit/Inventor on Windows.** AutoCAD LT 2027's requirements say "ARM Processors are not supported" [14]; Revit 2026 requires an "Intel or AMD processor" but publishes a Parallels-on-Apple-silicon configuration [15]; Fusion says ARM64 Windows works "using XtaJIT64/Prism emulation" but "has not yet completed certification" [16]. No native ARM64 Windows build of AutoCAD, Revit or Inventor was found in any official source. A Microsoft Q&A answer (2026-04-03) claiming AutoCAD 2026 "explicitly lists ARM64" is a community post that conflicts with Autodesk's own KBs [17].

## Current status (version, date, maintainer, momentum)

| Engine | Latest verified version / date | Maintainer | Momentum (as of 2026-09-03) |
|---|---|---|---|
| Rosetta 2 (macOS) | Ships in macOS; macOS 26.4+ shows "update to native" nags; macOS 27 (fall 2026) is the last general-purpose release [1][2] | Apple | Winding down. Gaming subset continues; Apple forum staff would not commit on the Linux-VM variant's future [18]. |
| Prism (Windows 11 on Arm) | Introduced in Windows 11 24H2; AVX/AVX2/BMI/FMA/F16C listed for "24H2 and newer" [7][8]. Oct 14 2025 cumulative update KB5066835 = builds 26100/26200.6899 [19] (press credits this update with the broad AVX rollout **[snippet-only]**) | Microsoft | Actively improving; Microsoft claims "most x64 applications are expected to perform comparably to native apps under emulation" [20]. |
| FEX-Emu | FEX-2608, released 2026-08-05 (removed FEXInterpreter; Wine VirtualProtect fix; WFE spin-loops for Wine). FEX-2607 (Jul 2026) added 256-bit SVE2 AVX prep, Wine/Proton unixlib, partial CUDA thunks; FEX-2605 (May 2026) fixed ARM64EC crash and Snapdragon X2 Elite atomics [21][22] | Ryan Houdek et al., with Valve support | Monthly releases, ~15k commits; deeply integrated with Wine/Proton ARM64EC. |
| Box64 | v0.4.4, released 2026-08-02 (box64-configurator, DynaCache on by default up to 2 GB, DRM accuracy). v0.4.2 2026-04-20 (PPC64LE backend, Vulkan x64 overlay, SteamRT3/Proton 11). v0.4.0 2026-01-03 (prefix-decoder refactor, FSGSBASE) [23][24] | Sébastien "ptitSeb" Chevalier | Very active; three point releases in 2026 across ARM64, RISC-V, LoongArch. |
| QEMU (TCG) | Not version-checked this session; license verified from repo [25]. UTM wraps it on macOS with "JIT based acceleration using QEMU TCG" [26] | QEMU project / UTM | Stable but slow for x86-on-ARM; Hangover removed it in 11.0 because FEX/Box64 were better [11]. |
| Hangover | hangover-11.16, 2026-08-30 (FEX 2608, Box64 v0.4.4, llvm-mingw exit thunks, wine-mono); 11.0 on 2026-01-13 "Dropped Qemu," "down to 10 patches on top of Wine," "box64cpu.dll upstreamed as WowBox64.dll" [11][12] | André Hentschel (AndreRH) | Tracks Wine releases within weeks; packages for Debian 11–13, Ubuntu 20.04–25.10, Termux [10]. |
| Wine (ARM64EC) | 10.0 tagged 2025-01-21 with the x86-64 emulation interface [13][27]; 11.16 (Aug 2026) "Improved exception handling on ARM64EC" [28] | WineHQ | ARM64EC is now a mainstream Wine target. |

Related macOS-host projects: Whisky (Wine + CrossOver 22.1.1 + Game Porting Toolkit, GPL-3.0) was archived 2025-05-11 as "no longer actively maintained" [29]. Apple's Game Porting Toolkit 4 offers a Metal 4 evaluation environment for "unmodified Windows executable[s]" [30]. A `FEX_MacOs` GitHub fork is inactive [31]. `podman-fex` (Apache-2.0, preview April 2026) runs FEX inside a libkrun Linux VM on Apple silicon, reporting ~0.3 s warm overhead on an M1 Max and a 30.4x JIT-cache speedup; it rejected Rosetta integration as "not viable" [32].

## Pricing and licensing (table)

| Component | License / cost | Verified from | Implication for a commercial closed-source MIRRORZ |
|---|---|---|---|
| Rosetta 2 | Proprietary Apple system component; free with macOS | [1][2] | Cannot be bundled or extended; usable only where macOS provides it (macOS apps; Linux VMs via Virtualization.framework). Ends for general apps after macOS 27. |
| Prism | Proprietary; part of Windows 11 on Arm | [7] | Requires a licensed Windows 11 Arm guest; Microsoft notes "a separate license for Windows 11 Pro" per VM instance, keys are "platform agnostic (x64 vs Arm)" [9]. |
| FEX-Emu | MIT (Copyright 2019 Ryan Houdek) | [3][33] | Embeddable in proprietary code with attribution; no copyleft. |
| Box64 | MIT (Copyright 2020 ptitSeb) | [6][34] | Same as FEX. |
| QEMU | "as a whole ... GNU General Public License, version 2"; TCG "mostly under the BSD or MIT licenses; but some parts may be GPLv2"; linux-user/ and bsd-user/ accept GPLv2-only contributions | [25] | Shipping a modified QEMU obliges source disclosure for it; UTM's pattern (Apache-2.0 frontend, QEMU as separate GPL binaries) [26] is the accepted workaround. |
| Hangover | LGPL-2.1 | [35] | Dynamic-link only; must provide source for modified LGPL parts and allow relinking. |
| Wine | LGPL-2.1 (Hangover inherits) | [10][35] | Same as Hangover. |
| Parallels Desktop | Commercial; official price page not reachable this session | — | **[snippet-only]**: search results show $99.99/yr Standard, $119.99/yr Pro, $149.99/yr Business, $219.99 perpetual — unverified. |
| Windows 11 Pro (guest) | Commercial retail license | [9] | Per-VM cost that Prism-based designs must pass on or absorb. |

## How it works (architecture)

**Rosetta 2.** Apple's documentation: "If a macOS binary contains only Intel instructions, macOS automatically launches Rosetta and begins the translation process. When translation finishes, the system launches the translated executable in place of the original." It "can translate most Intel-based apps, including apps that contain just-in-time (JIT) compilers," "translates all x86_64 instructions, including ones from the AVX and AVX2 instruction set," but "doesn't support the execution of AVX512," and never translates kernel extensions or x86_64-virtualizing VM apps [2]. A separate Virtualization.framework feature shares Rosetta into Linux VMs; an Apple Frameworks Engineer stressed this is "not the same use case as the Rosetta Translation Environment which is about running x86_64 macOS binaries" [18]. Apple also notes "macOS 27 directly integrates support for Intel binary translation, without needing to install Rosetta" [2].

**Prism.** "Emulation works as a software simulator, just-in-time compiling blocks of x86 instructions into Arm64 instructions ... A service caches these translated blocks of code ... The caches are produced for each module so that other apps can make use of them on first launch." x86 apps go through WOW64; "for x64 apps, there's no WOW64 layer ... system binaries are compiled as Arm64X PE files." "Emulation only supports user mode code and doesn't support drivers" [7]. Arm64EC lets x64 and native code mix in one process: "Most operating system code loaded by an x64 app running on Windows 11 on Arm is compiled as Arm64EC" [36]. Per-app knobs can disable the translation cache or CHPE hybrid binaries, or force strict self-modifying-code and 80-bit x87 handling [8].

**FEX.** A Linux user-mode emulator for x86/x86-64 on ARMv8.0+ that needs an x86-64 root filesystem and can "forward API calls to host system libraries like OpenGL or Vulkan" (thunks) [3]. It builds as a Windows PE/ARM64EC DLL that Wine loads through `HKLM\Software\Microsoft\Wow64\amd64` [13], and FEX-2607 added a Proton/Wine "unixlib" split so not everything has to be a DLL [22]. AVX is implemented on 128-bit NEON with a 256-bit SVE2 fast path prepared for future hardware [22][5].

**Box64.** A "Linux userspace x86-64 emulator" that "requires 64-bit libraries on the host system, as it directly translates x86_64 function calls" to native libc/SDL/OpenGL; DynaRec is "5-10x faster than the interpreter alone," and DynaCache persists generated code [6][23]. Box32 handles 32-bit guests; a PE build ships in Wine as `WowBox64.dll` [11].

**QEMU TCG.** Whole-system or user-mode binary translation; on Apple silicon UTM offers "JIT based acceleration using QEMU TCG" for x86_64 guests, with Hypervisor.framework reserved for ARM64 guests [26].

**Hangover.** "Uses emulator DLLs to emulate only the application you want to run, rather than an entire Wine installation." 64-bit uses "the ARM64EC ABI combined with an emulator (FEX)"; 32-bit uses Wine's WoW64 and breaks "out of emulation at the win32 syscall or wine unix call level for performance reasons" [10].

## Feature checklist (table)

| Feature | Rosetta 2 | Prism | FEX | Box64 | QEMU TCG | Hangover |
|---|---|---|---|---|---|---|
| Runs directly on macOS host | Yes (macOS binaries only) [2] | No (needs Windows Arm guest) [7][9] | No upstream; CodeWeavers macOS port **[snippet-only]**; `podman-fex` runs it in a Linux VM [32] | No (Linux only) [6] | Yes via UTM [26] | No (Linux only) [10] |
| Runs Windows x64 apps | Only via Wine/CrossOver-style layers (Whisky, GPTK) [29][30] | Yes, natively integrated [7] | Yes, with Wine ARM64EC [13] | Yes, with Wine (WowBox64) [11] | Yes, full Windows x64 VM, slowly [26] | Yes [10] |
| 32-bit x86 apps | Yes | Yes via WOW64; AVX exposure off by default [7][8] | Yes [3] | Yes via Box32 [23] | Yes | Yes via WoW64 [10] |
| AVX/AVX2 | Yes; no AVX-512 [2] | Yes, 24H2 and newer [8] | Yes (128-bit path; SVE2 256-bit prepared) [22][5] | Not verified this session | Yes (software) | Inherits FEX/Box64 |
| Kernel drivers / kexts | Not translated [2] | Not emulated [7] | N/A (user-mode) | N/A | Full-system only | N/A |
| Translation cache | Yes (system-managed) | Per-module shared cache [7] | JIT code cache (30.4x warm-up gain reported) [32] | DynaCache, on by default [23] | In-memory | Inherits |
| GPU/graphics path | Native Metal; D3DMetal via GPTK [30] | Native DirectX in guest; VM DX12 limits on Mac [9] | Thunks to host GL/Vulkan [3] | Native GL/Vulkan wrapping [6] | virtio/virgl or software | DXVK needs Vulkan 1.3 [10] |
| Page-size tolerance | Apple 16 KB native | Windows 4 KB | Requires 4 KB kernel [4] | Not verified | Any | Inherits FEX |
| License | Proprietary | Proprietary | MIT [33] | MIT [34] | GPLv2 (TCG BSD/MIT) [25] | LGPL-2.1 [35] |
| Momentum 2026 | Sunset [1] | Growing [8][20] | Monthly releases [21] | 3 releases in 2026 [23] | Dropped by Hangover [11] | Tracks Wine [12] |

## CAD / AutoCAD relevance

- **Official Autodesk position (Windows on Arm).** The WoA KB states: "You are unable to install any Autodesk program on an ARM based processor for a Windows Operating System ... Unsupported hardware (the ARM processor) ... is not compatible with Autodesk products, which are based on 64-bit (x64) software. Use a different computer that is based on x64" [37]. A separate installation-error KB adds "ARM processors are not supported for a lot of desktop Autodesk products (for Windows environment)" [38]. AutoCAD LT 2027: "ARM Processors are not supported" [14]. AutoCAD 2025: "not supported on ARM x86 and x86 operating systems" [39]. The AutoCAD 2026 requirements page itself was not reachable; search snippets of it also read "ARM processors are not supported" **[snippet-only]**.
- **AutoCAD's technical footprint (what any emulator must cover).** AutoCAD 2027 requires 64-bit Windows 11, a "2.5-2.9 GHz processor with 8 logical cores," DirectX 11 minimum and "DirectX 12 with Feature Level 12_0 ... for 'Fast' visual styles," and .NET 10 [40]. DWG TrueView 2026 (same engine family) moved from .NET 8.0 to .NET 10.0 at 2026.1.2 [41]. So the target is an x64 native (ARX/C++) core plus a modern .NET runtime plus DirectX 11/12 — all of which run under Prism in an Arm Windows guest, but must be provided by Wine/DXVK plus an x64 .NET runtime under Hangover.
- **Revit 2026.** "Intel or AMD processor with 2 GHz or higher"; .NET 8 (.NET 10 for 2026.5+); DirectX 11 SM5. Autodesk nevertheless publishes a Parallels configuration for "Any Apple silicon chip" running "Microsoft Windows 11," and specifies "Parallels Desktop virtual display adapter without 'Use Hardware Acceleration' option in Revit"; the Accelerated Graphics Tech Preview is "Not recommended with Parallels Desktop" [15]. Support KBs confirm Desktop Connector "is not compatible with Windows ARM architecture" under Parallels [42].
- **Inventor 2026.** 64-bit Windows 11/10, .NET 8, DirectX 11 [43]; the Mac KB says "Apple processors were not tested on Bootcamp or Virtual Machines, Parallels with Inventor," and Inventor 2023 on Parallels 18/M1–M2 needed the ARM64 VC++ redistributable [44].
- **Fusion.** Windows: "ARM64 devices can run Fusion on Windows 11 using XtaJIT64/Prism emulation. This functionality has not yet completed certification by Autodesk Fusion." macOS: native Apple silicon but "some specific commands ... will prompt for installation of Rosetta 2" [16]; a KB fixes Fusion crashes "in Windows on ARM or Parallels" with `QSG_RHI_PREFER_SOFTWARE_RENDERER=1` [45].
- **Virtualization policy.** Every Autodesk requirements page carries: "You may virtualize a product only if the applicable terms and conditions ... expressly permit virtualization" [15][40] — a licensing risk, not just a support caveat.
- **Practical verdict per engine.** Prism (Windows Arm VM) is the only path with real-world AutoCAD/Revit usage and Autodesk-published VM settings, albeit "unsupported." Nothing verified shows AutoCAD's .NET 8/10 + DirectX 12 stack under Wine ARM64EC/Hangover. Rosetta 2 cannot run Windows binaries alone and is being retired; QEMU TCG is the slow fallback.

## Strengths (what to match)

- **Prism's shared per-module translation cache** [7], default-on AVX2 for 64-bit apps with per-app compatibility toggles [8], and Arm64EC letting system DLLs run native inside an x64 process [36].
- **Rosetta's completeness**: whole-ISA coverage including AVX2, JIT-app support and install-time translation [2].
- **FEX's thunking** of GL/Vulkan to host libraries and its Wine-first engineering (ARM64EC DLL, unixlib, WFE spin-loops, VirtualProtect correctness) [3][21][22].
- **Box64's native-library wrapping** and persistent DynaCache; multi-ISA backends prove the Dynarec is portable [6][23].
- **Hangover's "emulate only the app"** philosophy and its tiny patch delta (10 patches over Wine) [10][11].

## Weaknesses (what MIRRORZ must beat)

- **Host-OS gap.** No open-source engine targets macOS natively (FEX needs Linux and 4 KB pages [4]; Box64 is Linux-only [6]). The Windows-guest route needs a paid Windows license per VM and inherits VM DirectX 12 and nested-virtualization limits [9].
- **Rosetta cliff.** Anything built on Rosetta or GPTK-style Rosetta stacks loses its engine after macOS 27 [1][2]; Whisky is already archived [29].
- **AutoCAD is officially unsupported on every ARM path** [14][37][38]; MIRRORZ must own the compatibility and support burden.
- **Graphics.** Hangover's DXVK needs Vulkan 1.3 [10], which inside a macOS VM implies unvalidated MoltenVK/virtio layers; Revit's Parallels guidance disables hardware acceleration [15].
- **Performance evidence is thin.** Only Microsoft's "comparably to native" claim [20] and a container project's timings [32] were readable; third-party Prism, FEX-vs-Box64 and QEMU-TCG benchmarks were snippet-only.

## Reusable code, ideas, and license implications for MIRRORZ

1. **MIT engines are safe to embed.** FEX and Box64 can be statically or dynamically linked into a closed-source product with copyright notice retention [33][34]. A macOS port of FEX is the most credible technical bet (CodeWeavers reportedly did it **[snippet-only]**; `podman-fex` shows FEX-in-a-Linux-VM works today on M-series [32]). Key porting work: 16 KB page handling, Mach-O/dyld loader or Linux-VM confinement, and NEON-only AVX (already in FEX) [4][5].
2. **LGPL layers must stay separable.** Wine and Hangover are LGPL-2.1 [35]; keep them as dynamically linked, user-replaceable components and publish modifications.
3. **QEMU as a sidecar, not a library.** If a TCG fallback is wanted, follow UTM's pattern (Apache-2.0 UI, GPL QEMU binaries shipped with source) [25][26].
4. **Prism-derived product ideas** (not code): shared module-level translation cache, per-app "safe mode" profiles, and a hybrid ABI so MIRRORZ shims run native inside the x64 process [7][8][36].
5. **Rosetta as a bridge only.** It may serve a 2026 MVP, but the emulator interface must let FEX/Box64 replace it before macOS 28; Apple staff would not promise the Linux-VM variant survives [18].
6. **Autodesk relationship.** With virtualization restricted by Autodesk's terms and every ARM path "unsupported," a partnership or documented test matrix with Autodesk belongs in the go-to-market plan [15][37].

## Open questions

- Does Autodesk's AutoCAD 2026 requirements page contain the "ARM processors are not supported" sentence verbatim (page unreachable; only LT 2027 and the WoA KB were read)?
- Has anyone run AutoCAD 2026/2027 (.NET 8/10, DirectX 12) under Hangover/Wine ARM64EC? No evidence either way was found.
- What exactly did CodeWeavers change in FEX for macOS, and is it open-source? The blog and press pages were unreachable.
- Will Apple keep Rosetta-for-Linux-VMs after macOS 27? Apple's forum answer only distinguishes the use cases [18].
- Quantitative Prism vs native and FEX vs Box64 numbers from reputable, fetchable sources are still needed before making performance claims.
- Parallels pricing and Parallels 26's specific Arm/DirectX capabilities were not verifiable this session.

## Sources (numbered list of URLs with dates)

1. Apple Developer News, "Upcoming changes to Rosetta support for Intel-based macOS apps" — https://developer.apple.com/news/?id=w5ngl9k2 (fetched 2026-09-03; page states macOS 27 is the final release to support Rosetta)
2. Apple Developer Documentation, "About the Rosetta translation environment" (JSON data endpoint) — https://developer.apple.com/tutorials/data/documentation/apple-silicon/about-the-rosetta-translation-environment.json (fetched 2026-09-03)
3. FEX-Emu/FEX README — https://github.com/FEX-Emu/FEX (fetched 2026-09-03)
4. FEX discussion #3267, "FEX-Emu on macOS arm64 | avx(2)" — https://github.com/FEX-Emu/FEX/discussions/3267 (Nov 2023 – Jun 2024)
5. Same discussion, June 2024 maintainer note that 128-bit AVX "will work even on Apple M1" — https://github.com/FEX-Emu/FEX/discussions/3267
6. ptitSeb/box64 README — https://github.com/ptitSeb/box64 (fetched 2026-09-03)
7. Microsoft Learn, "How emulation works on Arm" — https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation (fetched 2026-09-03 via Microsoft Learn MCP)
8. Microsoft Learn, "Adjust emulation settings on Arm" — https://learn.microsoft.com/windows/arm/apps-on-arm-program-compat-troubleshooter (fetched 2026-09-03)
9. Microsoft Support, "Options for using Windows 11 with Mac computers with Apple M1, M2, and M3 chips" — https://support.microsoft.com/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c (fetched 2026-09-03)
10. AndreRH/hangover README — https://github.com/AndreRH/hangover (fetched 2026-09-03)
11. Hangover release hangover-11.0 — https://github.com/AndreRH/hangover/releases/tag/hangover-11.0 (2026-01-13)
12. Hangover releases list (hangover-11.16, 2026-08-30) — https://github.com/AndreRH/hangover/releases
13. Wine 10.0 ANNOUNCE (GitHub mirror) — https://github.com/wine-mirror/wine/blob/wine-10.0/ANNOUNCE.md
14. Autodesk, "System requirements for AutoCAD LT 2027" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-LT-2027.html (via Autodesk Help MCP, 2026-09-03)
15. Autodesk, "System requirements for Revit 2026 products" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Revit-2026-products.html (©2025; via Autodesk Help MCP)
16. Autodesk, "System requirements for Autodesk Fusion" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Fusion-360.html (via Autodesk Help MCP, 2026-09-03)
17. Microsoft Q&A, "Dose snapdragon ARM processor will be compatible with Autocad..." — https://learn.microsoft.com/en-us/answers/questions/5849358/ (community answers dated 2026-04-03 and 2026-04-09)
18. Apple Developer Forums thread 787530, "What will happen to Rosetta 2 in 2027/macOS 28" — https://developer.apple.com/forums/thread/787530 (June 2025)
19. Microsoft Support, "October 14, 2025—KB5066835 (OS Builds 26200.6899 and 26100.6899)" — https://support.microsoft.com/help/5066835 (fetched 2026-09-03)
20. Microsoft Learn, "Arm-based Surface devices FAQ" — https://learn.microsoft.com/surface/surface-arm-faq (fetched 2026-09-03)
21. FEX release FEX-2608 — https://github.com/FEX-Emu/FEX/releases/tag/FEX-2608 (2026-08-05)
22. FEX releases list (FEX-2607, FEX-2605) — https://github.com/FEX-Emu/FEX/releases
23. Box64 release v0.4.4 — https://github.com/ptitSeb/box64/releases/tag/v0.4.4 (2026-08-02)
24. Box64 releases list (v0.4.2 2026-04-20, v0.4.0 2026-01-03) — https://github.com/ptitSeb/box64/releases
25. QEMU LICENSE — https://raw.githubusercontent.com/qemu/qemu/master/LICENSE (fetched 2026-09-03)
26. utmapp/UTM README — https://github.com/utmapp/UTM (fetched 2026-09-03)
27. wine-mirror tag wine-10.0 — https://github.com/wine-mirror/wine/releases/tag/wine-10.0 (tag dated Jan 21; Wine 10.0 is the January 2025 annual release preceding Wine 11.0 of Jan 2026)
28. Wine 11.16 ANNOUNCE (AndreRH arm64ec branch) — https://github.com/AndreRH/wine/blob/arm64ec/ANNOUNCE.md (Aug 2026)
29. Whisky-App/Whisky — https://github.com/Whisky-App/Whisky (archived 2025-05-11)
30. Apple, Game Porting Toolkit — https://developer.apple.com/games/game-porting-toolkit/ (fetched 2026-09-03)
31. Jpkovas/FEX_MacOs — https://github.com/Jpkovas/FEX_MacOs
32. tnk4on/podman-fex — https://github.com/tnk4on/podman-fex (preview, April 2026)
33. FEX LICENSE (MIT) — https://raw.githubusercontent.com/FEX-Emu/FEX/main/LICENSE
34. Box64 LICENSE (MIT) — https://raw.githubusercontent.com/ptitSeb/box64/main/LICENSE
35. Hangover LICENSE (LGPL-2.1) — https://raw.githubusercontent.com/AndreRH/hangover/master/LICENSE
36. Microsoft Learn, "Arm64EC - Build and port apps for native performance on Arm" — https://learn.microsoft.com/en-us/windows/arm/arm64ec (fetched 2026-09-03)
37. Autodesk KB, "Installation issues for Autodesk products on Windows 64-bit running on ARM processors (WoA)" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html (undated in MCP output)
38. Autodesk KB, "Install error: The install couldn't finish. Error 10 ... Parallels on macOS" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html
39. Autodesk KB, "Is the Smart Block feature of AutoCAD 2025 available on ARM x86 or x86 operating systems?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-the-Smart-Block-feature-of-AutoCAD-2025-available-on-ARM-x86-or-x86-operating-systems.html
40. Autodesk, "System requirements for AutoCAD 2027 including Specialized Toolsets" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html (via Autodesk Help MCP)
41. Autodesk, "System requirements for Autodesk DWG TrueView 2026" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-DWG-TrueView-2026.html
42. Autodesk KB, "Is Desktop Connector working on Windows ... using Parallels with ARM64 processor?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
43. Autodesk, "System requirements for Autodesk Inventor 2026" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Inventor-2026.html (search summary; full page not fetched)
44. Autodesk KB, "Install options for Autodesk Inventor on a Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Can-I-install-Autodesk-Inventor-on-a-Mac.html
45. Autodesk KB, "Autodesk Fusion crashes on startup on Windows on ARM" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Fusion-crashes-on-startup-in-Windows-on-ARM.html

Snippet-only (not fetchable through this session's proxy; verify before citing): CodeWeavers blog "CrossOver Preview: The right to bear ARM64 on Mac" (2026-07-31) https://www.codeweavers.com/blog/mjohnson/2026/7/31/crossover-preview-the-right-to-bear-arm64-on-mac ; AppleInsider (2026-07-31) https://appleinsider.com/articles/26/07/31/first-apple-silicon-native-crossover-build-in-testing-as-rosettas-end-nears ; Phoronix "Hangover 11.0 Released" https://www.phoronix.com/news/Hangover-11.0-Released ; box86.org release posts https://box86.org/2026/08/new-box64-v0-4-4-release/ ; Neowin/Windows Latest on Prism AVX (Oct 2025); Linaro "QEMU: A Tale of Performance analysis" (Jan 2025) https://www.linaro.org/blog/qemu-a-tale-of-performance-analysis/ ; Parallels pricing https://www.parallels.com/products/desktop/buy/ .
