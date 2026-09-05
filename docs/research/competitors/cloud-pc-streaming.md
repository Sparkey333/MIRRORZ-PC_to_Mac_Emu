# Cloud PC and Streaming Alternatives (Windows 365, Azure Virtual Desktop, Windows App, Shadow, Paperspace, hosted-Mac) — Competitor Profile

_Research date: 2026-09-03_

> Sourcing note: this session's web-search budget was exhausted before the topic started, and the network egress policy blocked direct fetches of `shadow.tech`, `help.shadow.tech`, `paperspace.com`, `docs.digitalocean.com`, `macincloud.com`, `macstadium.com`, `scaleway.com`, `aws.amazon.com`, `parsec.app`, `azure.microsoft.com` (direct), `learn.microsoft.com` (direct), `autodesk.com` (direct), `prices.azure.com`, `api.github.com`, the Wayback Machine, Wikipedia, the Apple App Store and every tech-press/review domain tried (PCMag, TechRadar, Tom's Guide, CNET, The Verge, Notebookcheck, Reddit). Microsoft pages were obtained from `www.microsoft.com` (direct fetch) and from Microsoft Learn via the Microsoft Learn MCP server (marked **[MS Learn]**); Autodesk pages via the Autodesk Product Help MCP server (marked **[ADSK KB]**); GitHub pages by direct fetch. **Every price, version and date below carries a numbered source; nothing is stated from memory. Where a fact could not be verified it is listed as a gap, not guessed.** Microsoft's own pricing pages carry no visible publication date, so "fetched 2026-09-04" is the only date available for them.

## TL;DR

- **Windows 365 is the only cloud PC in this set whose 2026 prices, GPU tiers and Mac client could be verified end-to-end.** Enterprise per-user/month: $28–$765 for CPU-only sizes (2 vCPU/4 GB/64 GB up to 32 vCPU/128 GB/2 TB) and **$310 (GPU Select), $537 (GPU Standard), $1,029 (GPU Super), $1,914 (GPU Max)**; Business (≤300 users) $36/$56/$108.80 with no GPU; Flex (ex-Frontline) $42/$99/$185 and $806 for GPU Standard per pooled licence. [1][2][3][4]
- **GPU tiers are AutoCAD-capable on paper.** GPU Standard = 4 vCPU/16 GB/8 GB vRAM, Super = 8 vCPU/56 GB/12 GB, Max = 16 vCPU/110 GB/16 GB (NVIDIA; AMD in limited regions); Microsoft lists "Autodesk, Revit" for these SKUs and validated **AutoCAD 2027 on an Azure NVads V710 v5 VM (24 vCPU/128 GiB, AMD Radeon PRO V710)**. AutoCAD 2027 recommends an 8 GB DirectX 12 GPU. [7][8][9][30][31]
- **Autodesk licensing permits cloud VMs, with caveats:** "Only Autodesk software available via subscription with single-user access is permitted for virtualization… Currently, all products can be virtualized"; a single-user subscription installs on up to three computers, one in use at a time; but Autodesk "doesn't provide technical support for your virtual environment" and says "Hardware acceleration for AutoCAD is not a supported feature over a remote desktop session." [32][33][34][35][40]
- **Windows App has replaced the Remote Desktop clients.** Current: macOS 11.3.9 (3064) 2026-08-11, iOS 11.3.4 2026-08-11, Android 11.0.0.120 2026-08-13, Windows 2.0.1315.0 2026-08-11, web 2026.0.7214.1 2026-08-18. The Store Remote Desktop app lost support 2025-05-27, the Windows MSI client 2026-03-27. On macOS: multi-monitor and Teams optimisation, **no USB/serial or multimedia redirection**, macOS 14+, work/school account only. [19][20][22][23]
- **A hybrid local+cloud product is legally and technically tractable:** AVD per-user access pricing exists so "a software vendor… [can] sell remote access of [its] app to… external users"; RDP "can accommodate latencies of up to 200 ms"; Microsoft itself blends local and cloud (Boot/Switch, Cloud Apps and Reserve GA Nov 2025, Link GA 2025-04-02). Shadow, Paperspace, MacinCloud and Parsec pricing could not be verified this session. [6][10][16][26]

## Current status (version, date, maintainer, momentum)

