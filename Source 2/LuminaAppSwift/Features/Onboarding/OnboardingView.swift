import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarded: Bool
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LuminaTheme.deepNavy.ignoresSafeArea()

                VStack(spacing: LuminaTheme.Spacing.xl) {
                    headerSection

                    if !viewModel.isBluetoothEnabled {
                        bluetoothWarning
                    } else if viewModel.discoveredDevices.isEmpty {
                        scanningSection
                    } else {
                        deviceListSection
                    }

                    Spacer()

                    bottomActions
                }
                .padding(.horizontal, LuminaTheme.Spacing.lg)
                .padding(.top, LuminaTheme.Spacing.lg)
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
        VStack(spacing: LuminaTheme.Spacing.md) {
            LampPreviewPlaceholder()
                .frame(height: 200)

            Text("Discover Your Lamp")
                .font(LuminaTheme.Typography.title)
                .foregroundColor(.white)

            Text("Make sure your Lumina lamp is powered on and in range. We'll scan for nearby devices.")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
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
        .padding(.vertical, LuminaTheme.Spacing.xl)
    }

    private var scanningSection: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            PulsingDot(color: LuminaTheme.neonPurple, size: 12)

            Text("Scanning for devices...")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.6))

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: LuminaTheme.neonPurple))
                .scaleEffect(1.2)

            GlassButton("Scan Again", icon: "arrow.clockwise") {
                viewModel.startScanning()
            }
            .frame(width: 200)
        }
        .padding(.vertical, LuminaTheme.Spacing.xl)
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
                    .padding(.bottom, LuminaTheme.Spacing.sm)
            }
        }
        .padding(.bottom, LuminaTheme.Spacing.xl)
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
