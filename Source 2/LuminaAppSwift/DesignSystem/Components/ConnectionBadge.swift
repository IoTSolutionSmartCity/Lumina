import SwiftUI

struct ConnectionBadge: View {
    let isConnected: Bool
    let serialNumber: String

    var body: some View {
        HStack(spacing: LuminaTheme.Spacing.sm) {
            Circle()
                .fill(isConnected ? LuminaTheme.neonGreen : LuminaTheme.neonRed)
                .frame(width: 10, height: 10)
                .shadow(color: isConnected ? LuminaTheme.neonGreen.opacity(0.6) : LuminaTheme.neonRed.opacity(0.6), radius: 4)

            Text(isConnected ? "Connected" : "Disconnected")
                .font(LuminaTheme.Typography.captionBold)

            Text("•")
                .foregroundColor(.white.opacity(0.4))

            Text(serialNumber)
                .font(LuminaTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .foregroundColor(.white)
        .padding(.horizontal, LuminaTheme.Spacing.md)
        .padding(.vertical, LuminaTheme.Spacing.sm)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.full)
    }
}

struct ConnectionStatusPill: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.6), radius: 4)

            if case .scanning = state {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.7)
            }

            Text(state.displayText)
                .font(LuminaTheme.Typography.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, LuminaTheme.Spacing.md)
        .padding(.vertical, LuminaTheme.Spacing.sm)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.full)
    }

    private var statusColor: Color {
        switch state {
        case .connected: return LuminaTheme.neonGreen
        case .scanning, .connecting: return LuminaTheme.neonOrange
        case .error: return LuminaTheme.neonRed
        case .disconnected: return LuminaTheme.neonRed
        }
    }
}
