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

                    if viewModel.heroDevice == nil {
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
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .navigationDestination(isPresented: $viewModel.showWifiSetup) {
                WifiSetupView(onFinished: finish)
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
        .onChange(of: viewModel.heroDevice?.id) { _, id in
            if id != nil {
                HapticManager.shared.lightImpact()
            }
        }
    }

    private var header: some View {
        VStack(spacing: LuminaTheme.Spacing.sm) {
            Text("Lumina")
                .font(LuminaTheme.Typography.display)
                .foregroundStyle(LuminaTheme.primaryGradient)

            Text(viewModel.problemMessage ?? "Power on the lamp. When it lights up here, tap it.")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, LuminaTheme.Spacing.md)
    }

    private var lampStage: some View {
        ZStack {
            if viewModel.heroDevice == nil && viewModel.problemMessage == nil {
                ScanHalo()
            }

            Button {
                viewModel.connectToHero()
            } label: {
                LampPreview3D(
                    color: viewModel.heroDevice == nil ? LuminaTheme.neonPurple : LuminaTheme.neonCyan,
                    brightness: viewModel.heroDevice == nil ? 0.45 : 0.9,
                    isOn: viewModel.problemMessage == nil,
                    showsReadout: false
                )
            }
            .buttonStyle(.pressable)
            .disabled(viewModel.heroDevice == nil || viewModel.isConnecting)
            .accessibilityLabel(viewModel.heroDevice == nil ? "Searching for the lamp" : "Connect to \(viewModel.heroDevice?.name ?? "lamp")")
            .accessibilityHint("Connects, then asks for the lamp Wi-Fi")

            if viewModel.isConnecting {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
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
                Text("\(viewModel.discoveredDevices.count) lamps nearby. Connecting to the closest.")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    private var statusTitle: String {
        if viewModel.isConnecting { return "Connecting…" }
        if let hero = viewModel.heroDevice { return "Tap \(hero.name)" }
        if viewModel.problemMessage != nil { return "Bluetooth needed" }
        if viewModel.isScanning { return "Looking for your lamp" }
        return "No lamp yet"
    }

    private var statusColor: Color {
        if viewModel.heroDevice != nil { return LuminaTheme.neonGreen }
        if viewModel.problemMessage != nil { return LuminaTheme.neonRed }
        return LuminaTheme.neonPurple
    }

    private func finish() {
        isOnboarded = true
        dismiss()
    }
}

private struct ScanHalo: View {
    @State private var expanded = false

    var body: some View {
        ZStack {
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
        .allowsHitTesting(false)
        .onAppear { expanded = true }
        .accessibilityHidden(true)
    }
}
