# New Entrants and Platform Shifts in Windows-on-Mac, 2025-2026
_Research date: 2026-09-03_

_Method note: the session's web-search quota was already exhausted and the egress proxy blocks parallels.com, codeweavers.com, winehq.org, apple.com/newsroom, broadcom.com/vmware.com and reddit/news sites. Every fact below therefore comes from pages that were actually fetched on 2026-09-04: Apple developer documentation (JSON endpoints and RSS), GitHub repositories/topic pages, Homebrew cask definitions, Microsoft Learn (via the Microsoft Learn tool) and Autodesk help (via the Autodesk Product Help tool). Where a vendor page could not be reached, the item is marked **not verifiable in this session** instead of being stated from memory. GitHub shows release dates without a year; where a year is inferred it is noted with the evidence used._

## TL;DR (5 bullets)
- **Apple has put a clock on x86-on-Mac.** Apple's Rosetta page says Rosetta "will be available through macOS 27" as a general-purpose tool, after which only "a subset of Rosetta functionality aimed at supporting older unmaintained gaming titles" remains; the macOS 27 beta-8 notes (Aug 31, 2026) state "All Intel-based software will no longer be compatible with macOS 28." Every Wine-based Mac product found (CrossOver-derived builds, Gcenx's WineHQ builds, Sikarugir, Highball, Lithium, soju, WineForge) still ships x86_64 Wine that runs under Rosetta 2. None of the incumbents has shipped an ARM64-native Wine path on macOS even though Wine 10.0 (2025) made ARM64EC "fully supported" and Wine 11.0 (Jan 2026) added ARM64 4K-page emulation on 16K hosts.
- **The Whisky vacuum was filled by a swarm of small, mostly gaming-only open-source projects in 2025-2026** (Highball 190 stars GPL-3.0 + CC0 database; Mythic 1.4k stars; MetalSharp "Windows games and Windows applications" under a non-commercial license; Silo; Cellar with an AI agent that configures Wine; soju; Playdock; Lithium). Whisky itself is unmaintained (Homebrew deprecated it 2025-04-09) and Kegworks was renamed Sikarugir. None targets professional apps, and D3DMetal (Apple GPTK) is non-redistributable, so they cannot become commercial products without re-plumbing graphics.
- **The VM incumbents moved on without Intel Macs and without CAD.** Homebrew's cask for Parallels Desktop is at 27.0.1 and is arm64-only with macOS 14+ required; Microsoft's own Windows-on-Mac page still lists only Parallels 18/19/20 as "authorized," warns about DirectX 12 and nested-virtualization limits, and requires a separate Windows 11 Pro license. UTM 4.7.5 (stable) and 5.0.5 (prerelease, "DirectX graphics support for Windows ... experimental") are free; VirtualBox 7.2.16 ships arm64 builds; VMware Fusion has no Homebrew cask anymore and its status could not be verified.
- **Autodesk shipped AutoCAD 2027 on March 25, 2026 with Windows 11-only, .NET 10, DirectX 12 feature-level 12_0 for "Fast" visual styles; AutoCAD 2027 for Mac is native on Apple silicon, Metal-only (OpenGL removed) and gains the Autodesk Assistant AI.** Autodesk's knowledge base still says ARM Windows hardware is "not compatible with Autodesk products," Desktop Connector does not work in Windows-on-ARM under Parallels, and support is only provided if a bug reproduces on physical hardware. Cloud-streamed Windows 365 is Microsoft's preferred answer and now has a macOS Windows App (macOS 14+).
- **What nobody is doing:** an ARM64-native Wine runtime for macOS (Rosetta-proof), an open D3D11/D3D12-to-Metal stack that is commercially redistributable (DXMT is LGPL and covers D3D10/11 only; D3DMetal is Apple-private), and any product tuned and supported for professional CAD workflows (licensing/sign-in, Desktop Connector, plotting, plug-ins). That is MIRRORZ's opening.

## Current status (version, date, maintainer, momentum)

