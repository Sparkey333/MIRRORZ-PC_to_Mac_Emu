# App Store Review Guidelines and Google Play Policy as Applied to Virtualization, Emulation and Wine Apps

_Research date: 2026-09-03_

> Method note. Official facts come from pages fetched 2026-09-03 (developer.apple.com, developer.android.com, GitHub, Autodesk help). Vendor/news domains (apple.com newsroom, parallels.com, mac.getutm.app, support.google.com, court sites) were unreachable; facts resting only on search summaries are marked **[SS]** and need re-verification.

## TL;DR

- **Mac App Store: feasible for a hypervisor product, unprecedented for a Wine product.** App Sandbox is mandatory [11]; 2.4.5 bans third-party installers, downloading "additional code", licence keys and non-store updates [1]. Sandbox-compatible `com.apple.security.hypervisor` / `.virtualization` entitlements (macOS 11+) [7][8] are what Parallels App Store Edition and UTM use.
- **Bundling Wine (LGPL-2.1+ [17]) or QEMU (GPL parts [18]) in a store app is a licensing risk, not a technical block.** Forum consensus: LGPL "technically allowed" but code signing makes relinking impractical [16]; UTM ships on the Mac App Store regardless [18][29]. Needs counsel.
- **iOS is a dead end for AutoCAD-class work.** 2.5.2 forbids executing downloaded code [1]; 4.7 only lets "retro game console and PC emulator apps ... offer to download games" [1][3]; `allow-jit` is macOS-only [9]; UTM SE is interpreter-only [18]; StikDebug (approved May 2025) is "no longer available on the App Store" [20][36].
- **Direct macOS distribution (Developer ID + notarization) is the primary channel.** Notarization is mandatory for Developer ID software on 10.15+ [12]; since Sequoia users "can no longer Control-click to override Gatekeeper" [6]. It permits perpetual licences, JIT, Wine/QEMU and self-updates.
- **Selling outside the store:** the US storefront needs no entitlement and the anti-steering ban "does not apply" [1][5]; the Ninth Circuit (2025-12-11) allowed a cost-based commission, Apple proposed 15%/5% in Aug 2026, and SCOTUS hears the case in its October 2026 term **[SS]** [30]-[34]. EU terms effective **2026-10-01**: IAP 26%, alternative PSP 20%, link-out 15%, 5% Core Technology Commission (Small Business 15/10/10) [15]. Google Play matters only through Android developer verification (enforced 2026-09-30 in BR/ID/SG/TH, global 2027; US$25 account with ID/D-U-N-S), which hits sideloaded Winlator-class apps [23][24][35].

## Current status (version, date, maintainer, momentum)

| Regime | Maintainer | Latest revision | Momentum |
|---|---|---|---|
| App Review Guidelines (iOS + Mac App Store) | Apple | Revised 2026-06-08 (intro, 1.2, 4.3, 4.5.3) [2]; 4.7 changed 2024-08-01 [3]; US 3.1.1/3.1.3 changed 2025-05-01 [5] | 2024-25 loosened emulators and US steering; 2026 targets low-quality apps |
| macOS Developer ID / notarization / Gatekeeper | Apple | notarytool mandatory since 2023-11-01 [12]; Sequoia Gatekeeper change 2024-08-06 [6] | Stable; more friction only for un-notarized apps |
| Mac App Store sandbox + VM entitlements | Apple | Entitlements macOS 11.0+ [7][8]; sandbox mandatory [11] | Stable; Parallels ASE and UTM are live precedents |
| Apple EU (DMA) terms | Apple | Updated 2026-08-18, effective 2026-10-01 [15] | CTF gone, 5% CTC, one fee schedule |
| US anti-steering (Epic v. Apple) | N.D. Cal. / 9th Cir. / SCOTUS | Order 2025-04-30; 9th Cir. No. 25-2935 2025-12-11 [32]; stay application 2026-05-04; Apple proposes 15%/5% 2026-08-13; SCOTUS Oct 2026 term **[SS]** [30]-[34] | Unsettled: 0% today, cost-based rate likely |
| Google Play "Device and Network Abuse" | Google | Text as quoted by developers 2022-23 [26] | Stable: no downloaded executable code; VM/interpreter exception |
| Android developer verification | Google | Aug 2026 advanced flow; 2026-09-30 regional enforcement; 2027 global [23][25] | Rolling out now |
| Precedent apps | UTM, Winlator, StikDebug | UTM v4.7.5 (QEMU 10.0.2; GitHub shows "03 Jan", i.e. 2026) [19]; Winlator v11.1.0 ("12 Jun", 2026) [22] | Active |

