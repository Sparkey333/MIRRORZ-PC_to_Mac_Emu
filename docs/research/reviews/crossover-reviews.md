# CrossOver Mac (CodeWeavers) — User Review Synthesis, 2024–2026

_Research date: 2026-09-03_

**Method note.** 14 distinct web searches; 15+ direct page fetches on github.com / raw.githubusercontent.com (Whisky, Kegworks/Sikarugir, cxbuilder, winecx mirror + LICENSE, DXMT, MoltenVK, Gcenx builds, Legendary wiki, Heroic/Whisky issue trackers) plus six Autodesk Knowledge Network articles via the Autodesk help API. **Every fetch to codeweavers.com, macworld.com, machow2.com, g2.com, macrumors.com, appleinsider.com, phoronix.com, 9to5mac.com and wikipedia.org was blocked by this session's egress proxy.** Facts from those sites come from the search engine's summaries of those pages, are marked **[snippet]**, and carry medium confidence. Nothing is stated from memory; unverifiable items are listed under Open questions.

## TL;DR (5 bullets)

- **Current product (Sept 2026):** CrossOver 26.3, released 2026‑07‑21 (CodeWeavers changelog [snippet]); the 26.x line is Wine 11.0 + D3DMetal 3.0 + DXMT 0.72 (CodeWeavers/AppleInsider/Phoronix, 2026‑02‑10 [snippet]). An ARM64‑native Preview was announced 2026‑07‑31; CrossOver 27 (early 2027) will be Apple‑Silicon‑only and existing 32‑bit bottles must be recreated as 64‑bit [snippet].
- **Consensus verdict:** "the best‑supported Wine on Mac" — lighter than a VM, no Windows licence, and the only vendor‑supported channel for Apple's D3DMetal. The caveat in nearly every source is *compatibility roulette*: some titles run perfectly, some need tweaking, some never launch (Macworld, MacHow2, G2 3.7/5 [snippet]).
- **Price vs free:** recurring reference prices are US$74/yr (CrossOver+) and US$494 (CrossOver Life), with deep sales (US$22.20 in Dec 2024) [snippet]; the store copy says "plans start as low as $39.95" [snippet] — unreconciled. The free rivals collapsed: Whisky is "no longer actively maintained" (README, fetched) and the community `winecx` builds Heroic used were deleted (GitHub 404, confirmed 2026‑09‑03).
- **Business / CAD:** CodeWeavers keeps compatibility pages for AutoCAD (many versions), Civil 3D, Revit 2024–26 and SolidWorks 2025, but no source reports a current AutoCAD running acceptably; Autodesk's KB says AutoCAD "is not supported when run using Wine or other Windows compatibility layers" (fetched).
- **For MIRRORZ:** CrossOver's Wine patches are LGPL‑2.1+, DXMT is LGPL‑2.1, MoltenVK is Apache‑2.0 — all reusable. Apple's D3DMetal/Game Porting Toolkit is closed‑source under a licence the Kegworks/Sikarugir maintainers say "can not be used for commerial ports" — MIRRORZ cannot ship it. CrossOver's GUI, CrossTie recipes and compatibility database are proprietary.

## Current status (version, date, maintainer, momentum)

| Item | Finding | Source / date | Conf. |
|---|---|---|---|
| Maintainer | CodeWeavers, Inc.; CrossOver funds the macOS side of Wine | MacRumors 2025‑04‑23 [snippet]; Whisky discussion #257 (fetched) | high |
| Latest stable | 26.3, 2026‑07‑21: fixes Diablo IV, Epic Launcher, GOG Galaxy after upstream updates | Changelog [snippet] | medium |
| 26.0 | 2026‑02‑10: Wine 11.0 (">6,000 changes"), D3DMetal 3.0, DXMT 0.72, Wine Mono 10.4.1, vkd3d 1.18, new D3DMetal toggle; Helldivers 2 multiplayer, GoW Ragnarök, FF VII Rebirth, Expedition 33 | CodeWeavers blog, AppleInsider, Phoronix [snippet] | medium |
| 26.1 | Diablo IV and Overwatch added | MacHow2 2026 [snippet] | medium |
| 25.0 | 2025‑03‑11: Wine 10.0, D3DMetal 2.1 (RDR2, TLOU Part 1), DXMT introduced, Epic Games Store, MoltenVK 1.2.10, vkd3d 1.14 | CodeWeavers blog, 9to5Mac, AppleInsider [snippet] | medium |
| 24.0 | Feb 2024: Wine 9.0 | AlternativeTo [snippet] | medium |
| Next | ARM64 Preview 2026‑07‑31; CrossOver 27 "early 2027", Apple Silicon only, Intel stays on 26, 32‑bit bottles retired | CodeWeavers blog, MacHow2 [snippet] | medium |
| Momentum | Annual major + 2–3 point releases. Free ecosystem shrank: Whisky's last release v2.3.5 (2025‑04‑05), README "no longer actively maintained"; `Gcenx/winecx` 404 | GitHub (fetched); Heroic #5495 (2026‑04‑20) | high |