**Windows 365 (Microsoft).** SaaS Cloud PCs billed per user per month in Business, Enterprise, Government, Flex (formerly Frontline) and Reserve editions, plus "Windows 365 for Agents (preview)" billed pay-as-you-go; "Windows 365 isn't currently available for individuals." [11][12] Weekly feature drops: week of 2026-06-01 added the **GPU Select** SKU, GPU support for Flex shared mode, a 32 vCPU size and context-based redirection (preview); week of 2026-05-11 began GA of **RDP Multipath with redundant TCP paths**; week of 2025-11-17 took **Cloud Apps**, **Reserve**, external identities and User Experience Sync to GA. [10] The Windows 365 Link thin client went GA 2025-04-02 in 20 countries, quote-priced. [6]

**Azure Virtual Desktop (Microsoft).** Customer-managed VDI on Azure; "Azure Virtual Desktop Hybrid is now generally available". Per-user access pricing for external users has two tiers (Apps; Desktops + apps) whose dollar values did not render in the fetched page; AVD VMs are "charged at Linux compute rates". [25][26] GPU families: NVadsA10 v5 (NVIDIA A10, 1/6 to 2 GPUs, GRID licence included) and NVads V710 v5 (AMD); **NVv3 and NVv4 retire 2026-09-30**. [28][29]

**Microsoft Windows App.** Unified client for Windows 365, AVD, Dev Box, RDS and remote PCs on Windows, macOS, iOS/iPadOS, Android/Chrome OS, web and Meta Quest (preview). macOS 11.3.5 (2026-04-13) adopted Liquid Glass and raised the floor to macOS 14; 11.3.7 (2026-06-29) added Personalization and a detachable Quick Launcher; Android 11.0.0.119 (2026-07-27) put hardware rendering in preview; web multi-monitor entered preview 2026-06-01. [20][21]

**Shadow PC, Paperspace, MacinCloud, MacStadium, Scaleway, Amazon WorkSpaces, Parsec.** All sources blocked; no version, price or status can be asserted. The Paperspace GitHub `cli` repo was updated 2026-02-07, so the line is still maintained [47]; Autodesk's KB has a live AutoCAD-on-Amazon-WorkSpaces article. [38]

**Open-source streaming stacks.** FreeRDP (Apache-2.0, ~13.6k stars): tags page lists 3.31.1 on 2026-09-02 (one extraction rendered the year as 2024; check manually). Sunshine (GPL-3.0, ~40.8k stars): v2026.516.143833 on 2026-05-16 with signed macOS DMGs and VideoToolbox encoding. Moonlight-qt (GPL-3.0): v6.1.0 on 2024-09-17 with macOS hardware decoding, HDR and experimental YUV 4:4:4 "for improved text clarity during remote desktop usage". [44][45][46]

## Pricing and licensing (table)

