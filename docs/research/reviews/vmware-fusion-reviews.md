# VMware Fusion Pro (2024-2026): What Users Say, and What MIRRORZ Must Beat

_Research date: 2026-09-03_

**Method note.** 35+ distinct web searches (2024-2026 terms) and 8+ fetched pages. The corporate egress proxy blocked every Broadcom, VMware, Parallels, Macworld, MacHow2, Wikipedia and review-aggregator domain, so facts from those pages come from dated search-result snippets and are marked **[S]** (snippet). Facts from pages actually fetched (GitHub, Microsoft Support/Learn via the Learn tool, Autodesk KB via the Autodesk help tool) are marked **[F]**. Every price, version, date and support-status claim below carries a numbered source; nothing is from memory.

## TL;DR

- **Free, but community-supported.** Fusion Pro became free for personal use on 2024-05-14 and free for commercial/educational use on 2024-11-11; paid Pro and its support contracts were retired, and Broadcom's FAQ states free users are "NOT ENTITLED TO SUPPORT THROUGH THE GLOBAL SUPPORT TEAM" [13][14][20].
- **Not abandoned, but the "neglect" narrative sticks.** Calendar-versioned releases have shipped on a roughly quarterly cadence: 13.6.4 (2025-07-15), 25H2 (2025-10-14), 25H2u1 (2026-02-26), 26H1 (2026-05-14) and 26H1u1 (VMSA-2026-0007, 2026-09-03) [7][17][18][19]. Yet reviewers in 2026 still describe "persistent bugs and a general sense of neglect under Broadcom" [2].
- **Download friction is the single most repeated complaint** (8+ independent sources): Broadcom account, Trade Compliance form, "Account verification is pending" stalls, public URLs removed, Homebrew cask disabled five times in 2025, and MIT-licensed community scripts written specifically to get around it [1][3][4][5][6][7].
- **Apple Silicon gaps remain in 2026:** no x86 guests, no Unity (Coherence-equivalent), no shared folders/drag-drop for Windows-on-ARM guests, and Windows 10 unsupported; Parallels, by contrast, is Microsoft-authorized and now previews x86 emulation [10][11][24][3].
- **For AutoCAD** the constraints are Windows-on-ARM's, not just Fusion's: Autodesk officially treats Windows-on-ARM as unsupported hardware and says "AutoCAD is not a supported product under Virtualization" [15][18][21]; DirectX 12 is absent in ARM VMs, which disables AutoCAD 2027's "Fast" visual styles [11][17].

## Current status (version, date, maintainer, momentum)

| Item | Status as of 2026-09-03 | Source |
|---|---|---|
| Product | VMware Fusion Pro (macOS desktop hypervisor), universal binary for Intel and Apple Silicon Macs | [28] [S] |
| Maintainer | Broadcom (VMware by Broadcom) | [13] [S] |
| Latest release | **26H1u1** (security/bug-fix update to 26H1; fixes CVE-2026-59346 CVSS 9.3 VMXNET3 and CVE-2026-59347 CVSS 8.1 HGFS, VMSA-2026-0007 published 2026-09-03) | [17] [S] |
| Previous | 26H1, build 25388279, 2026-05-14 (fixes CVE-2026-41702 TOCTOU root escalation affecting 25H2, VMSA-2026-0003) | [7] [F], [27] [S] |
| Earlier 2025-26 | 25H2u1 build 25219963 (2026-02-26; drops `vctl`); 25H2 build 24995814 (2025-10-14; first calendar-versioned release, adds `dictTool`, macOS Tahoe host support, USB 3.2); 13.6.4 build 24832108 (2025-07-15; NAT DNS fix on Sequoia 15.4+) | [7] [F], [15][18][19] [S] |
| Versioning | Switched from 13.x to YYHn calendar versioning with 25H2 | [15] [S] |
| Host OS | macOS Tahoe 26 supported from 25H2; Apple has said Tahoe is the last macOS for Intel Macs, which caps Fusion's Intel future | [15][26] [S] |
| VMware Tools | open-vm-tools 13.1.0 released 14 May (matches the 26H1 date), 13.0.10 on 27 Jan, 13.0.5 on 30 Sep | [9] [F] |
| Momentum signal | Community mirrors of every build (gandli/vmware-downloads, 85 stars, created 2026-05-30) exist precisely because official downloads are gated | [7] [F] |

