# CrossOver Mac (CodeWeavers) — Competitor Profile

_Research date: 2026-09-03_

> Sourcing note: during this research session the network egress policy blocked direct fetches of `codeweavers.com`, `support.codeweavers.com`, `media.codeweavers.com`, the Wayback Machine and most tech-press domains. Facts attributed to those pages were obtained from search-engine extracts of the named URL (marked **[via search]**) rather than a full page fetch. GitHub, Apple's developer site and Autodesk's knowledge base were fetched directly. Every price, version and date below carries its source; nothing is stated from memory.

## TL;DR

- **Current shipping version is CrossOver 26.3.0 (2026-07-21)** on the CrossOver 26 line, which launched 2026-02-10 on **Wine 11.0** with **D3DMetal 3.0, DXMT 0.72, vkd3d 1.18, Wine Mono 10.4.1**. [1][2][5][6]
- **2026 list pricing: CrossOver+ US$74 for 12 months of updates/support; renewal US$34/yr inside a 13-month window; CrossOver Life (lifetime) US$494.** No 2- or 3-year tier was found; a 14-day fully functional trial exists. Heavy promotional discounting (25–65% codes; sales to ~$18–24) is routine. [7][8][9][10][11]
- **Apple Silicon today runs through Rosetta 2 (Intel Wine).** A native ARM64 preview using a CodeWeavers-ported **FEX** emulator shipped 2026-07-31; it requires macOS 26.5+, has **no D3DMetal, incomplete D3D12, broken launchers and no bottle migration**. **CrossOver 27 (early 2027) drops Intel Macs, macOS < Sonoma and 32-bit bottles.** [16][17][18][19]
- **D3DMetal is Apple's proprietary Game Porting Toolkit component** (GPTK itself is built on CodeWeavers' CrossOver 22.1.1 source); Apple's license restricts GPTK/D3DMetal to evaluation and forbids redistribution, so only CodeWeavers ships it commercially. The open alternative **DXMT (D3D10/11 on Metal) is LGPL-2.1+, copyright "Feifan He for CodeWeavers", v0.80 on 2026-04-23**. [26][27][28][30][33]
- **CAD is not a CrossOver strength:** the compatibility database marks AutoCAD's rating "Outdated", AutoCAD Civil 3D/Mechanical, Revit 2016/2018 have no ratings, SolidWorks 2024/2025 have no advocate, and Office 365 is flagged "no longer supported". Autodesk's own policy offers no support in virtualized/emulated environments. [43][44][45][46][47][54][55]

## Current status (version, date, maintainer, momentum)

**Maintainer.** CodeWeavers, Inc. (St. Paul, MN), the principal corporate sponsor of the Wine project; it hosts Wine's website, employs many Wine developers and describes CrossOver as "the outer shell" around the Wine core. [53]

**Release train (verified dates).**

| Version | Date | Base / notable contents | Source |
|---|---|---|---|
| 23.5 | 2023-09-27 | First integration of Apple GPTK's **D3DMetal** (DX11/DX12); requires Apple Silicon + macOS Sonoma | [26] |
| 24.0 | 2024-02 | Wine 9.0; Office 365 install fixes | [56] |
| 25.0 | 2025-03-11 | Wine 10.0; D3DMetal 2.1; **DXMT introduced** (DXMT v0.30 "shipped with CrossOver 25.0"); vkd3d 1.14; MoltenVK 1.2.10; Wine Mono 9.4.0; Epic/GOG Galaxy support | [24][25][33] |
| 25.1.1 | 2025-09-15 | macOS 26 Tahoe support incl. Intel Macs ("Tahoe is a go") | [23] |
| **26.0** | **2026-02-10** | **Wine 11.0**; D3DMetal 3.0; DXMT 0.72; vkd3d 1.18; Wine Mono 10.4.1; NTSync (Linux); Tahoe UI refresh; anti-cheat fixes (Helldivers 2, Expedition 33, Starfield, KCD II, FF VII Rebirth…) | [1][2][3][4] |
| 26.1.0 | 2026-04 | Maintenance: Unity mouse input, Battle.net install, Quicken UI, Death Stranding 2 | [5] |
| 26.2.0 | 2026-06-09 | Helldivers 2 launch fix; **warnings on 32-bit bottles** | [5] |
| **26.3.0** | **2026-07-21** | Diablo IV launch fix; Epic Games Launcher downloads on Mac; GOG Galaxy client fix | [5][6] |

