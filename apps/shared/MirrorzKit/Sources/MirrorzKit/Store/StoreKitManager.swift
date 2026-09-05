// StoreKitManager.swift
// StoreKit 2 purchases (spec §2, §3.5).
//
//  - Loads the six consumer products (Standard/Pro × monthly/annual/perpetual).
//  - `purchase(_:)`: after `Product.purchase()` succeeds, sends the signed transaction
//    (`jwsRepresentation`) to `/v1/apple/link`, applies the returned token, and only then
//    calls `transaction.finish()`. On failure the transaction stays unfinished so StoreKit
//    redelivers it (`Transaction.updates` / `Transaction.unfinished`).
//  - Listens to `Transaction.updates` for renewals, Family Sharing, offer codes, Ask to Buy
//    approvals and purchases made on another device.
//  - Walks `Transaction.currentEntitlements` at launch; links only what is not linked yet so
//    licensing is not phoned home on every launch.
//  - `restore()` = `AppStore.sync()` followed by the entitlement walk.

import Foundation
import Observation
import StoreKit

public enum StorePurchaseOutcome: Hashable, Sendable {
    /// The purchase is linked to a MIRRORZ license. `key` is present on the first link only.
    case linked(key: String?)
    /// Waiting for approval (Ask to Buy) or for a deferred payment.
    case pending
    case cancelled
}

public enum StoreKitError: Error {
    case productUnavailable(StoreProductID)
    case unverifiedTransaction(any Error)
    case unknownProduct(String)
}

/// One row of the paywall: a plan/term pair backed by a StoreKit product.
public struct StoreOffering: Identifiable, Sendable {
    public let id: StoreProductID
    public let product: Product

    public init(id: StoreProductID, product: Product) {
        self.id = id
        self.product = product
    }

    public var plan: Plan { id.plan }
    public var term: PurchaseTerm { id.term }
    public var displayPrice: String { product.displayPrice }
    public var isFamilyShareable: Bool { product.isFamilyShareable }

    /// Monthly-equivalent price for annual plans ("$5.00 / month billed yearly").
    public var monthlyEquivalentPrice: String? {
        guard term == .annual else { return nil }
        let monthly = product.price / 12
        return monthly.formatted(product.priceFormatStyle)
    }
}

@MainActor
@Observable
public final class StoreKitManager {
    public typealias PurchaseOutcome = StorePurchaseOutcome
    public typealias StoreError = StoreKitError
    public typealias Offering = StoreOffering

    /// Persisted set of transaction ids already linked with the server (not secret).
    private static let linkedTransactionsKey = "com.mirrorz.store.linkedTransactions"

    // MARK: Observable state

    public private(set) var products: [Product] = []
    public private(set) var offerings: [Offering] = []
    public private(set) var isLoadingProducts = false
    public private(set) var isPurchasing = false
    public private(set) var isRestoring = false
    public private(set) var lastError: (any Error)?
    /// Product ids with a verified, unrevoked current entitlement.
    public private(set) var purchasedProductIDs: Set<String> = []
    /// Key returned by the most recent first-time link; the UI shows it once with a copy button.
    public private(set) var lastLinkedKey: String?
    public private(set) var hasStarted = false

    public let client: LicenseClient
    public let entitlements: Entitlements
    public let device: DeviceRecord

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var linkedTransactionIDs: Set<UInt64>

    public init(client: LicenseClient, entitlements: Entitlements, device: DeviceRecord, defaults: UserDefaults = .standard) {
        self.client = client
        self.entitlements = entitlements
        self.device = device
        self.defaults = defaults
        let stored = defaults.array(forKey: Self.linkedTransactionsKey) as? [String] ?? []
        self.linkedTransactionIDs = Set(stored.compactMap(UInt64.init))
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: Lifecycle

    /// Starts the transaction listener, loads products, replays unfinished transactions and
    /// walks current entitlements. Call once after `Entitlements.bootstrap()`.
    public func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        listenForTransactions()
        await loadProducts()
        await processUnfinishedTransactions()
        await processCurrentEntitlements()
    }