**Earlier vs. now.** In 2022-2023 (Fusion 13.0/13.5) Fusion was a $199-class paid product with a free Player tier; in 2024 it flipped to free, and in 2025-2026 it moved to calendar versioning under Broadcom [20][22][28]. Reviews written before late 2024 that discuss "Player vs Pro" pricing are obsolete.

## Pricing and licensing (table)

| Edition / period | Price | Notes | Source |
|---|---|---|---|
| Fusion Pro 13, before 2024-05 | ~$199 one-time (headline "199 $ app becomes free") | Pre-Broadcom-era list price; medium confidence (headline only) | [28] [S] |
| Fusion Player | Free personal tier; **End of Sale 2024-04-30** | Replaced by free Pro | [20] [S] |
| Fusion Pro, from 2024-05-14 | Free for personal use; paid commercial subscription still existed | Broadcom announcement | [20] [S] |
| Fusion Pro, from 2024-11-11 | **Free for commercial, educational and personal use**; no license key; only 13.5.2+ builds carry the free license | Paid Pro and paid support retired; support via docs and community forums | [13][14] [S] |
| Support entitlement | None from Broadcom Global Support; no public bug tracker; product team "monitors" community forums | Official FAQ | [12] [S] |
| Download prerequisite | Free Broadcom Support Portal "Basic" account + Trade Compliance webform (name, postal address, country); "dummy data" fails export screening | | [1][14] [F]/[S] |
| Competitor: Parallels Desktop 26 | $99.99/yr Standard, $119.99/yr Pro, $149.99/yr Business; $129.99 perpetual Standard | From reseller/coupon snippets; official buy page blocked, low-medium confidence | [23] [S] |
| Windows license | Separate Windows 11 Pro license required per VM instance (platform-agnostic keys) | Applies to both Fusion and Parallels | [11] [F] |

## How it works (architecture)

- **Hypervisor.** On Apple Silicon, Fusion runs on Apple's Hypervisor framework and needs no kernel extensions; it virtualizes only **ARM64 guests** ("It is not possible to run x86 operating systems in VMware Fusion VMs on Apple Silicon Mac systems") [10] [S]. On Intel Macs it still uses VMware's own VMM with the full feature set (Unity, shared folders, x86 guests).
- **Windows path.** Windows 11 on ARM is the only supported Windows guest on Apple Silicon; Windows 10 is not supported [10]. Inside the guest, Microsoft's **Prism** emulator (Windows 11 24H2+) JIT-translates x86 and x64 user-mode code; "emulation only supports user mode code and doesn't support drivers" [12] [F]. x64 emulation exists only on Windows 11, not Windows 10 [12].
- **Graphics.** Tech Preview 2023 (July 2023) added hardware-accelerated 3D for Windows 11 ARM guests, marketed as "full DirectX 11 3D games and apps", also for emulated 32/64-bit x86 software; OpenGL 4.3 is exposed to Linux ARM guests [21][22] [S]. DirectX 12 is not available in ARM VMs per Microsoft's own limitations list [11] [F].
- **Guest integration.** VMware Tools for Windows-on-ARM provides graphics, networking, clipboard and dynamic resolution, but Broadcom KB 315602 (updated July 2025) still lists shared folders, drag-and-drop, time sync, soft power ops and `vmrun` guest commands as unavailable for ARM guests, and Unity as unavailable [10] [S]. Nested virtualization (WSL2, VBS, Sandbox) is unavailable in ARM VMs on both Fusion and Parallels [10][11].
- **Tooling.** `vmrun`, a REST API (`vmrest`), `dictTool` (25H2), OVF Tool, Vagrant provider via a privileged utility service with a REST API (MPL-2.0) [10][15][10a].
- **Open components.** open-vm-tools: kernel modules GPL v2, user-space LGPL v2.1, SVGA/mouse drivers X11 license [8] [F].

