# Windows 11 on Arm: Licensing and Acquisition for VMs on Apple Silicon

_Research date: 2026-09-03_

Scope: what Microsoft permits, sells and supports for Windows 11 on Arm in a VM on Apple silicon, and what it means for MIRRORZ. Every price, version, date and status comes from a page fetched on 2026-09-03 unless marked "unfetched" (search snippet only; the research proxy blocked Parallels, Broadcom/VMware, UTM docs and most news sites).

## TL;DR

- Microsoft's live support article names exactly two routes for Windows 11 on Apple silicon: Windows 365 Cloud PC, and "Parallels Desktop versions 18, 19, and 20" as "authorized solutions for running Arm versions of Windows 11 Pro and Windows 11 Enterprise" on M1/M2/M3. No other hypervisor, no Home edition, no M4/M5 [S1].
- Official Windows 11 Arm64 ISOs have existed since November 2024 (first reported 2024-11-13 [S5]); the download page now serves "Windows 11 2025 Update | Version 25H2", a multi-edition ISO unlocked by product key, and Microsoft says "the primary use for Windows 11 Arm64 ISO files is to create virtual machines" [S2][S3].
- One license per VM. Microsoft Store list prices today: Windows 11 Pro USD 199.99, Home USD 139.00; Home-to-Pro upgrade about USD 99 [S8][S9][S10]. Microsoft: Pro keys are "platform agnostic (x64 vs Arm)" [S1]. The Windows license terms (April 2024 text) allow "only one instance of the software for use on one device, whether that device is physical or virtual" [S12].
- No Microsoft program lets an app vendor bundle Windows client licenses for VMs: ISV Royalty "does not currently include desktop operating systems" [S15]; Microsoft's virtual-desktop guidance says OEM licenses "typically" carry no virtualization rights [S14]. MIRRORZ must be bring-your-own-retail-license unless it negotiates a Parallels-style deal.
- Windows 365 is viable for firms but "isn't currently available for individuals" [S16]; Business runs USD 25.60-255.20 per user/month after a 20% cut on 2026-05-01, Enterprise USD 28-765 (GPU to 1,914) [S17][S17b][S18]. Windows 10, Arm included, left support 2025-10-14; consumer ESU now runs to 2027-10-12 [S20][S21b].

## Current status (version, date, maintainer, momentum)

**Owner:** Microsoft (Windows licensing, Windows on Arm docs, Windows 365). The Parallels authorization was announced by Alludo on 2023-02-16 (unfetched [S24]); the Microsoft support article behind it is undated but live [S1].

**Then vs. now:**
- 2021: Microsoft told The Register that Windows 11 on Arm on M1 Macs was "not a supported scenario"; only Insider Arm builds existed (unfetched, Sept 2021 [S25]). A Microsoft Q&A from 2023-10-15 confirms: "There isn't any official ISO for Windows 11 ARM available", only the Insider VHDX or UUP Dump [S4].
- 2023-02-16: Parallels Desktop 18 authorized for Pro/Enterprise on M1/M2 [S24]; the article now reads 18/19/20 and M1/M2/M3, still omitting Parallels 26, M4 and M5 [S1].
- 2024-11-13: official Arm64 ISO (24H2 then) [S5], documented on Microsoft Learn [S2].
- GA dates: 24H2 2024-10-01, 25H2 2025-09-30, 26H1 2026-02-10 [S6]. 26H1 is Arm-only, preinstalled on Snapdragon X2 devices, "not offered through Windows Update", on a different core; Home/Pro updates end 2028-03-14 [S6][S7]. VMs live on the 24H2/25H2 core (ISO = 25H2) and its H2-2026 successor [S7].
- 2026-05-01: Windows 365 Business list prices cut 20%; Windows Hybrid Benefit SKUs withdrawn from sale [S18]. Frontline renamed Flex; Reserve and Link added [S13][S16].

**Momentum:** Microsoft keeps investing in Windows on Arm (Prism emulator in 24H2, native Arm64 Office, Arm-first 26H1) [S6][S22] and calls Windows 365 "the most secure and fully compatible option" for Macs [S22]. The Parallels-only authorization has not widened in 3.5 years.

## Pricing and licensing (table)

