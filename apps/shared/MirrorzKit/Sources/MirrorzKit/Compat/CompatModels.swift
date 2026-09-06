// CompatModels.swift
// Codable mirror of server/src/compat/seed.json and server/src/compat/service.ts (spec §4).

import Foundation

// MARK: - Enumerations

public enum CompatRuntime: String, Codable, CaseIterable, Hashable, Sendable {
    case vm
    case bottle
    case either

    public var displayName: String {
        switch self {
        case .vm: return "Machine"
        case .bottle: return "Bottle"
        case .either: return "Machine or Bottle"
        }
    }

    /// True when an app with this runtime satisfies a filter for `wanted`
    /// (mirror of the server's search: `either` matches every runtime filter).
    public func matches(_ wanted: CompatRuntime) -> Bool {
        self == wanted || self == .either
    }
}

/// Spec §4 ratings.
public enum CompatRating: String, Codable, CaseIterable, Hashable, Sendable {
    case gold
    case silver
    case bronze
    case broken
    case notApplicable = "n/a"

    public var displayName: String {
        switch self {
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .bronze: return "Bronze"
        case .broken: return "Broken"
        case .notApplicable: return "Native Mac"
        }
    }

    public var summary: String {
        switch self {
        case .gold: return "Works out of the box"
        case .silver: return "Works with fix-ups"
        case .bronze: return "Usable, known issues"
        case .broken: return "Does not work"
        case .notApplicable: return "Use the native Mac version"
        }
    }

    public var symbolName: String {
        switch self {
        case .gold: return "medal"
        case .silver: return "medal"
        case .bronze: return "medal"
        case .broken: return "xmark.octagon"
        case .notApplicable: return "apple.logo"
        }
    }

    /// Higher is better; used for sorting.
    public var score: Int {
        switch self {
        case .gold: return 4
        case .silver: return 3
        case .bronze: return 2
        case .broken: return 0
        case .notApplicable: return 1
        }
    }
}

/// Known vendor-support values in the seed; other strings are kept verbatim in `CompatApp.vendorSupport`.
public enum VendorSupport: String, Codable, CaseIterable, Hashable, Sendable {
    case supported
    case unsupported
    case unsupportedInVM = "unsupported_in_vm"
    case nativeMacAvailable = "native_mac_available"

    public var displayName: String {
        switch self {
        case .supported: return "Vendor supported"
        case .unsupported: return "Not supported by vendor"
        case .unsupportedInVM: return "Vendor does not certify VMs"
        case .nativeMacAvailable: return "Native Mac version available"
        }
    }
}

/// Known fix-up types in the seed.
public enum FixupKind: String, Codable, CaseIterable, Hashable, Sendable {
    case hostRequirement = "host_requirement"
    case guestSetting = "guest_setting"
    case preset
    case sysvar
    case env
    case vmSetting = "vm_setting"
    case bottleSetting = "bottle_setting"

    public var displayName: String {
        switch self {
        case .hostRequirement: return "Mac requirement"
        case .guestSetting: return "Guest setting"
        case .preset: return "Preset"
        case .sysvar: return "System variable"
        case .env: return "Environment variable"
        case .vmSetting: return "Machine setting"
        case .bottleSetting: return "Bottle setting"
        }
    }
}

// MARK: - JSON value

/// Loss-free representation of the free-form `requirements` and preset dictionaries.
public enum JSONValue: Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    public var intValue: Int? {
        guard let value = doubleValue, value.rounded() == value, abs(value) < Double(Int.max) else { return nil }
        return Int(value)
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    /// Human-readable rendering for settings lists ("4096", "on", "best-for-cad").
    public var displayString: String {
        switch self {
        case .string(let value): return value
        case .number(let value): return value.rounded() == value ? String(Int(value)) : String(value)
        case .bool(let value): return value ? "on" : "off"
        case .null: return "—"
        case .array(let values): return values.map(\.displayString).joined(separator: ", ")
        case .object(let object): return object.keys.sorted().map { "\($0): \(object[$0]!.displayString)" }.joined(separator: ", ")
        }
    }
}