## Pricing and licensing (table)

| Item | Amount / terms | Source | Confidence |
|---|---|---|---|
| Apple Developer Program | US$99/yr incl. App Store, Developer ID, notarization | [14] | High |
| Apple Developer Enterprise Program | US$299/yr, in-house only | [14] | High |
| Apple EU commissions from 2026-10-01 | IAP 26% (15% SBP/after yr 1); alt in-app PSP 20% (10%); link-out 15% (10%); CTC 5% on alt-marketplace/Web Distribution sales; CTF, Initial Acquisition and Store Services fees eliminated | [15] | High |
| US storefront linked-out purchases | 0%, no entitlement, under 2025-04-30 order; Apple proposes 15% / 5% SBP (2026-08-13); rate to be set on remand | [1][5]; [31][34] **[SS]** | High / Medium |
| Android Developer Console | US$25 one-time (Full Distribution); free Limited Distribution (20 devices, no ID) | [24] | High |
| Google Play Console | "similar to Play's $25 registration fee" | [24] | High |
| Parallels Desktop | Standard US$99.99/yr, Pro US$119.99/yr, Business US$149.99/yr; App Store Edition price unverified | [28][27] **[SS]** | Medium/Low |
| UTM Mac App Store / UTM SE iOS | US$9.99 ("identical to the free version") / free | [29][44] **[SS]** | Medium |
| Wine | LGPL-2.1 "or (at your option) any later version" | [17] | High |
| UTM | Apache-2.0 wrapper; "incorporates several GPL components", gstreamer static, derives from QEMU | [18] | High |
| Winlator / StikDebug | LGPL-2.1, GitHub-only APK / AGPL-3.0 | [21][20] | High |

## How it works (architecture)

**1. Mac App Store.** Enable `com.apple.security.app-sandbox` [11] and satisfy 2.4.5: "(ii) ... no third-party installers allowed ... self-contained, single app installation bundles"; "(iv) may not download or install standalone apps, kexts, additional code, or resources to add functionality or significantly change the app from what we see during the review process"; "(v) may not request escalation to root privileges"; "(vi) may not ... require license keys, or implement their own copy protection"; "(vii) must use the Mac App Store to distribute updates" [1]. Virtualization is sanctioned in-sandbox: `com.apple.security.hypervisor` is "required to use the Hypervisor APIs in any process"; `.virtualization` gates the Virtualization framework; `com.apple.vm.networking` and `com.apple.vm.device-access` add NICs and USB capture [7][8]. JIT is a Hardened Runtime exception (`allow-jit`, macOS 10.7+, MAP_JIT) [9]; Apple's docs do not forbid it in store apps and QEMU-based UTM is sold there [18][29]. Unlocks must use in-app purchase (3.1.1), though store apps "may host plug-ins or extensions that are enabled with mechanisms other than the App Store" [1]. The cost is visible in Parallels' KB: because store apps "run in sandbox", the App Store Edition cannot share the Mac VPN with Windows and supports only the VirtIO Ethernet adapter; existing users are "not recommended" to switch **[SS]** [27].

