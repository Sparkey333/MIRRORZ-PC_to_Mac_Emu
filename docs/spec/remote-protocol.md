# MIRRORZ Remote — pairing + signaling protocol (v1)

_Normative for the macOS app (host), the iOS/Android companions (clients), and the server. Companion to `platform-contracts.md`. Server reference implementation: `server/src/remote/`._

MIRRORZ Remote lets a paired phone/tablet view and control a Mac's Apps and Machines. The media path is WebRTC peer-to-peer (H.264 video, an ordered data channel for input). The server only does three things: **authenticate** devices with their MZL1 license tokens, **pair** a companion with a Mac through a short single-use code, and **relay signaling** (SDP + ICE) between them. It never sees pixels or input.

```
  Mac (host)                       api.mirrorz.app                     Phone (client)
  ──────────                       ───────────────                     ──────────────
  POST /v1/remote/pairings ──────▶ create room + code
             ◀────────────────── { code, room_id, expires_at }
  show QR  mirrorz://pair?code=…
  WS /v1/remote/ws?role=host ────▶ attach host to room
             ◀────────────────── hello
                                                   ◀──── scan QR / type code
                                   redeem code ◀──────── WS /v1/remote/ws?role=client&code=…
                                   (single use)  ──────▶ hello { grant }
             ◀── peer-joined ────
  offer ────────────────────────▶ relay ─────────────────▶ offer
             ◀────────────────── relay ◀───────────────── answer
  ice ◀─────────────────────────▶ relay ◀───────────────▶ ice
  ═══════════════ WebRTC: H.264 video + "mz-input" data channel (LAN direct, TURN fallback) ═══════════════
  apps ─────────────────────────▶ relay ─────────────────▶ apps
             ◀────────────────── relay ◀───────────────── launch { app_id }
```

## 1. Definitions

| Term | Meaning |
|---|---|
| **Host** | The macOS app. Owns a **room**, streams video, receives input. Exactly one per room. |
| **Client** | A companion app (iOS/iPadOS/Android). Joins a room with a pairing **code** or a **grant**. Up to `max_clients` (default 8) per room. |
| **Room** | Server-side rendezvous keyed by the host device. Lives while the host's WebSocket is connected. |
| **Pairing code** | 6 symbols from the license-key alphabet, single use, 10-minute lifetime. |
| **Grant** | A signed `MZP1` credential the server hands a client after a successful code redemption so it can reconnect to the same Mac later without a new code. |
| **Device token** | The `MZL1` license token from `platform-contracts.md` §3.4. Every request in this protocol is authenticated with one. |
| **Device hash** | `sha256(device_id)` hex, first 16 characters. Raw device ids are never sent to other peers. |

## 2. Authentication (all endpoints)

Every endpoint takes a device token. The server:

1. Verifies the Ed25519 signature with its own signing key (`kid` must match) and rejects tokens whose `exp` has passed (the client must `POST /v1/licenses/refresh` first).
2. Loads the license `lid` and checks the device `dev` is **activated** on it (an unrevoked activation row) and that the license is currently **entitled** (`platform-contracts.md` §3.4 rules as computed by the server).
3. Checks the token's `features` contains **`mobile-companion`** (Standard and above; trials cannot use Remote).

Where the token goes:

| Endpoint | How to send the token |
|---|---|
| `POST /v1/remote/pairings` | JSON body field `token` |
| `GET /v1/remote/ice` | `Authorization: Bearer <token>` header (preferred) or `?auth=` query |
| `GET /v1/remote/ws` | `Authorization: Bearer <token>` header (preferred) or `auth=` query |

Native WebSocket clients (`URLSessionWebSocketTask`, OkHttp) can set headers and MUST prefer the header; the query form exists for environments that cannot. The server never logs query strings.

HTTP error codes (`{ error, message }`): `validation` (400), `bad_token` (401), `not_activated` / `expired` / `revoked` / `paused` / `feature_required` (403), `not_found` (404), `rate_limited` (429), `disabled` (503, Remote not configured on this server).

