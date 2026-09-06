# Windows-on-Mac Pricing Landscape and MIRRORZ Pricing Strategy (2026)

_Research date: 2026-09-03_

> Method note. The session's web-search budget was already exhausted (200/200) and the egress proxy blocks parallels.com, codeweavers.com, vmware.com/broadcom.com, setapp.com, shadow.tech, apps.apple.com and all Mac-press sites tried. Every fact below comes from fetchable pages: official Microsoft, Apple and Autodesk documentation, GitHub repos/release feeds/Homebrew casks, and GitHub-hosted third-party documents dated by commit history. Third-party-only prices are labelled and conflicts shown. Nothing is stated from memory.

## TL;DR (5 bullets)

- The full-VM segment has collapsed to one paid product. Parallels Desktop (now v27.0.1, Aug 2026) is the only Microsoft-authorized, paid Windows-on-Apple-silicon VM; 2026 third-party sources consistently report Standard $99.99/yr, Pro $119.99/yr, Business $149.99/yr, but disagree on the Standard perpetual price ($129.99 vs $219.99) [14][15][16][17][19]. VMware Fusion has been free for personal use since May 2024 and free for everyone (commercial included) since 11 Nov 2024 [43][44]; UTM is free/open source, with an App Store copy that is feature-identical and exists only to fund development [8].
- The translation-layer (Wine) segment prices at roughly $74/yr: CrossOver 26.3 is $74/yr ("CrossOver+"), $494 lifetime, 14-day trial, and was on sale at $54 on 29 Aug 2026 [13][46]. The free wrappers churn constantly: Whisky was archived 11 May 2025 [10], Kegworks was renamed Sikarugir [11], and Highball (GPL-3, free, beta) launched 23 Aug 2026 [13].
- Cloud PCs anchor the top of the range and set the "per-month" ceiling: Windows 365 Business is $36 / $56 / $108.80 per user per month (2/4/8 vCPU), monthly auto-renew, after a May 2026 price cut [20][22]; Enterprise runs $28 to $765, with GPU SKUs from $310 to $1,914 [21]. Shadow is only documented third-party at roughly $30 to $40/month [56]. Any VM route also needs a separate Windows 11 Pro licence per VM, per Microsoft [19].
- Prosumer Mac utilities cluster at $4.99 to $14.99/month for subscriptions (Setapp single-Mac plan is $14.99/mo in Aug 2026, up from $9.99 in 2017-2023 [48][50]; GeForce Now $9.99/$19.99 [55]) and $29 to $49 one-time with one year of updates (CleanShot X $29, Alfred Powerpack $44.99, CleanMyMac $39.95/yr) [52][53][54]. App Store economics: 800 price points, 30 percent commission (15 percent after year one of a subscription, or 15 percent throughout under the Small Business Program below $1M) [27][28][29].
- Recommendation: Ladder B (prosumer, perpetual-first): $9.99/mo, $79/yr, $149 perpetual with 12 months of updates, Family $129/yr or $229 perpetual for 5 Macs, Business $199/seat/yr; "Switch from Parallels" = 50 percent off year one or $99 perpetual trade-in, plus credit for unused Parallels months. No ads, ever. The structural price advantage is that a translation layer needs no Windows licence, so MIRRORZ's total cost of ownership is well under half of Parallels + Windows.

## Current status (version, date, maintainer, momentum)

