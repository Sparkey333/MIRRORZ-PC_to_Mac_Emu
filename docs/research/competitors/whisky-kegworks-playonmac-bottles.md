# Free Wine Front-Ends for macOS: Whisky, Kegworks/Sikarugir, PlayOnMac, Porting Kit, Bottles, Heroic (and the 2025-2026 successors)

_Research date: 2026-09-03_

_Method note: the research proxy blocked most non-GitHub domains (getwhisky.app, appleinsider, macrumors, codeweavers, heise, playonmac.com, portingkit.com, paulthetall.com, wineformac.org, docs.usebottles.com, reddit/HN). All versions, dates and statuses below come from GitHub-hosted primary sources (repos, READMEs, releases, Homebrew casks, commit logs), Apple's developer site or Autodesk's help center, fetched 2026-09-03. Facts seen only in search snippets of blocked pages are marked "(snippet only, unverified)"._

## TL;DR (5 bullets)

- **Whisky is dead upstream, but not as an idea.** Author Isaac Marovitz's maintenance notice (April 2025) says Whisky "has not been a positive on the Wine community", that "the revenue from CrossOver is what keeps Wine on Mac alive", and tells users to buy CrossOver; last upstream release v2.3.5 (5 Apr 2025), repo archived 11 May 2025 [1][2][4]. A GPL-3.0 community fork (frankea/Whisky) shipped "Whisky 3.7.0" on 30 Aug 2026 with a Wine 11.16 runtime, DXMT/DXVK, per-program backends, launcher support and a game library; macOS 15+, Apple Silicon only [10][11].
- **Kegworks was renamed Sikarugir on 9 Aug 2025** (tap commit "Update and rename kegworks.rb to sikarugir.rb"). It is the Wineskin lineage (doh123 -> Gcenx -> Kegworks 2.0.3/2.0.4 -> Sikarugir Creator 1.0/1.0.1): Creator.app builds self-contained `.app` wrappers with an LGPL-2.1 Configure.app inside, selectable renderers (WineD3D / D9VK / DXMT / D3DMetal / DXVK) and a catalogue of engines (CrossOver 19-24, Wine 10/11, GPTK 1.1). macOS 14+, Rosetta 2 required. Its README says it "is not a replacement for CrossOver or Whisky" [12][13][14][16][17].
- **The critical licensing fact for MIRRORZ**: Sikarugir's README says Apple's D3DMetal "commonly refered to as GPTK is closed source and has a restrictive license, it can not be used for commerial ports" [12]. Apple's GPTK is a developer evaluation tool (now "Game Porting Toolkit 4" on developer.apple.com) [22]. A commercial product cannot simply bundle D3DMetal; the open alternatives are DXMT (D3D10/11 on Metal), DXVK/MoltenVK, D9VK and WineD3D.
- **PlayOnMac, Bottles and Porting Kit are not real threats.** PlayOnMac 4's last release is 4.4 (17 May 2024) with only trivial Python fixes since (last commit 22 Feb 2026); its successor Phoenicis has had no tag since 5.0-alpha.3 (29 Sep 2020) [26][27]. Bottles is Linux-only (latest 67.2, 3 Sep 2024; "Bottles Next" rewrite in progress, still no macOS repo) [31]. Porting Kit is a free wrapper catalogue at v6.7.0 (19 Nov 2024) with separate ARM and Intel DMGs [23][24]. Heroic (GPLv3, 2.22.1 on 9 Aug 2026, macOS 14+) is a game-store launcher whose Wine Manager downloads Wine-Crossover, Wine-Staging or GPTK builds, and added DXMT in 2.21.0 (22 Apr 2026) [28][29][30].
- **None of these tools target CAD.** Whisky's docs are 100% games and neither Sikarugir's nor Whisky's trackers mention AutoCAD/Revit/SolidWorks; Autodesk confirms AutoCAD for Mac is "not straight 1:1 ports" and lacks Windows-only features (QuickCalc, Sheet Set Manager, Classic toolbars, TCOUNT) [33]. A supported, commercially licensable, productivity-first Wine front-end is the space Whisky's author said only CrossOver occupies.

## Current status (version, date, maintainer, momentum)