## 3. Pairing

### 3.1 Create a pairing (host)

`POST /v1/remote/pairings` — body `{ "token": "<MZL1>", "name"?: "<host display name ≤ 60>" }`

Response `201`:

```json
{
  "code": "7K3MZP",
  "display": "7K3-MZP",
  "room_id": "room_5Yt0xJ2mQ4aVbP7c",
  "host_hash": "9f2c1a7b3e4d5f60",
  "expires_at": 1800000600,
  "ws_url": "wss://api.mirrorz.app/v1/remote/ws",
  "deep_link": "mirrorz://pair?code=7K3MZP&h=9f2c1a7b3e4d5f60"
}
```

* One **room per host device**. A second `POST` from the same device while its room is alive returns the same `room_id` with a **new** code ("Pair another device"). A `POST` after the room closed creates a fresh room.
* A room created by `POST` but never attached by a host WebSocket is discarded when its last code expires.
* `code`: 6 symbols from the Crockford alphabet `0123456789ABCDEFGHJKMNPQRSTVWXYZ` (30 bits). Displayed as `XXX-XXX`. Input is normalized exactly like license keys: uppercase, strip `- _ .` and whitespace, map `O→0`, `I→1`, `L→1`.
* `expires_at`: Unix seconds, `now + 600`.
* `deep_link` is what the QR code encodes. `h` is the host device hash; companions use it for LAN discovery (§7) and to label the paired Mac. Universal-link form: `https://mirrorz.app/pair?code=…&h=…`.
* Rate limits: 10 per 5 minutes per device, 30 per minute per IP.

### 3.2 Redeem (client)

The companion redeems by opening the WebSocket with `role=client&code=<code>` (§4). Redemption is atomic: the first successful handshake consumes the code; any later attempt with the same code is closed with `4409 code_used`. Expired codes close with `4408 code_expired`. Five failed redemptions from one IP within 10 minutes trigger `4429 rate_limited` (brute force protection: 30 bits × 5 tries).

### 3.3 Grants (reconnect without a code)

After a successful redemption the `hello` message carries `grant`, a stateless credential signed with the server's license signing key:

```
MZP1.<base64url(JSON claims)>.<base64url(Ed25519 signature over UTF-8 "MZP1.<payload>")>
claims: { v:1, kid, host:<host device hash>, dev:<client device id>, lid:<client license id>, iat, exp }
```

* Default lifetime 90 days (`REMOTE_GRANT_DAYS`). Every successful connection returns a fresh grant in `hello`; the client replaces the stored one.
* The client stores grants in the keychain / EncryptedSharedPreferences keyed by `host`.
* To reconnect: `GET /v1/remote/ws?role=client&grant=<MZP1>` (+ auth). The server verifies the signature and expiry, checks `claims.dev == token.dev`, and looks up the live room for `claims.host`. No live room → `4404 host_offline`.
* Revocation is host-side: the host keeps its list of paired devices (Settings › Remote). A device the host has forgotten is dropped on join with `bye { reason: "kicked" }` (host sends `bye { to }` in response to `peer-joined`). The Mac verifies grants offline too (§7.3).

## 4. WebSocket endpoint

`GET /v1/remote/ws` with query parameters:

| Param | Host | Client | Meaning |
|---|---|---|---|
| `role` | `host` | `client` | required |
| `auth` | ✓ | ✓ | MZL1 token (or `Authorization: Bearer` header) |
| `room` | ✓ | — | `room_id` from §3.1; the token's `dev` must be the room's host device |
| `code` | — | one of | pairing code (first connection) |
| `grant` | — | one of | MZP1 grant (reconnect) |
| `v` | opt | opt | protocol version, `1` (default) |
| `name` | opt | opt | display name ≤ 60 chars, shown to the other side |

Behavior:

* The HTTP upgrade always succeeds; authentication and pairing are checked immediately afterwards. On failure the server sends one `error` message and closes with a 4xxx code (§4.2). Clients show `error.message`.
* Host attach: if the room already has a host connection (stale socket after a network blip) the **newer connection wins**; the old one receives `bye { reason: "replaced" }` and close `4409`.
* Client attach requires a **connected** host; otherwise `4404 host_offline`. A room is at most one host + `max_clients` clients (`4403 room_full`).
* When the host socket closes for any reason, the room closes: every client receives `bye { reason: "host_left" }` and close `4410`. Outstanding codes for that room are invalidated. Grants stay valid (they name the host, not the room).
* Keepalive: the server sends a WebSocket **ping every 25 s** and terminates a peer that has not answered by the next ping (≈50 s). Clients need no application-level ping.
* Frame limit: **64 KiB** (65 536 bytes) per message, text frames only. Larger frames close the socket with `1009`. JSON only; binary frames close with `4400`.
* Rate limits per connection (token bucket, burst / sustained): signaling messages (`offer` `answer` `ice` `launch` `bye` `error`) 60 / 20 per s; `apps` 10 / 1 per s; `input` 240 / 120 per s. Exceeding a bucket returns `error { code: "rate_limited" }` for that message (dropped, connection stays open); 200 dropped messages in a row close the socket with `4429`.
* Handshake limit: 20 burst / 12 per minute per IP.

### 4.1 Peer identity

The host's peer id is always `"host"`. Clients get `p_<8 base64url chars>` per connection. A peer descriptor is:

```json
{ "peer_id": "p_Qm3xk9Lz", "role": "client", "device_hash": "4b1e…", "name": "Brandon's iPhone",
  "platform": "ios", "same_license": true }
```

`same_license` is true when the peer's license id equals the host's. The server does not enforce same-license pairing; the host MAY (Settings › Remote › "Only devices on my license").

### 4.2 Close codes

| Code | Meaning | Typical `error.code` |
|---|---|---|
| `1000` | normal close (`bye`) | — |
| `1009` | frame over 64 KiB | `too_large` |
| `4400` | malformed handshake or binary frame | `validation` |
| `4401` | token missing / malformed / bad signature / expired | `bad_token` |
| `4403` | authenticated but not allowed | `not_activated` `expired` `revoked` `paused` `feature_required` `device_mismatch` `room_full` `not_allowed` |
| `4404` | unknown room / code / grant host | `not_found` `host_offline` |
| `4408` | pairing code expired | `code_expired` |
| `4409` | code already used / host replaced | `code_used` `replaced` |
| `4410` | room closed because host left, or kicked | `room_closed` `kicked` |
| `4429` | rate limited | `rate_limited` |
| `4503` | server shutting down | `server_shutdown` |

## 5. Messages

All messages are UTF-8 JSON objects with a string field `t`. Unknown top-level fields are ignored; unknown `t` values are answered with `error { code: "validation" }`. Every message is validated against the zod schemas in `server/src/remote/protocol.ts` (the source of truth for field limits). Peers MAY add `ref` (string ≤ 64) to any message they send; the server echoes it in `error` replies about that message.

Routing: the server stamps `from` (peer id) on every relayed message; peers cannot spoof it. Clients can only talk to the host, so they never set `to`. The host MUST set `to` on `offer`/`answer`/`ice`/`error`, MAY set it on `apps` (omit = broadcast to all clients) and `bye` (omit = close the room).

### 5.1 Server → peer