## Pricing and licensing (table)

| Tier | Price (USD) | Includes | Source / date | Conf. |
|---|---|---|---|---|
| Trial | Free, 14 days, fully functional | Test before buying | CodeWeavers compat pages, Macworld [snippet]. *Conflict:* Legendary wiki (2022‑01‑09, fetched) says 15 days, "expiry resets for every version" — prefer the newer CodeWeavers figure | medium |
| CrossOver+ (12 mo) | US$74 "normally" | 12 months of updates + support; after lapse "continue using the last version released for you until something breaks" | Yahoo Tech [snippet]; Slickdeals Dec 2024 ($22.20 "instead of the usual $74") [snippet]; licence blog 2025‑10‑09 [snippet] | medium |
| "Starts as low as" | US$39.95 | Tier unclear ("12 month and lifetime license plans… start as low as $39.95") | codeweavers.com/store [snippet] | low |
| CrossOver Life | US$494 | "All future updates… forever, access to CrossOver Preview forever," merch credits; ≈ "12 years of CrossOver+ renewals"; discounted "usually… once per year during the Cyber Monday sale" | Licence blog 2025‑10‑09; aggregators [snippet] | medium |
| Business / education | Not found | — | — | gap |
| Source licence | Wine patches LGPL‑2.1‑or‑later at media.codeweavers.com/pub/crossover/source/ | winecx LICENSE (fetched) | high |
| Binary/GUI | Proprietary EULA | codeweavers.com/crossover/eula [snippet] | medium |

The $74 / $494 pair recurs in 2024, 2025 and 2026 sources; the "$39.95" line is 2026 store copy and may be a promo or Linux SKU. Verify the store page before quoting externally.

## How it works (architecture)