| Project | Latest version / date (verified) | Maintainer | Status in Sept 2026 |
|---|---|---|---|
| **Whisky (upstream)** | v2.3.5, 5 Apr 2025 ("Fixed configuration view crashes on macOS 15.4") [2] | Isaac Marovitz | README: "Whisky is no longer actively maintained. Apps and games may break at any time." Repo archived 11 May 2025; 15.1k stars; whisky-book docs archived 17 Nov 2025 [1][3][9] |
| **Whisky (frankea fork)** | Whisky 3.7.0, 30 Aug 2026; Wine Libraries v4.6.4-beta.1 (Wine 11.16), 29 Aug 2026 [11] | @frankea (community) | Very active; 584 stars; macOS 15+; distributed via `brew install --cask frankea/whisky/whisky`, notarized DMG, Sparkle updates [10] |
| **Kegworks -> Sikarugir** | Creator v1.0.1 (cask 21 Jan 2026; tap touched 4 Aug 2026); Wrapper Template 1.0.14 [13][14][16][17] | Gcenx (engines, README), VitorMM (code), PaulTheTall (testing) | Active: README commits to 3 Sep 2026, discussions Aug 2026, 3.6k stars; binaries live in Creator/Wrapper/Engines repos and the tap [12][15] |
| **PlayOnMac (POL-POM-4)** | 4.4, 17 May 2024 [26] | qparis (PlayOnLinux) | Dormant maintenance: commits 22 Feb 2026 / 5 Jan 2026 are one-line Python 3.10 syntax fixes. README points contributors to Phoenicis [26] |
| **Phoenicis (PlayOnLinux/PlayOnMac 5)** | 5.0-alpha.3, 29 Sep 2020 [27] | PhoenicisOrg | Effectively stalled: only dependabot/translation-bot commits (last 28 Jan 2025) [27] |
| **Porting Kit** | 6.7.0, 19 Nov 2024 (GitHub release mirror; Homebrew cask matches) [23][24] | PaulTheTall / vitor251093 | Free (snippet only, unverified - site blocked); ARM and Intel DMGs [23] |
| **Bottles** | 67.2, 3 Sep 2024 [31] | bottlesdevs | Linux-only; "Bottles Next" rewrite repos updated Sep 2026, no macOS target found [31] |
| **Heroic Games Launcher** | 2.22.1, 9 Aug 2026 [29] | Heroic team | Active; GPLv3; macOS 14+; Wine Manager offers Wine-Crossover, Wine-Staging, GPTK; DXMT for M-series since 2.21.0 (22 Apr 2026) [28][29][30] |
| **Mythic** | v0.6.0 "The World", 27 Dec 2024 (pre-release); commits through 12 Feb 2026 [32] | vapidinfinity + community | GPL-3.0 (LICENSE.md, Dec 2025); macOS 14+; Epic + manual imports; Steam "in development"; 1.4k stars [32] |
| **Apple GPTK** | Apple: "Game Porting Toolkit 4" (2026) [22]; Gcenx community builds 3.0, 3.0-1/-2/-3; tap cask 3.0-2 (25 Feb 2026) [19][20] | Apple / Gcenx | Evaluation tool behind an Apple Developer download; Apple's own formula is still 1.1 from crossover-sources-22.1.1, x86_64 only [21] |

**Date caveat on GPTK community builds:** the Gcenx releases page as summarised gave "3.0 = 5 Dec 2024" and betas in 2024, which is impossible because Apple announced GPTK 3 at WWDC in June 2025. The explicitly-dated homebrew-wine commit log (2.1 in Mar 2025; 3.0-beta1 Jun 2025 ... beta5 Oct 2025; cask updates Dec 2025 and 25 Feb 2026) and Sikarugir's README commit "D3DMetal-v3.0" on 5 Dec 2025 show the real sequence is 3.0 = Dec 2025, 3.0-1/-2 = Feb 2026, 3.0-3 = Mar 2026 [19][20][12].

## Pricing and licensing (table)

