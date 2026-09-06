# VMware Fusion Pro (Broadcom) — Competitor Research

_Research date: 2026-09-03_

> Method note. Broadcom/VMware web properties (blogs.vmware.com, techdocs.broadcom.com, knowledge.broadcom.com, community.broadcom.com, support.broadcom.com) and most press sites were unreachable from this research sandbox (egress proxy 403). Facts attributed to those pages below were confirmed from the page excerpts returned by web search for the exact URL cited, cross-checked against at least one second source where possible. Pages that were fetched in full are GitHub-hosted (open-vm-tools, Homebrew cask issues, Vagrant provider, DXVK, MoltenVK, UTM, VirtualBuddy) and the Autodesk and Microsoft official-documentation MCP indexes. Anything not confirmable is listed under Open questions.

## TL;DR (5 bullets)

- **Still alive and shipping.** Broadcom released VMware Fusion Pro **26H1** on **May 14, 2026** (build 25388279), after **25H2u1** (Feb 26, 2026) and **25H2** (Oct 14, 2025). Broadcom's official cadence is "two major releases per year, labeled by half-year versions (e.g., 25H2, 26H1, 26H2)" with the caveat that "development will continue based on available resources." [1][2][3][7][8]
- **Free for everyone, including commercial use, since Nov 11, 2024.** No license key; paid SKUs are no longer sold; support is community-only (no tickets). Download requires a Broadcom Support Portal account plus a Trade Compliance form, which is enough friction that Homebrew disabled its `vmware-fusion` cask in 2025. [4][5][6][20][21]
- **Apple Silicon: real, but constrained.** Runs only arm64 guests via Apple's hypervisor APIs; no x86 emulation, no macOS guests on Apple Silicon, no nested virtualization (so no WSL2/VBS), and no shared folders for Windows 11 ARM guests. Windows 11 ARM needs a vTPM, which forces VM encryption ("fast" or "full"). [11][12][13][15][16]
- **3D on Apple Silicon = DirectX 11 (Metal-backed) + OpenGL 4.3** for Windows 11 ARM guests since Fusion 13.5 (Oct 20, 2023). No DirectX 12, no Vulkan for Windows guests. Parallels tops out at DirectX 11 too, so neither can enable AutoCAD's DX12 "Fast" visual styles. [10][17][24]
- **AutoCAD is a poor fit inside Fusion on Apple Silicon.** Autodesk states AutoCAD/Autodesk products cannot be installed on Windows-on-ARM (ARM64 unsupported) and that AutoCAD "is not a supported product under Virtualization." Fusion lacks the Microsoft authorization Parallels holds for Windows 11 on Apple Silicon. Fusion's realistic role for MIRRORZ is a free, "good-enough" generic VM, not a CAD platform. [25][26][27][28][29]

## Current status (version, date, maintainer, momentum)

**Maintainer.** VMware by Broadcom (Broadcom closed the VMware acquisition in Nov 2023). Fusion is developed by Broadcom's "Desktop Hypervisor" team, which per the official FAQ "will closely monitor Broadcom Communities" as the sole support channel. [4][7]

**Release timeline (most recent first).**