**Wine base.** Wine 11.0 was tagged 2026-01-13 (GitHub mirror), ~6,300 changes / 600+ bug fixes; headline items are NTSync, the redesigned WoW64 mode (single `wine` loader), ARM64 4K-page simulation, and a macOS `%gs` swap fix in the syscall dispatcher. [37][38][39]

**Momentum.** Cadence is one major release per year (Feb/Mar) plus 2–4 point releases; 2025–2026 work is dominated by gaming (anti-cheat, D3DMetal/DXMT, launchers) and the ARM64 transition. Public roadmap: **CrossOver 27, "penciled in for early 2027"**, Apple-Silicon-only, Sonoma+, 64-bit-bottles only; CrossOver 26 will keep working on Intel. [16][17][19]

## Pricing and licensing (table)

| Product | 2026 list price (USD) | Term | What you get | Source / date |
|---|---|---|---|---|
| **CrossOver+** | **$74** | 12 months of updates + support (Mac, Linux, ChromeOS) | All point/major releases during term; unlimited tech support; **perpetual right to use/re-download any version you were entitled to** after expiry | Store [7]; "Don't Panic" blog 2025-10-09 [9]; Licensing policy [8] **[via search]** |
| Renewal | **$34 / yr** | Renew any time within 13 months of purchase | Another year of updates/support | [9][10] **[via search]**. Support KB separately says renewing before expiry or ≤30 days after gives "50% off" (would be $37) — minor inconsistency, flag for verification [10] |
| **CrossOver Life** | **$494** | Lifetime | Lifetime upgrades, bug fixes, support | Store [7]; forum petition thread [11]; machow2 2026 [12] **[via search]** |
| Multi-year (2/3-yr) | *Not found* | — | No multi-year tier appears in any 2026 source | Gap |
| Legacy monthly/6-month ($39.95 / $49.95) | *Unverified* | — | Appears only on an undated G2 listing; treat as stale | [15] |
| Trial | Free | 14 days | Fully functional | [43] |
| Promotions | 25–65% off | frequent | e.g. code TAHOE −25% (Sept 2025); Slickdeals sales at $18.50–$24 | [23][17][11] |

Price history: CrossOver+ moved to $74 with CrossOver 22 (Aug 2022) after "over 13 years" without an increase. [14]

Licensing structure: Wine components are LGPL and CodeWeavers publishes its modified sources at `media.codeweavers.com/pub/crossover/source/` (mirrored nightly on GitHub with wine, dxvk, vkd3d, MoltenVK, samba, freetype, gnutls and clang subtrees); the CrossOver GUI/installer tooling and Apple's D3DMetal are proprietary. [40][41]

Seat count per license, refund terms and education/volume pricing could not be confirmed (pages blocked) — see Open questions.

## How it works (architecture)

