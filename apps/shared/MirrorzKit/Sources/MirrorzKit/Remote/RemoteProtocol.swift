// RemoteProtocol.swift
// Codable implementation of docs/spec/remote-protocol.md (v1): pairing codes and deep links
// (§3), MZP1 grants (§3.3, §7.3), the WebSocket handshake (§4) and close codes (§4.2), the
// `t`-keyed signaling messages (§5), the `mz-input` data-channel events (§5.4), ICE servers
// (§6) and the Bonjour TXT record (§7.1). Field limits mirror server/src/remote/protocol.ts.

import CryptoKit
import Foundation

public enum RemoteProtocol {
    public static let version = 1
    public static let bonjourServiceType = "_mirrorz._tcp"
    public static let dataChannelLabel = "mz-input"
    public static let dataChannelProtocol = "mz-input/1"
    public static let hostPeerID = "host"
    public static let localRoomID = "local"
    public static let grantPrefix = "MZP1"

    // Limits (§3.1, §4, §5)
    public static let pairingCodeLength = 6
    public static let pairingCodeLifetime: TimeInterval = 600
    public static let maxMessageBytes = 65_536
    public static let maxDataChannelBytes = 16_384
    public static let maxSDPBytes = 61_440
    public static let maxAppEntries = 200
    public static let maxInputEventsPerMessage = 64
    public static let maxTextInputLength = 4096
    public static let maxNameLength = 60
    public static let maxRefLength = 64
    public static let maxIconBytes = 8192
    public static let defaultMaxClients = 8
    public static let defaultGrantDays = 90
    public static let serverPingInterval: TimeInterval = 25
    /// Clients refresh ICE servers when `expires_at` is within this window (§6).
    public static let iceRefreshLeadTime: TimeInterval = 600

    /// Device hash (§1): `sha256(device_id)` hex, first 16 characters. Raw device ids never
    /// travel between peers.
    public static func deviceHash(_ deviceID: String) -> String {
        String(DeviceIdentity.sha256Hex(deviceID).prefix(16))
    }

    /// Bonjour instance name (§7.1).
    public static func bonjourInstanceName(computerName: String) -> String {
        "MIRRORZ on \(computerName)"
    }
}

/// Per-connection token buckets (§4), as (burst, sustained per second) unless noted.
public enum RemoteRateLimits {
    public static let signalingBurst = 60
    public static let signalingPerSecond = 20
    public static let appsBurst = 10
    public static let appsPerSecond = 1
    public static let inputBurst = 240
    public static let inputPerSecond = 120
    public static let handshakeBurstPerIP = 20
    public static let handshakePerMinutePerIP = 12
    public static let failedRedemptionsPer10MinutesPerIP = 5
    public static let pairingsPer5MinutesPerDevice = 10
    public static let pairingsPerMinutePerIP = 30
    /// Consecutive dropped messages that close the socket with 4429.
    public static let droppedMessagesBeforeClose = 200
}

public enum PeerRole: String, Codable, Hashable, Sendable {
    case host
    case client
}

// MARK: - Pairing codes and links (§3.1)

public enum PairingCode {
    /// Normalizes typed input like license keys (§3.1): uppercase, strip `- _ .` and whitespace,
    /// map O→0 and I/L→1. Returns nil unless exactly six alphabet symbols remain.
    public static func normalize(_ input: String) -> String? {
        var symbols = ""
        for character in input.uppercased() {
            if character.isWhitespace || character == "-" || character == "_" || character == "." { continue }
            switch character {
            case "O": symbols.append("0")
            case "I", "L": symbols.append("1")
            default: symbols.append(character)
            }
        }
        guard symbols.count == RemoteProtocol.pairingCodeLength,
              symbols.allSatisfy({ LicenseKey.alphabet.contains($0) }) else { return nil }
        return symbols
    }

    /// `XXX-XXX` display form.
    public static func display(_ code: String) -> String {
        guard code.count == RemoteProtocol.pairingCodeLength else { return code }
        return "\(code.prefix(3))-\(code.suffix(3))"
    }

    /// Generates a code from the Crockford alphabet (host offline mode, §7.2).
    public static func generate<G: RandomNumberGenerator>(using generator: inout G) -> String {
        let symbols = Array(LicenseKey.alphabet)
        return String((0..<RemoteProtocol.pairingCodeLength).map { _ in symbols[Int.random(in: 0..<symbols.count, using: &generator)] })
    }

    public static func generate() -> String {
        var generator = SystemRandomNumberGenerator()
        return generate(using: &generator)
    }
}

/// `mirrorz://pair?code=…&h=…` / `https://mirrorz.app/pair?code=…&h=…` (§3.1).
public struct PairingLink: Hashable, Sendable {
    public var code: String
    /// Host device hash; used for LAN discovery (§7.1) and to label the paired Mac.
    public var hostHash: String?

    public init(code: String, hostHash: String? = nil) {
        self.code = code
        self.hostHash = hostHash
    }

    private var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "code", value: code)]
        if let hostHash { items.append(URLQueryItem(name: "h", value: hostHash)) }
        return items
    }

    /// What the QR code encodes.
    public var deepLink: URL? {
        var components = URLComponents()
        components.scheme = MirrorzIdentity.urlScheme
        components.host = "pair"
        components.queryItems = queryItems
        return components.url
    }

    public var universalLink: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = MirrorzIdentity.universalLinkHost
        components.path = "/pair"
        components.queryItems = queryItems
        return components.url
    }

    /// Parses either form; the code is normalized and must be valid.
    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let isScheme = components.scheme == MirrorzIdentity.urlScheme && components.host == "pair"
        let isUniversal = components.scheme == "https" && components.host == MirrorzIdentity.universalLinkHost && components.path == "/pair"
        guard isScheme || isUniversal,
              let raw = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let code = PairingCode.normalize(raw) else { return nil }
        self.init(code: code, hostHash: components.queryItems?.first(where: { $0.name == "h" })?.value)
    }
}

