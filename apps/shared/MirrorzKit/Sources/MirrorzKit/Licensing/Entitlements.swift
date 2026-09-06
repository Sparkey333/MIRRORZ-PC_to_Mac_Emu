// Entitlements.swift
// The single observable that exposes the device's entitlement to the UI (spec §3.4).
//
// Rules implemented here:
//  1. Tokens are verified against the embedded trusted keys and the local device id.
//  2. perpetual: entitled forever. Builds dated after `upd` run in "updates expired" mode
//     (fully functional, no feature gating, banner offering the upgrade price).
//  3. subscription | trial: entitled while now < sub_exp. Refreshed every 24 h when online.
//     403 on refresh drops the entitlement immediately; network errors keep it until sub_exp.
//  4. Never more than one licensing call per day per device (user-initiated calls aside);
//     never blocks app launch — `bootstrap()` is synchronous and local, refreshes run detached.
//  5. The token lives in the keychain; `features` is the only thing the UI consults.

import Foundation
import Observation

/// Entitlement mode (spec §3.4).
public enum EntitlementMode: String, Hashable, Sendable, Codable {
    /// No valid token on this device.
    case none
    /// Entitled with all features of the plan.
    case full
    /// Perpetual license whose feature-update window ended before this build; still entitled.
    case updatesExpired = "updates_expired"
    /// Subscription or trial ended, or the server refused the refresh.
    case expired
}

/// Pure result of applying the rules to a claim set.
public struct EntitlementSnapshot: Hashable, Sendable {
    public var mode: EntitlementMode
    public var plan: Plan?
    public var kind: LicenseKind?
    public var features: Set<Feature>
    public var claims: LicenseClaims?

    public init(mode: EntitlementMode, plan: Plan? = nil, kind: LicenseKind? = nil, features: Set<Feature> = [], claims: LicenseClaims? = nil) {
        self.mode = mode
        self.plan = plan
        self.kind = kind
        self.features = features
        self.claims = claims
    }

    public static let none = EntitlementSnapshot(mode: .none)

    public var isEntitled: Bool { mode == .full || mode == .updatesExpired }
}

public struct EntitlementsConfiguration: Sendable {
    /// Embedded Ed25519 public keys `[{kid, x}]`.
    public var trustedKeys: [TrustedKey]
    /// The device record sent with licensing calls; its `id` is the token binding.
    public var device: DeviceRecord
    public var buildInfo: BuildInfo
    /// Spec: 24 h.
    public var refreshInterval: TimeInterval
    /// Injectable clock for tests.
    public var now: @Sendable () -> Date
    /// Keychain account holding the persisted state.
    public var stateAccount: String
    /// Runs the daily background refresh loop. Tests turn it off for determinism.
    public var automaticRefresh: Bool

    public init(
        trustedKeys: [TrustedKey],
        device: DeviceRecord,
        buildInfo: BuildInfo,
        refreshInterval: TimeInterval = 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = { Date() },
        stateAccount: String = "license-state",
        automaticRefresh: Bool = true
    ) {
        self.trustedKeys = trustedKeys
        self.device = device
        self.buildInfo = buildInfo
        self.refreshInterval = refreshInterval
        self.now = now
        self.stateAccount = stateAccount
        self.automaticRefresh = automaticRefresh
    }
}

/// Everything persisted in the keychain.
struct EntitlementsPersistedState: Codable, Sendable, Hashable {
    var token: String?
    /// Human key when known (typed by the user, or returned once by a store link).
    var licenseKey: String?
    var lastRefreshAttempt: Date?
    var lastRefreshSuccess: Date?
    /// Set when a refresh returned 403; cleared by the next successful refresh or activation.
    var droppedAt: Date?
    var droppedReason: String?
    var license: LicenseView?
}

@MainActor
@Observable
public final class Entitlements {
    public typealias Mode = EntitlementMode
    public typealias Snapshot = EntitlementSnapshot
    public typealias Configuration = EntitlementsConfiguration
    typealias PersistedState = EntitlementsPersistedState

    // MARK: Observable state

    public private(set) var snapshot: Snapshot = .none
    /// Last license view received from the server (devices, status, entitlement).
    public private(set) var license: LicenseView?
    /// The human license key when known; shown in Settings › License & Plans.
    public private(set) var licenseKey: String?
    public private(set) var lastRefreshAttempt: Date?
    public private(set) var lastRefreshSuccess: Date?
    public private(set) var lastError: (any Error)?
    public private(set) var isRefreshing = false
    public private(set) var isBootstrapped = false

