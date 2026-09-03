# Autodesk official knowledge-base findings (pulled via Autodesk Product Help API)

_Research date: 2026-09-03. Source: Autodesk Product Help / Support KB (SFDC articles + product documentation), queried programmatically._

## TL;DR

- Autodesk's official position: Windows-only Autodesk products can be run on a Mac with a virtualization program (Parallels Desktop or VMware Fusion named explicitly) or Boot Camp, but **running in a VM is "not supported"** under Autodesk's Virtual Installation Guidelines unless the product's terms expressly permit virtualization. Support tickets for VM-specific problems are redirected to the virtualization vendor.
- Autodesk explicitly states **"ARM processors are not supported for a lot of desktop Autodesk products (for Windows environment)"**. AutoCAD-family 2027 system requirements still say **"ARM Processors are not supported"** (Vehicle Tracking 2027 page, an AutoCAD 2027 host add-on). In practice AutoCAD x64 runs inside Windows 11 ARM via Microsoft's Prism x64 emulation, but it is unsupported by Autodesk.
- Autodesk KB nevertheless documents Parallels-specific fixes, which shows they see real customer volume there: switch the VM hypervisor from "Apple" to "Parallels" to fix selection lag in AutoCAD; install Rosetta 2 on the Mac before running Autodesk installers under Parallels; move installers from the shared macOS Downloads folder into the Windows profile; install the x64, x86 **and ARM64** VC++ redistributables in the Windows VM.
- AutoCAD for Mac exists natively but is **not a 1:1 port**: no QuickCalc, no Block table lookup, no Classic toolbar UI, no Bing/GEOMAP aerial maps, no shipped sample libraries, and historically missing Sheet Set Manager/Express Tools-class features. Autodesk's own KB suggests installing Windows via Boot Camp to get missing features. This is the core demand driver for MIRRORZ among CAD users.
- Autodesk Fusion crashes on Windows-on-ARM / Parallels unless `QSG_RHI_PREFER_SOFTWARE_RENDERER=1` is set. MIRRORZ should ship per-app "fix-up" profiles that apply such environment tweaks automatically.

## Verbatim-relevant KB facts

| Article | Key statement | Implication for MIRRORZ |
|---|---|---|
| "How to run Windows specific Autodesk programs on a Mac" | Use Parallels Desktop / VMware Fusion / Boot Camp; "Not all Autodesk product offerings may be virtualized... you assume all risks"; check product system requirements for virtual environment support. | Marketing must say "works with" not "supported by Autodesk". Offer a compatibility disclaimer per app. |
| "Install error... Error 10... Parallels on macOS" | Causes: Rosetta 2 missing on host; VC++ redistributables (x64/x86/ARM64) missing in guest; Downloads folder mapped to macOS; ADP service. "ARM processors are not supported for a lot of desktop Autodesk products... this environment is not supported and may need consultation with third-party vendor Parallels". | Pre-flight checklist in MIRRORZ: install Rosetta 2, pre-install VC++ x64/x86/ARM64 in the Windows image, default guest Downloads inside the guest, detect ADP service hangs. |
| "Selection in AutoCAD products lags... Parallels" | Fix: change Hypervisor from Apple to Parallels (Hardware > CPU & Memory > Advanced). | Hypervisor/backend choice affects AutoCAD interactivity. MIRRORZ per-app profile should choose the best-performing backend and expose an "AutoCAD tuned" preset. |
| "Cursor and display performance issues with AutoCAD within Parallels Desktop" | Symptoms: slow, mis-sized dialogs, choppy linework, cursor vanishes during pan/zoom, hardware acceleration disabled error. Fixes: resolution mode "Scaled/More Space", SmartMouse "Optimized for games", disable HW accel in AutoCAD, disable dynamic input. | Ship an "AutoCAD graphics preset" that sets DPI/scaling, mouse mode, and toggles GRAPHICSCONFIG hardware acceleration based on detected DirectX level in guest. |
| "Autodesk Self-Extract tool crashes... Parallels" | Parallels maps Downloads to Mac home; fix by using C:\Users\...\Downloads. | Default shared-folder policy must not redirect guest Downloads to host by default (or must whitelist installers). |
| "Installation issues... Windows 64-bit running on ARM (WoA)" | Historic article: Autodesk products are x64; ARM64 "not compatible". | Prism x64 emulation is required; document that Autodesk still does not certify ARM. |
| "Compare Features: AutoCAD for Windows against AutoCAD for Mac" | Mac version "not straight 1:1 ports"; QuickCalc, Block-table Lookup, Classic toolbar UI are Windows-only. LISP and ObjectARX supported on Mac full AutoCAD. | Target persona: users who need Windows-only AutoCAD features, verticals (Civil 3D, Plant 3D, Architecture, MEP, Electrical, Map 3D, Raster Design) that do not exist on Mac at all, plus Revit, Inventor, Navisworks, Vault. |
| "GEOMAP command is not working in AutoCAD for Mac" | Bing maps not in Mac version; Autodesk suggests Boot Camp. | Boot Camp no longer exists on Apple Silicon; the only path is virtualization. |
| "Autodesk Software asks to repair your license... Boot Camp on Parallels" | Hardware-tied activation can break when the same install is used natively and virtualized. | MIRRORZ must keep stable virtual hardware IDs (machine GUID, MAC, TPM, disk serial) across updates to avoid re-activation storms for Autodesk, Adobe, etc. |
| "Autodesk Fusion crashes on startup on Windows on ARM" | Set `QSG_RHI_PREFER_SOFTWARE_RENDERER=1`. | Add to the per-app fix-up database. |
| "Vehicle Tracking 2027 System Requirements" (AutoCAD 2027 host) | Windows 10/11 x64; "ARM Processors are not supported"; DirectX 11 basic, DirectX 12 FL 12_0 required for Shaded (Fast) visual styles; .NET 10. | Guest GPU must expose DX11 minimum and ideally DX12 FL12_0 for fast visual styles; ship .NET runtimes in the golden image. |
| "Desktop Connector System Requirements" | "Windows on Arm-based PCs are not supported at this time. Mac is not supported." | Autodesk Docs/ACC desktop sync will not run on ARM guests; document the limitation and offer a host-side fallback. |