/// `POST /v1/remote/pairings` → 201.
public struct PairingResponse: Codable, Hashable, Sendable {
    public var code: String
    public var display: String
    public var roomID: String
    public var hostHash: String
    /// Unix seconds (`now + 600`).
    public var expiresAt: Int
    public var wsURL: String
    public var deepLink: String

    enum CodingKeys: String, CodingKey {
        case code, display
        case roomID = "room_id"
        case hostHash = "host_hash"
        case expiresAt = "expires_at"
        case wsURL = "ws_url"
        case deepLink = "deep_link"
    }

    public init(code: String, display: String, roomID: String, hostHash: String, expiresAt: Int, wsURL: String, deepLink: String) {
        self.code = code
        self.display = display
        self.roomID = roomID
        self.hostHash = hostHash
        self.expiresAt = expiresAt
        self.wsURL = wsURL
        self.deepLink = deepLink
    }

    public var link: PairingLink? { URL(string: deepLink).flatMap(PairingLink.init(url:)) }
    public var webSocketURL: URL? { URL(string: wsURL) }
    public var expiresDate: Date { Date(timeIntervalSince1970: TimeInterval(expiresAt)) }

    public func isExpired(at date: Date) -> Bool {
        Int(date.timeIntervalSince1970) >= expiresAt
    }
}

// MARK: - Grants (§3.3, §7.3)

/// Claims of an `MZP1` grant. All times are Unix seconds.
public struct RemoteGrantClaims: Codable, Hashable, Sendable {
    public var v: Int
    public var kid: String
    /// Host device hash.
    public var host: String
    /// Client device id.
    public var dev: String
    /// Client license id.
    public var lid: String
    public var iat: Int
    public var exp: Int

    public init(v: Int = 1, kid: String, host: String, dev: String, lid: String, iat: Int, exp: Int) {
        self.v = v
        self.kid = kid
        self.host = host
        self.dev = dev
        self.lid = lid
        self.iat = iat
        self.exp = exp
    }

    public var expiresAt: Date { Date(timeIntervalSince1970: TimeInterval(exp)) }
}

public enum RemoteGrantError: Error, Hashable, Sendable {
    case malformed
    case unsupportedVersion(Int)
    case unknownKid(String)
    case badPublicKey(kid: String)
    case badSignature
    case expired
    case hostMismatch
    case deviceMismatch

    public var code: String {
        switch self {
        case .malformed: return "malformed"
        case .unsupportedVersion: return "unsupported_version"
        case .unknownKid: return "unknown_kid"
        case .badPublicKey: return "bad_public_key"
        case .badSignature: return "bad_signature"
        case .expired: return "expired"
        case .hostMismatch: return "host_mismatch"
        case .deviceMismatch: return "device_mismatch"
        }
    }
}

public enum RemoteGrant {
    public static let prefix = RemoteProtocol.grantPrefix

    /// Bytes the signature covers: UTF-8 of `MZP1.<payload>`.
    public static func signingInput(payload: String) -> Data {
        Data("\(prefix).\(payload)".utf8)
    }

    public static func decodeUnverified(_ grant: String) throws -> RemoteGrantClaims {
        try decodeClaims(try split(grant).payload)
    }

    /// Verifies signature, version and expiry; when given, also `host == hostHash` (the Mac's own
    /// device hash, §7.3) and `dev == deviceID` (the connecting client's device id).
    public static func verify(_ grant: String, trustedKeys: [TrustedKey], hostHash: String?, deviceID: String?, now: Date) throws -> RemoteGrantClaims {
        let parts = try split(grant)
        let claims = try decodeClaims(parts.payload)
        guard let key = trustedKeys.first(where: { $0.kid == claims.kid }) else { throw RemoteGrantError.unknownKid(claims.kid) }
        guard let signature = Base64URL.decode(parts.signature), signature.count == 64 else { throw RemoteGrantError.badSignature }
        let publicKey: Curve25519.Signing.PublicKey
        do {
            publicKey = try key.publicKey()
        } catch {
            throw RemoteGrantError.badPublicKey(kid: claims.kid)
        }
        guard publicKey.isValidSignature(signature, for: signingInput(payload: parts.payload)) else { throw RemoteGrantError.badSignature }
        guard claims.v == 1 else { throw RemoteGrantError.unsupportedVersion(claims.v) }
        guard Int(now.timeIntervalSince1970) < claims.exp else { throw RemoteGrantError.expired }
        if let hostHash, claims.host != hostHash { throw RemoteGrantError.hostMismatch }
        if let deviceID, claims.dev != deviceID { throw RemoteGrantError.deviceMismatch }
        return claims
    }

    private static func split(_ grant: String) throws -> (payload: String, signature: String) {
        let parts = grant.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == prefix else { throw RemoteGrantError.malformed }
        return (String(parts[1]), String(parts[2]))
    }

    private static func decodeClaims(_ payload: String) throws -> RemoteGrantClaims {
        guard let data = Base64URL.decode(payload) else { throw RemoteGrantError.malformed }
        do {
            return try JSONDecoder().decode(RemoteGrantClaims.self, from: data)
        } catch {
            throw RemoteGrantError.malformed
        }
    }
}

// MARK: - WebSocket handshake (§4)

/// Query parameters of `GET /v1/remote/ws`.
public struct RemoteSocketRequest: Hashable, Sendable {
    public var role: PeerRole
    /// MZL1 device token.
    public var token: String
    public var room: String?
    public var code: String?
    public var grant: String?
    public var name: String?
    public var version: Int

    public init(role: PeerRole, token: String, room: String? = nil, code: String? = nil, grant: String? = nil, name: String? = nil, version: Int = RemoteProtocol.version) {
        self.role = role
        self.token = token
        self.room = room
        self.code = code
        self.grant = grant
        self.name = name.map { String($0.prefix(RemoteProtocol.maxNameLength)) }
        self.version = version
    }

