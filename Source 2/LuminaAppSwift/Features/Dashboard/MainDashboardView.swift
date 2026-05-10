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

                        ControlCard(
                            brightness: $viewModel.brightness,
                            selectedColor: $viewModel.selectedColor,
                            isOn: $viewModel.isOn
                        )

                        quickActionsSection

                        Spacer(minLength: LuminaTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, LuminaTheme.Spacing.lg)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $viewModel.showOnboarding) {
            OnboardingView(isOnboarded: .constant(true))
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
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                GlowIcon(systemName: "gearshape.fill", color: .white.opacity(0.7), size: 22)
            }
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
                SceneButton(title: "Focus", icon: "brain.head.profile", color: LuminaTheme.neonCyan) {
                    viewModel.applyFocusScene()
                }

                SceneButton(title: "Relax", icon: "moon.fill", color: LuminaTheme.neonPurpleLight) {
                    viewModel.applyRelaxScene()
                }

                SceneButton(title: "Party", icon: "party.popper.fill", color: LuminaTheme.neonPink) {
                    viewModel.applyPartyScene()
                }

                SceneButton(title: "Off", icon: "power", color: LuminaTheme.neonRed) {
                    viewModel.turnOff()
                }
            }
        }
    }
}

struct SceneButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.mediumImpact()
            action()
        } label: {
            VStack(spacing: LuminaTheme.Spacing.xs) {
                GlowIcon(systemName: icon, color: color, size: 22, glowRadius: 6)
                    .frame(width: 44, height: 44)
                    .glassCard(cornerRadius: LuminaTheme.CornerRadius.md)

                Text(title)
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
