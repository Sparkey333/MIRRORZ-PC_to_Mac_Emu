# New Entrants and Market Moves in Windows-on-Mac, 2025-2026
_Research date: 2026-09-03_

Scope: new products, forks, major releases and platform changes since January 2025 that affect running Windows/PC software (AutoCAD in particular) on Apple-silicon Macs. Facts marked **[verified]** were read from a fetched official page (Apple developer site, GitHub, Microsoft Learn/Support, Autodesk Help). Facts marked **[search-only]** come from search-result snippets of pages the research proxy blocked (parallels.com, codeweavers.com, broadcom.com, most news sites) and should be re-checked before being quoted externally.

## TL;DR (5 bullets)

- **Apple started the clock.** Apple's WWDC25 State of the Union says "macOS Tahoe will be the final release for Intel Macs" [6], and Apple Developer News states macOS 27 is "the final release to support Rosetta" with only a subset kept for "older, unmaintained gaming titles"; macOS 26.4+ shows warnings when a Rosetta app launches [7]. Every free Wine-based Mac tool today (Gcenx builds, Sikarugir, Whisky, Mythic) ships i386/x86_64-only Wine and therefore depends on Rosetta [1][4][25].
- **CodeWeavers is the only Wine vendor building the post-Rosetta stack.** CrossOver 27 (due "early 2027") drops Intel Macs and 32-bit bottles, and a native ARM64 preview using upstream Wine ARM64EC plus a macOS port of the FEX emulator shipped 31 July 2026 -- still without D3DMetal and with launchers broken [36][37]. Upstream FEX itself lists Linux hosts only [26].
- **The Whisky vacuum was filled by hobby projects, not a productivity player.** Whisky was archived 11 May 2025 [1]; successors are Sikarugir (Wineskin lineage, mixed LGPL/proprietary, Rosetta required) [4], Mythic (GPL-3 game launcher; its Engine repo was archived 25 Dec 2025) [23][24], and beta wrappers MacWrap and Pixel Port [42]. None targets CAD or business apps.
- **Incumbents consolidated, not expanded.** Parallels stayed with KKR when Corel was split (announced 26 Feb 2026) [34]; Parallels Desktop 26 (Aug 2025) and 27 (Aug 2026, Apple-silicon-only, Metal-based OpenGL 4.3 driver) are incremental [29][32]; x86 emulation is still a 1-vCPU Windows 10 preview [33]. VMware Fusion Pro is free and shipped 26H1 in May 2026 [41]; UTM 4.7.5 (3 Jan 2026) still has no GPU acceleration for Windows guests [2][28].
- **The white space is unchanged.** Apple's macOS 27 Virtualization framework gained USB passthrough, DiskImageKit and custom networking but still targets only macOS and Linux guests [5]; Microsoft's Mac authorization page still names Parallels 18-20 on M1-M3 [12]; Autodesk's AutoCAD 2027 for Mac is Metal-only [18], but its Windows requirements list no ARM64 and its KBs call Windows-on-ARM and Parallels unsupported [19][20][21]. Nobody ships a native-ARM64, Rosetta-free, CAD-tuned compatibility layer for professional Windows apps.

## Current status (version, date, maintainer, momentum)

