// RatingChip.swift
// Compatibility rating chip: gold · silver · bronze · broken · n/a (spec §4).

import SwiftUI

public struct RatingChip: View {
    private let rating: CompatRating
    private let showsSummary: Bool

    public init(_ rating: CompatRating, showsSummary: Bool = false) {
        self.rating = rating
        self.showsSummary = showsSummary
    }

    public var body: some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: rating.symbolName)
                .imageScale(.small)
            Text(rating.displayName)
            if showsSummary {
                Text("·")
                Text(rating.summary)
            }
        }
        .font(MZTypography.captionStrong)
        .lineLimit(1)
        .foregroundStyle(MZColor.ratingText(rating))
        .padding(.horizontal, MZSpacing.sm)
        .padding(.vertical, MZSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MZRadius.chip, style: .continuous)
                .fill(MZColor.rating(rating))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MZRadius.chip, style: .continuous)
                .strokeBorder(rating == .notApplicable ? MZColor.border : Color.clear, lineWidth: MZStroke.hairline)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating.displayName): \(rating.summary)")
    }
}
