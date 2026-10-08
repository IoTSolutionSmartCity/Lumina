import SwiftUI

struct MainDashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            LuminaTheme.deepNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LuminaTheme.Spacing.lg) {
                        ConnectionStatusPill(state: viewModel.connectionState)
                            .padding(.top, LuminaTheme.Spacing.sm)

                        LampPreview3D(
                            color: viewModel.selectedColor,
                            brightness: viewModel.brightness,
                            isOn: viewModel.isOn
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))

                        ControlCard(
                            brightness: $viewModel.brightness,
                            selectedColor: $viewModel.selectedColor,
                            isOn: $viewModel.isOn
                        )

                        quickActionsSection

                        Spacer(minLength: LuminaTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, LuminaTheme.Spacing.lg)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.connectionState)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: viewModel.brightness) { _, _ in
            viewModel.sendUpdate()
        }
        .onChange(of: viewModel.selectedColor.hexString) { _, _ in
            viewModel.sendUpdate()
        }
        .onChange(of: viewModel.isOn) { _, _ in
            viewModel.sendUpdate(debounced: false)
        }
        .sheet(isPresented: $viewModel.showOnboarding) {
            OnboardingView(isOnboarded: .constant(true))
        }
        .fullScreenCover(isPresented: $viewModel.showWifiSetup) {
            NavigationStack {
                WifiSetupView(onFinished: { viewModel.showWifiSetup = false })
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lumina")
                    .font(LuminaTheme.Typography.display)
                    .foregroundStyle(LuminaTheme.primaryGradient)

                if let device = viewModel.connectedDevice {
                    Text(device.name)
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("No device connected")
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.55))
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                GlowIcon(systemName: "gearshape.fill", color: .white.opacity(0.7), size: 22)
                    .frame(width: 44, height: 44)
                    .glassCard(cornerRadius: LuminaTheme.CornerRadius.full)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Settings")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .padding(.horizontal, LuminaTheme.Spacing.lg)
        .padding(.top, LuminaTheme.Spacing.md)
        .padding(.bottom, LuminaTheme.Spacing.sm)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            Text("Quick Scenes")
                .font(LuminaTheme.Typography.headline)
                .foregroundColor(.white)

            HStack(spacing: LuminaTheme.Spacing.md) {
                SceneButton(title: "Focus", icon: "brain.head.profile", color: LuminaTheme.neonCyan, action: viewModel.applyFocusScene, isActive: viewModel.isOn && viewModel.brightness == 0.9 && viewModel.selectedColor.hexString == LuminaTheme.neonCyan.hexString)

                SceneButton(title: "Relax", icon: "moon.fill", color: LuminaTheme.neonPurpleLight, action: viewModel.applyRelaxScene, isActive: viewModel.isOn && viewModel.brightness == 0.4 && viewModel.selectedColor.hexString == LuminaTheme.neonPurpleLight.hexString)

                SceneButton(title: "Party", icon: "party.popper.fill", color: LuminaTheme.neonPink, action: viewModel.applyPartyScene, isActive: viewModel.isOn && viewModel.brightness == 1.0 && viewModel.selectedColor.hexString == LuminaTheme.neonPink.hexString)

                SceneButton(title: "Off", icon: "power", color: LuminaTheme.neonRed, action: viewModel.turnOff, isActive: !viewModel.isOn)
            }
        }
    }
}

struct SceneButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isActive: Bool = false

    var body: some View {
        Button {
            HapticManager.shared.mediumImpact()
            action()
        } label: {
            VStack(spacing: LuminaTheme.Spacing.xs) {
                GlowIcon(systemName: icon, color: color, size: 22, glowRadius: isActive ? 10 : 6)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.md)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.md)
                                    .stroke(isActive ? color.opacity(0.8) : LuminaTheme.glassBorder, lineWidth: isActive ? 1.5 : 1)
                            )
                    )
                    .shadow(color: isActive ? color.opacity(0.45) : .clear, radius: 10)

                Text(title)
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(isActive ? .white : .white.opacity(0.7))
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isActive)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : [.isButton])
    }
}