| Offer | Configuration | 2026 list price (USD, per user or licence / month) | Prerequisites and notes | Source |
|---|---|---|---|---|
| Windows 365 Business | 2 vCPU/8 GB/128 GB | $36.00 | ≤300 users; 30-day trial (card required); no GPU SKU on page | [1] |
| Windows 365 Business | 4 vCPU/16 GB/128 GB | $56.00 | | [1] |
| Windows 365 Business | 8 vCPU/32 GB/256 GB | $108.80 | "Design and engineering workstations" | [1] |
| Windows 365 Enterprise | 2 vCPU/4 GB/64–256 GB | $28 / $31 / $40 | Needs Windows E3/E5 (or M365 E3/E5/F3/Business Premium), Intune, Entra ID P1 | [3][12] |
| Windows 365 Enterprise | 2 vCPU/8 GB/128–256 GB | $41 / $50 | | [2][3] |
| Windows 365 Enterprise | 4 vCPU/16 GB/128–512 GB | $66 / $75 / $101 | | [2][3] |
| Windows 365 Enterprise | 8 vCPU/32 GB/128–512 GB | $123 / $132 / $158 | | [2][3] |
| Windows 365 Enterprise | 16 vCPU/64 GB/512 GB–1 TB | $277 / $315 | | [3] |
| Windows 365 Enterprise | 32 vCPU/128 GB/1–2 TB | $665 / $765 | New week of 2026-06-01 | [3][10] |
| Windows 365 Enterprise **GPU Select** | 6 vCPU/26 GB/4 GB vRAM/256 GB | **$310** | One 1920×1080 @ 30 fps display | [3][7] |
| Windows 365 Enterprise **GPU Standard** | 4 vCPU/16 GB/8 GB vRAM/512 GB (+176 GB temp) | **$537** | One 4K or two 1080p displays | [2][3][7] |
| Windows 365 Enterprise **GPU Super** | 8 vCPU/56 GB/12 GB vRAM/1 TB (+352 GB temp) | **$1,029** | Up to four 4K displays | [3][7] |
| Windows 365 Enterprise **GPU Max** | 16 vCPU/110 GB/16 GB vRAM min (performance page: "up to 24-GB vRAM")/1 TB | **$1,914** | "strict latency requirements"; the two Learn pages disagree on vRAM (minimum vs. up to) | [3][7][8] |
| Windows 365 Flex (ex-Frontline) | 2/4/64; 4/16/128; 8/32/128; GPU Standard | $42 / $99 / $185 / **$806** per licence | Dedicated mode: up to 3 Cloud PCs per licence, one active; Shared mode: pooled | [4][5][13] |
| Windows 365 Link device | Thin client | Quote only | GA 2025-04-02, 20 countries | [6] |
| Azure Virtual Desktop (internal users) | BYO licence | $0 access fee + Azure VM/storage/network | Eligible: M365 E3/E5/A3/A5/F3/Business Premium, Windows E3/E5, VDA | [25][26] |
| Azure Virtual Desktop (external users) | Per-user access pricing | Two flat tiers (Apps; Desktops + apps) — **dollar values not rendered; gap** | External commercial purposes only; billed only for users who connect in the month | [25][26][27] |
| Azure NVadsA10 v5 VMs | NV6ads 6 vCPU/55 GiB/1/6 A10 (4 GB) … NV36ads 36 vCPU/440 GiB/full A10 (24 GB) … NV72ads 2×A10 | **Hourly rates not obtainable (prices.azure.com blocked); gap** | GRID licence included; no nested virtualisation | [28] |
| Shadow PC / Paperspace / MacinCloud / MacStadium / Parsec / Amazon WorkSpaces | — | **Not verifiable this session** | See Open questions | — |
| Autodesk AutoCAD (single-user subscription) | Named user | Autodesk price not in scope | Installable on up to 3 computers, one in use at a time; virtualisation permitted for single-user subscriptions | [33][40] |

## How it works (architecture)

**Windows 365.** Cloud PCs run on Hyper-V; GPU SKUs get a persistent C: drive plus a large ephemeral D: scratch disk, ship with the vendor driver pre-installed ("external drivers… isn't supported"), and cannot run nested virtualisation (no WSL, Sandbox, Hyper-V). Capacity is dynamic, so a Cloud PC "might… exceed [its] license specified minimum specifications"; Microsoft says to use AVD "if you want to guarantee that all your users have the exact same GPU configuration". [7][8] Transport is RDP: a TCP reverse-connect session via a gateway on 443, then an upgrade to UDP through **RDP Shortpath** (STUN on 3478, else TURN relay), with **RDP Multipath** evaluating several UDP paths via ICE and now redundant TCP. Microsoft states RDP "can now accommodate latencies of up to 200 ms" and advises placing Cloud PCs near application data. [16][18] Bandwidth ranges from 0.3 Kbps idle to ~9.5 Mbps for video (lower in H.264/AVC 444 mode); UDP, full-screen and Windows App are recommended for GPU Cloud PCs. [7][17]

**Azure Virtual Desktop.** Customer-managed host pools of single- or multi-session Windows VMs; per-user access pricing is enrolled per subscription and "can only be used for external commercial purposes". Microsoft's AutoCAD 2027 reference architecture uses a `Standard_NV24ads_V710_v5` VM on Windows Server 2022 Datacenter: Azure Edition and leaves the remote-access protocol to the deployer. [26][27][30]

**Windows App (client).** Proprietary, versioned separately from its embedded RDP engine (Windows 2.0.1315.0 bundles engine 1.2.7342.0); sign-in needs a work/school account, but remote-PC connections on macOS work without signing in. [20][21][23]

**Open-source analogues.** Sunshine encodes with NVENC/QuickSync/AMF/VideoToolbox/VAAPI/Vulkan Video for Moonlight clients; FreeRDP implements RDP including H.264 and GFX surfaces. [44][45][46]