| Project | Price | Licence | Notes |
|---|---|---|---|
| Whisky (upstream + frankea fork) | Free | GPL-3.0 [1][10] | Bundled runtime = CrossOver 22.1.1 sources + GPTK + DXVK-macOS + MoltenVK + D3DMetal [3]. D3DMetal is Apple's closed component. |
| Sikarugir (ex-Kegworks) | Free | Mixed: Configure.app (modified Wineskin) LGPL-2.1; "Sikarugir Launcher" and "Creator.app (v1.0.1+)" explicitly "don't fall under LGPL-2.1" [12] | README: D3DMetal "can not be used for commerial ports" [12]. Kegworks-era README said the same [18]. |
| PlayOnMac 4 / Phoenicis | Free | GPL-3.0 / LGPL-3.0 [26][27] | |
| Porting Kit | Free (snippet only, unverified) | Not published on GitHub (binary-only release mirror) [24] | |
| Bottles | Free | GPL-3.0 [31] | Linux only. |
| Heroic | Free | GPLv3 [30] | |
| Mythic | Free | GPL-3.0 [32] | README carries "Copyright (c) 2023-2025 vapidinfinity. All rights reserved." alongside the GPL file. |
| CrossOver (for reference, from Whisky's own docs) | Whisky's notice cites "$74" as the up-front licence price and stresses it is "not a subscription" and upgrades cost less [4] | Proprietary | The only supported commercial option Whisky's author endorses. |
| Apple GPTK / D3DMetal | Free download for Apple Developer accounts [22] | Apple licence (License.pdf shipped with GPTK; Gcenx builds say users must "comply with Apple's License.pdf for D3DMetal") [19] | Evaluation-only positioning; Sikarugir reads it as non-commercial. |

## How it works (architecture)

**Whisky (SwiftUI bottle manager).** A native SwiftUI app around a bundled runtime ("WhiskyWine"): CrossOver 22.1.1 sources with Apple's GPTK patches, DXVK-macOS, MoltenVK and D3DMetal [3]. First-run flow (`WelcomeView`, `RosettaView`, `WhiskyWineDownloadView`, `WhiskyWineInstallView`) checks Rosetta 2 and downloads the runtime [8]. The UI is bottle-centric: `BottleCreationView`, `BottleListEntry`, `BottleView`, `ConfigView`, `RunningProcessesView`, `WinetricksView`, plus pinned programs [8]. The author's notice admits the original goal was to be "engine agnostic, simply serve as a frontend for Wine, and not provide a bundled version itself. That all changed when GPTK came out at WWDC" [4]. The frankea fork keeps the model but ships its own upstream-Wine 11.x "Wine Libraries", per-program backend routing and a library screen [11].

**Sikarugir / Kegworks (Wineskin lineage: one wrapper per app).** **Creator.app** produces a standalone macOS `.app` containing a Wine prefix, a chosen **engine** and an LGPL **Configure.app** (the modified Wineskin) for later tweaks; the "Sikarugir Launcher" runs it in "wineskinlauncher compatibility mode" [12][16]. Engines are downloadable tarballs in Wineskin naming: `WS12WineCX24.0.7_7`, `WS12WineCX23.7.1_4`, `WS12WineSikarugir10.0_6`, `WS12WhiskyWine2.5.0_3`, `WS12WineGPTK1.1_3`, `WS11WineSikarugir11.0`, `WS11WineCX21.2.0/20.0.4/19.0.2` (+32-bit variants) [17]. Renderers are per-wrapper toggles: WineD3D (DX8 and below), D9VK (DX9), DXMT (DX10/11 on Metal) as defaults; D3DMetal (64-bit DX11/12, Apple Silicon) and DXVK as toggles [12]. Wrapper templates 1.0-1.0.14 bundle DXMT, GStreamer, libsdl2 and D3DMetal; 1.0.13 fixed "black screen with CEF based launchers below macOS 26" [16]. Requires macOS 14+ and Rosetta 2 [12]; the Kegworks-era README supported macOS 10.15.4+ [18].

**Heroic.** Electron launcher whose macOS Wine Manager downloads Wine-Crossover (CrossOver 23 based, no DX12), Wine-Staging/Devel (Wined3d/DXVK/DXMT) or Game Porting Toolkit (D3DMetal, "only runs on Apple Silicon chips"); Rosetta 2 is required (missing Rosetta = "Error: spawn Unknown system error -86") [28].

**Apple GPTK.** Apple's Homebrew formula builds Wine from `crossover-sources-22.1.1.tar.gz`, x86_64 only; the D3DMetal libraries come from the Apple Developer download [21]. Gcenx's community tarballs add GStreamer and require Sonoma + Rosetta [19][20]. Apple's page now advertises "Game Porting Toolkit 4" with Metal 4, Metal Performance HUD/Debugger/System Trace and the Metal Shader Converter [22]. PlayOnMac 4 is a script-driven Wine installer for "GNU/Linux and macOS" [26]; Bottles is a Linux Flatpak prefix manager [31]; Porting Kit is a catalogue of pre-made wrappers with ARM and Intel builds [23].

## Feature checklist (table: feature | status | notes)

| Feature | Whisky (upstream) | Whisky (frankea 3.7) | Sikarugir | Heroic | PlayOnMac 4 | Porting Kit | Bottles |
|---|---|---|---|---|---|---|---|
| Apple Silicon native app | Yes (AS only) [1] | Yes (AS only, macOS 15+) [10] | App yes; Wine needs Rosetta 2 [12] | Yes; Rosetta 2 for Wine [28] | Rosetta (snippet only) | ARM + Intel DMGs [23] | n/a (Linux) |
| Intel Macs | No [1] | No [10] | Yes (macOS 14+) [12] | Yes, no GPTK [28] | Yes | Yes [23] | n/a |
| Bundled engine | CrossOver 22.1.1 + GPTK [3] | Wine 11.16 + D3DMetal + DXMT [11] | Engine catalogue (CX 19-24, Wine 10/11, GPTK 1.1) [17] | Downloadable (Wine-Crossover, Staging, GPTK) [28] | Downloadable Wine | Bundled per port | Linux runners |
| DX11/12 via D3DMetal | Yes [3] | Yes (Metal 4 encoding, MetalFX by default) [11] | Toggle, AS only [12] | GPTK option [28] | No evidence | Unknown | No |
| DXMT (open D3D11-on-Metal) | No | Yes [10] | Yes, default [12] | Yes since 2.21.0 [29] | No | Unknown | No |
| DXVK / MoltenVK | Yes [3] | Yes [10] | Toggle [12] | Yes [28] | No evidence | Unknown | Yes (Linux) |
| Per-bottle config (Win version, esync/msync, Retina, DPI, AVX, Metal HUD/Trace, DXR) | Yes [7] | Yes + per-program backend [11] | Via Configure.app inside wrapper [12] | Per-game settings | Basic | Fixed per port | Yes |
| Winetricks UI | Yes [8] | Yes | Yes (own winetricks fork) [13] | Yes | Yes | Unknown | Yes |
| Standalone .app export | No | No | Core feature [12] | No | Yes (shortcuts) | Yes (ports) | Yes (Linux) |
| Store launchers (Steam/Epic/EA/Battle.net) | Steam only, unsupported [5] | Steam, Epic, EA, Rockstar, Battle.net [10] | Templates fix CEF launchers [16] | Epic/GOG/Amazon native [30] | Scripts | Catalogue | Linux |
| Curated compatibility database | ~250 game pages in whisky-book [6] | "80+ game configurations" [10] | None (community discussions) | None | Scripts | Port catalogue | Yes (Linux) |
| Non-game / productivity focus | No | No | Partially (generic wrapper) | No | Some | Some | Some |
| Support / SLA | None [5] | Community | Community | Community | None | Community | Community |
| Commercially licensable stack | No (D3DMetal) | No (D3DMetal) | No (D3DMetal) unless disabled | No | Wine only | Unknown | Yes (Linux) |

## CAD / AutoCAD relevance

- None of the front-ends surveyed markets or documents CAD workloads. Whisky's documentation table of contents is exclusively games (roughly 250 titles) [6]; searches of the Whisky discussions and the Sikarugir issue tracker for "AutoCAD / CAD / SolidWorks / Revit" returned nothing [12-fetch, 1-fetch]. This is a research gap, not proof that AutoCAD fails, but it means no free front-end offers a recipe, a tested engine or a support path for CAD users.
- Autodesk's own help article "Compare Features: AutoCAD for Windows against AutoCAD for Mac" states that Mac editions "are not straight 1:1 ports", and lists Windows-only items such as QuickCalc, Lookup for Block tables, the Classic interface with toolbars, the Sheet Set Manager (Mac has a limited Project Manager), the GEOMAP/Bing maps feature, and Express Tools like TCOUNT; its suggested workaround for a missing feature is literally to install Windows via Boot Camp [33]. That is the demand MIRRORZ addresses on Apple Silicon, where Boot Camp no longer exists.
- Implication: a CAD stack needs D3D11 (DXMT/DXVK) and solid .NET support in Wine, not D3DMetal (DX12-focused and non-commercial). Sikarugir's CrossOver 24.0.7 / Wine 11 engines plus DXMT are the closest free approximation, with no CAD-specific fixes.

## Strengths (what to match)

1. **Zero-friction onboarding** (Whisky): Welcome -> Rosetta check -> runtime download -> install; then "press the plus button, name your bottle, select Windows version, then hit Create" and one "Run..." button [6][8].
2. **A compact, opinionated config panel** (Whisky `ConfigView`): Wine (Windows version, build, Retina, Enhanced Sync none/esync/msync, DPI sheet with 96-480 slider and live preview, AVX toggle with warning), DXVK (enable, async, HUD), Metal (HUD, Trace, DXR on Apple family 9 GPUs), plus Control Panel / Regedit / Winecfg escape hatches [7].
3. **Per-program graphics-backend routing, resumable runtime downloads, a library screen with artwork and running status, `whisky://` launch URLs and drag-and-drop .exe** (frankea 3.6.1-3.7.0) [11].
4. **Standalone app wrappers with swappable, versioned engines and templates** (Sikarugir) [12][16][17]; **an engine manager that states each engine's limits** (Heroic) [28].
5. **Honest documentation**: Whisky's "Whisky vs CrossOver" table lists what it lacks - automated installation, Denuvo, Epic/Battle.net/Ubisoft support, Wine 9, "Proper Technical Support", "Regular Updates to Wine" [5] - a ready-made spec for a paid product. Community compatibility databases (~250 whisky-book pages; frankea's "80+ game configurations") [6][10].

