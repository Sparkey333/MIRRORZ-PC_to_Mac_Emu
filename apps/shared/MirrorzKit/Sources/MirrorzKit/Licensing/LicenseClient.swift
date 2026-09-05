// LicenseClient.swift
// Client for the licensing endpoints (spec §3.2). Reference implementation: server/src/http/app.ts.

import Foundation

// MARK: - Wire types

/// `device` record sent with every activation call (spec §3.2). Field limits mirror the
/// server's schema (name ≤ 120, os_version/app_version ≤ 40) and are enforced on init.
public struct DeviceRecord: Codable, Hashable, Sendable {
    public var id: String
    public var name: String?
    public var platform: Platform
    public var osVersion: String?
    public var appVersion: String?

    enum CodingKeys: String, CodingKey {
        case id, name, platform
        case osVersion = "os_version"
        case appVersion = "app_version"
    }

    public init(id: String, name: String? = nil, platform: Platform, osVersion: String? = nil, appVersion: String? = nil) {
        self.id = id
        self.name = name.map { String($0.prefix(120)) }
        self.platform = platform
        self.osVersion = osVersion.map { String($0.prefix(40)) }
        self.appVersion = appVersion.map { String($0.prefix(40)) }
    }
}

/// One activated device in a license view.
public struct LicenseDevice: Codable, Hashable, Sendable, Identifiable {
    public var deviceID: String
    public var deviceName: String?
    public var platform: String?
    public var activatedAt: Int
    public var lastSeenAt: Int

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case deviceName = "device_name"
        case platform
        case activatedAt = "activated_at"
        case lastSeenAt = "last_seen_at"
    }

    public init(deviceID: String, deviceName: String? = nil, platform: String? = nil, activatedAt: Int, lastSeenAt: Int) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.platform = platform
        self.activatedAt = activatedAt
        self.lastSeenAt = lastSeenAt
    }

    public var id: String { deviceID }
    public var platformID: Platform? { platform.flatMap(Platform.init(rawValue:)) }
    public var activatedDate: Date { Date(timeIntervalSince1970: TimeInterval(activatedAt)) }
    public var lastSeenDate: Date { Date(timeIntervalSince1970: TimeInterval(lastSeenAt)) }
}

/// Server-side entitlement summary (camelCase on the wire, as the server emits it).
public struct LicenseEntitlement: Codable, Hashable, Sendable {
    public var entitled: Bool
    public var reason: String
    public var kind: LicenseKind
    public var plan: String
    public var features: [String]
    public var subscriptionEndsAt: Int?
    public var updatesUntil: Int?

    public init(entitled: Bool, reason: String, kind: LicenseKind, plan: String, features: [String], subscriptionEndsAt: Int? = nil, updatesUntil: Int? = nil) {
        self.entitled = entitled
        self.reason = reason
        self.kind = kind
        self.plan = plan
        self.features = features
        self.subscriptionEndsAt = subscriptionEndsAt
        self.updatesUntil = updatesUntil
    }

    public var featureSet: Set<Feature> { Feature.set(from: features) }
}

