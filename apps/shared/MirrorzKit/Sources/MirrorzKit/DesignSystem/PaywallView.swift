// PaywallView.swift
// Plans screen backed by StoreKit products. Per spec §5.4 there are no modal upsells: this
// view is embedded in Settings › License & Plans and in a feature's locked state only.

import StoreKit
import SwiftUI

public struct PaywallView: View {
    private let store: StoreKitManager
    private let entitlements: Entitlements
    private let onEnterLicenseKey: () -> Void

    @State private var term: PurchaseTerm = .annual
    @State private var busyPlan: Plan?
    @State private var errorMessage: String?
    @State private var linkedKey: String?
    @State private var isPendingApproval = false
    @State private var showOfferCodeSheet = false

    public init(store: StoreKitManager, entitlements: Entitlements, onEnterLicenseKey: @escaping () -> Void) {
        self.store = store
        self.entitlements = entitlements
        self.onEnterLicenseKey = onEnterLicenseKey
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: MZSpacing.xl) {
                header
                termPicker
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: MZSpacing.lg) { planCards }
                    VStack(spacing: MZSpacing.lg) { planCards }
                }
                promise
                if let linkedKey {
                    keyCard(linkedKey)
                }
                if isPendingApproval {
                    notice("Waiting for approval. The purchase will activate as soon as it is approved.", systemImage: "hourglass")
                }
                if let errorMessage {
                    notice(errorMessage, systemImage: "exclamationmark.triangle", tone: .danger)
                }
                secondaryActions
                hints
            }
            .padding(MZSpacing.xl)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(MZColor.background)
        .mzOfferCodeRedemption(isPresented: $showOfferCodeSheet)
        .task {
            if store.products.isEmpty { await store.loadProducts() }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: MZSpacing.sm) {
            Text(entitlements.isEntitled ? "Your plan" : "Choose your plan")
                .font(MZTypography.display)
                .foregroundStyle(MZColor.textPrimary)
            Text("Run Windows and PC software on your Mac. AutoCAD-ready. No ads, ever.")
                .font(MZTypography.callout)
                .foregroundStyle(MZColor.textSecondary)
                .multilineTextAlignment(.center)
            if entitlements.isTrial, let days = entitlements.daysRemaining {
                MZBadge(days == 0 ? "Trial ends today" : "Trial: \(days) day\(days == 1 ? "" : "s") left", tone: .warning, systemImage: "clock")
            }
            if entitlements.showsUpdateUpgradeBanner {
                MZBadge("Feature updates ended for your perpetual license — upgrade pricing applies", tone: .violet, systemImage: "arrow.up.circle")
            }
        }
    }

    private var termPicker: some View {
        Picker("Billing", selection: $term) {
            ForEach(PurchaseTerm.allCases) { term in
                Text(term.displayName).tag(term)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: 360)
    }

    @ViewBuilder
    private var planCards: some View {
        ForEach(Plan.purchasable, id: \.self) { plan in
            let offering = store.offering(plan: plan, term: term)
            PlanCard(
                plan: plan,
                term: term,
                price: offering?.displayPrice,
                secondaryPrice: offering?.monthlyEquivalentPrice.map { "\($0) / month, billed yearly" },
                isCurrent: entitlements.isEntitled && entitlements.plan == plan && entitlements.kind == term.licenseKind,
                isRecommended: plan == .standard,
                isBusy: busyPlan == plan
            ) {
                buy(plan)
            }
        }
    }

    private var promise: some View {
        Text("No ads. Cancel anytime. Perpetual never expires.")
            .font(MZTypography.headline)
            .foregroundStyle(MZColor.textPrimary)
            .multilineTextAlignment(.center)
    }

    private func keyCard(_ key: String) -> some View {
        MZCard {
            VStack(alignment: .leading, spacing: MZSpacing.sm) {
                Label("Your license key", systemImage: "key")
                    .font(MZTypography.headline)
                    .foregroundStyle(MZColor.textPrimary)
                Text(key)
                    .font(MZTypography.keyEntry)
                    .foregroundStyle(MZColor.accentText)
                    .textSelection(.enabled)
                Text("Save it. Use it to activate MIRRORZ on your other devices, or if you bought on iPhone or Android.")
                    .font(MZTypography.caption)
                    .foregroundStyle(MZColor.textSecondary)
                Button("Copy key", systemImage: "doc.on.doc") {
                    MZClipboard.copy(key)
                }
                .buttonStyle(.mzSecondary)
            }
        }
    }

    private func notice(_ text: String, systemImage: String, tone: MZBadge.Tone = .neutral) -> some View {
        HStack(alignment: .top, spacing: MZSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(tone == .danger ? MZColor.dangerText : MZColor.accentText)
            Text(text)
                .font(MZTypography.callout)
                .foregroundStyle(MZColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mzCard(padding: MZSpacing.md)
    }

    private var secondaryActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: MZSpacing.md) { actionButtons }
            VStack(spacing: MZSpacing.sm) { actionButtons }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button {
            Task { @MainActor in
                errorMessage = nil
                await store.restore()
                if let error = store.lastError { errorMessage = error.localizedDescription }
            }
        } label: {
            if store.isRestoring {
                ProgressView().controlSize(.small)
            } else {
                Text("Restore Purchases")
            }
        }
        .buttonStyle(.mzSecondary)
        .disabled(store.isRestoring)

        Button("Enter license key", systemImage: "key", action: onEnterLicenseKey)
            .buttonStyle(.mzSecondary)

        if store.isOfferCodeRedemptionAvailable {
            Button("Redeem offer code", systemImage: "gift") {
                showOfferCodeSheet = true
            }
            .buttonStyle(.mzSecondary)
        }
    }

    private var hints: some View {
        VStack(spacing: MZSpacing.xs) {
            Text("Bought on iPhone or Android? Open the companion app's License tab to see your key, then enter it here.")
            if store.offerings.contains(where: \.isFamilyShareable) {
                Text("Family Sharing is available on Apple platforms.")
            }
            Text("Subscriptions renew automatically until cancelled in your App Store account settings. Prices are shown in your local currency by the App Store.")
        }
        .font(MZTypography.caption)
        .foregroundStyle(MZColor.textSecondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Actions

    private func buy(_ plan: Plan) {
        busyPlan = plan
        errorMessage = nil
        isPendingApproval = false
        Task { @MainActor in
            defer { busyPlan = nil }
            do {
                let outcome = try await store.purchase(plan: plan, term: term)
                switch outcome {
                case .linked(let key):
                    if let key { linkedKey = key }
                case .pending:
                    isPendingApproval = true
                case .cancelled:
                    break
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

extension View {
    /// Offer-code redemption sheet where the platform supports it (iOS 16+, macOS 15+);
    /// a no-op elsewhere. The button that presents it is hidden on unsupported platforms.
    @ViewBuilder
    func mzOfferCodeRedemption(isPresented: Binding<Bool>) -> some View {
        if #available(macOS 15.0, *) {
            self.offerCodeRedemption(isPresented: isPresented) { _ in }
        } else {
            self
        }
    }
}
