# Wine on macOS: the open-source codebases MIRRORZ can build on (winemac.drv, CrossOver sources, Whisky, Kegworks/Sikarugir, Hangover, Wine-GE)

_Research date: 2026-09-03_

_Method note: 20+ web searches and ~35 page fetches. Several primary domains (codeweavers.com, winehq.org, apple support KB, most news sites, Wikipedia) are blocked by this environment's egress proxy; where a fact could only be taken from a search-engine snippet of such a page it is marked "(snippet)" and should be re-verified before being quoted externally. Everything else was read from the fetched page (GitHub repos/raw files, developer.apple.com, Autodesk help via the Autodesk MCP)._

## TL;DR (5 bullets)

- **Wine is LGPL-2.1-or-later and is the only viable foundation.** Every Mac product in this space (CrossOver, Whisky, Kegworks/Sikarugir, Mythic, GPTK itself) is a Wine build plus a launcher. Wine 11.0 (tagged 2026-01-13) made the "new WoW64" mode fully supported and removed the `wine64` loader, so 32-bit Windows apps run without any 32-bit host libraries [3][4].
- **Rosetta is on a clock.** Apple's developer documentation says Rosetta remains a general-purpose tool "through macOS 27", after which only a subset for "older unmaintained gaming titles" survives [47]. Today's Mac Wine builds are x86_64 and depend on Rosetta (Whisky, Sikarugir and Gcenx all require it). CodeWeavers' answer is native ARM64 Wine + a Mac port of the FEX emulator, previewed 2026-07-31 and requiring macOS 26.5+ (snippet) [39]. MIRRORZ must plan for ARM64EC Wine + an x86 emulator from day one.
- **The DirectX-to-Metal layer is the legal fault line.** Apple's D3DMetal (the only mature DX11/DX12-to-Metal layer) ships under a Game Porting Toolkit license that permits distribution "solely for non-commercial purposes" [24]. Whisky (free) and Sikarugir (free) ship it; CrossOver ships it commercially under a non-public Apple arrangement. A paid MIRRORZ cannot rely on the public license; DXMT (D3D10/11 to Metal, moving from MIT to LGPL, v0.80 on 2026-04-23) is the open alternative, and there is no open DX12-to-Metal path of comparable maturity [48].
- **LGPL compliance is routine but non-negotiable:** ship the LGPL text and prominent notice, publish the exact Wine source you ship (including your patches) from the same place or via a written offer, and keep Wine as separately replaceable dynamic libraries so users can relink/modify (LGPL 2.1 §4, §6) [7]. CodeWeavers' model (proprietary GUI + LGPL Wine sources at media.codeweavers.com) is the template [36][38].
- **The ecosystem is consolidating around CrossOver.** Whisky was archived 2025-05-11 after its author endorsed CrossOver [12][19]; Wine-GE was archived 2025-07-11 [34]; Mythic's Engine was archived 2025-12-25 [20]. The living open projects are upstream Wine, Gcenx's macOS builds, Sikarugir (Wineskin lineage), DXMT, and Hangover (Linux ARM64 reference for Wine+FEX/Box64).

## Current status (version, date, maintainer, momentum)