## Feature checklist (table: feature | status | notes)

| Feature | Status (2026-09) | Notes / source |
|---|---|---|
| GPU-accelerated Windows desktop from a Mac | Yes | Windows 365 GPU SKUs $310–$1,914/user/mo (Enterprise/Flex only); AVD NV VMs [3][4][7] |
| DirectX 12 for AutoCAD "Fast" visual styles | Plausible; not stated | AutoCAD 2027 needs DX12 FL 12_0 [31]; Microsoft does not publish the feature level of vGPU partitions (gap) |
| Autodesk licence compliance on a cloud VM | Permitted for single-user subscriptions | [32][33] |
| Autodesk technical support inside the cloud VM | Limited | Physical-machine repro may be required [34]; Autodesk does "not… support any virtual environments themselves" [39] |
| Hardware acceleration in AutoCAD over RDP | Autodesk: unsupported | Undated KB [35]; conflicts in practice with GPU Cloud PCs |
| macOS client: multiple monitors | Yes | Multi-monitor, dynamic resolution, smart sizing; no "selected monitors" [22] |
| macOS client: USB / serial redirection | No | Windows-only [22] |
| macOS client: multimedia redirection | No | Windows-only; Teams WebRTC/SlimCore available [22] |
| macOS minimum | macOS 14 (Windows 365 path) | Prerequisites page still lists macOS 12 for AVD/RDS/remote PC [20][23] |
| Personal Microsoft account sign-in | No | Work/school only [21] |
| Individual purchase of Windows 365 | No | "isn't currently available for individuals" [11] |
| Per-app streaming into the local desktop | Yes | Cloud Apps GA (Nov 2025), needs Flex licences in Shared mode [10][15] |
| Short-term / burst Cloud PC | Yes | Windows 365 Reserve GA (Nov 2025) [10] |
| Vendor-stated latency tolerance | Up to 200 ms RTT | [16]; Autodesk advises running AutoCAD locally when remote sessions lag [37] |
| Vendor-validated AutoCAD on cloud GPU | Yes | AutoCAD 2027 on NVads V710 v5; results "aren't a sizing recommendation" [30] |
| Reselling remote access to your own customers | Yes | AVD per-user access pricing; Windows Server hosts excluded [26] |
| Shadow / Paperspace / hosted-Mac pricing | Unverified | All sources blocked |

## CAD / AutoCAD relevance

AutoCAD 2027 (Windows) wants an 8-logical-core CPU, 16–32 GB RAM, a **2 GB DX11 GPU minimum and an 8 GB, 106 GB/s DX12 GPU recommended**, with DX12 feature level 12_0 required for the "Fast" visual styles and 12 GB VRAM for large datasets/point clouds; .NET 10. [31] Against that, Windows 365 GPU Standard (8 GB vRAM), Super (12 GB) and Max (16 GB min) meet the recommended VRAM line, and Microsoft's sizing page lists "Autodesk, Revit" among the apps for those SKUs. [7][9] Microsoft's own validation ran AutoCAD 2027's benchmark suite (eleven 2D/3D scenarios, five iterations each) on `Standard_NV24ads_V710_v5` with consistent run-to-run timings, but it explicitly notes the results are not a comparison with physical workstations. [30]

Autodesk's posture matters more than Microsoft's. Positive: virtualisation is allowed for single-user subscriptions and "Currently, all products can be virtualized" [33]; the Network License Manager may also be hosted in the cloud with a fixed MAC address [43]; a Revit-on-Azure article states "Autodesk supports Revit in virtual environments when licensing requirements and documented system requirements are met." [42] Negative: the same article and the Inventor policy say Autodesk "does not provide support for the configuration or operation of third-party virtualization platforms" and may ask for reproduction on physical hardware [34][42]; the AutoCAD KB says hardware acceleration "is not a supported feature over a remote desktop session" [35]; and Autodesk's remote-work guidance is blunt — "Install and run AutoCAD on the local system… If AutoCAD must be used over a remote connection… Most important: Improve the internet connection speed", with CURSORTYPE=1 and hardware acceleration off as mitigations. [37] Autodesk's own virtual-installation tuning guide adds: disable ToolTips, Dynamic Input and Selection Preview, prefer the H.264 codec ("Latency seems to be the less under H.264 codec") and use the Windows cursor. [36] Autodesk's own cloud answer, AutoCAD Web, is included with AutoCAD/LT subscriptions but "provides access to AutoCAD's core commands" only. [41]