/// Public license view (`PublicLicenseView` in server/src/license/service.ts).
public struct LicenseView: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var kind: LicenseKind
    public var plan: String
    public var status: LicenseStatus
    public var maxDevices: Int
    public var issuedAt: Int
    public var expiresAt: Int?
    public var updatesUntil: Int?
    public var autoRenew: Bool
    public var devices: [LicenseDevice]
    public var entitlement: LicenseEntitlement

    enum CodingKeys: String, CodingKey {
        case id, kind, plan, status
        case maxDevices = "max_devices"
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case updatesUntil = "updates_until"
        case autoRenew = "auto_renew"
        case devices, entitlement
    }

    public init(id: String, kind: LicenseKind, plan: String, status: LicenseStatus, maxDevices: Int, issuedAt: Int, expiresAt: Int? = nil, updatesUntil: Int? = nil, autoRenew: Bool, devices: [LicenseDevice], entitlement: LicenseEntitlement) {
        self.id = id
        self.kind = kind
        self.plan = plan
        self.status = status
        self.maxDevices = maxDevices
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.updatesUntil = updatesUntil
        self.autoRenew = autoRenew
        self.devices = devices
        self.entitlement = entitlement
    }

    public var planID: Plan? { Plan(rawValue: plan) }
    public var expiresDate: Date? { expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
    public var updatesUntilDate: Date? { updatesUntil.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
    public var activeDeviceCount: Int { devices.count }
    public var hasFreeSeat: Bool { devices.count < maxDevices }
}

public struct ActivationResponse: Codable, Hashable, Sendable {
    public var token: String
    public var license: LicenseView

    public init(token: String, license: LicenseView) {
        self.token = token
        self.license = license
    }
}

public struct TrialResponse: Codable, Hashable, Sendable {
    public var token: String
    public var license: LicenseView
    /// True when this device already had a trial and it was resumed.
    public var existing: Bool

    public init(token: String, license: LicenseView, existing: Bool) {
        self.token = token
        self.license = license
        self.existing = existing
    }
}

public struct DeactivationResponse: Codable, Hashable, Sendable {
    public var deactivated: Bool
    public var license: LicenseView

    public init(deactivated: Bool, license: LicenseView) {
        self.deactivated = deactivated
        self.license = license
    }
}

/// Response of `/v1/apple/link` and `/v1/google/link`. `key` is non-nil only on the first link
/// of a purchase; the app shows it once so the user can activate other devices with it.
public struct LinkResponse: Codable, Hashable, Sendable {
    public var token: String
    public var license: LicenseView
    public var key: String?

    public init(token: String, license: LicenseView, key: String? = nil) {
        self.token = token
        self.license = license
        self.key = key
    }
}

public struct JSONWebKey: Codable, Hashable, Sendable {
    public var kty: String
    public var crv: String
    public var x: String
    public var kid: String?
    public var use: String?
    public var alg: String?

    public init(kty: String = "OKP", crv: String = "Ed25519", x: String, kid: String? = nil, use: String? = nil, alg: String? = nil) {
        self.kty = kty
        self.crv = crv
        self.x = x
        self.kid = kid
        self.use = use
        self.alg = alg
    }
}

/// `GET /.well-known/mirrorz-license-key.json`.
public struct PublicKeyDocument: Codable, Hashable, Sendable {
    public var keys: [JSONWebKey]
    public var raw: String
    public var format: String?

    public init(keys: [JSONWebKey], raw: String, format: String? = nil) {
        self.keys = keys
        self.raw = raw
        self.format = format
    }

    /// Ed25519 keys as `TrustedKey`s. This is informational (key rotation notices, support
    /// diagnostics); entitlement verification uses the embedded list only.
    public var trustedKeys: [TrustedKey] {
        keys.compactMap { key in
            guard key.kty == "OKP", key.crv == "Ed25519" else { return nil }
            let candidate = TrustedKey(kid: key.kid ?? "", x: key.x)
            return TrustedKey(kid: key.kid ?? candidate.derivedKid, x: key.x)
        }
    }
}

// MARK: - Errors

/// Error codes from spec §3.2 plus the extra codes the reference server emits.
/// Modelled as a raw-value struct so unknown codes from newer servers stay representable.
public struct APIErrorCode: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }

    // Spec §3.2
    public static let validation = APIErrorCode(rawValue: "validation")
    public static let notFound = APIErrorCode(rawValue: "not_found")
    public static let deviceLimit = APIErrorCode(rawValue: "device_limit")
    public static let expired = APIErrorCode(rawValue: "expired")
    public static let revoked = APIErrorCode(rawValue: "revoked")
    public static let refunded = APIErrorCode(rawValue: "refunded")
    public static let paused = APIErrorCode(rawValue: "paused")
    public static let badToken = APIErrorCode(rawValue: "bad_token")
    public static let notActivated = APIErrorCode(rawValue: "not_activated")
    public static let rateLimited = APIErrorCode(rawValue: "rate_limited")
    public static let trialUsed = APIErrorCode(rawValue: "trial_used")
    /// Remote (docs/spec/remote-protocol.md §2): the token lacks `mobile-companion`.
    public static let featureRequired = APIErrorCode(rawValue: "feature_required")
    // Reference server extras
    public static let badJSON = APIErrorCode(rawValue: "bad_json")
    public static let badDevice = APIErrorCode(rawValue: "bad_device")
    public static let unknownProduct = APIErrorCode(rawValue: "unknown_product")
    public static let bundleMismatch = APIErrorCode(rawValue: "bundle_mismatch")
    public static let environmentMismatch = APIErrorCode(rawValue: "env_mismatch")
    public static let disabled = APIErrorCode(rawValue: "disabled")
    public static let unauthorized = APIErrorCode(rawValue: "unauthorized")
    public static let internalError = APIErrorCode(rawValue: "internal")

    /// Codes that mean the license itself is no longer entitled.
    public var meansEntitlementLost: Bool {
        [.expired, .revoked, .refunded, .paused, .notActivated].contains(self)
    }
}

