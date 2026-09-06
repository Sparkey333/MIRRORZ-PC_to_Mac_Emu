# Graphics Translation Stacks for Running Windows CAD on Apple Silicon: D3DMetal, DXMT, DXVK-macOS, MoltenVK, vkd3d-proton, Parallels, wined3d (and the new UTM Triton path)

_Research date: 2026-09-03_

Scope note: autodesk.com, kb.parallels.com, solidworks.com, codeweavers.com and winehq.org were unreachable from the sandbox; facts taken only from a search snippet of such pages are marked "(snippet)". Everything else was read from the cited page on 2026-09-03.

## TL;DR (5 bullets)

- **DirectX 11 is the must-have, DirectX 12 is a nice-to-have, OpenGL 4.5 is the SolidWorks blocker.** AutoCAD requires a DirectX 11-compliant GPU at minimum and uses DirectX 12 Feature Level 12_0 only for the "Fast" visual styles [4][5]; Revit 2026/2027 require a DirectX 11 card with Shader Model 5 and explicitly do not use DirectX 12 features [6][7]; SolidWorks' graphics engine is OpenGL 4.5 (snippet) [10] and Dassault does not support Windows on Mac hardware at all [9][10].
- **Only two production-grade D3D11-on-Metal implementations exist, and only one is usable commercially.** Apple's D3DMetal (D3D11+D3D12, now GPTK 4 / Metal 4) is proprietary and licensed "solely for non-commercial purposes" redistribution [1][2][3][17]; DXMT (D3D10/11, open source, maintained by its author at CodeWeavers) is LGPL-2.1+ as of the post-0.80 tree, with v0.80 (2026-04-23) the last MIT release [11][12][13].
- **The Vulkan route is a dead end for CAD-grade DirectX on macOS today.** DXVK-macOS is frozen at DXVK 1.10.3 (last release 2023) [14][15]; vkd3d-proton requires Vulkan 1.3 features (1,000,000 update-after-bind descriptors, robustness2, etc.) that it does not target on MoltenVK and has no macOS support [16]; MoltenVK itself (Apache-2.0, Vulkan 1.4 since v1.4.0 on 2025-08-20, v1.4.2 on 2026-07-24) still lacks geometry shaders and pipeline-statistics queries [18][19][20].
- **Parallels is the incumbent bar to clear: DirectX 11.1 plus a new Metal-based OpenGL 4.3 driver in Parallels Desktop 27 (2026-08-25), Pro edition, no DirectX 12** (snippets) [21][22][23]. Autodesk lists "Parallels Desktop for Mac: Recommended-Level Configuration" in the Revit 2026 requirements but tells users not to use the new Accelerated Graphics on Parallels [6][8].
- **The most promising open architecture appeared in the last 60 days: UTM's Triton/Neptune path** (a real Windows D3D11 user-mode driver in an ARM64 guest, serialised over VirtIO to a host backend that is DXMT or, "when available", D3DMetal), shipped in UTM 5.0.4 (2026-08-01) and extended to DirectX 12 in 5.0.5 (2026-09-02) [24][25][26]. MIRRORZ should build on this shape: VM + paravirtual D3D11 driver + DXMT host backend, with D3DMetal as an optional user-supplied accelerator, and a Zink-on-MoltenVK path for OpenGL 4.5.

## Current status (version, date, maintainer, momentum)

