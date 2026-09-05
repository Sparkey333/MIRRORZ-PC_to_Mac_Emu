// Feature.swift
// Feature flags gate premium tooling in the clients. Raw values are the exact strings
// from server/src/license/plans.ts and ship inside device tokens; never rename a raw value.

import Foundation

public enum Feature: String, Codable, CaseIterable, Hashable, Sendable {
    // trial
    case vm
    case bottles
    case coherence
    case compatDB = "compat-db"
    // standard
    case snapshots
    case cadPresets = "cad-presets"
    case mobileCompanion = "mobile-companion"
    case noAds = "no-ads"
    // pro
    case cli
    case api
    case nestedVirt = "nested-virt"
    case linkedClones = "linked-clones"
    case proTools = "pro-tools"
    case cloudSync = "cloud-sync"
    case prioritySupport = "priority-support"
    case networkLab = "network-lab"
    // business
    case mdm
    case sso
    case volumeLicensing = "volume-licensing"
    case goldenImages = "golden-images"
    case auditLog = "audit-log"

    /// Builds a feature set from the raw strings carried in a token or a license view.
    /// Unknown strings (features introduced by a newer server) are ignored rather than
    /// failing the whole token, so older builds keep working after a server upgrade.
    public static func set(from raw: [String]) -> Set<Feature> {
        Set(raw.compactMap(Feature.init(rawValue:)))
    }

    /// Lowest plan that includes the feature (mirrors PLAN_FEATURES).
    public var minimumPlan: Plan {
        switch self {
        case .vm, .bottles, .coherence, .compatDB:
            return .trial
        case .snapshots, .cadPresets, .mobileCompanion, .noAds:
            return .standard
        case .cli, .api, .nestedVirt, .linkedClones, .proTools, .cloudSync, .prioritySupport, .networkLab:
            return .pro
        case .mdm, .sso, .volumeLicensing, .goldenImages, .auditLog:
            return .business
        }
    }

    /// Short user-facing name (spec vocabulary §1).
    public var displayName: String {
        switch self {
        case .vm: return "Machines"
        case .bottles: return "Bottles"
        case .coherence: return "Mirror Mode"
        case .compatDB: return "Compatibility Database"
        case .snapshots: return "Snapshots"
        case .cadPresets: return "CAD presets"
        case .mobileCompanion: return "Mobile companion"
        case .noAds: return "No ads, ever"
        case .cli: return "Command-line tool"
        case .api: return "Automation API"
        case .nestedVirt: return "Nested virtualization"
        case .linkedClones: return "Linked clones"
        case .proTools: return "Pro tools"
        case .cloudSync: return "Cloud sync"
        case .prioritySupport: return "Priority support"
        case .networkLab: return "Network lab"
        case .mdm: return "MDM deployment"
        case .sso: return "Single sign-on"
        case .volumeLicensing: return "Volume licensing"
        case .goldenImages: return "Golden images"
        case .auditLog: return "Audit log"
        }
    }

    /// One-line explanation shown on plan cards and locked states.
    public var summary: String {
        switch self {
        case .vm: return "Full Windows and Linux virtual machines."
        case .bottles: return "Lightweight Wine-based environments, no Windows license needed."
        case .coherence: return "Windows app windows appear as native Mac windows."
        case .compatDB: return "Curated fix-ups and ratings for thousands of PC apps."
        case .snapshots: return "Roll a Machine back to any saved state."
        case .cadPresets: return "Tuned graphics and mouse settings for AutoCAD, Revit and SOLIDWORKS."
        case .mobileCompanion: return "View and control your Mac's Apps from iPhone, iPad or Android."
        case .noAds: return "No ads, no nag screens, no upsell pop-ups."
        case .cli: return "Script Machines and Bottles from the Terminal."
        case .api: return "Local automation API for CI and tooling."
        case .nestedVirt: return "Run hypervisors inside a Machine."
        case .linkedClones: return "Clone a Machine in seconds without copying its disk."
        case .proTools: return "Network conditioning, disk tools and diagnostics."
        case .cloudSync: return "Sync Apps and settings across your Macs."
        case .prioritySupport: return "Front-of-queue support from engineers."
        case .networkLab: return "Isolated virtual networks for testing."
        case .mdm: return "Deploy and configure via MDM profiles."
        case .sso: return "Sign in with your identity provider."
        case .volumeLicensing: return "Per-seat licensing managed centrally."
        case .goldenImages: return "Distribute pre-configured Machines to your team."
        case .auditLog: return "Track licensing and configuration changes."
        }
    }

    /// SF Symbol name used next to the feature.
    public var symbolName: String {
        switch self {
        case .vm: return "desktopcomputer"
        case .bottles: return "shippingbox"
        case .coherence: return "macwindow.on.rectangle"
        case .compatDB: return "checkmark.seal"
        case .snapshots: return "camera.on.rectangle"
        case .cadPresets: return "pencil.and.ruler"
        case .mobileCompanion: return "iphone"
        case .noAds: return "hand.raised"
        case .cli: return "terminal"
        case .api: return "curlybraces"
        case .nestedVirt: return "square.stack.3d.up"
        case .linkedClones: return "doc.on.doc"
        case .proTools: return "wrench.and.screwdriver"
        case .cloudSync: return "icloud"
        case .prioritySupport: return "bubble.left.and.bubble.right"
        case .networkLab: return "network"
        case .mdm: return "building.2"
        case .sso: return "person.badge.key"
        case .volumeLicensing: return "person.3"
        case .goldenImages: return "star.square.on.square"
        case .auditLog: return "list.bullet.clipboard"
        }
    }
}