- **Core:** Wine (LGPL) with CodeWeavers' patch set, wrapped by a proprietary macOS app (bottle manager, "install unlisted application" wizard, CrossTie-style install recipes tied to the online Compatibility Center). [40][53]
- **Bottles:** each bottle is an isolated virtual Windows environment with its own `C:` drive, registry, fonts, Windows-version profile (e.g., Win10) and per-bottle settings; multiple bottles coexist like separate Windows machines; the default is one bottle per app to prevent interference and to allow testing app versions side by side. 32-bit vs 64-bit bottle types exist; 32-bit support on macOS relies on "very invasive hacks" and is being removed in 27. [51][52][16]
- **Graphics back-ends (per-bottle toggles):** `wined3d` (OpenGL), **DXVK** (D3D9–11 → Vulkan → Metal via MoltenVK), **D3DMetal** (Apple GPTK; D3D11 + D3D12; Apple Silicon + Sonoma+ only), **DXMT** (D3D10/11 → Metal; open source; helps lower-spec Macs; DXMT files live in `CrossOver.app/Contents/SharedSupport/CrossOver/lib/dxmt/`). Sync options ESync/MSync; "High Resolution Mode" for Retina scaling. [26][50][34]
- **CPU on Apple Silicon (today):** the shipped Wine is x86_64 and runs under **Rosetta 2**. [12][19]
- **CPU on Apple Silicon (preview/27):** universal build with an ARM64 Wine that uses a CodeWeavers-ported **FEX** emulator for i386/x86-64 code (Wine's ARM64EC support, from Wine 10.0, is the enabling piece). ARM64 parts need **macOS 26.5+**; on older macOS it silently falls back to Intel Wine + Rosetta. Timeline: Wine 9.0 ARM64/emulated i386 (Jan 2024) → CrossOver client ported to ARM64 (May 2024) → Wine 10.0 ARM64EC (Jan 2025) → Linux ARM64 preview (Nov 2025) → Mac ARM64 preview (Jul 2026). [18][19][21]

**How it differs from free Wine on macOS.** Free Wine builds for macOS (e.g., Gcenx's, Wine 11.16 as of Aug 2026) require separate GStreamer installation, Catalina+, and ship **no D3DMetal**; the community "wine-crossover" formula is stuck on CrossOver 23.7.1 sources (Wine 8.0.1), showing how hard it is to rebuild CrossOver's stack from the LGPL drop. CrossOver adds: the bottle GUI, curated install recipes and the crowd-rated Compatibility Center, official support, the licensed D3DMetal binary, its private Wine patches ahead of upstream, and QA-driven fixes for launcher/anti-cheat breakage. [42][59][53]

## Feature checklist (table: feature | status | notes)

| Feature | Status (2026-09) | Notes / source |
|---|---|---|
| Wine base | Wine 11.0 | 26.x line [1][37] |
| DirectX 12 | Yes via D3DMetal 3.0 | Apple Silicon + Sonoma+ only [26][45] |
| DirectX 11 | Yes (D3DMetal / DXMT / DXVK / wined3d) | four selectable paths [50] |
| DirectX 9/10 | Yes (DXVK / wined3d; DXMT covers D3D10) | [33] |
| Vulkan | via MoltenVK (vkd3d 1.18) | [1] |
| Native Apple Silicon | **Preview only** (2026-07-31); GA in 27 (early 2027) | Rosetta 2 needed today [18][19] |
| Intel Mac support | 26.x yes; **dropped in 27** | [16] |
| Minimum macOS | 10.15 Catalina (26.x, per reviews); Tahoe needs ≥25.1.1; 27 needs Sonoma+ | [12][23][16] |
| 32-bit bottles | Supported with warnings in 26.2+; **removed in 27** | [5][16] |
| Anti-cheat (EAC etc.) | Partial; fixed for several titles in 26 | remaining weakness [4][12] |
| Launchers (Steam/Epic/GOG/Battle.net) | Supported; frequently re-broken by upstream updates | 26.1–26.3 changelogs [5] |
| Office 365 | **"no longer supported"** per compat page | Office 2024/2021 entries have per-version ratings (values not retrievable) [47] |
| Compatibility database | Crowd-rated 1–5 stars, per CrossOver version, "Outdated" flag | [48][49] |
| Bottle archive/export, multiple bottles | Yes | [51][52] |
| Source availability | Wine parts LGPL; GUI + D3DMetal proprietary | [40][41] |
| Linux/ChromeOS | Yes (same license) | [7] |

## CAD / AutoCAD relevance

- **Compatibility Center evidence is thin and stale.** The generic *AutoCAD* entry and *AutoCAD 2020/2017* are flagged "Outdated Rating… considered inaccurate for the latest versions of CrossOver"; *AutoCAD Civil 3D* and *AutoCAD Mechanical* have no ratings; *Revit 2016/2018* have no ratings and *Revit Architecture/2009* are outdated; *SolidWorks 2024/2025* have "nobody currently advocating" (SolidWorks 2025 shows a report against CrossOver 25.1.0 whose star value we could not read). No 2024–2026 success reports for current AutoCAD were surfaced by search. [43][44][45][46]
- **Technical headwinds for Windows AutoCAD under Wine:** AutoCAD 2025+ defaults to a **DirectX 12** renderer (`GFXDX12=1`, DX11 fallback available), needs a modern .NET runtime, and Autodesk's installer/ODIS, licensing (ADPClientServices) and sign-in flows are exactly the "background processes/licensing services" class that Wine layers struggle with. [54][55]
- **Autodesk policy:** products may be virtualized only where the license terms expressly permit it; Autodesk gives no technical support in virtual/emulated environments and disclaims all risk; its Mac guidance is native AutoCAD for Mac or Windows in Parallels/VMware/Boot Camp, and it warns that "ARM processors are not supported for a lot of desktop Autodesk products". CrossOver/Wine is not mentioned anywhere in Autodesk's guidance. [54][55]
- **Implication for MIRRORZ:** CrossOver is not positioned for CAD and CodeWeavers' 2025–2026 investment is almost entirely gaming; a CAD-first product with verified AutoCAD/Revit/SolidWorks recipes, DX12-on-Metal validation and licensing-flow support would be differentiated rather than head-on.

## Strengths (what to match)

1. **Ten-plus years of bottle UX** — isolated, archivable prefixes with per-bottle graphics/sync toggles; near-zero setup for listed apps. [51][52]
2. **Licensed D3DMetal + open DXMT** — the only commercial product shipping Apple's DX11/DX12 translator, plus a CodeWeavers-funded LGPL fallback that also runs on Intel Macs (experimental). [26][33]
3. **Upstream leverage** — CodeWeavers employs core Wine developers and gets its patches into Wine (11.0 = 6,300 changes), so compatibility compounds every year. [53][38]
4. **Crowd-sourced Compatibility Center with a 14-day trial** lowers purchase risk and doubles as marketing. [48][43]
5. **Clear perpetual-use licensing** ($74/yr, keep what you paid for; $494 lifetime) with aggressive discounting. [8][9]
6. **Ahead of the Rosetta cliff** — a working FEX-based ARM64 Wine before Apple ends Rosetta 2 (Tahoe 26.4 already warns; Rosetta ends after macOS 27). [18][22]

## Weaknesses (what MIRRORZ must beat)

1. **CAD/BIM coverage is effectively absent** — outdated or missing ratings for AutoCAD, Revit, SolidWorks; no vendor-validated recipes. [43]–[46]
2. **Rosetta dependence today** and an ARM64 preview that lacks D3DMetal, full D3D12, launcher support and bottle migration; users must rebuild bottles for 27. [19]
3. **Platform churn:** Intel Macs, macOS < Sonoma and all 32-bit bottles are cut in 27 — legacy CAD add-ins and older AutoCAD/LT builds lose a path. [16]
4. **Fragility to upstream updates** — nearly every 26.x point release is a fix for a launcher or game that an update broke. [5]
5. **Office 365 explicitly unsupported**; sign-in/licensing services remain a recurring failure class. [47]
6. **Dependency on Apple's proprietary D3DMetal** whose license bars redistribution — CodeWeavers' DX12 story exists at Apple's discretion; the community's free GPTK wrappers (Whisky, archived 2025-05-11) show how brittle that is. [27][30][31]
7. **Subscription friction** — updates stop after 12 months unless renewed; lifetime is $494. [8][9]
8. **No official Autodesk/Dassault support posture** — CrossOver cannot promise supportability for professional users. [54]

## Reusable code, ideas, and license implications for MIRRORZ

- **Wine (LGPL-2.1+) and CodeWeavers' CrossOver Wine sources (LGPL)** — MIRRORZ may build on either. LGPL obligations: ship/offer source for the Wine-derived parts and any modifications; keep proprietary code (GUI, orchestration, recipes) in separate processes/dynamically linked modules. Apple's own GPTK Homebrew formula is exactly this pattern (crossover-sources-22.1.1, LGPL-2.1+). [40][28]
- **DXMT (LGPL-2.1+, copyright "Feifan He for CodeWeavers")** — redistributable in a commercial product under LGPL; the maintainer announced v0.80 (2026-04-23) as the last MIT release, so pin ≤v0.80 if you need MIT terms, or comply with LGPL for ≥v0.81. Install layout (winemetal.so + d3d11/dxgi DLL overrides) is documented on the project wiki; DXMT already has experimental Intel-Mac support and needs Wine ≥10.18 for D3DKMT shared resources. [33][34]
- **D3DMetal / Apple GPTK** — **do not bundle.** Apple's license limits GPTK to evaluation/development and forbids shipping D3DMetal; Gcenx's redistributions require users to "comply with Apple's License.pdf for D3DMetal"; CodeWeavers ships it under a private arrangement. Options: (a) DXMT + DXVK/MoltenVK for DX11 and vkd3d/MoltenVK for DX12, (b) ask Apple for a license, (c) an opt-in "bring your own GPTK" installer that downloads from developer.apple.com under the user's own Apple developer agreement (this is what CXPatcher and Whisky did; both are GPL-3 and not reusable in closed source without copyleft). GPTK 4 (WWDC 2026) adds Metal 4 support. [27][29][30][31][32]
- **FEX (MIT) + Wine ARM64EC** — CodeWeavers has proven the FEX-on-macOS route for the post-Rosetta world; FEX is MIT-licensed so MIRRORZ can port it too, but expect the macOS-specific work (26.5+ requirement, page-size handling) to be substantial. [18][19][38]
- **Product ideas worth copying:** per-app bottles with archive/export; per-bottle graphics-backend switch; a public, per-version compatibility DB; 14-day trial; perpetual-use subscription. **Ideas to avoid:** gaming-first roadmap, 32-bit removal without a migration path, silent Rosetta fallback.
- **Ecosystem signal:** the GitHub `d3dmetal` topic shows ~20 small 2026 projects bundling free Wine + D3DMetal (Silo, WineForge, soju, Cellar…) — a legal gray zone MIRRORZ should not enter as a commercial vendor. [57]

## Open questions

1. Exact seat/device count per CrossOver+ and Life license, refund window, and edu/volume pricing (licensing page blocked).
2. Actual star ratings for Office 2024/2021, SolidWorks 2025 (CrossOver 25.1.0 report) and Revit 2024/2025 pages.
3. Whether CrossOver 26.x's minimum macOS is really 10.15 (only third-party reviews state it).
4. Terms of the CodeWeavers–Apple D3DMetal arrangement; whether it extends to ARM64 builds (the preview has no D3DMetal).
5. Whether Apple ends Rosetta 2 "after macOS 27" (MacRumors) or "with macOS 27" (machow2) — sources differ.
6. CrossOver 27 pricing changes (none announced).
7. Whether DXMT ≥0.81 has actually re-licensed in the repo (LICENSE now reads LGPL-2.1+; release notes say v0.80 was the last MIT build).

## Sources (numbered list of URLs with dates)

1. CodeWeavers blog — "CrossOver 26 cures artificial incompatibility…" (2026-02-10) — https://www.codeweavers.com/blog/mjohnson/2026/2/10/crossover-26-cures-artificial-incompatibility-with-windows-games-on-mac [via search]
2. Phoronix — "CrossOver 26 Released – Powered By Wine 11.0" (2026-02-10) — https://www.phoronix.com/news/CrossOver-26 [via search]
3. OMG! Ubuntu — "CrossOver 26 released with Wine 11.0 and NTSync" (2026-02) — https://www.omgubuntu.co.uk/2026/02/crossover-26-released [via search]
4. AppleInsider — "CrossOver 26 fixes major Windows games on macOS" (2026-02-10) — https://appleinsider.com/articles/26/02/10/crossover-26-update-adds-compatibility-for-blockbuster-expedition-33-and-helldivers-2 [via search]
5. CodeWeavers — CrossOver ChangeLog (26.1 Apr 2026; 26.2 2026-06-09; 26.3 2026-07-21) — https://www.codeweavers.com/crossover/changelog [via search]
6. CodeWeavers forum — "Announcing CrossOver 26.3.0" (2026-07-21) — https://www.codeweavers.com/support/forums/announce/?t=24&msg=356474 [via search]
7. CodeWeavers Store (2026) — https://www.codeweavers.com/store/ [via search]
8. CodeWeavers Licensing and Support Policy — https://www.codeweavers.com/store/licensing [via search]
9. CodeWeavers blog, A. Balfour — "Don't Panic: How CrossOver Licenses Work" (2025-10-09) — https://www.codeweavers.com/blog/balfour/2025/10/9/dont-panic-how-crossover-licenses-work [via search]
10. CodeWeavers support — "Renewing your CrossOver license" — https://support.codeweavers.com/purchasing/renewing-your-crossover-license [via search]
11. CodeWeavers forum — "Petition: Crossover Lifetime – Leasing" — https://www.codeweavers.com/support/forums/general/?t=40&msg=346618 [via search]
12. MacHow2 — "Crossover 26 Review" (2026) — https://machow2.com/crossover-mac-review/ [via search]
13. Macworld — "CodeWeavers CrossOver for Mac review" — https://www.macworld.com/article/2276922/crossover-for-mac-review.html [via search]
14. Linux Game Consortium — "CrossOver+ increases price with a discount" (2022-08-13) — https://linuxgameconsortium.com/crossover-increases-price-with-a-discount/ [via search]
15. G2 — CrossOver pricing (undated, legacy) — https://g2.com/products/crossover/pricing [via search]
16. CodeWeavers blog — "What's in and what's out for CrossOver 27" (2026-06-11) — https://www.codeweavers.com/blog/mjohnson/2026/6/11/whats-in-and-whats-out-for-crossover-27 [via search]
17. AppleInsider — "CrossOver… goes Apple Silicon only" (2026-06-11) — https://appleinsider.com/articles/26/06/11/crossover-a-windows-to-mac-gaming-tool-goes-apple-silicon-only [via search]
18. CodeWeavers blog — "CrossOver Preview: The right to bear ARM64 on Mac" (2026-07-31) — https://www.codeweavers.com/blog/mjohnson/2026/7/31/crossover-preview-the-right-to-bear-arm64-on-mac [via search]
19. AppleInsider — "First Apple Silicon CrossOver build in testing as Rosetta's end nears" (2026-07-31) — https://appleinsider.com/articles/26/07/31/first-apple-silicon-native-crossover-build-in-testing-as-rosettas-end-nears [via search]
20. TUAW — "CrossOver Goes Native on Apple Silicon" (2026-08-02) — https://www.tuaw.com/2026/08/02/crossover-goes-native-on-apple-silicon [via search]
21. CodeWeavers blog — "Twist our ARM64, here's the latest CrossOver Preview" (2025-11-06) — https://www.codeweavers.com/blog/mjohnson/2025/11/6/twist-our-arm64-heres-the-latest-crossover-preview [via search]
22. MacRumors — "macOS Tahoe 26.4 Displays Warnings for Apps That Won't Work After Rosetta 2 Support Ends" (2026-02-16) — https://www.macrumors.com/2026/02/16/macos-tahoe-26-4-rosetta-2-warnings/ [via search]
23. CodeWeavers blog — "Tahoe is a go with CrossOver 25.1.1" (2025-09-15) — https://www.codeweavers.com/blog/mjohnson/2025/9/15/tahoe-is-a-go-with-crossover-2511 [via search]
24. CodeWeavers blog — "Experience next level gaming on Mac with CrossOver 25" (2025-03-11) — https://www.codeweavers.com/blog/mjohnson/2025/3/11/experience-next-level-gaming-on-mac-with-crossover-25 [via search]
25. AppleInsider — "CrossOver 25 improves DirectX 11 support" (2025-03-11) — https://appleinsider.com/articles/25/03/11/crossover-25-improves-directx-11-support-works-with-epic-games-store [via search]
26. CodeWeavers press release — "CrossOver 23.5" (2023-09-27) — https://www.codeweavers.com/about/news/press/20230927 [via search]
27. CodeWeavers blog — "Wine comes to macOS: Apple's Game Porting Toolkit powered by CrossOver source code" (2023-06-06) — https://www.codeweavers.com/blog/mjohnson/2023/6/6/wine-comes-to-macos-apple-s-game-porting-toolkit-powered-by-crossover-source-code [via search]
28. Apple — homebrew-apple `game-porting-toolkit.rb` (crossover-sources-22.1.1, LGPL-2.1+, x86_64) — https://raw.githubusercontent.com/apple/homebrew-apple/master/Formula/game-porting-toolkit.rb (fetched 2026-09-03)
29. Apple Developer — Game Porting Toolkit (GPTK 4, WWDC 2026) — https://developer.apple.com/games/game-porting-toolkit/ (fetched 2026-09-03)
30. Gcenx — Game Porting Toolkit 3.0-3 release (2025-03-03; "comply with Apple's License.pdf for D3DMetal") — https://github.com/Gcenx/game-porting-toolkit/releases/tag/Game-Porting-Toolkit-3.0-3 (fetched)
31. Whisky (archived 2025-05-11; GPL-3; CrossOver 22.1.1 + GPTK) — https://github.com/Whisky-App/Whisky (fetched)
32. CXPatcher (GPL-3; unofficial CrossOver patcher) — https://github.com/italomandara/CXPatcher (fetched)
33. DXMT — README, LICENSE (LGPL-2.1+, "Feifan He for CodeWeavers"), tags (v0.72 2025-12-11; v0.80 2026-04-23), releases (v0.30 "shipped with CrossOver 25.0", 2025-03-13) — https://github.com/3Shain/dxmt , https://github.com/3Shain/dxmt/tags , https://github.com/3Shain/dxmt/releases (fetched)
34. DXMT wiki — "DXMT Installation Guide for Geeks" — https://github.com/3Shain/dxmt/wiki/DXMT-Installation-Guide-for-Geeks (fetched)
35. DXMT Discussion #19 — "September Status" (2024-09-28) — https://github.com/3Shain/dxmt/discussions/19 (fetched)
36. DXMT Issue #151 — "DXMT 1.0 Release Plan" (2026-04-21) — https://github.com/3Shain/dxmt/issues/151 (fetched)
37. wine-mirror tags — wine-11.0 (2026-01-13) — https://github.com/wine-mirror/wine/tags?after=wine-11.2 (fetched)
38. Wine 11.0 ANNOUNCE.md — https://github.com/wine-mirror/wine/blob/wine-11.0/ANNOUNCE.md (fetched)
39. Phoronix — "Wine 11.0 On Track For January Release" — https://www.phoronix.com/news/Wine-11.0-January-2026 [via search]
40. CodeWeavers — CrossOver Source Code — https://www.codeweavers.com/crossover/source [via search]
41. TheShellLand/crossover-source (nightly mirror of media.codeweavers.com sources) — https://github.com/TheShellLand/crossover-source (fetched)
42. Gcenx/homebrew-wine (wine-crossover = Wine 8.0.1 + crossover-sources-23.7.1) — https://github.com/Gcenx/homebrew-wine (fetched)
43. CodeWeavers Compatibility — AutoCAD ("Outdated Rating") — https://www.codeweavers.com/compatibility/crossover/autocad [via search]
44. CodeWeavers Compatibility — AutoCAD 2020 / Civil 3D / Mechanical — https://www.codeweavers.com/compatibility/crossover/autocad-2020 ; …/autocad-civil-3d ; …/autocad-mechanical [via search]
45. CodeWeavers Compatibility — Revit 2016 / 2018 / 2024 / 2025 — https://www.codeweavers.com/compatibility/crossover/revit-2018 ; …/autodesk-revit-2025 [via search]
46. CodeWeavers Compatibility — SolidWorks 2024 / 2025 — https://www.codeweavers.com/compatibility/crossover/solidworks-2025 [via search]
47. CodeWeavers Compatibility — Microsoft Office 365 ("no longer supported") / Office 2024 — https://www.codeweavers.com/compatibility/crossover/microsoft-office-365 ; …/microsoft-office-2024 [via search]
48. CodeWeavers — Rating System — https://www.codeweavers.com/compatibility/rating-system [via search]
49. CodeWeavers support — "The Compatibility Database" — https://support.codeweavers.com/the-compatibility-database [via search]
50. CodeWeavers support — "Advanced Settings in CrossOver Mac 25" — https://support.codeweavers.com/miscellanous/advanced-settings-in-crossover-mac [via search]
51. CodeWeavers — CrossOver Mac User Guide — https://support.codeweavers.com/user-guides/crossover-mac-user-guide [via search]
52. EveryMac — CrossOver bottles FAQ — https://everymac.com/mac-answers/windows-on-mac-faq/crossover-mac-officially-supported-applications-bottle.html [via search]
53. CodeWeavers blog, A. Lasky — "Wine, CrossOver & Proton — What's the relation?" (2019-03-21) — https://www.codeweavers.com/blog/alasky/2019/3/21/wine-crossover-and-proton-whats-the-relation [via search]
54. Autodesk KB — virtualization articles: "Are 3ds Max or Maya supported within a virtual environment?", "Install error… Error 10 … Parallels on macOS", "Which products are Mac-compatible?", "System requirements for AutoCAD 2020" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Running-3ds-Max-and-Maya-in-Virtual-Environments.html ; …/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html ; …/Which-products-are-Mac-compatible.html (fetched via Autodesk Product Help MCP, 2026-09-03)
55. Autodesk KB — "What is 'Configure your computer's graphics settings…' in AutoCAD 2025+" (GFXDX12, DirectX 12 default) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Turn-off-Configure-your-computer-s-graphics-settings-for-better-performance-in-AutoCAD.html (fetched via MCP); Autodesk virtualization policy — https://www.autodesk.com/support/account/admin/manage/virtualization [via search]
56. AlternativeTo — "CrossOver 24 released with Wine 9.0" (2024-02) — https://alternativeto.net/news/2024/2/crossover-24-released-with-wine-9-0-and-support-for-more-games-on-macos [via search]; OMG! Ubuntu "CrossOver 24 … Office 365 Install Fixes" (2024-02) — https://www.omgubuntu.co.uk/2024/02/crossover-24-released-run-office-365-linux [via search]
57. GitHub topic `d3dmetal` (snapshot 2026-09-03) — https://github.com/topics/d3dmetal (fetched)
58. AppleGamingWiki — Game Porting Toolkit (license: development/evaluation only) — https://www.applegamingwiki.com/wiki/Game_Porting_Toolkit [via search]
59. Gcenx/macOS_Wine_builds releases (Wine 11.16, Aug 2026; Catalina+; GStreamer required) — https://github.com/Gcenx/macOS_Wine_builds/releases (fetched)