| Product / project | Current state (verified 2026-09-04) | Maintainer, momentum |
|---|---|---|
| Parallels Desktop | Homebrew cask `parallels` = **27.0.1-58670**, `depends_on macos: :sonoma`, `depends_on arch: :arm64`; legacy casks `parallels@14`...`@20` exist. Release date, price and feature list not verifiable (parallels.com blocked). | Parallels GitHub org is active: `pd-ai-agent-core` (Python, updated Aug 31, 2026), `capsule-*` repos (2025-2026), `prl-devops-service` 1.0.5 (2026-07-22, "Fair Source" license, free for up to 10 users with a Business license). |
| CrossOver (CodeWeavers) | Homebrew cask `crossover` = **26.3.0**. The soju project states it builds from "CodeWeavers' published GPL sources (Wine 11.0, CrossOver 26.3 source drop)". Price and release date not verifiable (codeweavers.com blocked). | CodeWeavers funds DXMT (its LICENSE reads "Copyright (c) 2023-2026 Feifan He for CodeWeavers"). |
| UTM | **4.7.5** stable (GitHub date "03 Jan"; 2026 inferred because notes cite QEMU 10.0.2 and "Liquid Glass design on *OS 26"); **5.0.5** prerelease ("02 Sep", 2026 by page ordering) adds "DirectX graphics support for Windows ... experimental". Requires macOS 11+. | Open-source, single-maintainer style project, actively shipping. |
| VirtualBox | Cask **7.2.16** (build 174877) with separate `macOSArm64` and Intel installers. | Oracle. |
| VMware Fusion | **Not verifiable.** No `vmware-fusion*` cask exists in Homebrew `Casks/v` (only `vagrant-vmware-utility`); Broadcom pages blocked. | Broadcom. |
| Wine (upstream) | **Wine 11.0** tagged "13 Jan" (2026; notes reference Linux 6.14 NTSync, Vulkan 1.4.335). Wine 10.0 (2025) made ARM64EC fully supported. | WineHQ; Gcenx publishes macOS builds up to **11.16** ("24 Aug", 2026), x86_64/i386 only. |
| Whisky | README: "Whisky is no longer actively maintained. Apps and games may break at any time." Homebrew `deprecate! date: "2025-04-09", because: :unmaintained`; last release v2.3.5 ("05 Apr", 2025). 15.1k stars. | Dead. |
| Kegworks -> Sikarugir | Renamed; "successor to Wineskin"; macOS 14+; Apple silicon "require[s] Rosetta2"; tap cask `sikarugir` v1.0.1. README: "This project is not a replacement for CrossOver or Whisky." | Gcenx/VitorMM; alive but positioned as a wrapper builder. |
| Mythic | v0.6.0 ("27 Dec", 2025), GPL-3.0, 1.4k stars, "custom implementation of Apple's Game Porting Toolkit", macOS 14+. | Active. |
| Highball | GPL-3.0 app + CC0 compatibility database, 190 stars, Swift, macOS 14+, "no paid tier and never will"; assembles Wine from Gcenx builds with DXMT/DXVK/D3DMetal. | New (2026 activity). |
| MetalSharp | v0.61.0 (README "Updated: 2026-07-28"), PolyForm Noncommercial, "Run Windows games and Windows applications", custom Wine 11.5 + custom DXMT, macOS 15+, 60 stars. | New. |
| Silo | LGPL-2.1+, SwiftUI, "Apple GPTK4/D3DMetal + DXMT", macOS 15+, 32 stars. | New. |
| Cellar | MIT (2026), AI agent (Anthropic/DeepSeek/Kimi key) auto-configures Wine for old games, Apple silicon and Intel. | New. |
| soju, WineForge, Lithium, Playdock | soju: GPL-3.0 launcher stack from CrossOver 26.3 sources, verified on macOS 26.5/M4 Pro (status 2026-08). WineForge: Wine 11.16 tree focused on D3DMetal/Rosetta. Lithium: Wine x86_64 under Rosetta 2 + DXVK + MoltenVK, no GPTK. Playdock: "built on the Sikarugir engine". | New, small. |
| Apple `container` / Containerization | Linux containers as lightweight VMs; "supported on macOS 26"; Apple silicon only; release 1.3.1 ("29 Aug", 2026, fixes CVE-2026 IDs). | Apple, active. |
| Apple Game Porting Toolkit 4 | developer.apple.com: "Download Game Porting Toolkit 4"; evaluation environment "now supports Metal 4"; companion repo `apple/game-porting-toolkit` (Apache-2.0, updated Jun 8, 2026) ships agent skills and requires macOS 27 / Xcode 27. | Apple. |

