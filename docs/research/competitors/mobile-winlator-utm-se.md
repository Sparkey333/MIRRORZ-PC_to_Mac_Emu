# Running PC/Windows Apps on Android and iOS in 2026: Winlator, Box64/FEX-on-Termux, UTM SE, ExaGear, and Remote-Stream Clients

_Research date: 2026-09-03_ (fetches performed 2026-09-03/04; see Sources)

> Method note: web search was unavailable and the egress proxy blocked Apple/Google store pages, getutm.app, winlator.org, Parallels/Parsec/Jump/Moonlight sites, Wikipedia and press. Every fact below comes from fetched GitHub repos (READMEs, release pages, exact tag dates from git clones), Apple's guidelines/news feed, developer.android.com, Microsoft Learn and Autodesk's KB. Unverifiable items are flagged under Open questions.

## TL;DR (5 bullets)

- **Winlator is the reference architecture for "Windows on Android"** and is very much alive: LGPL-2.1, 18.9k GitHub stars, tag v11.2.0 created 2026-06-12 and a "Winlator 11.2 (Beta)" release page dated Aug 19 that bundles Box64 v0.4.4 [1][2][3]. It runs unmodified x86-64 Windows binaries via Wine + Box64 (glibc userland inside a Bionic app), with a Java X11 server and a Vulkan IPC shim ("Vortek") so it works on Adreno (Turnip) and Mali/Xclipse GPUs [4][5][6][7].
- **None of this is on Google Play in a form MIRRORZ could copy.** Winlator ships as a sideloaded APK with `targetSdkVersion 28` because Android 10+ forbids `execve()` from the app home dir for apps targeting API 29+, while Google Play now requires new apps/updates to target API 36 (Android 16) [8][9]. Termux's Play build is an explicitly "experimental" separate repo with missing functionality [10]. Android developer verification (regional enforcement 30 Sep 2026, global 2027) will add friction to sideloading [11].
- **On iOS, Apple's Guideline 4.7 now says "retro game console and PC emulator apps can offer to download games," but only without JIT.** UTM SE (threaded-interpreter, no JIT) is the App Store precedent; its App Store build was still v4.6.5 as of a Sept 2025 issue, and UTM's own notes say "iOS 26 breaks the technique that AltJIT and similar tools use to enable JIT" [12][13][14][15]. Nothing on iOS can run AutoCAD usably.
- **ExaGear is dead as a product** (per community READMEs: Eltechs stopped development 28 Feb 2019; closed-source, 32-bit-only, circulating as mods) and the Termux/Box64 "Mobox" route was archived 20 Jun 2025, so the market has consolidated on Winlator and its forks (Cmod, WinHub, afei mod, GameHub) [16][17][18][19].
- **For a MIRRORZ companion app, the realistic design is a remote-view/control + file-transfer client, not an emulator.** Apple's 4.2.7 ("Remote Desktop Clients") permits a mirror of a user-owned Mac on a LAN, forbids store-like UIs, and lets host-side transactions bypass IAP; 3.1.1 bans license keys as an unlock mechanism inside the app, while 3.1.3(b) allows multiplatform entitlements [20]. UTM already ships exactly this pattern ("UTM Server" on macOS 13+ streaming VMs to a free "UTM Remote" iOS app) [21].

## Current status (version, date, maintainer, momentum)