| Stack | Latest version / date | Maintainer | DirectX covered | Momentum (2026) |
|---|---|---|---|---|
| Apple D3DMetal (Game Porting Toolkit) | GPTK 4 (WWDC26, June 2026); evaluation environment requires macOS 27 and Apple silicon [1][2]; GPTK 3.0 binaries dated 2025-12-05, 3.0-3 on 2026-03-03 in the community repack [3] | Apple | D3D11 + D3D12 (D3DMetal 2.1 in CrossOver 25, 3.0 in CrossOver 26; UTM 5.0.5 uses it for DX12) [25][27][28] | High: Metal 4 backend, agent skills, CLI Metal tools [1][2]. Closed source; Apple's GitHub repo contains only skills/metal-cpp/samples under Apache-2.0 and "D3DMetal source is not included" [29] |
| DXMT | v0.80, 2026-04-23 (last MIT release); main branch LGPL-2.1+; commits through 2026-09-03 [11][12][13] | Feifan He ("3Shain"), copyright "for CodeWeavers 2023-2026" [12] | D3D10 + D3D11 (tessellation via Metal mesh shaders since v0.70 2025-10-17; D3DKMT shared resources need Wine 10.18+ since v0.72 2025-12-11; experimental Intel Mac support since v0.72) [11]. A `src/d3d12` directory exists and late-August/September 2026 commits are titled `feat(d3d12)` (unreleased) [13][30] | High: 1.0 plan published 2026-04-21 (stream-output, UAV counters, cross-process rendering; Metal 4 backend and tiled resources deferred post-1.0) [31]; shipped in CrossOver 25 and 26 [27][28] |
| DXVK-macOS | v1.10.3-20230507(-repack), 2023; "only DirectX 10 & DirectX 11", needs MoltenVK 1.2.0+ and Wine 7.1+ [14][15] | Gcenx (community) | D3D10 + D3D11 (d3d9.dll and dxgi.dll deliberately removed) [15] | Stalled: DXVK 2.x needs Vulkan features MoltenVK lacks; UTM had to patch geometry shaders into its own MoltenVK "to enable DXVK" (5.0.2, 2026-02-24) [24] |
| MoltenVK | v1.4.2, 2026-07-24 (min macOS 12 / iOS 15 / tvOS 15); v1.4.0 2025-08-20 brought Vulkan 1.4; v1.3.0 2025-05-02 [18][19] | Khronos Group (Vulkan Portability) | Not DirectX; Vulkan 1.4 subset on Metal [20] | Steady; two releases per year. Known limitations: pipeline-statistics queries unsupported, custom allocators ignored, primitive restart always on, no point polygon mode, descriptor-indexing tier limits [32] |
| vkd3d-proton | v3.0.1, 2026-05-06; v3.0 2025-11-17 [33] | HansKristian-Work (Valve/Proton) | D3D12 on Vulkan 1.3+ | High on Linux, none on macOS: requires 1,000,000 UpdateAfterBind descriptors, VK_EXT_robustness2, push descriptors; no macOS/MoltenVK support; the 2024 "port to mac?" issue is closed [16][34] |
| Wine / wined3d | Wine 11.0 released 2026-01-13 (6,000+ changes, WoW64 complete, Vulkan H.264 decode in wined3d) (snippet) [35]; Wine 10.0 2025-01-23 (snippet) [36] | WineHQ / CodeWeavers | D3D1-11 over OpenGL or Vulkan; D3D12 via bundled vkd3d (1.18 in CrossOver 26) (snippet) [28] | Stable but on macOS the OpenGL backend is capped at Apple's deprecated OpenGL 4.1 [37][38]; CrossOver's Graphics setting exposes wined3d, DXMT, DXVK and D3DMetal side by side (snippet) [39] |
| Parallels Desktop | 27, 2026-08-25: new Metal-based graphics driver with OpenGL 4.3 on Apple silicon (Pro edition), up to 2.6x OpenGL speed-up (snippets) [21][22]; 26 on 2025-08-26 (OpenGL 4.1) (snippet) [23] | Parallels (Alludo) | DirectX 11.1 on Apple silicon; no DirectX 12 (snippet) [40] | Commercial incumbent; DX12 has been a multi-year open request |
| UTM Triton/Neptune | UTM 5.0.4 2026-08-01 (DirectX 11 for Windows guests via Neptune backend in virglrenderer); 5.0.5 2026-09-02 (DirectX 12 with D3DMetal backend "when available"; iOS DX11 with DXMT) [24][25] | osy / UTM team | D3D11 (Triton UMD implements the D3D11 DDI inside the guest) and D3D12 via D3DMetal on host [25][26] | New, pre-release, but open source across the whole path: Mesa fork `osy/virtio-win-mesa` (branch `neptune`), `osy/kvm-guest-drivers-windows` (BSD-3-Clause, ARM64 drivers), `utmapp/virglrenderer` (branch `macos`), `utmapp/qemu` [26][41][42] |