## Pricing and licensing (table)

| Product | Price (verified?) | License / terms |
|---|---|---|
| Parallels Desktop 27 | **Not verifiable** (vendor site blocked). | Proprietary. Microsoft: "You need to have a separate license for Windows 11 Pro"; product keys "are platform agnostic (x64 vs Arm)". |
| CrossOver 26.3 | **Not verifiable.** | Proprietary app over LGPL/GPL Wine; source drops published (used by soju). |
| UTM 4.7.5 / 5.0.5 | Free download from GitHub releases (cask URL). | Open source on GitHub (license file not fetched). |
| VirtualBox 7.2.16 | Free download from download.virtualbox.org (cask URL). | Oracle (license not fetched). |
| Windows 365 Cloud PC | "offered on a per-user, per-month basis"; amounts not fetched. | Business (up to 300 users), Enterprise, Government, Flex, Reserve; "Windows 365 for Agents (preview)". |
| Whisky | Free. | GPL-3.0; unmaintained. |
| Sikarugir | Free. | Mixed: `Configure.app` LGPL-2.1; launcher and Creator.app "don't fall under LGPL-2.1"; D3DMetal v3.0 "can not be used for commerial ports". |
| Highball | Free, "no paid tier and never will". | GPL-3.0 app; CC0 database. |
| MetalSharp | Free for non-commercial use. | PolyForm Noncommercial 1.0.0. |
| Mythic | Free. | GPL-3.0. |
| Silo | Free. | LGPL-2.1+. |
| Cellar | Free, but "You need an API key to use the AI agent." | MIT. |
| DXMT | Free. | LGPL-2.1 or later ("for CodeWeavers"). |
| Apple D3DMetal / GPTK 4 | Free download with Apple ID. | Non-redistributable; soju: "Not included and never will be: Apple D3DMetal/GPTK binaries (non-redistributable)". |
| AutoCAD 2027 / AutoCAD for Mac 2027 | Subscription; amounts not fetched. | Autodesk virtualization note: "You may virtualize a product only if the applicable terms and conditions ... expressly permit virtualization." |

## How it works (architecture)

**Wine-based entrants (2025-2026).** All of them are x86_64 Wine builds executed under Rosetta 2 on Apple silicon. Gcenx's builds are configured `--build=x86_64-apple-darwin --enable-archs=i386,x86_64`; Sikarugir's cask carries `requires_rosetta`; Lithium describes "Wine (built x86_64, runs under Rosetta 2)"; soju sets `ROSETTA_ADVERTISE_AVX=1` because "D2R's loader requires AVX instructions" and notes that a Rosetta 2 bug "Apple fixed in 26.4" broke Blizzard's anti-cheat on macOS 15. Graphics is a menu of translation layers: WineD3D (DX8 and below), D9VK/DXVK (D3D9-11 via Vulkan/MoltenVK), DXMT (D3D10/11 to Metal, LGPL, CodeWeavers-sponsored), D3DMetal (Apple GPTK, D3D11/12, non-commercial) and vkd3d for D3D12. Sikarugir makes DXMT the default and D3DMetal a toggle; Highball assembles "pinned, SHA-256-verified upstream builds" and chooses a renderer per game from its CC0 database; Silo runs a real Windows Steam client in a shared bottle; Cellar wraps the whole thing in an LLM agent that "researches your game, diagnoses issues, and fixes compatibility problems automatically."

