# Free Windows-on-Mac Tools Through Users' Eyes: UTM, Whisky, Kegworks/Sikarugir and PlayOnMac (2024-2026)

_Research date: 2026-09-03_

> **Method and evidence caveat.** This session's WebSearch budget was already exhausted before the first query ran, so **no web searches were performed**; the 10-query minimum in the brief could not be met. Instead, roughly 45 pages were fetched directly (3-6 Sep 2026) plus 8 Autodesk knowledge-base articles via the Autodesk Product Help MCP. The sandbox egress policy blocked every review, news and forum site tried (Mac App Store, iTunes lookup, MacRumors, AppleInsider, 9to5Mac, Macworld, Ars, CodeWeavers blog, Reddit, Hacker News, Lobsters, Lemmy, Medium, AlternativeTo, Product Hunt, Apple Community, WineHQ forum, Autodesk forums, Wikipedia, Homebrew formulae API) and the official sites mac.getutm.app, docs.getutm.app, playonmac.com and wineformac.org. What did work: GitHub (repos, releases, tags, issues, discussions, raw docs, Homebrew cask sources), the GitHub issue-search API and Autodesk KBs. **User voice below is therefore GitHub-only** (issue/discussion authors), which skews toward technically engaged users; Reddit/App Store-style sentiment is not represented. Every price, version and status statement is tied to a fetched page in the Sources list.

## TL;DR

