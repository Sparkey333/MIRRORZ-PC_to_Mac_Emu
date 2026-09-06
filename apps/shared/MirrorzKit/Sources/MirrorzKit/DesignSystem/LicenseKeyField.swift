// LicenseKeyField.swift
// License key entry with auto-formatting as you type and live check-symbol validation (spec §3.3).

import SwiftUI

public struct LicenseKeyField: View {
    @Binding private var normalizedKey: String?
    @State private var text: String
    private let onSubmit: (String) -> Void

    /// - Parameters:
    ///   - normalizedKey: receives the 25-symbol canonical key while the input is valid, nil otherwise.
    ///   - initialText: pre-filled text (for example from `mirrorz://activate?key=`).
    ///   - onSubmit: called with the normalized key when the user presses Return on a valid key.
    public init(normalizedKey: Binding<String?>, initialText: String = "", onSubmit: @escaping (String) -> Void = { _ in }) {
        self._normalizedKey = normalizedKey
        self._text = State(initialValue: LicenseKey.formatPartial(initialText))
        self.onSubmit = onSubmit
    }

    private var validation: LicenseKey.Validation { LicenseKey.validation(of: text) }

    public var body: some View {
        VStack(alignment: .leading, spacing: MZSpacing.sm) {
            HStack(spacing: MZSpacing.sm) {
                Image(systemName: "key")
                    .foregroundStyle(MZColor.textSecondary)
                TextField("MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX", text: $text)
                    .textFieldStyle(.plain)
                    .font(MZTypography.keyEntry)
                    .foregroundStyle(MZColor.textPrimary)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    .keyboardType(.asciiCapable)
                    .submitLabel(.done)
                    #endif
                    .onSubmit {
                        if case .valid(let normalized) = validation { onSubmit(normalized) }
                    }
                statusIcon
            }
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MZRadius.control, style: .continuous)
                    .fill(MZColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MZRadius.control, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: validation.isValid ? MZStroke.emphasis : MZStroke.hairline)
            )
            .animation(MZMotion.standard, value: validation)

            Text(statusText)
                .font(MZTypography.caption)
                .foregroundStyle(statusColor)
                .accessibilityLabel(statusText)
        }
        .onChange(of: text, initial: true) { _, newValue in
            let formatted = LicenseKey.formatPartial(newValue)
            if formatted != newValue { text = formatted }
            if case .valid(let normalized) = LicenseKey.validation(of: formatted) {
                normalizedKey = normalized
            } else {
                normalizedKey = nil
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch validation {
        case .valid:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(MZColor.successText)
        case .badCheckSymbol, .invalidCharacter:
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(MZColor.dangerText)
        case .empty, .incomplete:
            Image(systemName: "circle.dotted").foregroundStyle(MZColor.textSecondary)
        }
    }

    private var borderColor: Color {
        switch validation {
        case .valid: return MZColor.accentCyan
        case .badCheckSymbol, .invalidCharacter: return MZColor.danger
        case .empty, .incomplete: return MZColor.border
        }
    }

    private var statusColor: Color {
        switch validation {
        case .valid: return MZColor.successText
        case .badCheckSymbol, .invalidCharacter: return MZColor.dangerText
        case .empty, .incomplete: return MZColor.textSecondary
        }
    }

    private var statusText: String {
        switch validation {
        case .empty:
            return "Paste or type the key from your email or the companion app. Dashes and spaces are optional."
        case .incomplete(let entered):
            return "\(entered) of \(LicenseKey.symbolCount) characters"
        case .invalidCharacter(let character):
            return "“\(character)” is not part of a MIRRORZ key."
        case .badCheckSymbol:
            return "That key doesn't check out — re-check each character."
        case .valid:
            return "Looks good. Press Return to activate."
        }
    }
}
