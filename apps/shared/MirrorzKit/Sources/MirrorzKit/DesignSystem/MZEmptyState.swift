// MZEmptyState.swift
// Empty/locked state with an SF Symbol, title, message and optional action.

import SwiftUI

public struct MZEmptyState: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(systemImage: String, title: String, message: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: MZSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(MZColor.accentText)
                .padding(.bottom, MZSpacing.xs)
            Text(title)
                .font(MZTypography.title)
                .foregroundStyle(MZColor.textPrimary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(MZTypography.callout)
                    .foregroundStyle(MZColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            if let actionTitle, let action {
                MZPrimaryButton(actionTitle, action: action)
                    .padding(.top, MZSpacing.sm)
            }
        }
        .padding(MZSpacing.xxl)
        .frame(maxWidth: .infinity)
    }

    /// Locked-feature state: explains which plan unlocks a feature. Plan upgrades live only in
    /// Settings › License and on a feature's locked state (spec §5.4) — this is the latter.
    public static func locked(_ feature: Feature, onUpgrade: @escaping () -> Void) -> MZEmptyState {
        MZEmptyState(
            systemImage: "lock",
            title: "\(feature.displayName) is part of \(feature.minimumPlan.displayName)",
            message: feature.summary,
            actionTitle: "See plans",
            action: onUpgrade
        )
    }
}