| Release | Date | Build | Notable |
|---|---|---|---|
| Fusion Pro **26H1** | 2026-05-14 | 25388279 | VM creation / last-powered-on timestamps; remote connections to ARM-based ESX hosts (tech-preview scenario); help links to Broadcom TechDocs; security + bug fixes; new guests incl. Ubuntu 26.04 LTS, Fedora 43/44, SLE 16, openSUSE 16.0, FreeBSD 15.0. Host: macOS Sequoia 15.0+. [1][2][9] |
| Fusion Pro **25H2u1** | 2026-02-26 | 25219963 | Fixes CVE-2026-22715 (VMSA-2026-0002); re-enabled the in-app "Check for updates" option. [3] |
| Fusion Pro **25H2** | 2025-10-14 | — | Switch to calendar versioning; `dictTool` CLI for .vmx/preferences; USB 3.2; virtual hardware v22; new guest OSes; requires macOS 15 Sequoia or later host. [8][18] |
| Fusion 13.6.4 | 2025-07 | — | VMSA-2025-0013 (CVE-2025-41236/41237/41238/41239); NAT and ESXi-upload fixes. [19] |
| Fusion 13.6.3 | 2025-03 (VMSA-2025-0004 issued 2025-03-04) | 24585314 | Fixes CVE-2025-22226 (actively exploited zero-day family). [19][21] |
| Fusion 13.6 | 2024-09-03 | — | Adds `vmcli`; **removes Unity mode** and Default Applications; drops legacy Tools ISOs. [22] |
| Fusion 13.5 | 2023-10-20 | — | **DirectX 11 3D for Windows 11 ARM on Apple Silicon**; "Get Windows" one-click download of Windows 11 ARM. [10][17] |
| Fusion 13.0 | 2022-11-18 | — | First GA with Apple Silicon support; Windows 11 ARM guests with OpenGL 4.3 only. [23] |

**Momentum signals.**
- Positive: two releases in the first half of 2026 (25H2u1, 26H1); security advisories are being patched promptly (VMSA-2026-0002 in Feb 2026); open-vm-tools 13.1.0 shipped 12 May 2026 (build 25218885) with GTK4 support. [1][3][31][32]
- Negative: the 2025 removal of in-app updates (KB 395172; users had to download manually from the Broadcom portal until 25H2u1 restored the check), Homebrew dropping the cask, and Broadcom's own "based on available resources" wording. Broad VMware headcount cuts (roughly half of the ~38,000 pre-acquisition staff by 2026, per a recruiting-industry report) are context, not a direct signal about the Fusion team. [7][20][30][33]
- Apple Silicon-specific features that were "not yet" in 2022 are still "not yet" in 2026: shared folders for Windows 11 ARM, nested virtualization, macOS guests, x86 emulation. The Broadcom KB still says "Development of Fusion's features on Apple silicon is an ongoing project." [11][13][15][16]

## Pricing and licensing (table)

| Item | Current status (2026) | Earlier | Source |
|---|---|---|---|
| Fusion Pro license | **$0** for commercial, educational and personal use; no license key | Fusion Pro $199 (perpetual); Fusion Player commercial $149; Player free for personal use | [4][5][34] |
| Paid SKUs | Not available for purchase; existing contracts honored until term end | Fusion Player end-of-sale 2024-04-30; Pro free for personal use from 2024-05-14 | [4][5][35] |
| Support | Community (Broadcom Communities, KB, docs) only; "support ticketing ... will no longer be available"; no phone/chat for Basic users | Paid enterprise support with Pro subscription | [4][6][7] |
| Download | Requires free Broadcom Support Portal account; Trade Compliance / Download Conditions form (name, postal address) | Direct download from vmware.com | [6][20][21] |
| Updates | Manual download from Broadcom portal (KB 395172, 2025); in-app "Check for updates" re-enabled in 25H2u1 (Feb 2026) | In-app auto-update | [3][30] |
| Editions | Single edition, "Fusion Pro", universal binary for Intel and Apple Silicon | Player vs Pro | [1][35] |
| Host requirement | macOS 15 Sequoia or later (25H2 and 26H1) | 13.x supported older macOS | [8][9] |
| Comparison: Parallels Desktop | Standard $99.99/yr or $219.99 one-time; Pro $119.99/yr; Business $149.99/yr (third-party price trackers, 2026); Homebrew cask lists 27.0.1-58670 on 2026-09-03 | — | [36][37] |

Bottom line: Fusion's price is zero, and that is its single biggest competitive weapon. Any MIRRORZ price point must be justified by things Fusion cannot do (x86 apps, CAD-grade graphics, zero-friction setup, first-party support).

## How it works (architecture)

