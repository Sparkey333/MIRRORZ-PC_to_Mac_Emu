# AutoCAD and CAD users on Mac: needs, workarounds, complaints

_Research date: 2026-09-03_

_Method note._ The session's web-search quota was exhausted (200/200) and the egress proxy blocked autodesk.com, forums.autodesk.com, reddit.com, parallels.com, solidworks.com, sketchup.com, chiefarchitect.com, vectorworks.net, codeweavers.com, winehq.org, wikipedia.org and web.archive.org. Evidence therefore comes from the Autodesk Product Help MCP (official KB and product docs, ~20 queries), the Microsoft Learn MCP (official Windows-on-Arm, Microsoft 365 and support pages) and WebFetch of 10 GitHub/Apple developer pages. Unverifiable items are listed under "Open questions", not stated from memory. Autodesk KB articles are undated in retrieved text.

## TL;DR (5 bullets)

- **AutoCAD for Mac is real but not 1:1.** Autodesk says the Mac products "are not straight 1:1 ports"; Express Tools, the Visual LISP IDE, DesignCenter, QuickCalc, block-table lookup, the classic toolbar UI and every specialized toolset (Architecture, MEP, Electrical, Mechanical, Map 3D, Plant 3D, Raster Design) are Windows-only. AutoLISP, ObjectARX/.NET plug-ins, DWG Compare, 3D and (since 2026) a "Sheet Set Manager" palette exist on Mac, but the Mac sheet-set manager "has limited functionality". [1][2][3][4][5][6]
- **Autodesk's official stance on VMs is split.** For **Revit/Revit LT 2026** Autodesk publishes a "Parallels Desktop for Mac" configuration listing "Any Apple silicon chip" with Windows 11 (hardware acceleration off, Accelerated Graphics Tech Preview "not recommended"). For the **AutoCAD family** the KB says "AutoCAD family products are not supported" under virtualization, and the Windows AutoCAD/LT requirements say "ARM Processors are not supported." [7][8][9][10]
- **Windows-on-ARM inside Parallels breaks real Autodesk workflows.** Autodesk documents that Desktop Connector (the Autodesk Docs/ACC sync client) "does not work on macOS with Apple Silicon ... when running Windows through Parallels"; sign-in can bounce to the macOS browser; installers fail with "Error 10" without Rosetta 2 and the ARM64 VC++ redistributable; ReCap will not run in any VM. [11][12][13][14]
- **Microsoft only "authorizes" Parallels 18/19/20 for Arm Windows 11 Pro/Enterprise on M-series Macs**, with listed limits: DirectX 12 dependencies, no nested virtualization (WSL, Sandbox, VBS), Arm64-only drivers, no 32-bit Arm apps, and a separate Windows 11 Pro license per VM. x64 apps run via Prism (Windows 11 24H2), which now exposes AVX/AVX2. [15][16][17]
- **Non-CAD Windows needs have the same shape.** Access is not available for Mac; Visio and Project desktop clients are Windows-only (web versions are cut down); Office for Mac VBA lacks ActiveX/COM add-ins and `Shell`; 32-bit Microsoft 365 Apps on Windows Arm lost feature updates in Oct 2025 and lose security updates in Dec 2026, which matters for legacy 32-bit Access databases in ARM VMs. [18][19][20][21][22]

## Current status (version, date, maintainer, momentum)