| Product | Latest version / date | Maintainer | Momentum and notes |
|---|---|---|---|
| Parallels Desktop 26 | Released 26 Aug 2025; supports macOS 26 + Windows 11 25H2; version numbers now track the year/macOS **[search-only]** [29][30] | Parallels (KKR-owned) | Enterprise features (SOC 2, Jamf/MDM); >1M customers, "49% net new ARR growth in 2025" per split press release **[search-only]** [34] |
| Parallels Desktop 27 | Announced 25 Aug 2026; Apple-silicon-only; new Metal-based graphics driver with OpenGL 4.3; SME acceleration on M4/M5; macOS 27 support **[search-only]** [32] | Parallels | One report says the OpenGL 4.3 driver is not available in Standard edition **[search-only]** [32] |
| CrossOver 26 | 10 Feb 2026; Wine 11.0, D3DMetal 3.0, DXMT 0.72, VKD3D 1.18 **[search-only]** [35] | CodeWeavers | Still x86_64 (Rosetta) on Mac |
| CrossOver 27 preview | Native ARM64 macOS preview 31 Jul 2026; release "early 2027"; Sonoma+ and Apple silicon only; 32-bit bottles removed **[search-only]** [36][37] | CodeWeavers | First Rosetta-independent Wine on Mac; preview lacks D3DMetal, D3D12, launcher support, bottle conversion |
| UTM | v4.7.5, published 3 Jan 2026 (QEMU 10.0.2 backend, Liquid Glass UI, App Intents) **[verified]** [2]; Apache-2.0, repo active (pushed 2 Sep 2026) [3] | osy / community | Free; Windows guests get no GPU acceleration (long-standing issue, virgl OpenGL only for Linux) [28] |
| VMware Fusion Pro | 26H1 released mid-May 2026 (sources say 14 or 15 May); free for commercial/personal use; 26H1u1 exists **[search-only]** [41] | Broadcom | Maintenance cadence; ARM ESXi connectivity, Secure Boot PK fixes |
| Whisky | Archived 11 May 2025; "no longer actively maintained" **[verified]** [1] | Isaac Marovitz (ended) | GPL-3.0; built on CrossOver 22.1.1 + GPTK; recommended CrossOver [1][39] |
| Sikarugir (ex-Kegworks, ex-Wineskin) | Repo active (pushed 4 Sep 2026), 3.6k stars, no GitHub releases (site downloads) **[verified]** [4]; renamed Oct 2025 **[search-only]** [40] | VitorMM, Gcenx (Wine engines), PaulTheTall | Requires macOS 14+ and Rosetta 2 on Apple silicon; D3DMetal toggle; README says it is "not a replacement for CrossOver or Whisky" [4] |
| Mythic | v0.6.0 pre-release (latest tag); GPL-3.0; macOS 14+ **[verified]** [23]; Engine repo archived 25 Dec 2025, moved to MythicApp/wine [24] | Mythic team | Game launcher (Epic/Steam), GPTK/D3DMetal based |
| MacWrap / Pixel Port | Free betas (2026) that wrap an .exe into a .app using Wine + GPTK **[search-only]** [42] | Indie | No verifiable pricing/licensing; Apple-silicon, Rosetta-based |
| Gcenx macOS Wine builds | 11.16 (24 Aug 2026); configured `--enable-archs=i386,x86_64` only **[verified]** [25] | Gcenx | The de-facto Wine binary supply for Sikarugir/hobby wrappers; x86-only |
| Apple GPTK | Game Porting Toolkit 4 (Metal 4, agentic porting skills) **[verified]** [9] | Apple | Developer-only evaluation environment; not a redistributable runtime |
| Apple `container` | 1.3.1 (29 Aug 2026), Apache-2.0, macOS 26, Linux containers as lightweight VMs **[verified]** [11] | Apple (open source) | Shows Apple's investment goes to Linux/dev workloads, not Windows |
| Windows App for macOS | 11.3.9 (3064), published 11 Aug 2026; macOS 14+; Liquid Glass on macOS 26 **[verified]** [15] | Microsoft | The Windows 365 / Cloud PC path; GPU Cloud PC tiers exist [16] |
| VirtualBuddy | 2.2 beta 4 (27 Aug 2026): USB passthrough needs macOS 27 host and guest **[verified]** [27] | insidegui | macOS/Linux guests only; illustrates new macOS 27 APIs |

## Pricing and licensing (table)

