// MZSpacing.swift
// Spacing, radii and motion tokens (spec §5.4: radius 12, chips 8, motion 200 ms ease-out).

import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum MZSpacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

public enum MZRadius {
    public static let card: CGFloat = 12
    public static let button: CGFloat = 12
    public static let chip: CGFloat = 8
    public static let control: CGFloat = 8
}

public enum MZStroke {
    public static let hairline: CGFloat = 1
    public static let emphasis: CGFloat = 2
}

public enum MZMotion {
    public static let duration: Double = 0.2
    /// The one animation curve used across the product.
    public static let standard = Animation.easeOut(duration: duration)
}

/// Clipboard helper used by the license key and pairing views.
public enum MZClipboard {
    @MainActor
    public static func copy(_ string: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = string
        #endif
    }
}