## Pricing and licensing (table)

| Component | License / price | Redistribution consequence for MIRRORZ | Source |
|---|---|---|---|
| Apple D3DMetal.framework / libd3dshared.dylib | Apple GPTK License: may "distribute the Apple Software solely for non-commercial purposes"; unmodified License.pdf must ship; "may not be sold or bundled into a commercial product" | Cannot be bundled or sold. Only a user-initiated download from developer.apple.com (as Apple's Homebrew tap requires) or a runtime "use if present" hook is defensible | [17][45] |
| Apple game-porting-toolkit GitHub repo | Apache-2.0 (skills, metal-cpp, samples only) | Freely reusable; contains no translation layer | [29] |
| DXMT | v0.80 and earlier: MIT. Main branch after 2026-04-23: LGPL-2.1 or later | Ship as a separately replaceable library with source offer; a fork of the MIT snapshot is possible but forfeits the d3d12 work | [11][12] |
| MoltenVK | Apache-2.0 | Free to bundle, modify, and keep patches private (UTM does) | [20] |
| DXVK / DXVK-macOS | zlib | Free to bundle | [14] |
| vkd3d-proton, Wine | LGPL-2.1 | Bundle as separate libraries with source | [16] |
| Triton UMD (Mesa fork), virglrenderer | Mesa/virgl are MIT-family (COPYING in repo) | Free to bundle | [41][42] |
| virtio-win guest drivers | BSD-3-Clause | Free to bundle; Windows driver signing is a separate cost | [42] |
| QEMU | GPL-2.0 (upstream) | Keep QEMU as a separate process; do not link proprietary code into it | [26] |
| Parallels Desktop 27 | Standard $99.99/yr, Pro $119.99/yr, Business $149.99/yr; Standard perpetual $219.99 (snippets, aggregated pricing pages) | Price anchor for MIRRORZ; OpenGL 4.3 driver is a Pro feature | [22][46] |
| CrossOver Mac | $74 for CrossOver+ (12 months), $494 lifetime, $34/yr renewal (snippet, CodeWeavers store/blog, Oct 2025) | Price anchor for a Wine-based product | [47] |

## How it works (architecture)

Three fundamentally different shapes exist:

1. **API-level translation inside Wine (no Windows).** The application's `d3d11.dll` import is satisfied by a replacement DLL that re-implements Direct3D on top of a host API. DXMT does D3D10/11 directly on Metal with its own DXBC-to-AIR shader compiler (`airconv`); the author explicitly rejected Apple's Metal Shader Converter to avoid "another proprietary piece" [49]. D3DMetal does D3D11 and D3D12 on Metal but is a black box that Wine loads via `libd3dshared` [17]. DXVK does D3D10/11 on Vulkan and therefore, on macOS, on MoltenVK-on-Metal, a double translation [14][20]. wined3d does Direct3D on OpenGL (4.1 on macOS) or Vulkan [37][38]. The x86-64 binary runs under Rosetta 2 and never sees a Windows kernel, so Autodesk's installer and licensing components, not graphics, are the usual failure point.

2. **Virtual machine with a paravirtual GPU (Windows ARM64 guest).** Parallels ships a proprietary guest display driver that forwards DirectX 11.1 and OpenGL to a Metal-based host renderer [21][40]. UTM's Triton does the same with open components: a Windows user-mode driver implementing the D3D11 DDI, a kernel-mode virtio-gpu driver, a VirtIO serialisation layer (Neptune) into virglrenderer, and then DXMT or D3DMetal on the macOS host [24][25][26]. Microsoft's real `d3d11.dll` runs in the guest, so vendor DRM sees normal Windows; x86 apps run under Prism emulation. Autodesk says "ARM Processors are not supported" for AutoCAD 2025 and Civil 3D 2026 (snippet) [4][50], yet lists Parallels as a Revit configuration [6].

3. **Vulkan as the intermediate (Linux Proton model).** DXVK + vkd3d-proton on a Vulkan driver. On macOS that driver is MoltenVK, whose portability subset lacks geometry shaders and other features vkd3d-proton demands [16][24][32]; CodeWeavers' 2023 vkd3d-on-MoltenVK patches gave CrossOver limited DX12, but Metal's descriptor and pipeline limits keep it well below Proton quality (snippets) [34][51].

## Feature checklist (table: feature | status | notes)

| Feature | Status | Notes |
|---|---|---|
| D3D11 Feature Level 11_0/11_1 on Metal | Available (DXMT, D3DMetal, Parallels 11.1) | DXMT 1.0 plan is "D3D10/11 implementation only" [31]; Parallels states DX 11.1 (snippet) [40] |
| D3D12 Feature Level 12_0 (AutoCAD "Fast" styles) | D3DMetal only (proprietary); DXMT d3d12 in development; vkd3d-on-MoltenVK partial | GPTK 4 translates DX12 to Metal 4 (snippet) [52]; DXMT `feat(d3d12)` commits Aug-Sep 2026 [13] |
| Geometry shaders / stream-output | DXMT: stream-output from GS is a 1.0 milestone [31]; MoltenVK: unsupported upstream, UTM patched it [24] | Legacy CAD viewports use GS for line rendering |
| Tessellation | DXMT via Metal mesh-shader emulation since v0.70 [11] | Post-1.0: tessellation-geometry pipeline [31] |
| Shared resources / cross-process (D3DKMT, keyed mutex) | DXMT since v0.72, needs Wine 10.18+; keyed mutex and cross-process rendering in 1.0 plan [11][31] | Needed for CAD add-ins and browser-based license dialogs |
| Timestamp queries, MTLFence sync, UAV overlap | DXMT v0.80 [11] | Profiling and compute passes |
| Pipeline statistics queries | MoltenVK: unsupported [32] | Some engines query them at startup |
| OpenGL 4.5 (SolidWorks Enhanced Graphics) | Not met by any stack: macOS host GL is 4.1 [38]; Parallels 27 gives 4.3 (snippet) [21]; SolidWorks engine is 4.5 (snippet) [10] | Zink (GL on Vulkan) over MoltenVK is the only open route to 4.5+ |
| OpenGL 4.1 in guest | UTM 5.0.0 "Apple Core OpenGL" [24]; Parallels 26 [23] | Sufficient for AutoCAD OpenGL fallback only |
| Vulkan in guest | UTM Venus (Linux guests) Vulkan 1.3 [24] | Windows guest Vulkan not yet in any Mac VM |
| Intel Macs | DXMT experimental since v0.72 [11]; D3DMetal Apple silicon only [3] | Apple silicon-only is acceptable for a 2026 product |
| Metal 4 backend | D3DMetal 4 yes [1]; DXMT post-1.0 [31]; MoltenVK no public plan | Metal 4 requires macOS 26/27 hardware M1+ |

## CAD / AutoCAD relevance

- **AutoCAD (Windows).** Autodesk's 2025 and 2027 requirement pages, which bracket 2026, both state: Basic "2 GB GPU with 29 GB/s Bandwidth and DirectX 11 compliant"; Recommended "8 GB GPU with 106 GB/s Bandwidth and DirectX 12 compliant"; "DirectX 12 with Feature Level 12_0 is required for Shaded (Fast), Shaded with edges (Fast), and Wireframe (Fast) visual styles" [4][5]. A separate Autodesk KB says DirectX 12 can be used from AutoCAD 2023 onward and that the modern graphics system needs DX12 hardware at feature level 11_0 (snippet) [53]. Conclusion: a solid D3D11 path runs AutoCAD; D3D12 unlocks the Fast visual styles. AutoCAD 2025 says "ARM Processors are not supported" [4]; the 2027 page drops the sentence but does not affirm ARM either [5]. Autodesk's virtualization note disclaims all warranties for virtualized use [4][5], and its KBs document Parallels-specific lag (fix: switch hypervisor from Apple to Parallels) and cursor/display issues [54][55]. AutoCAD for Mac exists natively (2027 requires macOS 14-26 on Intel or Apple M series with Metal) but lacks the Windows-only Specialized Toolsets [5].
- **Revit 2026/2027.** "DirectX 11 capable graphics card with Shader Model 5", 4 GB VRAM recommended; Autodesk lists "For Apple computer: Parallels Desktop for Mac: Recommended-Level Configuration" [6][7]. The new Accelerated Graphics (USD/Hydra, graduated from tech preview in 2027) "does not leverage additional features of DirectX 12" and "we currently don't recommend using the Accelerated Revit Graphics Tech Preview on Parallels Desktop for Mac or other virtualization solutions" [8]. So Revit is pure D3D11, and the differentiator MIRRORZ could own is making Accelerated Graphics fast enough that Autodesk's warning does not apply.
- **SolidWorks 2025/2026.** Windows-only; "Apple Mac machines running Windows using Boot Camp are not supported" (snippet, official requirements) [9]; Dassault "cannot recommend the use of virtualization or Parallels" (snippet, official blog) [10]; the graphics engine introduced in 2019 is OpenGL 4.5 (snippet, official help) [10]; RealView and certified-driver checks are OpenGL-driver-dependent. No DirectX stack helps here; the requirement is a high-version OpenGL implementation inside the guest.

## Strengths (what to match)

- **D3DMetal**: the only shipping D3D12-on-Metal with Metal 4 support and Apple driver-team quality; CrossOver and UTM both route DX12 to it [1][25][28]. Match its DX12 coverage eventually; do not depend on it.
- **DXMT**: open source, purpose-built for Metal's own resource tracking (which a reviewer notes avoids the over-synchronisation of D3DMetal's shared D3D11/D3D12 core) [49], own shader compiler, tessellation, shared resources, monthly releases and a funded maintainer [11][12]. This is the base to adopt.
- **MoltenVK**: Apache-2.0, Vulkan 1.4, twice-yearly releases; vendors carry private patches freely (UTM's geometry shaders) [20][24].
- **Parallels**: turnkey Windows 11 ARM with Microsoft authorization, DX11.1, and now Metal-backed OpenGL 4.3 with published CAD-adjacent benchmarks (ArcGIS Pro +35%, ZWCAD, Blender 4.3) (snippets) [21][22]. Autodesk documents it as a supported Revit configuration [6].
- **Triton/Neptune**: real D3D11 DDI driver in the guest, so vendor DLLs, .NET graphics interop and DRM see stock Windows; entirely open source and host-backend-agnostic [25][26].

## Weaknesses (what MIRRORZ must beat)

- Parallels: no DirectX 12 after years of requests (snippet) [40][56]; OpenGL 4.3 not 4.5; OpenGL driver gated to Pro pricing (snippet) [22]; Autodesk warns off Accelerated Graphics on it [8]; ARM-only Windows means x86 CAD runs through Prism emulation.
- CrossOver/Wine route: CodeWeavers' AutoCAD compatibility entry is stale (snippet) [57]; Autodesk installer/licensing assumes real Windows; wined3d on macOS is capped at OpenGL 4.1 [37][38]; D3DMetal cannot be bundled [17]; Whisky (GPL-3.0 GPTK front-end, archived 2025-05-11, developer endorsed CrossOver) shows free wrappers do not sustain [43][44].
- DXVK-macOS and vkd3d-proton: frozen (2023) and unsupported respectively [15][16].
- MoltenVK: no geometry shaders or pipeline statistics upstream; descriptor-indexing tier limits [32].
- DXMT: not 1.0; D3D12 unreleased; LGPL relicensing means MIRRORZ must architect for a separately-replaceable library [11][12][31].
- UTM Triton: weeks old, pre-release, no Windows-guest Vulkan/OpenGL 4.5, iOS-first tooling [24][25].

## Reusable code, ideas, and license implications for MIRRORZ

**Recommended graphics strategy (VM-first, open host backend, optional proprietary accelerator):**

1. **Guest**: Windows 11 ARM64 in a Virtualization.framework or QEMU-based VM (the only way AutoCAD's installer, licensing and Specialized Toolsets behave; also what Autodesk documents for Revit [6]). Adopt the Triton/Neptune design: a D3D11 UMD (Mesa fork, MIT) plus virtio-gpu KMD (BSD-3-Clause) [41][42]. Budget for Microsoft driver signing.
2. **Host D3D11 backend**: DXMT (LGPL-2.1+) as a dynamically loaded, user-replaceable library with a written source offer; contribute upstream, since its maintainer is funded by CodeWeavers and shipping 1.0 [11][12][31]. Do not fork the MIT v0.80 snapshot except as a fallback; the d3d12 work lives in the LGPL tree [13].
3. **Host D3D12 backend**: track DXMT's `src/d3d12` [30]; in the interim, detect a user-installed Game Porting Toolkit and use D3DMetal "when available", exactly as UTM 5.0.5 does [25], never bundling it (Apple: "solely for non-commercial purposes", License.pdf must accompany, no bundling in a commercial product [17][45]).
4. **OpenGL for SolidWorks**: implement guest OpenGL via Zink (Mesa, MIT) over a Venus/VirtIO Vulkan transport into MoltenVK (Apache-2.0) on the host; UTM already ships Venus for Linux guests [24]. This is the only open path to OpenGL 4.5 and would leapfrog Parallels' 4.3. Expect to carry MoltenVK patches (geometry shaders) as UTM does.
5. **Skip**: DXVK-macOS (frozen), vkd3d-proton on MoltenVK (unsupported), wined3d (GL 4.1 ceiling).

**Reusable code**: DXMT (`airconv` DXBC-to-AIR compiler, Metal resource tracking, D3DKMT glue) [11]; MoltenVK plus UTM's geometry-shader patch [20][24]; `osy/virtio-win-mesa` (neptune) and `utmapp/virglrenderer` (macos) for the paravirtual DDI transport [41][42]; Apple's Apache-2.0 repo for Metal 4 barrier/residency idioms and metal-cpp [29][2]. **License hygiene**: keep QEMU (GPL-2.0) out-of-process; keep LGPL libraries dynamically linked with relink capability; ship Apache/MIT/BSD/zlib notices; treat anything from Apple's GPTK download (D3DMetal, Metal Shader Converter binaries) as non-redistributable.

## Open questions

1. Does AutoCAD 2026's requirements page carry the "ARM Processors are not supported" sentence (present in 2025, absent in 2027)? The page was not fetchable; a snippet for Civil 3D 2026 still says ARM is unsupported [50].
2. What is DXMT's realistic D3D12 timeline, and will CodeWeavers ship it in CrossOver 27? Only commit titles are public [13].
3. Exact wording of Apple's GPTK License.pdf, including whether a "detect and use if the user installed it" hook counts as distribution; the D4Mac summary is second-hand [17].
4. Parallels 27 edition split and pricing were only visible through snippets [21][22][46]; confirm on the buy page.
5. Whether Zink over Venus/MoltenVK can pass SolidWorks' OpenGL 4.5 and RealView driver checks; no public data exists.
6. Windows 11 ARM licensing terms for a commercial VM product (Parallels is "Microsoft-authorized" (snippet) [48]).
7. Prism-in-VM versus Rosetta-under-Wine performance for AutoCAD; no head-to-head data found.

## Sources (numbered list of URLs with dates)

1. https://developer.apple.com/games/game-porting-toolkit/ (Apple, page copyright 2026; fetched 2026-09-03)
2. https://developer.apple.com/videos/play/wwdc2026/357/ (Apple WWDC26 session 357; fetched 2026-09-03)
3. https://github.com/Gcenx/game-porting-toolkit/releases.atom (release timestamps 2025-03-12 to 2026-03-03; fetched 2026-09-03)
4. Autodesk "System requirements for AutoCAD 2025 including Specialized Toolsets", https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2025-including-Specialized-Toolsets.html (via Autodesk Product Help MCP, 2026-09-03)
5. Autodesk "System requirements for AutoCAD 2027 including Specialized Toolsets", https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-AutoCAD-2027-including-Specialized-Toolsets.html (via Autodesk Product Help MCP, 2026-09-03)
6. Autodesk "System requirements for Revit 2026 products", https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Revit-2026-products.html (via MCP, 2026-09-03)
7. Autodesk "System requirements for Revit 2027 products", https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Revit-2027-products.html (via MCP, 2026-09-03)
8. Autodesk Revit help "FAQ - Accelerated Revit Graphics Tech Preview" https://help.autodesk.com/view/RVT/2026/ENU/?guid=GUID-1514E319-7DAB-422E-9BA3-142D135B5EBB and "Accelerated Graphics Graduates from Tech Preview" https://help.autodesk.com/view/RVT/2027/ENU/?guid=GUID-1F8469C6-386C-455A-9BD3-7E4ECC8BDA31 (via MCP, 2026-09-03)
9. https://www.solidworks.com/support/system-requirements (snippet only, 2026-09-03)
10. https://blogs.solidworks.com/products/solidworks/how-to-run-solidworks-on-a-mac/ and https://help.solidworks.com/2026/english/SolidWorks/sldworks/c_Performance_Settings_with_OpenGL.htm (snippets only, 2026-09-03)
11. https://github.com/3Shain/dxmt/releases.atom and https://github.com/3Shain/dxmt/releases/tag/v0.80 (v0.70 2025-10-17 through v0.80 2026-04-23; fetched 2026-09-03)
12. https://github.com/3Shain/dxmt/blob/main/LICENSE (LGPL-2.1+, "Feifan He for CodeWeavers 2023-2026"; fetched 2026-09-03)
13. https://github.com/3Shain/dxmt/commits/main (commits 2026-08-24 to 2026-09-03; fetched 2026-09-03)
14. https://github.com/Gcenx/DXVK-macOS (zlib, 1.10.x branch; fetched 2026-09-03)
15. https://github.com/Gcenx/DXVK-macOS/releases (v1.10.3-20230507 and repack, 2023; fetched 2026-09-03)
16. https://github.com/HansKristian-Work/vkd3d-proton (README requirements; fetched 2026-09-03)
17. https://github.com/MichaelLod/D4Mac/blob/main/THIRD_PARTY_LICENSES.md (Apple GPTK License clauses as quoted; fetched 2026-09-03)
18. https://github.com/KhronosGroup/MoltenVK/releases.atom (v1.3.0 2025-05-02, v1.4.0 2025-08-20, v1.4.1 2025-11-30, v1.4.2 2026-07-24; fetched 2026-09-03)
19. https://github.com/KhronosGroup/MoltenVK/releases/tag/v1.4.2 (min macOS 12 / iOS 15 / tvOS 15; fetched 2026-09-03)
20. https://github.com/KhronosGroup/MoltenVK (Apache 2.0, Vulkan 1.4; fetched 2026-09-03)
21. https://www.parallels.com/newsroom/news/press-releases/20260825-parallels-desktop-27/ (2026-08-25; snippet only)
22. https://www.parallels.com/blogs/parallels-desktop-27/ (snippet only: OpenGL 4.3 driver in Pro edition)
23. https://www.parallels.com/newsroom/news/press-releases/20250826-parallels-desktop-26/ (2025-08-26; snippet only)
24. https://github.com/utmapp/UTM/releases.atom (5.0.0 2026-01-12 through 5.0.5 2026-09-02; fetched 2026-09-03)
25. https://github.com/utmapp/UTM/releases/tag/v5.0.5 (2026-09-02; fetched 2026-09-03)
26. https://blog.getutm.app/2026/introducing-triton-directx-11-driver-for-qemu/ (2026; snippet only, via Phoronix/hwbusters/windowsforum summaries)
27. https://appleinsider.com/articles/25/03/11/crossover-25-improves-directx-11-support-works-with-epic-games-store (2025-03-11; snippet only)
28. https://www.codeweavers.com/blog/mjohnson/2026/2/10/crossover-26-cures-artificial-incompatibility-with-windows-games-on-mac and https://www.codeweavers.com/crossover/changelog (2026-02-10; snippets only)
29. https://github.com/apple/game-porting-toolkit (Apache-2.0; requires macOS 27 / Xcode 27 / GPTK 4; fetched 2026-09-03)
30. https://github.com/3Shain/dxmt/tree/main/src (d3d12 directory present; fetched 2026-09-03)
31. https://github.com/3Shain/dxmt/issues/151 (DXMT 1.0 Release Plan, 2026-04-21; fetched 2026-09-03)
32. https://raw.githubusercontent.com/KhronosGroup/MoltenVK/main/Docs/MoltenVK_Runtime_UserGuide.md (Known limitations; fetched 2026-09-03)
33. https://github.com/HansKristian-Work/vkd3d-proton/releases.atom (v3.0 2025-11-17, v3.0.1 2026-05-06; fetched 2026-09-03)
34. https://github.com/HansKristian-Work/vkd3d-proton/issues/1889 (opened 2024-02-09, closed; fetched 2026-09-03)
35. https://tech.slashdot.org/story/26/01/13/2035229/wine-110-released (2026-01-13; snippet only)
36. https://alternativeto.net/news/2025/4/wine-10-5-released-with-vulkan-h-264-decoding-bluetooth-pairing-and-mono-engine-10-0/ (Wine 10.0 date 2025-01-23; snippet only)
37. https://www.winehq.org/pipermail/wine-devel/2018-July/129491.html (winemac Vulkan driver on MoltenVK; snippet only)
38. https://developer.apple.com/documentation/Metal/migrating-opengl-code-to-metal and Apple Developer Forums threads 694866 / 723714 (OpenGL deprecated since macOS 10.14, 4.1 ceiling; snippets only)
39. https://support.codeweavers.com/miscellanous/advanced-settings-in-crossover-mac (Graphics: Auto/wined3d/DXMT/DXVK/D3DMetal; snippet only)
40. https://kb.parallels.com/en/129497 and https://kb.parallels.com/en/124137 ("DirectX 11.1 and OpenGL 4.3 on Apple silicon"; DX11 since Parallels 15; snippets only)
41. https://github.com/osy/virtio-win-mesa (branch neptune; fetched 2026-09-03)
42. https://github.com/osy/kvm-guest-drivers-windows (BSD-3-Clause, branch neptune, ARM64) and https://github.com/utmapp/virglrenderer (branch macos) (fetched 2026-09-03)
43. https://github.com/Whisky-App/Whisky (archived 2025-05-11; fetched 2026-09-03)
44. https://www.macrumors.com/2025/04/23/whisky-ends-mac-gaming-tool-crossover/ (2025-04-23; snippet only)
45. https://github.com/apple/homebrew-apple ("requires downloading the Game Porting Toolkit from developer.apple.com"; fetched 2026-09-03)
46. https://www.parallels.com/products/desktop/buy/ and https://www.vendr.com/marketplace/parallels (pricing snippets only, 2026)
47. https://www.codeweavers.com/store/ and https://www.codeweavers.com/blog/balfour/2025/10/9/dont-panic-how-crossover-licenses-work (snippets only)
48. https://www.parallels.com/products/desktop/microsoft-authorized-solution-windows-11-arm/ (snippet only)
49. https://github.com/3Shain/dxmt/discussions/15 (2024-09-03 to 2024-11-16; fetched 2026-09-03)
50. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Civil-3D-2026.html (ARM not supported; snippet only)
51. https://it.slashdot.org/story/23/08/17/1338241/directx-12-support-comes-to-crossover-on-mac-with-latest-update (2023-08-17; snippet only)
52. https://appleinsider.com/articles/26/06/17/apples-game-porting-toolkit-4-is-a-big-improvement-for-modern-game-coders (2026-06-17; snippet only)
53. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-run-with-DirectX-11-instead-of-DirectX12-in-graphics-card-setting-by-default.html (snippet only)
54. Autodesk KB "Selection in AutoCAD products lags for several seconds on Apple Mac computer with Parallels running Windows" (via MCP, 2026-09-03)
55. Autodesk KB "Cursor and display performance issues with AutoCAD within Parallels Desktop" and "Install error ... Error 10 ... Parallels on macOS" (via MCP, 2026-09-03)
56. https://forum.parallels.com/threads/directx-12-any-update-on-when-parallels-will-support-it.359555/ (snippet only)
57. https://www.codeweavers.com/compatibility/crossover/autocad (snippet only)