| Product | Price (USD) | License / terms | Source status |
|---|---|---|---|
| Parallels Desktop 26/27 Standard | $99.99/yr subscription or $219.99 one-time | Proprietary; Windows 11 licence sold separately | [search-only] [31][32] |
| Parallels Desktop Pro / Business | $119.99/yr; $149.99/yr (subscription only) | Proprietary | [search-only] [31][32] |
| CrossOver (Mac) | ~$74/yr ("CrossOver+"); CrossOver Life $494 lifetime; promos "from $39.95" | Proprietary wrapper over LGPL Wine; CodeWeavers publishes Wine changes | [search-only] [38] |
| VMware Fusion Pro | Free (commercial, educational, personal), no key required | Proprietary (Broadcom) | [search-only] [41] |
| UTM | Free (open source; optional paid App Store build) | Apache-2.0 | [verified] [3] |
| Whisky | Free | GPL-3.0, archived | [verified] [1] |
| Sikarugir | Free | Configure.app LGPL-2.1; Launcher and Creator.app proprietary from v1.0.1 | [verified] [4] |
| Mythic | Free | GPL-3.0 (app); Engine derived from WhiskyWine/Wine LGPL | [verified] [23][24] |
| Windows 11 Pro licence | Required per VM instance; keys are "platform agnostic (x64 vs Arm)" | Microsoft policy | [verified] [12] |
| Windows 365 | Per-user, per-month SaaS; GPU tiers (Select/Standard/Super/Max) | Microsoft | [verified] [12][16] |
| AutoCAD 2027 | Subscription (Autodesk store; price page blocked) | Virtualization only "if the applicable terms ... expressly permit virtualization" | [verified policy text] [19] |

## How it works (architecture)

Three architectures now compete, and the 2025-2026 news sorts cleanly into them.

**1. Full VM running Windows 11 on Arm.** Parallels, Fusion and UTM use Apple's Hypervisor/Virtualization frameworks to boot Arm64 Windows; x86/x64 apps inside the guest run under Microsoft's Prism emulator, which since Windows 11 24H2 exposes AVX/AVX2, BMI, FMA and F16C to x64 apps [13][14]. Kernel-mode drivers must be native Arm64; emulation is user-mode only [13]. Microsoft's Mac page limits the authorized configuration to Parallels 18-20 on M1-M3, notes DirectX 12 limitations, and forbids nested virtualization (WSL, Sandbox, VBS) [12]. Parallels' separate x86_64 emulator (a preview since 20.2 in Jan 2025) boots Intel Windows 10/Server 2022 only, with one vCPU, 8 GB RAM, no USB or sound **[search-only]** [33]. Parallels 27's headline is a Metal-based guest graphics driver reaching OpenGL 4.3 **[search-only]** [32]; UTM still lacks any GPU path for Windows guests [28].

**2. Translation layer (Wine) with no Windows.** Whisky, Sikarugir, Mythic, MacWrap, Pixel Port and CrossOver run Win32 binaries directly. Today every one of them is an x86_64 Wine process translated by Rosetta, with Direct3D handled by Apple's D3DMetal (from GPTK), DXVK/MoltenVK or DXMT [1][4][24][25]. CodeWeavers' path off Rosetta is Wine's ARM64EC support (Wine 10, Jan 2025) plus a macOS port of FEX for i386/x86-64 emulation, shipped as a CrossOver preview on 31 Jul 2026 **[search-only]** [37]. Upstream FEX remains Linux-only [26], so the macOS port is CodeWeavers' unreleased work.

**3. Remote Windows.** Microsoft's Windows App (macOS 11.3.9, Aug 2026) fronts Windows 365 Cloud PCs, including NVIDIA GPU tiers that support nested virtualization only on non-GPU SKUs [15][16]. Microsoft's own Mac guidance leads with Windows 365 before Parallels [12].

**Apple platform changes that matter.** WWDC26 session 224 adds to the macOS 27 Virtualization framework: automated macOS guest provisioning, USB accessory passthrough (hot-plug), vmnet-based custom topologies and port forwarding, DiskImageKit with ASIF base/cache/overlay layers (copy-on-write clones), custom Virtio devices and EFI Secure Boot for Linux -- and mentions no Windows guests and no Rosetta-in-VM changes [5]. Apple's `container` tool (macOS 26) runs Linux containers as lightweight VMs [10][11]. GPTK 4 adds Metal 4 and agentic porting skills but remains a developer evaluation environment [9].

## Feature checklist (table: feature | status | notes)