## What this means for the product

1. **AutoCAD is the flagship, but it is an "at your own risk" workload on any Apple Silicon Mac.** No vendor (Parallels included) has Autodesk certification. MIRRORZ can still win by being the most reliable and best-tuned option and by publishing its own tested compatibility matrix per AutoCAD release.
2. **Guest graphics matter more than raw CPU.** Autodesk's own troubleshooting is almost entirely about display scaling, cursor handling, and hardware acceleration. MIRRORZ's differentiator should be a first-class DirectX 11/12-on-Metal virtual GPU path and a CAD-specific display preset.
3. **Installer hygiene is a solved-but-annoying problem.** Rosetta 2, VC++ runtimes (including ARM64), .NET runtimes, and Downloads-folder location are all automatable. A "golden image" builder that pre-installs them removes the top install failure.
4. **Stable virtual hardware identity is mandatory** for CAD, Adobe, and engineering licensing.
5. **Per-app fix-up database** (environment variables, registry tweaks, system variables like GRAPHICSCONFIG/DYNMODE) is a genuine product feature, not a support article.

## Sources

1. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-run-Windows-specific-Autodesk-programs-on-a-Mac.html
2. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Install-error-The-install-couldn-t-finish-Error-10-when-installing-Autodesk-products.html
3. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Selection-in-AutoCAD-products-lags-for-several-seconds-on-Apple-Mac-computer-with-Parallels-running-Windows.html
4. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Cursor-and-display-performance-issues-with-AutoCAD-within-Parallels-Desktop.html
5. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Self-Extract-tool-closes-in-your-Windows-environment-when-using-Parallels-Desktop-on-a-Mac.html
6. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Surface-Pro-X-and-Windows-running-on-ARM-processors-WoA.html
7. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Compare-Features-AutoCAD-for-Windows-vs-AutoCAD-for-Mac.html
8. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/GEOMAP-command-is-not-working-in-AutoCAD-for-Mac.html
9. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Software-asks-to-repair-your-license-when-accessing-My-Boot-Camp-on-Parallels-Desktop.html
10. https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Autodesk-Fusion-crashes-on-startup-in-Windows-on-ARM.html
11. https://help.autodesk.com/view/VEHTRK/ENU/?guid=GUID-93FF210B-FE08-4DC3-B4DB-0B9BA7724E23
12. https://help.autodesk.com/view/CONNECT/ENU/?guid=System_Requirements_Desktop_Connector
