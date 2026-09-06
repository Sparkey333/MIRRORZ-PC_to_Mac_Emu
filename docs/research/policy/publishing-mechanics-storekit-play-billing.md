# Publishing Mechanics for MIRRORZ: App Store (StoreKit 2) + Google Play (Billing Library 8/9) + Direct Sales

_Research date: 2026-09-03_

Scope: what it takes in 2026 to ship a paid Mac app (Mac App Store build plus a Developer-ID direct-download build), an iOS companion and an Android companion, each selling a **monthly auto-renewable subscription** and a **one-time perpetual (non-consumable) unlock**, plus a **direct-sales perpetual license key** for the direct build. Every price, version, date and policy statement was taken from a page fetched on the research date; URL and page date are in Sources. Where the only reachable evidence was a search-result snippet of a page this environment could not fetch (support.google.com, play.google, the Android Developers Blog, Parallels' KB), the fact is marked **[snippet]** and must be re-verified before it drives a decision.

## TL;DR (5 bullets)

- **Apple fees (verified):** Developer Program 99 USD/year [1]. Small Business Program: **15%** commission if prior-calendar-year net proceeds were under **1,000,000 USD**; enrollment required, associated accounts aggregated, crossing the line mid-year moves future sales to the standard rate [2]. Standard subscriptions pay 70% in year one and 85% after one year of paid service; Small Business members get 85% every cycle [12].
- **Google fees (snippet only):** Google announced on June 24, 2026 that from **June 30, 2026** in the US, EEA and UK the service fee is **10%** on the first $1M and on all auto-renewing subscriptions, plus a separate **5% billing fee** when Play billing is used (waived for alternative billing/external links) **[snippet, 24]**. Elsewhere the older 15%-on-first-$1M / 30% structure applies **[snippet, 25]**. Verify before modelling revenue.
- **Hard 2026 deadlines:** Play Billing Library **8+** for all new apps and updates by **Aug 31, 2026** (extension to Nov 1, 2026; v9 mandatory Aug 31, 2027) [3]; Play target **API 36** by Aug 31, 2026 [4]; **Xcode 26 / iOS 26 SDK** for uploads since April 28, 2026 [5]; Apple's new age-rating questionnaire was due Jan 31, 2026 [6].
- **Store rules that dictate the licensing design:** Mac App Store apps must be sandboxed, may not show a license screen or require license keys, may not download additional code, and must use IAP to unlock functionality [7]. Guideline 3.1.3(b) lets an app honor entitlements bought elsewhere **if the same items are also sold as IAP** [7]. Only the US storefront permits outbound purchase links without an entitlement [7]. So: an MAS flavor (StoreKit 2 only) and a Developer ID flavor (license key + web checkout).
- **Virtualization review risk:** Guidelines 2.4.5 (sandbox, no extra code/kexts, no root), 2.5.2 (no downloading/executing code that changes functionality) and 4.7 (PC emulators may offer to download games, subject to 4.7.1-4.7.5) [7]. UTM SE was rejected under 4.7 and approved in July 2024 after Apple revised the rule **[snippet, 26]**; Parallels' sandboxed App Store Edition drops several integration features **[snippet, 27]**. `com.apple.security.hypervisor` / `.virtualization` exist since macOS 11.0 [8][9]; `com.apple.vm.networking` / `device-access` are restricted and need Apple authorization [10].

## Current status (version, date, maintainer, momentum)

| Component | Current state (with source date) |
|---|---|
| Apple Developer Program | 99 USD/year; organization enrollment needs a D-U-N-S number, legal-entity name and public website; fee waivers only for nonprofits, accredited education, government [1] (page © 2026). |
| StoreKit 2 | Actively developed. WWDC25 added `appTransactionID` (back-deployed to iOS 15), `originalPlatform`, `Transaction.currentEntitlements(for:)` replacing `currentEntitlement(for:)` (iOS 18.4), `SubscriptionStatus(for:)`, signed IAP requests via the App Store Server Library, and SwiftUI `SubscriptionOfferView`; purchases need a UI context (`NSWindow` on macOS) from iOS 18.2/aligned releases [11]. Original StoreKit deprecated from iOS 18 **[snippet, 28]**. |
| App Store Server API / Notifications V2 | 23 `notificationType` values today (SUBSCRIBED, DID_RENEW, EXPIRED, REFUND, REFUND_DECLINED, CONSUMPTION_REQUEST, GRACE_PERIOD_EXPIRED, REVOKE, ONE_TIME_CHARGE, EXTERNAL_PURCHASE_TOKEN, RESCIND_CONSENT, METADATA_UPDATE, MIGRATION, PRICE_CHANGE, ...) [13][14]. Apple's MIT-licensed App Store Server Library (Swift/Java/Python/Node) wraps every endpoint plus JWS verification [15]. `verifyReceipt` deprecated since June 2023, still functional, no end-of-life date [16]. |
| Play Billing Library | 8.0.0 on 2025-06-30; 8.3.0 on 2025-12-23; **9.0.0 on 2026-05-19; 9.1.0 on 2026-06-18** (Billing Choice APIs) [17]. Google's setup guide pins `billing_version = "9.1.0"` [18]. Two-year deprecation cycle [3]. |
| Play Developer API / RTDN | RTDN via Cloud Pub/Sub; after every notification call `purchases.subscriptionsv2.get` / `purchases.productsv2` for authoritative state [19]. Unacknowledged purchases auto-refund after **3 days** [20]. |
| Apple App Review | Apple says 90% of submissions are reviewed in under 24 hours [21]; 2026 forum threads report "Waiting for Review" of 7-20+ days (Feb), 3+ weeks (Mar) and 17-30 days (thread from Mar 15, 2026) with boilerplate replies [22][23]. One snippet reports a macOS build taking 3 days while iOS cleared in under 24 hours **[snippet, 23]**. |
| Google Play Console | 25 USD one-time registration **[snippet, 29]**; personal accounts created on/after Nov 13, 2023 must run a closed test with 12 testers for 14 days (reduced from 20 in Dec 2024); organization accounts exempt **[snippet, 30]**. |

## Pricing and licensing (table)

| Item | Value | Source / date |
|---|---|---|
| Apple Developer Program | 99 USD / year (varies by region) | [1], © 2026 |
| Apple standard commission | 30% on paid apps, IAP and year-one subscriptions | [12] |
| Apple subscriptions after 1 year of paid service | 15%; free-trial days and renewal extensions do not count toward the year | [12] |
| Apple Small Business Program | 15%; eligibility < 1,000,000 USD proceeds (net of commission and certain taxes) in prior calendar year, aggregated across Associated Developer Accounts; enroll in App Store Connect; effective 15 days after the fiscal month of approval; exceeding 1M in-year moves *future* sales to standard rate | [2] |
| Apple price points | 900 price points (Mar 9, 2023; 0.10 USD steps to 10 USD, 0.50 USD steps 10-50 USD); App Store Connect shows 800 by default plus 100 more up to 10,000 USD on request; base storefront with automatic equalization across 174 other storefronts / 43 currencies; Paid Apps Agreement required | [31][32] |
| Google Play registration | 25 USD one-time | **[snippet, 29]** |
| Play service fee (US/EEA/UK from June 30, 2026) | 10% on first 1M USD and all auto-renewing subscriptions + 5% billing fee if Play billing is used (waived for alternative billing/external links); secondary sources cite 20% on other one-time purchases from new installs and 15% program rate cards (Apps Experience / Games Level Up) from Sept 30, 2026 | **[snippet, 24][snippet, 25]** |
| Play service fee (rest of world) | 15% on first 1M USD, 30% above; 15% on subscriptions (pre-2026 structure) | **[snippet, 25]** |
| Apple Family Sharing | Auto-renewable subscriptions and non-consumables only; purchaser + up to 5 members; **irreversible once enabled** | [33][12] |
| Google Play Family Library | Paid apps only; IAP and subscriptions are never shared | **[snippet, 34]** |
| Apple refunds | `Transaction.beginRefundRequest` (iOS 15+); CONSUMPTION_REQUEST gives the server 12 hours to send consumption info; REFUND / REFUND_DECLINED / REFUND_REVERSED notifications; Extend Renewal Date allows max 2 extensions per customer per year, up to 90 days each | [35][14] |
| Google Play refunds | Users request through Google Play within 48 hours, afterwards via the developer; refunding the latest subscription order removes the subscription immediately **[snippet, 36]**; API path is `Orders:refund` with `revoke=true`; pending-refund-review RTDNs give 24 hours to answer via `ReviewRefund` | [20][19] |
| Direct-download Mac build | Developer ID certificate (issued by the Account Holder); notarization via `notarytool` "optional but recommended"; Gatekeeper checks it | [37] |

## How it works (architecture)

**One entitlement ledger, four storefront adapters.** Keep a server-side ledger keyed by MIRRORZ account and feed it from:

1. **Mac App Store + iOS (StoreKit 2).** One subscription group holding `mirrorz.pro.monthly`, plus non-consumable `mirrorz.perpetual`. The app calls `Product.products(for:)` and `product.purchase()` (with a window/view-controller context), listens to `Transaction.updates`, reads `Transaction.currentEntitlements(for:)`, and passes `appAccountToken` so notifications join to an account; transactions are JWS-signed and verifiable on device [11]. Register production and sandbox notification URLs; V2 notifications are JWS payloads, delivered once per event with up to 5 retries over 7 days, acknowledged with HTTP 200 [35]. Verify with the Server Library's `SignedDataVerifier` and use Get All Subscription Statuses / Transaction History / Look Up Order ID / Refund History for support and cross-platform status [15][35].
2. **Android (Play Billing 9.x).** A subscription with one auto-renewing monthly base plan and optional trial/intro offers, and a one-time product for the perpetual unlock [38]. Client: `queryProductDetailsAsync` -> `launchBillingFlow` (set `obfuscatedAccountId`) -> `PurchasesUpdatedListener`; call `queryPurchasesAsync` on resume; enable pending purchases and `enableAutoServiceReconnection()` [39]. Server: on each RTDN (Pub/Sub topic with publisher rights for `google-play-developer-notifications@system.gserviceaccount.com`) call `subscriptionsv2.get` / `productsv2`, grant only in state PURCHASED, **acknowledge within 3 days** [18][19][20]. Track `linkedPurchaseToken` on upgrades and poll the Voided Purchases API for clawbacks [20][40].
3. **Direct-download Mac build (Developer ID).** A build flavor with no StoreKit code: web checkout issues a signed license key the app redeems against the ledger. Only this build may show a license screen; the MAS build may not (2.4.5 vi) [7].
4. **Cross-platform honoring.** Under 3.1.3(b) the MAS/iOS apps may recognize a web or Android purchase as long as the same items are sold as IAP in-app, and must not steer users outside except on the US storefront or via a granted entitlement [7].

**Lifecycle mapping.** Apple: SUBSCRIBED -> DID_RENEW / DID_FAIL_TO_RENEW(GRACE_PERIOD) -> GRACE_PERIOD_EXPIRED -> EXPIRED; grace period 3, 16 or 28 days; REVOKE for Family Sharing removal [14][12]. Google: ACTIVE -> IN_GRACE_PERIOD -> ON_HOLD (60 days minus grace) -> EXPIRED, plus PAUSED and CANCELED; tokens stay queryable 60 days after expiry [41]. Map both to one `entitlement_state` enum.

## Feature checklist (table: feature | status | notes)

| Feature / task | Status (2026) | Notes and source |
|---|---|---|
| Apple Developer Program (organization, D-U-N-S) | Required | 99 USD/yr; Account Holder must accept Paid Apps Agreement before pricing anything [1][32] |
| Small Business Program enrollment | Do before first sale | List associated accounts; 15% applies 15 days after fiscal-month end of approval [2] |
| Build with Xcode 26 / iOS 26 SDK | Mandatory since Apr 28, 2026 for iOS/iPadOS/tvOS/visionOS/watchOS (macOS not named) | [5] |
| Strip `com.apple.quarantine` xattr from Mac bundles | Mandatory since Feb 18, 2025 (TestFlight and MAS) | [5] |
| Privacy manifest with approved API reasons (incl. SDKs) | Mandatory since May 1, 2024 | [5] |
| Age-rating questionnaire (4+/9+/13+/16+/18+) | Due Jan 31, 2026; otherwise updates blocked | [6] |
| EU DSA trader status | Required since Feb 17, 2025 for the EU storefront | [5] |
| App Privacy label | Required; must include third-party SDK data; editable without a new build | [42] |
| Screenshots (Apple) | 6.9-inch 1260 x 2736 (required if iPhone); 6.5-inch 1284 x 2778 fallback; iPad 13-inch 2064 x 2752; Mac 16:10 at 1280 x 800 / 1440 x 900 / 2560 x 1600 / 2880 x 1800; 1-10 per localization; JPEG/PNG, no alpha | [43]; a third-party guide says 1320 x 2868 **[snippet, 44]**; prefer Apple's page |
| Required metadata (Apple) | Name, subtitle, bundle ID, SKU, primary language, categories, age rating, version, copyright, support URL, privacy policy URL, icon, screenshots, availability, price, tax category | [45] |
| Create IAPs in App Store Connect | Product ID immutable; add review screenshot + notes; first IAP of each type must ship with a new app version | [46][47] |
| Subscription group | One group; perpetual unlock is a separate non-consumable | [12] |
| Family Sharing | Optional, irreversible; existing subscribers opt in; check `ownershipType` | [33][12] |
| StoreKit Testing in Xcode, sandbox, TestFlight (10,000 external testers; IAP free in sandbox) | Available | [48] |
| Server Notifications V2 URLs (prod + sandbox) | Required | [35][13] |
| Migrate off `verifyReceipt` / V1 | Deprecated June 2023; no EOL date | [16] |
| Play Console org account + payments profile | Required; personal accounts face the 12-tester test | [18] **[snippet, 30]** |
| Play Billing Library 8+ (target 9.1.0) | Mandatory by Aug 31, 2026 (ext. Nov 1); v9 by Aug 31, 2027 | [3][17] |
| Target API 36 | Mandatory by Aug 31, 2026 | [4] |
| Play Data safety form | Required for every published app incl. testing tracks **[snippet, 49]**; declare all SDK collection/sharing | [50] |
| RTDN + Developer API | Required; acknowledge within 3 days | [18][19][20] |
| Play refund handling | Voided Purchases API; pending-refund-review RTDN, 24-hour response | [19][20] |
| Play alternative billing / external offers / external payments | User-choice PBL 5.2+, alt-only 6.2.1+, EEA external offers PBL 8.2.1+, Japan external payments PBL 8.3+; enrolment pages on support.google.com (blocked here) | [51][52][53] |
| Developer ID + notarization for direct build | Required for Gatekeeper; `notarytool` | [37] |
| Mac App Store entitlements | App Sandbox + `com.apple.security.hypervisor` and/or `.virtualization` (macOS 11.0+); `com.apple.vm.networking` / `device-access` restricted | [8][9][10] |

## CAD / AutoCAD relevance

- **Trials.** Guideline 3.1.1 allows a non-subscription trial only via a Price-Tier-0 non-consumable named "XX-day Trial" with clear disclosure of what stops working; a CAD evaluator needs a real trial, so pair an introductory offer on the subscription with that trial non-consumable for the perpetual path [7][12].
- **Perpetual buyers are studios.** Procurement-driven buyers cannot use personal Apple IDs; the Developer ID build with license keys (recognized in MAS via 3.1.3(b)) is the volume/perpetual channel. Apple's list tops out at 10,000 USD on request, so a high-end perpetual SKU still fits a price point [32].
- **Fee math on high-price SKUs.** 15% (Apple Small Business) vs 10% + 5% (Play, US/EEA/UK) vs processor cost on the web is material on a 300-600 USD perpetual license; make the direct build the recommended perpetual channel outside the US storefront, where the app cannot even mention it [7].
- **Review risk is code execution, not CAD.** AutoCAD is irrelevant to App Review; the mechanism (a VM/translation layer that downloads a Windows runtime or executes non-bundled code) is what 2.4.5(iv) and 2.5.2 police. UTM shows Apple tolerating hardware virtualization on macOS while blocking JIT on iOS [7][54] **[snippet, 26]**.

## Strengths (what to match)

- StoreKit 2 plus the MIT-licensed Server Library give JWS verification, order lookup, refund history, renewal extension and consumption endpoints out of the box; no third-party subscription backend is needed on day one [15][35].
- Apple subscription economics improve after year one (85%) and Family Sharing can be a retention lever; Google's 2026 US/EEA/UK subscription rate (10% + 5%) is lower still **[snippet, 24]**.
- Google's RTDN + `subscriptionsv2.get` model, payment-recovery in-app messaging, grace/account-hold states, and 9.x billing-choice and price-increase messaging are mature [17][38].
- Apple's 900 equalized price points and Google's base-plan/offer model support a monthly plan, a trial and a perpetual SKU without custom currency logic [31][32][38].

## Weaknesses (what MIRRORZ must beat)

- **Review latency.** Despite "90% in under 24 hours", 2026 forum reports show multi-week waits with boilerplate replies; never schedule launches or hotfixes on a one-day assumption, and keep the direct build as the fast channel [21][22][23].
- **MAS sandbox shrinks the product.** Parallels' App Store Edition drops several host-integration features **[snippet, 27]**; MIRRORZ's MAS flavor will lose file-system and networking integration unless restricted `com.apple.vm.*` entitlements are granted [10].
- **No license keys or outbound purchase links in MAS/iOS outside the US** [7]; the direct-sales path must be discovered via website or email, not in-app.
- **Google-side facts are hard to verify programmatically**; the fee announcement, Data safety policy, refund rules and account requirements live on hosts this environment could not reach **[snippet, 24-30, 34, 36, 49]**.
- **Deadlines need a reliable backend from launch**: Google 3-day acknowledgement, Apple 12-hour CONSUMPTION_REQUEST [20][35].

## Reusable code, ideas, and license implications for MIRRORZ

- **apple/app-store-server-library-{node,swift,python,java}:** MIT; use for JWS verification, notification decoding, receipt-to-transaction lookup and promotional-offer signatures [15]; WWDC25 shows it signing `introductoryOfferEligibility` / `promotionalOffer` requests [11].
- **Play Billing docs sample code** for the client flow, pending purchases and auto-reconnect [18][39].
- **UTM (Apache 2.0 with statically linked GPL components):** reference for entitlement sets and for what Apple has accepted in a sandboxed VM app; do not copy GPL-linked binaries into a proprietary build [54].
- **Design ideas:** single subscription group with `visibleRelationship`-driven `SubscriptionOfferView` [11]; `appAccountToken` / `obfuscatedAccountId` on every purchase so both stores join to one account [11][20]; the store is the source of truth, so re-query (`Get All Subscription Statuses`, `subscriptionsv2.get`) rather than trusting client state [19][35].

## Open questions

1. Exact Play 2026 fee schedule for one-time purchases above 1M USD and outside the US/EEA/UK, and whether the 5% billing fee applies to the perpetual SKU **[snippet, 24][snippet, 25]**.
2. Does the Xcode 26 SDK minimum apply to macOS uploads? Apple names iOS/iPadOS/tvOS/visionOS/watchOS only [5].
3. Will Apple grant `com.apple.vm.networking` / `device-access` to a sandboxed MAS build ("contact your Apple representative") [10]?
4. Can the MAS build download a Windows-compatibility runtime post-install without tripping 2.4.5(iv)/2.5.2 [7]?
5. Are the US external-link allowance and the EU/Japan programs worth a separate SKU strategy [7][51-53]?
6. Parallels App Store Edition's current IAP prices as a comparable (apps.apple.com blocked) **[snippet, 27]**.

## Sources (numbered list of URLs with dates)

1. https://developer.apple.com/programs/enroll/ (page © 2026; fetched 2026-09-03)
2. https://developer.apple.com/app-store/small-business-program/ (fetched 2026-09-03)
3. https://developer.android.com/google/play/billing/deprecation-faq (page footer dated 2026-09-04)
4. https://developer.android.com/google/play/requirements/target-sdk (page updated 2026-08-14)
5. https://developer.apple.com/news/upcoming-requirements/ (requirements dated 2024-05-01 through 2026-04-28)
6. https://developer.apple.com/news/?id=ks775ehf (news dated 2025-07-24)
7. https://developer.apple.com/app-store/review/guidelines/ (living document; fetched 2026-09-03)
8. https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.hypervisor (JSON data endpoint; introduced macOS 11.0)
9. https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.virtualization (JSON data endpoint; introduced macOS 11.0)
10. https://developer.apple.com/forums/thread/656411 (posts Aug 2020 - Nov 2023)
11. https://developer.apple.com/videos/play/wwdc2025/241/ (WWDC25, June 2025)
12. https://developer.apple.com/app-store/subscriptions/ (fetched 2026-09-03)
13. https://raw.githubusercontent.com/apple/app-store-server-library-node/main/models/NotificationTypeV2.ts (main branch, fetched 2026-09-03)
14. https://developer.apple.com/documentation/appstoreservernotifications/notificationtype (JSON data endpoint, fetched 2026-09-03)
15. https://github.com/apple/app-store-server-library-node (README; MIT)
16. https://developer.apple.com/forums/thread/731550 (June 2023, Apple staff answer)
17. https://developer.android.com/google/play/billing/release-notes (entries through 9.1.0, 2026-06-18)
18. https://developer.android.com/google/play/billing/getting-ready (fetched 2026-09-03)
19. https://developer.android.com/google/play/billing/rtdn-reference (fetched 2026-09-03)
20. https://developer.android.com/google/play/billing/security (fetched 2026-09-03)
21. https://developer.apple.com/distribute/app-review/ (fetched 2026-09-03)
22. https://developer.apple.com/forums/thread/815537 (Feb 2026) and https://developer.apple.com/forums/thread/817793 (Mar-Jul 2026)
23. https://developer.apple.com/forums/thread/821273 (Apr-Jun 2026); macOS-vs-iOS remark from a developer.apple.com forums search snippet
24. https://android-developers.googleblog.com/2026/06/play-expanded-billing.html (published 2026-06-24; blocked by proxy, content via search snippet)
25. https://www.revenuecat.com/docs/platform-resources/google-platform-resources/15-reduced-service-fee and https://play.google/intl/en_us/additional-service-fee-tier-terms/ (blocked; snippet)
26. https://www.iphoneincanada.ca/2024/07/15/apple-approves-utm-se-the-first-pc-emulator-app-for-ios-following-initial-rejection/ and https://www.macrumors.com/2024/07/15/apple-approves-first-retro-pc-emulator-ios/ (2024-07-15; snippet)
27. https://kb.parallels.com/123796/ (Parallels KB; blocked, snippet)
28. https://qonversion.io/blog/wwdc-24-updates and https://askwwdc.com/q/4736 (WWDC24 deprecation of original StoreKit; snippet)
29. https://support.google.com/googleplay/android-developer/answer/6112435 (blocked; snippet)
30. https://support.google.com/googleplay/android-developer/answer/14151465 (blocked; snippet)
31. https://developer.apple.com/news/?id=dbrszv62 (news dated 2023-03-09)
32. https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price (fetched 2026-09-03)
33. https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases (fetched 2026-09-03)
34. https://support.google.com/googleplay/android-developer/thread/333251861/ and https://www.androidcentral.com/5-important-things-know-about-google-play-family-libraries (blocked; snippet)
35. https://developer.apple.com/videos/play/tech-talks/10887/ (Apple Tech Talk; fetched 2026-09-03)
36. https://support.google.com/googleplay/android-developer/answer/2741495 and https://support.google.com/googleplay/answer/15574908 (blocked; snippet)
37. https://developer.apple.com/developer-id/ (fetched 2026-09-03)
38. https://developer.android.com/google/play/billing/subscriptions (fetched 2026-09-03)
39. https://developer.android.com/google/play/billing/integrate (fetched 2026-09-03)
40. https://developer.android.com/google/play/billing/lifecycle/one-time (page updated 2026-02-26)
41. https://developer.android.com/google/play/billing/lifecycle/subscriptions (fetched 2026-09-03)
42. https://developer.apple.com/app-store/app-privacy-details/ (fetched 2026-09-03)
43. https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/ (fetched 2026-09-03)
44. https://www.mobileaction.co/guide/app-screenshot-sizes-and-guidelines-for-the-app-store/ (2026 guide; snippet)
45. https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties (fetched 2026-09-03)
46. https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/ (fetched 2026-09-03)
47. https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/ (fetched 2026-09-03)
48. https://developer.apple.com/in-app-purchase/ (fetched 2026-09-03)
49. https://support.google.com/googleplay/android-developer/answer/10787469 (blocked; snippet)
50. https://developer.android.com/guide/topics/data/collect-share (page updated 2026-03-06)
51. https://developer.android.com/google/play/billing/alternative (page updated 2026-04-03)
52. https://developer.android.com/google/play/billing/external (page updated 2026-02-26)
53. https://developer.android.com/google/play/billing/externalpaymentlinks (page updated 2026-02-26)
54. https://github.com/utmapp/UTM (README; Apache 2.0 with GPL components) and https://developer.apple.com/forums/thread/668496 (sandbox + hypervisor entitlement, fixed macOS 11.3 beta 2, Mar 2021)