| Item | USD list price | Source (date) | Notes |
|---|---|---|---|
| Windows 11 Pro, digital download | 199.99 | Microsoft Store [S8] (2026-09-03) | Page silent on Arm; Microsoft says Pro keys are platform-agnostic [S1] |
| Windows 11 Home, digital download | 139.00 | Microsoft Store [S9] (2026-09-03) | Not in the Parallels authorization; installable from the Arm ISO [S3][S11] |
| Home-to-Pro upgrade | ~99-99.99 | Microsoft Q&A [S10] (2025-10-10; 2024-11-20) | Requires an activated Home install |
| Windows 11 Enterprise in a VM | Volume licensing only | [S1][S14] | "get the Windows 11 Pro license. Then upgrade ... through a volume licensing agreement" |
| Windows 365 Business (up to 300 users, no other licenses needed) | 25.60 (2vCPU/4GB/64GB) to 255.20 (16vCPU/64GB/1TB); 108.80 for 8vCPU/32GB/256GB "design and engineering workstations" per user/month | [S17][S19] (2026-09-03) | 20% list decrease effective 2026-05-01 [S18] |
| Windows 365 Enterprise | 28 to 765; GPU SKUs 310 / 537 / 1,029 / 1,914 per user/month | [S17b] | Needs Windows Enterprise + Intune + Entra ID P1 per user [S13] |
| Windows 10 ESU, commercial | 61 per device year 1, doubling, max 3 years; free for Windows 365/Azure VMs | [S21] | Windows 10 retired 2025-10-14 [S20] |
| Windows 10 ESU, consumer | Free (Windows Backup or 1,000 Rewards points) or one-time 30 | [S21b] | "program ends on October 12, 2027"; a May-2026 Q&A moderator still said one year [S21c] - newest official page preferred |
| ISV Royalty (bundle Microsoft products in your app) | n/a | [S15] | Excludes "desktop operating systems, server operating systems, and online services" |
| Parallels Desktop 26 Standard (comparison) | 99.99/yr (unfetched [S26]) | | Windows sold separately |

**Governing license text.** The Windows OEM terms (last updated April 2024) and the Windows 10 retail terms (June 2018; the Windows 11 retail PDF URL could not be located, but the Windows 11 OEM text carries the identical clause) state: "(iv) Use in a virtualized environment. This license allows you to install only one instance of the software for use on one device, whether that device is physical or virtual. If you want to use the software on more than one virtual device, you must obtain a separate license for each instance." "Device" means "a local hardware system (whether physical or virtual)". Stand-alone (retail) software "may transfer ... to another device that belongs to you"; preinstalled software transfers only with the device. Prohibited: commercial hosting and installing "on a device for use only by remote users". Use requires activation "with a genuine product key or by other authorized method" [S12][S12b].

## How it works (architecture)

1. **Acquisition.** Download the Arm64 multi-edition ISO (25H2) from microsoft.com; "your product key ... unlock[s] the correct edition". The Arm ISO offers Home, Pro and Home Single Language but no N editions (a Pro N key fails with 0xC004F050, Dec 2025) [S3][S11].
2. **Third-party auto-download.** Parallels offers "Get Windows 11 from Microsoft" with "Auto Install" (Microsoft-moderated Q&A, 2026-05-29 [S11b]); snippets say it pulls an ESD such as `26100.2033...CLIENTCONSUMER_RET_A64FRE_en-us` from Microsoft servers and converts it with `esd2iso` (unfetched [S27]). VMware Fusion 13.5+ added a similar "Get Windows from Microsoft" flow (unfetched [S28]). The open-source route is CrystalFetch (Apache-2.0), which builds the ISO from "UUPDump APIs and converter scripts" and states "a valid license is required to install Windows 11" [S29]; UTM guides point to CrystalFetch in the Mac App Store and to "I don't have a product key" in Setup [S30]. No fetched Microsoft page documents a sanctioned third-party download API; the ISO page only warns that unsupported installs "won't be entitled to receive updates" [S3].
3. **Virtualization.** UTM (Apache-2.0) runs Windows on Arm via QEMU on Apple's Hypervisor.framework and uses Virtualization.framework only for macOS guests [S31]. Windows 11 needs UEFI plus a virtual TPM, which Parallels supplies (unfetched [S27]).
4. **Activation.** Enter a retail key in Settings > System > Activation; after rebuilding a VM the activation troubleshooter's hardware-change option re-assigns it [S32]. Microsoft: "A unique license is required for each instance of Windows 11 Pro, either on hardware or in a virtual machine" [S1].
5. **Documented guest limits (Parallels case):** WSL, Windows Subsystem for Android, Windows Sandbox and virtualization-based security "aren't supported"; 32-bit Arm Store apps unsupported; DirectX 12 caveats; "certain security features might not be available" [S1][S22].
6. **Cloud alternative.** Windows 365 streams a Cloud PC to the Mac via the Windows App or a browser, supports nested virtualization on 4vCPU+ sizes, and needs a Microsoft 365 tenant [S1][S13][S16].

