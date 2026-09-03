# Parallels Desktop for Mac (Parallels / KKR) — Competitor Profile

_Research date: 2026-09-03_

> Sourcing note. The session's egress policy denied direct fetches of parallels.com, kb.parallels.com, docs.parallels.com, forum.parallels.com and every news/review site tried (33 WebFetch attempts, all 403 by org policy). Facts therefore come from (a) WebSearch extracts of those pages (URL and date recorded; flagged "search extract"), (b) Microsoft support/Learn pages fetched in full via the Microsoft Learn MCP, (c) Autodesk support articles fetched in full via the Autodesk Help MCP, and (d) Parallels' open-source Go modules fetched from the allowed proxy.golang.org. Re-verify prices on parallels.com/products/desktop/buy/ before quoting externally.

## TL;DR (5 bullets)

- **Current version: Parallels Desktop 27** (27.0.0 build 58628, then 27.0.1 build 58670), press-released 2026-08-25 (blog dated 2026-08-21). **Apple-silicon-only, macOS 14 Sonoma or newer**; headline feature is a **Metal-based OpenGL 4.3 driver** (OpenGL up to 2.6x faster). Intel Macs stay on PD 26 with maintenance updates only.
- **List prices (USD):** Standard $99.99/yr or **$219.99 perpetual** (was $129.99 before the 2025 edition); Pro $119.99/yr; Business $149.99/yr; Pro/Business are subscription-only; App Store Edition is subscription-only and sandbox-limited. Launch promo $54.99 / $65.99 / $97.49 first year. **Windows 11 licence not included.**
- **Architecture:** an **ARM Windows 11 guest**; x86/x64 apps run through **Microsoft's in-guest Prism emulator**, not Parallels code. Parallels' own **x86 whole-VM emulator is a slow "early technology preview"** (1 vCPU, 8 GB cap, 2–7 min Windows boot, Pro/Business only). **DirectX 11.1 only — no DirectX 12.**
- **CAD reality check:** Parallels says "Autodesk recommends Parallels", but **Autodesk KBs state AutoCAD-family products are not supported in virtualized environments** and Windows-on-ARM is unsupported; Revit 2027 lists Parallels as a recommended config yet with **accelerated graphics "Not Supported"**; AutoCAD 2027 "Fast" visual styles need DX12 FL 12_0, which Parallels lacks. SolidWorks is validated against one Parallels build per release and not supported on Windows ARM.
- **Attack surface for MIRRORZ:** perpetual price hike plus a yearly major-version upgrade treadmill tied to macOS; DX12 gap; no nested virtualization (no WSL2/Hyper-V/VBS/Sandbox); double emulation for x64 CAD; Toolbox/upgrade nag prompts and auto-renewal complaints; separate Windows licence cost.

## Current status (version, date, maintainer, momentum)

| Item | Finding | Source |
|---|---|---|
| Latest version | **PD 27.0.0 (58628)**, then **27.0.1 (58670)** — stability/security, policy and declarative-deployment fixes | [7] |
| Release date | Press release 2026-08-25; blog dated 2026-08-21; AppleInsider/GlobeNewswire/MacTech 2026-08-25; one outlet says 28 Aug. **Use 25 Aug 2026.** | [1][2][3][6] |
| PD 27 features | Metal-based **OpenGL 4.3** driver (up to 2.6x; ArcGIS Pro up to +35%; "up to 160% faster" Blender 4.3); **SME exposure on M4/M5** (up to 7x matrix ops, 1.75x NN inference in Linux VMs); enterprise SSO improvements; security fixes in virtual networking, vGPU command processing and VirtIO; Ubuntu 26.04 LTS (x86_64 emulation), Fedora 44, Debian 13.6, Kali 2026.2 profiles | [1][2][3][5][50] |
| Platform | **Apple silicon only; Intel dropped**; minimum **macOS 14**; supports macOS 27 "Golden Gate". PD 26 keeps periodic security/compat updates for Intel Macs. | [4][5][6] |
| Previous major | PD 26 released 2025-08-26 (macOS Tahoe 26 + Windows 11 25H2; version numbering jumped from 20 to year-based 26). Latest PD 26 build: **26.4.1 (57516)**; a third-party listing dates it ~2026-08-09 (unverified). | [8][9] |
| Owner | Parallels International GmbH, owned by **KKR** funds. 2026-02-26: Corel announced a split — Vector Capital takes Corel's creativity brands, **Parallels stays with KKR** as an independent company (CEO Christa Quarles); the "Alludo" brand is gone. Close expected May 2026; no completion notice found. | [45] |
| Momentum | Annual majors locked to macOS releases; SOC 2 Type II; Enterprise Management Portal; Microsoft-authorized positioning; active tooling (Terraform provider v0.7.1 2026-01-23; prl-devops-service v1.0.5 2026-07-22). | [7][46] |