## Feature checklist (table: feature | status | notes)

| Feature | Status (Apple Silicon, 26H1u1) | Notes / source |
|---|---|---|
| Free for commercial use, no key | Yes | Since 2024-11-11 [13] |
| Vendor support | No (community only) | [12][13] |
| Windows 11 ARM guest | Yes; ISO download from UI since 13.5 (2023-10-23) | [22] |
| Windows 10 / any x86 guest | No | KB 315602 [10]; Parallels 20.2+ previews x86 emulation, "really slow", no USB/nested [24] |
| x86/x64 Windows apps inside ARM guest | Yes via Prism (user-mode only, no x86 drivers) | [12] |
| 3D acceleration in Windows ARM guest | DirectX 11-class, OpenGL 4.3 for Linux | No DX12 [11][21]; reviewers: "workable but not good" [2] |
| Unity (Coherence-style seamless windows) | No | [10][3] |
| Shared folders / drag-drop (Windows ARM) | No (SMB or cloud sync workarounds) | [10][29] |
| Copy/paste, dynamic resolution | Yes (VMware Tools) | [21] |
| Nested virtualization (WSL2, VBS) | No | [10][11] |
| Snapshots, linked clones, custom networking | Yes (Pro feature set) | [5][30] |
| Intel Mac support | Yes (universal binary), but Tahoe is the last Intel macOS | [26][28] |
| macOS Tahoe host | Supported from 25H2; user-reported sleep/suspend and VoiceOver bugs | [15][8s][9s] |
| Microsoft-authorized Windows-on-Mac | No (Parallels 18/19/20 are) | [11] |
| Package-manager install (Homebrew) | Cask disabled since 2025-06-23 | [2f][5f] |
| Security update cadence | Fixes shipped 2026-02, 2026-05, 2026-09 | [17][18][27] |

## CAD / AutoCAD relevance

1. **Autodesk's support stance is the blocker, not Fusion's feature list.** Autodesk KB articles state that Windows-on-ARM is "Unsupported hardware (the ARM processor)... not compatible with Autodesk products, which are based on 64-bit (x64) software" [15] [F]; "AutoCAD 2025 is not supported on ARM x86 and x86 operating systems" [16] [F]; "AutoCAD is not a supported product under Virtualization" [18] [F]; and "Parallels Desktop is no longer supported by Autodesk since the AutoCAD 2013 release" [19] [F]. Every system-requirements page carries the disclaimer that virtualization is "as is" and the user "assume[s] all risks" [17] [F]. Autodesk's general policy (stated for Inventor) is that support will ask you to reproduce a bug on physical hardware before helping [20a] [F].
2. **Conflict to resolve: AutoCAD 2026 on ARM64.** A Microsoft Q&A moderator (2026-04-03) asserts "Autodesk now explicitly lists ARM64 operating systems as supported for AutoCAD 2026" [14] [F], and a reseller blog says the same for Snapdragon X [S]. The Autodesk pages retrievable here (AutoCAD 2027 requirements: "64-bit Microsoft Windows 11", no ARM mention) neither confirm nor deny it [17]. Treat ARM64 support as **unverified** until the AutoCAD 2026/2027 requirements page is read directly.
3. **Graphics ceiling.** AutoCAD 2027 requires a DirectX 11-compliant GPU at minimum, recommends DirectX 12, and "DirectX 12 with Feature Level 12_0 is required for 'Fast' visual styles" [17] [F]. Fusion's ARM guest exposes DirectX 11-class acceleration only [21], so AutoCAD would fall back to the DX11 path (`GFXDX12=0`) [22a]. Expect the classic VM symptoms Autodesk documents for Parallels: sluggish cursor, choppy linework, dialogs mis-sized, "hardware acceleration is turned off" errors [18b] [F].
4. **Native alternative.** AutoCAD for Mac 2024+ runs natively on Apple Silicon (Autodesk cites up to 2x speed-up) [23a] [F], but the specialized toolsets (Architecture, MEP, Electrical, Plant 3D, etc.) are Windows-only, and Autodesk says AutoCAD-family products are not supported when virtualized to get them [21] [F]. That toolset gap is MIRRORZ's real market.
5. **Evidence that x64 CAD does run in Fusion's ARM VM:** a September 2026 GitHub guide documents installing SolidWorks (x64) in Windows 11 ARM64 on Fusion Pro on an M2 Pro [31] [F]; details of performance were not retrievable.