- **Hosted (type-2) hypervisor.** On Intel Macs Fusion historically loaded kernel extensions; on modern macOS and on Apple Silicon it runs on Apple's user-space hypervisor APIs (Hypervisor.framework) with no kexts, which is also why the host floor is now macOS 15. [9][14]
- **Apple Silicon guest model.** Only arm64/aarch64 guests: Windows 11 ARM, arm64 Linux, BSDs. "It is not possible to run x86 operating systems in VMware Fusion VMs on Apple Silicon Mac systems," and macOS guests are "supported on Apple hardware with Intel-based processors only." [11][16]
- **x86 application compatibility inside the guest is Microsoft's job, not VMware's.** Windows 11 ARM runs x86/x64 apps through Microsoft's Prism emulator (24H2+), which is "user mode code" only ("doesn't support drivers"). This is the same path Parallels relies on. [15][38]
- **Graphics.** A VMware SVGA virtual GPU exposed to the guest through a WDDM driver from VMware Tools. On Apple Silicon the 3D backend is Metal: 13.5 "added support for Metal-accelerated DirectX 11 3D graphics on Windows 11 VMs on Apple Silicon Macs." Intel hosts additionally get eGPU passthrough. OpenGL 4.3 in the guest. No DX12, no Vulkan for Windows guests. [10][17][23]
- **Security/TPM.** Windows 11's TPM 2.0 requirement is met by a vTPM, and Fusion requires the VM to be encrypted to host the vTPM. The Windows 11 install walkthrough offers "full encryption or a fast encryption"; fast encryption "only encrypts the parts of the VM necessary to support the TPM device." [12]
- **Integration (VMware Tools for Windows ARM).** Drag-and-drop, clipboard, display resize. Shared folders (vmhgfs) are **not** implemented for Windows 11 ARM guests on Apple Silicon (workarounds: SMB share, cloud sync, drag-and-drop). Unity (app-window integration) was removed in 13.6 for all hosts, so Fusion has no Coherence-style mode at all. [13][22]
- **Nested virtualization.** Not supported on Apple Silicon even though macOS 15 exposes it on M3+; consequently WSL2, VBS, Windows Sandbox, WDAG do not work in the guest. [15][39]
- **Automation surface.** `vmcli` (13.6), `dictTool` (25H2), `vmrest` REST API, `vmrun`; HashiCorp's `vagrant-vmware-desktop` provider (MPL-2.0) drives Fusion through a privileged `vagrant-vmware-utility` service. [8][22][40]
- **Guest agent is open source.** `open-vm-tools` (GPL v2 kernel modules, LGPL v2.1 user-space, X11 for SVGA/mouse drivers) covers shared folders, drag-and-drop/copy-paste, resolution, time sync, quiescing. The Windows Tools build and the hypervisor itself are proprietary. [31][32][41]

## Feature checklist (table: feature | status | notes)

| Feature | Status (Fusion Pro 26H1 on Apple Silicon, unless noted) | Notes / source |
|---|---|---|
| Native Apple Silicon host | Yes | Universal binary; since 13.0 (Nov 2022). [1][23] |
| Intel Mac host | Yes (macOS 15+) | Same download. [1][9] |
| Windows 11 ARM guest | Yes | "Get Windows" downloads ISO from Microsoft. [10][17] |
| Windows 10/11 x86 guest on Apple Silicon | **No** | No x86 emulation. Parallels 20.2+ has a slow x86 emulation preview. [11][42] |
| Windows x86/x64 apps inside ARM guest | Via Microsoft Prism | User-mode only; no x86 drivers. [38] |
| macOS guest on Apple Silicon | **No** | Intel hosts only. [16] |
| vTPM / Windows 11 requirements | Yes | Requires fast or full VM encryption. [12] |
| Secure Boot / UEFI | Yes | Standard for Windows 11 ARM VMs. [12] |
| 3D: DirectX | DX11 (Metal-backed) | Since 13.5 (Oct 2023). No DX12. [10][17] |
| 3D: OpenGL | 4.3 | Windows and Linux guests. [23] |
| 3D: Vulkan (Windows guest) | No | — |
| eGPU passthrough | Intel hosts only | [23] |
| Coherence-style app windows (Unity) | **Removed** (13.6, Sept 2024) | No equivalent on any host now. [22] |
| Shared folders (Win11 ARM) | **No** | KB: "not supported for Windows 11 ARM GOS on Apple Silicon hosts." [13] |
| Drag-and-drop / clipboard | Yes | Via VMware Tools for Windows ARM. [13] |
| Nested virtualization (WSL2, VBS, Sandbox) | **No** | [15][39] |
| Snapshots, linked clones, encryption | Yes | Pro feature set retained in free product. [4] |
| CLI / API | vmcli, dictTool, vmrest, vmrun | [8][22] |
| Remote ESXi / vSphere connect | Yes; ARM ESXi remote in 26H1 | [1][2] |
| Auto-update | Restored in 25H2u1 (Feb 2026) after 2025 removal | [3][30] |
| Microsoft authorization for Win11 on Apple Silicon | **No** (Parallels only) | [43] |
| Price | $0 all uses | [4] |
| Support | Community only | [6][7] |
| Download friction | Broadcom account + Trade Compliance form | [20][21] |

