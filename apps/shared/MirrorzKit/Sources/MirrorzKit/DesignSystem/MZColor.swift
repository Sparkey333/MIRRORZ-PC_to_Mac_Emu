// MZColor.swift
// Palette from spec §5.4 — dark-first with a paired light palette.
// Dark values are the spec's; light values keep the same hue families with adequate contrast.

import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum MZColor {
    // Surfaces and text (dynamic)
    public static let background = Color(mzLight: 0xF8FAFC, dark: 0x0B0F1A)
    public static let surface = Color(mzLight: 0xFFFFFF, dark: 0x121826)
    public static let surfaceElevated = Color(mzLight: 0xF1F5F9, dark: 0x1A2234)
    public static let border = Color(mzLight: 0xE5E7EB, dark: 0x1F2937)
    public static let textPrimary = Color(mzLight: 0x111827, dark: 0xE5E7EB)
    public static let textSecondary = Color(mzLight: 0x6B7280, dark: 0x9CA3AF)

    // Accents (spec values in both modes; used as fills)
    public static let accentCyan = Color(mzHex: 0x22D3EE)
    public static let accentViolet = Color(mzHex: 0x8B5CF6)
    public static let success = Color(mzHex: 0x34D399)
    public static let warning = Color(mzHex: 0xFBBF24)
    public static let danger = Color(mzHex: 0xF87171)

    // Accents as text/icon colors: darker in light mode so they pass contrast on white.
    public static let accentText = Color(mzLight: 0x0E7490, dark: 0x22D3EE)
    public static let violetText = Color(mzLight: 0x6D28D9, dark: 0x8B5CF6)
    public static let successText = Color(mzLight: 0x047857, dark: 0x34D399)
    public static let warningText = Color(mzLight: 0xB45309, dark: 0xFBBF24)
    public static let dangerText = Color(mzLight: 0xB91C1C, dark: 0xF87171)

    /// Text drawn on an accent fill (always the dark background tone).
    public static let onAccent = Color(mzHex: 0x0B0F1A)

    // Compatibility ratings (spec §4)
    public static let ratingGold = warning
    public static let ratingSilver = Color(mzHex: 0x9CA3AF)
    public static let ratingBronze = Color(mzHex: 0xD08A4B)
    public static let ratingBroken = danger
    public static let ratingNotApplicable = Color(mzLight: 0xE5E7EB, dark: 0x1F2937)

    public static func rating(_ rating: CompatRating) -> Color {
        switch rating {
        case .gold: return ratingGold
        case .silver: return ratingSilver
        case .bronze: return ratingBronze
        case .broken: return ratingBroken
        case .notApplicable: return ratingNotApplicable
        }
    }

    public static func ratingText(_ rating: CompatRating) -> Color {
        rating == .notApplicable ? textSecondary : onAccent
    }

    /// Parses `#RRGGBB` / `RRGGBB`.
    public static func hex(_ string: String) -> Color? {
        var hex = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        return Color(mzHex: value)
    }
}

extension Color {
    /// Opaque sRGB color from a 24-bit hex value.
    public init(mzHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Dynamic color that follows the system appearance.
    public init(mzLight light: UInt32, dark: UInt32) {
        #if canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(mzHex: isDark ? dark : light)
        })
        #elseif canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            UIColor(mzHex: traits.userInterfaceStyle == .dark ? dark : light)
        })
        #else
        self.init(mzHex: dark)
        #endif
    }
}

#if canImport(AppKit)
extension NSColor {
    public convenience init(mzHex hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#elseif canImport(UIKit)
extension UIColor {
    public convenience init(mzHex hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif
