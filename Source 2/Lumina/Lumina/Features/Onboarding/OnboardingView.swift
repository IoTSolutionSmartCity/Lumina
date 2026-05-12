import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarded: Bool
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LuminaTheme.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LuminaTheme.Spacing.lg) {
                        headerSection

                        stateCard

                        bottomActions
                    }
                    .padding(.horizontal, LuminaTheme.Spacing.lg)
                    .padding(.top, LuminaTheme.Spacing.lg)
                    .padding(.bottom, LuminaTheme.Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        skipOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }

    private var headerSection: some View {
        VStack(spacing: LuminaTheme.Spacing.lg) {
            discoveryHero

            Text("Discover Your Lamp")
                .font(LuminaTheme.Typography.title)
                .foregroundColor(.white)

            Text("Power on your Lumina ESP32-S3 lamp and keep it nearby. We will scan Bluetooth first, then guide pairing.")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }

    private var discoveryHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                        .stroke(LuminaTheme.glassBorder, lineWidth: 1)
                )
                .shadow(color: LuminaTheme.neonPurple.opacity(0.2), radius: 24)

            VStack(spacing: LuminaTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(LuminaTheme.neonPurple.opacity(0.18))
                        .frame(width: 118, height: 118)
                    Circle()
                        .stroke(LuminaTheme.neonPurple.opacity(0.4), lineWidth: 1)
                        .frame(width: 150, height: 150)
                    AnimatedGlowIcon(systemName: "lamp.desk.fill", color: LuminaTheme.neonPurple, size: 54)
                }

                HStack(spacing: LuminaTheme.Spacing.sm) {
                    PulsingDot(color: statusColor, size: 8)
                    Text(statusText)
                        .font(LuminaTheme.Typography.captionBold)
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .frame(height: 220)
    }

    private var stateCard: some View {
        VStack(spacing: LuminaTheme.Spacing.lg) {
            if !viewModel.isBluetoothEnabled {
                bluetoothWarning
            } else if viewModel.discoveredDevices.isEmpty {
                scanningSection
            } else {
                deviceListSection
            }
        }
        .padding(LuminaTheme.Spacing.lg)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.xl)
    }

    private var bluetoothWarning: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundColor(LuminaTheme.neonOrange)

            Text("Bluetooth Required")
                .font(LuminaTheme.Typography.headline)
                .foregroundColor(.white)

            Text("Please enable Bluetooth in Settings to discover nearby lamps.")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            NeonButton("Open Settings", icon: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .frame(width: 200)
        }
    }

    private var scanningSection: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            PulsingDot(color: LuminaTheme.neonPurple, size: 12)

            VStack(spacing: 4) {
                Text("Scanning for Lumina")
                    .font(LuminaTheme.Typography.headline)
                    .foregroundColor(.white)
                Text("Keep the lamp powered on and within Bluetooth range.")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: LuminaTheme.neonPurple))
                .scaleEffect(1.2)

            GlassButton("Scan Again", icon: "arrow.clockwise") {
                viewModel.startScanning()
            }
            .frame(width: 200)
        }
    }

    private var deviceListSection: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            HStack {
                Text("Found \(viewModel.discoveredDevices.count) device(s)")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Button {
                    viewModel.startScanning()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.neonPurple)
                }
            }

            ForEach(viewModel.discoveredDevices) { device in
                DeviceDiscoveryRow(device: device, isConnecting: viewModel.connectingDevice?.id == device.id) {
                    viewModel.connect(to: device)
                }
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            if case .connecting = viewModel.connectionState {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Connecting to \(viewModel.connectingDevice?.name ?? "device")...")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            if case .error(let msg) = viewModel.connectionState {
                Text(msg)
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.neonRed)
                    .multilineTextAlignment(.center)
                    .padding(LuminaTheme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: LuminaTheme.CornerRadius.lg)
            }
        }
    }

    private var statusText: String {
        if !viewModel.isBluetoothEnabled {
            return "Bluetooth needed"
        }
        return viewModel.connectionState.displayText
    }

    private var statusColor: Color {
        switch viewModel.connectionState {
        case .connected: return LuminaTheme.neonGreen
        case .scanning, .connecting: return LuminaTheme.neonOrange
        case .disconnected: return LuminaTheme.neonPurple
        case .error: return LuminaTheme.neonRed
        }
    }

    private func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "isOnboarded")
        isOnboarded = true
        dismiss()
    }
}

struct DeviceDiscoveryRow: View {
    let device: DiscoveredPeripheral
    let isConnecting: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: LuminaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(LuminaTheme.neonPurple.opacity(0.2))
                    .frame(width: 44, height: 44)

                GlowIcon(systemName: "lamp.desk.fill", color: LuminaTheme.neonPurple, size: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(LuminaTheme.Typography.headline)
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 10))
                    Text("RSSI: \(device.rssi) dBm")
                        .font(LuminaTheme.Typography.caption)
                }
                .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            if isConnecting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: LuminaTheme.neonPurple))
                    .scaleEffect(0.8)
            } else {
                Button {
                    onConnect()
                } label: {
                    Text("Connect")
                        .font(LuminaTheme.Typography.captionBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, LuminaTheme.Spacing.md)
                        .padding(.vertical, LuminaTheme.Spacing.sm)
                        .background(LuminaTheme.neonPurple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(LuminaTheme.Spacing.md)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.lg)
    }
}