## Pricing and licensing (table)

USD list prices from Parallels' buy page and PD 27 launch coverage (Aug 2026).

| Edition | Subscription | Perpetual | Notes |
|---|---|---|---|
| **Standard** | **$99.99/yr** (promo $54.99 yr 1) | **$219.99** (up from $129.99/£104.99 to $219.99/£154.99 with the 2025 edition) | 4 vCPU / 8 GB vRAM per VM on Apple silicon; only edition with perpetual option |
| **Pro** | **$119.99/yr** (promo $65.99) | none | up to 18 vCPU / 62 GB vRAM per VM on Apple silicon (32 / 128 GB on Intel); dev tools, advanced networking, x86 emulator preview, CLI/API |
| **Business** | **$149.99/yr** (promo $97.49) | none | management portal, policies (USB, clipboard, shared folders, network), Intune/SSO; Enterprise custom |
| **App Store Edition** | in-app subscription, reported **$99.99/yr**; 14-day trial, auto-renews | none | sandboxed; see limits below |
| **Education** | 50% off | — | [49] |
| **Windows 11** | not included; Microsoft requires a separate Windows 11 Pro key per VM (keys are x64/ARM agnostic); Enterprise via volume licensing on top; ~$199 retail per third party (low confidence) | | [22][51] |

**Perpetual licence — included / excluded** (KB 122929 [13]; Macworld/TechRadar [11][12]):
- Included: indefinite use of the purchased major version; minor updates and fixes **for that version until end-of-life**; 30 days phone/chat support and 2 years email support from release; 3-month Parallels Toolbox.
- Excluded: **major-version upgrades** (discounted upgrade purchase required), unlimited support, and the "ongoing feature updates" subscriptions receive.
- macOS risk: Parallels' compatibility KB says older versions are "not fully optimized and compatible" with newer macOS and users "should upgrade to the latest Parallels Desktop version" [53]. With a new major every year, a perpetual licence has a one-to-two macOS-release shelf life; PD 27 dropping Intel leaves PD 26 Intel perpetual owners at end of line.
- Friction: a 2026 forum thread reports a "perpetual" purchase displayed as a subscription renewing in 60 days [43]; TechRadar's PD 26 headline lamented the effective loss of perpetual options [12].

**App Store Edition limitations** (KB 123796, WebNots [14][15]): same core as Standard, but the sandbox removes Mac-VPN sharing and VPN apps in Windows, keyboard-layout sync, Windows-to-Mac file sharing, Free Up Disk Space / Reclaim / Maintenance, SATA location selector, Picture-in-Picture, Touch Bar, middle-click shortcuts, virtual printer and VM templates. Parallels advises existing users not to migrate to it; it accepts Standard/Pro/Business subscription keys but not perpetual keys.

## How it works (architecture)