| Project | What it is | Latest state observed | Maintainer / momentum |
|---|---|---|---|
| **Wine (upstream)** incl. `dlls/winemac.drv` | Win32 compatibility layer; macOS driver is C + Objective-C (`cocoa_app.m`, `cocoa_window.m`, `cocoa_opengl.m`, `vulkan.c`, `clipboard.c`, etc.) [2] | Stable 11.0 tagged 2026-01-13 [4]; dev tags wine-11.13 (2026-07-10) through wine-11.17 (2026-09-04) on a two-week cadence [5] | WineHQ / CodeWeavers-funded; very active |
| **Gcenx macOS_Wine_builds / homebrew-wine** | Official-ish WineHQ macOS packages; builds configured `--enable-archs=i386,x86_64`, MacPorts deps, llvm-mingw; distributed as `.tar.xz`, `brew install --cask wine-stable` [8] | Releases tracking 11.14/11.15/11.16, "macOS Catalina and greater", bundle wine-gecko 2.47.4 + wine-mono [9]. The tap README also lists `wine-crossover` (built from `crossover-sources-23.7.1`, Wine 8.0.1 era) and `game-porting-toolkit` 3.0 casks [10] | Single volunteer (Gcenx); active |
| **CrossOver (wine-crossover sources)** | CodeWeavers' commercial fork; Wine parts LGPL, published at media.codeweavers.com/pub/crossover/source (snippet) [38]; community mirrors e.g. marzent/winecx (LGPL-2.1, branch `ff-wine-9.12`) [36] | CrossOver 26 released 2026-02-10 on Wine 11.0 (snippet) [41]; 26.3 on 2026-07-21 (snippet) [44]; ARM64 Mac preview 2026-07-31 (snippet) [39]; CrossOver 27 planned early 2027, Apple-silicon-only, macOS Sonoma+, 32-bit bottles removed (snippet) [40] | CodeWeavers; the commercial center of gravity |
| **Whisky** | SwiftUI launcher, GPL-3.0, "built on top of CrossOver 22.1.1 and Apple's Game Porting Toolkit" [12][13] | Last release v2.3.5 (2025-04-05) [14]; repo archived 2025-05-11 with notice "no longer actively maintained" [12] | Discontinued; author endorsed CrossOver (snippet) [19] |
| **Kegworks -> Sikarugir** | Wineskin lineage (Objective-C). `Kegworks-App/Kegworks` now redirects to `Sikarugir-App/Sikarugir` [26]; renamed Oct 2025 (snippet) [27] | Wrapper templates through 1.0.15 (KosmicKrisp v20260903, DXMT 0.74, D3DMetal 3.0, MoltenVK 1.4.1) [25]; requires macOS 14+ and Rosetta 2 on Apple silicon [22] | Small community team; active in 2026 |
| **Hangover** | Wine + FEX/Box64 for x86 Windows apps on **ARM64 Linux**; LGPL-2.1 [28] | hangover-11.16 (2026-08-30): FEX 2608, Box64 0.4.4; since 11.0 "10 patches on top of Wine", QEMU dropped, Box64 CPU DLL upstreamed as `WowBox64.dll` [29] | André Zwing; active; **no macOS support** [28] |
| **Wine-GE** | GloriousEggroll's Proton-patched Wine for Lutris (Linux) | Archived 2025-07-11; README: "THIS REPO IS DEAD. UMU-LAUNCHER IS ITS SUCCESSOR"; final tag GE-Proton8-26 [34][35] | Discontinued; irrelevant to macOS except as a patch-set reference |
| **DXMT** | D3D11/D3D10 -> Metal for Wine on macOS | v0.73 (2026-01-21), v0.74 (2026-03-10), v0.80 (2026-04-23, "last release distributed in MIT license", moving to LGPL) [48] | 3Shain; active; shipped inside CrossOver 26 (DXMT 0.72, snippet) [41] |
| **Mythic Engine / MythicApp/wine** | GPTK-style Wine for the Mythic launcher; Engine derived from WhiskyWine, archived 2025-12-25; successor `MythicApp/wine` is LGPL-2.1 on branch `mythic-crossover-24.0.7-stable` [20][21] | Active fork of CrossOver 24 sources | Small team |

## Pricing and licensing (table)