## Strengths (what to match)

- **Real x64 CPUs and real NVIDIA/AMD GPUs.** Cloud PCs sidestep both Apple-silicon x86 emulation and the Metal-translation layer that local virtualisers must use; AutoCAD's DX12 path and vendor drivers are native. [7][30][31]
- **Per-user, all-in monthly pricing with no hardware refresh** and the ability to resize a Cloud PC remotely when a user outgrows it. [3][11]
- **A mature, free, multi-platform client** (Windows App) with multi-monitor and dynamic-resolution support on macOS and a browser fallback that only needs AVC and WebGL. [20][22][23]
- **Transport engineering**: UDP Shortpath, TURN relays, Multipath fail-over and a published bandwidth model give a predictable, tunable experience up to ~200 ms RTT. [16][17][18]
- **Licensing paths for vendors**: AVD per-user access pricing is designed for "a software vendor… [selling] remote access of [its] productivity app to… customers". [26]
- **Hybrid primitives already exist**: Cloud Apps (single app streamed into the local desktop), Reserve (short-term Cloud PC), Boot/Switch, Link. [6][10][15]

## Weaknesses (what MIRRORZ must beat)

- **Cost**: the cheapest AutoCAD-grade Cloud PC is $310/user/month (GPU Select, 4 GB vRAM, single 1080p display) and the tier matching AutoCAD's recommended 8 GB VRAM is $537/month — $6,444 per year per seat, before Windows E3/Intune/Entra prerequisites — versus a one-time local licence. [3][12]
- **Not sold to individuals, and Business tier has no GPU**: a freelance drafter on a MacBook cannot buy a GPU Cloud PC at all without an Enterprise or Flex tenant. [1][11]
- **Latency and input feel**: even Microsoft's 200 ms tolerance is a ceiling, and Autodesk's KB treats remote sessions as a degraded mode (cursor lag, pan/zoom stutter, hardware acceleration "not supported"). Local virtualisation has zero network dependency. [16][35][37]
- **Mac client gaps**: no USB/serial redirection (plotters, dongles, 3D mice), no multimedia redirection, work-account-only sign-in, macOS 14+ floor. [21][22]
- **Spec drift and no hardware guarantee** on Windows 365 GPU SKUs; deterministic hardware requires AVD, which shifts operational burden to the customer. [7]
- **Nested virtualisation blocked** on GPU Cloud PCs (no WSL/Hyper-V/Sandbox), and AVD GPU VMs likewise. [7][28]
- **Autodesk support posture is unchanged**: cloud does not buy certification; support may still demand a physical-machine repro. [34][42]
- **Data gravity**: drawings must live in the cloud; Microsoft advises placing the Cloud PC near the data, not the user. [16]

## Reusable code, ideas, and license implications for MIRRORZ

- **FreeRDP (Apache-2.0)** is the only permissively licensed, production-grade RDP implementation; it can be linked into a proprietary MIRRORZ client to reach Windows 365/AVD/RDS/remote PCs without Windows App, and already handles H.264 and GFX. [44]
- **Sunshine and Moonlight (both GPL-3.0)** show the low-latency recipe (host hardware encode, VideoToolbox decode, YUV 4:4:4 for line clarity, HDR) but copyleft bars embedding them in a closed binary; use them as references or as separate processes behind an arm's-length IPC boundary, and confirm with counsel. [45][46]
- **Microsoft's transport playbook** (TCP reverse-connect, then STUN/TURN UDP upgrade, ICE multipath, AVC 444) is documented well enough to replicate for a MIRRORZ "burst to cloud" path. [16][17][18]
- **Autodesk's virtual-installation tuning list** (ToolTips, Dynamic Input, Selection Preview, CURSORTYPE, H.264, /nohardware, GRAPHICSCONFIG) should become a MIRRORZ per-app profile for both local VM and cloud session, complementing the Parallels fix-ups in `docs/research/reviews/autodesk-kb-official-findings.md`. [36][37]
- **Licensing design**: a single-user Autodesk subscription may be installed on three computers with one active, so a hybrid product can keep one install locally and one in the cloud; keep stable virtual hardware IDs in both. [40] For the cloud half, AVD per-user access pricing is the compliant route for MIRRORZ as vendor; use Windows 11 Enterprise single-session images, since Windows Server hosts are excluded. [26]
- **Product idea, "Cloud Burst" tier**: local MIRRORZ VM for everyday 2D drafting; one-click hand-off of the same DWG set to a GPU Cloud PC (Windows 365 Reserve/Flex, or MIRRORZ-hosted AVD on NVadsA10 v5) for 3D/point-cloud work, rendering, or apps that refuse ARM; Cloud-Apps-style single windows inside the macOS desktop. Microsoft's Reserve and Cloud Apps GA validate the demand pattern. [10][15]