| Item | Status (verified) | Source |
|---|---|---|
| AutoCAD for Mac 2026 | Release notes dated **March 25, 2025**; 2026.1 added REVCLOUDLAYER/TABLELAYER/VIEWPORTLAYER; "Project Manager" renamed **Sheet Set Manager**; Fast Shaded mode expanded; faster 2D file open. | [3] |
| AutoCAD for Mac 2027 | Release notes dated **March 25, 2026**; 2027.0.1 update **May 26, 2026**. Adds Geometry Cleanup, AI "Smart Blocks: Detect and Convert", Autodesk Assistant, shortcut-menu customization. **OpenGL removed; Metal is the sole graphics engine.** | [23][24] |
| Apple Silicon | AutoCAD for Mac has run natively on Apple Silicon since the 2024 release (installer still needs Rosetta 2). AutoCAD 2020 for Mac ran M-series "under Rosetta 2 mode". | [25][9] |
| Supported macOS (LT 2026 for Mac) | macOS Tahoe 26, Sequoia 15, Sonoma 14; Intel 64-bit or Apple M-series; 8 GB RAM basic / 16 GB recommended. | [10] |
| ObjectARX / .NET on Mac | Autodesk publishes Mac dev environments per release (AutoCAD 2026: macOS 14.3.1+/Xcode 15.4/Mono 6.1.2; 2027: macOS 15.4.1+/Xcode 16.3), so Mac plug-ins exist but must be built separately. | [26] |
| AutoLISP tooling on Mac | Visual LISP IDE "is not available ... on Mac OS"; the official replacement is the Autodesk-AutoCAD/AutoLispExt VS Code extension (Apache-2.0, Windows + Mac, AutoCAD 2021+, 145 stars, updated 2026-08-28). | [2][27] |
| Revit / Civil 3D / Inventor / Navisworks / 3ds Max / toolsets | No native macOS versions. Revit: "does not have a native Macintosh version"; Inventor "requires a Windows operating system"; "At this time there is no Navisworks on Mac"; 3ds Max under Parallels is "an unsupported configuration"; toolsets are "only supported on Windows". | [28][29][30][31][6] |
| Fusion | Native on Apple Silicon "as of July 2023". Fusion on Windows-on-ARM/Parallels can crash at startup (workaround: `QSG_RHI_PREFER_SOFTWARE_RENDERER=1`). | [32][33] |
| Windows-on-Mac tooling momentum | Whisky (Wine/GPTK GUI, GPL-3.0, 15.1k stars) **archived May 11, 2025**. Gcenx WineHQ macOS builds continue (11.16 Aug 24; 11.15 Aug 8; 11.14 Jul 27, Wine 11.x cycle). Sikarugir (Wineskin successor) active, macOS 14+. Apple GPTK is at **version 4**. UTM (Apache-2.0, QEMU) last listed releases: 5.0.x betas (Sep 2, 2024). | [34][35][36][37][38] |

Momentum: Autodesk ships annual Mac releases and is converging terminology (Sheet Set Manager) and graphics (Metal-only in 2027), but the gap list has been stable for years. Community Wine front-ends churn (Whisky dead, Sikarugir alive) while Parallels remains the only Microsoft-authorized route.

## Pricing and licensing (table)

Vendor price pages were unreachable, so only licensing rules and price points present in official KB text are listed.

| Item | Verified fact | Source / date |
|---|---|---|
| AutoCAD / LT subscription price | **Not verifiable** (autodesk.com blocked). KB: monthly > annual > 3-year unit cost; occasional users pointed to Flex. | [39] |
| Autodesk Flex (pay-per-day tokens) | Revit = **10 tokens ≈ $30/day**; Fusion = 3 tokens/day. Tokens expire 1 year from purchase; KB says check the current rate sheet. | [40][41][42] |
| Autodesk single-user subscription device limit | May be installed on up to **three computers**; only the named user, on one computer at a time. Relevant to a user wanting AutoCAD for Mac *and* Windows AutoCAD in a VM. | [43][44] |
| Autodesk license in Boot Camp + Parallels | Same Windows partition used both natively and via "My Boot Camp" VM requires activating twice; license repair prompts. | [45] |
| Autodesk virtualization terms | "You may virtualize a product only if the applicable terms and conditions ... expressly permit virtualization ... you assume all risks." Repeated verbatim on every relevant KB and requirements page. | [46][7] |
| Windows 11 in a VM on Apple Silicon | Separate **Windows 11 Pro license per VM instance**; keys are platform-agnostic (x64/Arm); Enterprise requires Pro then a volume-licence upgrade. Parallels 18/19/20 are the "authorized solutions". | [15] |
| Windows 365 Cloud PC | Microsoft's other sanctioned route for M-series Macs: per-user, per-month SaaS (prices unreachable). | [15] |
| AutoCAD web app | Anyone can *view*; editing requires a desktop AutoCAD/LT subscription. | [47] |
| Microsoft Access | Not included in Microsoft 365 Apps for Mac / Office LTSC for Mac; Windows desktop only. | [18] |
| Visio / Project desktop | Windows desktop apps (Visio Plan 2 / LTSC 2024; Project Online Desktop Client "only supported on Windows 10/11 PCs"). | [19][20] |
| Parallels Desktop / CrossOver prices | **Not verifiable** (sites blocked). | — |
| Apple GPTK (D3DMetal) | Free download but, per Sikarugir maintainers, "closed source and has a restrictive license it can not be used for commercial ports"; Apple's page does not state redistribution terms. | [37][36] |