| Item | License / price | Source & date |
|---|---|---|
| Wine | LGPL 2.1 "or (at your option) any later version"; copyright Wine project authors 1993-2026 | [1] |
| winemac.drv | Part of Wine, same LGPL | [2] |
| CrossOver Wine sources | LGPL (published tarballs; mirrors carry LGPL-2.1 LICENSE) | [36][38] |
| CrossOver product | Proprietary GUI/support; **CrossOver+ 1-year listed at $74**, subscriptions "starting as low as $39.95" (snippet of the CodeWeavers store; not directly fetched, verify) | [43][44] |
| Whisky | GPL-3.0 (the Swift app); free | [12] |
| WhiskyWine runtime tarball | Downloaded at first run from `https://data.getwhisky.app/Wine/Libraries.tar.gz`; contains CrossOver-derived Wine + D3DMetal | [15][16][18] |
| Sikarugir | Mixed: `Configure.app` LGPL-2.1 (sources in `Sikarugir-foss-sources`); Launcher and Creator.app (v1.0.1+) under other terms; free | [22][23] |
| Apple D3DMetal / GPTK | Apple SLA: use only to develop/test/evaluate games for Apple products; distribute "solely for non-commercial purposes"; no reverse engineering; may not run on non-Apple hardware | [24] |
| Apple `apple/game-porting-toolkit` GitHub | Apache-2.0, but contains only agent skills, metal-cpp and samples, not D3DMetal; GPTK 4 is downloaded from developer.apple.com | [45][46] |
| Hangover | LGPL-2.1 | [28] |
| FEX | MIT (C++) | [31] |
| Box64 | MIT (C) | [32] |
| DXMT | MIT through v0.80, LGPL thereafter | [48] |
| Wine-GE | Build scripts + submodules (proton-wine, wine-staging); no top-level LICENSE file; Wine parts LGPL | [34] |

## How it works (architecture)

**Wine's macOS shape.** Wine is a set of PE DLLs (built with llvm-mingw) plus Unix-side `.so`/`.dylib` "unixlibs" and a `wine` loader. On macOS, `winemac.drv` is the display driver: Objective-C files (`cocoa_app.m`, `cocoa_window.m`, `cocoa_event.m`, `cocoa_clipboard.m`, `cocoa_cursorclipping.m`, `cocoa_display.m`, `cocoa_status_item.m`, `cocoa_opengl.m`) bridge to AppKit, and C files (`window.c`, `surface.c`, `gdi.c`, `keyboard.c`, `mouse.c`, `opengl.c`, `vulkan.c`, `systray.c`) implement the driver contract [2]. Vulkan reaches Metal through MoltenVK (a runtime dependency of Gcenx's builds) [8].

**32-bit without 32-bit libraries.** Since Wine 9.0 (experimental) and fully in 11.0, the "new WoW64" mode runs 32-bit PE code inside a 64-bit Unix process; 11.0 also supports 16-bit apps there, deprecates pure `WINEARCH=win32` prefixes, and drops the `wine64` binary "in favor of a single `wine` loader that selects the correct mode based on the binary being executed" [3]. This is what lets Wine live on 64-bit-only macOS. (Community explanation: Rosetta cannot run 32-bit processes, but a 64-bit process may create 32-bit code segments, which is how CrossOver's older `--enable-win32on64` and now upstream WoW64 work on Apple silicon; snippet) [53].

**Today's Apple-silicon path = x86_64 Wine under Rosetta.** Gcenx builds with `--enable-archs=i386,x86_64` [8]; Whisky's setup flow has a `RosettaView` that calls `Rosetta2.isRosettaInstalled` / `Rosetta2.installRosetta()` [17]; Sikarugir documents "Apple Silicon systems require Rosetta2" [22]. Wine 10.0 removed the need for the preloader with Xcode >= 15.3 and added syscall emulation for direct-NT-syscall apps on Sonoma+ [6]; 11.0 swaps `%gs` in the macOS syscall dispatcher and implements thread priorities on macOS [3].

**Tomorrow's path = ARM64EC Wine + external x86 emulator.** Wine 10.0: "The ARM64EC architecture is fully supported... The 64-bit x86 emulation interface is implemented. This takes advantage of the ARM64EC support to run all of the Wine code as native, with only the application's x86-64 code requiring emulation. The FEX emulator implements this interface when built as ARM64EC", selected via `HKLM\Software\Microsoft\Wow64\amd64` [6]. Hangover is the reference implementation on Linux: Wine configured `--enable-archs=arm64ec,aarch64,i386 --with-mingw=clang`, FEX compiled twice (`libarm64ecfex.dll` with the `arm64ec-w64-mingw32` triple for 64-bit apps, `libwow64fex.dll` with `aarch64-w64-mingw32` for 32-bit), Box64 as `wowbox64.dll` (`-DARM_DYNAREC=ON -DWOW64=ON`), all dropped into `lib/wine/aarch64-windows/` [30]. Hangover needs only ~10 patches on top of upstream Wine [29]. Neither FEX nor Box64 lists macOS as a host [31][32]; CodeWeavers says it made "a custom version of FEX compatible with Mac" and ships universal builds where the ARM64 half needs macOS 26.5+ and older systems fall back to Intel Wine + Rosetta (snippet) [39]. No public source for that Mac FEX port was found (an unrelated 1-star fork `Jpkovas/FEX_MacOs` exists) [33].

**Graphics translation layers.** WineD3D (D3D8/9 over OpenGL), D9VK/DXVK over MoltenVK, DXMT (D3D10/11 direct to Metal), and Apple's D3DMetal (D3D11/12 to Metal, 64-bit only) are the menu Sikarugir exposes per wrapper [22]. Whisky stored `D3DMetal.framework` and `libd3dshared.dylib` under `.../Libraries/Wine/lib/external/` (snippet) [18].

**Launcher pattern.** Whisky (Swift) downloads a versioned runtime tarball at first launch (`WhiskyWineVersion.plist` + `Libraries.tar.gz` from its CDN) into `~/Library/Application Support/<bundle id>/` and then spawns Wine per bottle [15][16]. Sikarugir instead generates self-contained `.app` wrappers from templates carrying an engine [25]. CrossOver's proprietary GUI drives an LGPL Wine that CodeWeavers republishes as source [38]; building those sources yourself yields Wine "without D3DMetal support or the CrossOver GUI" [37].

## Feature checklist (table: feature | status | notes)

| Feature | Status (2026-09) | Notes |
|---|---|---|
| 64-bit x86 Windows apps on Apple silicon | Works via Rosetta (x86_64 Wine) | All current builds; Rosetta general-purpose support ends after macOS 27 [47] |
| 32-bit x86 Windows apps | Works via new WoW64 inside 64-bit process | Fully supported in Wine 11.0 [3]; CrossOver 27 drops "32-bit bottles" (snippet) [40] |
| Native ARM64 Wine on macOS | Preview only (CrossOver, macOS 26.5+) | Upstream Wine supports ARM64/ARM64EC; the missing piece on Mac is a FEX host port [6][39] |
| D3D9 | Open | WineD3D / D9VK [22] |
| D3D10/11 to Metal | Open | DXMT v0.80 (2026-04-23), LGPL going forward [48] |
| D3D12 to Metal | Proprietary only | D3DMetal 3.0 (non-commercial license) [24]; GPTK 4 is current on Apple's site [45] |
| Vulkan on Metal | Open | MoltenVK 1.4.1 in Sikarugir templates; KosmicKrisp v20260903 also used [25] |
| Cocoa integration (windows, clipboard, cursor clipping, tray) | Upstream | `winemac.drv` [2] |
| .NET runtime for apps | Upstream | wine-mono bundled by Gcenx (11.3.0 with 11.16) [9]; AutoCAD needs Microsoft .NET 8/10, not Mono (see below) |
| App-store distribution | Not demonstrated | No fetched source shows a notarized/App Store Wine product; open question |
| Commercial redistribution of D3DMetal | Only with Apple agreement | Public SLA is non-commercial [24] |

## CAD / AutoCAD relevance

Autodesk's Windows requirements (fetched via the Autodesk help MCP): AutoCAD 2025 needs 64-bit Windows 11/10 1809+, ".NET 8", a DirectX 11 GPU minimum, and "DirectX 12 with Feature Level 12_0 is required for Shaded (Fast), Shaded with edges (Fast), and Wireframe (Fast) visual styles"; it also states "ARM Processors are not supported" [49]. AutoCAD 2027 raises this to Windows 11 only, 16 GB basic RAM and ".NET 10", keeping the DX12 FL 12_0 requirement for "Fast" styles [50]. The 2026 article was not retrievable here; search snippets report .NET 8 and the same DX12 FL 12_0 rule [51].

Implications for a Wine-based MIRRORZ: (1) modern AutoCAD is x86-64 only, so the ARM64 future needs a full x86-64 emulator (FEX-class), not just ARM64EC Wine; (2) the "Fast" visual styles need D3D12 FL 12_0, which on macOS today means D3DMetal or nothing (vkd3d over MoltenVK is not demonstrated at this level in any fetched source), while the non-Fast styles fall back to D3D11 where DXMT is viable; (3) Microsoft .NET 8/10 must be installed into the prefix (Wine-Mono does not satisfy modern .NET); (4) Autodesk's own licensing note says products may only be virtualized where terms permit, a contractual question MIRRORZ must check. Competitive context: AutoCAD 2025/2027 for Mac run natively on "Apple M series CPU" [49][50], so MIRRORZ's value must come from Windows-only toolsets (Map 3D, Electrical, MEP, Plant 3D are "Windows Only" per Autodesk) and Windows-only plug-ins. CodeWeavers' AutoCAD compatibility page and the WineHQ AppDB were unreachable; historical forum snippets describe most AutoCAD versions as poorly rated in Wine [54], so treat AutoCAD compatibility as unproven until tested.

## Strengths (what to match)

- **Upstream-first discipline (Hangover).** ~10 patches on top of Wine, with Box64's WoW DLL upstreamed, keeps rebasing cheap [29]. CrossOver's fork, by contrast, needs mirrors and custom configure flags [36][37].
- **Runtime-as-download (Whisky).** Small GPL app; versioned runtime tarball fetched from a CDN; per-bottle isolation [15][16].
- **Per-app renderer choice (Sikarugir).** WineD3D / D9VK / DXMT / D3DMetal / DXVK toggles per wrapper [22], with clear labeling of which components are LGPL and where the sources live [23].
- **Transparent LGPL practice (CodeWeavers).** Source tarballs per release at a public URL; proprietary value in the GUI, support and curated per-app fixes [38].
- **Emulator-in-a-DLL (Wine 10/11 + FEX).** Clean interface (`HKLM\Software\Microsoft\Wow64\amd64`), emulation only of app code [6].

## Weaknesses (what MIRRORZ must beat)

- **Rosetta dependence.** Every shipping open build is x86_64 and Rosetta-bound [8][17][22]; Apple limits Rosetta after macOS 27 [47].
- **DirectX 12 lock-in to Apple's non-commercial D3DMetal** [24]; DXMT stops at D3D11 [48].
- **Fragility and abandonment.** Whisky (archived 2025-05-11) [12], Mythic Engine (archived 2025-12-25) [20], Wine-GE (archived 2025-07-11) [34]; Gcenx is one person [8].
- **CrossOver 27 drops Intel Macs and 32-bit bottles (snippet) [40]**, which leaves legacy CAD plug-ins exposed; a product that keeps WoW64 32-bit support on ARM64 (as Hangover does with `libwow64fex.dll`/`wowbox64.dll` [30]) has a niche.
- **No public, productized macOS FEX.** CodeWeavers' Mac FEX is not published in any fetched source [33][39].

## Reusable code, ideas, and license implications for MIRRORZ

**Reuse as-is (LGPL, dynamically loaded, unmodified or lightly patched):** upstream Wine including `winemac.drv` [1][2]; Gcenx's build recipe (MacPorts deps, llvm-mingw, `--enable-archs`, tar.xz packaging) [8]; DXMT (note: post-0.80 versions are LGPL, so the same obligations apply) [48]; Hangover's build layout for ARM64EC + FEX/Box64 DLLs [30]; CrossOver's published Wine sources for app-specific fixes [36][38]. MIT components (FEX, Box64) can be embedded and even modified privately, though a Mac host port is MIRRORZ's own engineering [31][32].

**Must rewrite or license:** the launcher/bottle manager (Whisky is GPL-3.0, which would infect a closed app if its code were copied; treat it as a design reference only) [12]; Sikarugir's non-LGPL Launcher/Creator [22]; anything DX12-to-Metal (D3DMetal requires an Apple agreement; the public SLA forbids commercial distribution) [24]; a FEX host layer for macOS [33].

**LGPL 2.1 compliance checklist for a closed-source app bundling Wine** (text from COPYING.LIB [7]; this is analysis, not legal advice):
1. *Unmodified or modified Wine binaries are "the Library".* §4: you may distribute Wine "in object code or executable form... provided that you accompany it with the complete corresponding machine-readable source code"; offering the source "from the same place" as the binaries satisfies this. Any changes you make are themselves LGPL (§2). Practically: publish `mirrorz-wine-<version>-src.tar.xz` (Wine + all patches + build scripts) next to each release, as CodeWeavers does [38].
2. *Your GUI that execs `wine` as a separate process* is not linked with Wine; keep it that way and it stays outside the LGPL (§5 "work that uses the Library" only becomes a derivative when linked). Whisky (GPL) and CrossOver (proprietary) both use this process boundary.
3. *Any MIRRORZ code loaded inside Wine processes* (custom DLLs, a renderer, hooks) is a "work that uses the Library" linked at run time. §6 then requires: "prominent notice with each copy of the work that the Library is used in it" plus "a copy of this License", license terms that "permit modification of the work for the customer's own use and reverse engineering for debugging such modifications", and one of §6(a)-(e). The natural choice is §6(b): "use a suitable shared library mechanism... that... will operate properly with a modified version of the library, if the user installs one". Concretely: keep Wine's DLLs/dylibs as separate replaceable files, do not statically link Wine into your binaries, and do not enable hardened-runtime library validation or integrity checks that stop a user from swapping in a rebuilt Wine.
4. *Header-only use:* §5 allows unrestricted use of "numerical parameters, data structure layouts and accessors, and small macros and small inline functions (ten lines or less)"; larger header material makes your object code a derivative.
5. *EULA hygiene:* your EULA must not prohibit modification/relinking of the Wine parts or reverse engineering for debugging them (§6 preamble). Sikarugir's split of "Configure.app is LGPL, sources here; Launcher is not" is a compact worked example [22][23].

**How Whisky bundled GPTK, and what that means.** Whisky did not ask users to download GPTK from Apple: its `WhiskyWineDownloadView` fetches `https://data.getwhisky.app/Wine/Libraries.tar.gz` [15], and the maintainer confirmed GPTK 2 shipped "as of WhiskyWine 2.3.0" [18]; the tarball placed `D3DMetal.framework`/`libd3dshared.dylib` in `Libraries/Wine/lib/external` (snippet) [18]. That is defensible only because Apple's SLA lets "the Framework in its entirety" be distributed separately "subject to the non-commercial restriction" and Whisky was free [24]. A paid MIRRORZ cannot reuse this pattern.

**How CrossOver ships D3DMetal legally.** Apple's GPTK is "powered by CrossOver source code" (CodeWeavers blog, 2023-06-06, snippet) [42] and CrossOver has shipped D3DMetal commercially since 23.5 (2023), now D3DMetal 3.0 in CrossOver 26 (snippet) [41]. The terms of that Apple/CodeWeavers arrangement are not public in any fetched source; the only public license is the non-commercial SLA [24]. MIRRORZ's options: (a) negotiate directly with Apple's developer relations/games team; (b) partner with or license via CodeWeavers (its PortJump porting service is preparing its own post-Rosetta emulation, beta "by end-2026", snippet) [40]; (c) ship DXMT/DXVK only and accept no D3D12 "Fast" styles.

**Architectural lessons to carry over.** Build ARM64EC Wine + emulator DLLs now (Hangover recipe) and treat x86_64+Rosetta as a transitional universal-binary fallback, exactly as CrossOver's preview does [30][39]; version the runtime separately from the app (Whisky) [15]; expose renderer choice per bottle (Sikarugir) [22]; keep patches minimal and upstream them (Hangover) [29]; and budget for a Metal-native D3D12 story, because the CAD flagship's best visual styles need it [49].

## Open questions

1. Exact terms and cost of a commercial D3DMetal license from Apple; whether Apple will license it to a non-games CAD product.
2. Whether CodeWeavers will publish its macOS FEX host port (MIT FEX carries no obligation; the Wine side of CrossOver 27 will be LGPL and must be published).
3. Real AutoCAD 2025/2026 behaviour under DXMT vs D3DMetal (CodeWeavers' compatibility page and WineHQ AppDB were unreachable; no 2025-2026 first-hand report was fetched).
4. Whether Autodesk's license permits running AutoCAD under Wine on macOS (Autodesk's "virtualization" clause) [49].
5. CrossOver's current price list, verified from the store page rather than snippets [43].
6. Feasibility of a notarized, hardened-runtime Mac app that still satisfies LGPL §6(b) relinking (no fetched source demonstrates an App Store Wine product).
7. Wine-GE final release year (release page summary reported 2025-02-04; Lutris discussion snippet says February 2024) [35].

## Sources (numbered list of URLs with dates)

1. https://raw.githubusercontent.com/wine-mirror/wine/master/LICENSE (LGPL 2.1+; copyright 1993-2026; fetched 2026-09-03)
2. https://github.com/wine-mirror/wine/tree/master/dlls/winemac.drv (file listing; fetched 2026-09-03)
3. https://raw.githubusercontent.com/wine-mirror/wine/wine-11.0/ANNOUNCE.md (Wine 11.0 release notes, Jan 2026)
4. https://github.com/wine-mirror/wine/releases/tag/wine-11.0 (tagged 2026-01-13)
5. https://github.com/wine-mirror/wine/tags (wine-11.13 2026-07-10 ... wine-11.17 2026-09-04)
6. https://raw.githubusercontent.com/wine-mirror/wine/wine-10.0/ANNOUNCE.md (Wine 10.0 release notes, Jan 2025)
7. https://raw.githubusercontent.com/wine-mirror/wine/master/COPYING.LIB (LGPL 2.1 text, §4-§6)
8. https://github.com/Gcenx/macOS_Wine_builds (README; fetched 2026-09-03)
9. https://github.com/Gcenx/macOS_Wine_builds/releases (11.14-11.16 notes; "macOS Catalina and greater")
10. https://github.com/Gcenx/homebrew-wine (README cask list; fetched 2026-09-03)
11. https://github.com/Gcenx/game-porting-toolkit/releases/tag/Game-Porting-Toolkit-3.0-3 (2025-03-03)
12. https://github.com/Whisky-App/Whisky (GPL-3.0; archived 2025-05-11)
13. https://raw.githubusercontent.com/Whisky-App/Whisky/main/README.md (maintenance notice; CrossOver 22.1.1 + GPTK; macOS 14+, Apple silicon)
14. https://github.com/Whisky-App/Whisky/releases (v2.3.5, 2025-04-05)
15. https://raw.githubusercontent.com/Whisky-App/Whisky/main/Whisky/Views/Setup/WhiskyWineDownloadView.swift (Libraries.tar.gz URL)
16. https://raw.githubusercontent.com/Whisky-App/Whisky/main/WhiskyKit/Sources/WhiskyKit/WhiskyWine/WhiskyWineInstaller.swift (version plist, install folder)
17. https://raw.githubusercontent.com/Whisky-App/Whisky/main/Whisky/Views/Setup/RosettaView.swift (Rosetta check/install)
18. https://github.com/orgs/Whisky-App/discussions/1024 (GPTK 2 in WhiskyWine 2.3.0; D3DMetal file locations, snippet via mybyways.com)
19. https://www.macrumors.com/2025/04/23/whisky-ends-mac-gaming-tool-crossover/ (2025-04-23; snippet only, domain blocked)
20. https://github.com/MythicApp/Engine (LGPL; archived 2025-12-25)
21. https://github.com/MythicApp/wine (LGPL-2.1; branch mythic-crossover-24.0.7-stable)
22. https://github.com/Sikarugir-App/Sikarugir and https://raw.githubusercontent.com/Sikarugir-App/Sikarugir/main/README.md (fetched 2026-09-03)
23. https://github.com/Sikarugir-App/Sikarugir-foss-sources (LGPL-2.1 Configure sources)
24. https://github.com/Sikarugir-App/Sikarugir/blob/main/D3DMetal/3.0/License.pdf (Apple "Software License Agreement for Game Porting Toolkit", text extracted 2026-09-03)
25. https://github.com/Sikarugir-App/Wrapper/releases (templates through 1.0.15; KosmicKrisp v20260903)
26. https://github.com/Kegworks-App/Kegworks (redirects to Sikarugir; observed 2026-09-03)
27. https://wineformac.org/news/blog-kegworks-sikarugir-2025.html (rename, Oct 2025; snippet only)
28. https://github.com/AndreRH/hangover (LGPL-2.1; Linux ARM64 only)
29. https://github.com/AndreRH/hangover/releases (hangover-11.16, 2026-08-30; 11.0 notes)
30. https://github.com/AndreRH/hangover/blob/master/docs/COMPILE.md (build recipe)
31. https://github.com/FEX-Emu/FEX (MIT; Linux ARM64 host)
32. https://github.com/ptitSeb/box64 (MIT; Linux)
33. https://github.com/Jpkovas/FEX_MacOs (unofficial macOS FEX fork)
34. https://github.com/GloriousEggroll/wine-ge-custom (archived 2025-07-11; "UMU-LAUNCHER IS ITS SUCCESSOR")
35. https://github.com/GloriousEggroll/wine-ge-custom/releases (GE-Proton8-26)
36. https://github.com/marzent/winecx (LGPL-2.1 mirror of CrossOver sources; branch ff-wine-9.12)
37. https://gist.github.com/sarimarton/471e9ff8046cc746f6ecb8340f942647 (building CrossOver 20 sources on macOS; 2023-01-22)
38. https://www.codeweavers.com/crossover/source (blocked; snippet: LGPL sources at media.codeweavers.com/pub/crossover/source/)
39. https://www.codeweavers.com/blog/mjohnson/2026/7/31/crossover-preview-the-right-to-bear-arm64-on-mac (2026-07-31; snippet only)
40. https://www.codeweavers.com/blog/mjohnson/2026/6/11/whats-in-and-whats-out-for-crossover-27 and https://www.codeweavers.com/blog/orudge/2026/6/19/portjump-update-upcoming-changes-to-macos-support-for-intel-based-applications (June 2026; snippets only)
41. https://www.codeweavers.com/blog/mjohnson/2026/2/10/crossover-26-cures-artificial-incompatibility-with-windows-games-on-mac (2026-02-10; snippet only)
42. https://www.codeweavers.com/blog/mjohnson/2023/6/6/wine-comes-to-macos-apple-s-game-porting-toolkit-powered-by-crossover-source-code (2023-06-06; snippet only)
43. https://www.codeweavers.com/store/ (blocked; snippet: CrossOver+ 1-year $74)
44. https://machow2.com/crossover-mac-review/ (blocked; snippet: CrossOver 26.3 on 2026-07-21; tiers)
45. https://developer.apple.com/games/game-porting-toolkit/ (GPTK 4; fetched 2026-09-03)
46. https://github.com/apple/game-porting-toolkit (Apache-2.0; skills/samples only)
47. https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment (Rosetta "through macOS 27"; fetched via the docs JSON endpoint 2026-09-03)
48. https://github.com/3Shain/dxmt, https://github.com/3Shain/dxmt/tags and https://github.com/3Shain/dxmt/releases/tag/v0.80 (v0.80 2026-04-23; MIT to LGPL)
49. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html (via Autodesk Product Help MCP, 2026-09-03)
50. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html (via Autodesk Product Help MCP, 2026-09-03)
51. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2026-including-Specialized-Toolsets.html (snippet only)
52. https://forum.winehq.org/viewtopic.php?t=37004 (WoW64 32-bit on Mac; snippet only)
53. https://forums.macrumors.com/threads/wine-on-apple-silicon.2251712/ (32-bit code segments under Rosetta; snippet only)
54. https://www.codeweavers.com/compatibility/crossover/autocad and https://forum.winehq.org/viewtopic.php?t=13358 (blocked; historical AutoCAD ratings, snippet only)
