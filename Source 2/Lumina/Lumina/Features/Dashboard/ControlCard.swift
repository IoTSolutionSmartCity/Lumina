import SwiftUI

struct ControlCard: View {
    @Binding var brightness: Double
    @Binding var selectedColor: Color
    @Binding var isOn: Bool
    var isBreathing: Binding<Bool> = .constant(false)
    var onMode: ((UInt8, Color, Bool) -> Void)?

    var body: some View {
        GlassCard {
            VStack(spacing: LuminaTheme.Spacing.lg) {
                powerToggle

                if isOn {
                    VStack(spacing: LuminaTheme.Spacing.lg) {
                        brightnessControl
                        colorSection
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    ))
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.75), value: isOn)
        }
    }

    private var powerToggle: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            HapticManager.shared.mediumImpact()
        } label: {
            HStack(spacing: LuminaTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isOn ? LuminaTheme.neonGreen.opacity(0.22) : LuminaTheme.neonRed.opacity(0.14))
                        .frame(width: 56, height: 56)
                        .shadow(color: (isOn ? LuminaTheme.neonGreen : LuminaTheme.neonRed).opacity(isOn ? 0.45 : 0.2), radius: isOn ? 10 : 4)

                    GlowIcon(
                        systemName: "power",
                        color: isOn ? LuminaTheme.neonGreen : .white.opacity(0.55),
                        size: 26,
                        glowRadius: isOn ? 12 : 3
                    )
                    .rotationEffect(.degrees(isOn ? 0 : -90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.65), value: isOn)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isOn ? "Lamp is On" : "Lamp is Off")
                        .font(LuminaTheme.Typography.title2)
                        .foregroundColor(.white)
                        .contentTransition(.opacity)
                    Text(isOn ? "Tap to turn off" : "Tap to wake your lamp")
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(LuminaTheme.textSecondary)
                }

                Spacer()

                Text(isOn ? "ON" : "OFF")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, LuminaTheme.Spacing.md)
                    .padding(.vertical, LuminaTheme.Spacing.sm)
                    .background((isOn ? LuminaTheme.neonGreen : LuminaTheme.neonRed).opacity(0.85))
                    .clipShape(Capsule())
                    .contentTransition(.opacity)
            }
            .padding(LuminaTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xl)
                    .fill(isOn ? LuminaTheme.neonGreen.opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xl)
                            .stroke(isOn ? LuminaTheme.neonGreen.opacity(0.55) : Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOn)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lamp power")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(isOn ? "Double tap to turn off" : "Double tap to turn on")
        .accessibilityAddTraits(.isButton)
    }

    private var brightnessControl: some View {
        GlassSlider(
            value: $brightness,
            icon: "sun.max.fill",
            label: "Brightness",
            tint: selectedColor
        )
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            ColorWheelPicker(selectedColor: $selectedColor, isBreathing: isBreathing, onMode: onMode)
        }
    }
}

struct NeonToggleStyle: ToggleStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
        .background(
            Capsule()
                .fill(configuration.isOn ? color.opacity(0.3) : Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(configuration.isOn ? color : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .overlay(
            GeometryReader { geometry in
                Circle()
                    .fill(configuration.isOn ? color : .white.opacity(0.4))
                    .frame(width: 24, height: 24)
                    .shadow(color: configuration.isOn ? color.opacity(0.6) : .clear, radius: 6)
                    .offset(x: configuration.isOn ? geometry.size.width / 2 - 16 : -(geometry.size.width / 2 - 16))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isOn)
            }
        )
        .frame(width: 52, height: 30)
        .contentShape(Capsule())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}