    public func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: StoreProductID.appStoreProductIDs)
            let order = StoreProductID.allCases.map(\.rawValue)
            products = loaded.sorted { (order.firstIndex(of: $0.id) ?? .max) < (order.firstIndex(of: $1.id) ?? .max) }
            offerings = products.compactMap { product in
                StoreProductID(rawValue: product.id).map { Offering(id: $0, product: product) }
            }
        } catch {
            lastError = error
        }
    }

    public func product(for id: StoreProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    public func offering(plan: Plan, term: PurchaseTerm) -> Offering? {
        offerings.first { $0.plan == plan && $0.term == term }
    }

    /// Offer-code redemption UI exists on iOS 16+ and macOS 15+.
    public var isOfferCodeRedemptionAvailable: Bool {
        if #available(macOS 15.0, *) { return true }
        return false
    }

    // MARK: Purchase / restore

    public func purchase(plan: Plan, term: PurchaseTerm) async throws -> PurchaseOutcome {
        guard let id = StoreProductID.product(plan: plan, term: term) else { throw StoreError.unknownProduct("\(plan.rawValue).\(term.rawValue)") }
        guard let product = product(for: id) else { throw StoreError.productUnavailable(id) }
        return try await purchase(product)
    }

    public func purchase(_ product: Product) async throws -> PurchaseOutcome {
        isPurchasing = true
        defer { isPurchasing = false }
        lastError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                return try await handle(verification, source: .purchase)
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .cancelled
            }
        } catch {
            lastError = error
            throw error
        }
    }

    /// "Restore Purchases": asks the App Store to sync, then re-links current entitlements.
    public func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        lastError = nil
        do {
            try await AppStore.sync()
        } catch {
            lastError = error
            return
        }
        await processCurrentEntitlements(forceLink: true)
    }

    /// Forgets the "already linked" bookkeeping (used when the user signs out of a license).
    public func resetLinkHistory() {
        linkedTransactionIDs = []
        defaults.removeObject(forKey: Self.linkedTransactionsKey)
        lastLinkedKey = nil
    }

    // MARK: Transaction handling

    private enum Source {
        case purchase
        case update
        case entitlement(forceLink: Bool)
    }

    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    _ = try await self.handle(result, source: .update)
                } catch {
                    self.lastError = error
                }
            }
        }
    }

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                _ = try await handle(result, source: .update)
            } catch {
                lastError = error
            }
        }
    }

    private func processCurrentEntitlements(forceLink: Bool = false) async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               StoreProductID(rawValue: transaction.productID) != nil {
                ids.insert(transaction.productID)
            }
            do {
                _ = try await handle(result, source: .entitlement(forceLink: forceLink))
            } catch {
                lastError = error
            }
        }
        purchasedProductIDs = ids
    }

    @discardableResult
    private func handle(_ result: VerificationResult<Transaction>, source: Source) async throws -> PurchaseOutcome {
        switch result {
        case .unverified(_, let error):
            // Never finish an unverified transaction; StoreKit will present it again.
            throw StoreError.unverifiedTransaction(error)
        case .verified(let transaction):
            guard StoreProductID(rawValue: transaction.productID) != nil else {
                // Not a MIRRORZ product (e.g. a leftover from testing); nothing to link.
                await transaction.finish()
                return .cancelled
            }
            if transaction.revocationDate != nil {
                // Refund or Family Sharing revocation. The server learns about it through App
                // Store Server Notifications; locally we finish and let the daily refresh pick it up.
                await transaction.finish()
                linkedTransactionIDs.remove(transaction.id)
                persistLinked()
                purchasedProductIDs.remove(transaction.productID)
                await entitlements.refreshIfNeeded()
                return .cancelled
            }
            let needsLink: Bool
            switch source {
            case .purchase, .update:
                needsLink = true
            case .entitlement(let forceLink):
                needsLink = forceLink || !linkedTransactionIDs.contains(transaction.id) || !entitlements.isEntitled
            }
            var key: String?
            if needsLink {
                let response = try await client.linkApple(signedTransaction: result.jwsRepresentation, device: device)
                try entitlements.apply(token: response.token, license: response.license, key: response.key)
                key = response.key
                if let key { lastLinkedKey = key }
                linkedTransactionIDs.insert(transaction.id)
                persistLinked()
            }
            // Only after the server accepted the transaction (spec §3.5).
            await transaction.finish()
            purchasedProductIDs.insert(transaction.productID)
            return .linked(key: key)
        }
    }

    private func persistLinked() {
        defaults.set(linkedTransactionIDs.map(String.init), forKey: Self.linkedTransactionsKey)
    }
}

extension StoreKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .productUnavailable(let id):
            return "\(id.plan.displayName) (\(id.term.displayName)) is not available in the App Store right now."
        case .unverifiedTransaction:
            return "The App Store transaction could not be verified."
        case .unknownProduct(let id):
            return "Unknown product \(id)."
        }
    }
}