| Feature | Status across the field (Sep 2026) | Notes |
|---|---|---|
| Native ARM64 host binary, no Rosetta | Parallels/Fusion/UTM: yes (VMs). Wine family: only CrossOver 27 preview | Whisky, Sikarugir, Mythic, Gcenx builds are i386/x86_64 [1][4][25] |
| x86-64 Windows app execution on Apple silicon | VMs via Prism inside Arm Windows; Wine via Rosetta; CrossOver preview via FEX+ARM64EC | Parallels' own x86 emulator: Win10 only, 1 vCPU **[search-only]** [33] |
| DirectX 11/12 | VMs: DX11 class in Parallels, DX12 "limitations" per Microsoft [12]; Wine: D3DMetal (GPTK) covers D3D9-12 [24] | CrossOver ARM64 preview has no D3DMetal yet **[search-only]** [37] |
| OpenGL 4.x in guest | Parallels 27 claims 4.3 via Metal driver (Pro+) **[search-only]** [32]; UTM virgl only for Linux [28] | Relevant to legacy CAD/GIS |
| Metal-native rendering path for pro apps | Only native Mac apps (AutoCAD for Mac 2027 is Metal-only) [18] | No compatibility layer exposes Metal features to Windows apps |
| USB / peripheral passthrough | Parallels: yes; Apple VZ framework: new in macOS 27 [5]; Parallels x86 emulator: no [33] | Dongles/plotters matter for CAD shops |
| Windows licence required | VMs: yes, per instance [12]; Wine family: no | Cost and admin gap Wine can exploit |
| Microsoft-authorized Windows-on-Mac | Parallels 18-20 on M1-M3 only [12] | Page not updated for PD 26/27 or M4/M5 |
| CAD-vendor support statement | Autodesk: Parallels "no longer supported" for AutoCAD since 2013 release [21]; ARM-based Windows unsupported [20] | Support liability sits with the user |
| Enterprise management (MDM, SOC 2) | Parallels 26 **[search-only]** [29]; Windows 365 native | Open-source tools: none |
| Open-source core | UTM (Apache-2.0), Whisky (GPL-3), Mythic (GPL-3), Sikarugir (mixed), Wine (LGPL) | CrossOver/Parallels/Fusion proprietary |
| Rosetta dependency after macOS 27 | Fatal for all x86_64 Wine wrappers; VMs unaffected | Apple keeps only a gaming subset [7] |
| Post-Rosetta status of Linux-VM Rosetta | Apple engineer: "a different use case" from app translation, no commitment [8] | Watch item |

## CAD / AutoCAD relevance

- **AutoCAD 2027 shipped 25 Mar 2026** (release notes dated) [17]. The Mac edition removed OpenGL and made Metal the sole graphics engine, added Autodesk Assistant and Smart Blocks, and supports macOS 14/15/26 on Intel or M-series [18][19]. This raises the bar: a Windows-AutoCAD-on-Mac product must at least match a native Metal app's 2D/3D responsiveness.
- **Windows AutoCAD 2027 requirements list "64-bit Microsoft Windows 11", DirectX 12 feature level 12_0 for "Fast" visual styles, .NET 10** -- and do not mention ARM64 [19]. A third-party guide claims AutoCAD 2026 supports Snapdragon ARM64 natively **[search-only, conflicts with official pages]** [44]; Autodesk's own KB says Windows-on-ARM installs are "unsupported hardware" [20] and Desktop Connector does not work in Parallels on Apple silicon [22]. Treat ARM-native AutoCAD as unconfirmed.
- **Autodesk's virtualization stance is a liability shield**: products may be virtualized only where the licence "expressly permit[s] virtualization" and Autodesk "makes no representations, warranties or other promises" [19]. The Parallels KB says support for AutoCAD within Parallels ended with the 2013 release [21]. MIRRORZ cannot expect vendor blessing; it must earn trust through published compatibility evidence.
- **Toolsets are Windows-only** (Map 3D, Electrical, Plant 3D, MEP, Mechanical) [19]: this is the concrete reason Mac users still need Windows AutoCAD, and the Windows-only toolset list is where a Wine-based product can differentiate from AutoCAD for Mac.
- **Parallels 27's OpenGL 4.3 Metal driver is the first incumbent feature explicitly aimed at "GIS, CAD-adjacent, 3D and engineering workflows"** **[search-only]** [32]; it is gated to Pro/Business and still runs AutoCAD x64 under Prism inside an Arm VM with Microsoft-documented DX12 limits [12].