## Weaknesses (what MIRRORZ must beat)

1. **Sustainability**: the most popular tool (15.1k stars) was a solo student project that ended because it was "incredibly time-consuming" and unpaid [4]; successors are hobby projects (frankea 584 stars; Sikarugir 3.6k) with "won't receive support" engine policies [10][17].
2. **Licensing fragility**: every fast DX11/12 path relies on D3DMetal, which Sikarugir says "can not be used for commerial ports" [12]; Whisky's runtime is CrossOver 22.1.1-era code [3]. A commercial product must build on LGPL Wine + DXMT/DXVK/MoltenVK, or license from CodeWeavers.
3. **Rosetta dependency and macOS churn**: all engines need Rosetta 2 on Apple Silicon [12][28]; macOS 15.4 broke Whisky's config view [2]; Sikarugir's maintainer will not predict macOS 28 "without a macOS 28 developer beta" (though "Compiling Sikarugir itself for arm64 is none issue") [15].
4. **No automated installers or app-specific fixes** - Whisky marks these as CrossOver-only [5] - and a **games-only mental model** (libraries, controllers, store launchers; nothing for .dwg associations, printing, licensing helpers or fleet deployment).
5. **A confusing landscape**: Wineskin -> Kegworks -> Sikarugir in two years, an unaffiliated "sikarugir.com" the README warns may be malware, and two "Whisky"s [12][13][10]. PlayOnMac/Phoenicis (2020 alpha) and Bottles (Linux-only) are not credible on modern Macs [26][27][31].