| Product | Current version (source) | Maintainer / owner | Momentum in 2026 |
|---|---|---|---|
| Parallels Desktop | 27.0.1-58670; macOS Sonoma+, Apple silicon only [1]; v27 shipped 25 Aug 2026, v26 ~26 Aug 2025 [13][62] | Parallels (Corel/Alludo) | Annual August releases; Microsoft lists PD 18/19/20 as the authorized Windows-on-Arm solution [19] |
| VMware Fusion | 13.6.x (13.6.4 cited Nov 2025) [45]; download needs a Broadcom portal login [44] | Broadcom | Free for all since 11 Nov 2024; paid editions no longer sold; development promised, no support for ex-commercial customers [43]. No Homebrew cask (404) [2] |
| UTM | Stable v4.7.5 (3 Jan 2026, QEMU 10.0.2); betas v5.0.0 to v5.0.5 (12 Jan to 2 Sep 2026) add "DirectX graphics support for Windows" [7] | utmapp (Apache-2.0 with LGPL parts), 35.4k stars [6] | Very active; sister project d3dmetal-native (MIT, Jul 2026) puts D3D11/12 on Metal via Apple's D3DMetal.framework [9] |
| CrossOver | 26.3.0 [2] | CodeWeavers (funds most Wine development) | Steady; CrossOver source underpins Whisky and Apple's GPTK lineage [10] |
| Whisky | v2.3.5 (5 Apr 2025); repository archived 11 May 2025, "no longer actively maintained" [10] | Whisky-App (GPL-3.0) | Dead; 15.1k stars at archival |
| Kegworks / Sikarugir | github.com/Kegworks-App/Kegworks now serves Sikarugir-App/Sikarugir (created 1 Aug 2024, 3,592 stars, active Sep 2026); Creator cask v1.0.1 [11][12] | Sikarugir-App (LGPL-2.1 Configure.app; proprietary Launcher/Creator 1.0.1+) | Active but explicitly "not a replacement for CrossOver or Whisky"; warns sikarugir.com is not affiliated [11][12] |
| Highball | Beta; repo created 23 Aug 2026, 248 stars; GPL-3.0 app + CC0 database [13] | gauthierpiarrette | New free competitor: Wine + DXMT + D3DMetal + DXVK, Steam/Epic integration, Homebrew tap |
| Setapp | Client 3.55.0 [4] | MacPaw | Plans repriced upward (see below) |
| Windows 365 | Business pricing update GA week of 4 May 2026 [22] | Microsoft | Growing; Windows 365 for Agents adds $0.40/hour PAYG and $5/Cloud PC/month always-on SKUs [23] |
| Shadow | Client 9.9.10457 [5] | Shadow (post-2021 bankruptcy, new ownership) [55] | Shipping hardware/game updates in 2026 [55] |

## Pricing and licensing (table)

All USD. "Official" = fetched from the vendor's own site during this research; "3P" = GitHub-hosted third-party document, dated by commit.

| Product / plan | Price | Licence model | Source quality and date |
|---|---|---|---|
| Parallels Desktop Standard | $99.99/yr (four 2026 3P sources); one coupon site lists $89.99/yr [16] | Annual subscription, 1 Mac | 3P: Apr, Jun, Aug 2026 [14][15][13]; historically identical since PD18 (2022) [18] |
| Parallels Desktop Standard perpetual | $219.99 (Apr and Jun 2026 [15][14][17]) vs $129.99 (Aug 2026 [13], May 2026 [16], 2022 [18]) | One-time, that major version only; paid upgrades | Conflict. Verify on parallels.com before use |
| Parallels Pro / Business | $119.99/yr / $149.99/yr; subscription only [14][16]; one JP survey lists $159.99 / $199.99 [17] | Annual; Business adds SSO/mass deployment | 3P 2026; JP figures may be currency-converted |
| Parallels upgrades | Standard perpetual upgrade $62.99 [16] ($69.99 in 2022 [18]); Pro upgrade $55.99/yr [16] | Paid major-version upgrade | 3P May 2026 |
| Parallels extras | Edu discount up to 50 percent, 14-day trial [17]; routine Black Friday / back-to-school sales [16] | | 3P 2026 |
| Windows 11 Pro licence (required per VM) | Microsoft Store page unreachable (HTTP 503); a 2025 Amazon bestseller dataset shows Windows 11 Pro OEM at $146.18 [60] | Per-instance; keys are platform agnostic (x64/Arm) [19] | Official policy; 3P price |
| VMware Fusion Pro | Free for personal, educational and commercial use since 11 Nov 2024 (personal since 14 May 2024); no licence key [43][44] | Free; no paid tier sold | 3P mirrors of Broadcom blog, dated |
| UTM | Free (GitHub); Mac App Store copy identical, "directly funds development" [8]; 3P docs report the App Store price as $9.99 [15] | Apache-2.0 + LGPL components [6] | Official site source (no price shown); 3P for $9.99 |
| CrossOver+ (1 year) | $74/yr list; $54 on sale 29 Aug 2026; 14-day trial [13][46][47] | Annual subscription incl. updates and support | 3P Mar to Aug 2026 |
| CrossOver Life | $494 lifetime [13][46][47] | Perpetual incl. updates | 3P 2026 |
| Whisky / Sikarugir / Highball | Free [10][11][13] | GPL-3 / mixed LGPL+proprietary / GPL-3 | Official repos |
| Setapp Mac | $14.99/mo (1 Mac); Mac + iOS $18.99/mo; Power User $22.99/mo (4 Macs + 4 iOS); annual "up to 40 percent" off; 7-day trial [48] | Subscription bundle; 70 percent of fees pooled to developers by usage [48] | 3P captured from setapp.com/pricing on 13 Aug 2026 |
| Setapp (history) | $9.99/mo 2017-2023; $9.99/$12.49/$14.99 tiers in Jun 2022; Power User $13.49/mo annual in 2021 [50] | | 3P, dated posts |
| Windows 365 Business | $36 (2 vCPU/8 GB/128 GB), $56 (4/16/128), $108.80 (8/32/256) per user/month; monthly auto-renew; 30-day trial on the $36 plan; max 300 users [20] | Per-user per-month SaaS | Official, fetched Sep 2026 |
| Windows 365 Enterprise | $28 (2/4/64) to $765 (32/128/2 TB); GPU Select $310, GPU Standard $537, GPU Super $1,029, GPU Max $1,914 [21] | Requires Windows E3, Intune, Entra ID P1 | Official, Sep 2026 |
| Shadow PC | "starts at $39.99/month" (undated note) [56]; $35/mo (older DE list) [56]; $30/mo after a 2021 doubling [56] | Monthly cloud PC | 3P only, official page blocked |
| Prosumer references | CleanMyMac $39.95/yr [52]; CleanShot X $29 + 1 yr updates; Snagit ~$50 or $39/yr; DevUtils $29; Parallels Toolbox ~$20-25/yr [54]; Alfred Powerpack $44.99 [53]; GeForce Now $9.99 / $19.99 per month [55]; older list: Bartender $15, iStat Menus $16, Moom $10, PopClip $4.99, DaisyDisk $9.95, Paste $5.99 [51] | Mixed | 3P 2025-2026; [51] undated |
| App Store rules | Up to 800 price points, +100 higher on request up to $10,000; base-country pricing across 175 storefronts [27]; 30 percent commission, 15 percent after 12 paid months of a subscription; 15 percent throughout in the Small Business Program (<$1M prior-year proceeds) [28][29]; Family Sharing to 5 family members; offer codes now on macOS; grace periods 3/16/28 days [29] | | Official |