## Strengths (what to match)

- **CodeWeavers' engineering roadmap**: ARM64EC + FEX gives a Rosetta-free future and macOS 27-proof foundation; CodeWeavers funds upstream Wine, which makes its stack the reference implementation to track [36][37].
- **Parallels' enterprise polish**: MDM/Jamf deployment, SOC 2, Microsoft authorization, per-year versioning aligned with macOS, and now a Metal-backed OpenGL 4.3 driver **[search-only]** [29][32].
- **Zero-cost baselines**: Fusion Pro is free and UTM is Apache-2.0; any paid product must beat "free VM + your own Windows licence" on convenience and performance [3][41].
- **Apple's new primitives**: DiskImageKit ASIF overlays (instant clones, shared read-only base images), USB passthrough, vmnet port forwarding and guest provisioning are free building blocks in macOS 27 [5].
- **D3DMetal quality**: every Wine-based Mac tool rides Apple's D3DMetal for DirectX 9-12; matching that means using it (GPTK terms) or shipping DXMT/DXVK+MoltenVK [24].

## Weaknesses (what MIRRORZ must beat)

- **Rosetta cliff**: Whisky (dead), Sikarugir, Mythic, MacWrap and Pixel Port all die with general-purpose Rosetta after macOS 27 unless they rebuild on ARM64EC; none has announced it [1][4][7][25].
- **Games-first focus**: every Wine newcomer markets Steam/Epic gaming; nobody validates productivity workflows (dialogs, printing/plotting, licensing daemons, .NET 10, Access runtime) that AutoCAD needs [19][23][42].
- **CrossOver 27 preview gaps**: no D3DMetal, no D3D12, broken launchers, no bottle migration, and a stated "early 2027" release **[search-only]** [37]. A 6-12 month window exists.
- **VM friction**: Windows licence per instance, no Microsoft authorization beyond Parallels 18-20/M1-M3, DX12 limits, nested-virt bans [12]; Parallels x86 emulator is Windows 10, 1 vCPU **[search-only]** [33]; UTM has no Windows GPU path [28].
- **Vendor support vacuum**: Autodesk disclaims virtualization and ARM [19][20][21]; Microsoft's authorization page is stale [12]. No incumbent publishes AutoCAD-specific compatibility data.
- **Incumbents' attention is elsewhere**: Parallels is being repositioned as a standalone KKR asset (split announced Feb 2026, expected close May 2026) **[search-only]** [34]; Apple's virtualization roadmap is macOS/Linux/containers [5][10]; Broadcom ships Fusion as a free maintenance product [41].

## Reusable code, ideas, and license implications for MIRRORZ

- **Wine (LGPL-2.1+)**: usable in a commercial product if Wine modifications are published; proprietary UI/launcher can stay closed (CodeWeavers and Sikarugir both do this) [4][38]. Track upstream ARM64EC work; do not build on Gcenx x86_64-only builds for the long term [25].
- **FEX (MIT)**: permissive; upstream is Linux-only, so a macOS port is real engineering (CodeWeavers has not published theirs as of the preview) [26][37]. MIT allows a closed fork, but contributing back reduces maintenance cost.
- **Whisky (GPL-3.0, archived)**: SwiftUI bottle-management UI and GPTK integration patterns are reusable only under GPL-3 -- copying code forces MIRRORZ's app to be GPL; study, do not copy [1].
- **Mythic (GPL-3.0) / Mythic Engine (Wine LGPL derivative of WhiskyWine)**: same GPL caveat for the app; Engine build scripts are LGPL-derived and informative for D3DMetal packaging [23][24].
- **Sikarugir Configure.app (LGPL-2.1)**: winetricks-style prefix configuration logic; Launcher/Creator are proprietary and off-limits [4].
- **UTM (Apache-2.0)**: permissive; its Apple Virtualization backend, QEMU packaging, and App Intents automation are reusable for a VM fallback mode [3].
- **Apple `container`/Containerization (Apache-2.0)**: reference implementation of Virtualization framework, vmnet and ASIF usage in Swift [11].
- **GPTK / D3DMetal**: Apple's evaluation environment is developer-only; redistribution terms are not published on the page [9]. Assume D3DMetal cannot be bundled without an Apple agreement; plan for DXMT/DXVK+MoltenVK as the shippable path, as CrossOver 26 does with DXMT **[search-only]** [35].
- **Ideas to copy**: year-based versioning aligned to macOS (Parallels 26/27); publishing per-app compatibility ratings (CrossOver); ASIF overlay images for instant per-app sandboxes (macOS 27 DiskImageKit) [5]; Metal-backed OpenGL 4.3 as an explicit CAD feature **[search-only]** [32].