## Strengths (what to match)

Ranked by how many independent sources repeat them (S = search-snippet source, F = fetched):

| # | Pro | Sources | Paraphrased quotes |
|---|---|---|---|
| 1 | Free for everyone incl. commercial, no key | 8+ ([13][14][20][28][1s][2s][4s][5s]) | "a no-brainer for personal/hobby use in 2026"; "one of the best-value virtualization solutions available" |
| 2 | Pro-grade VM management: snapshots, cloning, advanced networking, multi-VM | 5 ([5s][30][1s][4s][2s]) | "snapshot functionality... quickly revert back"; "superior networking and snapshot management" |
| 3 | Runs on both Intel and Apple Silicon Macs | 3 ([28][1s][30]) | "supports both Intel and Apple Silicon Macs... enterprise-grade capabilities" |
| 4 | Guest VMs are stable and fast once running (Capterra/TrustRadius) | 2 ([5s][6s]) | "The VMs are stable, fast, and reliable, with frequent updates" |
| 5 | One-click Windows 11 ARM download/install | 3 ([22][10][2s]) | "downloading and installing Windows 11... from the Fusion user interface" |
| 6 | Hardware 3D for Windows ARM (DX11) and Linux (OpenGL 4.3) | 4 ([21][22][28][10]) | "run full DirectX 11 3D games and apps with stunning fidelity" (2023 marketing) |
| 7 | Development and security fixes continue (four releases in 12 months) | 4 ([7][17][18][27]) | "critical architectural transitions... expanded support for the latest hardware and OS" |
| 8 | Strong multi-core throughput | 2 ([3s][32]) | "best-in-class multi-core performance... trails slightly... in single-core" |
| 9 | Good ARM Linux/dev workflows (Vagrant, k8s labs, NixOS) | 4 (GitHub repos [31], [10a], [30]) | "Perfect for developers who prioritize speed" |
| 10 | Lightweight macOS footprint, no kernel extensions | 2 ([30][33]) | "less aggressive about integrating itself into macOS" |

## Weaknesses (what MIRRORZ must beat)

