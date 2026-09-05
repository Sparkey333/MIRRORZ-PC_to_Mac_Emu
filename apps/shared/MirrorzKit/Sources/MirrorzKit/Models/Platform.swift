// Platform.swift
// Device platform values used in the licensing device record (spec §3.2).

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum Platform: String, Codable, CaseIterable, Hashable, Sendable {
    case macos
    case ios
    case ipados
    case android
    case web

    public var displayName: String {
        switch self {
        case .macos: return "Mac"
        case .ios: return "iPhone"
        case .ipados: return "iPad"
        case .android: return "Android"
        case .web: return "Web"
        }
    }

    /// SF Symbol used in device lists.
    public var symbolName: String {
        switch self {
        case .macos: return "macbook"
        case .ios: return "iphone"
        case .ipados: return "ipad"
        case .android: return "candybarphone"
        case .web: return "globe"
        }
    }

    /// The platform family this binary was compiled for, without idiom detection.
    public static var compiled: Platform {
        #if os(macOS)
        return .macos
        #else
        return .ios
        #endif
    }

    /// Detects the running platform. Main-actor isolated because iPad detection goes
    /// through `UIDevice`, which is main-actor bound.
    @MainActor
    public static func detect() -> Platform {
        #if os(macOS)
        return .macos
        #elseif canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .pad ? .ipados : .ios
        #else
        return .ios
        #endif
    }
}