    public static func host(token: String, room: String, name: String? = nil) -> RemoteSocketRequest {
        RemoteSocketRequest(role: .host, token: token, room: room, name: name)
    }

    public static func client(token: String, code: String, name: String? = nil) -> RemoteSocketRequest {
        RemoteSocketRequest(role: .client, token: token, code: code, name: name)
    }

    public static func client(token: String, grant: String, name: String? = nil) -> RemoteSocketRequest {
        RemoteSocketRequest(role: .client, token: token, grant: grant, name: name)
    }

    /// The socket URL. `http(s)` bases become `ws(s)`. The token goes in the query only when
    /// `authInQuery` is set (environments that cannot send headers); otherwise use `urlRequest`.
    public func url(base: URL, authInQuery: Bool = false) -> URL {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false) ?? URLComponents()
        switch components.scheme {
        case "http": components.scheme = "ws"
        case "https": components.scheme = "wss"
        default: break
        }
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + "/v1/remote/ws"
        var items = [URLQueryItem(name: "role", value: role.rawValue)]
        if let room { items.append(URLQueryItem(name: "room", value: room)) }
        if let code { items.append(URLQueryItem(name: "code", value: code)) }
        if let grant { items.append(URLQueryItem(name: "grant", value: grant)) }
        if version != RemoteProtocol.version { items.append(URLQueryItem(name: "v", value: String(version))) }
        if let name { items.append(URLQueryItem(name: "name", value: name)) }
        if authInQuery { items.append(URLQueryItem(name: "auth", value: token)) }
        components.queryItems = items
        return components.url ?? base
    }

    /// Request with `Authorization: Bearer <token>` (preferred by the spec).
    public func urlRequest(base: URL, userAgent: String? = nil) -> URLRequest {
        var request = URLRequest(url: url(base: base, authInQuery: false))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let userAgent { request.setValue(userAgent, forHTTPHeaderField: "User-Agent") }
        return request
    }
}

/// WebSocket close codes (§4.2).
public enum RemoteCloseCode: Int, Codable, Hashable, Sendable, CaseIterable {
    case normal = 1000
    case messageTooLarge = 1009
    case validation = 4400
    case badToken = 4401
    case forbidden = 4403
    case notFound = 4404
    case codeExpired = 4408
    case conflict = 4409
    case roomClosed = 4410
    case rateLimited = 4429
    case serverShutdown = 4503

    public var summary: String {
        switch self {
        case .normal: return "Closed normally."
        case .messageTooLarge: return "A message exceeded 64 KiB."
        case .validation: return "Malformed handshake or binary frame."
        case .badToken: return "The device token is missing, malformed or expired."
        case .forbidden: return "Authenticated but not allowed."
        case .notFound: return "Unknown room, code, or the Mac is offline."
        case .codeExpired: return "The pairing code has expired."
        case .conflict: return "The pairing code was already used, or the host was replaced."
        case .roomClosed: return "The Mac closed the session."
        case .rateLimited: return "Too many attempts. Try again later."
        case .serverShutdown: return "The service is restarting."
        }
    }

    /// True when a client should retry with its grant after a delay (host offline, restart).
    public var isTransient: Bool {
        self == .notFound || self == .serverShutdown || self == .rateLimited
    }
}

/// `error.code` values (§4.2, §5). Raw-value struct so new codes stay representable.
public struct RemoteErrorCode: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }

    public static let validation = RemoteErrorCode(rawValue: "validation")
    public static let tooLarge = RemoteErrorCode(rawValue: "too_large")
    public static let badToken = RemoteErrorCode(rawValue: "bad_token")
    public static let notActivated = RemoteErrorCode(rawValue: "not_activated")
    public static let expired = RemoteErrorCode(rawValue: "expired")
    public static let revoked = RemoteErrorCode(rawValue: "revoked")
    public static let paused = RemoteErrorCode(rawValue: "paused")
    public static let featureRequired = RemoteErrorCode(rawValue: "feature_required")
    public static let deviceMismatch = RemoteErrorCode(rawValue: "device_mismatch")
    public static let roomFull = RemoteErrorCode(rawValue: "room_full")
    public static let notAllowed = RemoteErrorCode(rawValue: "not_allowed")
    public static let notFound = RemoteErrorCode(rawValue: "not_found")
    public static let hostOffline = RemoteErrorCode(rawValue: "host_offline")
    public static let codeExpired = RemoteErrorCode(rawValue: "code_expired")
    public static let codeUsed = RemoteErrorCode(rawValue: "code_used")
    public static let replaced = RemoteErrorCode(rawValue: "replaced")
    public static let roomClosed = RemoteErrorCode(rawValue: "room_closed")
    public static let kicked = RemoteErrorCode(rawValue: "kicked")
    public static let rateLimited = RemoteErrorCode(rawValue: "rate_limited")
    public static let serverShutdown = RemoteErrorCode(rawValue: "server_shutdown")
    public static let launchFailed = RemoteErrorCode(rawValue: "launch_failed")
}

/// `bye.reason` (§5.1, §5.2).
public struct ByeReason: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }

    public static let hostLeft = ByeReason(rawValue: "host_left")
    public static let kicked = ByeReason(rawValue: "kicked")
    public static let replaced = ByeReason(rawValue: "replaced")
    public static let roomClosed = ByeReason(rawValue: "room_closed")
    public static let serverShutdown = ByeReason(rawValue: "server_shutdown")
}

/// `peer-left.reason` (§5.1).
public struct PeerLeftReason: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }

    public static let bye = PeerLeftReason(rawValue: "bye")
    public static let closed = PeerLeftReason(rawValue: "closed")
    public static let timeout = PeerLeftReason(rawValue: "timeout")
    public static let kicked = PeerLeftReason(rawValue: "kicked")
    public static let rateLimited = PeerLeftReason(rawValue: "rate_limited")
}