- **Wine + CodeWeavers patches.** A patched Wine, a native macOS GUI, and *CrossTie* install recipes. The Wine portion is LGPL and mirrored publicly (winecx, fetched); `cxbuilder` (fetched, pinned to CrossOver 24 / Wine 9.0) rebuilds it "to enable game launchers and productivity software that don't work on mainline Wine."
- **Bottles.** Each app lives in a self‑contained bottle (Wine prefix + `cxbottle.conf`), with a per‑bottle Windows version ("Windows 7 64‑bit" recommended by the Legendary wiki). Third‑party launchers must treat bottles differently from plain prefixes — Heroic #4369 (2025‑03‑02) shows the failure when they don't.
- **Graphics.** Four back ends: wined3d, DXVK (D3D9–11 → Vulkan → MoltenVK), DXMT (D3D10/11 → Metal; LGPL‑2.1, fetched) and Apple's proprietary D3DMetal (64‑bit D3D11/12 → Metal, Apple Silicon only). Since 25.0 the "Auto" setting picks per title from CodeWeavers' database; DXMT is called out as good "for lower spec Macs" (PaulTheTall 2025 [snippet]). D3DMetal first shipped in 23.5 (discussion #257) and can be disabled per bottle via `WINED3DMETAL = "0"` (Whisky #600, 2023‑11‑04).
- **32‑bit.** Historically a custom LLVM "win32on64" build (sarimarton gist, fetched); the ARM64 preview implies Wine's WoW64 path and the end of legacy 32‑bit bottles in 27 [snippet]. Apple Silicon "additionally require[s] Rosetta2" until then (Sikarugir README).
- **Sync.** NTSync arrived in 26 for Linux only [snippet]; Whisky used msync on macOS (issue logs, fetched).

## Feature checklist (table: feature | status | notes)

| Feature | Status (Sept 2026) | Notes / source |
|---|---|---|
| Windows apps without a Windows licence | Yes | Core value in every review [snippet] |
| Apple Silicon | Yes (Rosetta today; native ARM64 in Preview) | CodeWeavers 2026‑07‑31 [snippet] |
| Intel Mac | Yes through 26.x; dropped in 27 | Same; Heroic #5862 (2026‑09‑01) shows Intel/Ventura users stuck on old builds |
| 32‑bit apps | Yes in 26.x; bottles must be recreated for 27 | [snippet] |
| D3DMetal (DX11/12) | Yes, 3.0, with UI toggle | AppleInsider 2026‑02‑10 [snippet] |
| DXMT (DX10/11 → Metal) | Yes, 0.72 | Phoronix [snippet]; Heroic already ships DXMT 0.74 (#5495 log) |
| DXVK / MoltenVK | Yes | Legendary wiki (fetched) |
| Bottle isolation, per‑bottle Windows version & back end | Yes | Legendary wiki; Whisky #600 |
| CrossTie one‑click recipes | Yes (proprietary) | [snippet] |
| Community compatibility DB | Yes | AutoCAD/Revit/SolidWorks pages exist; ratings not retrievable |
| Epic / Steam / GOG launchers | Yes (Epic since 25; 26.3 fixed Epic and GOG) | [snippet] |
| Anti‑cheat multiplayer | Generally no | Macworld [snippet] |
| Keep software after lapse | Yes, last entitled version | Licence blog [snippet] |
| Lifetime licence | Yes (Life) | Same |
| Vendor tickets | Yes with subscription; responsiveness disputed | Forums [snippet] |
| Open‑source Wine patches | Yes, LGPL‑2.1+ | winecx LICENSE (fetched) |

## CAD / AutoCAD relevance

- **Autodesk's position (fetched KB):** "AutoCAD is not supported when run using Wine or other Windows compatibility layers"; supported platforms are Windows and macOS only. For Windows‑only Autodesk products on a Mac, Autodesk points to Parallels/VMware/Boot Camp, warns "Not all Autodesk product offerings may be virtualized," and says of the Toolsets that "AutoCAD family products are not supported" in virtualized environments.
- **Technical bar (fetched):** AutoCAD 2025 (Windows) needs .NET 8, a DirectX 11 GPU minimum, DX12 Feature Level 12_0 for "Fast" visual styles, and "ARM Processors are not supported"; AutoCAD 2027 requires Windows 11, .NET 10, 16 GB RAM. `GFXDX12 = 0` falls back to the DX11 engine — the realistic path for a translation layer (DXMT/DXVK do DX11; only Apple's D3DMetal does DX12).
- **CrossOver evidence:** compatibility pages exist for AutoCAD (generic), 2000/R14/2014/2017/2020, Civil 3D, AutoCAD Mechanical, Revit 2024/2025/2026 and SolidWorks 2025 (bodies blocked). A 2026 guide notes "GPU‑intensive tools such as Revit and SOLIDWORKS present a particular challenge" and that software with "licensing requirements, special drivers, or hardware dependencies [is] more likely to cause problems" (Ace Cloud Hosting [snippet]). No source reports AutoCAD 2024–2027 working in CrossOver; the newest dedicated CodeWeavers entry surfaced was AutoCAD 2020.
- **Native alternative:** AutoCAD for Mac 2027 supports macOS Tahoe 26/Sequoia/Sonoma on Intel and M‑series (fetched) — so Mac demand centres on the Windows‑only Toolsets (Architecture, MEP, Electrical, Plant 3D, Map 3D, Mechanical, Raster Design), plug‑ins, Revit and Civil 3D.

**Implication:** the Wine route is unsupported by Autodesk, licensing behaviour "cannot be guaranteed," and the 2025+ engine leans on DX12 and .NET 8/10. MIRRORZ should not market AutoCAD as supported until it has its own dated, per‑release test evidence.

## Strengths (what to match)

Top 10 pros by recurrence across sources:

1. **No Windows, no VM overhead** — "considerably lighter than a virtual machine," no licence cost, apps open like Mac apps (Macworld, MacHow2, Yahoo Tech, G2 [snippet]).
2. **Best‑supported Wine on Mac / D3DMetal gains** — CrossOver + D3DMetal "upwards of 20% better" than Whisky (Whisky #981, 2024‑05‑13); same game "performs great" in CrossOver but stuttered and ran hotter in Whisky (#1280, 2025‑01‑03); Diablo IV ~50 fps at 1080p medium on M2 Pro (MacHow2 [snippet]).
3. **Steady dated cadence** — 24 (Feb 2024), 25 (Mar 2025), 26 (Feb 2026), 26.3 (Jul 2026), ARM64 preview (Jul 2026), each re‑based on current Wine.
4. **Bottles** — isolation, per‑bottle Windows version and back end; praised as easy (Macworld [snippet], Legendary wiki).
5. **Ease of install / CrossTies** — G2: users "praise… ease of use" and how it "simplifies… installing and managing applications" [snippet].
6. **Back‑end choice with sane defaults** — "Auto" picks wined3d/DXMT/DXVK/D3DMetal per title [snippet].
7. **Testable value** — full‑function trial plus public ratings let buyers check the roulette first (Macworld [snippet]).
8. **Fair lapse policy** — keep the last version; lifetime option (licence blog [snippet]).
9. **Ecosystem legitimacy** — Whisky's author endorsed CrossOver, saying Whisky "contributed practically zero" to Wine while threatening CrossOver (MacRumors 2025‑04‑23 [snippet]; discussion #257).
10. **Support exists** — "better support compared to free Wine front‑ends like Porting Kit" (Yahoo [snippet]); CodeWeavers staff cite 4 h / 2 h / 37 min ticket turnarounds in one dispute (forum [snippet]).

## Weaknesses (what MIRRORZ must beat)

Top 10 cons by recurrence:

1. **Compatibility roulette** — "some games work almost perfectly, some need considerable experimentation and others won't launch at all" (Macworld [snippet]); G2's lead negative; "limited compatibility," "manual configuration" (backlinkworks [snippet]).
2. **Anti‑cheat multiplayer** is a dead zone (Macworld [snippet]).
3. **Price vs free** — $74/yr or $494 once against Whisky/Kegworks/Wine at $0 was the standing objection through 2025; a forum thread is titled "Petition: Crossover Lifetime – Leasing" [snippet]. The free options' collapse weakens but doesn't remove it.
4. **Inconsistent support** — a ticket unanswered for 8 days and a pattern of "more than a week" waits; "Support Ticket System Broken" (form resets, discards content); CodeWeavers rebuts with fast times in another case (forums [snippet], undated).
5. **Manual tweaking** — DXVK/D3DMetal toggles, Windows‑version choice, launch flags (Legendary wiki; Heroic #4418, 2025‑03‑15: free wine‑crossover games "won't work at all if DXVK is disabled").
6. **Opaque bottle model** — launchers mis‑handle bottle vs prefix (Heroic #4369); CrossOver 27 invalidates 32‑bit bottles [snippet].
7. **Updates break setups** — 26.3 exists to fix Diablo IV/Epic/GOG "after update" [snippet]; macOS point releases break Wine stacks (Whisky #1372, 2025‑04‑26: 15.4.1 broke Steam).
8. **Intel Macs orphaned** — no 27 for Intel; Intel users already stuck (Heroic #5862, 2026‑09‑01).
9. **Business/CAD second‑class** — game‑led marketing; no current AutoCAD/Revit/SolidWorks success evidence; Autodesk disclaims Wine.
10. **Rosetta and closed pieces** — Rosetta dependency until 27; D3DMetal is Apple‑proprietary, so headroom rests on a component nobody else can ship.

**Beat‑list:** a per‑app *verified* compatibility contract (dated, versioned, auto re‑tested on each macOS/Wine update); first‑class business/CAD workflows (activation, printing/plotters, .NET provisioning, DX12→Metal without Apple's blob); SLA‑backed support; bottle migration tooling (32→64‑bit, Intel→ARM); pricing that survives comparison with $74/yr.

## Reusable code, ideas, and license implications for MIRRORZ

| Component | Licence (fetched) | Commercial reuse |
|---|---|---|
| CrossOver Wine sources (winecx mirror) | LGPL‑2.1‑or‑later | Yes: ship as relinkable dynamic library, publish modifications, keep notices. `cxbuilder` (LGPL‑3.0) documents the build but targets CrossOver 24 |
| Upstream Wine 11.x macOS builds (Gcenx, latest 11.16, Aug 24) | LGPL | Yes; maintainer warns AV vendors flag MinGW‑built PE binaries — plan notarisation/whitelisting |
| DXMT (3Shain) | LGPL‑2.1 (+ others) | Yes; the D3D10/11→Metal layer CrossOver 26 (0.72) and Heroic (0.74) bundle — the open substitute for D3DMetal on DX11 |
| MoltenVK | Apache‑2.0 | Yes; DXVK→MoltenVK for DX9–11 |
| Apple GPTk / D3DMetal | Proprietary — Sikarugir: "closed source… restrictive license it can not be used for commerial ports"; cxbuilder: GPTk dir "contains proprietary software from Apple, and is not covered under this license" | **No.** DX12 must come from vkd3d‑proton→MoltenVK or an in‑house DX12→Metal layer |
| CrossOver GUI, CrossTies, compat DB, `cxbottle.conf` | Proprietary | Ideas only: declarative recipes, per‑bottle back end, "Auto" from curated DB, one‑line overrides |
| Whisky (SwiftUI, on CrossOver 22.1.1 + GPTk) | GPL‑3.0 | Copying code would GPL the front end; study UX only. Its 190+ open issues are a free catalogue of failure modes |
| Sikarugir/Kegworks | Mixed (Configure.app LGPL‑2.1; launcher/creator other terms) | Check per file; useful reference for wrapper packaging and the five‑back‑end selector |

Ideas worth copying: the "Auto" back‑end table keyed by app ID; bottle‑level config overrides; a trial whose "expiry resets for every version"; the "keep the last version you paid for" lapse policy.

## Open questions

1. Exact current store SKUs/prices — reconcile "$39.95" with $74 / $494; any business/education pricing.
2. CodeWeavers ratings and last‑tested versions for AutoCAD 2020–2027, Revit 2026, SolidWorks 2025.
3. Dated support‑SLA evidence — forum threads cited could not be fetched.
4. Whether CrossOver 27 drops Rosetta entirely and how DXVK/MoltenVK fare on ARM64.
5. Independent D3DMetal 3.0 vs DXMT 0.7x vs DXVK benchmarks on M3/M4.
6. Autodesk licensing/sign‑in behaviour under Wine — "cannot be guaranteed"; needs lab testing.

## Sources (numbered list of URLs with dates)

(F) fetched directly; (A) Autodesk help API; (S) search‑result summary only (page blocked).

1. (S) CodeWeavers store — https://www.codeweavers.com/store — accessed 2026‑09‑03.
2. (S) CodeWeavers blog, "Don't Panic: How CrossOver Licenses Work" — https://www.codeweavers.com/blog/balfour/2025/10/9/dont-panic-how-crossover-licenses-work — 2025‑10‑09.
3. (S) CodeWeavers blog, "CrossOver Preview: The right to bear ARM64 on Mac" — https://www.codeweavers.com/blog/mjohnson/2026/7/31/crossover-preview-the-right-to-bear-arm64-on-mac — 2026‑07‑31.
4. (S) CodeWeavers blog, CrossOver 26 — https://www.codeweavers.com/blog/mjohnson/2026/2/10/crossover-26-cures-artificial-incompatibility-with-windows-games-on-mac — 2026‑02‑10.
5. (S) CodeWeavers blog, CrossOver 25 — https://www.codeweavers.com/blog/mjohnson/2025/3/11/experience-next-level-gaming-on-mac-with-crossover-25 — 2025‑03‑11.
6. (S) CodeWeavers changelog (26.3, 2026‑07‑21) — https://www.codeweavers.com/crossover/changelog.
7. (S) CodeWeavers compatibility: https://www.codeweavers.com/compatibility/crossover/autocad ; …/autocad-2020 ; …/autocad-civil-3d ; …/autodesk-revit-2026 ; …/solidworks-2025 — undated.
8. (S) CodeWeavers forums: "Lack Of Support" https://www.codeweavers.com/support/forums/general/?t=26&msg=229125 ; "Support Ticket System Broken" (msg 41992); "Could not submit a support ticket" (msg 220358); "Petition: Crossover Lifetime – Leasing" https://www.codeweavers.com/support/forums/general/?t=40&msg=346618 — undated.
9. (S) Macworld, CrossOver for Mac review (26.3) — https://www.macworld.com/article/2276922/crossover-for-mac-review.html — 2026.
10. (S) MacHow2, "Crossover 26 Review" — https://machow2.com/crossover-mac-review/ — 2026.
11. (S) Yahoo Tech — https://tech.yahoo.com/computing/articles/windows-software-modern-mac-still-141516493.html — undated.
12. (S) G2 CrossOver reviews (3.7/5) — https://www.g2.com/products/crossover/reviews.
13. (S) AppleInsider, CrossOver 26 — https://appleinsider.com/articles/26/02/10/crossover-26-update-adds-compatibility-for-blockbuster-expedition-33-and-helldivers-2 — 2026‑02‑10.
14. (S) Phoronix, CrossOver 26 — https://www.phoronix.com/news/CrossOver-26 — Feb 2026.
15. (S) 9to5Mac, CrossOver 25 — https://9to5mac.com/2025/03/11/crossover-25-red-dead-redemption-2-macos/ — 2025‑03‑11.
16. (S) PaulTheTall, "Crossover 25 hits the streets!" — https://www.paulthetall.com/crossover-25-hits-the-streets/ — 2025.
17. (S) AlternativeTo news: CrossOver 24 https://alternativeto.net/news/2024/2/crossover-24-released-with-wine-9-0-and-support-for-more-games-on-macos (Feb 2024); CrossOver 26 https://alternativeto.net/news/2026/2/crossover-26-released-with-wine-11-ntsync-on-linux-and-support-for-many-new-games-on-mac (Feb 2026).
18. (S) MacRumors, Whisky ends — https://www.macrumors.com/2025/04/23/whisky-ends-mac-gaming-tool-crossover/ — 2025‑04‑23; AppleInsider — https://appleinsider.com/articles/25/04/16/whisky-development-ends-on-macos-to-help-wine-flourish — 2025‑04‑16.
19. (S) Slickdeals — https://slickdeals.net/f/18909469-codeweavers-crossover-linux-and-mac-software-18-50 ; Dec 2024 thread https://slickdeals.net/f/17955651-crossover-for-mac-on-sale-windows-compatibility-tool-can-play-diablo-1-2-and-4-on-mac-22-20.
20. (S) backlinkworks review — https://blogs.backlinkworks.com/a-comprehensive-review-of-crossover-mac-pros-cons-and-features/ — undated.
21. (S) Ace Cloud Hosting, "How to Run Windows Apps on Mac in 2026" — https://www.acecloudhosting.com/blog/run-windows-apps-on-mac/.
22. (F) Whisky README — https://raw.githubusercontent.com/Whisky-App/Whisky/main/README.md — 2026‑09‑03.
23. (F) Whisky releases (v2.3.5, 2025‑04‑05) — https://github.com/Whisky-App/Whisky/releases.
24. (F) Whisky discussion #257 (2023‑07‑21 → Jan 2025) — https://github.com/orgs/Whisky-App/discussions/257.
25. (F) Whisky issues #600 (2023‑11‑04), #981 (2024‑05‑13), #1280 (2025‑01‑03), #1372 (2025‑04‑26) — https://github.com/Whisky-App/Whisky/issues/981 etc.
26. (F) Heroic issues #4369 (2025‑03‑02), #4418 (2025‑03‑15), #5495 (2026‑04‑20), #5862 (2026‑09‑01) — https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/issues/5495 etc.
27. (F) Legendary wiki, "CrossOver Setup (macOS)" — https://github.com/derrod/legendary/wiki/CrossOver-Setup-(macOS) — 2022‑01‑09.
28. (F) Kegworks/Sikarugir README — https://github.com/Kegworks-App/Kegworks — 2026‑09‑03.
29. (F) cxbuilder README — https://github.com/101arrowz/cxbuilder — 2026‑09‑03.
30. (F) PhoenicisOrg/winecx + LICENSE — https://github.com/PhoenicisOrg/winecx ; https://raw.githubusercontent.com/PhoenicisOrg/winecx/master/LICENSE.
31. (F) 3Shain/dxmt — https://github.com/3Shain/dxmt — 2026‑09‑03.
32. (F) KhronosGroup/MoltenVK — https://github.com/KhronosGroup/MoltenVK — 2026‑09‑03.
33. (F) Gcenx/macOS_Wine_builds releases (11.16, Aug 24) — https://github.com/Gcenx/macOS_Wine_builds/releases ; Gcenx/winecx 404 — https://github.com/Gcenx/winecx.
34. (F) sarimarton gist, compile CrossOver from source — https://gist.github.com/sarimarton/471e9ff8046cc746f6ecb8340f942647 — last activity 2026‑05‑23.
35. (A) Autodesk KB, "AutoCAD and verticals on Linux" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-and-verticals-on-Linux.html.
36. (A) Autodesk KB, "How to run Windows specific Autodesk programs on a Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-run-Windows-specific-Autodesk-programs-on-a-Mac.html.
37. (A) Autodesk KB, "Are AutoCAD Toolsets supported on Mac OS?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Are-AutoCAD-Toolsets-supported-on-Mac-OS.html.
38. (A) Autodesk KB, system requirements AutoCAD 2025 — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html ; AutoCAD 2027 — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html.
39. (A) Autodesk KB, GFXDX12 — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Turn-off-Configure-your-computer-s-graphics-settings-for-better-performance-in-AutoCAD.html.