## How it works (architecture)

A Mac CAD user today chooses among four architectures, each with a distinct failure mode that MIRRORZ can position against:

1. **Native AutoCAD for Mac.** Cocoa UI, Metal renderer (OpenGL dropped in 2027), same DWG engine, ObjectARX/Mono plug-in ABI compiled with Xcode. Missing the Windows-only feature set (see checklist). [1][23][26]
2. **Parallels Desktop + Windows 11 Arm + Prism.** An Arm64 Windows guest runs on Apple's Virtualization.framework; x64 CAD binaries are JIT-translated by Prism (24H2), which caches translated blocks per module and exposes AVX/AVX2. Emulation is user-mode only: kernel drivers, anti-cheat, nested virtualization and 32-bit Arm apps are out. Autodesk's Revit config turns *off* Retina scaling and hardware acceleration in the VM. [16][17][15][7]
3. **Wine-family translation on macOS (CrossOver, Gcenx Wine, Whisky, Sikarugir).** Runs Win32/x64 binaries without Windows via Rosetta 2 + Wine, with Direct3D translated by WineD3D/DXVK/DXMT (open) or D3DMetal/GPTK (Apple, non-commercial). No Windows license, but no vendor support or kernel drivers; Whisky's archiving shows the maintenance burden. [34][37][35]
4. **Remote/cloud Windows (Windows 365, RDP/Citrix).** Recommended by Autodesk KBs for Revit and Inventor and by Microsoft as "the most secure and fully compatible option" for M-series Macs; latency-bound. [28][29][15]

## Feature checklist (table: feature | status | notes)

Status is for the *native* AutoCAD for Mac line (2026/2027) versus AutoCAD for Windows, per Autodesk documentation.

| Feature | Status on Mac | Notes / source |
|---|---|---|
| DWG file compatibility | Yes | Same native DWG; "Unsupported objects" (custom objects from verticals) can be purged but not edited. [1][48] |
| AutoLISP (incl. DCL dialogs, Unicode) | Yes | Since 2021 for Mac; VS Code AutoLispExt is the supported editor. [49][27] |
| Visual LISP IDE | **No** | "not available in AutoCAD LT for Windows and on Mac OS." [2] |
| Express Tools (TCOUNT, etc.) | **No** | "Express Tools are supported in AutoCAD for Windows only; not available ... on Mac OS and Web." [5][4] |
| ObjectARX / .NET plug-ins | Partial | Supported, but require a separate macOS (Xcode/Mono) build. [26] |
| Specialized toolsets (Architecture, MEP, Electrical, Mechanical, Map 3D, Plant 3D, Raster Design) | **No** | "only supported on Windows operating system." [6] |
| Sheet Set Manager | Partial | Mac palette exists (renamed from Project Manager in 2026) but "has limited functionality compared to the Sheet Set Manager ... on Windows." Sheet Set Manager *for Web* was removed in AutoCAD 2026.1.1. [4][3][50] |
| DWG Compare / Xref Compare | Yes | Added 2019 for Mac, in-place compare and import since 2020; Xref compare 2021. [48][51][49] |
| Dynamic block authoring (Block Editor) | Unclear | Autodesk's comparison states "Lookup for Block tables is only available on AutoCAD and AutoCAD LT on Windows"; no Mac Block Editor page was retrievable. [52][1] |
| DesignCenter (ADCENTER) | **No** | "ADCENTER or DESIGNCENTER is not available in AutoCAD for Mac"; use Blocks palette. [53] |
| QuickCalc | **No** | Windows only. [1] |
| Classic toolbar interface | **No** | Windows only. [1] |
| 3D modeling / visualization | Yes | Free-form 3D, Fast Shaded mode expanded in 2026/2027; Metal-only from 2027. [1][3][23] |
| Smart Blocks (AI), Autodesk Assistant | Yes | 2026/2027 Mac releases. [3][23] |
| Languages | Partial | Mac: English, French, German, Japanese, Korean (2020+), Simplified Chinese (2021+). [54][49] |
| Network deployment tooling | Partial | No deployment-creation wizard on macOS; not a .pkg for JAMF. [55] |
| DWG TrueView | **No** | Windows-only; Autodesk suggests Parallels/Boot Camp or the web viewer. [56] |

## CAD / AutoCAD relevance

- **Who needs Windows AutoCAD on a Mac.** Anyone dependent on toolsets (Civil 3D and Plant 3D especially), Express Tools, DesignCenter, full Sheet Set Manager, Windows-only .NET add-ins or DWG TrueView. Autodesk's KB answer for each is "use Parallels/Boot Camp/remote Windows", not "wait for Mac parity". [6][30][56][28]
- **Revit is the strongest VM use-case Autodesk will bless.** The Revit 2026 requirements page is the only place Autodesk prints an Apple-silicon-plus-Windows-11 configuration; it also flags what breaks: Desktop Connector is incompatible with Windows ARM, hardware acceleration and Retina scaling must be off, and 4 GB video memory must be dedicated to the guest. [7][11]
- **Inventor/Navisworks/3ds Max are "works, unsupported".** Autodesk: Inventor on M1/M2 "not tested", known file-open issues on Parallels 18 fixed by the ARM64 VC++ redistributable; Navisworks "possible ... necessary to install Parallels"; 3ds Max under Parallels unsupported; ReCap cannot run in any VM because it "needs direct access to the graphics card". [29][30][31][14]
- **SolidWorks, SketchUp/Enscape, Chief Architect, Vectorworks.** Vendor pages were unreachable; no claim is made (see Open questions). The only related first-party evidence is Microsoft's note that Blender, Affinity and DaVinci Resolve ship native Arm64 Windows builds, which does not cover these vendors. [17]
- **What the Mac CAD user is really asking for** (synthesised from Autodesk's own troubleshooting articles, i.e. problems people actually filed): x64 fidelity without ARM-emulation caveats (VC++ ARM redist, 32-bit components, drivers) [13][22]; working sign-in and Desktop Connector inside the guest [12][11]; smooth cursor and correct Retina DPI [57][7]; folder mapping that does not break Windows installers [13]; GPU acceleration Autodesk will not tell them to switch off [7][14]; no second Windows license or Autodesk seat if avoidable [15][43].

## Strengths (what to match)

- **Native AutoCAD for Mac is fast and legitimate.** Apple-silicon binary, Metal renderer, same DWG, AutoLISP/ObjectARX, annual cadence in step with Windows (2026: Smart Blocks; 2027: AI block detection, Assistant). MIRRORZ must be at least as responsive for 2D drafting or users stay native. [25][3][23]
- **Parallels is the vendor-endorsed path.** Named in Autodesk's Revit requirements and Microsoft's Windows-on-Mac policy, with a documented configuration (16 GB host, 4 GB guest VRAM, Windows 11). MIRRORZ can only match this by getting into vendor documentation or being demonstrably more compatible. [7][15]
- **Prism has closed much of the x64 gap.** Microsoft states most x64 apps "are expected to perform comparably to native apps under emulation", with per-app emulation settings to trade compatibility for speed. [17][58]
- **Open tooling exists for the translation route.** Wine 11.x builds for macOS, DXMT/DXVK/D9VK renderers, and the Sikarugir wrapper framework are maintained; AutoLispExt shows Autodesk itself will support Mac-side developer tooling. [35][37][27]

## Weaknesses (what MIRRORZ must beat)

- **Support ambiguity.** Autodesk says AutoCAD-family products are unsupported under virtualization yet publishes a Parallels configuration for Revit; users cannot tell which applies. A vendor-verified compatibility matrix per Autodesk release would remove real anxiety. [8][7]
- **ARM-guest breakage.** Desktop Connector fails, 32-bit Office cannot be installed, kernel drivers (dongles, PDF printers, AV, anti-cheat) need Arm64 builds, WSL/Sandbox/VBS are unavailable, and DirectX 12 apps may not run. Avoiding the Arm-Windows layer sidesteps this whole class. [11][22][16][15]
- **Graphics compromises.** Autodesk's guidance for Revit in Parallels is to disable hardware acceleration and avoid the Accelerated Graphics preview; ReCap cannot run at all. MIRRORZ's differentiator should be Metal-backed D3D11/12 that Autodesk's viewers accept. [7][14]
- **Licensing friction.** Second Windows license per VM, Boot Camp/VM double activation, sign-in redirect bugs, 3-device single-user limits. Handling Identity Manager redirects and needing no Windows license (Wine route) is materially cheaper for the user. [15][45][12][43]
- **Community tool churn.** Whisky's archiving ("apps and games may break at any time") and Sikarugir's mixed licensing show that the Wine-on-Mac ecosystem lacks a commercial, supported product beyond CrossOver. [34][37]
- **No 2026-cycle evidence that Autodesk tests Windows-on-ARM for AutoCAD.** Windows AutoCAD 2025 and LT 2027 requirements still say "ARM Processors are not supported", so every Parallels AutoCAD user is off-policy. [9][10]

## Reusable code, ideas, and license implications for MIRRORZ

| Asset | What it offers | License / implication |
|---|---|---|
| Wine (via Gcenx macOS builds) | Win32/x64 loader, DLL reimplementation, WineD3D; Gcenx bundles gecko/mono and Vulkan-portability patches. | LGPL assumed (license page unreachable; verify). Dynamic linking plus published modifications is workable commercially. [35] |
| DXMT / DXVK / D9VK / MoltenVK | D3D10/11 to Metal (DXMT), D3D9-11 to Vulkan on MoltenVK. Sikarugir ships these as the *commercially usable* renderers. | Sikarugir states these "can be used for commercial ports"; check each project's license individually. [37] |
| Apple GPTK 4 / D3DMetal | Best D3D11/12-to-Metal performance, Metal 4 support, shader converter. | "closed source ... can not be used for commercial ports" per Sikarugir; Apple's page gives no redistribution grant. Treat as evaluation-only; do not ship. [36][37] |
| Whisky (archived) | SwiftUI bottle manager on CrossOver 22.1.1 + GPTK; UX reference for bottle management. | GPL-3.0: code cannot go into a proprietary app; ideas can. [34] |
| Sikarugir | Wrapper/launcher architecture, engine switching (WineD3D/D9VK/DXMT/D3DMetal/DXVK). | Configure.app LGPL-2.1; Launcher/Creator proprietary; read repo licence before reuse. [37] |
| UTM | QEMU-based full-system emulation and Apple Virtualization.framework front-end; experimental accelerated Windows 11 graphics. | Apache-2.0 with GPL/LGPL QEMU components; full x86_64 system emulation (TCG) is the slow fallback, not a CAD-grade path. [38][59] |
| FEX-Emu | Fast user-mode x86/x64-on-Arm64 JIT with Wine integration. | MIT, but **Linux only**; a macOS port would be a research project, though its Wine/thunk design is the closest open analogue to Prism + Wine. [60] |
| AutoLispExt | Autodesk's own cross-platform LISP debugger. | Apache-2.0; could be bundled or recommended. [27] |
| Autodesk KB troubleshooting set | Reproducible bugs to design against: Error 10 folder mapping, browser-redirect sign-in, cursor smoothness (DirectX9 / "Scaled" resolution), ARM64 VC++ redist. | Public documentation; use as an acceptance-test list. [13][12][57][29] |

Product implications: (a) decide early between an **x64 Windows guest** (avoids Arm-guest breakage but needs fast x64 emulation that does not exist in open form on macOS) and a **Wine-style translation layer** (no Windows license or drivers, but Autodesk Identity Manager and .NET-heavy apps like Revit are the risk); (b) either way, ship a per-release compatibility matrix for AutoCAD, Revit, Civil 3D, Inventor, Navisworks, Access, Visio and Project; (c) do not depend on D3DMetal for shipping builds.

## Open questions

1. List prices for AutoCAD, AutoCAD LT, Parallels Desktop, CrossOver, Windows 365 and Windows 11 Pro could not be fetched (vendor pages blocked); only Flex token rates were verifiable.
2. The AutoCAD 2026 (Windows) requirements article was not surfaced; "ARM Processors are not supported" is confirmed for AutoCAD 2025 and AutoCAD LT 2027, bracketing 2026.
3. SolidWorks, SketchUp/Enscape, Chief Architect and Vectorworks macOS/Apple-silicon status and pricing: vendor sites blocked; no first-party evidence gathered.
4. QuickBooks Desktop (Windows and Mac) sales/discontinuation status: intuit.com blocked.
5. Whether AutoCAD for Mac 2026/2027 supports dynamic-block *authoring* at parity: no Mac Block Editor page was retrievable; only "Lookup for Block tables is Windows-only" is confirmed.
6. Reddit r/AutoCAD, r/Revit and Autodesk Community threads were unreachable; user-pain evidence is drawn from Autodesk KB "users reported" articles and Microsoft Q&A threads instead.
7. Wine's licence text (gitlab.winehq.org) was blocked; confirm the LGPL assumption before any reuse decision.
8. Microsoft's "authorized" Parallels list stops at version 20 and M3; coverage of newer Parallels/M4/M5 combinations is unverified.

## Sources (numbered list of URLs with dates)

1. Autodesk KB, "Compare Features: AutoCAD for Windows against AutoCAD for Mac" (undated, retrieved 2026-09-03) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Compare-Features-AutoCAD-for-Windows-vs-AutoCAD-for-Mac.html
2. Autodesk ObjectARX 2027 docs, "Visual LISP IDE to Visual Studio Code Feature Access Comparison" — https://help.autodesk.com/view/OARX/2027/ENU/?guid=GUID-30033BD2-7A43-4109-B08A-C1CFC9A7D9A5
3. Autodesk, "What's New in AutoCAD for Mac 2026" (2026 docs; release notes dated 2025-03-25) — https://help.autodesk.com/view/ACDMAC/2026/ENU/?guid=GUID-6BA7B080-AF01-4DCE-905E-BAD3CD5AF66D and https://help.autodesk.com/view/ACDMAC/2026/ENU/?guid=AUTOCAD_MAC_2026_RELEASE_NOTES
4. Autodesk KB, "Are the TCOUNT and SHEETSET commands available in AutoCAD LT, including AutoCAD for Mac and AutoCAD LT for Mac?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Are-TCOUNT-SHEETSET-commands-available-for-Mac-versions-of-AutoCAD-LT.html
5. Autodesk ObjectARX 2027 docs, "Entity and Selection Set Functions Reference (AutoLISP/Express Tools)" — https://help.autodesk.com/view/OARX/2027/ENU/?guid=GUID-676F8B1B-7C23-4480-9DD4-19D0836EAE08
6. Autodesk KB, "Are AutoCAD Toolsets supported on Mac OS?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Are-AutoCAD-Toolsets-supported-on-Mac-OS.html
7. Autodesk KB, "System requirements for Revit 2026 products" (©2025) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Revit-2026-products.html
8. Autodesk KB, "Slow mouse performance in AutoCAD products when working in a virtual environment" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-on-Citrix-slow-mouse-performance.html
9. Autodesk KB, "System requirements for AutoCAD 2025 including Specialized Toolsets" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html
10. Autodesk KB, "System requirements for AutoCAD LT 2027" (includes AutoCAD LT 2026 for Mac) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-LT-2027.html
11. Autodesk KB, "Is Desktop Connector working on Windows running on iOS using Parallels with ARM64 processor?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
12. Autodesk KB, "Sign-in page does not appear when launching Autodesk products in Parallels on Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Sign-in-page-does-not-appear-when-launching-Autodesk-products-in-Parallels-on-Mac.html
13. Autodesk KB, "Install error: The install couldn't finish. Error 10 ... Parallels on macOS" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html
14. Autodesk KB, "Unable to Launch ReCap when using Mac Book Pro in Parallels or VMWare environment" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/ReCap-is-not-working-using-Mac-Book-Pro-in-Parallels-or-VMWare-environment.html
15. Microsoft Support, "Options for using Windows 11 with Mac computers with Apple M1, M2, and M3 chips" (undated) — https://support.microsoft.com/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c
16. Microsoft Learn, "How emulation works on Arm" (Prism, Windows 11 24H2) — https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation
17. Microsoft Support, "Windows Arm-based PCs FAQ" (references May 2026 content) — https://support.microsoft.com/windows/windows-arm-based-pcs-faq-477f51df-2e3b-f68f-31b0-06f5e4f8ebb5
18. Microsoft Learn, "Office applications service description — availability in plans for Mac" — https://learn.microsoft.com/office365/servicedescriptions/office-applications-service-description/office-applications-service-description#microsoft-365-apps-availability-in-plans-for-mac
19. Microsoft Learn, "Visio service description" and "Deployment guide for Visio" — https://learn.microsoft.com/office365/servicedescriptions/visio-online-service-description/visio-online-service-description ; https://learn.microsoft.com/microsoft-365-apps/deploy/deployment-guide-for-visio
20. Microsoft Q&A (moderator answers), "Cannot install Microsoft Project desktop client" and "Installing Microsoft Project on Mac" — https://learn.microsoft.com/answers/a/12418040 ; https://learn.microsoft.com/answers/a/12006666
21. Microsoft Learn, "Office for Mac" VBA overview and Q&A on ActiveX/Shell on Mac — https://learn.microsoft.com/office/vba/api/overview/office-mac ; https://learn.microsoft.com/answers/a/12390610 ; https://learn.microsoft.com/answers/a/11958041
22. Microsoft Learn, "32-bit Windows Arm-based devices end of support for Microsoft 365 Apps" (feature updates ended Oct 2025; security ends Dec 2026) — https://learn.microsoft.com/microsoft-365-apps/end-of-support/end-of-support-32bit-arm ; related Q&A https://learn.microsoft.com/answers/a/12348799
23. Autodesk, "What's New in AutoCAD for Mac 2027" — https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-81FF4C76-6077-4D2B-9081-250BDBEA645D
24. Autodesk, AutoCAD for Mac 2027 release notes (2026-03-25) and Updates (2027.0.1, 2026-05-26) — https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=AUTOCAD_MAC_2027_RELEASE_NOTES ; https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=AUTOCAD_MAC_2027_UPDATES
25. Autodesk, "Apple Silicon Support" (AutoCAD for Mac docs) — https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-EA31738F-CDDE-4170-970A-745BC19C7674
26. Autodesk ObjectARX docs, "General Development Compatibility (ObjectARX/.NET)" 2026 and 2027 — https://help.autodesk.com/view/OARX/2026/ENU/?guid=GUID-73279C76-12E2-468B-8687-6B07CE12C350 ; https://help.autodesk.com/view/OARX/2027/ENU/?guid=GUID-73279C76-12E2-468B-8687-6B07CE12C350
27. GitHub, Autodesk-AutoCAD/AutoLispExt (Apache-2.0; updated 2026-08-28) — https://github.com/Autodesk-AutoCAD/AutoLispExt
28. Autodesk KB, "Using Revit on a Macintosh system" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Revit-2017-on-Mac-OS-X.html
29. Autodesk KB, "Install options for Autodesk Inventor on a Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Can-I-install-Autodesk-Inventor-on-a-Mac.html
30. Autodesk KB, "Using Navisworks on a Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Where-I-can-find-Navisworks-for-Mac.html
31. Autodesk KB, "How to install 3ds Max on a Macintosh using Parallels Desktop" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-install-3ds-Max-on-a-Macintosh-using-Parallels-Desktop.html
32. Autodesk KB, "Using Fusion on Apple M1 or M2 System Architecture" (native as of July 2023) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Fusion-360-supported-on-Apple-M1-System-Architecture.html
33. Autodesk KB, "Autodesk Fusion crashes on startup on Windows on ARM" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Fusion-crashes-on-startup-in-Windows-on-ARM.html
34. GitHub, Whisky-App/Whisky (GPL-3.0; archived 2025-05-11) — https://github.com/Whisky-App/Whisky
35. GitHub, Gcenx/macOS_Wine_builds and releases (11.16 Aug 24; 11.15 Aug 8; 11.14 Jul 27) — https://github.com/Gcenx/macOS_Wine_builds ; https://github.com/Gcenx/macOS_Wine_builds/releases
36. Apple Developer, "Game Porting Toolkit" (GPTK 4) — https://developer.apple.com/games/game-porting-toolkit/
37. GitHub, Sikarugir-App/Sikarugir (Wineskin successor; D3DMetal commercial restriction statement) — https://github.com/Sikarugir-App/Sikarugir ; https://github.com/Kegworks-App/Kegworks
38. GitHub, utmapp/UTM and releases (5.0.5 beta 2024-09-02) — https://github.com/utmapp/UTM ; https://github.com/utmapp/UTM/releases
39. Autodesk KB, "How do I decide if I need a monthly, annual, or multi-year subscription?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-do-I-decide-if-I-need-a-monthly-annual-or-multi-year-subscription.html
40. Autodesk KB, MEP Content Editor Sync / "Revit 10 tokens, $30/day" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-there-any-charge-for-the-use-of-the-MEP-Content-Editor-Sync-tool-like-the-token-rate-per-person-or-is-it-based-on-storage-cost-or-both.html
41. Autodesk KB, "Flex tokens show charges for both Fusion Teams and Fusion" (Fusion 3 tokens/day) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Token-usage-for-Fusion-Teams.html
42. Autodesk KB, "Use Flex tokens with an Autodesk subscription"; "No cloud credits or tokens inside Autodesk Fusion account" (tokens expire 1 year) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Use-Flex-tokens-with-an-Autodesk-subscription.html ; https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cloud-Credits-for-Fusion-360-are-gone.html
43. Autodesk KB, "Is it possible to install and activate Revit/Revit LT on two machines?" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Can-I-install-and-activate-my-single-seat-of-Revit-on-multiple-machines.html
44. Autodesk KB, "Maximum number of computers permitted for a subscription with single-user access" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Maximum-number-of-computers-permitted-for-single-user-subscription.html
45. Autodesk KB, "Autodesk Software asks to repair your license when accessing 'My Boot Camp' on Parallels Desktop" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Software-asks-to-repair-your-license-when-accessing-My-Boot-Camp-on-Parallels-Desktop.html
46. Autodesk KB, "How to run Windows specific Autodesk programs on a Mac" and "Mac-compatible Autodesk software" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-run-Windows-specific-Autodesk-programs-on-a-Mac.html ; https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Mac-compatible-Autodesk-software.html
47. Autodesk KB, "How to view DWG drawing files on the Mac OS platform" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-view-DWG-drawing-files-on-the-Mac-Platform.html
48. Autodesk, "What's New in AutoCAD 2019 for Mac" (DWG Compare, Purge unsupported objects) — https://help.autodesk.com/view/ACDMAC/2023/ENU/?guid=GUID-683A46E8-DE14-4BAA-A546-58F23F9FFB00
49. Autodesk, "What's New in AutoCAD 2021 for Mac" (AutoLISP VS Code, DCL, Xref Compare, Metal) — https://help.autodesk.com/view/ACDMAC/2024/ENU/?guid=GUID-A16D55D2-0349-40F8-B6BA-B3E9FBE56A19
50. Autodesk, "About Sheet Set Manager for Web" (removed in AutoCAD 2026.1.1) and Mac "Sheet Set Manager Palette" — https://help.autodesk.com/view/ACD/2026/ENU/?guid=GUID-1690E514-A7B0-44EB-8EB0-E1C897D78780 ; https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-BC4FD147-114F-4940-9AEF-636A53D30C56
51. Autodesk, "What's New in AutoCAD 2020 for Mac" (in-place Drawing Compare, Blocks palette) — https://help.autodesk.com/view/ACDMAC/2023/ENU/?guid=GUID-357E401A-04D6-4624-B25C-97BA8E4637D4
52. Autodesk, "Block Editor" (AutoCAD 2027 Windows docs) — https://help.autodesk.com/view/ACD/2027/ENU/?guid=GUID-B69D58AD-7920-4198-AB2A-0E24B944F6CD
53. Autodesk KB, "ADCENTER command not working in AutoCAD Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/ADCENTER-command-not-working-in-AutoCAD-Mac.html
54. Autodesk KB, "Available languages for AutoCAD for Mac and AutoCAD LT for Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Available-languages-for-AutoCAD-LT-for-Mac.html
55. Autodesk KB, "Network deployment creation option for Autodesk software on Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Network-deployment-creation-option-for-Autodesk-software-on-Mac.html
56. Autodesk KB, "DWG TrueView will not install on the Mac operating system" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/DWG-TrueView-will-not-install-on-the-Mac-operating-system-to-open-DWG-files.html
57. Autodesk KB, "Cursor not moving smoothly when using Parallels Desktop on Mac" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-not-moving-smoothly-when-using-Parallels-Desktop-on-Mac.html
58. Microsoft Learn, "Adjust emulation settings on Arm" (Prism per-app settings, AVX/AVX2) — https://learn.microsoft.com/windows/arm/apps-on-arm-program-compat-troubleshooter
59. Microsoft Learn, "Windows 11 Arm ISO files overview" (Arm64 VMs on Apple silicon) — https://learn.microsoft.com/windows/arm/iso
60. GitHub, FEX-Emu/FEX (MIT; Linux Arm64 only) — https://github.com/FEX-Emu/FEX
61. Autodesk KB, "Installation issues for Autodesk products on Windows 64-bit running on ARM processors (WoA)" — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html
62. Microsoft Learn, "Add Arm support to your Windows app" (kernel drivers must be Arm64; no kernel emulation) — https://learn.microsoft.com/windows/arm/add-arm-support