// MARK: - Peers, limits, ICE (§4.1, §5.1, §6)

public struct PeerDescriptor: Codable, Hashable, Sendable, Identifiable {
    public var peerID: String
    public var role: PeerRole
    public var deviceHash: String
    public var name: String?
    public var platform: String?
    public var sameLicense: Bool

    enum CodingKeys: String, CodingKey {
        case peerID = "peer_id"
        case role
        case deviceHash = "device_hash"
        case name, platform
        case sameLicense = "same_license"
    }

    public init(peerID: String, role: PeerRole, deviceHash: String, name: String? = nil, platform: String? = nil, sameLicense: Bool = false) {
        self.peerID = peerID
        self.role = role
        self.deviceHash = deviceHash
        self.name = name
        self.platform = platform
        self.sameLicense = sameLicense
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        peerID = try container.decode(String.self, forKey: .peerID)
        role = try container.decode(PeerRole.self, forKey: .role)
        deviceHash = try container.decode(String.self, forKey: .deviceHash)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        platform = try container.decodeIfPresent(String.self, forKey: .platform)
        sameLicense = try container.decodeIfPresent(Bool.self, forKey: .sameLicense) ?? false
    }

    public var id: String { peerID }
    public var platformID: Platform? { platform.flatMap(Platform.init(rawValue:)) }
    public var isHost: Bool { role == .host }
}

public struct RemoteLimits: Codable, Hashable, Sendable {
    public var maxMessageBytes: Int
    public var signalPerSec: Int
    public var inputPerSec: Int
    public var maxClients: Int
    public var grantExpiresAt: Int?

    enum CodingKeys: String, CodingKey {
        case maxMessageBytes = "max_message_bytes"
        case signalPerSec = "signal_per_sec"
        case inputPerSec = "input_per_sec"
        case maxClients = "max_clients"
        case grantExpiresAt = "grant_expires_at"
    }

    public init(maxMessageBytes: Int = RemoteProtocol.maxMessageBytes, signalPerSec: Int = RemoteRateLimits.signalingPerSecond, inputPerSec: Int = RemoteRateLimits.inputPerSecond, maxClients: Int = RemoteProtocol.defaultMaxClients, grantExpiresAt: Int? = nil) {
        self.maxMessageBytes = maxMessageBytes
        self.signalPerSec = signalPerSec
        self.inputPerSec = inputPerSec
        self.maxClients = maxClients
        self.grantExpiresAt = grantExpiresAt
    }
}

/// One entry of `iceServers` (RTCIceServer shape).
public struct ICEServer: Codable, Hashable, Sendable {
    public var urls: [String]
    public var username: String?
    public var credential: String?

    public init(urls: [String], username: String? = nil, credential: String? = nil) {
        self.urls = urls
        self.username = username
        self.credential = credential
    }
}

/// `GET /v1/remote/ice`.
public struct ICEServersResponse: Codable, Hashable, Sendable {
    public var iceServers: [ICEServer]
    public var ttl: Int
    public var expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case iceServers
        case ttl
        case expiresAt = "expires_at"
    }

    public init(iceServers: [ICEServer], ttl: Int, expiresAt: Int) {
        self.iceServers = iceServers
        self.ttl = ttl
        self.expiresAt = expiresAt
    }

    /// True when `expires_at` is within 10 minutes (§6).
    public func needsRefresh(at date: Date) -> Bool {
        TimeInterval(expiresAt) - date.timeIntervalSince1970 < RemoteProtocol.iceRefreshLeadTime
    }
}

// MARK: - App entries and surface (§5.2)

public enum AppEntryKind: String, Codable, Hashable, Sendable {
    case app
    case machine

    /// Unknown values decode to the nearest default (§10).
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AppEntryKind(rawValue: raw) ?? .app
    }
}

public enum AppEntryState: String, Codable, Hashable, Sendable {
    case stopped
    case starting
    case running

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AppEntryState(rawValue: raw) ?? .stopped
    }
}

public enum AppEntryRuntime: String, Codable, Hashable, Sendable {
    case vm
    case bottle
}

public struct AppEntry: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var kind: AppEntryKind
    /// Absent for machines.
    public var runtime: AppEntryRuntime?
    public var state: AppEntryState
    public var compatID: String?
    public var machineID: String?
    /// PNG data URI ≤ 8 KiB.
    public var icon: String?

    enum CodingKeys: String, CodingKey {
        case id, name, kind, runtime, state
        case compatID = "compat_id"
        case machineID = "machine_id"
        case icon
    }

    public init(id: String, name: String, kind: AppEntryKind, runtime: AppEntryRuntime? = nil, state: AppEntryState = .stopped, compatID: String? = nil, machineID: String? = nil, icon: String? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.runtime = runtime
        self.state = state
        self.compatID = compatID
        self.machineID = machineID
        self.icon = icon
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decodeIfPresent(AppEntryKind.self, forKey: .kind) ?? .app
        // Unknown runtime strings become nil rather than failing the whole list.
        runtime = try container.decodeIfPresent(String.self, forKey: .runtime).flatMap(AppEntryRuntime.init(rawValue:))
        state = try container.decodeIfPresent(AppEntryState.self, forKey: .state) ?? .stopped
        compatID = try container.decodeIfPresent(String.self, forKey: .compatID)
        machineID = try container.decodeIfPresent(String.self, forKey: .machineID)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }

    /// Decoded PNG bytes of `icon` when it is a `data:image/png;base64,…` URI.
    public var iconData: Data? {
        guard let icon, let comma = icon.firstIndex(of: ","), icon.hasPrefix("data:image/png;base64,") else { return nil }
        return Data(base64Encoded: String(icon[icon.index(after: comma)...]))
    }

    public var isRunning: Bool { state == .running }
}