| # | Con | Sources | Paraphrased quotes |
|---|---|---|---|
| 1 | Broadcom download/registration friction | 8+ ([1][2f][3f][4f][5f][6][7][2s][6s][7s]) | "The Broadcom portal to download Fusion is extremely confusing" (G2); "obliged to log in... presented with a Trade Compliance and Download Conditions form" (Homebrew #210104, 2025-04-25); "all known public URLs have been again removed as per upstream policy" (Homebrew PR, 2025-06-23); "Account verification is pending" stalls (Broadcom community blog, 2025-05-25) |
| 2 | No x86 guests on Apple Silicon; Windows 11 ARM only, Windows 10 unsupported | 6 ([10][1s][2s][34][35][24]) | "cannot virtualize x86 operating systems natively"; Parallels now ships an x86 preview, Fusion does not |
| 3 | No vendor support; community-only, no bug tracker | 6 ([12][13][3s][2s][4s][36]) | "NOT ENTITLED TO SUPPORT THROUGH THE GLOBAL SUPPORT TEAM"; "certainly isn't ideal if you're an enterprise deploying it" |
| 4 | Slower than Parallels in daily use (boot, suspend, CPU) | 5 ([3s][2s][6s][4s][32]) | "launches Windows in under 5 seconds versus VMware's 8.4" (Parallels, vendor); "suspending... 3 to 5 seconds, compared to 30 seconds to a full minute in Fusion" (MacHow2) |
| 5 | Missing Unity/Coherence and shared folders on Apple Silicon | 5 ([10][3s][29][2s][37]) | "still hasn't caught up on Coherence Mode or shared folders"; "Shared Folder is not supported for Windows 11 ARM GOS on Apple Silicon hosts" (KB, July 2025) |
| 6 | 3D/GPU performance weak; no DX12 | 5 ([2s][5s][6s][11][38]) | "Virtualized 3D performance is workable but not good"; "Less Attractive Graphics Api Support"; "More GPU enhancements have been requested" |
| 7 | Stability regressions on new macOS (Sequoia 15.x, Tahoe 26.x) | 4 sites, 6+ threads ([8s][9s][2s][39]) | "Fusion seems to be impacted by a serious bug in relation to Tahoe and sleep"; Start button flips to Suspend and back, VM never powers on; VoiceOver crash returned on Tahoe; "crashes immediately after launch on macOS Sequoia" |
| 8 | Perception of neglect / uncertain future under Broadcom | 5 ([2s][3s][1s][36][40]) | "dragged down by persistent bugs and a general sense of neglect"; "Broadcom hasn't committed to keeping it free long-term"; "no longer really competes at the same level" |
| 9 | Not Microsoft-authorized for Windows 11 on Mac (Parallels is) | 2 ([11][3s]) | "Parallels Desktop versions 18, 19, and 20 are authorized solutions" |
| 10 | Slow updates via Homebrew impossible; manual updates "can take a while" | 3 ([2f][5f][2s]) | Cask disabled 2025-03-24, re-enabled/re-disabled through 2025-06-23 |

**Reading the pattern for MIRRORZ:** users forgive missing polish when the product is free, but they do not forgive (a) a hostile acquisition path, (b) no one to call, and (c) a graphics ceiling that makes CAD "workable but not good". A paid product that removes all three has a clear story even against a free incumbent.

## Reusable code, ideas, and license implications for MIRRORZ

- **open-vm-tools** (vmware/open-vm-tools, 2.7k stars): kernel modules GPL v2; user-space daemon, shared-folders (vmhgfs/vmhgfs-fuse), drag-and-drop, clipboard, time-sync and guest-info plugins LGPL v2.1; SVGA/mouse drivers X11 [8] [F]. **Implication:** LGPL components can be linked from a proprietary MIRRORZ guest agent if kept as separately replaceable libraries and their source/notices ship; GPL v2 kernel modules cannot be merged into closed-source drivers. The Windows-side VMware Tools and the SVGA3D/DX11 translation layer are closed; nothing to reuse there.
- **hashicorp/vagrant-vmware-desktop** (MPL-2.0): pattern of a small privileged helper exposing a REST API for network setup and product verification, with the unprivileged app talking to it [10a] [F]. Reusable design, and MPL file-level copyleft is compatible with a commercial app.
- **St7530/VMware-download-helper** (MIT, 44 stars) and **gandli/vmware-downloads** (MIT, 85 stars) [6][7] [F]: not code to reuse but proof of demand: a one-click, no-account, no-compliance-form install is a feature. MIRRORZ should offer a signed direct download, Homebrew cask and MDM package on day one.
- **Product ideas worth copying:** `dictTool`-style CLI for editing VM config; lifecycle timestamps (created / last powered on) in the VM library (26H1) [16]; VM-level encryption with fast/full modes for vTPM [10]; Windows ISO fetch from inside the app (13.5) [22].
- **Do not copy:** Broadcom's gated distribution; community-only support with no bug tracker [12].
- **Legal note on Windows:** Microsoft's page says a separate Windows 11 Pro license is required per VM and only names Parallels (and Windows 365) as authorized on Apple Silicon [11] [F]. If MIRRORZ runs a Windows guest, an OEM/authorization conversation with Microsoft is on the critical path; if it runs Windows binaries without Windows, this is moot but the compatibility burden moves to MIRRORZ.
- **Autodesk policy:** any "AutoCAD on Mac via MIRRORZ" claim must be worded so users know Autodesk will not support it and may require reproduction on physical hardware [18][20a][21] [F].

## Open questions

1. Does Autodesk's AutoCAD 2026/2027 requirements page actually list ARM64 Windows as supported (Microsoft Q&A moderator says yes; Autodesk KB pages retrievable here say ARM is unsupported)? Needs a direct read of the Autodesk page [14][15][17].
2. What are the exact 26H1u1 build number and release date (a download site claims build 25689522; VMSA-2026-0007 dated 2026-09-03)? TechDocs was blocked [17].
3. Has the shared-folders/Unity gap for Windows-on-ARM changed in 26H1? KB 315602 (July 2025) says no; no 2026 source says otherwise [10].
4. Are there any measured DX11 benchmarks (e.g., AutoCAD or SolidWorks frame rates) in Fusion ARM VMs vs Parallels? Only qualitative claims found [2s][3s].
5. Will Broadcom keep Fusion free, and will Intel-Mac builds stop after Tahoe? No official statement found [3s][26].
6. Parallels 26 pricing came from reseller snippets; confirm on parallels.com [23].

## Sources (numbered list of URLs with dates)

Fetched pages [F]:

1. https://github.com/Homebrew/homebrew-cask/issues/210104 — "vmware-fusion package download now behind login and Trade Compliance form", 2025-04-25.
2f. https://github.com/Homebrew/homebrew-cask/pull/217370 — "vmware-fusion: re-re-disable", 2025-06-23.
3f. https://github.com/Homebrew/homebrew-cask/pull/206133 — "vmware-fusion: disable", 2025-03-24.
4f. https://github.com/Homebrew/homebrew-cask/issues/206132 — "vmware-fusion fails to download", 2025-03-24.
5f. https://github.com/Homebrew/homebrew-cask/issues?q=vmware-fusion — disable/enable history, 2025-03-04 to 2025-06-23.
6. https://github.com/St7530/VMware-download-helper — MIT userscript bypassing "Account verification is Pending" (undated; 44 stars as of 2026-09-03).
7. https://github.com/gandli/vmware-downloads — build/date table for Fusion 13.6.4, 25H2, 25H2u1, 26H1; data updated 2026-07-06.
8. https://github.com/vmware/open-vm-tools — licensing and components (read 2026-09-03).
9. https://github.com/vmware/open-vm-tools/releases — 13.1.0 (14 May), 13.0.10 (27 Jan), 13.0.5 (30 Sep), 13.0.0 (19 Jun).
10a. https://github.com/hashicorp/vagrant-vmware-desktop — MPL-2.0, REST utility design.
11. https://support.microsoft.com/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c — Parallels authorization, DX12 and nested-virtualization limits (undated; fetched 2026-09-03).
12. https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation — Prism emulation (fetched 2026-09-03).
13m. https://support.microsoft.com/windows/windows-arm-based-pcs-faq-477f51df-2e3b-f68f-31b0-06f5e4f8ebb5 — Windows on Arm limitations; Windows 10 EOL 2025-10-14.
14. https://learn.microsoft.com/en-us/answers/questions/5849358/dose-snapdragon-arm-processor-will-be-compatible-w — Microsoft Q&A, 2026-04-03 (community answer, not Autodesk).
15. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html — Autodesk KB: ARM unsupported.
16a. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-the-Smart-Block-feature-of-AutoCAD-2025-available-on-ARM-x86-or-x86-operating-systems.html — AutoCAD 2025 not on ARM.
17. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html — AutoCAD 2027 requirements (DX11 min, DX12 for Fast styles, virtualization disclaimer).
18. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-on-Citrix-slow-mouse-performance.html — "AutoCAD is not a supported product under Virtualization."
18b. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html — VM display symptoms.
19. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-Mac-won-t-launch-when-running-AutoCAD-within-Parallels.html — Parallels unsupported since AutoCAD 2013.
20a. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Does-Inventor-support-running-on-virtual-machines.html — virtual-install support policy.
21a. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Are-AutoCAD-Toolsets-supported-on-Mac-OS.html — toolsets Windows-only; AutoCAD family unsupported when virtualized.
22a. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-run-with-DirectX-11-instead-of-DirectX12-in-graphics-card-setting-by-default.html — GFXDX12.
23a. https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-EA31738F-CDDE-4170-970A-745BC19C7674 — AutoCAD for Mac native Apple Silicon.
31. https://github.com/dtorre38/Solidworks-Mac-VMware-Fusion-Install — SolidWorks on Fusion Pro / Windows 11 ARM64 / M2 Pro, created 2026-09-01.

Search-snippet sources [S] (pages blocked by proxy; dates as shown in results):

10. https://knowledge.broadcom.com/external/article/315602 — KB "Compatibility considerations for Arm guest operating systems in Fusion VMs on Apple silicon" (updated July 2025).
12. https://www.vmware.com/docs/desktop-hypervisor-faqs — Desktop Hypervisor FAQ (support entitlement, bug reporting).
13. https://blogs.vmware.com/cloud-foundation/2024/11/11/vmware-fusion-and-workstation-are-now-free-for-all-users/ — 2024-11-11.
14. https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html — KB 368667 (13.5.2+ free, no key, Trade Compliance form).
15. https://blogs.vmware.com/cloud-foundation/2025/10/14/vmware-workstation-fusion-25h2-embracing-calendar-versioning-and-new-features/ — 2025-10-14.
16. https://blogs.vmware.com/cloud-foundation/2026/05/14/announcing-vmware-workstation-and-fusion-26h1/ — 2026-05-14.
17. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/26H1/release-notes/vmware-fusion-26h1u1-release-notes.html — 26H1u1 release notes; VMSA-2026-0007 (2026-09-03 per https://aicybr.com/blog/vmware-workstation-fusion-vmsa-2026-0007).
18. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/25H2/release-notes/vmware-fusion-25h2u1-release-notes.html — 25H2u1, 2026-02-26.
19. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/13-0/release-notes/vmware-fusion-1364-release-notes.html — 13.6.4, 2025-07-15.
20. https://www.macrumors.com/2024/05/15/vmware-fusion-pro-13-free-personal-use/ and https://borncity.com/win/2024/05/12/vmware-player-fusion-player-is-end-of-sale-vmware-security-advisories-now-at-broadcom/ — free personal use 2024-05-14; Player EOS 2024-04-30.
21. https://appleinsider.com/articles/23/07/14/next-vmware-release-for-apple-silicon-will-have-full-3d-hardware-acceleration and https://9to5mac.com/2023/07/17/vmware-fusion-3d-macs/ — Tech Preview 2023 DX11.
22. https://tidbits.com/watchlist/vmware-fusion-13-5/ — Fusion 13.5, 2023-10-23.
23. https://www.parallels.com/products/desktop/buy/ (blocked); pricing via https://parallelscoupon.com/subscription/ and https://www.vendr.com/marketplace/parallels (2026).
24. https://kb.parallels.com/en/130217 — Parallels x86 emulation preview (20.2.0, Jan 2025 per https://www.theregister.com/2025/01/16/parallels_x86_vms_on_apple_silicon/).
26. https://appleinsider.com/articles/25/06/09/macos-tahoe-is-the-last-big-update-for-intel-macs — 2025-06-09.
27. https://cybersecuritynews.com/vmware-fusion-toctou-vulnerability/ — CVE-2026-41702, VMSA-2026-0003, 2026-05-14.
28. https://www.neowin.net/news/vmware-fusion-pro-26h1-released-with-support-for-more-guest-oses/ (May 2026) and https://www.notebookcheck.net/199-app-becomes-free-VMware-Fusion-Pro-13-virtualizes-Windows-11-for-free-on-Apple-MacBook-and-the-like.837839.0.html (May 2024).
29. https://forums.macrumors.com/threads/trying-to-share-folders-between-windows-11-arm-vm-and-m3-mac-where-is-the-sharing-preference-panel.2427538/ — shared-folders gap.
30. https://windowsforum.com/windows-news.4/parallels-desktop-vs-fusion-pro-best-windows-vm-for-apple-silicon-macs.441140/ — 2026 comparison.
32. https://www.diskinternals.com/vmfs-recovery/parallel-desktop-vs-vmware-fusion/ — multi-core claim.
33. https://mjtsai.com/blog/2020/07/09/vmware-fusion-tech-preview-for-big-sur/ — no-kext architecture (2020).
34. https://discussions.apple.com/thread/255841785 — M4 iMac, no x86 guests (2024).
35. https://forums.macrumors.com/threads/can-i-run-windows-10-on-vm-fusion-13-5.2411155/ — Windows 10 unsupported.
36. https://www.theregister.com/2023/12/15/vmware_by_broadcom_update/ — Broadcom commitment statement, 2023-12-15.
37. https://community.broadcom.com/vmware-cloud-foundation/discussion/fusion-13-where-is-the-setting-for-shared-folders — community thread.
38. https://www.hivenet.com/post/vmware-fusion-on-m1-macs-apple-silicon-virtualization-guide — 20-50% overhead, GPU limits.
39. https://community.broadcom.com/vmware-cloud-foundation/discussion/latest-fusion-crashes-immediately-after-launch-on-macos-sequoia-15x — Sequoia crash thread.
40. https://www.macworld.com/article/668080/vmware-fusion-review.html — Macworld review ("Now free for personal use").
1s. https://www.parallels.com/compare/vmware/fusion/ — Parallels vendor comparison (2026).
2s. https://machow2.com/vmware-fusion-mac-review/ — "VMware Fusion FREE Review 2026".
3s. same as 1s (Parallels comparison, vendor claims: 31-42% CPU, 8.4 s boot).
4s. https://macuser.org.uk/2026/01/21/compare-parallels-to-vmware-fusion/ — 2026-01-21.
5s. https://www.capterra.com/p/212917/VMware-Fusion/reviews/ — Capterra reviews (2026 page).
6s. https://g2.com/products/vmware-fusion/reviews — G2 reviews.
7s. https://community.broadcom.com/blogs/julia-klaus/2025/05/25/trouble-downloading-fusion-or-workstation-account — 2025-05-25.
8s. https://community.broadcom.com/vmware-cloud-foundation/question/is-macos-tahoe-stable-on-fusion-25h2 ; https://community.broadcom.com/vmware-cloud-foundation/discussion/fusion-1364-issues-with-macos-tahoe ; https://community.broadcom.com/vmware-cloud-foundation/discussion/crash-professional-26h1-25388279-macos-tahoe ; https://community.broadcom.com/vmware-cloud-foundation/discussion/macos-tahoe-265-vmware-fusion-26h1-and-vmware-tools-1310 — Tahoe stability threads (2025-2026).
9s. https://www.applevis.com/forum/macos-mac-apps/vmware-fusion-macos-tahoe — VoiceOver and sleep bugs on Tahoe.
