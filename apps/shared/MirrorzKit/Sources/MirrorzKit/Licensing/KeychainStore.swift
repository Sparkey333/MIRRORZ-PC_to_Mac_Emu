// KeychainStore.swift
// Keychain-backed storage for the device token and device id (spec §1, §3.1, §3.4 rule 5).

import Foundation
import Security

/// Small key/value secure store abstraction so Entitlements and DeviceIdentity can be
/// tested with an in-memory store.
public protocol SecureStore: Sendable {
    func data(forKey key: String) throws -> Data?
    func set(_ data: Data, forKey key: String) throws
    func removeValue(forKey key: String) throws
}

public extension SecureStore {
    func string(forKey key: String) throws -> String? {
        guard let data = try data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func set(_ string: String, forKey key: String) throws {
        try set(Data(string.utf8), forKey: key)
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func encode<T: Encodable>(_ value: T, forKey key: String) throws {
        try set(try JSONEncoder().encode(value), forKey: key)
    }
}

public enum KeychainError: Error, Hashable, Sendable {
    case unexpectedStatus(OSStatus)
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            let text = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
            return "Keychain error: \(text)"
        }
    }
}

/// Generic-password keychain items under service `com.mirrorz.license`.
///
/// - `accessGroup`: set to the App Group / keychain access group when the token must be shared
///   between targets (for example the macOS app and its CLI helper).
/// - `useDataProtectionKeychain`: on iOS the data-protection keychain is the only keychain. On
///   macOS it requires the app to be signed with a keychain access group, so it defaults to
///   `true` only when an access group is given; otherwise the login keychain is used.
public struct KeychainStore: SecureStore {
    public static let defaultService = MirrorzIdentity.keychainService

    public let service: String
    public let accessGroup: String?
    public let useDataProtectionKeychain: Bool

    public init(service: String = KeychainStore.defaultService, accessGroup: String? = nil, useDataProtectionKeychain: Bool? = nil) {
        self.service = service
        self.accessGroup = accessGroup
        #if os(macOS)
        self.useDataProtectionKeychain = useDataProtectionKeychain ?? (accessGroup != nil)
        #else
        self.useDataProtectionKeychain = useDataProtectionKeychain ?? true
        #endif
    }

    public func data(forKey key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func set(_ data: Data, forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var item = query
            item[kSecValueData as String] = data
            // Available after first unlock; never migrated to another device.
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    public func removeValue(forKey key: String) throws {
        let status = SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        if useDataProtectionKeychain {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        return query
    }
}

/// Thread-safe in-memory store for tests and SwiftUI previews.
public final class InMemorySecureStore: SecureStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    public init(initial: [String: Data] = [:]) {
        storage = initial
    }

    public func data(forKey key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    public func set(_ data: Data, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = data
    }

    public func removeValue(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = nil
    }

    public var keys: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(storage.keys)
    }
}