/// Pixel size of the streamed frame.
public struct StreamSurface: Codable, Hashable, Sendable {
    public var w: Int
    public var h: Int

    public init(w: Int, h: Int) {
        self.w = w
        self.h = h
    }
}

// MARK: - Input events (§5.4)

/// `mods` bitmask: 1 shift, 2 ctrl, 4 alt/option, 8 meta (cmd/win).
public struct InputModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let shift = InputModifiers(rawValue: 1)
    public static let control = InputModifiers(rawValue: 2)
    public static let alt = InputModifiers(rawValue: 4)
    public static let meta = InputModifiers(rawValue: 8)
}

/// Pointer buttons for `dn`/`up`.
public enum PointerButton: Int, Codable, Hashable, Sendable, CaseIterable {
    case left = 0
    case middle = 1
    case right = 2
    case back = 3
    case forward = 4
}

/// One event on the `mz-input` channel (or in an `input` fallback message). Coordinates are
/// normalized 0…1 to the streamed surface, origin top-left.
public struct InputEvent: Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case move = "mv"
        case down = "dn"
        case up
        case scroll = "sc"
        case key
        case text = "txt"
    }

    public var k: Kind
    public var x: Double?
    public var y: Double?
    /// Pointer button (0 left, 1 middle, 2 right, 3 back, 4 forward).
    public var b: Int?
    public var dx: Double?
    public var dy: Double?
    /// W3C `KeyboardEvent.code` (`KeyA`, `Enter`, `ArrowLeft`, …).
    public var code: String?
    public var mods: InputModifiers
    /// Text to commit (`txt`), ≤ 4096 characters.
    public var s: String?
    /// Optional client-monotonic millisecond timestamp.
    public var t: Int?

    public init(k: Kind, x: Double? = nil, y: Double? = nil, b: Int? = nil, dx: Double? = nil, dy: Double? = nil, code: String? = nil, mods: InputModifiers = [], s: String? = nil, t: Int? = nil) {
        self.k = k
        self.x = x
        self.y = y
        self.b = b
        self.dx = dx
        self.dy = dy
        self.code = code
        self.mods = mods
        self.s = s
        self.t = t
    }

    public static func move(x: Double, y: Double, t: Int? = nil) -> InputEvent {
        InputEvent(k: .move, x: x, y: y, t: t)
    }

    public static func pointerDown(x: Double, y: Double, button: PointerButton = .left, mods: InputModifiers = [], t: Int? = nil) -> InputEvent {
        InputEvent(k: .down, x: x, y: y, b: button.rawValue, mods: mods, t: t)
    }

    public static func pointerUp(x: Double, y: Double, button: PointerButton = .left, mods: InputModifiers = [], t: Int? = nil) -> InputEvent {
        InputEvent(k: .up, x: x, y: y, b: button.rawValue, mods: mods, t: t)
    }

    public static func keyDown(_ code: String, mods: InputModifiers = [], t: Int? = nil) -> InputEvent {
        InputEvent(k: .down, code: code, mods: mods, t: t)
    }

    public static func keyUp(_ code: String, mods: InputModifiers = [], t: Int? = nil) -> InputEvent {
        InputEvent(k: .up, code: code, mods: mods, t: t)
    }

    /// Full press (down + up) for on-screen keyboards and shortcut chips.
    public static func keyPress(_ code: String, mods: InputModifiers = [], t: Int? = nil) -> InputEvent {
        InputEvent(k: .key, code: code, mods: mods, t: t)
    }

    /// Scroll at a point; positive `dy` scrolls content up (like `WheelEvent.deltaY`).
    public static func scroll(x: Double, y: Double, dx: Double, dy: Double, mods: InputModifiers = [], t: Int? = nil) -> InputEvent {
        InputEvent(k: .scroll, x: x, y: y, dx: dx, dy: dy, mods: mods, t: t)
    }

    /// Pinch-zoom is a ctrl-modified scroll (zooms most PC apps including AutoCAD).
    public static func pinch(x: Double, y: Double, dy: Double, t: Int? = nil) -> InputEvent {
        InputEvent(k: .scroll, x: x, y: y, dx: 0, dy: dy, mods: .control, t: t)
    }

    public static func text(_ string: String, t: Int? = nil) -> InputEvent {
        InputEvent(k: .text, s: String(string.prefix(RemoteProtocol.maxTextInputLength)), t: t)
    }

    public var button: PointerButton? { b.flatMap(PointerButton.init(rawValue:)) }

    /// Range checks the host applies before injecting (§5.4). Invalid events are dropped.
    public var isValid: Bool {
        func inUnit(_ value: Double?) -> Bool {
            guard let value else { return false }
            return value >= 0 && value <= 1 && value.isFinite
        }
        switch k {
        case .move:
            return inUnit(x) && inUnit(y)
        case .down, .up:
            guard inUnit(x) && inUnit(y) || code != nil else { return false }
            if let b { return (0...4).contains(b) && inUnit(x) && inUnit(y) }
            return code.map { !$0.isEmpty } ?? false
        case .scroll:
            return inUnit(x) && inUnit(y) && dx != nil && dy != nil && (dx?.isFinite ?? false) && (dy?.isFinite ?? false)
        case .key:
            return code.map { !$0.isEmpty } ?? false
        case .text:
            return s.map { !$0.isEmpty && $0.count <= RemoteProtocol.maxTextInputLength } ?? false
        }
    }
}