| Project | Maintainer | Latest verified version / date | Momentum | Source |
|---|---|---|---|---|
| Winlator (upstream) | brunodev85 | Tag v11.2.0 (2026-06-12); "Winlator 11.2 (Beta)" release page dated Aug 19; app `versionName "11.2"`; last commit 2026-08-19 | Very high: 18.9k stars, 1.7k forks; releases v9.0.0 (2025-01-03), v10.0.0 (2025-02-28), v10.1.0 (2025-05-16), v11.0.0 (2025-09-26), v11.1.0 (2026-06-01) | [1][2][3][22] |
| Winlator forks | Cmod 1.1k stars (2025-12-09); afeimod/winlator-mod 691 (2026-04-19); Winlator-Glibc 553, MIT, "on hold" since 2024-10-15; WinHub 432 (2026-08-29); WinlatorMali 393 (2026-09-02) | WinHub lineage: "Winlator -> cmod -> Bionic Nightly -> Star Marcescence -> WinHub" | Fragmented but active | [23][24][25] |
| GameHub (GameSir, closed source) | GameSir | Community "gamehub-lite" (2k stars) patches GameHub 5.1.0, stripping Umeng/Firebase/JPush telemetry and shrinking 118 MB to 52 MB | Commercial Winlator-class app; Play listing not verifiable here | [19][26] |
| Box64 | ptitSeb | Tags v0.4.4 (2026-08-02), v0.4.5-1 (2026-08-07); last commit 2026-09-03 | Monthly-ish releases; MIT | [27][28] |
| FEX-Emu | FEX-Emu | Monthly tags FEX-2608 (2026-08-04), FEX-2607 (2026-07-02); last commit 2026-09-03 | Focus on Linux/Wine/ARM64EC; no Android/Termux support statements in README or docs | [29][30] |
| Termux | termux | v0.118.3 (tag 2025-05-23); `targetSdkVersion=28`, `minSdkVersion=21`, `compileSdkVersion=36` | Google Play build is a separate "experimental" repo for Android 11+ | [10][31] |
| Mobox (Termux + Box64 + Wine) | olegos2 | Repository archived 2025-06-20; last commit 2024-11-23 | Dead | [18] |
| ExaGear | Eltechs (later Huawei brand) | Development ceased 2019-02-28 per exagear-302 README; "resumed in 2020 under the Huawei brand" per Exagear-For-Termux README; only mods (exagear-302 324 stars, upd. 2025-02-25) | Dead as a consumer product | [16][17][32] |
| UTM / UTM SE | osy (utmapp) | Tags v5.0.5 beta (2026-09-01), v5.0.0 (2026-01-11), v4.7.5 (2026-01-03), v4.7.2 (2025-08-19), v4.6.5 (2025-04-07). App Store UTM SE reported stuck at 4.6.5 (issue #7411, 2025-09-16, closed "not planned") | Active on macOS; iOS App Store channel stagnant | [13][14][15][33] |
| Moonlight / Sunshine | moonlight-stream / LizardByte | Sunshine tag v2026.902.143621 (2026-09-02); both GPL-3.0 | Active | [34][35][36] |
| Microsoft Windows App | Microsoft | Available for Windows, macOS, iOS/iPadOS, Android/Chrome OS, web, Meta Quest; Remote Desktop Store app unsupported from 2025-05-27; MSI client unsupported from 2026-03-27 | Microsoft's consolidated remote client | [37][38] |

## Pricing and licensing (table)

| Product | Price (verified) | License / IP notes | Source |
|---|---|---|---|
| Winlator (upstream, forks) | Free APK from GitHub Releases | LGPL-2.1 (main repo, `winlator-app`, `vortek`). WinHub states GPL-3.0; Winlator-Glibc states MIT (fork relicensing is inconsistent) | [1][22][7][24][25] |
| Box64 | Free | MIT | [27] |
| FEX | Free | MIT | [29] |
| Termux | Free (F-Droid/GitHub; Play build experimental) | Open source (LICENSE.md) | [10] |
| ExaGear (mods) | Original was paid on Google Play; now pirated/modded, closed-source binaries | No usable license; do not touch | [16][17] |
| UTM (macOS/iOS) | Free from GitHub; UTM Remote "plans are to release it as a free app in the App Store"; UTM SE accepts "donations through In-App Purchase" (App Store price itself not verifiable here) | Apache 2.0 frontend, but "uses several (L)GPL components ... parts of the code are taken from qemu. Please be aware of this if you intend on redistributing" | [12][21][39] |
| iSH (x86 Linux shell on iOS) | On the App Store (id1436902243) | Dual license files (LICENSE.IOS / LICENSE.md) | [40] |
| Moonlight (iOS/Android) | Free on App Store (id1000551566) and Google Play/Amazon/F-Droid | GPL-3.0 | [34][35] |
| Sunshine (host) | Free | GPL-3.0 | [36] |
| Windows App | Free client; "You can't sign in ... using a personal Microsoft account", but sign-in is not required for Remote PC connections | Proprietary | [37] |
| Parsec / Jump Desktop / Splashtop / Parallels Access | **Not verifiable** (domains blocked) | — | gap |

## How it works (architecture)

**Winlator (verified from source tree, [3][4][5][6][7]).** The upstream repo is now a thin shell whose `.gitmodules` pulls three submodules: `app` (brunodev85/winlator-app), `vortek`, and `gladio` [41]. Key facts:

- *Process model.* The APK is `arm64-v8a` only, `minSdkVersion 26`, `targetSdkVersion 28`, `extractNativeLibs="true"`. API 28 is deliberate: Android 10 removed execute permission for the app home directory for apps targeting API 29+ ("Untrusted apps that target Android 10 cannot invoke `execve()` directly on files within the app's home directory") [8]. Winlator installs a glibc root filesystem ("native GLIBC for better I/O performance", v10.0) built with Termux-Pacman glibc patches, then launches Box64 -> Wine -> the Windows x86-64 binary [42][1].
- *CPU.* Box64 provides x86-64 -> ARM64 dynamic recompilation ("a speed boost 5-10x faster than the interpreter alone") with DynaCache; Wine WoW64 for 32-bit apps "is still experimental, but it works in most cases" [27]. Winlator ships selectable Box64 builds (0.3.3-0.3.7 installable; 0.4.0 in v11.0, 0.4.4 in v11.2) with per-container presets [3][43][2].
- *Display.* Winlator does not use Termux-X11; it embeds its own X11 server written in Java (`com.winlator.xserver`, 99 source files) plus `xenvironment` components (`RootFS`, `XServerComponent`, `GuestProgramLauncherComponent`, PulseAudio/ALSA, SysV SHM, `VortekRendererComponent`, `VirGLRendererComponent`) and a `winhandler` bridge [3].
- *GPU.* Three paths: (a) **Turnip** (Mesa's open Adreno Vulkan driver; 24.1.0/25.0.0/26.0.3) via `libadrenotools`; (b) **Vortek**, "a compatibility layer on top of the Vulkan host driver" that "performs ... Format emulation, SPIR-V inspection, texture decoding" by marshaling "Vulkan commands ... across an IPC boundary, allowing a game client running on glibc (box64 + wine) to interface with a native Vulkan renderer server" — the Mali/Xclipse path; (c) **VirGL** and the experimental **Gladio** "OpenGL wrapper through GLES" (v11.0) [7][5][43][3]. On top sit DXVK (0.96-2.6.1), VKD3D (2.12-3.0b), WineD3D (4.21-10.0), D8VK/D7VK and CNC-DDraw [3][1].
- *Audio/input.* ALSA/PulseAudio shims, on-screen "Input Controls" profiles, external gamepad/keyboard, MIDI handler [3].

**Termux route (Mobox, "termux-box").** Same stack but user-assembled inside Termux with Termux-X11 as the display server; Box64's own docs call the native Termux build "experimental" and say it "won't run linux binaries" without extra Android libs [18][44]. Mobox was archived in June 2025 [18].

**FEX vs Box64.** FEX is "a fast usermode x86 and x86-64 emulator for Arm64 Linux" (ARMv8.0+, MIT) tested on Arch/Fedora/openSUSE/Ubuntu; recent releases focus on Wine unixlib/ARM64EC and Snapdragon X2 Elite; its README and docs contain no Android/Termux support statements [29][30]. Winlator upstream and the fork READMEs we could read do not list FEXCore as a component (only GameHub-style closed apps are rumored to; unverified).

**UTM SE (iOS).** "UTM/QEMU requires dynamic code generation (JIT) for maximum performance ... UTM SE ('slow edition') uses a threaded interpreter which performs better than a traditional interpreter but still slower than JIT ... can be sideloaded as a regular app"; SE targets are ARM, PPC, RISC-V and x86 [12]. This is whole-system emulation of a full Windows install, so x86 Windows runs at interpreter speed. iSH is the other App Store precedent: usermode x86 Linux via a gadget-threaded interpreter [40].

**Remote-stream clients.** Moonlight (client) + Sunshine (host) use hardware video encode; on macOS, Sunshine requires macOS 14.2+, captures via ScreenCaptureKit, encodes only with Video Toolbox, and lacks gamepad emulation [36]. Windows App (Microsoft) supports "Remote PC" connections from iOS/iPadOS and Android without signing in [37].

## Feature checklist (table: feature | status | notes)

| Feature | Status (2026) | Notes / source |
|---|---|---|
| Run x86-64 Win32 apps on Android | Yes (Winlator, forks, GameHub) | Wine + Box64; 32-bit via WoW64 "experimental" [1][27] |
| Run x86-64 Win32 apps on iOS | Effectively no | UTM SE = interpreter-speed whole-system emulation; JIT blocked; iOS 26 broke AltJIT [12][14] |
| Google Play distribution of a Winlator-class app | Not with current stack | targetSdk 28 vs Play's API 36 requirement; W^X rule [8][9] |
| Vulkan on Adreno | Yes (Turnip 26.0.3) | [43] |
| Vulkan on Mali/Xclipse | Yes via Vortek shim | [7][5][2] |
| DirectX 9/10/11/12 | Yes via DXVK/VKD3D | [3] |
| OpenGL | Partial (VirGL, experimental Gladio) | v11.0 notes [43] |
| Steam client | Yes (fixed startup, "Steam Legacy" option in 11.1) | [2] |
| Multi-controller, vibration, MIDI | Yes | v11.0 [43] |
| Touch/on-screen controls | Yes | `inputcontrols` package [3] |
| .NET apps | Partial (Wine Mono) | README tip [1] |
| 16 KB page-size devices | Unknown | No matching issues in upstream tracker; Play deadline for updates 2027-02-01 [45][46] |
| Sideload viability post-2026 | Degrading | Android developer verification: regional 2026-09-30, global 2027; "advanced flow" for power users, ADB unaffected [11] |
| Remote view of a Mac VM from iPhone/iPad | Yes (UTM Remote, Moonlight/Sunshine, Windows App to a Windows guest) | [21][34][36][37] |
| Apple Silicon Mac as host for Windows | UTM (QEMU/Apple Virtualization, DirectX support in 5.0.5 beta) | [33] |

## CAD / AutoCAD relevance

- **AutoCAD is x64-only on Windows.** Autodesk's KB states Autodesk products "are based on 64-bit (x64) software" and are "not compatible" with Windows-on-ARM hardware, and "AutoCAD 2025 is not supported on ARM x86 ... AutoCAD products can only be supported on x64 operating systems" [47][48]. AutoCAD 2027 requires 64-bit Windows 11, 16 GB RAM (32 GB recommended), a DirectX 11 GPU with DirectX 12 FL 12_0 needed for "Fast" visual styles, and .NET 10; the Mac build supports "Apple M series CPU" natively [49].
- **Implication for Android emulation:** every AutoCAD instruction must go through Box64's dynarec and D3D through DXVK/VKD3D on a phone GPU. Winlator's own tips advise a "Stability" Box64 preset for Unity apps — a hint at how fragile large managed/.NET-heavy apps are [1]. No fetched source documents AutoCAD running under Winlator; treat it as unproven and likely unusable for real work.
- **Autodesk's own mobile answer** is the AutoCAD mobile app: iOS 17.0+, 64-bit Android 8.0+, Windows 10 x64; Chromebook unsupported [50]. That is the bar for "view/mark-up DWG on a phone" that a MIRRORZ companion app would be compared against.
- **Strategic reading:** on mobile, the only credible AutoCAD experience is *streaming* the desktop session from a Mac/PC (Windows App, Moonlight/Sunshine, UTM Remote-style), which is exactly what Apple 4.2.7 allows and what Autodesk's virtualization clause tolerates ("You may virtualize a product only if the applicable terms ... expressly permit virtualization") [20][49].

## Strengths (what to match)

1. **Compatibility-layer, not VM.** Wine+Box64 avoids booting Windows; MIRRORZ should aim for the same "no Windows license, no VM boot" feel [1][42].
2. **Per-app containers with tunables** (Box64 presets, DX wrapper, graphics driver, env vars, exec args), plus installable component versions (multiple DXVK/VKD3D/Turnip builds) so users can pin what works [3][43].
3. **GPU abstraction that tolerates broken drivers.** Vortek's IPC Vulkan proxy with format emulation and SPIR-V inspection is an elegant answer to heterogeneous GPUs — the same problem MIRRORZ faces mapping D3D to Metal [7][5].
4. **Community velocity.** Monthly Box64/FEX releases and a fork ecosystem shipping features upstream lacks [27][29][23].
5. **UTM's companion pattern.** "UTM Server" on macOS 13+ streams QEMU VMs to a free "UTM Remote" iOS/visionOS client reusing the same SwiftUI frontend "without any of the QEMU backend" [21].

## Weaknesses (what MIRRORZ must beat)

1. **Distribution is sideload-only** (targetSdk 28, W^X), with Android developer verification tightening from 30 Sep 2026 [8][9][11]. A commercial product cannot rely on this.
2. **Gaming-centric UX** (gamepad models, on-screen controls, Steam) — no productivity affordances such as printer/plotter passthrough, license servers, or document round-tripping.
3. **Correctness/stability gaps**: WoW64 and Gladio "experimental", "Stability" presets for Unity, Mali quirks — unacceptable for hours-long CAD sessions [27][43][2].
4. **License hygiene is messy across forks** (LGPL-2.1 upstream vs GPL-3.0 WinHub vs MIT Winlator-Glibc; GameHub telemetry stripped by a "lite" repatch) [24][25][19].
5. **iOS is a dead end for emulation**: UTM SE is interpreter-only, App Store build stagnant at 4.6.5, and iOS 26 killed AltJIT-style workarounds [13][14][12].
6. **No CAD evidence anywhere** — nobody claims AutoCAD works on Winlator, and Autodesk explicitly disclaims ARM/virtualized environments [47][49].

## Reusable code, ideas, and license implications for MIRRORZ

| Component | License | Reuse posture for a commercial macOS product |
|---|---|---|
| Wine | LGPL-2.1 (not fetched; per Winlator credits) | Dynamic linking/shipping as separate binaries is standard practice; keep Wine sources/patches published. |
| Box64 | MIT [27] | Freely reusable; largely redundant next to Rosetta 2 on Apple Silicon, but DynaCache and per-app presets are ideas to borrow. |
| FEX | MIT [29] | Same as above; its ARM64EC/Wine work is the most relevant modern x86-on-ARM design reference. |
| Winlator app, Vortek, Gladio | LGPL-2.1 [1][7][22] | Android UI not portable; Vortek's IPC Vulkan-proxy design is worth studying for a D3D->Metal path; copying code triggers LGPL obligations. |
| DXVK / VKD3D | zlib / LGPL (not fetched) | Already the industry path (Wine->Vulkan); on macOS this implies MoltenVK or a native Metal backend. |
| UTM (frontend Apache 2.0; QEMU parts GPL) [12] | Study `Remote`/`Services` for the server<->remote-client protocol; do not copy GPL'd QEMU-derived code. |
| Moonlight / Sunshine | GPL-3.0 [34][36] | Do not embed; treat as an interoperability target (a Sunshine-compatible stream lets users bring Moonlight). |
| iSH | mixed [40] | Precedent only. |
| ExaGear mods | closed/pirated [16][17] | Never use. |

**Companion-app scope that is realistic under current rules [20][37][21]:**
- *Remote view/control* of the MIRRORZ session: allowed under Apple 4.2.7 as "a generic mirror of the host device" or, if app-specific, restricted to a user-owned Mac on a LAN with everything executed/rendered on the host and no store-like UI.
- *License management*: the iOS app may **not** unlock features with license keys (3.1.1) but may honor entitlements bought elsewhere if the same items are also offered as IAP (3.1.3(b)); transactions inside the mirrored Windows software "do not need to use in-app purchase" (4.2.7(d)). Google Play's equivalent text could not be fetched.
- *File transfer*: pushing DWGs/photos to the Mac and pulling PDFs back is ordinary functionality; on Play it needs API 36 targeting and 16 KB alignment for native code [9][46].
- *Not realistic*: running AutoCAD locally on a phone or tablet, or shipping a JIT-based emulator on iOS.

## Open questions

1. What exactly is listed on Google Play today (GameHub by GameSir? Winlator clones?) and what price/rating they carry — play.google.com and mirror sites were blocked.
2. App Store listing details for UTM SE (price, current version, "What's New" date) — apps.apple.com and itunes.apple.com blocked; only the GitHub issue evidence (4.6.5 as of 2025-09-16) is available.
3. The precise 2024 timeline of Apple's 4.7 change (April 2024 retro-console wording, the reported June 2024 UTM SE rejection and July 2024 approval) — Apple's news archive only paginates back to June 2025 and press/Wikipedia were blocked; the *current* 4.7 text ("retro game console and PC emulator apps") is verified.
4. Whether any Winlator fork ships FEXCore (GameHub is closed source; gamehub-lite README lists no components).
5. Whether Winlator/Box64 already run on 16 KB page-size devices (no matching upstream issues found).
6. Current pricing of Parsec, Jump Desktop, Splashtop, and the status of Parallels Access (all domains blocked).
7. Google Play's written stance on emulators / dynamically loaded executable code (Policy Center blocked); only the policy-timeline page (Aug 26 2026, Sep 30 2026, Jan 27 2027 changes) was reachable [51].

## Sources (numbered list of URLs with dates)

All fetches 2026-09-03/04. "git" = exact tag/commit dates read from a blobless clone of the repo.

1. https://github.com/brunodev85/winlator — README, LGPL-2.1, 18.9k stars; git tags v9.0.0 2025-01-03 ... v11.1.0 2026-06-01, v11.2.0 2026-06-12; HEAD 2026-08-19
2. https://github.com/brunodev85/winlator/releases/tag/v11.2.0 and .../v11.1.0 — release notes
3. https://github.com/brunodev85/winlator-app (git HEAD 2026-08-19) — build.gradle (minSdk 26, targetSdk 28, arm64-v8a, versionName 11.2), AndroidManifest, `com.winlator.*` packages
4. https://github.com/brunodev85/winlator/commits/main — Turnip 26.0.3 / VKD3D 3.0b added 2026-04-14
5. https://github.com/leegao/winlator-internals — Vortek IPC description
6. https://github.com/brunodev85/winlator-app — README
7. https://github.com/brunodev85/vortek — description, LGPL-2.1
8. https://developer.android.com/about/versions/10/behavior-changes-10 — execve restriction for API 29+
9. https://developer.android.com/google/play/requirements/target-sdk — API 36 for new apps/updates; extension to 2026-11-01
10. https://github.com/termux/termux-app — README (Google Play experimental build); git tag v0.118.3 2025-05-23
11. https://developer.android.com/developer-verification — 2026-09-30 regional, 2027 global
12. https://github.com/utmapp/UTM — README (JIT, UTM SE, Apache 2.0 + (L)GPL parts)
13. https://github.com/utmapp/UTM/issues/7411 — App Store UTM SE at 4.6.5 (issue 2025-09-16)
14. https://github.com/utmapp/UTM/releases/tag/v4.7.2 — iOS 26 breaks AltJIT (git tag 2025-08-19)
15. https://developer.apple.com/app-store/review/guidelines/ — 4.7, 2.5.2, 4.2.7, 3.1.1, 3.1.3, 5.2
16. https://github.com/XHYN-PH/exagear-302 — ExaGear ceased 2019-02-28, 32-bit only
17. https://github.com/ZhymabekRoman/Exagear-For-Termux — "resumed in 2020 under the Huawei brand"
18. https://github.com/olegos2/mobox — archived 2025-06-20; git HEAD 2024-11-23
19. https://github.com/Producdevity/gamehub-lite — GameHub 5.1.0 patcher
20. Same as [15] (4.2.7, 3.1.1, 3.1.3(b))
21. https://github.com/utmapp/UTM/releases/tag/v4.5.0 — UTM Server / UTM Remote (git tag 2024-02-27)
22. LICENSE files of winlator and winlator-app via git (LGPL-2.1)
23. https://github.com/brunodev85/winlator/forks?sort=stargazers — fork stars and dates
24. https://github.com/winhub-emu/winhub — lineage, SDK 26/28, GPL-3.0
25. https://github.com/longjunyu2/winlator — MIT, "on hold" since 2024-10-15
26. https://github.com/topics/winlator — topic listing
27. https://github.com/ptitSeb/box64 — README (MIT, DynaRec 5-10x, WoW64 experimental)
28. Box64 git tags v0.4.4 2026-08-02, v0.4.5-1 2026-08-07; https://github.com/ptitSeb/box64/releases
29. https://github.com/FEX-Emu/FEX — README (MIT, ARMv8.0+)
30. FEX git tags FEX-2608 2026-08-04, FEX-2607 2026-07-02; https://github.com/FEX-Emu/FEX/releases
31. termux-app gradle.properties via git (targetSdkVersion=28, minSdkVersion=21, compileSdkVersion=36)
32. https://github.com/topics/exagear — mod repos and dates
33. UTM git tags (v5.0.5 2026-09-01, v5.0.0 2026-01-11, v4.7.5 2026-01-03, v4.6.5 2025-04-07); https://github.com/utmapp/UTM/releases
34. https://github.com/moonlight-stream/moonlight-ios — App Store id1000551566, GPL-3.0
35. https://github.com/moonlight-stream/moonlight-android — Google Play/Amazon/F-Droid, GPL-3.0
36. https://github.com/LizardByte/Sunshine — macOS 14.2+, capture/encoder matrix, GPL-3.0; git tag v2026.902.143621 2026-09-02
37. https://learn.microsoft.com/windows-app/overview and https://learn.microsoft.com/windows-app/get-started-connect-devices-desktops-apps (Microsoft Learn MCP)
38. https://learn.microsoft.com/windows-365/end-user-access-cloud-pc#remote-desktop — Store RD app unsupported 2025-05-27; MSI 2026-03-27
39. https://github.com/utmapp/UTM/releases/tag/v4.5.4 — SE donations via IAP; UTM Remote free (git tag 2024-08-24)
40. https://github.com/ish-app/ish — App Store id1436902243
41. winlator .gitmodules via git (app, vortek, gladio)
42. https://github.com/brunodev85/winlator/releases/tag/v10.0.0 — native glibc, Box64 0.3.4, Wine 9.2-custom (git tag 2025-02-28)
43. https://github.com/brunodev85/winlator/releases/tag/v11.0.0 — Gladio, Box64 0.4.0, Wine 10.10 (git tag 2025-09-26); installable_components/*/index.txt via git
44. box64 docs/COMPILE.md via git — Termux native build "experimental"
45. https://github.com/brunodev85/winlator/issues?q=16kb — no results
46. https://developer.android.com/guide/practices/page-sizes — 16 KB deadline 2027-02-01
47. Autodesk KB "Installation issues ... Windows 64-bit running on ARM processors (WoA)" (Autodesk Product Help MCP, undated)
48. Autodesk KB "Is the Smart Block feature of AutoCAD 2025 available on ARM x86 ..." (Autodesk MCP, undated)
49. Autodesk KB "System requirements for AutoCAD 2027 including Specialized Toolsets" (Autodesk MCP, undated)
50. Autodesk KB "System requirements for AutoCAD Mobile App", article 000485302 (Autodesk MCP, undated)
51. https://developer.android.com/distribute/play-policies — policy timeline
52. https://developer.apple.com/news/ and .../news/rss/news.rss — guideline updates 2025-06-09, 2025-11-13, 2026-02-06, 2026-06-08
53. https://github.com/StephenDev0/StikDebug — off App Store; iOS 17.4-18.x; iOS 26 limited