**2. Direct macOS distribution.** Developer ID certificate, Hardened Runtime, secure timestamp, notary service; "10.15+: ALL software built after June 1, 2019, distributed with Developer ID MUST be notarized"; store apps are exempt [12]. Since Sequoia, un-notarized software needs a System Settings > Privacy & Security detour [6]. No sandbox, IAP, update or licence-key rules apply, so Wine, QEMU, JIT, self-updates and perpetual keys are all fine; CrossOver **[SS]** [45] and the free UTM build ship this way.

**3. iOS App Store.** 2.5.2 (applies to App Store Review and EU Notarization Review): apps may not "download, install, or execute code which introduces or changes features or functionality of the app" [1]. 4.7 carves out HTML5 mini apps, streaming games, chatbots, plug-ins and "retro game console and PC emulator apps can offer to download games", subject to 4.7.1-4.7.5 (privacy, content filtering, "an index of software and metadata available in your app" with universal links, age gating) [1][3][4]. Apple approved UTM SE in July 2024 after a 2.5.2 rejection **[SS]** [44]; SE "uses a threaded interpreter instead" because JIT "requires either a jailbroken device or version-specific workarounds" [18]. No iOS `allow-jit` exists [9]; UTM v4.7.5 lists jailbreak/TrollStore/sideload routes for JIT builds [19]. StikDebug (AGPL-3.0 JIT enabler) is now AltSource/GitHub-only [20]; press dates approval to May 2025 and removal to December 2025 **[SS]** [36].

**4. Google Play.** "An app may not download executable code (e.g. dex, JAR, .so files) from a source other than Google Play" [26]; Google's page, per search summary, exempts "code that runs in a virtual machine or an interpreter where either provides indirect access to Android APIs" **[SS]** [26]. Winlator ("run Windows (x86_64) applications with Wine and Box86/Box64") "is distributed exclusively through GitHub Releases ... not available on Google Play Store" [21]. From 2026-09-30 (BR/ID/SG/TH) and 2027 globally, "unregistered apps will be blocked from installation on certified devices"; developers need a US$25 Android Developer Console account (government ID or D-U-N-S) and must register package names and signing keys; ADB installs are exempt and a 24-hour "advanced flow" exists [23][24][25]. New personal Play accounts also need a 12-tester/14-day closed test **[SS]** [43].

**5. Selling licences outside the store.** *US:* 3.1.1(a): entitlements "are not required for developers to include buttons, external links, or other calls to action in their United States storefront apps"; 3.1.3 exempts "apps on the United States storefront" from the anti-steering ban [1][5]. StoreKit External Purchase APIs are documented only for EU/EEA, South Korea, Brazil (iOS 26.5), Japan (iOS 26.2) and Russia [13]. *EU:* the 2026-08-18 terms cover iOS/iPadOS and alternative distribution; macOS is not mentioned [15]. *Elsewhere:* apps "may not include buttons, external links, or other calls to action that direct customers to purchasing mechanisms other than in-app purchase" [1]. 3.1.3(b) lets users unlock items bought elsewhere "provided those items are also available as in-app purchases within the app" [1] - the hook for honouring web-bought licences in a store edition.

## Feature checklist (table: feature | status | notes)

| Feature | Mac App Store | Direct (Developer ID) | iOS App Store | Google Play | Notes |
|---|---|---|---|---|---|
| Sandbox required | Yes [11] | No | Implicit | n/a | Causes ASE feature loss [27] |
| Hypervisor / Virtualization framework | Entitlements [7][8] | Yes | Non-store builds only [19] | n/a | Parallels, UTM precedents |
| JIT (MAP_JIT) | `allow-jit` [9][10] | Yes | Not available [9] | Native code OK | x86-64 emulation needs it |
| Bundle Wine (LGPL-2.1+) | Possible; relink vs signing unresolved [16][17]; no precedent | Yes (CrossOver) | No | Winlator, off-Play [21] | Counsel |
| Bundle QEMU (GPL) | UTM precedent [18][29]; FSF disputes **[SS]** | Yes | UTM SE (interpreter) | n/a | Process boundary, publish source |
| Run user-supplied Windows installers | Grey under 2.4.5(iv); 4.7 says "games" [1] | Yes | No (2.5.2) | VM exception [26] | Key risk |
| Own licence keys / perpetual licence | Banned 2.4.5(vi), 3.1.1 [1] | Yes | Banned | Not researched | Use 3.1.3(b) unlock |
| External purchase link | US yes, 0% today [1][5]; EU 15%/10% [15]; others no [1] | n/a | Same | n/a | US may become 15%/5% |
| Self-update | Store only | Any | Store only | Store/verified sideload | |
| Root / kexts | Banned 2.4.5(v) | User-approved | Banned | Banned | |
| Guest USB / NIC | `vm.device-access`, `vm.networking` [7] | Yes | n/a | n/a | ASE: VirtIO only **[SS]** [27] |
| Developer identity | US$99 [14] | Same | Same | US$25 + ID/D-U-N-S [24] | |