extension InputEvent: Codable {
    enum CodingKeys: String, CodingKey {
        case k, x, y, b, dx, dy, code, mods, s, t
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        k = try container.decode(Kind.self, forKey: .k)
        x = try container.decodeIfPresent(Double.self, forKey: .x)
        y = try container.decodeIfPresent(Double.self, forKey: .y)
        b = try container.decodeIfPresent(Int.self, forKey: .b)
        dx = try container.decodeIfPresent(Double.self, forKey: .dx)
        dy = try container.decodeIfPresent(Double.self, forKey: .dy)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        mods = InputModifiers(rawValue: try container.decodeIfPresent(Int.self, forKey: .mods) ?? 0)
        s = try container.decodeIfPresent(String.self, forKey: .s)
        t = try container.decodeIfPresent(Int.self, forKey: .t)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(k, forKey: .k)
        try container.encodeIfPresent(x, forKey: .x)
        try container.encodeIfPresent(y, forKey: .y)
        try container.encodeIfPresent(b, forKey: .b)
        try container.encodeIfPresent(dx, forKey: .dx)
        try container.encodeIfPresent(dy, forKey: .dy)
        try container.encodeIfPresent(code, forKey: .code)
        if !mods.isEmpty { try container.encode(mods.rawValue, forKey: .mods) }
        try container.encodeIfPresent(s, forKey: .s)
        try container.encodeIfPresent(t, forKey: .t)
    }
}

/// Messages on the `mz-input` data channel.
public enum InputChannelMessage: Hashable, Sendable {
    /// Client → host: one event or a batch.
    case events([InputEvent])
    /// Host → client: `{ "k": "surface", "w": …, "h": … }` when the stream size changes.
    case surface(StreamSurface)
}

public enum InputChannelCodec {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    private struct SurfaceObject: Codable {
        var k: String
        var w: Int
        var h: Int
    }

    private struct Probe: Decodable {
        var k: String
    }

    /// Encodes one event as an object, several as an array. Throws `.tooLarge` over 16 KiB.
    public static func encode(_ events: [InputEvent]) throws -> Data {
        let data = events.count == 1 ? try encoder.encode(events[0]) : try encoder.encode(events)
        guard data.count <= RemoteProtocol.maxDataChannelBytes else { throw RemoteCodecError.tooLarge(data.count) }
        return data
    }

    public static func encode(surface: StreamSurface) throws -> Data {
        try encoder.encode(SurfaceObject(k: "surface", w: surface.w, h: surface.h))
    }

    public static func decode(_ data: Data) throws -> InputChannelMessage {
        guard data.count <= RemoteProtocol.maxDataChannelBytes else { throw RemoteCodecError.tooLarge(data.count) }
        if data.first == UInt8(ascii: "[") {
            return .events(try decoder.decode([InputEvent].self, from: data))
        }
        let probe = try decoder.decode(Probe.self, from: data)
        if probe.k == "surface" {
            let object = try decoder.decode(SurfaceObject.self, from: data)
            return .surface(StreamSurface(w: object.w, h: object.h))
        }
        return .events([try decoder.decode(InputEvent.self, from: data)])
    }

    /// Coalesces consecutive `mv` events (keeps the last of each run) before batching.
    public static func coalescingMoves(_ events: [InputEvent]) -> [InputEvent] {
        var out: [InputEvent] = []
        for event in events {
            if event.k == .move, let last = out.last, last.k == .move {
                out[out.count - 1] = event
            } else {
                out.append(event)
            }
        }
        return out
    }
}

// MARK: - Signaling messages (§5)

public struct HelloMessage: Codable, Hashable, Sendable {
    public var v: Int
    public var peerID: String
    public var role: PeerRole
    public var roomID: String
    public var hostHash: String
    /// Own descriptor (`self` on the wire).
    public var selfDescriptor: PeerDescriptor
    /// Host: current clients; client: `[host]`.
    public var peers: [PeerDescriptor]
    /// Client only.
    public var grant: String?
    public var iceServers: [ICEServer]
    public var limits: RemoteLimits

    enum CodingKeys: String, CodingKey {
        case v
        case peerID = "peer_id"
        case role
        case roomID = "room_id"
        case hostHash = "host_hash"
        case selfDescriptor = "self"
        case peers, grant
        case iceServers = "ice_servers"
        case limits
    }

    public init(v: Int = RemoteProtocol.version, peerID: String, role: PeerRole, roomID: String, hostHash: String, selfDescriptor: PeerDescriptor, peers: [PeerDescriptor], grant: String? = nil, iceServers: [ICEServer] = [], limits: RemoteLimits = RemoteLimits()) {
        self.v = v
        self.peerID = peerID
        self.role = role
        self.roomID = roomID
        self.hostHash = hostHash
        self.selfDescriptor = selfDescriptor
        self.peers = peers
        self.grant = grant
        self.iceServers = iceServers
        self.limits = limits
    }

    public var host: PeerDescriptor? { role == .host ? selfDescriptor : peers.first { $0.isHost } }
}

public struct PeerJoinedMessage: Codable, Hashable, Sendable {
    public var peer: PeerDescriptor

    public init(peer: PeerDescriptor) {
        self.peer = peer
    }
}

public struct PeerLeftMessage: Codable, Hashable, Sendable {
    public var peerID: String
    public var reason: PeerLeftReason

    enum CodingKeys: String, CodingKey {
        case peerID = "peer_id"
        case reason
    }

    public init(peerID: String, reason: PeerLeftReason) {
        self.peerID = peerID
        self.reason = reason
    }
}

/// `offer` / `answer`. `to` is host-only; `from` is stamped by the server.
public struct SessionDescriptionMessage: Codable, Hashable, Sendable {
    public var to: String?
    public var from: String?
    public var ref: String?
    public var sdp: String

    public init(to: String? = nil, from: String? = nil, ref: String? = nil, sdp: String) {
        self.to = to
        self.from = from
        self.ref = ref
        self.sdp = sdp
    }

    public var isWithinLimit: Bool { sdp.utf8.count <= RemoteProtocol.maxSDPBytes }
}

/// `RTCIceCandidateInit` shape (camelCase, as WebRTC uses).
public struct ICECandidate: Codable, Hashable, Sendable {
    public var candidate: String
    public var sdpMid: String?
    public var sdpMLineIndex: Int?
    public var usernameFragment: String?