## Open questions

1. Will CodeWeavers publish its macOS FEX port under MIT, and when will D3DMetal land in the ARM64 build? (codeweavers.com blocked; verify.)
2. Does Apple keep Rosetta for Linux VMs after macOS 27? Apple staff called it "a different use case" without commitment [8].
3. Is AutoCAD 2026/2027 actually ARM64-native on Windows? Autodesk's official pages do not say so [19][20]; the claim comes from a third-party site [44].
4. Exact Parallels 27 release date and whether OpenGL 4.3 is Pro-only (press release and windowsforum blocked) [32].
5. VMware Fusion 26H1 exact release date (14 vs 15 May 2026 in different snippets) and any Apple-silicon-specific Windows changes [41].
6. Whether Microsoft will refresh the Mac authorization page for Parallels 26/27 and M4/M5 [12].
7. Pricing/licensing of MacWrap and Pixel Port, and whether either has a productivity roadmap [42].
8. Whether GPTK 4's D3DMetal licence permits third-party redistribution [9].

## Sources (numbered list of URLs with dates)

Fetched and verified (accessed 2026-09-05):
1. https://github.com/Whisky-App/Whisky -- archived 2025-05-11; GPL-3.0; "no longer actively maintained".
2. https://github.com/utmapp/UTM/releases/tag/v4.7.5 -- v4.7.5 published 3 Jan (2026 per GitHub current-year display).
3. https://github.com/utmapp/UTM -- Apache-2.0; pushed 2026-09-02 (repo metadata via GitHub API).
4. https://github.com/Sikarugir-App/Sikarugir -- README: macOS 14+, Rosetta 2 required, mixed licensing; pushed 2026-09-04.
5. https://developer.apple.com/videos/play/wwdc2026/224/ -- WWDC26 "Expand the capabilities of your Virtualization app" (June 2026).
6. https://developer.apple.com/videos/play/wwdc2025/102/ -- WWDC25 Platforms State of the Union transcript (9 June 2025).
7. https://developer.apple.com/news/?id=w5ngl9k2 -- "Upcoming changes to Rosetta support" (page dated 1 Sep 2026).
8. https://developer.apple.com/forums/thread/787530 -- Apple DTS/Frameworks engineer replies on Rosetta after macOS 27.
9. https://developer.apple.com/games/game-porting-toolkit/ -- Game Porting Toolkit 4 (2026).
10. https://developer.apple.com/videos/play/wwdc2025/346/ -- "Meet Containerization" (June 2025).
11. https://github.com/apple/container -- Apache-2.0; macOS 26; releases 1.3.1 (29 Aug 2026), 1.3.0, 1.2.2.
12. https://support.microsoft.com/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c -- Microsoft policy page (undated; fetched 2026-09-05).
13. https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation -- Prism emulator (Windows 11 24H2).
14. https://learn.microsoft.com/windows/arm/apps-on-arm-program-compat-troubleshooter -- AVX/AVX2 and per-app emulation settings.
15. https://learn.microsoft.com/windows-app/whats-new?tabs=macos -- Windows App macOS 11.3.9 (11 Aug 2026).
16. https://learn.microsoft.com/windows-365/enterprise/gpu-cloud-pc -- GPU Cloud PC tiers.
17. https://help.autodesk.com/view/ACD/2027/ENU/?guid=AUTOCAD_2027_RELEASE_NOTES -- dated 25 Mar 2026.
18. https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-81FF4C76-6077-4D2B-9081-250BDBEA645D -- What's New in AutoCAD for Mac 2027 (OpenGL removed, Metal sole engine).
19. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html -- Windows and Mac requirements; virtualization disclaimer.
20. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html -- ARM64 Windows "unsupported hardware".
21. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html and https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-Mac-won-t-launch-when-running-AutoCAD-within-Parallels.html -- Parallels not supported since AutoCAD 2013.
22. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
23. https://github.com/MythicApp/Mythic and https://github.com/MythicApp/Mythic/releases -- GPL-3.0; macOS 14+; v0.6.0 pre-release.
24. https://github.com/MythicApp/Engine -- archived 25 Dec 2025; WhiskyWine derivative.
25. https://github.com/Gcenx/macOS_Wine_builds and /releases -- 11.16 (24 Aug 2026); `--enable-archs=i386,x86_64`.
26. https://github.com/FEX-Emu/FEX -- MIT; Linux hosts.
27. https://github.com/insidegui/VirtualBuddy/releases -- 2.2 beta 4 (27 Aug 2026), USB passthrough requires macOS 27.
28. https://github.com/utmapp/UTM/issues/4285 -- guest OpenGL limits (closed via PR #7576).