extension JSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

// MARK: - App profile

public struct CompatFixup: Codable, Hashable, Sendable {
    public var type: String
    public var key: String?
    public var value: String?
    public var reason: String?
    /// Wire key `optional`; nil means required.
    public var isOptional: Bool?

    enum CodingKeys: String, CodingKey {
        case type, key, value, reason
        case isOptional = "optional"
    }

    public init(type: String, key: String? = nil, value: String? = nil, reason: String? = nil, isOptional: Bool? = nil) {
        self.type = type
        self.key = key
        self.value = value
        self.reason = reason
        self.isOptional = isOptional
    }

    public var kind: FixupKind? { FixupKind(rawValue: type) }
    public var isRequired: Bool { !(isOptional ?? false) }

    /// "DYNMODE = 0", "preset cad-graphics", "requires rosetta2".
    public var summary: String {
        switch (kind, key, value) {
        case (.hostRequirement, _, let value?): return "Requires \(value)"
        case (.preset, _, let value?): return "Preset: \(value)"
        case (_, let key?, let value?): return "\(key) = \(value)"
        case (_, let key?, nil): return key
        case (_, nil, let value?): return value
        default: return type
        }
    }
}

/// `requirements` is a free-form object on the server; typed accessors cover the seed's keys.
public struct CompatRequirements: Codable, Hashable, Sendable {
    public var values: [String: JSONValue]

    public init(values: [String: JSONValue] = [:]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        values = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    public subscript(key: String) -> JSONValue? { values[key] }

    public var directX: String? { values["dx"]?.stringValue }
    public var directXRecommended: String? { values["dx_recommended"]?.stringValue }
    public var openGL: String? { values["opengl"]?.stringValue }
    public var ramGB: Int? { values["ram_gb"]?.intValue }
    public var diskGB: Int? { values["disk_gb"]?.intValue }
    public var guestRuntimes: [String] { values["guest_runtimes"]?.arrayValue?.compactMap(\.stringValue) ?? [] }
}

/// Community report counts (`GET /v1/compat/apps/:id`).
public struct CommunityStats: Codable, Hashable, Sendable {
    public var works: Int
    public var worksWithFixups: Int
    public var partial: Int
    public var broken: Int
    public var total: Int

    enum CodingKeys: String, CodingKey {
        case works
        case worksWithFixups = "works_with_fixups"
        case partial, broken, total
    }

    public init(works: Int = 0, worksWithFixups: Int = 0, partial: Int = 0, broken: Int = 0, total: Int = 0) {
        self.works = works
        self.worksWithFixups = worksWithFixups
        self.partial = partial
        self.broken = broken
        self.total = total
    }

    /// Share of reports that are `works` or `works_with_fixups`, 0…1.
    public var successRate: Double? {
        guard total > 0 else { return nil }
        return Double(works + worksWithFixups) / Double(total)
    }
}

public struct CompatApp: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var vendor: String
    public var category: String
    public var runtime: CompatRuntime
    public var rating: CompatRating
    public var versions: [String]?
    public var arch: String?
    public var vendorSupport: String?
    public var notes: String?
    public var requirements: CompatRequirements?
    public var fixups: [CompatFixup]
    /// Present only in `GET /v1/compat/apps/:id` responses.
    public var community: CommunityStats?

    enum CodingKeys: String, CodingKey {
        case id, name, vendor, category, runtime, rating, versions, arch
        case vendorSupport = "vendor_support"
        case notes, requirements, fixups, community
    }

