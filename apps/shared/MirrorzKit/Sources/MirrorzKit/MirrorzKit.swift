// MirrorzKit.swift
// Product identity constants shared by every Apple client (spec §1, §7).

import Foundation

/// Product identity values from `docs/spec/platform-contracts.md` §1.
public enum MirrorzIdentity {
    public static let productName = "MIRRORZ"
    public static let macOSBundleID = "com.mirrorz.app"
    public static let iOSBundleID = "com.mirrorz.companion"
    public static let appGroup = "group.com.mirrorz"
    public static let keychainService = "com.mirrorz.license"
    public static let urlScheme = "mirrorz"
    public static let universalLinkHost = "mirrorz.app"
    public static let productionAPIBaseURL = URL(string: "https://api.mirrorz.app")!
    public static let developmentAPIBaseURL = URL(string: "http://localhost:8787")!
    /// Product string carried in every token (`claims.product`).
    public static let tokenProduct = "mirrorz"
}

/// Build metadata used for the perpetual "updates window" rule (spec §3.4 rule 2)
/// and for the `app_version` field of the device record.
///
/// Versions are semantic and shared across all apps (spec §7). The build date is read from
/// the `MZBuildDate` Info.plist key (ISO-8601 date, written by the Xcode build phase); the
/// fallback constant is the date this source snapshot was cut and is only used when the
/// host bundle carries no key (unit tests, previews).
public struct BuildInfo: Hashable, Sendable {
    public var version: String
    public var buildDate: Date

    public init(version: String, buildDate: Date) {
        self.version = version
        self.buildDate = buildDate
    }

    public static let infoPlistBuildDateKey = "MZBuildDate"

    /// The fallback used when no `MZBuildDate` key is present. Keep in sync with releases.
    public static let fallbackBuildDate: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "UTC")
        components.year = 2026
        components.month = 9
        components.day = 3
        return components.date ?? Date(timeIntervalSince1970: 1_788_393_600)
    }()

    /// Reads the version and build date from a bundle (defaults to the main bundle).
    public static func current(bundle: Bundle = .main) -> BuildInfo {
        let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0.0"
        var buildDate = fallbackBuildDate
        if let raw = bundle.object(forInfoDictionaryKey: infoPlistBuildDateKey) as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            if let date = formatter.date(from: raw) {
                buildDate = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: raw) { buildDate = date }
            }
        }
        return BuildInfo(version: version, buildDate: buildDate)
    }
}