Search-result snippets only (page blocked by research proxy; unverified):
29. https://www.parallels.com/blogs/parallels-desktop-26/ (26 Aug 2025).
30. https://9to5mac.com/2025/08/26/parallels-desktop-26-brings-macos-26-support-and-new-tools-for-it/ (26 Aug 2025).
31. https://www.parallels.com/products/desktop/buy/ and https://www.macworld.com/article/668146/parallels-desktop-review.html (2025-2026 pricing).
32. https://www.parallels.com/newsroom/news/press-releases/20260825-parallels-desktop-27/ ; https://9to5mac.com/2026/08/29/parallels-desktop-27/ ; https://windowsforum.com/windows-news.4/parallels-desktop-27-opengl-4-3-requires-pro-edition.443518/ (Aug 2026).
33. https://kb.parallels.com/130217 -- x86 emulator limitations (Win10/Server 2022, 1 vCPU, 8 GB, no USB/sound).
34. https://www.parallels.com/newsroom/news/press-releases/20260226-corel-announcement/ ; https://www.heise.de/en/news/Corel-to-be-split-Parallels-remains-with-KKR-11217943.html (26 Feb 2026).
35. https://www.codeweavers.com/blog/mjohnson/2026/2/10/crossover-26-cures-artificial-incompatibility-with-windows-games-on-mac ; https://www.phoronix.com/news/CrossOver-26 (10 Feb 2026).
36. https://www.codeweavers.com/blog/mjohnson/2026/6/11/whats-in-and-whats-out-for-crossover-27 (11 Jun 2026).
37. https://www.codeweavers.com/blog/mjohnson/2026/7/31/crossover-preview-the-right-to-bear-arm64-on-mac ; https://appleinsider.com/articles/26/07/31/first-apple-silicon-native-crossover-build-in-testing-as-rosettas-end-nears (31 Jul 2026).
38. https://www.codeweavers.com/store/ (pricing, 2026).
39. https://appleinsider.com/articles/25/04/16/whisky-development-ends-on-macos-to-help-wine-flourish (16 Apr 2025).
40. https://machow2.com/kegworks-officially-renamed-to-sikarugir/ (Oct 2025).
41. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/26H1/release-notes/vmware-fusion-26h1-release-notes.html ; https://blogs.vmware.com/cloud-foundation/2026/05/14/announcing-vmware-workstation-and-fusion-26h1/ (May 2026).
42. https://macwrap.app/ ; https://pixelport.gg/blog/whisky-is-dead-what-replaces-it/ (2026).
43. https://www.macrumors.com/2026/02/16/macos-tahoe-26-4-rosetta-2-warnings/ (16 Feb 2026).
44. https://unanswered.io/guide/does-autocad-run-on-arm-processors (undated; claim conflicts with Autodesk KB).