**VM route.** Parallels 27 (arm64-only) and UTM run Arm64 Windows 11 under Apple's Virtualization/Hypervisor frameworks; x64 apps inside run through Microsoft's Prism emulator (Windows 11 24H2+), which "supports emulation of both x86 and x64 apps," now exposes AVX/AVX2/BMI/FMA/F16C, and offers per-app "Change emulation settings". Prism "only supports user mode code and doesn't support drivers"; kernel drivers must be Arm64. Microsoft's Mac page lists nested-virtualization features (WSL, WSA, Sandbox, VBS) as unsupported and says Arm Windows "has limitations ... including those that rely on DirectX 12". UTM 5.0.5 adds an experimental DirectX-to-Metal (D3DMetal-based) guest driver for Windows on macOS. Apple's `container` project shows the platform direction: each Linux container is its own lightweight VM, using "Rosetta 2 for running linux/amd64 containers on Apple silicon"; macOS 27 "directly integrates support for Intel binary translation, without needing to install Rosetta" for "Intel Linux binaries running in ARM virtual machines (VMs) as well as Intel Linux containers." Note Rosetta explicitly "doesn't translate ... Virtual Machine apps that virtualize x86_64 computer platforms," so x86 Windows VMs on Apple silicon remain pure emulation (UTM/QEMU).

**Apple platform changes.** macOS 26 Tahoe added ASIF sparse disk images "suitable for ... virtual machines storage via the Virtualization framework," Metal 4, and a boot-arg that makes any Rosetta process crash so developers can test Rosetta-free. macOS 27 (beta since Jun 8, 2026; beta 8 on Aug 31, 2026) adds DiskImageKit (Swift APIs for ASIF images for the Virtualization framework), vmnet loopback port forwarding, a Settings list of "Intel-based apps that will be incompatible with macOS 28," does not restore Rosetta after upgrade, launches apps natively even if a user chose "Open using Rosetta," and ships a beta-only command-line switch for "legacy Intel-based games" that "disables Rosetta". GPTK 4 (WWDC 2026 timeframe) pairs a Metal 4 evaluation environment with open-source "agent skills" for Claude Code, Codex and Gemini CLI.

**Windows on Arm.** Windows 11 Arm64 ISOs are official; 32-bit Arm (AArch32) apps are deprecated and "Support for 32-bit Arm versions of applications is removed in a future release of Windows 11"; the 32-bit edition of Microsoft 365 Apps on Arm stopped feature updates in October 2025 and loses security updates in December 2026; Arm64EC/Arm64X let vendors mix native and emulated code.

## Feature checklist (table: feature | status | notes)

| Feature | Status across the field | Notes |
|---|---|---|
| ARM64-native Wine on macOS (no Rosetta) | **Nobody ships it** | Wine 10.0: "The ARM64EC architecture is fully supported"; Wine 11.0: ARM64 4K-page simulation on 16K hosts; all Mac builds remain x86_64. |
| D3D12 without Apple's D3DMetal | Partial | vkd3d/MoltenVK path exists (soju: "Graphics itself can run on pure open-source vkd3d/MoltenVK if D3DMetal is absent"); DXMT "does not provide D3D12 support." |
| D3D10/11 to Metal, redistributable | Yes | DXMT, LGPL-2.1+. |
| Commercial redistribution of D3DMetal | No | Sikarugir: D3DMetal v3.0 license "can not be used for commerial ports." |
| Windows 11 Arm VM on Apple silicon | Yes (Parallels, UTM, VirtualBox arm64) | Microsoft authorizes Parallels 18/19/20 by name only; nested virtualization, WSL/WSA, DirectX 12 limits. |
| x86 Windows VM on Apple silicon | Emulation only | Rosetta does not translate x86 VM apps; UTM/QEMU emulation. |
| Intel Mac support | Shrinking | Parallels 27 cask arm64-only; AutoCAD 2027 for Mac still lists "64-bit Intel CPU"; macOS 28 drops Intel software. |
| AI-assisted configuration | Emerging | Cellar (agent configures Wine); Parallels `pd-ai-agent-core`; Apple GPTK agent skills; AutoCAD 2027 "Autodesk Assistant". |
| Open compatibility database | Yes (games) | Highball's CC0 `highball-db`; nothing equivalent for professional apps. |
| Professional CAD support/certification | **None** | Autodesk: ARM Windows "not compatible"; Desktop Connector fails in Parallels ARM; support requires physical-hardware repro. |
| Cloud Windows for Mac | Yes | Windows 365 via Windows App (macOS 14+ for W365); W365 "supports nested virtualization". |

## CAD / AutoCAD relevance