## CAD / AutoCAD relevance

1. **Autodesk's position on ARM.** Autodesk's KB "Installation issues for Autodesk products on Windows 64-bit running on ARM processors (WoA)" states: "You are unable to install any Autodesk program on an ARM based processor for a Windows Operating System... it is not compatible with Autodesk products, which are based on 64-bit (x64) software." The AutoCAD 2026 system requirements say ARM processors are not supported, and the AutoCAD 2027 requirements list only 64-bit Windows 11 on x64. A Fusion VM on Apple Silicon is, by definition, a Windows-on-ARM machine. [25][26][27]
2. **Autodesk's position on virtualization.** "AutoCAD is not a supported product under Virtualization" (KB on slow mouse performance in Citrix/VMware/Azure), plus the boilerplate that Autodesk "makes no representations, warranties or other promises related to use of any product in any virtualization environment." A separate Autodesk KB does list Parallels Desktop and VMware Fusion as virtualized environments for non-native products, but that is a compatibility listing, not a support commitment. [28][29]
3. **Graphics ceiling.** AutoCAD 2027 requires a DirectX 11-compliant GPU at minimum and "DirectX 12 with Feature Level 12_0 ... for 'Fast' visual styles." Fusion (DX11) and Parallels (DX11) both fail the DX12 bar, so in either VM AutoCAD runs with reduced visual styles. [24][27]
4. **Practical experience.** Parallels' AutoCAD landing page asserts Fusion on Apple Silicon has "no DirectX acceleration, no OpenGL hardware acceleration, software-rendered 3D" for Windows guests. That claim contradicts VMware's own 13.5 release notes (DX11 for Windows 11 ARM) and should be treated as competitor marketing; the real differentiators are Microsoft's authorization, Parallels' Coherence/shared-folder integration, and Parallels' explicit Autodesk tuning. [17][43][44]
5. **AutoCAD for Mac** has run natively on Apple Silicon since the 2024 release, which is the option Autodesk actually points Mac users to. MIRRORZ's opportunity is the Windows-only toolsets (Architecture, MEP, Plant 3D, Electrical, Map 3D, Raster Design) and third-party .NET/ObjectARX plug-ins that never shipped for Mac. [27][45]

Implication for MIRRORZ: Fusion is not a credible AutoCAD path today. Any user who gets AutoCAD running inside Fusion on an M-series Mac has done so against Autodesk's stated support policy, with Prism-emulated x64 binaries, DX11-only graphics, no shared folders, and no vendor support on either side.

## Strengths (what to match)