## Reusable code, ideas, and license implications for MIRRORZ

- **GPL-3.0 code (Whisky upstream and fork, Mythic, Heroic, Bottles)** cannot be linked into a proprietary app. Safe use: copy the UX and behaviours - ConfigView layout, setup flow, bottle model, `whisky://` scheme, resumable runtime download, Sparkle updates, bottle migration from the archived app, and the `whisky games` / `whisky launch` CLI - and re-implement [6][7][8][11].
- **LGPL-2.1 code (Wine, Sikarugir's Configure.app/Wineskin, Winetricks)** is usable commercially if kept as separately replaceable components with LGPL obligations met. Sikarugir's engine packaging (`WS12WineCX24.0.7_7` tarballs + template wrapper) is a proven pattern for shipping and hot-swapping engines [17]. Sikarugir's Launcher and Creator.app are explicitly outside LGPL-2.1 with no published licence - do not copy [12].
- **Permissive components** (DXVK and D9VK: Zlib; MoltenVK: Apache-2.0) are bundle-able with attribution [13]. **DXMT** is the key open D3D11-on-Metal path, already default in Sikarugir and offered by Heroic and the Whisky fork [12][28][10]; verify its licence file before bundling (not fetched).
- **D3DMetal / GPTK**: treat as unavailable for a shipped product. Options: (a) DXMT + DXVK/MoltenVK only; (b) a CodeWeavers licensing/OEM deal (CrossOver is the source of Whisky's runtime and GPTK's Wine); (c) GPTK as a user-installed, user-licensed optional engine, as Heroic and Sikarugir do - with legal review [3][19][22].
- **Engine supply chain**: Homebrew's `wine-stable` is 11.0_1 built by Gcenx (requires Rosetta) [25], and Gcenx also produces the community GPTK and CrossOver-source builds [19][20] - one volunteer feeds every free front-end. MIRRORZ should own its Wine build pipeline; Whisky's archived `WhiskyBuilder`/`wine` repos show the shape [9].
- **Distribution**: notarized DMG + Homebrew cask + Sparkle appcast; bottles stored outside the app so they survive uninstall; an importer for orphaned Whisky bottles [10].

## Open questions

1. Exact text/date of the getwhisky.app notice (blocked); the whisky-book notice is undated but references macOS 15.4 (fixed 5 Apr 2025) and press coverage clusters 16-23 Apr 2025 (AppleInsider, CodeWeavers, MacRumors - not fetched).
2. Rationale for Kegworks -> Sikarugir: a wineformac.org post claims "October 2025", but the Homebrew tap shows the rename on 9 Aug 2025; README history under the current name only reaches 26 Apr 2025.
3. Licence text of Sikarugir Creator.app/Launcher ("don't fall under LGPL-2.1"; the referenced "FOSS repository" was not located) and the exact wording of Apple's D3DMetal License.pdf.
4. Porting Kit's pricing/engines and PlayOnMac's current site version (sites blocked).
5. Any documented AutoCAD run under Sikarugir/Whisky/CrossOver (WineHQ AppDB and CodeWeavers forums blocked); DXMT's licence and D3D11 coverage for CAD workloads.
6. Other 2025-2026 entrants named only in blocked round-ups - "MacWrap" (free beta; no GitHub repo found) and "Pixel Port" (paid one-click service) - snippet only, unverified.

## Sources (numbered list of URLs with dates)

1. Whisky GitHub repo (archived 11 May 2025; 15.1k stars; GPL-3.0; macOS 14+/Apple Silicon) - https://github.com/Whisky-App/Whisky - fetched 2026-09-03
2. Whisky releases (v2.3.5, 5 Apr 2025; v2.3.4, 10 Nov 2024) - https://github.com/Whisky-App/Whisky/releases - fetched 2026-09-03
3. Whisky README (raw; components CrossOver 22.1.1, GPTK, DXVK-macOS, MoltenVK, D3DMetal) - https://raw.githubusercontent.com/Whisky-App/Whisky/main/README.md - fetched 2026-09-03
4. Whisky "Maintenance Notice" by Isaac Marovitz (whisky-book; repo archived 17 Nov 2025) - https://raw.githubusercontent.com/Whisky-App/whisky-book/main/src/maintenance-notice.md - fetched 2026-09-03
5. Whisky "Whisky or CrossOver?" comparison - https://raw.githubusercontent.com/Whisky-App/whisky-book/main/src/cx.md - fetched 2026-09-03
6. Whisky user guide and table of contents - https://raw.githubusercontent.com/Whisky-App/whisky-book/main/src/guide.md and .../src/SUMMARY.md - fetched 2026-09-03
7. Whisky ConfigView.swift (settings inventory) - https://github.com/Whisky-App/Whisky/blob/main/Whisky/Views/Bottle/ConfigView.swift - fetched 2026-09-03
8. Whisky Views/Setup and Views/Bottle listings - https://github.com/Whisky-App/Whisky/tree/main/Whisky/Views/Setup and .../Views/Bottle - fetched 2026-09-03
9. Whisky-App organisation repositories (WhiskySite updated 14 Jun 2026; whisky-book archived 17 Nov 2025; WhiskyBuilder archived 6 Apr 2024) - https://github.com/orgs/Whisky-App/repositories - fetched 2026-09-03
10. frankea/Whisky README (community fork; macOS 15+; GPL-3.0; 584 stars) - https://github.com/frankea/Whisky and https://raw.githubusercontent.com/frankea/Whisky/main/README.md - fetched 2026-09-03
11. frankea/Whisky releases (Whisky 3.7.0, 30 Aug 2026; 3.6.1, 13 Aug 2026; 3.6.0, 4 Aug 2026; Wine Libraries v4.6.4-beta.1, 29 Aug 2026) - https://github.com/frankea/Whisky/releases - fetched 2026-09-03
12. Sikarugir README (macOS 14+, Rosetta 2, renderer list, licence sections, D3DMetal restriction, "not a replacement for CrossOver or Whisky"; README commits to 3 Sep 2026, "D3DMetal-v3.0" commit 5 Dec 2025) - https://github.com/Sikarugir-App/Sikarugir and https://raw.githubusercontent.com/Sikarugir-App/Sikarugir/main/README.md - fetched 2026-09-03
13. Sikarugir-App organisation (Sikarugir 3,579 stars; Creator, Engines, Wrapper; forks of MoltenVK, dxvk, dxmt, d9vk, wine, winetricks) - https://github.com/Sikarugir-App - fetched 2026-09-03
14. Sikarugir Homebrew tap: cask (Creator v1.0.1, depends on Sonoma, requires Rosetta) and commit history ("Create Kegworks-App/kegworks tap" 21 Mar 2025; "kegworks: update to 2.0.4" 11 Apr 2025; "Update and rename kegworks.rb to sikarugir.rb" 9 Aug 2025; "sikarugir: update to v1.0.1" 21 Jan 2026; last commit 4 Aug 2026) - https://raw.githubusercontent.com/Sikarugir-App/homebrew-sikarugir/main/Casks/sikarugir.rb and https://github.com/Sikarugir-App/homebrew-sikarugir/commits/main - fetched 2026-09-03
15. Sikarugir discussion #228 "Prospects for this app under macOS 27 and macOS 28?" (23 May 2026) - https://github.com/orgs/Sikarugir-App/discussions/228 - fetched 2026-09-03
16. Sikarugir Wrapper releases (v1.0, 3 Oct 2024; templates 1.0-1.0.14; 1.0.13 CEF fix "below macOS 26") and Creator releases (v2.0.3 pre-release 4 Oct; v2.0.4 11 Apr; v1.0 13 Aug; v1.0.1 21 Jan) - https://github.com/Sikarugir-App/Wrapper/releases and https://github.com/Sikarugir-App/Creator/releases - fetched 2026-09-03
17. Sikarugir Engines (release v1.0, 3 Oct 2024, "won't receive support") and EngineList.txt - https://github.com/Sikarugir-App/Engines/releases and https://raw.githubusercontent.com/Sikarugir-App/Engines/main/EngineList.txt - fetched 2026-09-03
18. Kegworks README snapshot (fork; macOS 10.15.4+; `Kegworks-App/kegworks` tap; D3DMetal restriction) - https://github.com/gxgl/Kegworks - fetched 2026-09-03
19. Gcenx game-porting-toolkit releases (tags 1.1, 1.1-gstreamer, 2.1, 3.0-beta3..beta5, 3.0, 3.0-1, 3.0-2, 3.0-3; Sonoma+, 16 GB recommended; "comply with Apple's License.pdf for D3DMetal") - https://github.com/Gcenx/game-porting-toolkit/releases - fetched 2026-09-03
20. Gcenx homebrew-wine: cask game-porting-toolkit.rb (3.0-2, Sonoma, Rosetta) and commit log (2.1 Mar 2025; 3.0-beta1 Jun 2025 ... beta5 Oct 2025; updates 5 Dec 2025, 25 Feb 2026; wine-crossover cask removed 16 Apr 2026; last commit 9 Jun 2026) - https://raw.githubusercontent.com/Gcenx/homebrew-wine/master/Casks/game-porting-toolkit.rb and https://github.com/Gcenx/homebrew-wine/commits/master - fetched 2026-09-03
21. Apple homebrew-apple formula game-porting-toolkit.rb (version 1.1; crossover-sources-22.1.1; x86_64 only; LGPL-2.1+) - https://raw.githubusercontent.com/apple/homebrew-apple/main/Formula/game-porting-toolkit.rb - fetched 2026-09-03
22. Apple Developer, Game Porting Toolkit page ("Game Porting Toolkit 4", Metal 4, Metal Shader Converter; (c) 2026) - https://developer.apple.com/games/game-porting-toolkit/ - fetched 2026-09-03
23. Homebrew cask porting-kit.rb (version 6.7.0; ARM and Intel DMGs from vitor251093/porting-kit-releases) - https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/p/porting-kit.rb - fetched 2026-09-03
24. Porting Kit release v6.7.0 (19 Nov 2024) and release list - https://github.com/vitor251093/porting-kit-releases/releases/tag/v6.7.0 - fetched 2026-09-03
25. Homebrew cask wine-stable.rb (11.0_1; Gcenx macOS_Wine_builds; requires Rosetta) - https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/w/wine-stable.rb - fetched 2026-09-03
26. PlayOnLinux/POL-POM-4 repo (GPL-3.0; "PlayOnLinux and PlayOnMac 4"; points to Phoenicis), releases (4.4, 17 May 2024), commits (22 Feb 2026, 5 Jan 2026, 7 Nov 2025) - https://github.com/PlayOnLinux/POL-POM-4 , /releases , /commits/master - fetched 2026-09-03
27. PhoenicisOrg/phoenicis repo (LGPL-3.0; Linux and macOS), tags (5.0-alpha.3, 29 Sep 2020), commits (28 Jan 2025) - https://github.com/PhoenicisOrg/phoenicis , /tags , /commits/master - fetched 2026-09-03
28. Heroic wiki "Using Heroic on a Mac computer" (last updated 20 Apr 2026) - https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/wiki/Using-Heroic-on-a-Mac-computer - fetched 2026-09-03
29. Heroic releases (2.22.1, 9 Aug 2026; 2.22.0, 16 May 2026; 2.21.0, 22 Apr 2026 with DXMT) - https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases - fetched 2026-09-03
30. Heroic README (GPLv3; macOS 14+; Homebrew cask) - https://raw.githubusercontent.com/Heroic-Games-Launcher/HeroicGamesLauncher/main/README.md - fetched 2026-09-03
31. Bottles repo (Linux; GPL-3.0; 8.8k stars), releases (67.2, 3 Sep 2024), bottlesdevs org (bottles-next et al.) - https://github.com/bottlesdevs/Bottles , /releases , https://github.com/orgs/bottlesdevs/repositories - fetched 2026-09-03
32. MythicApp/Mythic repo, releases (v0.6.0, 27 Dec 2024, pre-release), commits (12 Feb 2026), LICENSE.md (GPL-3.0), README (macOS 14+) - https://github.com/MythicApp/Mythic , /releases , /commits/main , https://raw.githubusercontent.com/MythicApp/Mythic/main/LICENSE.md - fetched 2026-09-03
33. Autodesk, "Compare Features: AutoCAD for Windows against AutoCAD for Mac" (via Autodesk Product Help MCP) - https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Compare-Features-AutoCAD-for-Windows-vs-AutoCAD-for-Mac.html - fetched 2026-09-03
34. Search-result snippets only (pages blocked, not fetched): AppleInsider "Whisky development ends on macOS to help Wine flourish" (16 Apr 2025) https://appleinsider.com/articles/25/04/16/whisky-development-ends-on-macos-to-help-wine-flourish ; CodeWeavers blog "Whisky's Legacy" (18 Apr 2025) https://www.codeweavers.com/blog/jramey/2025/04/18/whisky-s-legacy-and-the-spirit-it-leaves-behind ; MacRumors (23 Apr 2025) https://www.macrumors.com/2025/04/23/whisky-ends-mac-gaming-tool-crossover/ ; wineformac.org "Kegworks Renamed to Sikarugir" https://wineformac.org/news/blog-kegworks-sikarugir-2025.html ; blog.apps.deals "Whisky Alternatives for Mac" https://blog.apps.deals/whisky-alternatives-mac ; paulthetall.com "New Porting Kit ... ARM version" https://www.paulthetall.com/new-porting-kit-has-landed-including-arm-version-for-apple-silicon/
