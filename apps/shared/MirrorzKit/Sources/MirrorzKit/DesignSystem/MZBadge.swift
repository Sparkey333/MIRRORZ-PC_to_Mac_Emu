// MZBadge.swift
// Small tinted label chip (8 pt corners).

import SwiftUI

public struct MZBadge: View {
    public enum Tone: Hashable, Sendable {
        case neutral
        case accent
        case violet
        case success
        case warning
        case danger

        var fill: Color {
            switch self {
            case .neutral: return MZColor.surfaceElevated
            case .accent: return MZColor.accentCyan.opacity(0.18)
            case .violet: return MZColor.accentViolet.opacity(0.18)
            case .success: return MZColor.success.opacity(0.18)
            case .warning: return MZColor.warning.opacity(0.18)
            case .danger: return MZColor.danger.opacity(0.18)
            }
        }

        var foreground: Color {
            switch self {
            case .neutral: return MZColor.textSecondary
            case .accent: return MZColor.accentText
            case .violet: return MZColor.violetText
            case .success: return MZColor.successText
            case .warning: return MZColor.warningText
            case .danger: return MZColor.dangerText
            }
        }
    }

    private let text: String
    private let tone: Tone
    private let systemImage: String?

    public init(_ text: String, tone: Tone = .neutral, systemImage: String? = nil) {
        self.text = text
        self.tone = tone
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: MZSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(text)
                .lineLimit(1)
        }
        .font(MZTypography.captionStrong)
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, MZSpacing.sm)
        .padding(.vertical, MZSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MZRadius.chip, style: .continuous)
                .fill(tone.fill)
        )
        .accessibilityLabel(text)
    }
}