- **UTM is the only one of the four with a full Windows VM and real momentum.** Stable v4.7.5 (3 Jan 2026, QEMU 10.0.2) plus a 5.0 beta line ending at v5.0.5 (2 Sep 2026) that ships the first experimental DirectX driver for Windows guests. Free on GitHub; the identical App Store build is a ~$9.99 "support the developer" purchase. Users' three evergreen complaints are unchanged since 2021: x86-64 emulation is "extremely slow, unusable", Windows guests get no 3D acceleration (wontfix in 2022; a May 2026 report still shows Windows 11 ARM on the Microsoft Basic Render Driver), and Windows setup needs CrystalFetch, SPICE guest tools and a 24H2 driver workaround.
- **Whisky is dead, by its author's choice.** Maintenance notice published 9 Apr 2025, last release 2.3.5 (5 Apr 2025), repository archived 11 May 2025, Homebrew cask deprecated 2025-04-09 as `:unmaintained`. Isaac Marovitz's stated reason: Whisky drew users away from CrossOver and "the revenue from CrossOver is what keeps Wine on Mac alive", so he told users to buy CrossOver. Fallout: Steam broke on macOS 15.4.1 with nobody to fix it, users apologising for filing bugs, and a community fork (frankea/Whisky, 3.7.0 on 30 Aug 2026, 648 stars) trying to carry on.
- **"Kegworks" no longer exists under that name.** The Wineskin successor was renamed Sikarugir (Homebrew tap renamed 9 Aug 2025); 3.6k stars, macOS 14+, **Rosetta 2 required**, D3DMetal "can not be used for commercial ports", and its own README says it "is not a replacement for CrossOver or Whisky". Its maintainer cannot promise it will survive macOS 28.
- **PlayOnMac is legacy software.** Last GitHub release 4.4 (17 May 2024), Homebrew at 4.4.4, 2025-26 commits are Python syntax-warning fixes, and the promised successor Phoenicis has not tagged a release since v5.0-alpha.3 (29 Sep 2020). No Apple Silicon work is visible anywhere.
- **For MIRRORZ/AutoCAD:** none of the four gives GPU-accelerated x86 Windows, and Autodesk states it does not support Wine layers or virtual environments. The clearest "I wish this existed" signals in the threads are Rosetta-class x86 speed inside a VM, 3D acceleration for Windows guests, a runtime that does not break on every macOS point release, and a sustainable way to pay a maintainer (UTM users asked how to fund it outside the App Store; Whisky's author redirected his users to a paid product).

## Current status (version, date, maintainer, momentum)

| Tool | Latest version and date | Maintainer | Momentum (as of Sep 2026) | Sources |
|---|---|---|---|---|
| **UTM** | Stable **v4.7.5**, tagged 3 Jan 2026 (marked "Latest"); beta **v5.0.5**, 2 Sep 2026 (v5.0.0 11 Jan, 5.0.1 19 Jan, 5.0.2 24 Feb, 5.0.3 3 May, 5.0.4 1 Aug 2026). Homebrew cask 4.7.5, macOS Big Sur+ | osy / Turing Software (utmapp org) | Strong: 35.4k stars; monthly-ish betas; DirectX-for-Windows work landed Aug-Sep 2026 | [1][2][3][4][5][23] |
| **Whisky** | **v2.3.5**, 5 Apr 2025 (final). Notice 9 Apr 2025; repo archived (read-only) 11 May 2025; cask `deprecate! 2025-04-09 :unmaintained` | Isaac Marovitz (ended) | None upstream; 15.1k stars frozen. Community fork frankea/Whisky: 3.6.0 (4 Aug), 3.6.1 (13 Aug), 3.7.0 (30 Aug 2026), 648 stars, macOS 15+ | [24][25][26][27][30][35][36] |
| **Kegworks -> Sikarugir** | Creator v1.0.1 (21 Jan 2026, tap bump 22 Jan 2026); earlier Kegworks 2.0.3 (tap created 21 Mar 2025), 2.0.4 (11 Apr 2025); tap renamed 9 Aug 2025; last tap commit 6 Sep 2026 | Gcenx (Sikarugir-App org) | Moderate: 3.6k stars, 155 commits, active tap; discussions frequently unanswered | [38][39][40][41][42][43] |
| **PlayOnMac** | **4.4** (GitHub release 17 May 2024); Homebrew cask **4.4.4** from repository.playonmac.com; last commits 22 Feb 2026 (Python 3.10 warning fix), 7 Nov 2025 (dead link) | qparis (PlayOnLinux) | Minimal: 494 stars; successor Phoenicis (732 stars, LGPL-3.0) last tag v5.0-alpha.3 29 Sep 2020, dependabot-only commits to 28 Jan 2025 | [45][46][47][48][49][50][51] |

Date conflicts noted: the fetch tool read the v4.7.5 and v5.0.5 release pages as "January 3, 2025" and "September 2, 2025" because GitHub omits the year for current-year dates; the tags page, the v4.7.5 announcement thread (3 Jan 2026) and the release note's "Liquid Glass design for *OS 26" all place them in 2026, which is used here [2][3][5][20]. The frankea fork's README says the original was "archived on April 9, 2025"; GitHub's own banner says 11 May 2025 and the notice's first commit is 9 Apr 2025, so: notice 9 Apr, archive 11 May [24][27][35].

## Pricing and licensing (table)

| Tool | Price (verified) | License | Notes |
|---|---|---|---|
| UTM | Free download from GitHub/website. Official docs: "UTM is and always will be completely free and open source... The Mac App Store version is identical to the GitHub version and there are no features left out. The only advantage... is that you can get automatic updates"; buying it "directly funds the development" [6][7]. Users report the App Store listing at **$9.99** ("The App Store version cost 10$. But the free version is on the GitHub and the website", 6 Mar 2025) [14][15] | Apache-2.0 frontend with GPL components (QEMU) [1] | apps.apple.com blocked; price is user-reported, medium confidence |
| Whisky | Free | GPL-3.0 [24] | Built on CrossOver 22.1.1 sources + Apple GPTK/D3DMetal, DXVK-macOS, MoltenVK [28]; README asks users to "Support the work of CodeWeavers using our affiliate link" [28] |
| Sikarugir (ex-Kegworks) | Free (Homebrew tap) | Wineskin/Winery components LGPL-2.1; other components under their own terms; **D3DMetal "closed source and has a restrictive license it can not be used for commercial ports"** [38][39][41] | Gcenx GPTK builds: "ensure you comply with Apple's License.pdf for D3DMetal" [44] |
| PlayOnMac | Free | GPL-3.0 (POL-POM-4); Phoenicis LGPL-3.0 [45][49] | |

## How it works (architecture)

- **UTM** is a SwiftUI front end over a QEMU fork. On Apple Silicon it "run[s] ARM64 operating systems... at near native speeds" via Hypervisor.framework, while "lower performance emulation is available to run x86/x64" through QEMU's TCG JIT [7]. macOS guests use Virtualization.framework [1]. Graphics: SPICE/QXL or virtio-gpu; 3D goes guest driver -> virglrenderer/ANGLE -> Metal. The in-repo graphics doc states that for Windows the "guest drivers for VirtIO GPU are not available or are incomplete", and GPU acceleration is unavailable when using UTM Remote [9]. The 5.0 betas add an experimental Windows driver: "Modern accelerated graphics for Windows 11 is now available on UTM for the first time. The driver is still experimental and games compatibility is currently limited" (v5.0.4, 1 Aug 2026); v5.0.5 routes DirectX 12 through a D3DMetal backend "when available", DirectX 11 on iOS via DXMT, and requires macOS 13+ for these features [4][5].
- **Whisky** was a native SwiftUI "bottle" manager around WhiskyWine (a CrossOver-22.1.1-derived Wine build) with Apple's Game Porting Toolkit D3DMetal, DXVK and MoltenVK; no Windows OS is installed, apps run through Wine + Rosetta 2 on Apple Silicon (macOS 14+) [24][28].
- **Sikarugir/Kegworks** is the Wineskin lineage: it builds a self-contained .app "wrapper" per Windows program, with selectable renderers WineD3D, D9VK, DXMT, D3DMetal and DXVK; "Apple Silicon systems require Rosetta2" and macOS 14+ [38][39]. Kegworks-era README supported macOS 10.15.4+ and installed via `Kegworks-App/kegworks` [41].
- **PlayOnMac** is a Python/wxPython GUI over stock Wine with scripted installers, shared with PlayOnLinux; the repo points to Phoenicis (Java) as version 5 [45].

## Feature checklist (table: feature | status | notes)

| Feature | Status | Notes |
|---|---|---|
| Run a full x86-64 Windows OS on Apple Silicon | UTM: yes, emulated. Others: no (Wine only) | UTM defaults x86-64 guests to **one core** "due to memory ordering requirements"; forcing more is "at the cost of correctness... odd crashes" [8] |
| Run Windows 11 ARM natively virtualized | UTM: yes | Users report host reboots when launching 24H2 VMs (Dec 2024, UTM 4.6.4, still open) [17] |
| 3D/GPU acceleration for Windows guests | UTM: officially no ("does not currently support GPU emulation/virtualization on Windows") [7]; experimental in 5.0.4/5.0.5 betas [4][5] | 2022 request closed **wontfix** [10]; May 2026 report: Windows 11 ARM guest falls back to "Microsoft Basic Render Driver (d3d10warp.dll)" while the same game runs under CrossOver [13] |
| DirectX via Wine translation | Whisky/Sikarugir: D3DMetal (DX11/12), DXVK, DXMT; PlayOnMac: WineD3D only | D3DMetal is non-commercial-only [39][44]; frankea fork cannot execute GPTK payloads without Wine unwinder changes (issue open 31 Jul 2026) [37] |
| Guided Windows setup | UTM: 10-step guide, needs CrystalFetch ISO tool and SPICE guest tools; 24H2 needs eject/reinstall/reset workaround [8] | "Getting ready" stuck thread: 102 comments [16] |
| Survives macOS updates | Whisky: no ("Apps and games may break at any time") [24]; macOS 15.4.1 broke Steam [31] | Sikarugir maintainer on macOS 28: "no way to be 100% sure" [43] |
| Rosetta 2 dependency | Whisky, Sikarugir, Homebrew wine-stable: required [38][52]; UTM: not required | Homebrew `wine-stable` 11.0_1 cask carries a `disable!` dated 2026-09-01 for Gatekeeper check failures [52] |
| Paid support channel | None; UTM support is community Discord/GitHub; Whisky redirected users to CrossOver [26][28] | |
| Automatic updates | UTM: App Store build only [6]; Whisky: Sparkle (dead) [28] | |

## CAD / AutoCAD relevance

- **Autodesk policy.** "AutoCAD is not supported when run using Wine or other Windows compatibility layers"; "Linux distributions and Wine-based environments are not part of Autodesk's supported platforms" [53]. Virtualization "setups are not something Autodesk supports"; support requires reproducing an issue "in a physical environment" [56]. Its Parallels KB lists the symptoms a CAD user will recognise: "Overall performance is slow... Linework displays choppy or dashed. Mouse cursor performance is sluggish... a system error... hardware acceleration is turned off" [54]. Desktop Connector "is not compatible with Windows ARM architecture" [55].
- **What that means per tool.** UTM x86-64 Windows would run the real AutoCAD installer but on a single emulated core with no 3D acceleration, which users already describe as "unusable" for an Ubuntu desktop, let alone a DirectX 11 CAD viewport [11][8][7]. UTM Windows-on-ARM is fast but AutoCAD's Windows-ARM story is unsupported and the guest is on the Basic Render Driver [13][55]. Whisky/Sikarugir/PlayOnMac would need AutoCAD's installer, .NET stack and D3D11 viewport to survive Wine; no GitHub issue in any of the four repos mentions AutoCAD at all (search returned zero results), i.e. these communities are gamers, not CAD users.
- **Net:** there is no free tool in 2026 that a CAD professional can recommend; the gap MIRRORZ targets is real and un-served by the FOSS layer.

## Strengths (what to match)

1. **Radical transparency on limits.** UTM's own site says x86 emulation is "lower performance" and that Windows lacks 3D acceleration; the maintainer answers slowness reports with "Yes that's expected as x86_64 is being emulated" [7][11]. Users trust a tool that does not oversell.
2. **Free-plus-tip pricing that people accept.** The App Store build is a pure support purchase with "no features left out", and users volunteered to fund UTM via Patreon/GitHub Sponsors/crypto as early as 2021 [6][19].
3. **Frictionless ISO acquisition.** UTM's CrystalFetch pulls legitimate Windows ISOs from Microsoft inside the wizard flow [8].
4. **Native-feeling Mac UI.** Whisky's SwiftUI bottle manager earned 15.1k stars and a fork the moment it died; Sikarugir produces a standalone .app per program [24][35][38].
5. **Open renderer choice.** Sikarugir exposes WineD3D/D9VK/DXMT/D3DMetal/DXVK toggles per wrapper; UTM 5.0.5 layers D3DMetal and DXMT under a VM [39][5].

## Weaknesses (what MIRRORZ must beat)

1. **x86 speed.** Four years of "extremely slow, unusable" reports (M1 Air 2021 through "still unusable after four years" in Mar 2025) with UTM using "only 1 of 9 cores" [11]. A user-documented path to 4-5x (TSO mode, return-address prediction, ARM flag extensions) sits open since Jul 2023 partly because TSO needs a private entitlement "that couldn't be done with the App Store version" [12].
2. **No Windows GPU.** Closed wontfix in 2022; in May 2026 a Windows 11 ARM guest still lands on the software renderer and the reporter notes CrossOver runs the same game [10][13]. The 5.0 driver is "experimental", games compatibility "limited", and needs a fresh install because it "could lead to instability" [4].
3. **Setup friction.** Third-party ISO tool, guest-tool ISO, eject-reinstall-reset dance for 24H2, host kernel panics on VM launch, and a 102-comment "stuck on Getting ready" thread [8][16][17].
4. **Abandonment risk is the norm.** Whisky's author quit and told users to pay CodeWeavers; Whisky users kept filing bugs while apologising ("I know this project is now inactive") [26][31]; Sikarugir's maintainer cannot promise macOS 28 [43]; PlayOnMac's successor has not shipped in six years [49][51]; even UTM users needle "third and final release... quality control issues?" [20].
5. **Rosetta cliff.** Every Wine-based option needs Rosetta 2 [38][52]; the community is already discussing FEX and "Metal-accelerated virtual machines" as post-Rosetta escape hatches [43].
6. **Licensing traps.** Apple's D3DMetal is the fastest DX11/12 path but "can not be used for commercial ports" [39][44]; CrossOver-derived Wine builds carry GPL/LGPL obligations [28].
7. **No support.** Unanswered discussions dominate Sikarugir and UTM Help; Whisky's Steam breakage (67 comments) got no maintainer answer before the archive [42][29].

### What users say they wish existed
- Rosetta-class x86 performance inside a VM (#5460) and multi-core x86 emulation that does not crash [12][8].
- Real 3D/DirectX for Windows guests (#3459, 2024 "gpu passthrough to play directx games", #7732) [10][21][13].
- Nested virtualization so WSL2 works in a Windows ARM guest (#6821, 23 comments) [22].
- A way to fund the maintainer outside Apple's store (#2332) [19]; conversely Whisky's author argued users **should** pay for CrossOver because free wrappers starve Wine-on-Mac development [26]. No verbatim "I would pay $X for..." quotes were reachable; treat willingness-to-pay as inferred (App Store tip purchases, CrossOver redirect, fork activity).

## Reusable code, ideas, and license implications for MIRRORZ

- **UTM (Apache-2.0 frontend; QEMU fork GPL-2.0/LGPL-2.1).** The SwiftUI VM wizard, CrystalFetch ISO fetcher and Windows guest-tools packaging are reusable patterns; linking the QEMU fork or virtio-gpu driver work pulls GPL obligations into any shipped binary, so treat QEMU as a separately distributed process, not a library [1][8]. Its Graphics.md is the best public map of the virgl/ANGLE/Metal pipeline and its Windows gaps [9].
- **Whisky (GPL-3.0).** Bottle model, Sparkle updates, WhiskyCmd CLI and per-bottle DXVK/Metal-HUD toggles are good UX references; code is GPL-3.0, so copy ideas, not files. Its WhiskyWine is CrossOver 22.1.1-derived (LGPL/GPL mix) [24][28].
- **Sikarugir/Kegworks (LGPL-2.1 core).** Wrapper-per-app packaging and the renderer switchboard are worth mirroring; **do not ship D3DMetal** in a commercial product [39][44]. DXVK/DXMT/MoltenVK (open licences) are the commercially safe translation layers.
- **PlayOnMac/Phoenicis (GPL-3.0/LGPL-3.0).** Scripted installer recipes are the reusable idea; the codebase itself is stale.
- **Strategic lesson.** The free layer is gamer-focused, Rosetta-bound and maintainer-fragile; a paid product that owns the x86 translation and GPU path (no D3DMetal, no Rosetta dependency) and offers real support is differentiated on every axis users complain about.

## Open questions

1. Actual 2026 App Store price and rating count for UTM (apps.apple.com and iTunes lookup blocked; $9.99 is user-reported from Mar 2025).
2. Whether UTM 5.0.x's experimental DirectX driver reaches x86-64 (emulated) guests or only Windows 11 ARM, and its stability by GA.
3. Apple's official wording on Rosetta availability beyond macOS 27 (support.apple.com and the macOS 26 release notes returned no body); only a community paraphrase was captured [43].
4. Reddit/App Store/MacRumors sentiment on the Whisky shutdown and on "would pay for" alternatives (all blocked).
5. Whether the `wine-stable` Homebrew disable (dated 2026-09-01, Gatekeeper failures) is a transient packaging issue or a durable macOS 26 policy problem for all unsigned Wine builds [52].
6. Current PlayOnMac binary status on Apple Silicon (playonmac.com blocked; no GitHub issues mention M-series at all).

## Sources (numbered list of URLs with dates)

1. https://github.com/utmapp/UTM - README, 35.4k stars, licence paragraph (fetched Sep 2026)
2. https://github.com/utmapp/UTM/tags - v5.0.5 2 Sep 2026 ... v4.7.2 19 Aug 2025 (fetched Sep 2026)
3. https://github.com/utmapp/UTM/releases/tag/v4.7.5 - "Latest", QEMU 10.0.2, Liquid Glass (3 Jan 2026)
4. https://github.com/utmapp/UTM/releases/tag/v5.0.4 - "v5.0.4 (Beta)", first accelerated Windows graphics (1 Aug 2026)
5. https://github.com/utmapp/UTM/releases/tag/v5.0.5 - "v5.0.5 (Beta)", DirectX/D3DMetal/DXMT, min-OS revert (2 Sep 2026)
6. https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/installation/macos.md - free/App Store statement (fetched Sep 2026)
7. https://raw.githubusercontent.com/utmapp/mac.getutm.app/main/index.html - marketing copy on emulation speed and no Windows GPU (fetched Sep 2026)
8. https://raw.githubusercontent.com/utmapp/docs.getutm.app/main/guides/windows.md - Windows 11 guide, single-core default, 24H2 workaround (fetched Sep 2026)
9. https://raw.githubusercontent.com/utmapp/UTM/main/Documentation/Graphics.md - graphics architecture, Windows driver gap (fetched Sep 2026)
10. https://github.com/utmapp/UTM/issues/3459 - "3d acceleration on windows", enhancement + wontfix (opened 8 Jan 2022)
11. https://github.com/utmapp/UTM/discussions/2533 - "On MacBook Air M1 it is extremely slow, unusable!" (15 May 2021; comments to 8 Mar 2025)
12. https://github.com/utmapp/UTM/issues/5460 - Rosetta-style x86 optimisations proposal (13 Jul 2023, open)
13. https://github.com/utmapp/UTM/issues/7732 - Windows 11 ARM guest on Basic Render Driver (31 May 2026, open)
14. https://github.com/utmapp/UTM/discussions/7076 - "App Store version cost 10$... free version is on the GitHub" (4-6 Mar 2025)
15. https://github.com/utmapp/UTM/issues/7046 - "on the appstore it says its 9.99" (4 Mar 2025)
16. https://github.com/utmapp/UTM/issues/3130 - Windows 11 "Getting ready" stuck, 102 comments (25 Sep 2021)
17. https://github.com/utmapp/UTM/issues/6919 - host reboots launching Windows ARM 24H2 VM, 35 comments (23 Dec 2024, open)
18. https://github.com/utmapp/UTM/issues/3330 - "UTM seems to run slower than Parallels Desktop" (22 Nov 2021, open)
19. https://github.com/utmapp/UTM/issues/2332 - "How can I help fund you without going through the apple app store" (25 Feb 2021)
20. https://github.com/utmapp/UTM/discussions/7558 - v4.7.5 announcement thread and user comments (3-4 Jan 2026)
21. https://github.com/utmapp/UTM/discussions?discussions_q=directx and ...?discussions_q=windows+x86+slow - thread listings incl. "gpu passthrough to be able to play directx games" (7 Sep 2024), "Extremely poor performance emulating all x64 OSes" (23 Aug 2022)
22. GitHub issue search (utmapp/UTM) via GitHub MCP - #6821 nested virtualization for Windows ARM/WSL2 (20 Nov 2024), #7531 (23 Dec 2025)
23. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/u/utm.rb - version 4.7.5, Big Sur+ (fetched Sep 2026)
24. https://github.com/Whisky-App/Whisky - archived 11 May 2025 banner, notice, 15.1k stars, GPL-3.0, macOS 14+
25. https://github.com/Whisky-App/Whisky/releases - v2.3.5 5 Apr 2025; 2.3.4 10 Nov 2024; 2.3.3 19 Sep 2024; 2.3.2 13 Apr 2024
26. https://raw.githubusercontent.com/Whisky-App/whisky-book/main/src/maintenance-notice.md - Isaac Marovitz's notice (fetched Sep 2026)
27. https://github.com/Whisky-App/whisky-book/commits/main/src/maintenance-notice.md - first commit 9 Apr 2025
28. https://raw.githubusercontent.com/Whisky-App/Whisky/main/README.md - components, CrossOver affiliate wording
29. https://github.com/Whisky-App/Whisky/issues/1199 - steamwebhelper breakage, 67 comments (6 Nov 2024)
30. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/w/whisky.rb - 2.3.5, `deprecate! date: "2025-04-09", because: :unmaintained`
31. https://github.com/Whisky-App/Whisky/issues/1372 - "macOS 15.4.1 breaks Steam" (26 Apr 2025)
32. GitHub issue search (Whisky-App/Whisky) via GitHub MCP - last issues Mar-Apr 2025 (#1351, #1353, #1355, #1357, #1362, #1364, #1365)
33. https://github.com/Whisky-App/Whisky/discussions - troubleshooting threads to 7 May 2025
34. https://raw.githubusercontent.com/Whisky-App/whisky-book/main/src/cx.md - "CrossOver supports more apps than Whisky..."
35. https://github.com/frankea/Whisky - community fork, 648 stars, macOS 15+, "Not affiliated with the original project"
36. https://github.com/frankea/Whisky/releases - 3.7.0 30 Aug 2026; 3.6.1 13 Aug; 3.6.0 4 Aug; Wine Libraries 4.6.4-beta.1 29 Aug 2026
37. https://github.com/frankea/Whisky/issues/163 - GPTK/D3DMetal payload unwinder problem (31 Jul 2026, open); issues list incl. #233 (26 Aug 2026)
38. https://github.com/Kegworks-App/Kegworks (redirects to https://github.com/Sikarugir-App/Sikarugir) - 3.6k stars, macOS 14+, Rosetta 2, D3DMetal restriction, "not a replacement for CrossOver or Whisky"
39. https://raw.githubusercontent.com/Sikarugir-App/Sikarugir/main/README.md - renderer list, Homebrew commands (fetched Sep 2026)
40. https://github.com/Sikarugir-App/homebrew-sikarugir/commits/main - kegworks 2.0.3 (21 Mar 2025), 2.0.4 (11 Apr 2025), rename to sikarugir.rb (9 Aug 2025), v1.0.1 (22 Jan 2026), last commit 6 Sep 2026
41. https://github.com/gxgl/Kegworks - Kegworks-era README snapshot (macOS 10.15.4+, `Kegworks-App/kegworks` tap)
42. https://github.com/orgs/Sikarugir-App/discussions - thread list (Oct 2025 - Aug 2026), many unanswered
43. https://github.com/orgs/Sikarugir-App/discussions/228 - "Prospects for this app under macOS 27 and macOS 28?" Gcenx reply (23 May 2026)
44. https://github.com/Gcenx/game-porting-toolkit/releases - GPTK 3.0-3 (3 Mar 2025), Sonoma+, 16 GB, D3DMetal licence wording
45. https://github.com/PlayOnLinux/POL-POM-4 - "PlayOnLinux and PlayOnMac 4", GPL-3.0, 494 stars, Phoenicis note
46. https://github.com/PlayOnLinux/POL-POM-4/releases - 4.4 (17 May 2024)
47. https://github.com/PlayOnLinux/POL-POM-4/commits/master - commits 22 Feb 2026, 5 Jan 2026, 7 Nov 2025, Dec 2024
48. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/p/playonmac.rb - version 4.4.4, repository.playonmac.com
49. https://github.com/PhoenicisOrg/phoenicis - LGPL-3.0, 732 stars, 3,073 commits
50. https://github.com/PhoenicisOrg/phoenicis/tags - v5.0-alpha.3 (29 Sep 2020)
51. https://github.com/PhoenicisOrg/phoenicis/commits/master - dependabot/translation commits to 28 Jan 2025
52. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/w/wine-stable.rb - 11.0_1, Gcenx builds, `requires_rosetta`, `disable!` 2026-09-01
53. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-and-verticals-on-Linux.html - Wine not supported (via Autodesk Product Help MCP, Sep 2026)
54. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html - symptoms in a VM (via MCP)
55. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html - Desktop Connector not on Windows ARM (via MCP)
56. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Information-on-configuring-Revit-using-VMware-Horizon-roaming-profiles.html - "Virtualization setups are not something Autodesk supports" (via MCP)
57. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Selection-in-AutoCAD-products-lags-for-several-seconds-on-Apple-Mac-computer-with-Parallels-running-Windows.html - hypervisor workaround (via MCP)

Blocked (not fetched, not cited for facts): mac.getutm.app, docs.getutm.app, apps.apple.com, itunes.apple.com, playonmac.com, wineformac.org, codeweavers.com, appleinsider.com, macrumors.com, 9to5mac.com, macworld.com, arstechnica.com, reddit.com, news.ycombinator.com, hn.algolia.com, lobste.rs, lemmy.world, medium.com, alternativeto.net, producthunt.com, formulae.brew.sh, forums.macrumors.com, discussions.apple.com, forum.winehq.org, forums.autodesk.com, support.apple.com, developer.apple.com (pages returned no body), en.wikipedia.org, bing.com, duckduckgo.com, api.github.com (403).