1. **Hypervisor.** Type-2 hypervisor using Apple-silicon hardware virtualization via a Parallels-written engine on Apple's Hypervisor framework; a VM can be switched between "Apple" and "Parallels" back-ends (Autodesk's KB recommends the Parallels back-end to cure AutoCAD selection lag) [33][47].
2. **Guest OS.** ARM64 guests only: Windows 11 on Arm (Pro/Enterprise authorized), ARM Linux, macOS. Windows 11 ARM (25H2 offered in-app) is downloaded from Microsoft in a two-click flow; activation needs the user's own key [9][22][26].
3. **x86/x64 Windows apps = Microsoft Prism.** Inside the ARM guest, Prism JIT-translates x86/x64 user-mode code to ARM64 with per-module caches; since 24H2 it exposes AVX/AVX2, BMI, FMA, F16C to x64 apps (not 32-bit x86 by default). **Kernel drivers must be native ARM64.** Some Prism optimizations require Snapdragon X hardware, so Apple-silicon guests miss part of the speed-up [24][25]. Parallels contributes nothing here.
4. **Parallels x86 whole-VM emulator.** PD 20.2 (Jan 2025) "early technology preview": x86_64 Windows 10 / Server 2022 (Windows 11 needs workarounds) and some Linux. Limits: **1 vCPU, 8 GB RAM max, UEFI guests only, no USB, no nested virtualization, Windows boot 2–7 minutes**; Parallels' own words: "slow, really slow". **Pro/Business/Enterprise only.** PD 20.3 (Apr 2025) added a **FEX-Emu**-based engine for Linux VMs; PD 27 ships an Ubuntu 26.04 x86_64 profile. heise/The Register: usable only in exceptional cases [17][18][19][20].
5. **Rosetta-in-Linux.** Since PD 19, ARM Linux VMs run x86-64 binaries/containers through Apple's Rosetta via Virtualization.framework (macOS 13+) [47].
6. **Graphics.** Paravirtual GPU mapped to Metal. Guest levels: **DirectX 11.1**; **OpenGL 4.3** with PD 27's driver (marketing pages still say 4.1). **No DirectX 12** although Windows reports it; DX12 forum requests have no roadmap answer [21][54][55][11].
7. **Coherence.** Hides the VM desktop; Windows app windows appear on the Mac desktop with a "Windows Applications" folder in the Dock; shared folders/clipboard; Apple Intelligence Writing Tools inside Windows apps (PD 20.1+); OBS virtual camera; Touch ID/Windows Hello [27].
8. **Not possible in the guest.** Nested virtualization (so no Hyper-V, WSL2, Windows Sandbox, VBS, Windows Subsystem for Android — WSL1 works); 32-bit ARM apps; non-ARM64 drivers (anti-cheat, some dongles). Apple's framework offers nested virtualization for macOS guests on M3+/macOS 15, but Parallels still does not for Windows VMs [22][48].
9. **Management.** Enterprise Management Portal, declarative deployment, Intune, SSO; prlctl/prlsrvctl CLI; REST DevOps service; Terraform/Packer/Vagrant integrations [46].

## Feature checklist (table: feature | status | notes)