## Feature checklist (table)

| Feature | Status (2026-09-03) | Notes / source |
|---|---|---|
| Official Arm64 ISO | Available (25H2) | Since Nov 2024; VMs are the stated primary use [S2][S3][S5] |
| Windows 10 Arm ISO | Never published | Insider VHDX only; Windows 10 unsupported since 2025-10-14 [S4][S20] |
| Microsoft-authorized hypervisors on Apple silicon | Parallels 18/19/20 (M1-M3) only | Pro/Enterprise only [S1] |
| Windows 11 Home in a VM | Installable, unauthorized | Moderator: "you might still be able to run Home ... be prepared for incompatibilities" [S11b] |
| Enterprise in a VM | VL upgrade from Pro, or VDA/E3/E5/M365 rights | [S1][S14] |
| Retail key activates Arm build | Yes, "platform agnostic" | [S1][S32] |
| 26H1 in a VM | Not available | Preinstalled Snapdragon X2 only [S7] |
| Microsoft Store in the VM | Works; only 32-bit Arm Store apps excluded | Reinstalling a missing Store app is "not supported" by Microsoft [S1][S33]; Parallels has a KB for it (unfetched [S34]) |
| WSL / Sandbox / VBS | Not supported (nested virtualization) | [S1] |
| Windows 365 for individuals | Not available | [S16] |
| Windows 365 from macOS | Supported (Windows App, browser) | [S13][S16] |
| Vendor-bundled Windows license | Not available for client OS in a VM | [S14][S15] |
| Windows 10 consumer ESU | Through 2027-10-12 | [S21b] |
| Autodesk products on Windows on Arm | Officially unsupported | [S35]-[S38] |

## CAD / AutoCAD relevance

- Autodesk's KB says "You are unable to install any Autodesk program on an ARM based processor for a Windows Operating System (WoA)", calling Arm64 "unsupported hardware" [S35]. AutoCAD 2025 requirements: "ARM Processors are not supported" [S36]. AutoCAD 2027 requirements (64-bit Windows 11, .NET 10) no longer mention Arm either way [S37]; the 2026 page was not retrievable, and a third-party claim that 2026 "explicitly lists ARM64" is unverified (unfetched [S39]).
- Autodesk maintains a KB for "Error 10" installs on "Windows Virtual Machine running Parallels on macOS": install the ARM64 Visual C++ redistributable, "ARM processors are not supported for a lot of desktop Autodesk products", and "Virtualization Policy, this environment is not supported" [S38]. Desktop Connector "does not work ... when running Windows through Parallels" on Apple silicon [S38b]; Fusion on WoA/Parallels needs a software-renderer workaround [S38c].
- Every Autodesk requirements page adds: virtualize "only if the applicable terms and conditions ... expressly permit virtualization", with no warranty for any virtualization environment [S36][S37].
- Net: AutoCAD in a Windows 11 Arm VM runs x64 code under Prism emulation (24H2+) [S22] on an OS Autodesk does not list, in a hypervisor Microsoft lists only if it is Parallels. Only Windows 365 (8vCPU/32GB or GPU sizes, USD 108.80-1,914 per user/month, organizations only) pairs Microsoft support with x64 AutoCAD [S16][S17][S17b].

## Strengths (what to match)

