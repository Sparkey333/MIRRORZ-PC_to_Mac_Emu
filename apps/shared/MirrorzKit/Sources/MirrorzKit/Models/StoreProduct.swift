// StoreProduct.swift
// Store product identifiers (identical on App Store Connect, Google Play and Stripe lookup keys).
// Mirror of server/src/billing/products.ts and spec §2.

import Foundation

public enum StoreProductID: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case standardMonthly = "com.mirrorz.standard.monthly"
    case standardAnnual = "com.mirrorz.standard.annual"
    case standardPerpetual = "com.mirrorz.standard.perpetual"
    case proMonthly = "com.mirrorz.pro.monthly"
    case proAnnual = "com.mirrorz.pro.annual"
    case proPerpetual = "com.mirrorz.pro.perpetual"
    case businessAnnual = "com.mirrorz.business.annual"

    public var id: String { rawValue }

    public var plan: Plan {
        switch self {
        case .standardMonthly, .standardAnnual, .standardPerpetual: return .standard
        case .proMonthly, .proAnnual, .proPerpetual: return .pro
        case .businessAnnual: return .business
        }
    }

    public var term: PurchaseTerm {
        switch self {
        case .standardMonthly, .proMonthly: return .monthly
        case .standardAnnual, .proAnnual, .businessAnnual: return .annual
        case .standardPerpetual, .proPerpetual: return .perpetual
        }
    }

    public var kind: LicenseKind { term.licenseKind }

    /// Business is sold direct only (Stripe / invoice); the stores list the six consumer products.
    public var isSoldInAppStore: Bool { plan.isSoldInAppStore }

    /// Product ids to request from StoreKit / Play Billing.
    public static let appStoreProductIDs: [String] = allCases.filter(\.isSoldInAppStore).map(\.rawValue)

    public static func product(plan: Plan, term: PurchaseTerm) -> StoreProductID? {
        allCases.first { $0.plan == plan && $0.term == term }
    }
}
