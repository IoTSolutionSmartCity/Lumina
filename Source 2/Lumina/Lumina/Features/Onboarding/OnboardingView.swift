import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarded: Bool
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                LuminaTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: LuminaTheme.Spacing.lg) {
                    header

                    Spacer(minLength: LuminaTheme.Spacing.md)

                    lampStage

                    statusLine

                    if case .error(let message) = viewModel.connectionState, !viewModel.isConnecting {
                        Text(message)
                            .font(LuminaTheme.Typography.caption)
                            .foregroundColor(LuminaTheme.neonRed)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.discoveredDevices.isEmpty {
                        GlassButton(viewModel.isScanning ? "Scanning…" : "Scan again", icon: "arrow.clockwise") {
                            viewModel.beginDiscovery()
                        }
                        .frame(width: 200)
                        .disabled(viewModel.isScanning)
                    }

                    Spacer(minLength: LuminaTheme.Spacing.md)
                }
                .padding(.horizontal, LuminaTheme.Spacing.lg)
                .padding(.bottom, LuminaTheme.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") { finish() }
                        .foregroundColor(LuminaTheme.textSecondary)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showWifiSetup) {
                NavigationStack {
                    WifiSetupView(onFinished: finish)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            viewModel.beginDiscovery()
            try? await Task.sleep(for: .seconds(20))
            if !Task.isCancelled {
                viewModel.stopScanning()
            }
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }

    private var header: some View {
        VStack(spacing: LuminaTheme.Spacing.sm) {
            Text("Lumina")
                .font(LuminaTheme.Typography.display)
                .foregroundStyle(LuminaTheme.primaryGradient)

            Text(viewModel.problemMessage ?? "Power on the lamp, then tap the one you want.")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(LuminaTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, LuminaTheme.Spacing.md)
    }

    private var lampStage: some View {
        Group {
            if viewModel.discoveredDevices.isEmpty {
                ZStack {
                    if viewModel.problemMessage == nil {
                        ScanHalo()
                    }
                    LampPreview3D(
                        color: LuminaTheme.neonPurple,
                        brightness: 0.45,
                        isOn: viewModel.problemMessage == nil,
                        showsReadout: false
                    )
                    .accessibilityLabel("Searching for the lamp")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
            } else {
                VStack(spacing: LuminaTheme.Spacing.sm) {
                    ForEach(viewModel.discoveredDevices) { device in
                        Button {
                            viewModel.connect(to: device)
                        } label: {
                            HStack(spacing: LuminaTheme.Spacing.md) {
                                Image(systemName: "lamp.desk.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(LuminaTheme.neonCyan)
                                    .frame(width: 36, height: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(LuminaTheme.Typography.headline)
                                        .foregroundColor(.white)
                                    Text(signalLabel(device.rssi))
                                        .font(LuminaTheme.Typography.caption)
                                        .foregroundColor(LuminaTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .padding(.horizontal, LuminaTheme.Spacing.md)
                            .frame(minHeight: 60)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressable)
                        .disabled(viewModel.isConnecting)
                        .glassCard(cornerRadius: LuminaTheme.CornerRadius.lg)
                        .accessibilityLabel("Connect to \(device.name)")
                    }
                    if viewModel.isConnecting {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, LuminaTheme.Spacing.sm)
                    }
                }
            }
        }
    }

    private func signalLabel(_ rssi: Int) -> String {
        if rssi == 0 { return "Saved lamp" }
        if rssi >= -60 { return "Strong signal" }
        if rssi >= -80 { return "Nearby" }
        return "Weak signal"
    }

    private var statusLine: some View {
        VStack(spacing: 4) {
            HStack(spacing: LuminaTheme.Spacing.sm) {
                PulsingDot(color: statusColor, size: 8)
                Text(statusTitle)
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white.opacity(0.8))
            }
            if viewModel.discoveredDevices.count > 1 {
                Text("\(viewModel.discoveredDevices.count) lamps nearby. Tap the one you want.")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.textSecondary)
            }
        }
    }

    private var statusTitle: String {
        if viewModel.isConnecting { return "Connecting…" }
        if !viewModel.discoveredDevices.isEmpty { return "Choose a lamp" }
        if viewModel.problemMessage != nil { return "Bluetooth needed" }
        if viewModel.isScanning { return "Looking for your lamp" }
        return "No lamp yet"
    }

    private var statusColor: Color {
        if !viewModel.discoveredDevices.isEmpty { return LuminaTheme.neonGreen }
        if viewModel.problemMessage != nil { return LuminaTheme.neonRed }
        return LuminaTheme.neonPurple
    }

    private func finish() {
        isOnboarded = true
        dismiss()
    }
}

private struct ScanHalo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        ZStack {
            if reduceMotion {
                Circle()
                    .stroke(LuminaTheme.neonPurple.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 160, height: 160)
            } else {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(LuminaTheme.neonPurple.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 160, height: 160)
                        .scaleEffect(expanded ? 1.85 : 0.72)
                        .opacity(expanded ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 2.4)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.6),
                            value: expanded
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            expanded = true
        }
        .accessibilityHidden(true)
    }
}