| Feature | Status (Sept 2026) | Notes / source |
|---|---|---|
| Windows 11 ARM on Apple silicon | Yes, Microsoft-authorized | MS page names PD 18/19/20 on M1/M2/M3 for Win 11 Pro/Enterprise; Parallels claims M1–M5; MS page not updated for PD 26/27 or M4/M5 at fetch date [22][26] |
| Auto-download/install Windows 11 ARM | Yes | two clicks; 25H2 in-app; key not included [9][26] |
| x64/x86 Windows apps | via Microsoft Prism | AVX/AVX2 since 24H2; no kernel drivers [24][25] |
| Parallels x86 whole-VM emulation | tech preview, slow | 1 vCPU / 8 GB / UEFI / no USB; Pro+ only [17][19] |
| x86 Linux | preview via FEX; x86 binaries in ARM Linux via Rosetta | [20][47] |
| DirectX 11 | yes (11.1) | [21][55] |
| DirectX 12 | **no** | reported by Windows, not functional [11][21] |
| OpenGL | 4.3 (PD 27); 4.1 earlier | [1][28] |
| Vulkan in guest | not advertised | — |
| Coherence | yes | [27] |
| Nested virtualization (Windows guest) | no | blocks WSL2, Hyper-V, Sandbox, VBS, WSA [22][48] |
| 32-bit ARM apps | no | [22] |
| vCPU / RAM per VM | Std 4 / 8 GB; Pro 18 / 62 GB (Apple silicon) | [16] |
| Intel Mac support | PD 26 maintenance only | [4][5] |
| macOS guests | yes; nested virt on M3+/macOS 15 | [48] |
| Perpetual licence | Standard only, $219.99; majors extra | [10][13] |
| App Store Edition | subscription-only, sandbox-limited | [14][15] |
| Enterprise mgmt / SOC 2 | yes (Business/Enterprise) | [7][9] |
| Telemetry | opt-in/out CEP + "Product Usage Data" (VM names, hardware config, software inside VMs); Toolbox hits api2.amplitude.com even with CEP off | [39][41] |
| AI/ML acceleration | SME on M4/M5 (Linux; Windows per Parallels blog) | [1][5] |

## CAD / AutoCAD relevance

**Parallels' claims.** Its AutoCAD, Autodesk, Revit and SolidWorks pages say "Autodesk recommends Parallels Desktop" for the Windows-only Specialized Toolsets, that it is "the only Microsoft-authorized solution" on M1–M5, and that it provides DirectX 11 / OpenGL 4.1; the SolidWorks page cites RealView/FEA visualisation and Pro's 62 GB / 18 vCPU limits [28][29][52].

**Autodesk's own statements (fetched in full).**
- "Are AutoCAD Toolsets supported on Mac OS?": Toolsets are Windows-only, and "while some Autodesk products other than AutoCAD family might be under virtualized environment, **AutoCAD family products are not supported**" [30].
- "Installation issues ... Windows running on ARM processors (WoA)": ARM64 is "unsupported hardware... not compatible with Autodesk products, which are based on 64-bit (x64) software"; remedy: use an x64 computer [31].
- "Install error 10 ... Parallels on macOS": "ARM processors are not supported for a lot of desktop Autodesk products"; needs Rosetta 2 on the host and x64/x86/ARM64 VC++ runtimes; the environment "is not supported and may need consultation with third-party vendor Parallels" [32].
- "Selection in AutoCAD lags ... Parallels": switch the VM's hypervisor from Apple to Parallels [33].
- AutoCAD 2027 (Windows) requirements: 64-bit Windows 11, 8 logical cores, 16–32 GB, DX11 GPU basic / DX12 recommended; **"DirectX 12 with Feature Level 12_0 is required for 'Fast' visual styles"** — impossible under Parallels' DX11.1 vGPU. AutoCAD 2027 for Mac is native on M-series (macOS 14–26) but lacks Specialized Toolsets and most .NET/ObjectARX plug-ins [36][30].
- Revit 2027 requirements list "Parallels Desktop for Mac: Recommended-Level Configuration" (macOS 13.7+, 32 GB, any Apple silicon) but "**Accelerated Graphics: Not Supported with Parallels Desktop for Mac**"; run the Parallels adapter with hardware acceleration off. Autodesk's Revit-on-Mac KB notes M-series adds "a second layer of emulation to go from Windows for ARM to x64" [34][35].
- Autodesk's blanket clause: virtualize only where terms permit; Autodesk "makes no representations, warranties or other promises" and users "assume all risks" [37].

**SolidWorks.** No macOS build. Parallels is on Dassault's supported-hypervisor list, but each release is validated against one build (SolidWorks 2026 ↔ PD 26.0.1 per resellers); Windows-on-ARM is not officially supported; Composer is unsupported in VMs; resellers advise against Simulation/Flow/Visualize in a Mac VM [38].

