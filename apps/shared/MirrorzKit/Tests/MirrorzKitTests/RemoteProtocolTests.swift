// RemoteProtocolTests.swift
// docs/spec/remote-protocol.md: message round-trips, wire keys, input events, pairing codes
// and links, grants, handshake URLs, close codes, ICE and Bonjour.

import CryptoKit
import XCTest
@testable import MirrorzKit

final class RemoteProtocolTests: XCTestCase {
    private let host = PeerDescriptor(peerID: "host", role: .host, deviceHash: "9f2c1a7b3e4d5f60", name: "Studio", platform: "macos", sameLicense: true)
    private let client = PeerDescriptor(peerID: "p_Qm3xk9Lz", role: .client, deviceHash: "4b1e0f9a8c7d6e5f", name: "Brandon's iPhone", platform: "ios", sameLicense: true)

    private func samples() -> [(RemoteMessage, RemoteMessageType)] {
        let ice = [ICEServer(urls: ["stun:stun.mirrorz.app:3478"]), ICEServer(urls: ["turn:turn.mirrorz.app:3478?transport=udp", "turns:turn.mirrorz.app:5349?transport=tcp"], username: "1800021600:mirrorz", credential: "K1s=")]
        let limits = RemoteLimits(maxMessageBytes: 65_536, signalPerSec: 20, inputPerSec: 120, maxClients: 8, grantExpiresAt: 1_807_776_000)
        let apps = [
            AppEntry(id: "app_autocad-2026", name: "AutoCAD 2026", kind: .app, runtime: .vm, state: .running, compatID: "autocad", machineID: "vm_win11", icon: "data:image/png;base64,iVBORw0KGgo="),
            AppEntry(id: "vm_win11", name: "Windows 11", kind: .machine, state: .running),
        ]
        return [
            (.hello(HelloMessage(peerID: "p_Qm3xk9Lz", role: .client, roomID: "room_5Yt0xJ2mQ4aVbP7c", hostHash: host.deviceHash, selfDescriptor: client, peers: [host], grant: "MZP1.e30.c2ln", iceServers: ice, limits: limits)), .hello),
            (.peerJoined(PeerJoinedMessage(peer: client)), .peerJoined),
            (.peerLeft(PeerLeftMessage(peerID: client.peerID, reason: .timeout)), .peerLeft),
            (.offer(SessionDescriptionMessage(to: client.peerID, from: "host", ref: "o1", sdp: "v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\n")), .offer),
            (.answer(SessionDescriptionMessage(from: client.peerID, sdp: "v=0\r\n")), .answer),
            (.ice(ICEMessage(to: client.peerID, from: "host", candidate: ICECandidate(candidate: "candidate:1 1 UDP 2122252543 192.168.1.10 51000 typ host", sdpMid: "0", sdpMLineIndex: 0, usernameFragment: "abcd"))), .ice),
            (.apps(AppsMessage(to: client.peerID, from: "host", apps: apps, streaming: "app_autocad-2026", surface: StreamSurface(w: 2560, h: 1440))), .apps),
            (.launch(LaunchMessage(appID: "app_autocad-2026", from: client.peerID, ref: "l1")), .launch),
            (.input(InputMessage(evs: [.move(x: 0.5, y: 0.25), .pointerDown(x: 0.5, y: 0.25), .pointerUp(x: 0.5, y: 0.25)], from: client.peerID)), .input),
            (.error(ErrorMessage(to: client.peerID, from: "host", ref: "l1", code: .launchFailed, message: "AutoCAD is still starting")), .error),
            (.bye(ByeMessage(reason: .hostLeft)), .bye),
        ]
    }

    // MARK: Messages