- **AutoCAD 2027 (Windows), release notes dated March 25, 2026:** OS "64-bit Microsoft Windows 11" only (AutoCAD 2025 still allowed Windows 10 1809+); ".NET 10"; basic 16 GB RAM; "DirectX 12 with Feature Level 12_0 is required for 'Fast' visual styles"; basic GPU "DirectX 11 compliant". The 2027 page no longer prints the sentence "ARM Processors are not supported" that appears on the AutoCAD 2025 and AutoCAD LT 2027 pages; treat this as an unexplained wording change, not as ARM support, because Autodesk's KB still says Windows-on-ARM hardware "is not compatible with Autodesk products."
- **AutoCAD 2027 for Mac:** macOS 14/15/26, "64-bit Intel CPU / Apple M series CPU", "Beginning with AutoCAD for Mac 2027, OpenGL is no longer supported. Metal is now the sole graphics engine," plus Autodesk Assistant, Smart Blocks and Geometry Cleanup. Autodesk's own comparison says Mac products "are not straight 1:1 ports" and lack e.g. QuickCalc, block-table lookup and the Classic toolbar UI, which is why Windows AutoCAD on a Mac still matters (Specialized Toolsets are "Windows Only").
- **Virtualization posture:** "Autodesk provides technical support to make sure that your software works properly, but doesn't provide technical support for your virtual environment"; Parallels-specific KBs cover selection lag ("Change Hypervisor from Apple to Parallels"), installer "Error 10" (needs Rosetta 2 and x64/x86/ARM64 VC++ redistributables) and Desktop Connector not working on Windows ARM.
- **Implication for MIRRORZ:** the flagship target needs D3D11 at minimum and D3D12 FL12_0 for the fast visual styles, .NET 10 on Windows, and Autodesk's sign-in/licensing stack; none of the 2025-2026 entrants tests any of this, and the VM incumbents hand support problems back to Autodesk, who hands them back to the hypervisor vendor.

## Strengths (what to match)

- **Highball:** verifiable, reproducible engines ("pinned, SHA-256-verified upstream builds") and a CC0 evidence database with "provenance on every claim" - copy this rigor for CAD workflows.
- **Silo / MetalSharp:** automatic per-title renderer selection between D3DMetal and DXMT, bundled custom Wine, self-updating from GitHub releases, and (MetalSharp) explicit "Windows applications" scope.
- **Cellar:** LLM-driven diagnosis of Wine failures is a genuinely new UX; MIRRORZ can do the same with a curated CAD recipe set.
- **Parallels:** the only route with a Microsoft-authorized Windows license story, Business-tier devops tooling, and an AI agent library in the open.
- **UTM:** free, open, Apple-Virtualization-native, and now experimenting with a DirectX guest driver.
- **Apple `container`/DiskImageKit/ASIF:** the sanctioned, fast VM plumbing on macOS 26/27; MIRRORZ should use ASIF images and the Virtualization framework if it ever needs a VM fallback.

## Weaknesses (what MIRRORZ must beat)