    public var mode: Mode { snapshot.mode }
    public var plan: Plan? { snapshot.plan }
    public var kind: LicenseKind? { snapshot.kind }
    public var features: Set<Feature> { snapshot.features }
    public var claims: LicenseClaims? { snapshot.claims }
    public var isEntitled: Bool { snapshot.isEntitled }
    public var hasToken: Bool { persisted.token != nil }

    /// Reason the entitlement was dropped by the server (`expired`, `revoked`, `refunded`, `paused`…).
    public var droppedReason: APIErrorCode? { persisted.droppedReason.map(APIErrorCode.init(rawValue:)) }

    public let configuration: Configuration
    public let client: LicenseClient

    @ObservationIgnored private let store: SecureStore
    @ObservationIgnored private var persisted = PersistedState()
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    public init(configuration: Configuration, client: LicenseClient, store: SecureStore = KeychainStore()) {
        self.configuration = configuration
        self.client = client
        self.store = store
    }

    // MARK: Lifecycle

    /// Loads the keychain state and evaluates it locally. Call once at launch; it performs
    /// no network work, so the app never waits on licensing to show its first window.
    public func bootstrap() {
        persisted = (try? store.decode(PersistedState.self, forKey: configuration.stateAccount)) ?? PersistedState()
        evaluate()
        isBootstrapped = true
        scheduleRefreshLoop()
    }

    /// Feature gate used by the UI and the engines.
    public func has(_ feature: Feature) -> Bool {
        snapshot.features.contains(feature)
    }

    /// Lowest plan that unlocks a feature (for locked states).
    public func planRequired(for feature: Feature) -> Plan {
        feature.minimumPlan
    }

    // MARK: Derived values for the UI

    public var subscriptionEndsAt: Date? { snapshot.claims?.subscriptionEndsAt }
    public var updatesUntil: Date? { snapshot.claims?.updatesUntil }
    public var isTrial: Bool { snapshot.kind == .trial }

    /// Whole days left on a trial or subscription (nil for perpetual / no license).
    public var daysRemaining: Int? {
        guard let end = subscriptionEndsAt, snapshot.kind != .perpetual else { return nil }
        let seconds = end.timeIntervalSince(configuration.now())
        return max(0, Int((seconds / 86_400).rounded(.up)))
    }

    /// True for perpetual licenses whose feature-update window has ended for this build.
    public var showsUpdateUpgradeBanner: Bool { snapshot.mode == .updatesExpired }

    // MARK: Mutations

    /// Verifies and stores a token received from activation, trial, refresh or a store link.
    public func apply(token: String, license: LicenseView?, key: String? = nil) throws {
        _ = try LicenseToken.verify(token, trustedKeys: configuration.trustedKeys, deviceID: configuration.device.id)
        persisted.token = token
        persisted.droppedAt = nil
        persisted.droppedReason = nil
        if let license { persisted.license = license }
        if let key, let canonical = LicenseKey.canonical(key) { persisted.licenseKey = canonical }
        save()
        evaluate()
        scheduleRefreshLoop()
    }

    /// `POST /v1/licenses/activate` with a typed key, then stores the token.
    @discardableResult
    public func activate(key: String) async throws -> LicenseView {
        guard let canonical = LicenseKey.canonical(key) else { throw APIClientError.invalidKey }
        let response = try await client.activate(key: canonical, device: configuration.device)
        try apply(token: response.token, license: response.license, key: canonical)
        markRefreshed(success: true)
        return response.license
    }

    /// `POST /v1/trials` — 14-day trial, one per device.
    @discardableResult
    public func startTrial() async throws -> TrialResponse {
        let response = try await client.startTrial(device: configuration.device)
        try apply(token: response.token, license: response.license)
        markRefreshed(success: true)
        return response
    }

    /// Deactivates a device on the current license (needs the key). Deactivating this device
    /// also clears the local entitlement.
    public func deactivate(deviceID: String) async throws {
        guard let key = persisted.licenseKey else { throw EntitlementsError.keyUnknown }
        let response = try await client.deactivate(key: key, deviceID: deviceID)
        if deviceID == configuration.device.id {
            clear()
        } else {
            persisted.license = response.license
            license = response.license
            save()
        }
    }

    /// Removes the token and license from this device (local only).
    public func clear() {
        persisted = PersistedState()
        lastError = nil
        save()
        evaluate()
    }

    /// Refreshes the token when the 24 h window has elapsed. Safe to call on every
    /// foreground; it returns immediately when nothing is due.
    public func refreshIfNeeded() async {
        guard persisted.token != nil, !isRefreshing else { return }
        if let last = persisted.lastRefreshAttempt, configuration.now().timeIntervalSince(last) < configuration.refreshInterval {
            return
        }
        await performRefresh()
    }