**Net:** on Parallels, AutoCAD/Revit/SolidWorks run as x64 binary → Prism JIT → ARM Windows → DX11 vGPU → Metal, with no official Autodesk support and DX12 features disabled. Removing an emulation layer, delivering DX12-class graphics on Metal, or securing explicit ISV statements would each be a real differentiator.

## Strengths (what to match)

- Microsoft authorization plus a licensed one-click Windows 11 ARM download — settles the legality question for enterprises [22][26].
- Coherence-level integration: app windows in macOS, Dock entries, shared clipboard/folders, printers, Touch ID/Windows Hello, Apple Intelligence in Windows apps [27].
- Guest graphics on Metal at DX11.1 / OpenGL 4.3 with published pro-app gains (ArcGIS Pro, Blender, ZWCAD) [1][3].
- ISV mindshare: Revit sysreqs and Dassault's hypervisor list name Parallels; curated per-app CAD landing pages [28][34][38].
- Enterprise readiness: SOC 2 Type II, management portal, Intune, SSO, declarative deployment, Terraform/Packer/DevOps API [7][9][46].
- Yearly cadence with day-one support for each macOS [4].

## Weaknesses (what MIRRORZ must beat)

1. **Price/licence model:** $99.99–$149.99/yr; perpetual raised to $219.99 and locked to one major; new major yearly; Pro/Business subscription-only; Windows 11 Pro key extra [10][11][13].
2. **No DirectX 12** — no AutoCAD "Fast" visual styles, modern games, some viewers [11][36].
3. **Double emulation for x64 CAD** (Prism inside an ARM VM); Parallels' own x86 emulator is a 1-vCPU preview; nothing app-level [17][19][35].
4. **No nested virtualization:** WSL2, Hyper-V, VBS, Sandbox, WSA all fail [22].
5. **ISV support gap:** Autodesk disclaims AutoCAD-family virtualization and Windows-on-ARM; Revit accelerated graphics unsupported [30][31][34].
6. **Upsell/billing complaints:** recurring threads on Toolbox promotions inside Desktop and upgrade pop-ups; BBB reports of surprise renewals ($99.99 Feb 2026, $123.59 Aug 2026), refund refusals; perpetual licences shown as expiring subscriptions; Trustpilot centres on cancellation friction [40][42][43][44].
7. **Telemetry unease:** "Product Usage Data" includes VM names, hardware and software inside VMs; Toolbox contacts Amplitude even with CEP off [39][41].
8. **Intel Macs abandoned** by PD 27; App Store Edition gaps; Standard's 4 vCPU / 8 GB cap is below AutoCAD 2027's 8-core / 16–32 GB requirement [4][14][16][36].

## Reusable code, ideas, and license implications for MIRRORZ