## CAD / AutoCAD relevance

- Autodesk "provides full support for certain products when they are used on a Mac in virtualized environments such as Parallels Desktop and VMware Fusion"; "A separate Windows license is required" [37]. Its virtualization terms add that a product may be virtualized "only if the applicable terms and conditions ... expressly permit virtualization" and that guidance is "as is" [42]. A VM-based tier can cite Autodesk's Parallels support; a Wine-based tier must not imply it.
- Autodesk's Parallels KBs preview the pain of a sandboxed edition: selection lag fixed by switching "Hypervisor from Apple to Parallels" [38]; cursor/display problems [39]; "Desktop Connector does not work on macOS with Apple Silicon ... when running Windows through Parallels" [40]. An edition that cannot bridge VPNs or custom adapters [27] breaks network-licence setups common in CAD shops.
- AutoCAD for Mac 2024 "runs natively on both Intel and Apple Silicon" (installer needs Rosetta 2) [41]; MIRRORZ's value is Windows-only toolsets and plug-ins.
- Verdict: Developer ID direct first; sandboxed store edition second with stated feature cuts; iOS never; Android out of scope.

## Strengths (what to match)

- **Parallels App Store Edition**: proves Apple accepts a sandboxed hypervisor with subscription IAP; keep a store SKU for discoverability.
- **UTM's dual channel**: free notarized build plus a US$9.99 "identical" store build **[SS]** [29] from one codebase [18].
- **UTM SE**: shows Apple approves a PC emulator once JIT is removed and a 4.7.4 software index is provided [1][19]; its tiered install routes are a model.
- **Winlator**: Wine+Box64 built in the open under LGPL, shipped off-store [21].

## Weaknesses (what MIRRORZ must beat)

- **Parallels ASE** drops VPN sharing and non-VirtIO adapters and is "not recommended" for existing users **[SS]** [27]; engineer around the sandbox or label the store edition "lite".
- **UTM SE** is interpreter-only, unusable for CAD; iOS JIT policy is unstable (StikDebug approved, then pulled) [20][36].
- **CrossOver** has no store presence **[SS]** [45]; a store-accepted Wine runtime would stand out.
- **Winlator** has no store listing and faces verification gating from 2026-09-30 [23].
- **Gatekeeper friction** for un-notarized builds [6]: notarize every build, betas included.

## Reusable code, ideas, and license implications for MIRRORZ

- **Wine (LGPL-2.1+ [17])**: usable in a proprietary product if kept a separately replaceable, dynamically linked component and modified source is published. In a store build the relink duty collides with code signing [16]; options: ship Wine as separately signed replaceable bundles plus object files, get counsel's opinion, or keep Wine in the Developer ID edition only.
- **QEMU / UTM pattern [18]**: Apache-licensed app, GPL QEMU in helper processes, source published; never link GPL code into proprietary binaries.
- **Apple Virtualization framework [7]**: the only sandbox-friendly, store-precedented path; use it for a Windows-on-ARM VM tier with x86 emulation in the guest. A search summary says the sandbox blocks the Rosetta-for-Linux path **[SS]**.
- **Winlator (LGPL-2.1 [21])**: ideas only (container UI, Box64). **StikDebug (AGPL-3.0 [20])**: do not copy; iOS-specific.
- **Monetisation**: sell perpetual and subscription licences on the web; US store edition links out at 0% today, budget 15% [1][5][31]; EU budget 15% link-out or 5% CTC for Web Distribution from 2026-10-01 [15]; elsewhere offer identical IAP SKUs and honour web licences via 3.1.3(b) [1].
- **Infra checklist**: Apple Developer Program US$99/yr [14]; notarytool pipeline [12]; Android Developer Console (US$25, D-U-N-S) only if an Android companion is ever built [24].

