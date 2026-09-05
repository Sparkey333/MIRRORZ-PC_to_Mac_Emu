// MZCard.swift
// Surface container: surface fill, 1 pt border, 12 pt continuous corners.

import SwiftUI

public struct MZCard<Content: View>: View {
    private let padding: CGFloat
    private let isSelected: Bool
    private let content: Content

    public init(padding: CGFloat = MZSpacing.lg, isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.isSelected = isSelected
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: MZRadius.card, style: .continuous)
                    .fill(MZColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MZRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? MZColor.accentCyan : MZColor.border, lineWidth: isSelected ? MZStroke.emphasis : MZStroke.hairline)
            )
            .animation(MZMotion.standard, value: isSelected)
    }
}

public extension View {
    /// Wraps the view in a card surface.
    func mzCard(padding: CGFloat = MZSpacing.lg, isSelected: Bool = false) -> some View {
        MZCard(padding: padding, isSelected: isSelected) { self }
    }
}
