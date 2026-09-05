// Plan.swift
// Plans, license kinds and purchase terms (spec §2, server/src/license/plans.ts).

import Foundation

/// Plan identifiers. Raw values are the exact strings carried in tokens (`claims.plan`).
public enum Plan: String, Codable, CaseIterable, Hashable, Sendable {
    case trial
    case standard
    case pro
    case business

    /// Mirror of PLAN_FEATURES in server/src/license/plans.ts.
    public var features: Set<Feature> {
        switch self {
        case .trial:
            return [.vm, .bottles, .coherence, .compatDB]
        case .standard:
            return Plan.trial.features.union([.snapshots, .cadPresets, .mobileCompanion, .noAds])
        case .pro:
            return Plan.standard.features.union([
                .cli, .api, .nestedVirt, .linkedClones, .proTools, .cloudSync, .prioritySupport, .networkLab,
            ])
        case .business:
            return Plan.pro.features.union([.mdm, .sso, .volumeLicensing, .goldenImages, .auditLog])
        }
    }

    /// Mirror of `featuresFor(plan)`: unknown plan strings fall back to Standard.
    public static func features(forPlanNamed raw: String) -> Set<Feature> {
        (Plan(rawValue: raw) ?? .standard).features
    }

    /// Marketing name, e.g. "MIRRORZ Standard" (pricing/pricing.json).
    public var displayName: String {
        switch self {
        case .trial: return "MIRRORZ Trial"
        case .standard: return "MIRRORZ Standard"
        case .pro: return "MIRRORZ Pro"
        case .business: return "MIRRORZ Business"
        }
    }

    /// Short name used in chips and pickers.
    public var shortName: String {
        switch self {
        case .trial: return "Trial"
        case .standard: return "Standard"
        case .pro: return "Pro"
        case .business: return "Business"
        }
    }

    /// Tagline from pricing/pricing.json.
    public var tagline: String {
        switch self {
        case .trial: return "14 days, every Standard feature, no card required."
        case .standard: return "Run Windows and PC apps on your Mac. AutoCAD-ready."
        case .pro: return "Everything in Standard plus developer & power tools."
        case .business: return "Per-seat, centrally managed, MDM-deployable."
        }
    }

    /// Devices per license (pricing.json `devices`); Business is per seat.
    public var deviceLimit: Int {
        switch self {
        case .trial: return 1
        case .standard: return 3
        case .pro: return 5
        case .business: return 2
        }
    }

    /// Ordering used to decide whether a plan covers a feature's minimum plan.
    public var rank: Int {
        switch self {
        case .trial: return 0
        case .standard: return 1
        case .pro: return 2
        case .business: return 3
        }
    }

    /// True when the plan is sold through the App Store (Business is direct only).
    public var isSoldInAppStore: Bool {
        self == .standard || self == .pro
    }

    /// Plans offered on the paywall, in display order.
    public static let purchasable: [Plan] = [.standard, .pro]
}

extension Plan: Comparable {
    public static func < (lhs: Plan, rhs: Plan) -> Bool { lhs.rank < rhs.rank }
}

/// License kind (`claims.kind`), mirror of `LicenseKind` in server/src/license/token.ts.
public enum LicenseKind: String, Codable, CaseIterable, Hashable, Sendable {
    case perpetual
    case subscription
    case trial

    public var displayName: String {
        switch self {
        case .perpetual: return "Perpetual"
        case .subscription: return "Subscription"
        case .trial: return "Trial"
        }
    }
}

/// How a plan is bought. Perpetual is a one-time purchase that never expires
/// (12 months of feature updates, security updates forever).
public enum PurchaseTerm: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case monthly
    case annual
    case perpetual

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .perpetual: return "Perpetual"
        }
    }

    /// Suffix shown after a price, e.g. "$7.99 / month".
    public var priceSuffix: String {
        switch self {
        case .monthly: return "/ month"
        case .annual: return "/ year"
        case .perpetual: return "one time"
        }
    }

    public var licenseKind: LicenseKind {
        self == .perpetual ? .perpetual : .subscription
    }
}

/// License status as reported by the server's license view.
public enum LicenseStatus: String, Codable, Hashable, Sendable {
    case active
    case expired
    case revoked
    case refunded
    case paused
}