/// A non-2xx response with the `{ error, message }` envelope.
public struct APIError: Error, Hashable, Sendable {
    public var status: Int
    public var code: APIErrorCode
    public var message: String

    public init(status: Int, code: APIErrorCode, message: String) {
        self.status = status
        self.code = code
        self.message = message
    }

    /// Spec §3.4 rule 3: a 403 on refresh drops the entitlement immediately.
    public var isForbidden: Bool { status == 403 }

    /// User-facing text following the spec vocabulary.
    public var userMessage: String {
        switch code {
        case .notFound: return "That license key was not found. Check it and try again."
        case .deviceLimit: return "This license is already active on its maximum number of devices. Deactivate one in Settings › License & Plans."
        case .expired: return "This subscription has expired."
        case .revoked: return "This license has been revoked."
        case .refunded: return "This purchase was refunded."
        case .paused: return "This subscription is paused. Update the payment method to resume it."
        case .badToken: return "The stored license needs to be re-activated."
        case .notActivated: return "This device is no longer activated on the license."
        case .rateLimited: return "Too many attempts. Please wait a moment and try again."
        case .trialUsed: return "The free trial has already been used on this device."
        case .validation, .badJSON, .badDevice: return "The request was rejected. Please update MIRRORZ and try again."
        case .unknownProduct: return "This purchase does not match a MIRRORZ product."
        default: return message.isEmpty ? "Something went wrong (\(code))." : message
        }
    }
}

extension APIError: LocalizedError {
    public var errorDescription: String? { userMessage }
}

/// Every failure a client call can produce.
public enum APIClientError: Error, Sendable {
    /// The key failed local normalization (bad length, alphabet or check symbol).
    case invalidKey
    /// The server answered with an error envelope.
    case api(APIError)
    /// The request never completed (offline, DNS, TLS, timeout…).
    case network(any Error)
    /// A 2xx body could not be decoded.
    case decoding(any Error)
    /// Non-2xx without an error envelope.
    case unexpectedStatus(Int)

    public var apiError: APIError? {
        if case .api(let error) = self { return error }
        return nil
    }

    /// True when the call failed before the server could answer.
    public var isNetworkFailure: Bool {
        if case .network = self { return true }
        return false
    }
}

extension APIClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidKey: return "That does not look like a MIRRORZ license key."
        case .api(let error): return error.userMessage
        case .network: return "MIRRORZ could not reach the licensing service. Check your connection and try again."
        case .decoding: return "The licensing service sent an unexpected response."
        case .unexpectedStatus(let status): return "The licensing service returned status \(status)."
        }
    }
}

public typealias LicenseClientError = APIClientError

// MARK: - Client