| `t` | Fields | Notes |
|---|---|---|
| `hello` | `v:1`, `peer_id`, `role`, `room_id`, `host_hash`, `self` (own descriptor), `peers` (host: current clients; client: `[host]`), `grant?` (client only), `ice_servers` (§6, may be `[]`), `limits { max_message_bytes, signal_per_sec, input_per_sec, max_clients, grant_expires_at? }` | First message after a successful handshake. |
| `peer-joined` | `peer` (descriptor) | Host only. |
| `peer-left` | `peer_id`, `reason` (`"bye"` `"closed"` `"timeout"` `"kicked"` `"rate_limited"`) | Host only. |
| `bye` | `reason` (`"host_left"` `"kicked"` `"replaced"` `"room_closed"` `"server_shutdown"`) | Sent right before a server-initiated close. |
| `error` | `code`, `message`, `ref?`, `from?` | `from` present when relayed from the host (§5.2 `error`). |
| relayed | any of §5.2 with `from` added | |

### 5.2 Peer → server (relayed)

| `t` | Direction | Fields |
|---|---|---|
| `offer` | either | `to` (host only), `sdp` (string ≤ 61 440 bytes) |
| `answer` | either | `to` (host only), `sdp` |
| `ice` | either | `to` (host only), `candidate`: `{ candidate, sdpMid?, sdpMLineIndex?, usernameFragment? }` or `null` (end of candidates) |
| `apps` | host → clients | `to?`, `apps: AppEntry[]` (≤ 200), `streaming: <entry id> \| null`, `surface?: { w, h }` (pixel size of the streamed frame) |
| `launch` | client → host | `app_id` (an `AppEntry.id`) |
| `input` | client → host | `evs: InputEvent[]` (1..64). Fallback only; normally on the data channel (§5.4) |
| `error` | host → client | `to`, `code`, `message`, `ref?` — e.g. `launch_failed` answering a `launch` |
| `bye` | either | `to?` (host: kick one client; absent: close the room), `reason?` |

`AppEntry`:

```json
{ "id": "app_autocad-2026", "name": "AutoCAD 2026", "kind": "app", "runtime": "vm",
  "state": "running", "compat_id": "autocad", "machine_id": "vm_win11", "icon": "data:image/png;base64,…" }
```

`kind` ∈ `app` | `machine`; `runtime` ∈ `vm` | `bottle` (absent for machines); `state` ∈ `stopped` | `starting` | `running`; `icon` optional PNG data URI ≤ 8 KiB (omit icons when the list would exceed the 64 KiB frame; clients fall back to a generic glyph). `apps` always carries the **whole** list (replace, not patch). The host sends `apps` on client join, whenever the list or `streaming` changes, and after every `launch`.

`launch { app_id }` means "start it if needed and show it on my stream". The host answers with an updated `apps` (state/streaming changed) or `error { code: "launch_failed" }`. The host's video track always shows the `streaming` target: the App's window in Mirror Mode, or the Machine's display.

### 5.3 Who starts the offer

The **host** creates the `RTCPeerConnection` and sends the `offer` when it receives `peer-joined` (one peer connection per client). The client answers. Both trickle `ice`. On ICE failure the client reconnects the WebSocket (with its grant) and the host re-offers; the host uses ICE restart when a connection drops but the socket is still up.

### 5.4 WebRTC media and data

