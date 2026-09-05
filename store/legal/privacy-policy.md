# MIRRORZ Privacy Policy

_Effective: on first public release. Draft prepared 2026-09-05. Have counsel review before publication._

MIRRORZ ("we", "us") makes the MIRRORZ app for Mac, the MIRRORZ Companion apps for iOS and Android, and the services at mirrorz.app. This policy explains what we collect, why, and what we never collect.

## The short version

- **No advertising, no ad networks, no analytics SDKs, no trackers.** None of our apps contain third-party advertising or analytics code.
- **Telemetry is off by default.** The only optional data you can choose to send is an anonymous "this app works / does not work" compatibility report.
- **We do not see what you run.** Machines and Bottles run entirely on your Mac. We never receive screenshots, file names, documents, keystrokes, or the contents of your virtual machines.
- **Licensing needs a little data** so your license works on the right Macs. That is the only data we collect by default, and it is listed below in full.

## What we collect and why

| Data | When | Why | Kept for |
|---|---|---|---|
| Device identifier (an opaque random or hashed value created by the app; never your serial number or Apple ID) | Trial start, license activation, daily license refresh | To count devices against your plan and issue your offline device token | Life of the license + 12 months |
| Device name, platform, OS version, app version | Same | To show you which Macs are activated and to support you | Same |
| License key (stored only as a one-way hash) and plan | Purchase | To validate your license | Life of the license + 7 years (accounting) |
| Email address (stored only as a one-way hash after the key is delivered) | Direct purchases on mirrorz.app | To send your license key and receipts | Hash retained for support lookups; raw address held by our payment processor |
| App Store / Google Play purchase identifiers (original transaction id, purchase token) | In-app purchases | To honor purchases, refunds and renewals reported by Apple or Google | Life of the license + 7 years |
| Pairing codes and room identifiers | When you pair a phone or tablet | To connect your companion to your Mac | Minutes; rooms end when the Mac disconnects |
| Server logs (IP address, request path, status) | Every request | Security and abuse prevention | 30 days, then deleted |

We do not use the data above for marketing and we never sell or rent it.

## Optional compatibility reports

If you turn on **Send anonymous compatibility reports** (off by default), the app sends: the app you ran (its catalog id and version), whether it worked, the runtime used, your Mac model family, your macOS version and the MIRRORZ version. No identifier of any kind is attached, and the report cannot be linked to your license or device. You can turn this off at any time.

## MIRRORZ Remote

When you control your Mac from a phone or tablet, the video and input travel over a WebRTC connection that is encrypted end to end (DTLS-SRTP). On the same network the connection is direct. Otherwise our signaling server exchanges connection descriptions and, if needed, our TURN relay forwards encrypted packets it cannot read. We do not store video, audio or input.

## Payments

Purchases on the Mac App Store, the iOS App Store and Google Play are processed by Apple or Google under their privacy terms; we receive only the purchase identifiers described above. Direct purchases are processed by Stripe; we never see or store card numbers.

## Windows and third-party software

Windows is downloaded from Microsoft and licensed by Microsoft. Programs you run inside Machines or Bottles have their own privacy policies and may contact their own vendors; MIRRORZ does not intercept or inspect that traffic.

## Your rights

You can request a copy of the data associated with your license, correct it, or ask us to delete it by emailing privacy@mirrorz.app with your license key or purchase receipt. We answer within 30 days. Deleting license data ends the license. Residents of the EU/EEA, UK, California and other jurisdictions with privacy laws have the rights those laws provide, including the right to complain to a supervisory authority. We do not "sell" or "share" personal information as defined by the CCPA/CPRA.

## Children

MIRRORZ is not directed at children under 13 (or the higher age required in your country) and we do not knowingly collect data from them.

## International transfers

Our servers are operated in the United States and the European Union. Where data leaves the EU/UK we rely on Standard Contractual Clauses.

## Changes

We will post changes here and, for material changes, show a notice in the app. We will never add advertising or analytics through a policy change.

## Contact

privacy@mirrorz.app