    public init(
        id: String,
        name: String,
        vendor: String,
        category: String,
        runtime: CompatRuntime,
        rating: CompatRating,
        versions: [String]? = nil,
        arch: String? = nil,
        vendorSupport: String? = nil,
        notes: String? = nil,
        requirements: CompatRequirements? = nil,
        fixups: [CompatFixup] = [],
        community: CommunityStats? = nil
    ) {
        self.id = id
        self.name = name
        self.vendor = vendor
        self.category = category
        self.runtime = runtime
        self.rating = rating
        self.versions = versions
        self.arch = arch
        self.vendorSupport = vendorSupport
        self.notes = notes
        self.requirements = requirements
        self.fixups = fixups
        self.community = community
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        vendor = try container.decode(String.self, forKey: .vendor)
        category = try container.decode(String.self, forKey: .category)
        runtime = try container.decode(CompatRuntime.self, forKey: .runtime)
        rating = try container.decode(CompatRating.self, forKey: .rating)
        versions = try container.decodeIfPresent([String].self, forKey: .versions)
        arch = try container.decodeIfPresent(String.self, forKey: .arch)
        vendorSupport = try container.decodeIfPresent(String.self, forKey: .vendorSupport)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        requirements = try container.decodeIfPresent(CompatRequirements.self, forKey: .requirements)
        fixups = try container.decodeIfPresent([CompatFixup].self, forKey: .fixups) ?? []
        community = try container.decodeIfPresent(CommunityStats.self, forKey: .community)
    }

    public var vendorSupportKind: VendorSupport? { vendorSupport.flatMap(VendorSupport.init(rawValue:)) }
    public var hasNativeMacVersion: Bool { vendorSupportKind == .nativeMacAvailable || rating == .notApplicable }
    public var presetName: String? { fixups.first { $0.kind == .preset }?.value }
    public var requiresRosetta: Bool { fixups.contains { $0.kind == .hostRequirement && $0.value == "rosetta2" } }
    public var categoryDisplayName: String { CompatCategory.displayName(for: category) }

    /// Local mirror of the server's `search` matcher.
    public func matches(query needle: String) -> Bool {
        let needle = needle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty { return true }
        return id.contains(needle) || name.lowercased().contains(needle) || vendor.lowercased().contains(needle)
    }
}

/// Categories are free strings on the server; this maps the seed's values to labels.
public enum CompatCategory {
    public static let known: [String: String] = [
        "cad": "CAD", "bim": "BIM", "gis": "GIS", "productivity": "Productivity", "finance": "Finance",
        "engineering": "Engineering", "eda": "Electronics (EDA)", "games": "Games", "utility": "Utilities",
        "enterprise": "Enterprise", "developer": "Developer tools", "creative": "Creative",
    ]

    public static func displayName(for raw: String) -> String {
        known[raw] ?? raw.capitalized
    }
}

// MARK: - Presets and catalog

public struct CompatPreset: Codable, Hashable, Sendable {
    public var description: String?
    public var vm: [String: JSONValue]?
    public var guest: [String: JSONValue]?
    public var bottle: [String: JSONValue]?

    public init(description: String? = nil, vm: [String: JSONValue]? = nil, guest: [String: JSONValue]? = nil, bottle: [String: JSONValue]? = nil) {
        self.description = description
        self.vm = vm
        self.guest = guest
        self.bottle = bottle
    }
}

/// The catalog: the full seed, or the `{ version, apps }` shape of `GET /v1/compat/apps`.
public struct CompatCatalog: Codable, Hashable, Sendable {
    public var version: String
    public var runtimes: [String: String]
    public var apps: [CompatApp]
    public var presets: [String: CompatPreset]

    enum CodingKeys: String, CodingKey {
        case version, runtimes, apps, presets
    }

    public init(version: String, runtimes: [String: String] = [:], apps: [CompatApp], presets: [String: CompatPreset] = [:]) {
        self.version = version
        self.runtimes = runtimes
        self.apps = apps
        self.presets = presets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        runtimes = try container.decodeIfPresent([String: String].self, forKey: .runtimes) ?? [:]
        // One malformed entry (e.g. a rating added by a newer server) must not drop the catalog.
        apps = try container.decode([LossyDecodable<CompatApp>].self, forKey: .apps).compactMap(\.value)
        presets = try container.decodeIfPresent([String: CompatPreset].self, forKey: .presets) ?? [:]
    }

    public static let empty = CompatCatalog(version: "0", apps: [])

    public func app(id: String) -> CompatApp? { apps.first { $0.id == id } }

    /// Distinct categories in catalog order of first appearance.
    public var categories: [String] {
        var seen: Set<String> = []
        return apps.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }
}