## How it works (architecture)

Two architectures compete, and the choice drives price structure:

1. Full virtualization (Parallels, VMware Fusion, UTM, Windows 365). An Arm64 Windows 11 guest runs on a hypervisor; x86/x64 apps run under Microsoft's Prism emulator, which gained AVX/AVX2 in Windows 11 24H2 [25]; kernel drivers must be native Arm64 [26]. Microsoft publishes Arm64 ISOs for VMs on Apple silicon [24] and requires a separate Windows 11 Pro licence per VM [19]. Apple's Virtualization framework documents only macOS and Linux guests [31]. Nested virtualization (WSL, Sandbox, VBS) is unsupported on Mac [19]. Parallels caps DirectX at 11.1 [13]; UTM 5.0.5 beta adds DirectX for Windows guests [7].

2. API translation (CrossOver, Whisky, Sikarugir, Highball, and MIRRORZ). Wine implements Win32 in a macOS process; Direct3D is translated to Metal by D3DMetal (Apple's Game Porting Toolkit), DXMT, DXVK-on-MoltenVK, or WineD3D [11][13]. No Windows licence is needed [13]. Costs move from "licence + VM" to "compatibility engineering," which is why CrossOver sells support and a curated compatibility database rather than a hypervisor.

3. Cloud (Windows 365, Shadow). Per-user-per-month streaming; a Mac is just a client. Windows 365 supports nested virtualization and is Microsoft's first-listed Mac option [19].

## Feature checklist (table: feature | status | notes)

| Feature (packaging / commercial) | Status in market | Notes for MIRRORZ |
|---|---|---|
| Free tier that runs Windows apps | Yes: VMware Fusion, UTM, Highball, Sikarugir | Free is the floor; MIRRORZ must sell CAD-grade reliability, not access |
| Microsoft-authorized Windows on Arm | Parallels only (18/19/20 listed) [19] | Translation layers do not need this |
| No Windows licence required | Wine-based tools only [13] | Core TCO argument vs Parallels |
| Perpetual licence available | Parallels Standard (price disputed), CrossOver Life $494, CleanShot/Alfred style one-time [13][14][53][54] | Strong user demand for perpetual (see sentiment) |
| Monthly billing | Windows 365, Shadow, Setapp, GeForce Now [20][48][55][56] | Parallels and CrossOver are annual-only in sources found |
| Family / multi-Mac plan | Setapp Power User (4 Macs) $22.99/mo [48]; App Store Family Sharing (5) [29] | Family Sharing makes a "Family" SKU nearly free to offer on App Store |
| Business / SSO / deployment | Parallels Business $149.99/yr [14]; Windows 365 Enterprise prerequisites [21] | Price business at 2x consumer |
| Student / edu pricing | Parallels up to 50 percent [17] | Match |
| Free trial | Parallels 14 days [17]; CrossOver 14 days [13]; Setapp 7 days [48]; Windows 365 30 days [20] | 14 days is the norm |
| Routine discounting | Parallels seasonal sales [16]; CrossOver $54 vs $74 list [13] | Expect list price to be a ceiling |
| App Store distribution | UTM (feature-identical paid copy) [8]; Parallels has an App Store edition (page blocked) | Watch the 30/15 percent commission and the perpetual-upgrade limitation |
| DirectX 12 | D3DMetal (translation) yes; Parallels no (DX 11.1) [13] | Differentiator for 3D CAD viewports |
| Ads | None observed in any product | State "no ads" explicitly anyway |

## CAD / AutoCAD relevance

- AutoCAD for Mac is not a 1:1 port: QuickCalc, block-table lookup, the classic toolbar UI and Bing-map GEOMAP are Windows-only, and every AutoCAD specialized toolset (Architecture, MEP, Electrical, Mechanical, Map 3D, Plant 3D, Raster Design) is Windows-only [33][36]. This is MIRRORZ's demand driver.
- Autodesk's position on VMs is hostile: "AutoCAD is not a supported product under Virtualization" [39]; "AutoCAD family products are not supported" in virtualized environments [36]; support may require reproducing on physical hardware [40]. Autodesk also states Windows on Arm devices are "not compatible with Autodesk products, which are based on 64-bit (x64) software" [34], and in its Parallels install-error article notes "ARM processors are not supported for a lot of desktop Autodesk products" [35]. Desktop Connector does not work in Windows-on-Arm under Parallels [38]. AutoCAD 2025 requires an x64 OS [34].
- Practical Parallels pain points Autodesk documents: selection lag fixed only by switching the VM hypervisor from Apple to Parallels [37]; cursor/display issues and hardware-acceleration failures [39]. AutoCAD for Mac 2024+ is Apple-silicon native [41].
- Pricing implication: the buyer already pays Autodesk and is told VMs are unsupported. A $79 to $149 tool that runs real Windows AutoCAD is priced against Windows 365's "design and engineering" SKU at $108.80 per month [20], not against a $9.99 utility.

## Strengths (what to match)

- Parallels: annual cadence, Microsoft authorization, edu discount, SSO business tier, trial, perpetual option [14][17][19].
- CrossOver: two-SKU ladder ($74/yr or $494 life), 14-day trial, curated compatibility database, support included; discounts to ~$54 [13][46].
- UTM: transparent "pay only to support us" App Store model [8].
- Setapp: multi-device tiers, annual discount up to 40 percent [48].
- Windows 365: monthly no-commitment billing, 30-day trial [20].

## Weaknesses (what MIRRORZ must beat)

- Parallels' true cost is $99.99/yr plus a Windows 11 Pro key (~$146 retail) [16][60][19]; perpetual pricing is so confusing that 2026 sources disagree by $90 [13][14].
- Parallels is subscription-first; forum sentiment calls SaaS a "plague" and prefers perpetual licences [58]; one documented user dropped Parallels Pro once Fusion became free [57]; Shadow is "so expensive for what it is" [59].
- CrossOver's $494 lifetime is a steep anchor that its own site discounts against [13].
- Free tools have no support or guarantees and churn (Whisky archived; Sikarugir "not a replacement") [10][11].
- Windows 365 needs a Microsoft 365 admin tenant, hostile to individual drafters [21].

## Proposed MIRRORZ pricing ladders

All ladders: no ads; no Windows licence required; 14-day trial; edu 50 percent off; same list price direct and on the App Store (15 percent commission under the Small Business Program below $1M [28]; steer perpetual buyers direct because the App Store cannot sell paid version upgrades cleanly).

**Ladder A: undercut Parallels, subscription-led.** Monthly $7.99; Annual $59.99; Perpetual + 12 months of updates $129 (update pass $49/yr); Family (5 Macs, via Family Sharing) $99.99/yr; Business $119/seat/yr. Rationale: 40 percent under Parallels Standard; sits inside the $4.99 to $14.99 prosumer band; $129 mirrors Parallels' historical perpetual anchor [18]. Risk: reads as "cheap Parallels" rather than "CAD-grade".

**Ladder B (recommended): prosumer, perpetual-first.** Monthly $9.99; Annual $79; Perpetual + 12 months of updates $149 (update pass $59/yr, never mandatory); Family $129/yr or $229 perpetual (5 Macs); Business $199/seat/yr (SSO, deployment profiles, priority support, LISP/plug-in compatibility reports). Rationale: CrossOver+ at $74/yr is the direct comparable for a translation layer [46]; MIRRORZ charges a small premium for CAD-specific validation; the perpetual tier answers the strongest sentiment signal [58]; TCO vs Parallels + Windows (~$246 year one) is under one third [14][60].

**Ladder C: CAD professional, freemium.** Free (1 app profile, community support, MIRRORZ badge); Pro $14.99/mo or $119/yr (2 Macs); Perpetual + 12 months $199; Studio/Business $249/seat/yr with certified AutoCAD/toolset profiles and SLA. Rationale: benchmark is Windows 365's engineering SKU at $108.80 per month [20], so $119/yr is trivially justified for a professional; the free tier neutralizes UTM/Fusion/Highball as acquisition competitors. Risk: free tier support load.

**"Switch from Parallels" offer (all ladders).** With any Parallels licence key or receipt: 50 percent off the first year (Ladder B: $39.50), or $99 perpetual trade-in (vs $149), plus credit for unused Parallels months (up to 6 months free), one-click import of the Windows apps found in the user's Parallels VM, and a written 30-day money-back guarantee. Time it to Parallels' August renewal wave [13][62].

## Reusable code, ideas, and license implications for MIRRORZ

- Wine (LGPL) is reusable in a commercial product if LGPL obligations are met; Highball and Sikarugir ship it that way [11][13]. CrossOver's own app layer is proprietary [13].
- D3DMetal ships inside Apple's Game Porting Toolkit under Apple's own licence; Sikarugir's README calls it "restrictive proprietary licensing unsuitable for commercial ports" and Highball labels it "non-commercial, downloaded separately" [11][13]. Do not bundle D3DMetal; rely on DXMT (MIT/LGPL per Highball) and DXVK (Zlib) for shippable DirectX, or obtain terms from Apple. Apple's GitHub GPTK repo (skills, samples, metal-cpp) is Apache-2.0 [32].
- UTM's d3dmetal-native (MIT) shows a non-Wine host interface for D3DMetal (swapchains, cross-process sharing, pseudo-HWNDs); useful design reference even if the framework itself cannot be redistributed [9].
- Highball's CC0 compatibility database with provenance is directly reusable and worth seeding with CAD entries [13].
- Whisky (GPL-3) is archived; GPL-3 code cannot be mixed into a closed app, but its SwiftUI bottle-management UX is a pattern to copy, not code to copy [10].
- Business rules to borrow: CrossOver's two-SKU simplicity, Parallels' edu discount and trial, Setapp's usage-weighted developer payouts (if MIRRORZ ever lists on Setapp, expect ~70 percent of the pooled fee shared by usage) [48].

## Open questions

1. Official Parallels prices (especially Standard perpetual $129.99 vs $219.99, and whether v27 changed pricing) could not be fetched; verify on parallels.com/products/desktop/buy.
2. Official CrossOver, Setapp and Shadow price pages are blocked here; confirm $74/$494, $14.99/$18.99/$22.99, and Shadow tiers.
3. Windows 11 Pro retail price from Microsoft Store (HTTP 503 during research).
4. Whether Microsoft has extended "authorized solution" status beyond Parallels 20 (the page still names 18/19/20) [19].
5. Legal terms for commercial redistribution of D3DMetal; whether Apple offers a commercial licence.
6. Parallels App Store in-app prices (apps.apple.com blocked).
7. Press reviews (Macworld, Ars, PCMag, TidBITS) were unreachable; sentiment rests on GitHub-hosted blogs and HN/Reddit mirrors.

## Sources (numbered list of URLs with dates)

1. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/p/parallels.rb (fetched 2026-09-06; version 27.0.1-58670)
2. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/c/crossover.rb (fetched 2026-09-06; 26.3.0); vmware-fusion.rb returns 404
3. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/u/utm.rb (fetched 2026-09-06; 4.7.5)
4. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/s/setapp.rb (fetched 2026-09-06; 3.55.0)
5. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/s/shadow.rb (fetched 2026-09-06; 9.9.10457)
6. https://github.com/utmapp/UTM and https://raw.githubusercontent.com/utmapp/UTM/main/README.md (fetched 2026-09-06)
7. https://github.com/utmapp/UTM/releases.atom (v4.7.5 2026-01-03; v5.0.0 2026-01-12 to v5.0.5 2026-09-02)
8. https://raw.githubusercontent.com/utmapp/mac.getutm.app/main/index.html (App Store FAQ; fetched 2026-09-06)
9. https://github.com/utmapp/d3dmetal-native (MIT; created 2026-07-04)
10. https://github.com/Whisky-App/Whisky (archived 2025-05-11) and https://github.com/Whisky-App/Whisky/releases/latest (v2.3.5, 2025-04-05)
11. https://github.com/Kegworks-App/Kegworks (redirects to https://github.com/Sikarugir-App/Sikarugir; README fetched 2026-09-06)
12. https://raw.githubusercontent.com/Sikarugir-App/homebrew-sikarugir/main/Casks/sikarugir.rb (Creator v1.0.1)
13. https://github.com/gauthierpiarrette/highball (created 2026-08-23); https://raw.githubusercontent.com/gauthierpiarrette/highball-website/main/content/vs/parallels.html and content/vs/crossover.html (commits 2026-08-29)
14. https://raw.githubusercontent.com/eliekh05/guides/main/guides/run-windows-on-mac-parallels-desktop.html (commits 2026-06-11/12)
15. https://raw.githubusercontent.com/ETACUDER/tmv-recon/main/docs/tally-on-mac.md (commit 2026-04-29)
16. https://raw.githubusercontent.com/Garymckn/Parallels-Coupon/main/README.md (commits 2025-05-27, 2026-05-19)
17. https://raw.githubusercontent.com/aegisfleet/tool-survey-report/main/_reports/parallels-desktop.md (report date 2026-06-14)
18. GitHub mirror of ZDNet Parallels Desktop 18 review text, e.g. https://github.com/techidaily/site-tech-savvy (2022-era pricing)
19. https://support.microsoft.com/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c (fetched 2026-09-06 via Microsoft Learn MCP)
20. https://www.microsoft.com/en-us/windows-365/business/compare-plans-pricing (fetched 2026-09-06)
21. https://www.microsoft.com/en-us/windows-365/enterprise/compare-plans-pricing (fetched 2026-09-06)
22. https://learn.microsoft.com/windows-365/business/whats-new (week of 2026-05-04 pricing update)
23. https://learn.microsoft.com/windows-365/agents/pricing-paygo-always-available
24. https://learn.microsoft.com/windows/arm/iso
25. https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation and https://learn.microsoft.com/windows/arm/apps-on-arm-program-compat-troubleshooter
26. https://learn.microsoft.com/windows/arm/faq
27. https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/ (fetched 2026-09-06)
28. https://developer.apple.com/app-store/small-business-program/ (fetched 2026-09-06)
29. https://developer.apple.com/app-store/subscriptions/ (fetched 2026-09-06)
30. https://developer.apple.com/news/ (price/tax update notices 2026-01-29 and 2026-08-27)
31. https://developer.apple.com/tutorials/data/documentation/virtualization.json (fetched 2026-09-06)
32. https://developer.apple.com/games/game-porting-toolkit/ and https://github.com/apple/game-porting-toolkit (Apache-2.0; created 2026-06-08)
33. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Compare-Features-AutoCAD-for-Windows-vs-AutoCAD-for-Mac.html
34. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html and https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-the-Smart-Block-feature-of-AutoCAD-2025-available-on-ARM-x86-or-x86-operating-systems.html
35. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html
36. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Are-AutoCAD-Toolsets-supported-on-Mac-OS.html
37. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Selection-in-AutoCAD-products-lags-for-several-seconds-on-Apple-Mac-computer-with-Parallels-running-Windows.html
38. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
39. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-on-Citrix-slow-mouse-performance.html and .../Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html
40. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Running-3ds-Max-and-Maya-in-Virtual-Environments.html
41. https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-EA31738F-CDDE-4170-970A-745BC19C7674
42. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-LT-for-Mac-purchased-from-Apple-vs-purchased-from-Autodesk-or-a-reseller.html
43. Broadcom announcements as mirrored: https://github.com/kherrick/hacker-news (2024-05-14 entry linking blogs.vmware.com/teamfusion/2024/05/fusion-pro-now-available-free-for-personal-use.html); https://github.com/kherrick/lobsters (2024-11-11 entry linking blogs.vmware.com/cloud-foundation/2024/11/11/vmware-fusion-and-workstation-are-now-free-for-all-users/); https://github.com/Chaoses-Ib/ComputerHardware (Virtualization/Hosted/VMware/README.md quoting the Broadcom statement)
44. https://github.com/MKV-Auto/mkv-auto-release/blob/main/docs/Guides/VM_SETUP_MACOS.md (Fusion free for personal and commercial use, no key, Broadcom portal download)
45. https://github.com/ryotakato/ryotakato.github.io/blob/main/_posts/2025-11-26-build-windows-on-mac.md (Fusion 13.6.4)
46. https://raw.githubusercontent.com/vectorcmdr/NMSE/main/docs/dev/crossover-macos-guide.md (commits 2026-03-20, 2026-04-16)
47. https://github.com/izaart95-jpg/tech-grimoire/blob/main/fundamentals/wine-compatibility.md
48. https://raw.githubusercontent.com/serpcompany/serp-pass/main/docs/research/SETAPP_PRODUCT_REFERENCE.md (setapp.com/pricing captured 2026-08-13)
49. https://raw.githubusercontent.com/jessems/appstores.dev/main/content/stores/setapp.mdx (updated 2025-01-10)
50. https://github.com/adamsappletech/adamsappletech.github.io/blob/main/_posts/2022-06-10-setapp.md; https://github.com/boochtek/mac-setup/blob/master/misc/setapp.sh; https://github.com/ndeville/notes.github.io (apps/setapp); https://github.com/ChrisChinchilla/chrischinchilla.com (2023 Setapp post)
51. https://raw.githubusercontent.com/hzlzh/Best-App/master/README.md (last commit 2026-03-17; entries undated)
52. https://github.com/totoantonio/diskcleaner-site/blob/main/src/content/blog/cleanmymac-alternative.md (2026-03-13)
53. https://github.com/pleasedodisturb/macOS-nirvana/blob/main/research/perplexity-alfred-research.md (Alfred Powerpack $44.99)
54. https://github.com/qhkm/kitakod-showcase/blob/main/docs/PRICING_ANALYSIS.md (CleanShot X, Snagit, DevUtils, Parallels Toolbox)
55. https://github.com/Pinggy-io/pinggy_website/blob/main/content/blog/best_playit_gg_alternatives.md (GeForce Now tiers, Jan 2026 cap; Shadow status 2026)
56. https://github.com/Miro0o/miniWorldModel (Cloud Gaming.md, Shadow from $39.99/mo); https://github.com/interlunar/win10-regtweak (Research.md, $35/mo); https://github.com/aleksandr-vin/aleksandr-vin.github.io/blob/main/_posts/2021-07-29-half-life-alyx-on-oculus-quest-2.md
57. https://github.com/questionlp/linhpham.org_jekyll/blob/main/_posts/2024-07-29-migrating-from-macos-fedora-framework-laptop-16.md
58. https://github.com/jnd0/hn-brief/blob/main/summaries/2026/02/02.md (HN discussion summary on subscriptions vs perpetual licences)
59. https://github.com/rumca-js/RSS-Link-Database-2025 (r/selfhosted mirror, 2025-01-05, "Shadow.tech ... so expensive for what it is")
60. https://github.com/Tapsa210/amazon_top1000_analysis (Amazon_bestsellers_items_2025.csv: Windows 11 Pro OEM $146.18)
61. https://learn.microsoft.com/answers/a/12348799 (Microsoft Q&A recommending Parallels over UTM for Office on Apple silicon)
62. https://github.com/nowscott/EverydayTechNews (news_archive/2025-08/26.md, Parallels Desktop 26 release headline); https://github.com/bobkingdom/TrendRadar (2026-08-26 Parallels Desktop 27 release headline)