/// Talks to the licensing API. Stateless; safe to share.
public actor LicenseClient {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var appVersion: String
        public var platform: Platform
        public var timeout: TimeInterval

        public init(
            baseURL: URL = MirrorzIdentity.productionAPIBaseURL,
            appVersion: String,
            platform: Platform = .compiled,
            timeout: TimeInterval = 20
        ) {
            self.baseURL = baseURL
            self.appVersion = appVersion
            self.platform = platform
            self.timeout = timeout
        }

        /// `MIRRORZ/<version> (<platform>)`.
        public var userAgent: String { "MIRRORZ/\(appVersion) (\(platform.rawValue))" }
    }

    public let configuration: Configuration
    private let transport: HTTPTransport
    private let builder: APIRequestBuilder

    public init(configuration: Configuration, transport: HTTPTransport = URLSessionTransport.ephemeral()) {
        self.configuration = configuration
        self.transport = transport
        self.builder = APIRequestBuilder(baseURL: configuration.baseURL, userAgent: configuration.userAgent, timeout: configuration.timeout)
    }

    // MARK: Request bodies

    private struct TrialBody: Encodable { var device: DeviceRecord }
    private struct ActivateBody: Encodable { var key: String; var device: DeviceRecord }
    private struct RefreshBody: Encodable { var token: String }
    private struct DeactivateBody: Encodable {
        var key: String
        var deviceID: String
        enum CodingKeys: String, CodingKey {
            case key
            case deviceID = "device_id"
        }
    }
    private struct AppleLinkBody: Encodable { var signedTransaction: String; var device: DeviceRecord }
    private struct GoogleLinkBody: Encodable { var purchaseToken: String; var productId: String; var device: DeviceRecord }

    // MARK: Endpoints

    /// `POST /v1/trials` — 14-day trial, one per device. 201 on creation, 200 when resumed.
    public func startTrial(device: DeviceRecord) async throws -> TrialResponse {
        try await post("/v1/trials", body: TrialBody(device: device))
    }

    /// `POST /v1/licenses/activate`. The key is normalized locally first (spec §3.3).
    public func activate(key: String, device: DeviceRecord) async throws -> ActivationResponse {
        guard let normalized = LicenseKey.normalize(key) else { throw APIClientError.invalidKey }
        return try await post("/v1/licenses/activate", body: ActivateBody(key: normalized, device: device))
    }

    /// `POST /v1/licenses/refresh` — 401 bad token, 403 revoked/expired.
    public func refresh(token: String) async throws -> ActivationResponse {
        try await post("/v1/licenses/refresh", body: RefreshBody(token: token))
    }

    /// `POST /v1/licenses/deactivate`.
    public func deactivate(key: String, deviceID: String) async throws -> DeactivationResponse {
        guard let normalized = LicenseKey.normalize(key) else { throw APIClientError.invalidKey }
        return try await post("/v1/licenses/deactivate", body: DeactivateBody(key: normalized, deviceID: deviceID))
    }

    /// `GET /v1/licenses/status?key=`.
    public func status(key: String) async throws -> LicenseView {
        guard let normalized = LicenseKey.normalize(key) else { throw APIClientError.invalidKey }
        let request = builder.get("/v1/licenses/status", query: [URLQueryItem(name: "key", value: normalized)])
        return try await perform(request)
    }

    /// `POST /v1/apple/link` with a StoreKit 2 `jwsRepresentation`.
    public func linkApple(signedTransaction: String, device: DeviceRecord) async throws -> LinkResponse {
        try await post("/v1/apple/link", body: AppleLinkBody(signedTransaction: signedTransaction, device: device))
    }

    /// `POST /v1/google/link` — unused on Apple platforms; included for API completeness.
    public func linkGoogle(purchaseToken: String, productId: String, device: DeviceRecord) async throws -> LinkResponse {
        try await post("/v1/google/link", body: GoogleLinkBody(purchaseToken: purchaseToken, productId: productId, device: device))
    }

    /// `GET /.well-known/mirrorz-license-key.json`.
    public func publicKeys() async throws -> PublicKeyDocument {
        try await perform(builder.get("/.well-known/mirrorz-license-key.json"))
    }

    // MARK: Plumbing

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let request: URLRequest
        do {
            request = try builder.post(path, body: body)
        } catch {
            throw APIClientError.decoding(error)
        }
        return try await perform(request)
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let response = try await APIResponseDecoder.send(request, via: transport)
        return try APIResponseDecoder.decode(Response.self, from: response)
    }
}
