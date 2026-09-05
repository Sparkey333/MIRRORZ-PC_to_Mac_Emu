// TestSupport.swift
// Fixture loading, a fake HTTP transport and a controllable clock.

import Foundation
import XCTest
@testable import MirrorzKit

/// Shape of core/tests/fixtures/license-fixtures.json.
struct Fixtures: Decodable {
    struct KeyFixture: Decodable {
        var kid: String
        var x: String
        var trustedKey: TrustedKey { TrustedKey(kid: kid, x: x) }
    }

    struct Expect: Decodable {
        var valid: Bool
        var error: String?
        var entitledAtNow: Bool?
        var modeAtNow: String?
        var modeAfterUpdatesWindow: String?
        var entitledAfterUpdatesWindow: Bool?
        var entitledAt: [String: Bool]?

        enum CodingKeys: String, CodingKey {
            case valid, error
            case entitledAtNow = "entitled_at_now"
            case modeAtNow = "mode_at_now"
            case modeAfterUpdatesWindow = "mode_after_updates_window"
            case entitledAfterUpdatesWindow = "entitled_after_updates_window"
            case entitledAt = "entitled_at"
        }
    }

    struct TokenFixture: Decodable {
        var name: String
        var token: String
        var expect: Expect
    }

    struct Normalization: Decodable {
        var input: String
        var normalized: String?
    }

    struct LicenseKeys: Decodable {
        var valid: [String]
        var invalid: [String]
        var normalization: [Normalization]
    }

    var now: Int
    var deviceID: String
    var trustedKeys: [KeyFixture]
    var untrustedKey: KeyFixture
    var tokens: [TokenFixture]
    var licenseKeys: LicenseKeys

    enum CodingKeys: String, CodingKey {
        case now
        case deviceID = "device_id"
        case trustedKeys = "trusted_keys"
        case untrustedKey = "untrusted_key"
        case tokens
        case licenseKeys = "license_keys"
    }

    var trusted: [TrustedKey] { trustedKeys.map(\.trustedKey) }
    var nowDate: Date { Date(timeIntervalSince1970: TimeInterval(now)) }

    func token(named name: String) throws -> String {
        guard let fixture = tokens.first(where: { $0.name == name }) else {
            throw XCTSkip("fixture \(name) missing")
        }
        return fixture.token
    }

    static func load() throws -> Fixtures {
        guard let url = Bundle.module.url(forResource: "license-fixtures", withExtension: "json") else {
            throw NSError(domain: "MirrorzKitTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "license-fixtures.json not in test bundle"])
        }
        return try JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: url))
    }
}

/// Programmable transport that records every request.
final class FakeTransport: HTTPTransport, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> HTTPResponse

    private let lock = NSLock()
    private var handler: Handler
    private var recorded: [URLRequest] = []

    init(_ handler: @escaping Handler) {
        self.handler = handler
    }

    func send(_ request: URLRequest) async throws -> HTTPResponse {
        lock.lock()
        recorded.append(request)
        let current = handler
        lock.unlock()
        return try current(request)
    }

    func setHandler(_ handler: @escaping Handler) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    var requests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    var requestCount: Int { requests.count }

    func body<T: Decodable>(_ type: T.Type, ofRequestAt index: Int) throws -> T {
        let data = try XCTUnwrap(requests[index].httpBody)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func json<T: Encodable>(_ value: T, status: Int = 200) -> HTTPResponse {
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        return HTTPResponse(statusCode: status, headers: ["content-type": "application/json"], body: data)
    }

    static func raw(_ json: String, status: Int = 200) -> HTTPResponse {
        HTTPResponse(statusCode: status, headers: ["content-type": "application/json"], body: Data(json.utf8))
    }

    static func error(status: Int, code: String, message: String = "error") -> HTTPResponse {
        raw(#"{"error":"\#(code)","message":"\#(message)"}"#, status: status)
    }

    static func offline() -> FakeTransport {
        FakeTransport { _ in throw URLError(.notConnectedToInternet) }
    }
}

/// Mutable clock shared with the code under test through a `@Sendable` closure.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ date: Date) {
        current = date
    }

    var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func advance(by seconds: TimeInterval) {
        lock.lock()
        current = current.addingTimeInterval(seconds)
        lock.unlock()
    }

    func set(_ date: Date) {
        lock.lock()
        current = date
        lock.unlock()
    }
}

extension LicenseView {
    static func sample(kind: LicenseKind = .perpetual, plan: Plan = .standard, deviceID: String = "device-fixture-0001", now: Int = 1_800_000_000) -> LicenseView {
        LicenseView(
            id: "lic_sample",
            kind: kind,
            plan: plan.rawValue,
            status: .active,
            maxDevices: plan.deviceLimit,
            issuedAt: now,
            expiresAt: kind == .perpetual ? nil : now + 30 * 86_400,
            updatesUntil: kind == .perpetual ? now + 365 * 86_400 : nil,
            autoRenew: kind == .subscription,
            devices: [LicenseDevice(deviceID: deviceID, deviceName: "Test Mac", platform: "macos", activatedAt: now, lastSeenAt: now)],
            entitlement: LicenseEntitlement(entitled: true, reason: kind.rawValue, kind: kind, plan: plan.rawValue, features: plan.features.map(\.rawValue).sorted())
        )
    }
}

extension DeviceRecord {
    static let fixture = DeviceRecord(id: "device-fixture-0001", name: "Test Mac", platform: .macos, osVersion: "14.6.0", appVersion: "1.0.0")
}

func makeTemporaryDirectory(_ name: String = "MirrorzKitTests") throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(name, isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
