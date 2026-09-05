// MZTypography.swift
// Type scale on the system font (SF Pro on Apple platforms, spec §5.4). Dynamic Type friendly.

import SwiftUI

public enum MZTypography {
    public static let display = Font.system(.largeTitle, design: .default).weight(.bold)
    public static let title = Font.system(.title2, design: .default).weight(.semibold)
    public static let headline = Font.system(.headline, design: .default).weight(.semibold)
    public static let body = Font.system(.body, design: .default)
    public static let callout = Font.system(.callout, design: .default)
    public static let caption = Font.system(.caption, design: .default)
    public static let captionStrong = Font.system(.caption, design: .default).weight(.semibold)
    public static let mono = Font.system(.body, design: .monospaced)
    /// License keys and pairing codes.
    public static let keyEntry = Font.system(.title3, design: .monospaced).weight(.medium)
    public static let price = Font.system(.title, design: .rounded).weight(.bold)
}

public extension View {
    /// Applies a MIRRORZ text style with the primary text color.
    func mzText(_ font: Font, color: Color = MZColor.textPrimary) -> some View {
        self.font(font).foregroundStyle(color)
    }
}
