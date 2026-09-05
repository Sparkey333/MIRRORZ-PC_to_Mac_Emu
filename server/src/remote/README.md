# `server/src/remote` — MIRRORZ Remote pairing + signaling

Reference implementation of [`docs/spec/remote-protocol.md`](../../../docs/spec/remote-protocol.md) (protocol v1). The server authenticates devices with their `MZL1` license tokens, pairs a companion with a Mac through a 6-symbol single-use code, and relays WebRTC signaling. It never sees pixels or input: video (H.264) and the `mz-input` data channel are peer-to-peer (LAN first, TURN fallback).

| File | Responsibility |
|---|---|
| `protocol.ts` | zod schemas for every inbound message (`offer` `answer` `ice` `apps` `launch` `input` `error` `bye`), the `InputEvent` JSON, query/body schemas, limits, close codes, pairing-code normalization. Source of truth for field limits. |
| `auth.ts` | `RemoteAuth.authenticate(token)`: verifies the Ed25519 signature and expiry, then checks **in the database** that the device is activated, the license is entitled now, and the plan has `mobile-companion`. Issues/verifies stateless `MZP1` reconnect grants (signed with the same key so the Mac can verify them offline). |
| `rooms.ts` | `RoomRegistry`: one room per host device, single-use pairing codes with a 10-minute TTL, atomic redemption, host replacement, room death on host disconnect, per-connection token buckets, message routing (server-stamped `from`, host-only `to`, broadcast `apps`, kick). Transport-agnostic via `PeerSocket`. |
| `ice.ts` | `IceService`: STUN/TURN list from `STUN_URLS` / `TURN_URL` / `TURN_USER` / `TURN_PASS`; when `TURN_SECRET` is set, time-limited TURN REST credentials (`<expiry>:<user>`, base64 HMAC-SHA1) with `TURN_TTL_SECONDS` lifetime. |
| `ws.ts` | Fastify routes: `POST /v1/remote/pairings`, `GET /v1/remote/ice`, `GET /v1/remote/ws` (via `@fastify/websocket`, 64 KiB `maxPayload`), handshake/pairing rate limits, brute-force window for code redemption, 25 s ping keepalive, sweep timer, graceful shutdown (`bye {server_shutdown}` + `4503`). |
| `index.ts` | `createRemote({ licenses, keys, env })` factory used by `main.ts`; re-exports. |
| `remote.test.ts` | End-to-end tests with the `ws` client against `app.listen` on an ephemeral port. |

## Verified here (Linux, Node 22)

* `npm run typecheck` — clean (`tsc --strict`, `noUncheckedIndexedAccess`).
* `npm test` — the pre-existing 28 tests plus 8 remote tests pass:
  * protocol unit tests: pairing-code normalization (`oil-l0o` → `011100`), `InputEvent` per-kind requirements, unknown fields stripped from relayed messages;
  * ICE: HMAC-SHA1 TURN REST credentials match a hand computation; static creds; TURN without creds omitted; env parsing;
  * pairing → host `hello` → client redeems a lowercase/dashed code → `peer-joined` → `offer`/`answer`/`ice` relay with `from` stamped and `to` stripped → `apps` broadcast and targeted → `launch` → `input` fallback → host `error` relay → validation/permission errors (`not_allowed`, `validation` with `ref` echo, `unknown_peer`) → kick (`bye {kicked}`, close `4410`, `peer-left`);
  * single-use codes (`4409 code_used`), unknown (`4404`), malformed (`4400`), host offline (`4404 host_offline`), second code reuses the room, brute-force throttle (`4429` after 5 failures);
  * expiry with a fake clock (`4408 code_expired` at 601 s, a code minted at 599 s still works, pending rooms swept);
  * bad auth: tampered token (`4401`/`401`), missing token, bad role/version (`4400`), trial plan (`403 feature_required`), other device hosting the room (`4403 device_mismatch`), deactivated device (`403 not_activated`), expired token (`4401`);
  * room dies with the host (`bye {host_left}` + `4410`), grant reconnect after the Mac comes back, fresh grant per connection, stolen grant (`4403 device_mismatch`), forged grant (`4401`), newer host replaces older (`bye {replaced}` + `4409`), capacity (`4403 room_full`, unused code survives), oversized frame closes with `1009`, bare host `bye` closes the room;
  * endpoints answer `503 disabled` when `deps.remote` is omitted.

## Not verifiable in this container

* Real WebRTC media (H.264 capture/encode, `mz-input` data channel), Bonjour advertisement and the offline local-signaling fallback live in the macOS/iOS/Android apps (Xcode / Android Studio); the server only relays JSON.
* coturn interop for the time-limited credentials: the username/credential format follows the TURN REST API draft that coturn's `use-auth-secret` implements; run `turnutils_uclient` against a real coturn to confirm the deployment.
* Load behavior behind a load balancer: room state is in-memory and single-node by design — use sticky sessions (or a single signaling node) until a shared store is added.

## Configuration

`REMOTE_MAX_CLIENTS` (8), `REMOTE_GRANT_DAYS` (90), `REMOTE_PUBLIC_WS_URL` (derived from the request when unset), `STUN_URLS` (`stun:stun.mirrorz.app:3478`; empty = none), `TURN_URL`, `TURN_SECRET`, `TURN_USER`, `TURN_PASS`, `TURN_TTL_SECONDS` (21600).

## Privacy

Only device hashes (`sha256(device_id)[:16]`) travel between peers; the server stores nothing about sessions, never logs query strings (tokens and codes travel there), and never logs client IPs (`main.ts` request serializer). No analytics or telemetry.
