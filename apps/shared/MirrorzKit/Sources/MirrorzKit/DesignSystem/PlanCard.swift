// PlanCard.swift
// One plan on the paywall: name, tagline, store price, feature highlights and the buy button.

import SwiftUI

public struct PlanCard: View {
    private let plan: Plan
    private let term: PurchaseTerm
    private let price: String?
    private let secondaryPrice: String?
    private let isCurrent: Bool
    private let isRecommended: Bool
    private let isBusy: Bool
    private let features: [Feature]
    private let action: () -> Void

    public init(
        plan: Plan,
        term: PurchaseTerm,
        price: String?,
        secondaryPrice: String? = nil,
        isCurrent: Bool = false,
        isRecommended: Bool = false,
        isBusy: Bool = false,
        features: [Feature]? = nil,
        action: @escaping () -> Void
    ) {
        self.plan = plan
        self.term = term
        self.price = price
        self.secondaryPrice = secondaryPrice
        self.isCurrent = isCurrent
        self.isRecommended = isRecommended
        self.isBusy = isBusy
        self.features = features ?? PlanCard.highlightedFeatures(for: plan)
        self.action = action
    }

    /// Features listed on the card, in order.
    public static func highlightedFeatures(for plan: Plan) -> [Feature] {
        switch plan {
        case .trial: return [.vm, .bottles, .coherence, .compatDB]
        case .standard: return [.vm, .bottles, .coherence, .cadPresets, .snapshots, .mobileCompanion, .noAds]
        case .pro: return [.cli, .api, .linkedClones, .nestedVirt, .cloudSync, .networkLab, .prioritySupport]
        case .business: return [.volumeLicensing, .mdm, .sso, .goldenImages, .auditLog]
        }
    }

    public var body: some View {
        MZCard(isSelected: isRecommended) {
            VStack(alignment: .leading, spacing: MZSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text(plan.shortName)
                        .font(MZTypography.title)
                        .foregroundStyle(MZColor.textPrimary)
                    Spacer()
                    if isCurrent {
                        MZBadge("Current plan", tone: .success, systemImage: "checkmark")
                    } else if isRecommended {
                        MZBadge("Most popular", tone: .accent)
                    }
                }
                Text(plan.tagline)
                    .font(MZTypography.callout)
                    .foregroundStyle(MZColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: MZSpacing.xs) {
                        Text(price ?? "—")
                            .font(MZTypography.price)
                            .foregroundStyle(MZColor.textPrimary)
                            .contentTransition(.numericText())
                        Text(term.priceSuffix)
                            .font(MZTypography.caption)
                            .foregroundStyle(MZColor.textSecondary)
                    }
                    if let secondaryPrice {
                        Text(secondaryPrice)
                            .font(MZTypography.caption)
                            .foregroundStyle(MZColor.textSecondary)
                    }
                }
                .animation(MZMotion.standard, value: price)

                Divider().overlay(MZColor.border)

                VStack(alignment: .leading, spacing: MZSpacing.sm) {
                    if plan == .pro {
                        Text("Everything in Standard, plus:")
                            .font(MZTypography.captionStrong)
                            .foregroundStyle(MZColor.textSecondary)
                    }
                    ForEach(features, id: \.self) { feature in
                        Label {
                            Text(feature.displayName)
                                .font(MZTypography.callout)
                                .foregroundStyle(MZColor.textPrimary)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MZColor.successText)
                        }
                    }
                }

                Spacer(minLength: MZSpacing.sm)

                MZPrimaryButton(buttonTitle, isLoading: isBusy, fullWidth: true, action: action)
                    .disabled(isCurrent || price == nil)

                Text(footnote)
                    .font(MZTypography.caption)
                    .foregroundStyle(MZColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(plan.displayName), \(term.displayName), \(price ?? "price unavailable")")
    }

    private var buttonTitle: String {
        if isCurrent { return "Current plan" }
        if price == nil { return "Unavailable" }
        switch term {
        case .perpetual: return "Buy \(plan.shortName)"
        case .annual, .monthly: return "Subscribe to \(plan.shortName)"
        }
    }

    private var footnote: String {
        switch term {
        case .perpetual: return "One-time purchase. 12 months of feature updates, security updates forever. Never expires."
        case .annual: return "Billed yearly. Cancel anytime."
        case .monthly: return "Billed monthly. Cancel anytime."
        }
    }
}