- Parallels' Microsoft-blessed flow: one-click "Get Windows 11 from Microsoft", automatic Arm image download, vTPM/UEFI, and a Microsoft page IT admins can cite. MIRRORZ needs an equally frictionless legal path: the official 25H2 Arm64 ISO plus the USD 199.99 Pro / 139.00 Home listings [S3][S8][S9].
- Microsoft's own wording that a retail key is all a VM needs and works across x64/Arm [S1][S32]; quote it in onboarding.
- Windows 365's "any device, fully compatible, nested virtualization allowed" message [S1][S22] is the compatibility bar in the enterprise segment.

## Weaknesses (what MIRRORZ must beat)

- Cost: USD 199.99 for Pro on top of the app; Parallels plus Windows is roughly USD 300 in year one (Parallels price unfetched [S26]).
- No consumer Windows 365; Business needs a tenant and admin center [S16][S17].
- Microsoft-listed VM gaps: no WSL, Sandbox, VBS or 32-bit Arm Store apps; DirectX 12 caveats [S1].
- Edition friction: no N editions on the Arm ISO, Home unauthorized, Enterprise needs a VL agreement [S1][S11].
- Autodesk leaves any Arm-VM CAD user unsupported by both vendors [S35][S38].
- The authorization page lags hardware (no M4/M5) and is Parallels-only; a new vendor starts from "unsupported" [S1].

## Reusable code, ideas, and license implications for MIRRORZ

- **CrystalFetch (Apache-2.0)** is reusable for building the Arm ISO from Microsoft's update servers via UUP Dump metadata; Apache-2.0 permits commercial use with attribution and NOTICE preservation. Copy its disclaimers ("not affiliated with Microsoft", "a valid license is required") [S29].
- **UTM (Apache-2.0 with GPL/LGPL parts such as QEMU and gstreamer plugins)** demonstrates the QEMU + Hypervisor.framework pattern; check the mixed licensing before static linking [S31].
- **Legal posture:**
  1. The Windows license terms permit VM installs provided each VM has its own license and use is neither commercial hosting nor remote-only [S12]. A customer running their own retail Windows on their own Mac stays within those terms; nothing fetched suggests a hypervisor needs Microsoft's permission for that. "Authorized" in [S1] is a support statement, not an exclusive right.
  2. Do not resell or bundle Windows: ISV Royalty excludes desktop OS [S15]; OEM/System Builder licenses are for preinstallation on new PCs and generally lack virtualization rights [S14] (System Builder terms on Newegg were not fetchable [S40]).
  3. Trademarks: no "Windows" in the product name, no implied endorsement; "works with Windows" compatibility claims are fine [S41]. Never say "Microsoft-authorized"; today that phrase belongs to Parallels.
  4. Auto-downloading the ISO is a gray area: Parallels, VMware and CrystalFetch all do it, but no fetched Microsoft document authorizes or forbids it. Prefer the official download page and record the user's acceptance of Microsoft's terms in Setup.
  5. Home is licensable [S12] but unsupported in this scenario [S11b]; default guidance to Pro.
  6. Never promise Windows 10: no Arm ISO ever existed and the product is retired [S4][S20].
- **Product ideas:** a bring-your-key wizard deep-linking to the USD 199.99/139.00 SKUs; up-front disclosure of Microsoft's documented VM limits; an optional Windows 365 connector (Windows App runs on macOS [S13]) for firms needing supported x64 AutoCAD.

## Open questions

1. Has Microsoft extended the authorization beyond Parallels 18-20 and M1-M3 (Parallels 26, M4/M5)? The live page does not say [S1].
2. Is there a formal Microsoft-Parallels agreement covering in-app ESD download, and could a new vendor get the same? No public document found.
3. Does AutoCAD 2026/2027 officially support Windows on Arm? 2027 is silent, 2025 says no, the WoA KB says no; the "ARM64 in 2026" claim is unverified [S36][S37][S39].
4. Will the H2-2026 feature update ship an Arm64 ISO, and will 26H1-only features ever reach VMs? [S7]
5. Consumer ESU: 2027-10-12 per the consumer page vs. one year per a May-2026 moderator [S21b][S21c].
6. Current Parallels 26 pricing and whether Parallels sells Windows keys in-app (unfetched).

## Sources (numbered list of URLs with dates)