- **Zero price, full Pro feature set, commercial use allowed.** Snapshots, clones, encryption, vTPM, REST API, CLI tooling, all free. [4]
- **Trusted brand and enterprise-grade VM format.** .vmx/.vmdk interoperability with Workstation and ESXi; OVF import/export; vSphere remote management; large existing install base and Vagrant ecosystem. [1][40]
- **Windows 11 ARM onboarding is genuinely easy** since 13.5: "Get Windows" pulls the ISO, encryption/vTPM are handled in the wizard. [10][12]
- **Metal-backed DirectX 11 and OpenGL 4.3** for Windows guests on Apple Silicon: good enough for most 2D/3D productivity apps and many games. [17]
- **Security responsiveness**: VMSA patches appear in Fusion within days of disclosure (e.g., CVE-2025-22226 in March 2025; CVE-2026-22715 in Feb 2026). [3][19]
- **Open guest agent**: open-vm-tools is LGPL/GPL and actively maintained (13.1.0, May 2026). [31][32]

## Weaknesses (what MIRRORZ must beat)

- **No x86 guests on Apple Silicon**, and therefore total dependence on Windows-on-ARM plus Microsoft's Prism for legacy apps; no path for apps that need x86 kernel drivers. [11][38]
- **No app-window integration** (Unity removed), **no shared folders** for Windows 11 ARM, **no nested virtualization**. Parallels' Coherence, shared folders, and "Optimized for Games/Design" profiles are direct wins. [13][15][22]
- **Graphics stuck at DX11/OpenGL 4.3**, no DX12/Vulkan, no eGPU on Apple Silicon. [17][24]
- **Download and update friction**: Broadcom account, trade-compliance form, in-app updates removed for most of 2025, Homebrew cask disabled. First-run experience is the worst in the category. [20][21][30]
- **No support**: community forum only; no SLA, no phone/chat, no ticketing. [6][7]
- **Not Microsoft-authorized** for Windows 11 on Apple Silicon (Parallels is), which matters to IT departments and to anyone reading Microsoft's own guidance page. [43]
- **Not an AutoCAD-supported configuration** on two counts (ARM host, virtualization). [25][28]
- **Roadmap opacity**: no public roadmap, and Broadcom's own FAQ hedges with "based on available resources." Apple Silicon gaps have persisted for four years. [7][13]

## Reusable code, ideas, and license implications for MIRRORZ

- **open-vm-tools (github.com/vmware/open-vm-tools).** Kernel modules GPL v2; most user-space LGPL v2.1; SVGA and mouse drivers X11 license; some BSD/MIT third-party pieces. The Linux guest-agent code (hgfs shared folders, DnD/copy-paste plugins, resolution, time sync) is reusable in a Linux guest under LGPL terms (dynamic linking, ship source of modified LGPL components). The X11-licensed SVGA driver is the most permissive piece and a useful reference for a paravirtual display path. There is no open Windows-on-ARM Tools; MIRRORZ cannot borrow Fusion's Windows integration. [31][32][41]
- **Vagrant VMware Desktop provider (MPL-2.0).** A worked example of splitting privileged host operations into a separate utility service (networking, verification) from an unprivileged plugin, which is exactly the shape a notarized, sandboxed Mac app will need. MPL is file-level copyleft; fine to study, fine to link if modified files stay MPL. [40]
- **Graphics translation stack (reference, not Fusion code).** The open Direct3D-on-Metal route is D3D8/9/10/11 to Vulkan via **DXVK** (zlib license) and Vulkan to Metal via **MoltenVK** (Apache 2.0, Vulkan 1.4 on Apple Silicon). Both licenses are permissive and compatible with a proprietary MIRRORZ binary with attribution. This is how MIRRORZ can exceed Fusion's DX11 ceiling in a translation-layer design (Wine/CrossOver-style) rather than a VM design. [46][47]
- **Apple Virtualization.framework front-ends.** UTM (Apache 2.0, with (L)GPL QEMU components) and VirtualBuddy (BSD-2-Clause) show how far a small team gets with Apple's own frameworks; UTM already exposes nested virtualization, which Fusion does not. Note UTM statically links some (L)GPL parts, so any reuse must be audited component by component. [48][49]
- **Product ideas worth copying from Fusion:** "Get Windows" one-click ISO acquisition; fast (partial) VM encryption to satisfy vTPM cheaply; year-half versioning for predictability; a REST API and CLI from day one.
- **License implications summary:** never link GPL v2 kernel-module code into a proprietary macOS binary; LGPL components only via dynamic linking with source-offer; prefer X11/zlib/Apache/BSD/MPL pieces for anything compiled into the shipping app; keep an SBOM from the first commit.

