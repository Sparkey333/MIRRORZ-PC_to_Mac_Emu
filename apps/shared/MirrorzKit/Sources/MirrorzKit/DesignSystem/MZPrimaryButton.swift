// MZPrimaryButton.swift
// Button styles: accent-cyan primary and bordered secondary, 12 pt corners, 200 ms ease-out.

import SwiftUI

public struct MZPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private let fullWidth: Bool

    public init(fullWidth: Bool = false) {
        self.fullWidth = fullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MZTypography.headline)
            .foregroundStyle(MZColor.onAccent)
            .padding(.horizontal, MZSpacing.lg)
            .padding(.vertical, MZSpacing.md)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: MZRadius.button, style: .continuous)
                    .fill(MZColor.accentCyan)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(MZMotion.standard, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: MZRadius.button, style: .continuous))
    }
}

public struct MZSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private let fullWidth: Bool
    private let isDestructive: Bool

    public init(fullWidth: Bool = false, isDestructive: Bool = false) {
        self.fullWidth = fullWidth
        self.isDestructive = isDestructive
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MZTypography.headline)
            .foregroundStyle(isDestructive ? MZColor.dangerText : MZColor.textPrimary)
            .padding(.horizontal, MZSpacing.lg)
            .padding(.vertical, MZSpacing.md)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: MZRadius.button, style: .continuous)
                    .fill(configuration.isPressed ? MZColor.surfaceElevated : MZColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MZRadius.button, style: .continuous)
                    .strokeBorder(isDestructive ? MZColor.danger.opacity(0.6) : MZColor.border, lineWidth: MZStroke.hairline)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(MZMotion.standard, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: MZRadius.button, style: .continuous))
    }
}

public extension ButtonStyle where Self == MZPrimaryButtonStyle {
    static var mzPrimary: MZPrimaryButtonStyle { MZPrimaryButtonStyle() }
    static func mzPrimary(fullWidth: Bool) -> MZPrimaryButtonStyle { MZPrimaryButtonStyle(fullWidth: fullWidth) }
}

public extension ButtonStyle where Self == MZSecondaryButtonStyle {
    static var mzSecondary: MZSecondaryButtonStyle { MZSecondaryButtonStyle() }
    static func mzSecondary(fullWidth: Bool = false, isDestructive: Bool = false) -> MZSecondaryButtonStyle {
        MZSecondaryButtonStyle(fullWidth: fullWidth, isDestructive: isDestructive)
    }
}

/// Primary call to action with an optional progress state.
public struct MZPrimaryButton: View {
    private let title: String
    private let systemImage: String?
    private let isLoading: Bool
    private let fullWidth: Bool
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, isLoading: Bool = false, fullWidth: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: MZSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MZColor.onAccent)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
        }
        .buttonStyle(.mzPrimary(fullWidth: fullWidth))
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}