- **Parallels Desktop is proprietary** — nothing to reuse. Its open source is tooling: `terraform-provider-parallels-desktop` v0.7.1 (2026-01-23) is **MIT** (copyright Carlos Lapao; "maintained by Parallels and the community"); `prl-devops-service` v1.0.5 (2026-07-22) and `packer-plugin-parallels` v1.2.8 (2025-04-22) exist but their licences were not verified [46]. Study for automation/API UX; do not copy prlctl semantics without a clean-room approach.
- **FEX-Emu:** Parallels adopted this open-source x86-on-ARM project for its Linux engine (PD 20.3). Strong candidate for MIRRORZ's user-mode x86-64 → ARM64 translation; verify its licence and any Parallels patches first [20].
- **Apple public APIs** Parallels depends on — Hypervisor.framework, Virtualization.framework (incl. Rosetta-for-Linux), Metal — carry no Parallels IP.
- **Ideas to copy:** one-click licensed Windows download; Coherence app-in-Dock UX; per-app CAD pages with benchmarks; hypervisor back-end toggle; policy portal.
- **Ideas to invert:** app-level execution (no full Windows VM, no Windows licence); DX12-on-Metal (Apple's Game Porting Toolkit D3DMetal is licence-restricted — evaluate carefully); a perpetual licence that survives macOS upgrades; no in-app upsell; opt-in telemetry that never inspects VM/app contents.
- **Legal/ISV:** Autodesk's virtualization terms and Windows-on-ARM disclaimers apply equally to MIRRORZ; seek explicit Autodesk/Dassault statements early — "supported" status is Parallels' main CAD moat and is thinner than its marketing implies.

## Open questions

1. Release date of 26.4.1 (57516) and whether a 26.5 exists (KB not fetchable).
2. Did the Corel/Vector Capital split close in May 2026; Parallels' new legal identity?
3. Has Microsoft's authorization page been updated for PD 26/27 and M4/M5 (fetched page still lists PD 18–20, M1–M3)?
4. App Store Edition current in-app prices (monthly option?) and PD 27 parity.
5. Does SME acceleration apply to Windows guests (Parallels blog) or Linux only (AppleInsider)?
6. Is the x86 emulator still Pro/Business-gated and 1 vCPU in PD 27?
7. Any DX12 roadmap statement (none found through Sept 2026)?
8. Licences of `prl-devops-service` and `packer-plugin-parallels`; FEX licence and Parallels upstream contributions.
9. Full current text of Autodesk's "Virtualization Policy" page.

## Sources (numbered list of URLs with dates)

1. Parallels PR, PD 27 — https://www.parallels.com/newsroom/news/press-releases/20260825-parallels-desktop-27/ (2026-08-25; search extract)
2. Parallels blog, PD 27 — https://www.parallels.com/blogs/parallels-desktop-27/ (2026-08-21; search extract)
3. AppleInsider, PD 27 — https://appleinsider.com/articles/26/08/25/new-parallels-desktop-27-delivers-faster-opengl-for-windows-apps-on-mac (2026-08-25)
4. TidBITS Watchlist, PD 27 — https://tidbits.com/watchlist/parallels-desktop-27/ (Aug 2026)
5. MacTrast, PD 27 Apple-silicon-only — https://www.mactrast.com/2026/08/parallels-desktop-27-update-now-apple-silicon-only-offers-faster-graphics-and-ai-acceleration-thanks-to-new-metal-based-graphics-driver/ (Aug 2026)
6. 9to5Mac, PD 27 — https://9to5mac.com/2026/08/29/parallels-desktop-27/ (2026-08-29); GlobeNewswire PR copy — https://www.globenewswire.com/news-release/2026/08/25/3350526/0/en/parallels-desktop-27-expands-professional-windows-app-support-with-faster-graphics-and-ai-acceleration.html (2026-08-25)
7. Parallels KB 131168, PD 27 updates summary — https://kb.parallels.com/en/131168 (2026; search extract)
8. Parallels KB 131014, PD 26 updates summary — https://kb.parallels.com/en/131014 (2026; search extract)
9. Parallels PR, PD 26 — https://www.parallels.com/newsroom/news/press-releases/20250826-parallels-desktop-26/ (2025-08-26)
10. Parallels, Buy page — https://www.parallels.com/products/desktop/buy/ (2026; search extract)
11. Macworld, PD 26 review — https://www.macworld.com/article/668146/parallels-desktop-review.html (2025)
12. TechRadar, PD 26 perpetual-licence piece — https://www.techradar.com/pro/a-mysterious-internet-speed-booster-feature-could-be-the-perfect-reason-to-jump-on-parallels-26-if-youre-on-mac-shame-about-the-lack-of-perpetual-license-though (2025)
13. Parallels KB 122929, one-time vs subscription — https://kb.parallels.com/en/122929 (search extract)
14. Parallels KB 123796, App Store vs Standard — https://kb.parallels.com/123796/ ; KB 124811 — https://kb.parallels.com/en/124811 (search extracts)
15. WebNots, App Store Edition — https://www.webnots.com/why-you-should-not-buy-parallels-desktop-for-mac-app-store-edition/
16. Parallels KB 120658, VM hardware limits — https://kb.parallels.com/en/120658 ; Pro page — https://www.parallels.com/products/desktop/pro/ (search extracts)
17. Parallels KB 130217, x86 emulator — https://kb.parallels.com/en/130217 (search extract)
18. Parallels docs PD 26, x86_64 VMs on Apple silicon — https://docs.parallels.com/pdfm-ug-26/parallels-desktop-for-mac-26-users-guide/advanced-topics/working-with-virtual-machines/importing-and-running-x86_64-intel-virtual-machines-on-apple-silicon-macs (search extract)
19. heise, "emulates Intel VMs – but lame" — https://www.heise.de/en/news/Parallels-Desktop-for-Apple-Silicon-emulates-Intel-VMs-but-lame-10238225.html (2025-01); The Register — https://www.theregister.com/2025/01/16/parallels_x86_vms_on_apple_silicon/ (2025-01-16)
20. Parallels blog, PD 20.3 (FEX) — https://www.parallels.com/blogs/parallels-desktop-20-3-0/ (2025-04); PD 20.2 — https://www.parallels.com/blogs/parallels-desktop-20-2-0/ (2025-01)
21. Parallels KB 129497, Windows 11 on Apple silicon limitations — https://kb.parallels.com/en/129497 ; KB 128914 — https://kb.parallels.com/en/128914 (search extracts)
22. Microsoft Support, Options for Windows 11 on M1/M2/M3 Macs — https://support.microsoft.com/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c (fetched 2026-09-03)
23. Microsoft Support, Windows Arm-based PCs FAQ — https://support.microsoft.com/windows/windows-arm-based-pcs-faq-477f51df-2e3b-f68f-31b0-06f5e4f8ebb5 (fetched 2026-09-03)
24. Microsoft Learn, How emulation works on Arm (Prism) — https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation (fetched 2026-09-03)
25. Microsoft Learn, Adjust emulation settings on Arm — https://learn.microsoft.com/windows/arm/apps-on-arm-program-compat-troubleshooter (fetched 2026-09-03)
26. Parallels, Microsoft-authorized page — https://www.parallels.com/products/desktop/microsoft-authorized-solution-windows-11-arm/ ; AppleInsider on the authorization — https://appleinsider.com/articles/23/02/16/microsoft-gives-official-blessing-to-windows-11-for-arm-on-parallels (2023-02-16)
27. Parallels KB 4670, Coherence — https://kb.parallels.com/en/4670 ; PD 26 docs, Merging Windows and macOS — https://docs.parallels.com/landing/pdfm-ug/parallels-desktop-for-mac-26-users-guide/use-windows-on-your-mac/setting-how-windows-works-with-macos/merging-windows-and-macos (search extracts)
28. Parallels, AutoCAD page — https://www.parallels.com/apps/autocad/ (2026; search extract)
29. Parallels, SolidWorks page — https://www.parallels.com/apps/solidworks/ (2026; search extract)
30. Autodesk KB, AutoCAD Toolsets on Mac OS — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Are-AutoCAD-Toolsets-supported-on-Mac-OS.html (fetched 2026-09-03)
31. Autodesk KB, Windows on ARM (WoA) — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html (fetched)
32. Autodesk KB, Install error 10 on Parallels — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html (fetched)
33. Autodesk KB, AutoCAD selection lag on Parallels — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Selection-in-AutoCAD-products-lags-for-several-seconds-on-Apple-Mac-computer-with-Parallels-running-Windows.html (fetched)
34. Autodesk, Revit 2027 system requirements — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Revit-2027-products.html (fetched)
35. Autodesk KB, Using Revit on a Macintosh — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Revit-2017-on-Mac-OS-X.html (fetched)
36. Autodesk, AutoCAD 2027 system requirements — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html (fetched)
37. Autodesk KB, Windows-specific Autodesk programs on a Mac — https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-run-Windows-specific-Autodesk-programs-on-a-Mac.html (fetched)
38. Hawk Ridge — https://hawkridgesys.com/blog/can-i-run-solidworks-on-mac ; Ace Cloud Hosting — https://www.acecloudhosting.com/blog/does-solidworks-run-properly-on-mac-with-parallel/ ; TriMech — https://video.trimech.com/can-solidworks-run-on-a-mac-in-2025 (2025–2026; search extracts)
39. Parallels CEP — https://www.parallels.com/about/legal/pcep/ ; Privacy Statement — https://www.parallels.com/about/legal/privacy/ (search extracts)
40. Parallels Forums, Toolbox advertisements and popups — https://forum.parallels.com/threads/parallels-toolbox-advertisements-and-popups.370595/ (Aug 2026)
41. Parallels Forums, Toolbox telemetry & Amplitude — https://forum.parallels.com/threads/parallels-toolbox-telemetry-amplitude.370528/ (2026)
42. BBB complaints, Parallels Inc — https://www.bbb.org/us/wa/yarrow-point/profile/computer-software-developers/parallels-inc-1296-22044003/complaints (2026)
43. Parallels Forums, perpetual shown as subscription — https://forum.parallels.com/threads/i-bought-a-perpetual-license-and-you-show-it-as-subscription-with-renewal-due-after-only-60-days.370736/ (2026)
44. Trustpilot — https://www.trustpilot.com/review/parallels.com ; MacRumors Forums billing thread — https://forums.macrumors.com/threads/parallels-billing-and-customer-support.2471042/
45. Corel split PR — https://www.parallels.com/newsroom/news/press-releases/20260226-corel-announcement/ (2026-02-26); heise — https://www.heise.de/en/news/Corel-to-be-split-Parallels-remains-with-KKR-11217943.html (2026-02)
46. GitHub Parallels org — https://github.com/Parallels ; terraform-provider-parallels-desktop v0.7.1 MIT, verified via https://proxy.golang.org/github.com/!parallels/terraform-provider-parallels-desktop/@latest (2026-01-23); prl-devops-service v1.0.5 (2026-07-22); packer-plugin-parallels v1.2.8 (2025-04-22)
47. Parallels KB 129871, Rosetta in Linux VMs — https://kb.parallels.com/en/129871 ; KB 125343 — https://kb.parallels.com/125343 (search extracts)
48. Parallels Forums, nested virtualization M3+/macOS 15 — https://forum.parallels.com/threads/macos-15-sequoia-nested-virtualization-for-m3-macs.364397/ (2024–2025)
49. Parallels Education — https://www.parallels.com/plans/education/ (2026)
50. Parallels docs, What's New in PD 27 — https://docs.parallels.com/landing/pdfm-ug/parallels-desktop-for-mac-27-users-guide/readme/whats-new-in-parallels-desktop-27 (Aug 2026; search extract)
51. The Software City, Windows 11 licence cost 2026 — https://thesoftwarecity.com/blog/how-much-does-it-cost-to-activate-windows (2026; low confidence)
52. Parallels, Autodesk page — https://www.parallels.com/apps/autodesk/ ; Revit blog — https://www.parallels.com/blogs/revit-for-mac/ (search extracts)
53. Parallels KB 114381, macOS compatibility — https://kb.parallels.com/en/114381 (search extract)
54. Parallels Forums, DirectX 12 request — https://forum.parallels.com/threads/directx-12-any-update-on-when-parallels-will-support-it.359555/
55. Parallels KB 124137, DirectX 11 support — https://kb.parallels.com/124137 (search extract)