    func testEveryMessageTypeRoundTrips() throws {
        var covered: Set<RemoteMessageType> = []
        for (message, type) in samples() {
            let data = try RemoteCodec.encode(message)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], "\(type)")
            XCTAssertEqual(object["t"] as? String, type.rawValue)
            let decoded = try RemoteCodec.decode(data)
            XCTAssertEqual(decoded, message, "\(type)")
            XCTAssertEqual(decoded.type, type)
            let text = try RemoteCodec.encodeText(message)
            XCTAssertEqual(try RemoteCodec.decode(text: text), message)
            covered.insert(type)
        }
        XCTAssertEqual(covered, Set(RemoteMessageType.allCases))
    }

    func testHelloWireKeys() throws {
        let hello = samples()[0].0
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: try RemoteCodec.encode(hello)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["t", "v", "peer_id", "role", "room_id", "host_hash", "self", "peers", "grant", "ice_servers", "limits"])
        let selfDescriptor = try XCTUnwrap(object["self"] as? [String: Any])
        XCTAssertEqual(Set(selfDescriptor.keys), ["peer_id", "role", "device_hash", "name", "platform", "same_license"])
        let limits = try XCTUnwrap(object["limits"] as? [String: Any])
        XCTAssertEqual(limits["max_message_bytes"] as? Int, 65_536)
        XCTAssertEqual(limits["grant_expires_at"] as? Int, 1_807_776_000)
        let servers = try XCTUnwrap(object["ice_servers"] as? [[String: Any]])
        XCTAssertEqual(servers.count, 2)
        XCTAssertEqual(servers[1]["username"] as? String, "1800021600:mirrorz")
        if case .hello(let message) = hello {
            XCTAssertEqual(message.host?.peerID, "host")
        } else {
            XCTFail("expected hello")
        }
    }

    func testAppsEncodesStreamingNullAndSnakeCase() throws {
        let message = RemoteMessage.apps(AppsMessage(apps: [AppEntry(id: "a", name: "A", kind: .app, runtime: .bottle)], streaming: nil))
        let json = try XCTUnwrap(String(data: try RemoteCodec.encode(message), encoding: .utf8))
        XCTAssertTrue(json.contains(#""streaming":null"#), json)
        XCTAssertFalse(json.contains("\"to\""))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let apps = try XCTUnwrap(object["apps"] as? [[String: Any]])
        XCTAssertEqual(apps[0]["runtime"] as? String, "bottle")
        XCTAssertEqual(apps[0]["state"] as? String, "stopped")
        XCTAssertNil(apps[0]["compat_id"])

        let decoded = try RemoteCodec.decode(text: #"{"t":"apps","from":"host","apps":[{"id":"app_1","name":"X","kind":"app","runtime":"vm","state":"running","compat_id":"autocad","machine_id":"vm_win11"}],"streaming":"app_1","surface":{"w":1920,"h":1080}}"#)
        guard case .apps(let apps2) = decoded else { return XCTFail("expected apps") }
        XCTAssertEqual(apps2.from, "host")
        XCTAssertEqual(apps2.streamingEntry?.compatID, "autocad")
        XCTAssertEqual(apps2.surface, StreamSurface(w: 1920, h: 1080))
        XCTAssertEqual(decoded.from, "host")
    }

    func testUnknownEnumValuesFallBackToDefaults() throws {
        let decoded = try RemoteCodec.decode(text: #"{"t":"apps","apps":[{"id":"x","name":"X","kind":"widget","runtime":"cloud","state":"exploding"}],"streaming":null}"#)
        guard case .apps(let apps) = decoded else { return XCTFail("expected apps") }
        XCTAssertEqual(apps.apps[0].kind, .app)
        XCTAssertNil(apps.apps[0].runtime)
        XCTAssertEqual(apps.apps[0].state, .stopped)
        XCTAssertNil(apps.streaming)
    }

    func testIceEndOfCandidatesIsNull() throws {
        let message = RemoteMessage.ice(ICEMessage(to: "p_1", candidate: nil))
        let json = try XCTUnwrap(String(data: try RemoteCodec.encode(message), encoding: .utf8))
        XCTAssertTrue(json.contains(#""candidate":null"#), json)
        let decoded = try RemoteCodec.decode(text: json)
        guard case .ice(let ice) = decoded else { return XCTFail("expected ice") }
        XCTAssertTrue(ice.isEndOfCandidates)
        XCTAssertEqual(ice.to, "p_1")
    }

    func testUnknownFieldsAreIgnoredAndUnknownTypeFails() throws {
        let message = try RemoteCodec.decode(text: #"{"t":"launch","app_id":"app_1","from":"p_1","future":{"x":1}}"#)
        XCTAssertEqual(message, .launch(LaunchMessage(appID: "app_1", from: "p_1")))
        XCTAssertThrowsError(try RemoteCodec.decode(text: #"{"t":"teleport"}"#)) { error in
            XCTAssertEqual(error as? RemoteCodecError, .unknownType("teleport"))
        }
    }

    func testFrameLimitAndIconFallback() throws {
        let icon = "data:image/png;base64," + String(repeating: "A", count: 8000)
        let entries = (0..<200).map { AppEntry(id: "app_\($0)", name: "App \($0)", kind: .app, runtime: .vm, icon: icon) }
        let apps = AppsMessage(apps: entries)
        XCTAssertThrowsError(try RemoteCodec.encode(.apps(apps))) { error in
            guard case .tooLarge? = error as? RemoteCodecError else { return XCTFail("expected tooLarge, got \(error)") }
        }
        let data = try RemoteCodec.encodeApps(apps)
        XCTAssertLessThanOrEqual(data.count, RemoteProtocol.maxMessageBytes)
        guard case .apps(let decoded) = try RemoteCodec.decode(data) else { return XCTFail("expected apps") }
        XCTAssertEqual(decoded.apps.count, 200)
        XCTAssertNil(decoded.apps[0].icon)
        XCTAssertEqual(AppsMessage(apps: entries + entries).apps.count, RemoteProtocol.maxAppEntries)
    }

    func testMessageClassification() {
        XCTAssertTrue(RemoteMessage.launch(LaunchMessage(appID: "a")).isClientSendable)
        XCTAssertFalse(RemoteMessage.apps(AppsMessage(apps: [])).isClientSendable)
        XCTAssertTrue(RemoteMessage.bye(ByeMessage()).isSignaling)
        XCTAssertFalse(RemoteMessage.input(InputMessage(evs: [])).isSignaling)
        XCTAssertEqual(InputMessage(evs: Array(repeating: .move(x: 0, y: 0), count: 100)).evs.count, 64)
    }

    // MARK: Input events (§5.4)

    func testInputEventWireFormat() throws {
        let move = try InputChannelCodec.encode([.move(x: 0.5, y: 0.25)])
        XCTAssertEqual(String(data: move, encoding: .utf8), #"{"k":"mv","x":0.5,"y":0.25}"#)
        let down = try InputChannelCodec.encode([.pointerDown(x: 0.5, y: 0.25, button: .right)])
        XCTAssertEqual(String(data: down, encoding: .utf8), #"{"b":2,"k":"dn","x":0.5,"y":0.25}"#)
        let key = try InputChannelCodec.encode([.keyPress("KeyA", mods: [.control, .shift])])
        XCTAssertEqual(String(data: key, encoding: .utf8), #"{"code":"KeyA","k":"key","mods":3}"#)
        let pinch = try InputChannelCodec.encode([.pinch(x: 0.5, y: 0.5, dy: -120)])
        XCTAssertEqual(String(data: pinch, encoding: .utf8), #"{"dx":0,"dy":-120,"k":"sc","mods":2,"x":0.5,"y":0.5}"#)
        let text = try InputChannelCodec.encode([.text("Hello", t: 123_456)])
        XCTAssertEqual(String(data: text, encoding: .utf8), #"{"k":"txt","s":"Hello","t":123456}"#)
    }

    func testInputChannelBatchesAndSurface() throws {
        let events: [InputEvent] = [.move(x: 0.1, y: 0.1), .move(x: 0.2, y: 0.2), .pointerDown(x: 0.2, y: 0.2)]
        let batch = try InputChannelCodec.encode(events)
        XCTAssertEqual(batch.first, UInt8(ascii: "["))
        XCTAssertEqual(try InputChannelCodec.decode(batch), .events(events))

        let single = try InputChannelCodec.decode(Data(#"{"k":"up","x":0.2,"y":0.2,"b":0}"#.utf8))
        XCTAssertEqual(single, .events([.pointerUp(x: 0.2, y: 0.2)]))

        let surface = try InputChannelCodec.encode(surface: StreamSurface(w: 2560, h: 1440))
        XCTAssertEqual(String(data: surface, encoding: .utf8), #"{"h":1440,"k":"surface","w":2560}"#)
        XCTAssertEqual(try InputChannelCodec.decode(surface), .surface(StreamSurface(w: 2560, h: 1440)))

        XCTAssertEqual(InputChannelCodec.coalescingMoves(events).count, 2)
        XCTAssertThrowsError(try InputChannelCodec.encode([.text(String(repeating: "x", count: 4096))] + Array(repeating: .text(String(repeating: "y", count: 4096)), count: 4)))
    }

    func testInputEventValidation() {
        XCTAssertTrue(InputEvent.move(x: 0, y: 1).isValid)
        XCTAssertFalse(InputEvent.move(x: 1.5, y: 0).isValid)
        XCTAssertTrue(InputEvent.pointerDown(x: 0.5, y: 0.5, button: .forward).isValid)
        XCTAssertFalse(InputEvent(k: .down, x: 0.5, y: 0.5, b: 7).isValid)
        XCTAssertTrue(InputEvent.keyDown("Enter").isValid)
        XCTAssertFalse(InputEvent(k: .down).isValid)
        XCTAssertTrue(InputEvent.scroll(x: 0.5, y: 0.5, dx: 0, dy: -120).isValid)
        XCTAssertFalse(InputEvent(k: .scroll, x: 0.5, y: 0.5).isValid)
        XCTAssertTrue(InputEvent.text("hi").isValid)
        XCTAssertFalse(InputEvent(k: .text, s: "").isValid)
        XCTAssertEqual(InputEvent.text(String(repeating: "x", count: 5000)).s?.count, 4096)
        XCTAssertEqual(InputEvent.pointerDown(x: 0, y: 0, button: .middle).button, .middle)
    }

    // MARK: Pairing (§3)

    func testPairingCodeNormalization() {
        XCTAssertEqual(PairingCode.normalize("7K3-MZP"), "7K3MZP")
        XCTAssertEqual(PairingCode.normalize(" 7k3 mzp "), "7K3MZP")
        XCTAssertEqual(PairingCode.normalize("ol1.i_l"), "011111")
        XCTAssertEqual(PairingCode.normalize("MZ3MZP"), "MZ3MZP", "no prefix stripping for pairing codes")
        XCTAssertNil(PairingCode.normalize("7K3MZ"))
        XCTAssertNil(PairingCode.normalize("7K3MZPX"))
        XCTAssertNil(PairingCode.normalize("7K3MZU"))
        XCTAssertEqual(PairingCode.display("7K3MZP"), "7K3-MZP")
        for _ in 0..<50 {
            let code = PairingCode.generate()
            XCTAssertEqual(code.count, 6)
            XCTAssertEqual(PairingCode.normalize(code), code)
        }
    }

    func testPairingLinks() throws {
        let link = PairingLink(code: "7K3MZP", hostHash: "9f2c1a7b3e4d5f60")
        XCTAssertEqual(link.deepLink?.absoluteString, "mirrorz://pair?code=7K3MZP&h=9f2c1a7b3e4d5f60")
        XCTAssertEqual(link.universalLink?.absoluteString, "https://mirrorz.app/pair?code=7K3MZP&h=9f2c1a7b3e4d5f60")
        XCTAssertEqual(PairingLink(url: try XCTUnwrap(link.deepLink)), link)
        XCTAssertEqual(PairingLink(url: try XCTUnwrap(link.universalLink)), link)
        XCTAssertEqual(PairingLink(url: URL(string: "mirrorz://pair?code=7k3-mzp")!), PairingLink(code: "7K3MZP"))
        XCTAssertNil(PairingLink(url: URL(string: "mirrorz://pair?code=BAD")!))
        XCTAssertNil(PairingLink(url: URL(string: "https://example.com/pair?code=7K3MZP")!))
        XCTAssertNil(PairingLink(url: URL(string: "mirrorz://activate?key=MZ-1")!))
    }

    func testPairingResponseDecodes() throws {
        let json = #"{"code":"7K3MZP","display":"7K3-MZP","room_id":"room_5Yt0xJ2mQ4aVbP7c","host_hash":"9f2c1a7b3e4d5f60","expires_at":1800000600,"ws_url":"wss://api.mirrorz.app/v1/remote/ws","deep_link":"mirrorz://pair?code=7K3MZP&h=9f2c1a7b3e4d5f60"}"#
        let response = try JSONDecoder().decode(PairingResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.link, PairingLink(code: "7K3MZP", hostHash: "9f2c1a7b3e4d5f60"))
        XCTAssertEqual(response.webSocketURL?.host, "api.mirrorz.app")
        XCTAssertFalse(response.isExpired(at: Date(timeIntervalSince1970: 1_800_000_000)))
        XCTAssertTrue(response.isExpired(at: Date(timeIntervalSince1970: 1_800_000_600)))
        XCTAssertEqual(try JSONDecoder().decode(PairingResponse.self, from: try JSONEncoder().encode(response)), response)
    }

    func testRemoteClientCreatesPairingAndFetchesICE() async throws {
        let transport = FakeTransport { request in
            switch (request.httpMethod, request.url?.path) {
            case ("POST", "/v1/remote/pairings"):
                let body = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any])
                XCTAssertEqual(body["token"] as? String, "MZL1.a.b")
                XCTAssertEqual((body["name"] as? String)?.count, 60)
                return FakeTransport.raw(#"{"code":"7K3MZP","display":"7K3-MZP","room_id":"room_1","host_hash":"9f2c1a7b3e4d5f60","expires_at":1800000600,"ws_url":"wss://api.mirrorz.app/v1/remote/ws","deep_link":"mirrorz://pair?code=7K3MZP&h=9f2c1a7b3e4d5f60"}"#, status: 201)
            case ("GET", "/v1/remote/ice"):
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer MZL1.a.b")
                XCTAssertFalse(request.url?.query?.contains("auth") ?? false)
                return FakeTransport.raw(#"{"iceServers":[{"urls":["stun:stun.mirrorz.app:3478"]}],"ttl":21600,"expires_at":1800021600}"#)
            default:
                return FakeTransport.error(status: 404, code: "not_found")
            }
        }
        let client = RemoteClient(configuration: .init(baseURL: URL(string: "http://localhost:8787")!, userAgent: "MIRRORZ/1.0.0 (macos)"), transport: transport)
        let pairing = try await client.createPairing(token: "MZL1.a.b", name: String(repeating: "n", count: 80))
        XCTAssertEqual(pairing.roomID, "room_1")
        let ice = try await client.iceServers(token: "MZL1.a.b")
        XCTAssertEqual(ice.iceServers.first?.urls, ["stun:stun.mirrorz.app:3478"])
        XCTAssertFalse(ice.needsRefresh(at: Date(timeIntervalSince1970: 1_800_000_000)))
        XCTAssertTrue(ice.needsRefresh(at: Date(timeIntervalSince1970: 1_800_021_100)))
    }

    func testFeatureRequiredErrorSurfaces() async {
        let transport = FakeTransport { _ in FakeTransport.error(status: 403, code: "feature_required", message: "mobile-companion required") }
        let client = RemoteClient(configuration: .init(baseURL: URL(string: "http://localhost:8787")!, userAgent: "MIRRORZ/1.0.0 (ios)"), transport: transport)
        do {
            _ = try await client.iceServers(token: "MZL1.a.b")
            XCTFail("expected feature_required")
        } catch let error as APIClientError {
            XCTAssertEqual(error.apiError?.code, .featureRequired)
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    // MARK: Handshake (§4)

    func testSocketRequestURLs() {
        let base = URL(string: "https://api.mirrorz.app")!
        let hostRequest = RemoteSocketRequest.host(token: "MZL1.a.b", room: "room_1", name: "Studio")
        XCTAssertEqual(hostRequest.url(base: base).absoluteString, "wss://api.mirrorz.app/v1/remote/ws?role=host&room=room_1&name=Studio")
        XCTAssertEqual(hostRequest.url(base: base, authInQuery: true).absoluteString, "wss://api.mirrorz.app/v1/remote/ws?role=host&room=room_1&name=Studio&auth=MZL1.a.b")

        let codeRequest = RemoteSocketRequest.client(token: "MZL1.a.b", code: "7K3MZP")
        XCTAssertEqual(codeRequest.url(base: URL(string: "http://localhost:8787")!).absoluteString, "ws://localhost:8787/v1/remote/ws?role=client&code=7K3MZP")

        let grantRequest = RemoteSocketRequest.client(token: "MZL1.a.b", grant: "MZP1.x.y", name: String(repeating: "n", count: 70))
        let request = grantRequest.urlRequest(base: base, userAgent: "MIRRORZ/1.0.0 (ios)")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer MZL1.a.b")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "MIRRORZ/1.0.0 (ios)")
        XCTAssertEqual(request.url?.query?.contains("grant=MZP1.x.y"), true)
        XCTAssertEqual(request.url?.query?.contains("auth="), false)
        XCTAssertEqual(grantRequest.name?.count, 60)

        let local = RemoteSocketRequest.client(token: "MZL1.a.b", code: "7K3MZP", name: nil)
        XCTAssertEqual(local.url(base: URL(string: "wss://studio.local:47800")!).absoluteString, "wss://studio.local:47800/v1/remote/ws?role=client&code=7K3MZP")
    }

    func testCloseCodes() {
        XCTAssertEqual(RemoteCloseCode(rawValue: 4409), .conflict)
        XCTAssertEqual(RemoteCloseCode(rawValue: 4410), .roomClosed)
        XCTAssertNil(RemoteCloseCode(rawValue: 4444))
        XCTAssertTrue(RemoteCloseCode.notFound.isTransient)
        XCTAssertFalse(RemoteCloseCode.badToken.isTransient)
        XCTAssertEqual(Set(RemoteCloseCode.allCases.map(\.rawValue)), [1000, 1009, 4400, 4401, 4403, 4404, 4408, 4409, 4410, 4429, 4503])
    }

    func testReasonCodesKeepUnknownValues() throws {
        let bye = try RemoteCodec.decode(text: #"{"t":"bye","reason":"maintenance"}"#)
        XCTAssertEqual(bye, .bye(ByeMessage(reason: ByeReason(rawValue: "maintenance"))))
        let error = try RemoteCodec.decode(text: #"{"t":"error","code":"rate_limited","message":"slow down","ref":"i9"}"#)
        XCTAssertEqual(error, .error(ErrorMessage(ref: "i9", code: .rateLimited, message: "slow down")))
    }

    // MARK: Grants (§3.3, §7.3)

    func testGrantVerification() throws {
        let signer = Curve25519.Signing.PrivateKey()
        let trusted = TrustedKey(kid: "k1", x: Base64URL.encode(signer.publicKey.rawRepresentation))
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let claims = RemoteGrantClaims(kid: "k1", host: "9f2c1a7b3e4d5f60", dev: "device-fixture-0001", lid: "lic_sub", iat: 1_800_000_000, exp: 1_800_000_000 + 90 * 86_400)
        let payload = Base64URL.encode(try JSONEncoder().encode(claims))
        let signature = try signer.signature(for: RemoteGrant.signingInput(payload: payload))
        let grant = "MZP1.\(payload).\(Base64URL.encode(signature))"

        let verified = try RemoteGrant.verify(grant, trustedKeys: [trusted], hostHash: "9f2c1a7b3e4d5f60", deviceID: "device-fixture-0001", now: now)
        XCTAssertEqual(verified, claims)
        XCTAssertEqual(try RemoteGrant.decodeUnverified(grant).lid, "lic_sub")

        func expect(_ error: RemoteGrantError, _ body: () throws -> RemoteGrantClaims, line: UInt = #line) {
            XCTAssertThrowsError(try body(), line: line) { XCTAssertEqual($0 as? RemoteGrantError, error, line: line) }
        }
        expect(.hostMismatch) { try RemoteGrant.verify(grant, trustedKeys: [trusted], hostHash: "other", deviceID: nil, now: now) }
        expect(.deviceMismatch) { try RemoteGrant.verify(grant, trustedKeys: [trusted], hostHash: nil, deviceID: "device-other", now: now) }
        expect(.expired) { try RemoteGrant.verify(grant, trustedKeys: [trusted], hostHash: nil, deviceID: nil, now: now.addingTimeInterval(91 * 86_400)) }
        expect(.unknownKid("k1")) { try RemoteGrant.verify(grant, trustedKeys: [], hostHash: nil, deviceID: nil, now: now) }
        let other = TrustedKey(kid: "k1", x: Base64URL.encode(Curve25519.Signing.PrivateKey().publicKey.rawRepresentation))
        expect(.badSignature) { try RemoteGrant.verify(grant, trustedKeys: [other], hostHash: nil, deviceID: nil, now: now) }
        expect(.malformed) { try RemoteGrant.verify("MZL1.\(payload).\(Base64URL.encode(signature))", trustedKeys: [trusted], hostHash: nil, deviceID: nil, now: now) }
        expect(.malformed) { try RemoteGrant.verify("MZP1.abc", trustedKeys: [trusted], hostHash: nil, deviceID: nil, now: now) }

        // A license token is not a grant (and vice versa): the signing prefix differs.
        let asLicense = "MZL1.\(payload).\(Base64URL.encode(signature))"
        XCTAssertThrowsError(try LicenseToken.verify(asLicense, trustedKeys: [trusted], deviceID: nil))
    }

    // MARK: Identity and discovery (§1, §7.1)

    func testDeviceHash() {
        XCTAssertEqual(RemoteProtocol.deviceHash("device-fixture-0001"), "17d4b8a5c4e1b0f8")
        XCTAssertEqual(RemoteProtocol.deviceHash("device-fixture-0001").count, 16)
    }

    func testBonjourTXTRecord() {
        let advertisement = BonjourAdvertisement(hostHash: "9f2c1a7b3e4d5f60", roomID: nil, certificateFingerprint: "ab12", name: "Studio")
        XCTAssertEqual(advertisement.txtRecord, ["v": "1", "h": "9f2c1a7b3e4d5f60", "room": "-", "fp": "ab12", "n": "Studio"])
        XCTAssertFalse(advertisement.isOnline)
        let parsed = BonjourAdvertisement(txtRecord: ["v": "1", "h": "9f2c1a7b3e4d5f60", "room": "room_1", "fp": "ab12", "n": "Studio"])
        XCTAssertEqual(parsed?.roomID, "room_1")
        XCTAssertEqual(parsed?.isOnline, true)
        XCTAssertNil(BonjourAdvertisement(txtRecord: ["v": "1"]))
        XCTAssertEqual(RemoteProtocol.bonjourInstanceName(computerName: "Studio"), "MIRRORZ on Studio")
        XCTAssertEqual(RemoteProtocol.bonjourServiceType, "_mirrorz._tcp")
    }
}