    public init(candidate: String, sdpMid: String? = nil, sdpMLineIndex: Int? = nil, usernameFragment: String? = nil) {
        self.candidate = candidate
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
        self.usernameFragment = usernameFragment
    }
}

/// `ice`. A nil `candidate` is encoded as JSON `null` (end of candidates).
public struct ICEMessage: Hashable, Sendable {
    public var to: String?
    public var from: String?
    public var ref: String?
    public var candidate: ICECandidate?

    public init(to: String? = nil, from: String? = nil, ref: String? = nil, candidate: ICECandidate?) {
        self.to = to
        self.from = from
        self.ref = ref
        self.candidate = candidate
    }

    public var isEndOfCandidates: Bool { candidate == nil }
}

extension ICEMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case to, from, ref, candidate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        to = try container.decodeIfPresent(String.self, forKey: .to)
        from = try container.decodeIfPresent(String.self, forKey: .from)
        ref = try container.decodeIfPresent(String.self, forKey: .ref)
        candidate = try container.decodeIfPresent(ICECandidate.self, forKey: .candidate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(to, forKey: .to)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encodeIfPresent(ref, forKey: .ref)
        try container.encode(candidate, forKey: .candidate)
    }
}

/// `apps` (host → clients): always the whole list. `streaming` is encoded as `null` when nothing streams.
public struct AppsMessage: Hashable, Sendable {
    public var to: String?
    public var from: String?
    public var ref: String?
    public var apps: [AppEntry]
    public var streaming: String?
    public var surface: StreamSurface?

    public init(to: String? = nil, from: String? = nil, ref: String? = nil, apps: [AppEntry], streaming: String? = nil, surface: StreamSurface? = nil) {
        self.to = to
        self.from = from
        self.ref = ref
        self.apps = Array(apps.prefix(RemoteProtocol.maxAppEntries))
        self.streaming = streaming
        self.surface = surface
    }

    /// Copy without icons, for when the list would exceed the 64 KiB frame (§5.2).
    public func withoutIcons() -> AppsMessage {
        var copy = self
        copy.apps = apps.map { entry in
            var entry = entry
            entry.icon = nil
            return entry
        }
        return copy
    }

    public var streamingEntry: AppEntry? { streaming.flatMap { id in apps.first { $0.id == id } } }
}

extension AppsMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case to, from, ref, apps, streaming, surface
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        to = try container.decodeIfPresent(String.self, forKey: .to)
        from = try container.decodeIfPresent(String.self, forKey: .from)
        ref = try container.decodeIfPresent(String.self, forKey: .ref)
        apps = try container.decode([AppEntry].self, forKey: .apps)
        streaming = try container.decodeIfPresent(String.self, forKey: .streaming)
        surface = try container.decodeIfPresent(StreamSurface.self, forKey: .surface)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(to, forKey: .to)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encodeIfPresent(ref, forKey: .ref)
        try container.encode(apps, forKey: .apps)
        try container.encode(streaming, forKey: .streaming)
        try container.encodeIfPresent(surface, forKey: .surface)
    }
}

/// `launch` (client → host): start if needed and show on my stream.
public struct LaunchMessage: Codable, Hashable, Sendable {
    public var appID: String
    public var from: String?
    public var ref: String?

    enum CodingKeys: String, CodingKey {
        case appID = "app_id"
        case from, ref
    }

    public init(appID: String, from: String? = nil, ref: String? = nil) {
        self.appID = appID
        self.from = from
        self.ref = ref
    }
}

/// `input` (client → host) — fallback when the data channel is unavailable; 1…64 events.
public struct InputMessage: Codable, Hashable, Sendable {
    public var evs: [InputEvent]
    public var from: String?
    public var ref: String?

    public init(evs: [InputEvent], from: String? = nil, ref: String? = nil) {
        self.evs = Array(evs.prefix(RemoteProtocol.maxInputEventsPerMessage))
        self.from = from
        self.ref = ref
    }
}

/// `error` from the server (with `ref`/`from`) or from the host (with `to`).
public struct ErrorMessage: Codable, Hashable, Sendable {
    public var to: String?
    public var from: String?
    public var ref: String?
    public var code: RemoteErrorCode
    public var message: String

    public init(to: String? = nil, from: String? = nil, ref: String? = nil, code: RemoteErrorCode, message: String) {
        self.to = to
        self.from = from
        self.ref = ref
        self.code = code
        self.message = message
    }
}

/// `bye`: host with `to` kicks one client, without `to` closes the room; server sends it before closing.
public struct ByeMessage: Codable, Hashable, Sendable {
    public var to: String?
    public var from: String?
    public var ref: String?
    public var reason: ByeReason?

    public init(to: String? = nil, from: String? = nil, ref: String? = nil, reason: ByeReason? = nil) {
        self.to = to
        self.from = from
        self.ref = ref
        self.reason = reason
    }
}

public enum RemoteMessageType: String, Codable, CaseIterable, Hashable, Sendable {
    case hello
    case peerJoined = "peer-joined"
    case peerLeft = "peer-left"
    case offer
    case answer
    case ice
    case apps
    case launch
    case input
    case error
    case bye
}

/// One WebSocket message. Encoded flat: `{ "t": "<type>", …fields }`.
public enum RemoteMessage: Hashable, Sendable {
    case hello(HelloMessage)
    case peerJoined(PeerJoinedMessage)
    case peerLeft(PeerLeftMessage)
    case offer(SessionDescriptionMessage)
    case answer(SessionDescriptionMessage)
    case ice(ICEMessage)
    case apps(AppsMessage)
    case launch(LaunchMessage)
    case input(InputMessage)
    case error(ErrorMessage)
    case bye(ByeMessage)

    public var type: RemoteMessageType {
        switch self {
        case .hello: return .hello
        case .peerJoined: return .peerJoined
        case .peerLeft: return .peerLeft
        case .offer: return .offer
        case .answer: return .answer
        case .ice: return .ice
        case .apps: return .apps
        case .launch: return .launch
        case .input: return .input
        case .error: return .error
        case .bye: return .bye
        }
    }