## Open questions

1. Shadow PC, Paperspace, MacinCloud, MacStadium, Scaleway, Amazon WorkSpaces and Parsec 2026 tiers, GPU models and prices — every source blocked; re-run from an unrestricted network (URLs: shadow.tech, paperspace.com/pricing, macincloud.com/pricing, aws.amazon.com/workspaces/pricing, parsec.app/pricing).
2. Exact AVD per-user access prices (Apps vs Desktops + apps) and NVadsA10 v5 / NVads V710 v5 hourly rates — need azure.microsoft.com pricing calculator or prices.azure.com.
3. DirectX feature level and driver version exposed by Windows 365 GPU partitions; whether AutoCAD's "Fast" visual styles enable on GPU Select/Standard.
4. Independent latency measurements (glass-to-glass) for Windows App on Apple silicon versus Moonlight/Parsec; none obtainable this session.
5. Whether Autodesk's "hardware acceleration not supported over remote desktop" KB article predates GPU Cloud PCs; its date is not exposed by the KB API.
6. Windows 365 Link street price; Windows 365 Business GPU availability; any 2026 announcement of individual/consumer Windows 365 (techcommunity blog on the Flex rename was blocked).
7. FreeRDP 3.31.1 release year (tags page: 2026; release page extraction: 2024) — confirm manually.

## Sources (numbered list of URLs with dates)