* **Video**: one `sendonly` track from the host, **H.264** Constrained Baseline or Main, `packetization-mode=1`, 30 fps target, keyframe on request (PLI/FIR handled by the WebRTC stack), 1–8 Mbit/s adaptive, resolution = the streamed surface capped at the client's `max_height` hint. Capture: ScreenCaptureKit (window or display); encode: VideoToolbox hardware. The host sends `surface` so clients can map coordinates before the first frame.
* **Audio**: optional Opus `sendonly` track (system audio of the streamed App/Machine). Off by default.
* **Data channel `mz-input`**: created by the host in the offer, `ordered: true`, reliable (no `maxRetransmits`), `protocol: "mz-input/1"`. Client → host only. Each message is UTF-8 JSON: one `InputEvent` or a JSON array of them (batch `mv` at the client's touch sample rate, coalescing consecutive `mv`). Host → client on this channel: `{ "k": "surface", "w": 2560, "h": 1440 }` when the stream size changes.
* Payload cap on the channel: 16 KiB.

`InputEvent` (all coordinates normalized `0..1` to the streamed surface, origin top-left):

```json
{ "k": "mv"|"dn"|"up"|"sc"|"key"|"txt", "x": 0.5, "y": 0.25, "b": 0, "dx": 0, "dy": -120,
  "code": "KeyA", "mods": 0, "s": "Hello", "t": 123456 }
```

| `k` | Required | Meaning |
|---|---|---|
| `mv` | `x`, `y` | pointer move |
| `dn` / `up` | `x`, `y`, `b` **or** `code` | button/key down and up. With `b`: pointer button `0` left, `1` middle, `2` right, `3` back, `4` forward at `x`,`y`. With `code`: a keyboard key. |
| `sc` | `x`, `y`, `dx`, `dy` | scroll at `x`,`y`; deltas in pixels, positive `dy` scrolls content up (like `WheelEvent.deltaY`). Pinch-zoom is sent as `sc` with `mods` = ctrl (`2`), which zooms in most PC apps including AutoCAD. |
| `key` | `code` | a full press (down + up) — used by on-screen keyboards and shortcut chips |
| `txt` | `s` (≤ 4096 chars) | commit text (IME / dictation / paste) |

`code` uses W3C UI Events `KeyboardEvent.code` values (`KeyA`, `Digit1`, `Enter`, `Escape`, `Space`, `ArrowLeft`, `F5`, …). `mods` is a bitmask: `1` shift, `2` ctrl, `4` alt/option, `8` meta (cmd/win). `t` is an optional client-monotonic millisecond timestamp for ordering diagnostics. Touch on the companion maps to the pointer: tap → `dn`+`up` `b:0`; long-press → `b:2`; drag → `mv`; two-finger pan → `sc`; pinch → `sc` + ctrl. Events with values outside their ranges are dropped by the host.

## 6. ICE servers

`GET /v1/remote/ice` (authenticated, §2) →

```json
{ "iceServers": [ { "urls": ["stun:stun.mirrorz.app:3478"] },
                  { "urls": ["turn:turn.mirrorz.app:3478?transport=udp", "turns:turn.mirrorz.app:5349?transport=tcp"],
                    "username": "1800021600:mirrorz", "credential": "K1s…=" } ],
  "ttl": 21600, "expires_at": 1800021600 }
```

Server environment:

| Variable | Meaning |
|---|---|
| `STUN_URLS` | comma-separated `stun:` URLs (default `stun:stun.mirrorz.app:3478`; empty string = none) |
| `TURN_URL` | comma-separated `turn:`/`turns:` URLs; absent = no TURN entry |
| `TURN_SECRET` | enables **time-limited credentials** (coturn `use-auth-secret` / TURN REST API): `username = "<expiry unix seconds>:<TURN_USER or "mirrorz">"`, `credential = base64(HMAC-SHA1(TURN_SECRET, username))` |
| `TURN_USER` / `TURN_PASS` | static credentials when `TURN_SECRET` is not set (dev only) |
| `TURN_TTL_SECONDS` | lifetime of time-limited credentials (default 21 600 = 6 h) |

The same list is included in `hello.ice_servers`; clients refresh via `GET /v1/remote/ice` when `expires_at` is within 10 minutes. `iceTransportPolicy` is `all`; LAN host candidates naturally win over relay.

## 7. LAN-first and offline mode

### 7.1 Bonjour advertisement (host)

While hosting, the Mac advertises `_mirrorz._tcp` (via `NWListener` with a `NWListener.Service`) with instance name `MIRRORZ on <computer name>` and TXT records:

| Key | Value |
|---|---|
| `v` | `1` |
| `h` | host device hash (16 hex) |
| `room` | current server `room_id`, or `-` when offline |
| `fp` | SHA-256 fingerprint (hex) of the local TLS certificate (§7.3) |
| `n` | display name ≤ 60 |

The SRV record carries the local signaling port. Companions browse with `NWBrowser` (Apple) / `NsdManager` (Android, `_mirrorz._tcp.`) and match `h` against `deep_link.h` or their stored grants. A match means "the Mac is on this network": show the *On your network* chip, and prefer LAN candidates. Signaling still goes through the server whenever the server is reachable.

### 7.2 Offline fallback (local signaling)

When `api.mirrorz.app` is unreachable from the companion (or the Mac is offline — the Mac keeps advertising with `room=-`), the companion connects to the Mac directly:

`wss://<bonjour host>:<port>/v1/remote/ws?role=client&auth=<MZL1>&code=<local code>|grant=<MZP1>`

* The Mac runs the same WebSocket endpoint locally with the **same message set and close codes**; it is the server for its own room (`room_id` = `local`). `hello.ice_servers` is `[]`.
* Local pairing codes are generated by the Mac with the same alphabet, shown in the same QR (`deep_link` with `h`), single use, 10 minutes. The Mac does not issue grants offline; an existing server grant is accepted (§7.3).
* No rate limits beyond the 64 KiB frame cap and input rate; the LAN is trusted only after authentication.

### 7.3 Local security

* TLS with a self-signed certificate generated once per Mac and stored in the keychain; its SHA-256 fingerprint is `fp` in TXT and the companion **pins** it (`sec_protocol_options_set_verify_block` / OkHttp `CertificatePinner`). The companion also stores `fp` next to the grant and refuses a changed fingerprint until the user re-pairs.
* The Mac verifies the companion's `MZL1` token with the embedded public keys (`platform-contracts.md` §3.4 rule 1), requires `mobile-companion`, and verifies an `MZP1` grant the same way, additionally requiring `grant.host == own device hash` and `grant.dev == token.dev`.
* A device the Mac has forgotten is refused with `4410 kicked` even with a valid grant.

## 8. Security summary

* Pairing codes: 30 bits, single use (atomic redeem), 10-minute expiry, 5 failed attempts per IP per 10 minutes, then `4429`.
* Every socket is bound to an activated, entitled device; tokens are verified server-side on every connect (never cached).
* Rooms die with the host; clients cannot outlive the host or talk to each other; `from` is server-stamped; `to` is host-only.
* All inbound messages are validated with zod before any relay; frames over 64 KiB are dropped at the transport; per-message rate limits; no message is persisted.
* No raw device ids on the wire between peers (hashes only); no IPs stored; nothing about sessions is logged beyond counts (telemetry is off by default and this protocol adds none).
* TURN credentials are short-lived HMAC credentials issued only to authenticated devices.

## 9. Sequence: happy path

```
Host                              Server                              Client
POST /v1/remote/pairings ───────▶
        ◀─────────────────────── 201 { code, room_id, deep_link }
WS ?role=host&room=…&auth=… ────▶
        ◀─────────────────────── hello { peers: [] }
                                         ◀─────────── WS ?role=client&code=…&auth=…
                                  redeem code (single use)
                                         ───────────▶ hello { peers:[host], grant, ice_servers }
        ◀─────────────────────── peer-joined { peer }
apps { to } ────────────────────▶ ─────────────────▶ apps
offer { to, sdp } ──────────────▶ ─────────────────▶ offer { from:"host", sdp }
        ◀─────────────────────── ◀───────────────── answer { sdp }
ice { to } ◀────────────────────▶ ◀───────────────▶ ice
                     ═══ H.264 video ▶   ◀ mz-input JSON events ═══
        ◀─────────────────────── ◀───────────────── launch { app_id }
apps { to, streaming } ─────────▶ ─────────────────▶ apps
bye ────────────────────────────▶ ─────────────────▶ bye { reason:"host_left" } + close 4410
```

## 10. Versioning

`v=1`. Additive changes (new optional fields, new `error.code` values, new `AppEntry.kind` values) do not bump the version; clients ignore unknown fields and treat unknown enum values as their nearest default. Breaking changes bump `v` and the server accepts both for one release cycle.