1. [S1] Microsoft Support, Options for using Windows 11 with Mac computers with Apple M1, M2, and M3 chips (undated; fetched 2026-09-03): https://support.microsoft.com/en-us/windows/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips-cd15fd62-9b34-4b78-b0bc-121baa3c568c
2. [S2] Microsoft Learn, Windows 11 Arm ISO files overview (fetched 2026-09-03): https://learn.microsoft.com/en-us/windows/arm/iso
3. [S3] Microsoft, Download Windows 11 Arm64, shows Version 25H2 (fetched 2026-09-03): https://www.microsoft.com/en-us/software-download/windows11arm64
4. [S4] Microsoft Q&A, Windows 10/11 ISO for ARM (2023-10-15): https://learn.microsoft.com/en-us/answers/questions/4094716/where-can-i-download-the-windows-10-and-or-11-iso
5. [S5] GitHub, AmpereComputing/Windows-11-On-Ampere issue #6 (2024-11-13): https://github.com/AmpereComputing/Windows-11-On-Ampere/issues/6
6. [S6] Microsoft Learn, Windows 11 release information (revised 2026-08-27): https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information
7. [S7] Microsoft Learn, Windows 11 version 26H1 (2026-02-10): https://learn.microsoft.com/en-us/windows/whats-new/windows-11-version-26h1 and https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-26h1
8. [S8] Microsoft Store, Windows 11 Pro, USD 199.99 (fetched 2026-09-03): https://www.microsoft.com/en-us/d/windows-11-pro/dg7gmgf0d8h4
9. [S9] Microsoft Store, Windows 11 Home, USD 139.00 (fetched 2026-09-03): https://www.microsoft.com/en-us/d/windows-11-home/dg7gmgf0krt0
10. [S10] Microsoft Q&A, Home-to-Pro upgrade cost (2025-10-10; 2024-11-20): https://learn.microsoft.com/en-us/answers/questions/5580879/win-11-home-office-2025-sutdent-licences-upgrade-w and https://learn.microsoft.com/en-us/answers/questions/4013416/upgrading-to-windows-11-pro-using-microsoft-store
11. [S11] Microsoft Q&A, Windows 11 Pro N on ARM (Parallels) (2025-12-04): https://learn.microsoft.com/en-us/answers/questions/5646758/windows-11-pro-n-on-arm-parallels
12. [S11b] Microsoft Q&A, Using Windows 11 through parallels on mac (2026-05-28): https://learn.microsoft.com/en-us/answers/questions/5904730/using-windows-11-through-parallels-on-mac
13. [S12] Microsoft License Terms, Windows OS, OEM, last updated April 2024 (PDF fetched 2026-09-03): https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/11/oem-(pre-installed)/UseTerms_OEM_Windows_11_English.pdf
14. [S12b] Microsoft License Terms, Windows 10 retail, June 2018 (PDF fetched 2026-09-03): https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/10/retail-packaged/UseTerms_Retail_Windows_10_English.pdf
15. [S13] Microsoft Learn, Windows 365 service description (fetched 2026-09-03): https://learn.microsoft.com/office365/servicedescriptions/windows-365-service-description/windows-365-service-description
16. [S14] Microsoft Licensing, Windows 11 licensing for virtual desktops (fetched 2026-09-03): https://www.microsoft.com/licensing/guidance/Windows-11-Licensing-for-Virtual-Desktops
17. [S15] Microsoft Licensing, ISV Royalty program page (fetched 2026-09-03): https://www.microsoft.com/en-us/licensing/licensing-programs/isv-program
18. [S16] Microsoft Learn, What is Windows 365? (fetched 2026-09-03): https://learn.microsoft.com/windows-365/overview
19. [S17] Microsoft, Windows 365 Business all-pricing (fetched 2026-09-03): https://www.microsoft.com/en-us/windows-365/business/all-pricing
20. [S17b] Microsoft, Windows 365 Enterprise all-pricing (fetched 2026-09-03): https://www.microsoft.com/en-us/windows-365/enterprise/all-pricing
21. [S18] Microsoft Partner Center announcements, April 2026 (2026-04-08) and May 2026 (2026-05-07): https://learn.microsoft.com/partner-center/announcements/2026-april and https://learn.microsoft.com/partner-center/announcements/2026-may
22. [S19] Microsoft, Windows 365 Business compare plans (fetched 2026-09-03): https://www.microsoft.com/en-us/windows-365/business/compare-plans-pricing
23. [S20] Microsoft Learn Lifecycle, Windows 10 Home and Pro (fetched 2026-09-03): https://learn.microsoft.com/en-us/lifecycle/products/windows-10-home-and-pro
24. [S21] Microsoft Learn, ESU program for Windows 10 (fetched 2026-09-03): https://learn.microsoft.com/en-us/windows/whats-new/extended-security-updates
25. [S21b] Microsoft, Windows 10 Consumer ESU (fetched 2026-09-03): https://www.microsoft.com/en-us/windows/extended-security-updates
26. [S21c] Microsoft Q&A, Windows 10 ESU beyond October 2026 (2026-05-22): https://learn.microsoft.com/en-us/answers/questions/5899411/windows-10-esu-beyond-october-2026
27. [S22] Microsoft Support, Windows Arm-based PCs FAQ (fetched 2026-09-03): https://support.microsoft.com/en-us/windows/windows-arm-based-pcs-faq-477f51df-2e3b-f68f-31b0-06f5e4f8ebb5
28. [S24] Alludo press release via GlobeNewswire (2023-02-16) - unfetched: https://www.globenewswire.com/news-release/2023/02/16/2610139/0/en/Parallels-Desktop-Now-an-Authorized-Solution-to-Use-With-Windows-11-on-Mac-With-Apple-Silicon.html
29. [S25] MacRumors, "Not a Supported Scenario" (2021-09-14) - unfetched: https://www.macrumors.com/2021/09/14/arm-windows-m1-macs-not-supported/
30. [S26] Parallels Desktop buy page - unfetched: https://www.parallels.com/products/desktop/buy/
31. [S27] Parallels KB 129607, Windows 11 for Arm installation with OOBE - unfetched: https://kb.parallels.com/en/129607
32. [S28] Broadcom TechDocs, Fusion 13 Download and Install Windows 11 on Apple silicon - unfetched: https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/13-0/using-vmware-fusion/creating-virtual-machines/create-a-virtual-machine/download-and-install-windows-11.html
33. [S29] GitHub, TuringSoftware/CrystalFetch (fetched 2026-09-03): https://github.com/TuringSoftware/CrystalFetch
34. [S30] GitHub, jameskaois/windows-11-on-mac-apple-silicon (fetched 2026-09-03): https://github.com/jameskaois/windows-11-on-mac-apple-silicon
35. [S31] GitHub, utmapp/UTM (fetched 2026-09-03): https://github.com/utmapp/UTM
36. [S32] Microsoft Q&A, retail keys for VMs: https://learn.microsoft.com/answers/a/12819532 and https://learn.microsoft.com/answers/a/8176731
37. [S33] Microsoft Learn KB 4339074, reinstalling Microsoft Store not supported: https://learn.microsoft.com/troubleshoot/windows-client/shell-experience/cannot-remove-uninstall-or-reinstall-microsoft-store-app
38. [S34] Parallels KB 128520, Install Microsoft Store to Windows 11 on ARM - unfetched: https://kb.parallels.com/en/128520
39. [S35] Autodesk KB, Installation issues on Windows on ARM (WoA) (via Autodesk MCP, 2026-09-03): https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html
40. [S36] Autodesk, System requirements for AutoCAD 2025: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html
41. [S37] Autodesk, System requirements for AutoCAD 2027: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html
42. [S38] Autodesk KB, Error 10 on Parallels VM: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html
43. [S38b] Autodesk KB, Desktop Connector on Parallels ARM64: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Is-Desktop-Connector-working-on-Windows-running-on-iOS-using-Parallels-with-ARM64.html
44. [S38c] Autodesk KB, Fusion crashes on Windows on ARM: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Fusion-crashes-on-startup-in-Windows-on-ARM.html
45. [S39] Microsoft Q&A thread on Snapdragon and AutoCAD (claim unverified): https://learn.microsoft.com/en-us/answers/questions/5849358/dose-snapdragon-arm-processor-will-be-compatible-w
46. [S40] Newegg listing quoting OEM System Builder terms - unfetched: https://www.newegg.com/global/kw-en/microsoft-windows-11-pro/p/N82E16832350882
47. [S41] Microsoft, General trademark guidelines (fetched 2026-09-03): https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general