    /// Server-stamped sender of a relayed message.
    public var from: String? {
        switch self {
        case .hello, .peerJoined, .peerLeft: return nil
        case .offer(let m), .answer(let m): return m.from
        case .ice(let m): return m.from
        case .apps(let m): return m.from
        case .launch(let m): return m.from
        case .input(let m): return m.from
        case .error(let m): return m.from
        case .bye(let m): return m.from
        }
    }

    /// Messages a client may send (everything except `apps`, which is host → clients).
    public var isClientSendable: Bool {
        switch self {
        case .offer, .answer, .ice, .launch, .input, .bye: return true
        case .error, .apps, .hello, .peerJoined, .peerLeft: return false
        }
    }

    /// Messages counted against the signaling bucket (§4).
    public var isSignaling: Bool {
        switch self {
        case .offer, .answer, .ice, .launch, .bye, .error: return true
        default: return false
        }
    }
}

extension RemoteMessage: Codable {
    private enum TypeKey: String, CodingKey {
        case t
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypeKey.self)
        let raw = try container.decode(String.self, forKey: .t)
        guard let type = RemoteMessageType(rawValue: raw) else { throw RemoteCodecError.unknownType(raw) }
        switch type {
        case .hello: self = .hello(try HelloMessage(from: decoder))
        case .peerJoined: self = .peerJoined(try PeerJoinedMessage(from: decoder))
        case .peerLeft: self = .peerLeft(try PeerLeftMessage(from: decoder))
        case .offer: self = .offer(try SessionDescriptionMessage(from: decoder))
        case .answer: self = .answer(try SessionDescriptionMessage(from: decoder))
        case .ice: self = .ice(try ICEMessage(from: decoder))
        case .apps: self = .apps(try AppsMessage(from: decoder))
        case .launch: self = .launch(try LaunchMessage(from: decoder))
        case .input: self = .input(try InputMessage(from: decoder))
        case .error: self = .error(try ErrorMessage(from: decoder))
        case .bye: self = .bye(try ByeMessage(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TypeKey.self)
        try container.encode(type.rawValue, forKey: .t)
        switch self {
        case .hello(let m): try m.encode(to: encoder)
        case .peerJoined(let m): try m.encode(to: encoder)
        case .peerLeft(let m): try m.encode(to: encoder)
        case .offer(let m), .answer(let m): try m.encode(to: encoder)
        case .ice(let m): try m.encode(to: encoder)
        case .apps(let m): try m.encode(to: encoder)
        case .launch(let m): try m.encode(to: encoder)
        case .input(let m): try m.encode(to: encoder)
        case .error(let m): try m.encode(to: encoder)
        case .bye(let m): try m.encode(to: encoder)
        }
    }
}

public enum RemoteCodecError: Error, Hashable, Sendable {
    /// Frame over the 64 KiB (WebSocket) or 16 KiB (data channel) cap.
    case tooLarge(Int)
    case unknownType(String)
    case invalidUTF8
}

/// JSON text-frame framing (§4: text frames only, ≤ 64 KiB).
public enum RemoteCodec {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    public static func encode(_ message: RemoteMessage) throws -> Data {
        let data = try encoder.encode(message)
        guard data.count <= RemoteProtocol.maxMessageBytes else { throw RemoteCodecError.tooLarge(data.count) }
        return data
    }

    public static func encodeText(_ message: RemoteMessage) throws -> String {
        guard let text = String(data: try encode(message), encoding: .utf8) else { throw RemoteCodecError.invalidUTF8 }
        return text
    }

    public static func decode(_ data: Data) throws -> RemoteMessage {
        guard data.count <= RemoteProtocol.maxMessageBytes else { throw RemoteCodecError.tooLarge(data.count) }
        return try decoder.decode(RemoteMessage.self, from: data)
    }

    public static func decode(text: String) throws -> RemoteMessage {
        try decode(Data(text.utf8))
    }

    /// Encodes an `apps` message, dropping icons if the full list does not fit the frame.
    public static func encodeApps(_ apps: AppsMessage) throws -> Data {
        do {
            return try encode(.apps(apps))
        } catch RemoteCodecError.tooLarge {
            return try encode(.apps(apps.withoutIcons()))
        }
    }
}

// MARK: - Bonjour (§7.1)

/// TXT record of the `_mirrorz._tcp` advertisement.
public struct BonjourAdvertisement: Hashable, Sendable {
    public var version: Int
    public var hostHash: String
    /// Server room id, or nil when offline (`-` on the wire).
    public var roomID: String?
    /// SHA-256 fingerprint (hex) of the Mac's local TLS certificate; companions pin it.
    public var certificateFingerprint: String
    public var name: String

    public init(version: Int = RemoteProtocol.version, hostHash: String, roomID: String?, certificateFingerprint: String, name: String) {
        self.version = version
        self.hostHash = hostHash
        self.roomID = roomID
        self.certificateFingerprint = certificateFingerprint
        self.name = String(name.prefix(RemoteProtocol.maxNameLength))
    }

    public var txtRecord: [String: String] {
        ["v": String(version), "h": hostHash, "room": roomID ?? "-", "fp": certificateFingerprint, "n": name]
    }

    public init?(txtRecord: [String: String]) {
        guard let hostHash = txtRecord["h"], let fingerprint = txtRecord["fp"] else { return nil }
        let room = txtRecord["room"]
        self.init(
            version: txtRecord["v"].flatMap(Int.init) ?? RemoteProtocol.version,
            hostHash: hostHash,
            roomID: (room == nil || room == "-") ? nil : room,
            certificateFingerprint: fingerprint,
            name: txtRecord["n"] ?? ""
        )
    }

    public var isOnline: Bool { roomID != nil }
}