1. https://www.microsoft.com/en-us/windows-365/business/compare-plans-pricing — fetched 2026-09-04 (no page date)
2. https://www.microsoft.com/en-us/windows-365/enterprise/compare-plans-pricing — fetched 2026-09-04
3. https://www.microsoft.com/en-us/windows-365/all-pricing — fetched 2026-09-04
4. https://www.microsoft.com/en-us/windows-365/frontline/compare-plans-pricing — fetched 2026-09-04 (Flex/Frontline)
5. https://www.microsoft.com/en-us/windows-365/frontline — fetched 2026-09-04
6. https://www.microsoft.com/en-us/windows-365/link — fetched 2026-09-04 (GA 2025-04-02)
7. https://learn.microsoft.com/windows-365/enterprise/gpu-cloud-pc — [MS Learn] 2026-09-04
8. https://learn.microsoft.com/windows-365/enterprise/gpu-cloud-pc-performance — [MS Learn] 2026-09-04
9. https://learn.microsoft.com/windows-365/enterprise/cloud-pc-size-recommendations — [MS Learn] 2026-09-04
10. https://learn.microsoft.com/windows-365/enterprise/whats-new — [MS Learn] 2026-09-04 (entries dated weeks of 2025-09-15, 2025-11-17, 2026-05-11, 2026-06-01)
11. https://learn.microsoft.com/windows-365/overview — [MS Learn] 2026-09-04
12. https://learn.microsoft.com/office365/servicedescriptions/windows-365-service-description/windows-365-service-description — [MS Learn] 2026-09-04
13. https://learn.microsoft.com/windows-365/enterprise/introduction-windows-365-flex — [MS Learn] 2026-09-04
14. https://learn.microsoft.com/windows-365/enterprise/windows-365-flex-license — [MS Learn] 2026-09-04
15. https://learn.microsoft.com/windows-365/enterprise/cloud-apps — [MS Learn] 2026-09-04
16. https://learn.microsoft.com/windows-365/enterprise/optimal-provisioning-cloud-pc — [MS Learn] 2026-09-04
17. https://learn.microsoft.com/windows-365/enterprise/requirements-network — [MS Learn] 2026-09-04
18. https://learn.microsoft.com/windows-365/enterprise/understanding-remote-desktop-protocol-traffic — [MS Learn] 2026-09-04
19. https://learn.microsoft.com/windows-365/end-user-access-cloud-pc — [MS Learn] 2026-09-04 (Remote Desktop retirement dates 2025-05-27, 2026-03-27)
20. https://learn.microsoft.com/windows-app/whats-new — [MS Learn] 2026-09-04 (releases dated 2026-08-11 to 2026-08-18)
21. https://learn.microsoft.com/en-us/windows-app/overview — [MS Learn] 2026-09-04
22. https://learn.microsoft.com/windows-app/compare-platforms-features — [MS Learn] 2026-09-04
23. https://learn.microsoft.com/windows-app/get-started-connect-devices-desktops-apps — [MS Learn] 2026-09-04
24. https://learn.microsoft.com/windows-server/remote/remote-desktop-services/connect-remote-desktop-services — [MS Learn] 2026-09-04
25. https://azure.microsoft.com/en-us/pricing/details/virtual-desktop/ — via [MS Learn] fetch 2026-09-04 (per-user prices not rendered)
26. https://learn.microsoft.com/azure/virtual-desktop/licensing — [MS Learn] 2026-09-04
27. https://learn.microsoft.com/azure/virtual-desktop/enroll-per-user-access-pricing — [MS Learn] 2026-09-04
28. https://learn.microsoft.com/azure/virtual-machines/sizes/gpu-accelerated/nvadsa10v5-series — [MS Learn] 2026-09-04
29. https://learn.microsoft.com/azure/virtual-machines/sizes/gpu-accelerated/nv-family — [MS Learn] 2026-09-04 (NVv3/NVv4 retirement 2026-09-30)
30. https://learn.microsoft.com/industry/manufacturing/architecture/autodesk-autocad-amd — [MS Learn] 2026-09-04
31. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html — [ADSK KB] 2026-09-04
32. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Virtual-Environments-when-using-Autodesk-software.html — [ADSK KB] 2026-09-04
33. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Does-Revit-work-on-Azure-Virtual-Desktops.html — [ADSK KB] 2026-09-04
34. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Does-Inventor-support-running-on-virtual-machines.html — [ADSK KB] 2026-09-04
35. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Hardware-acceleration-is-unavailable-in-AutoCAD-over-Citrix.html — [ADSK KB] 2026-09-04 (undated)
36. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-Performance-Recommendations-for-Citrix-XenApp.html — [ADSK KB] 2026-09-04
37. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/panning-and-cursor-performance-issues-in-autocad-while-working-remotely.html — [ADSK KB] 2026-09-04
38. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Performance-and-selection-issues-in-AutoCAD-when-running-on-Amazon-Workspaces.html — [ADSK KB] 2026-09-04
39. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Revit-benchmarking-on-Azure-Virtual-Desktop.html — [ADSK KB] 2026-09-04
40. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Can-I-install-and-activate-my-single-seat-of-Revit-on-multiple-machines.html — [ADSK KB] 2026-09-04
41. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-360-Pro-Mobile-App-Free-with-AutoCAD-Subscription.html — [ADSK KB] 2026-09-04
42. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Blank-Home-screen-and-empty-Project-Browser-on-Microsoft-Azure-virtual-environment-in-Revit.html — [ADSK KB] 2026-09-04
43. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/About-installing-the-Network-License-Manager-on-a-cloud-environment.html — [ADSK KB] 2026-09-04
44. https://github.com/FreeRDP/FreeRDP and https://github.com/FreeRDP/FreeRDP/tags — fetched 2026-09-04 (Apache-2.0; tags 3.31.1 2026-09-02)
45. https://github.com/LizardByte/Sunshine and https://github.com/LizardByte/Sunshine/releases/latest — fetched 2026-09-04 (GPL-3.0; v2026.516.143833, 2026-05-16)
46. https://github.com/moonlight-stream/moonlight-qt, /releases and /blob/master/LICENSE — fetched 2026-09-04 (GPL-3.0; v6.1.0, 2024-09-17)
47. https://github.com/Paperspace — fetched 2026-09-04 (cli updated 2026-02-07)
48. https://learn.microsoft.com/windows-365/enterprise/identity-authentication — [MS Learn] 2026-09-04 (external identities)