- **Rosetta dependence is the shared Achilles heel.** Every Wine-on-Mac product is x86_64 under Rosetta 2, and Apple says general-purpose Rosetta ends after macOS 27 with only a games subset surviving; macOS 27 already stops auto-restoring Rosetta and forces native launch. A product that ships ARM64EC Wine plus an x86 user-mode emulator (Wine 10.0 documents the `HKLM\Software\Microsoft\Wow64\amd64` emulator interface implemented by FEX) is the only durable path.
- **Graphics licensing.** D3DMetal is non-commercial and non-redistributable; the open alternatives cover D3D10/11 (DXMT) and Vulkan-based D3D9-12 (DXVK/vkd3d over MoltenVK). AutoCAD's D3D12 FL12_0 "Fast" styles will need vkd3d-over-MoltenVK work or a Metal 4 backend.
- **Scope.** Highball, Mythic, Silo, soju, Playdock, Lithium and WineForge are games-only; Whisky is dead; Sikarugir disclaims being a CrossOver/Whisky replacement; MetalSharp cannot be used commercially.
- **VM route is officially unsupported for CAD and still Arm-Windows constrained** (DirectX 12 caveats, no nested virtualization, Desktop Connector broken, separate Windows license, Microsoft's page stale at Parallels 20).
- **Cloud route** requires an organization tenant ("Windows 365 isn't currently available for individuals") and a network.

## Reusable code, ideas, and license implications for MIRRORZ

- **Wine 11.x (LGPL-2.1+)**: base runtime; ARM64EC + FEX interface is upstream. Shipping modified Wine requires publishing source for LGPL components; proprietary UI/launcher layers are fine (CrossOver, Sikarugir and Silo all do this).
- **DXMT (LGPL-2.1+)**: D3D10/11 to Metal; safe to bundle with source offer. **DXVK (Zlib per Highball's summary), MoltenVK, vkd3d** for the D3D9/12 gaps.
- **D3DMetal / GPTK 4**: do not bundle; at most detect a user-supplied GPTK like Silo ("imports Apple's Game Porting Toolkit from your `.dmg`").
- **Highball's CC0 `highball-db`**: model for an open "verified runs" database; CC0 means MIRRORZ can copy the schema and seed data freely.
- **soju (GPL-3.0)**: reference for launcher/login fixes (CEF renderer, `ROSETTA_ADVERTISE_AVX`, D3DMetal payload layout); GPL means learn from it, do not link it into proprietary code.
- **Gcenx macOS_Wine_builds / macports-wine**: proven build recipe and dependency list (MoltenVK, GStreamer 1.28.5, llvm-mingw); builds are x86_64-only, so MIRRORZ must add an arm64 build lane.
- **Sikarugir**: LGPL `Configure.app` reusable; launcher/Creator are not LGPL - avoid.
- **MetalSharp**: PolyForm Noncommercial - study only, no reuse.
- **Apple `container`/Containerization (Apple GitHub, open source)**: pattern for sub-second VM boot, ASIF images, Rosetta directory share, and DiskImageKit on macOS 27 if MIRRORZ adds a "real Windows" VM fallback.
- **Apple GPTK agent skills (Apache-2.0)**: reuse the Metal 4/MetalFX knowledge base for MIRRORZ's own agent-assisted porting of CAD graphics.

## Open questions

1. Exact release dates, prices and feature lists of Parallels Desktop 26/27 and CrossOver 25/26 (vendor sites blocked); whether Parallels 27 really dropped Intel Macs (cask says arm64-only).
2. VMware Fusion's status under Broadcom in 2025-2026 (no cask, no reachable page).
3. Has CodeWeavers or anyone shipped an ARM64EC Wine build for macOS, and does FEX/Box64 work under Apple's `%gs` swap and 16K pages? (Wine 11.0 notes: "Using a 4K-page kernel is strongly recommended.")
4. Does AutoCAD 2027's removal of the "ARM Processors are not supported" sentence signal an upcoming Windows-on-Arm build, which would change the VM route's economics?
5. What exactly survives in Apple's post-macOS-27 "subset of Rosetta functionality" for games, and can a Wine-based CAD product qualify?
6. Will Microsoft update its Windows-on-Mac authorization page beyond Parallels 20 / M3, and will Windows 365 open to individuals?

## Sources (numbered list of URLs with dates)
1. https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment (Apple docs JSON, fetched 2026-09-04)
2. https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes ("macOS 27 Golden Gate Beta 8 Release Notes"; beta 8 dated Aug 31, 2026 in Apple's releases RSS)
3. https://developer.apple.com/documentation/macos-release-notes/macos-26-release-notes (fetched 2026-09-04)
4. https://developer.apple.com/news/releases/rss/releases.rss (items: macOS 27.0 beta Jun 8, 2026; macOS 26.6.2 Aug 17, 2026; Xcode 27 beta 6 Aug 24, 2026; macOS 27.0 beta 8 Aug 31, 2026)
5. https://developer.apple.com/documentation/virtualization (fetched 2026-09-04)
6. https://developer.apple.com/games/game-porting-toolkit/ (fetched 2026-09-04)
7. https://github.com/apple/game-porting-toolkit (README; repo updated Jun 8, 2026)
8. https://github.com/apple/container and https://github.com/apple/containerization (READMEs; release 1.3.1 "29 Aug", 2026)
9. https://raw.githubusercontent.com/wine-mirror/wine/wine-11.0/ANNOUNCE.md and https://github.com/wine-mirror/wine/releases/tag/wine-11.0 (tag "13 Jan"; 2026)
10. https://raw.githubusercontent.com/wine-mirror/wine/wine-10.0/ANNOUNCE.md (Wine 10.0, 2025)
11. https://github.com/Gcenx/macOS_Wine_builds (README; releases 11.16 "24 Aug" and 11.0_1 "16 Apr", 2026)
12. https://github.com/Whisky-App/Whisky (README maintenance notice; v2.3.5 "05 Apr", 2025) and https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/w/whisky.rb (deprecated 2025-04-09)
13. https://github.com/Kegworks-App/Kegworks (redirects to Sikarugir README) and https://raw.githubusercontent.com/Sikarugir-App/homebrew-sikarugir/main/Casks/sikarugir.rb (v1.0.1)
14. https://github.com/3Shain/dxmt (README and LICENSE, 2023-2026)
15. https://github.com/topics/game-porting-toolkit and https://github.com/topics/wine?o=desc&s=updated (fetched 2026-09-04)
16. https://github.com/gauthierpiarrette/highball (fetched 2026-09-04)
17. https://github.com/metalsharp/MetalSharp (README "Updated: 2026-07-28")
18. https://github.com/mikaelhug/Silo, https://github.com/lasermaze/Cellar, https://github.com/Alien4042x/WineForge, https://github.com/kaangiray26/lithium (READMEs/LICENSEs, fetched 2026-09-04)
19. https://github.com/BCD1210/soju (README, "Status (2026-08)")
20. https://github.com/MythicApp/Mythic (v0.6.0 "27 Dec", 2025)
21. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/p/parallels.rb (27.0.1-58670, fetched 2026-09-04)
22. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/c/crossover.rb (26.3.0)
23. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/u/utm.rb (4.7.5) and https://github.com/utmapp/UTM/releases/tag/v4.7.5, /v5.0.5
24. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/v/virtualbox.rb (7.2.16) and https://github.com/Homebrew/homebrew-cask/tree/master/Casks/v (no vmware-fusion cask)
25. https://github.com/orgs/Parallels/repositories and https://github.com/Parallels/prl-devops-service (README; CHANGELOG 1.0.5 dated 2026-07-22)
26. https://support.microsoft.com/en-us/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c (fetched 2026-09-04)
27. https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation and https://learn.microsoft.com/windows/arm/apps-on-arm-program-compat-troubleshooter (Prism)
28. https://learn.microsoft.com/microsoft-365-apps/end-of-support/end-of-support-32bit-arm (Oct 2025 / Dec 2026 dates)
29. https://learn.microsoft.com/windows/arm/arm32-to-arm64 and https://learn.microsoft.com/windows/whats-new/deprecated-features
30. https://learn.microsoft.com/windows/arm/iso and https://learn.microsoft.com/en-us/windows/arm/add-arm-support
31. https://learn.microsoft.com/windows-app/get-started-connect-devices-desktops-apps and https://learn.microsoft.com/windows-365/overview
32. https://learn.microsoft.com/en-us/windows/whats-new/whats-new-windows-11-version-25h2 (WSUS availability Oct 14, 2025)
33. https://learn.microsoft.com/answers/a/12344798 (community answer on Oct 2025 Prism changes; low confidence)
34. https://help.autodesk.com/view/ACD/2027/ENU/?guid=AUTOCAD_2027_RELEASE_NOTES (March 25, 2026)
35. https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=AUTOCAD_MAC_2027_RELEASE_NOTES (March 25, 2026) and https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-81FF4C76-6077-4D2B-9081-250BDBEA645D
36. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html
37. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html and .../System-requirements-for-AutoCAD-LT-2027.html
38. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html
39. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
40. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Selection-in-AutoCAD-products-lags-for-several-seconds-on-Apple-Mac-computer-with-Parallels-running-Windows.html
41. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html
42. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Does-Inventor-support-running-on-virtual-machines.html (virtualization support policy wording)
43. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Compare-Features-AutoCAD-for-Windows-vs-AutoCAD-for-Mac.html
44. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Fusion-crashes-on-startup-in-Windows-on-ARM.html