/// Decodes to `nil` instead of failing the enclosing array.
public struct LossyDecodable<Value: Decodable>: Decodable {
    public let value: Value?

    public init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

// MARK: - Reports and routing

public enum CompatReportResult: String, Codable, CaseIterable, Hashable, Sendable {
    case works
    case worksWithFixups = "works_with_fixups"
    case partial
    case broken

    public var displayName: String {
        switch self {
        case .works: return "Works"
        case .worksWithFixups: return "Works with fix-ups"
        case .partial: return "Partially works"
        case .broken: return "Broken"
        }
    }
}

/// Anonymous, opt-in compatibility report (`POST /v1/compat/reports`). By construction it
/// carries no identifiers — only the app, the outcome and hardware class.
public struct CompatReport: Codable, Hashable, Sendable {
    public var appID: String
    public var appVersion: String?
    public var runtime: CompatRuntime?
    public var result: CompatReportResult
    public var macModel: String?
    public var macOSVersion: String?
    public var mirrorzVersion: String?
    public var notes: String?

    enum CodingKeys: String, CodingKey {
        case appID = "app_id"
        case appVersion = "app_version"
        case runtime, result
        case macModel = "mac_model"
        case macOSVersion = "macos_version"
        case mirrorzVersion = "mirrorz_version"
        case notes
    }

    public init(
        appID: String,
        appVersion: String? = nil,
        runtime: CompatRuntime? = nil,
        result: CompatReportResult,
        macModel: String? = nil,
        macOSVersion: String? = nil,
        mirrorzVersion: String? = nil,
        notes: String? = nil
    ) {
        self.appID = String(appID.prefix(80))
        self.appVersion = appVersion.map { String($0.prefix(40)) }
        self.runtime = runtime
        self.result = result
        self.macModel = macModel.map { String($0.prefix(80)) }
        self.macOSVersion = macOSVersion.map { String($0.prefix(40)) }
        self.mirrorzVersion = mirrorzVersion.map { String($0.prefix(40)) }
        self.notes = notes.map { String($0.prefix(500)) }
    }
}

public struct CompatReportReceipt: Codable, Hashable, Sendable {
    public var accepted: Bool

    public init(accepted: Bool) {
        self.accepted = accepted
    }
}

/// Input of `POST /v1/compat/route`: metadata extracted from an unknown installer.
public struct RouteRequest: Codable, Hashable, Sendable {
    public enum Architecture: String, Codable, Hashable, Sendable {
        case x86
        case x64
        case arm64
    }

    public var arch: Architecture?
    public var needsDriver: Bool?
    public var needsService: Bool?
    public var dotnet: String?
    public var dx: String?

    enum CodingKeys: String, CodingKey {
        case arch
        case needsDriver = "needs_driver"
        case needsService = "needs_service"
        case dotnet, dx
    }

    public init(arch: Architecture? = nil, needsDriver: Bool? = nil, needsService: Bool? = nil, dotnet: String? = nil, dx: String? = nil) {
        self.arch = arch
        self.needsDriver = needsDriver
        self.needsService = needsService
        self.dotnet = dotnet
        self.dx = dx
    }

    /// Offline mirror of the server's `routeUnknown` heuristic (identical decisions).
    public var localDecision: RouteDecision {
        if needsDriver == true || needsService == true {
            return RouteDecision(runtime: .vm, reason: "kernel driver or Windows service required")
        }
        if dx == "12" {
            return RouteDecision(runtime: .vm, reason: "DirectX 12 is more reliable in the VM path today")
        }
        if arch == .arm64 {
            return RouteDecision(runtime: .vm, reason: "ARM64-native Windows binaries run at full speed in the VM")
        }
        return RouteDecision(runtime: .bottle, reason: "Bottle first: fastest launch, no Windows license; VM fallback on failure")
    }
}

public struct RouteDecision: Codable, Hashable, Sendable {
    public var runtime: CompatRuntime
    public var reason: String

    public init(runtime: CompatRuntime, reason: String) {
        self.runtime = runtime
        self.reason = reason
    }
}