    /// User-initiated refresh ("Check license now"). Bypasses the daily throttle.
    public func refreshNow() async throws {
        guard persisted.token != nil else { throw EntitlementsError.noToken }
        await performRefresh()
        if let error = lastError { throw error }
    }

    // MARK: Pure evaluation

    /// Applies spec §3.4 to a verified claim set. `dropped` is true after a 403 refresh.
    public nonisolated static func evaluate(claims: LicenseClaims?, now: Date, buildDate: Date, dropped: Bool = false) -> Snapshot {
        guard let claims else { return .none }
        let plan = claims.planID
        if dropped {
            return Snapshot(mode: .expired, plan: plan, kind: claims.kind, features: [], claims: claims)
        }
        switch claims.kind {
        case .perpetual:
            let build = Int(buildDate.timeIntervalSince1970)
            let mode: Mode = (claims.upd.map { build <= $0 } ?? true) ? .full : .updatesExpired
            return Snapshot(mode: mode, plan: plan, kind: .perpetual, features: claims.featureSet, claims: claims)
        case .subscription, .trial:
            let ends = claims.subExp ?? claims.exp
            let entitled = Int(now.timeIntervalSince1970) < ends
            return Snapshot(mode: entitled ? .full : .expired, plan: plan, kind: claims.kind, features: entitled ? claims.featureSet : [], claims: claims)
        }
    }

    // MARK: Internals

    private func evaluate() {
        var claims: LicenseClaims?
        if let token = persisted.token {
            do {
                claims = try LicenseToken.verify(token, trustedKeys: configuration.trustedKeys, deviceID: configuration.device.id)
            } catch {
                // A token that no longer verifies (key rotation, device id change) is useless; drop it.
                lastError = error
                persisted.token = nil
                save()
            }
        }
        snapshot = Self.evaluate(
            claims: claims,
            now: configuration.now(),
            buildDate: configuration.buildInfo.buildDate,
            dropped: persisted.droppedAt != nil
        )
        license = persisted.license
        licenseKey = persisted.licenseKey
        lastRefreshAttempt = persisted.lastRefreshAttempt
        lastRefreshSuccess = persisted.lastRefreshSuccess
    }

    private func performRefresh() async {
        guard let token = persisted.token else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        markRefreshed(success: false)
        do {
            let response = try await client.refresh(token: token)
            try apply(token: response.token, license: response.license)
            markRefreshed(success: true)
            lastError = nil
        } catch let error as APIClientError {
            lastError = error
            if let api = error.apiError, api.isForbidden {
                // Spec §3.4 rule 3: drop the entitlement immediately.
                persisted.droppedAt = configuration.now()
                persisted.droppedReason = api.code.rawValue
                save()
                evaluate()
            }
            // Network errors and other statuses: keep working until sub_exp.
        } catch {
            lastError = error
        }
    }

    private func markRefreshed(success: Bool) {
        let now = configuration.now()
        persisted.lastRefreshAttempt = now
        if success { persisted.lastRefreshSuccess = now }
        lastRefreshAttempt = persisted.lastRefreshAttempt
        lastRefreshSuccess = persisted.lastRefreshSuccess
        save()
    }

    private func save() {
        do {
            try store.encode(persisted, forKey: configuration.stateAccount)
        } catch {
            lastError = error
        }
    }

    /// Seconds until the next refresh is due (0 when overdue, nil when there is no token).
    private func secondsUntilNextRefresh() -> TimeInterval? {
        guard persisted.token != nil else { return nil }
        guard let last = persisted.lastRefreshAttempt else { return 0 }
        return max(0, configuration.refreshInterval - configuration.now().timeIntervalSince(last))
    }

    /// Background loop: sleeps until the next daily refresh, runs it, repeats. Started by
    /// `bootstrap()` and restarted whenever a token is applied. Never blocks the caller.
    private func scheduleRefreshLoop() {
        refreshTask?.cancel()
        guard configuration.automaticRefresh else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let wait = self.secondsUntilNextRefresh() ?? 60 * 60
                if wait > 0 {
                    do {
                        try await Task.sleep(for: .seconds(wait))
                    } catch {
                        return
                    }
                }
                if Task.isCancelled { return }
                await self.refreshIfNeeded()
                // Guard against a tight loop if the clock is frozen (tests) or refresh is throttled.
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }
}

public enum EntitlementsError: Error, Hashable, Sendable {
    /// No token stored on this device.
    case noToken
    /// The human key is not known locally (store purchase linked on another device); the user
    /// can deactivate from the device that knows the key, or via support.
    case keyUnknown
}

extension EntitlementsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noToken: return "This device has no license to refresh."
        case .keyUnknown: return "The license key is not stored on this device. Enter it in Settings › License & Plans to manage devices."
        }
    }
}