## Open questions

1. Will App Review treat a user-supplied Windows installer (e.g. AutoCAD) as "additional code ... to add functionality" under 2.4.5(iv)? 4.7 says "games"; no Wine-based store app was found.
2. Can a sandboxed store app spawn Wine's server processes and use `allow-jit` for x86-64 translation within sandbox IPC/file rules? Parallels and UTM use hypervisors.
3. LGPL-2.1 section 6 relinking vs App Store code signing needs a legal opinion [16].
4. Final US linked-out commission: remand ongoing; Apple's 15%/5% proposal and the SCOTUS October 2026 term may change it **[SS]** [31][33][34].
5. Do the Aug 2026 EU terms touch macOS? Not mentioned [15].
6. Parallels App Store Edition price and full feature diff (KB and listing unreachable) [27].
7. UTM v4.7.5 and Winlator v11.1.0 release years are inferred from GitHub's current-year date format [19][22]; confirm via API.
8. Google Play's commission, and whether Play would accept a Winlator-class runtime under the VM/interpreter exception, were not researched beyond the quoted text [26].

## Sources (numbered list of URLs with dates)

_All developer.apple.com, developer.android.com, GitHub and Autodesk items were fetched 2026-09-03; "SS" = search-engine summary only (page unreachable)._

1. Apple, App Review Guidelines (revised 2026-06-08) - https://developer.apple.com/app-store/review/guidelines/
2. Apple Developer News, 2026-06-08 - https://developer.apple.com/news/?id=a233fmpw
3. Apple Developer News, 2024-08-01 (4.7 PC emulators) - https://developer.apple.com/news/?id=ty0avr2s
4. Apple Developer News, 2024-04-05 (4.7 retro emulators) - https://developer.apple.com/news/?id=0kjli9o1
5. Apple Developer News, 2025-05-01 (US storefront 3.1.1/3.1.3) - https://developer.apple.com/news/?id=9txfddzf
6. Apple Developer News, 2024-08-06 (Sequoia Gatekeeper) - https://developer.apple.com/news/?id=saqachfa
7. Apple docs, com.apple.security.virtualization - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.virtualization
8. Apple docs, com.apple.security.hypervisor - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.hypervisor
9. Apple docs, com.apple.security.cs.allow-jit - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.allow-jit
10. Apple docs, allow-unsigned-executable-memory - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.allow-unsigned-executable-memory
11. Apple docs, App Sandbox - https://developer.apple.com/documentation/security/app-sandbox
12. Apple docs, Notarizing macOS software - https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
13. Apple docs, StoreKit External Purchase - https://developer.apple.com/documentation/storekit/external-purchase
14. Apple Developer Program pricing - https://developer.apple.com/programs/
15. Apple, DMA and apps in the EU (updated 2026-08-18) - https://developer.apple.com/support/dma-and-apps-in-the-eu/
16. Apple Developer Forums, LGPL on the App Store (Dec 2015) - https://developer.apple.com/forums/thread/27709
17. Wine LICENSE - https://github.com/wine-mirror/wine/blob/master/LICENSE
18. UTM README - https://github.com/utmapp/UTM
19. UTM release v4.7.5 ("03 Jan", 2026) - https://github.com/utmapp/UTM/releases/tag/v4.7.5
20. StikDebug README - https://github.com/StephenDev0/StikDebug
21. Winlator README - https://github.com/brunodev85/winlator
22. Winlator release v11.1.0 ("12 Jun", 2026) - https://github.com/brunodev85/winlator/releases/tag/v11.1.0
23. Google, Android developer verification - https://developer.android.com/developer-verification
24. Google, developer verification FAQ - https://developer.android.com/developer-verification/guides/faq
25. Google, developer verification guides - https://developer.android.com/developer-verification/guides
26. Google Play, Device and Network Abuse (SS) - https://support.google.com/googleplay/android-developer/answer/16559646 ; quoted in https://github.com/HMS-Core/hms-flutter-plugin/issues/175 (2022-03-17), https://github.com/robolectric/robolectric/issues/8563 (2023-10-25)
27. Parallels KB 123796, App Store vs Standard Edition (unreachable; SS) - https://kb.parallels.com/123796/
28. Parallels, Buy Parallels Desktop 2026 (unreachable; SS) - https://www.parallels.com/products/desktop/buy/
29. UTM for Mac (unreachable; SS) - https://mac.getutm.app/
30. 9to5Mac, 2025-12-11, Ninth Circuit commission ruling (SS) - https://9to5mac.com/2025/12/11/apple-defeats-ban-on-charging-commission-on-linked-out-purchases-from-ios-apps/
31. 9to5Mac, 2026-08-13, Apple proposes up to 15% (SS) - https://9to5mac.com/2026/08/13/apple-proposes-commissions-of-up-to-15-for-off-app-store-purchases-in-the-us/
32. Justia, Epic v. Apple No. 25-2935 (9th Cir. 2025-12-11) (SS) - https://law.justia.com/cases/federal/appellate-courts/ca9/25-2935/25-2935-2025-12-11.html
33. SCOTUS docket 25A1213, Apple stay application, 2026-05-04 - https://www.supremecourt.gov/DocketPDF/25/25A1213/407958/20260504154515930_2026-05-04%20Apple-Epic%20SCT%20Application%20to%20Stay%20Mandate.pdf
34. MacDailyNews, 2026-08-14, SCOTUS clears path (SS) - https://macdailynews.com/2026/08/14/u-s-supreme-court-clears-path-for-app-store-commission-showdown-as-apple-must-defend-its-rates-in-lower-court/
35. 9to5Google, 2025-08-25, developer verification announcement (SS) - https://9to5google.com/2025/08/25/android-apps-developer-verification/
36. 9to5Mac, 2025-05-01, StikDebug approved (SS) - https://9to5mac.com/2025/05/01/jit-enabler-lands-on-app-store-likely-unlocking-wii-and-switch-emulation-on-ios/ ; Ubergizmo, Dec 2025, pulled (SS) - https://www.ubergizmo.com/2025/12/stikdebug-pulled-appstore/
37. Autodesk KB 000231568, Mac-compatible Autodesk software - https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Mac-compatible-Autodesk-software.html
38. Autodesk KB, AutoCAD selection lag in Parallels - https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Selection-in-AutoCAD-products-lags-for-several-seconds-on-Apple-Mac-computer-with-Parallels-running-Windows.html
39. Autodesk KB, cursor/display issues in Parallels - https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html
40. Autodesk KB, Desktop Connector on Parallels ARM64 - https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
41. Autodesk Help, AutoCAD for Mac, Apple Silicon Support - https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-EA31738F-CDDE-4170-970A-745BC19C7674
42. Autodesk KB, 3ds Max/Maya in virtual environments (virtualization terms) - https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Running-3ds-Max-and-Maya-in-Virtual-Environments.html
43. Google Play Console Help, testing requirements for new personal accounts (unreachable; SS) - https://support.google.com/googleplay/android-developer/answer/14151465
44. MacRumors, 2024-07-15, UTM SE approved (SS) - https://www.macrumors.com/2024/07/15/apple-approves-first-retro-pc-emulator-ios/
45. CodeWeavers CrossOver (unreachable; SS) - https://www.codeweavers.com/crossover