## Open questions

1. Exact release date of Fusion 13.6.3 (the VMSA was 2025-03-04; the TechDocs page carries a later update stamp). [19]
2. Whether 26H1 changed anything about 3D on Apple Silicon (release-notes summaries mention only security/bug fixes and timestamps; the full notes were not fetchable). [1][2]
3. Whether Broadcom intends to add nested virtualization on M3+ hosts now that macOS 15 exposes it; no statement found. [15][39]
4. Whether Fusion's "remote connections to ARM-based ESX hosts" signals a broader ARM investment that could reach the desktop product (e.g., x86 emulation), or is purely a management feature. [1][2]
5. open-vm-tools 13.1.0 date discrepancy: the ReleaseNotes.md in the repo says 12 May 2026 (build 25218885), while the auto-summarized releases page listed May 2025; the repo file is treated as authoritative here. [31][32]
6. Parallels' 2026 list prices could only be confirmed via third-party price trackers because parallels.com was unreachable. [36]
7. Any first-party benchmark of Fusion vs Parallels on M4/M5 hardware; the only numbers found (31-42% CPU advantage, 5 s vs 8.4 s boot) are from Parallels' own comparison page. [44]

## Sources (numbered list of URLs with dates)

1. Broadcom/VMware blog, "VMware Workstation and Fusion 26H1: Performance, Visibility, and Modern Architecture," 2026-05-14. https://blogs.vmware.com/cloud-foundation/2026/05/14/announcing-vmware-workstation-and-fusion-26h1/
2. Broadcom TechDocs, "VMware Fusion 26H1 Release Notes," 2026-05 (build 25388279). https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/26H1/release-notes/vmware-fusion-26h1-release-notes.html
3. Broadcom TechDocs, "VMware Fusion 25H2u1 Release Notes," 2026-02-26 (build 25219963). https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/25H2/release-notes/vmware-fusion-25h2u1-release-notes.html
4. Broadcom/VMware blog, "VMware Fusion and Workstation are Now Free for All Users," 2024-11-11. https://blogs.vmware.com/cloud-foundation/2024/11/11/vmware-fusion-and-workstation-are-now-free-for-all-users/
5. Broadcom KB 368667, "Download and license VMware Desktop Hypervisor (Fusion Pro and Workstation Pro)," 2024-11 (updated 2025). https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html
6. Broadcom/VMware blog, "VMware Fusion & Workstation Going Free: Customer Feedback and New Resources," 2025-03-10. https://blogs.vmware.com/cloud-foundation/2025/03/10/vmware-fusion-workstation-going-free-new-resources/
7. VMware, "VMware Fusion & Workstation (Desktop Hypervisor) Frequently Asked Questions" (PDF), 2025. https://www.vmware.com/docs/desktop-hypervisor-faqs
8. Broadcom/VMware blog, "VMware Workstation & Fusion 25H2: Embracing Calendar Versioning and New Features," 2025-10-14. https://blogs.vmware.com/cloud-foundation/2025/10/14/vmware-workstation-fusion-25h2-embracing-calendar-versioning-and-new-features/
9. Broadcom TechDocs, "System Requirements for Fusion Pro" (25H2/26H1), 2025-2026. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/26H1/using-vmware-fusion/getting-started-with-vmware-fusion/system-requirements-for-vmware-fusion.html
10. VMware, "VMware Fusion 13.5 Release Notes," 2023-10-20. https://docs.vmware.com/en/VMware-Fusion/13.5/rn/vmware-fusion-135-release-notes/index.html
11. Broadcom KB 315602, "Compatibility considerations for Arm guest operating systems in Fusion VMs on Apple silicon," updated 2025-2026. https://knowledge.broadcom.com/external/article/315602
12. Broadcom TechDocs, "Download and Install Windows 11 as Guest Operating System on Apple Silicon Mac" (25H2), 2025. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/25H2/using-vmware-fusion/creating-virtual-machines/create-a-virtual-machine/download-and-install-windows-11.html
13. Broadcom TechDocs, "Guest Operating Systems That Support Shared Folders" (25H2), 2026-02. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/25H2/using-vmware-fusion/sharing-files-between-windows-and-your-mac/guest-operating-systems-that-support-shared-folders.html
14. Apple Developer Documentation, "Hypervisor" framework (undated, current). https://developer.apple.com/documentation/hypervisor
15. Broadcom Community, "Nested virtualization with VMware Fusion in Sequoia?" 2024-11. https://community.broadcom.com/vmware-cloud-foundation/question/nested-virtualization-with-vmware-fusion-in-sequoia
16. Broadcom TechDocs, "Creating a macOS Virtual Machine in Fusion Pro" (26H1), 2026. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/26H1/using-vmware-fusion/creating-virtual-machines/create-a-virtual-machine/creating-a-mac-os-x-virtual-machine-in-vmware-fusion.html
17. AAPL Ch. (applech2.com), "VMware Fusion v13.5 released with DirectX 11 3D on Apple Silicon and Get Windows," 2023-10-20. https://applech2.com/archives/20231020-vmware-fusion-v13-5-for-now-available.html
18. Daily CyberSecurity (securityonline.info), "Broadcom Shifts VMware Workstation/Fusion to Year-Based Versioning with New 25H2 Release," 2025-10. https://securityonline.info/broadcom-shifts-vmware-workstation-fusion-to-year-based-versioning-with-new-25h2-release/
19. Broadcom TechDocs, "VMware Fusion 13.6.3 / 13.6.4 Release Notes," 2025-03 and 2025-07. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/13-0/release-notes/vmware-fusion-1364-release-notes.html
20. GitHub, Homebrew/homebrew-cask issue #210104, "vmware-fusion package download now behind login and Trade Compliance form," 2025-04-25 (fetched in full). https://github.com/Homebrew/homebrew-cask/issues/210104
21. GitHub, Homebrew/homebrew-cask issue #206132, "vmware-fusion fails to download" (13.6.3 build 24585314), 2025-03-24 (fetched in full). https://github.com/Homebrew/homebrew-cask/issues/206132
22. Broadcom TechDocs, "VMware Fusion 13.6 Release Notes," 2024-09-03. https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/13-0/release-notes/vmware-fusion-136-release-notes.html
23. AppleInsider, "VMware Fusion 13 adds Windows 11 virtualization for Apple Silicon Macs," 2022-11-18. https://appleinsider.com/articles/22/11/18/vmware-fusion-13-adds-windows-11-virtualization-for-apple-silicon-macs
24. Parallels KB 124137, "DirectX 11 support in Parallels Desktop for Mac," and Parallels Forums "DirectX 12 - any update," 2025-2026. https://kb.parallels.com/en/124137
25. Autodesk KB, "Installation issues for Autodesk products on Windows 64-bit running on ARM processors (WoA)," current (via Autodesk Product Help index). https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html
26. Autodesk, "System requirements for AutoCAD 2026 including Specialized Toolsets," 2025. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2026-including-Specialized-Toolsets.html
27. Autodesk, "System requirements for AutoCAD 2027 including Specialized Toolsets," 2026 (via Autodesk Product Help index). https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html
28. Autodesk KB, "Slow mouse performance in AutoCAD products when working in a virtual environment," current. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-on-Citrix-slow-mouse-performance.html
29. Autodesk KB, "Which products are Mac-compatible?" current. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Which-products-are-Mac-compatible.html
30. Broadcom KB 395172, "Important Update: Change in Product Update Process for VMware Workstation and VMware Fusion," 2025. https://knowledge.broadcom.com/external/article?articleNumber=395172
31. GitHub, vmware/open-vm-tools ReleaseNotes.md, 13.1.0 dated 2026-05-12, build 25218885 (fetched in full). https://github.com/vmware/open-vm-tools/blob/master/ReleaseNotes.md
32. GitHub, vmware/open-vm-tools README and LICENSE (fetched in full). https://github.com/vmware/open-vm-tools
33. KORE1, "VMware Broadcom Layoffs 2026," 2026. https://www.kore1.com/vmware-broadcom-layoffs-2026/
34. Macworld, "VMware Fusion Review: Now free for personal use" (lists Pro $199 / Player commercial $149), 2024. https://www.macworld.com/article/668080/vmware-fusion-review.html
35. Born's Tech and Windows World, "VMware Player/Fusion Player is End of Sale," 2024-05-12. https://borncity.com/win/2024/05/12/vmware-player-fusion-player-is-end-of-sale-vmware-security-advisories-now-at-broadcom/
36. Vendr, "Parallels Software Pricing & Plans 2026," 2026. https://www.vendr.com/marketplace/parallels
37. GitHub raw, Homebrew cask `parallels.rb` (version 27.0.1-58670), fetched 2026-09-03. https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/p/parallels.rb
38. Microsoft Learn, "How emulation works on Arm" (Prism), current. https://learn.microsoft.com/windows/arm/apps-on-arm-x86-emulation
39. Parallels Forums, "macOS 15 Sequoia: nested virtualization for M3+ Macs," 2024. https://forum.parallels.com/threads/macos-15-sequoia-nested-virtualization-for-m3-macs.364397/
40. GitHub, hashicorp/vagrant-vmware-desktop (MPL-2.0) (fetched in full). https://github.com/hashicorp/vagrant-vmware-desktop
41. GitHub, vmware/open-vm-tools LICENSE (fetched in full). https://github.com/vmware/open-vm-tools/blob/master/open-vm-tools/LICENSE
42. The Register, "Parallels x86 VMs on Apple Silicon," 2025-01-16. https://www.theregister.com/2025/01/16/parallels_x86_vms_on_apple_silicon/
43. Parallels, "Run Windows 11 on Apple silicon with a Microsoft-Authorized Solution," current; AppleInsider, "Microsoft, Parallels partnership brings Windows 11 to Apple Silicon Macs," 2023-02-16. https://www.parallels.com/products/desktop/microsoft-authorized-solution-windows-11-arm/
44. Parallels, "Parallels Desktop vs VMware Fusion (2026)" and "Run AutoCAD on Mac: Parallels Desktop vs. UTM vs. VMware Fusion," 2026 (competitor marketing). https://www.parallels.com/compare/vmware/fusion/ and https://www.parallels.com/apps/autocad/
45. Autodesk Help, AutoCAD for Mac "Apple Silicon Support" (2024+ native), current. https://help.autodesk.com/view/ACDMAC/2027/ENU/?guid=GUID-EA31738F-CDDE-4170-970A-745BC19C7674
46. GitHub, doitsujin/dxvk (zlib) (fetched in full). https://github.com/doitsujin/dxvk
47. GitHub, KhronosGroup/MoltenVK (Apache 2.0, Vulkan 1.4 on Metal) (fetched in full). https://github.com/KhronosGroup/MoltenVK
48. GitHub, utmapp/UTM (Apache 2.0) (fetched in full). https://github.com/utmapp/UTM
49. GitHub, insidegui/VirtualBuddy (BSD-2-Clause) (fetched in full). https://github.com/insidegui/VirtualBuddy
50. The Register, "VMware quietly debuts Arm hypervisor tech preview," 2026-05-19. https://www.theregister.com/virtualization/2026/05/19/vmware-quietly-debuts-arm-hypervisor-tech-preview/5242293
