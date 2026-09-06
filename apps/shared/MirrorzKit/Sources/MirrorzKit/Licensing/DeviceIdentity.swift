// DeviceIdentity.swift
// Stable, opaque, client-generated device id (spec §3.1) and the device record (§3.2).
//
//   macOS:  sha256(IOPlatformUUID + "com.mirrorz.app") hex (64 chars)
//   iOS:    random UUID generated once (36 chars), stored in the Keychain
// Both are cached in the keychain so they survive reinstalls.

import CryptoKit
import Foundation
#if os(macOS)
import IOKit
#endif
#if canImport(UIKit)
import UIKit
#endif

public enum DeviceIdentity {
    /// Keychain account under which the id is cached.
    public static let keychainAccount = "device-id"
    /// Salt from spec §3.1 (the macOS bundle id, used on macOS only).
    public static let macOSSalt = MirrorzIdentity.macOSBundleID
    public static let idLengthRange = 32...64

    /// Returns the device id, generating and persisting it on first use.
    public static func deviceID(store: SecureStore) throws -> String {
        if let cached = try store.string(forKey: keychainAccount), isAcceptable(cached) {
            return cached
        }
        let fresh = generate()
        try store.set(fresh, forKey: keychainAccount)
        return fresh
    }

    /// Length check from spec §3.1 (32–64 characters).
    public static func isAcceptable(_ id: String) -> Bool {
        idLengthRange.contains(id.count) && !id.contains { $0.isWhitespace }
    }

    /// Derives a new id for this platform without touching the keychain.
    public static func generate() -> String {
        #if os(macOS)
        if let uuid = platformUUID(), !uuid.isEmpty {
            return sha256Hex(uuid + macOSSalt)
        }
        #endif
        return UUID().uuidString.lowercased()
    }

    /// Lower-case hex SHA-256 of the UTF-8 string.
    public static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Builds the `device` record for licensing calls. Main-actor because the device name
    /// and idiom come from UIKit on iOS.
    @MainActor
    public static func deviceRecord(id: String, appVersion: String, name: String? = nil) -> DeviceRecord {
        DeviceRecord(
            id: id,
            name: name ?? defaultDeviceName(),
            platform: Platform.detect(),
            osVersion: operatingSystemVersionString(),
            appVersion: appVersion
        )
    }

    /// "14.6.1" style version string.
    public static func operatingSystemVersionString() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    @MainActor
    private static func defaultDeviceName() -> String? {
        #if os(macOS)
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        #elseif canImport(UIKit)
        return UIDevice.current.name
        #else
        return nil
        #endif
    }
}

#if os(macOS)
extension DeviceIdentity {
    /// `IOPlatformUUID` from the IORegistry's platform expert device.
    public static func platformUUID() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        guard let property = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        return property.takeRetainedValue() as? String
    }
}
#endif
