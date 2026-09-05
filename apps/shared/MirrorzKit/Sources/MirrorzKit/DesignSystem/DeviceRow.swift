// DeviceRow.swift
// One activated device in Settings › License & Plans, with a confirmed Deactivate action.

import SwiftUI

public struct DeviceRow: View {
    private let device: LicenseDevice
    private let isCurrentDevice: Bool
    private let onDeactivate: (() -> Void)?
    @State private var isConfirming = false

    public init(device: LicenseDevice, isCurrentDevice: Bool = false, onDeactivate: (() -> Void)? = nil) {
        self.device = device
        self.isCurrentDevice = isCurrentDevice
        self.onDeactivate = onDeactivate
    }

    private var displayName: String {
        if let name = device.deviceName, !name.isEmpty { return name }
        return device.platformID?.displayName ?? "Device"
    }

    public var body: some View {
        HStack(spacing: MZSpacing.md) {
            Image(systemName: device.platformID?.symbolName ?? "questionmark.square.dashed")
                .font(.title2)
                .foregroundStyle(MZColor.accentText)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: MZSpacing.xxs) {
                HStack(spacing: MZSpacing.sm) {
                    Text(displayName)
                        .font(MZTypography.headline)
                        .foregroundStyle(MZColor.textPrimary)
                        .lineLimit(1)
                    if isCurrentDevice {
                        MZBadge("This device", tone: .accent)
                    }
                }
                HStack(spacing: MZSpacing.xs) {
                    Text("Activated")
                    Text(device.activatedDate, style: .date)
                    Text("· Last seen")
                    Text(device.lastSeenDate, style: .relative)
                    Text("ago")
                }
                .font(MZTypography.caption)
                .foregroundStyle(MZColor.textSecondary)
                .lineLimit(1)
            }
            Spacer(minLength: MZSpacing.sm)
            if onDeactivate != nil {
                Button("Deactivate") {
                    isConfirming = true
                }
                .buttonStyle(.mzSecondary(isDestructive: true))
            }
        }
        .padding(.vertical, MZSpacing.sm)
        .confirmationDialog("Deactivate \(displayName)?", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("Deactivate", role: .destructive) { onDeactivate?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(isCurrentDevice
                 ? "MIRRORZ will stop running on this device until you activate it again."
                 : "MIRRORZ will stop running on \(displayName) until it is activated again. This frees one of your device slots.")
        }
        .accessibilityElement(children: .combine)
    }
}
