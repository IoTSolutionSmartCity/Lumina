import SwiftUI

struct ControlCard: View {
    @Binding var brightness: Double
    @Binding var selectedColor: Color
    @Binding var isOn: Bool

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
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isOn)
        }
    }

    private var powerToggle: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                isOn.toggle()
            }
            HapticManager.shared.mediumImpact()
        } label: {
            HStack(spacing: LuminaTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isOn ? LuminaTheme.neonGreen.opacity(0.22) : LuminaTheme.neonRed.opacity(0.14))
                        .frame(width: 56, height: 56)
                        .shadow(color: (isOn ? LuminaTheme.neonGreen : LuminaTheme.neonRed).opacity(isOn ? 0.75 : 0.25), radius: isOn ? 18 : 8)

                    GlowIcon(
                        systemName: "power",
                        color: isOn ? LuminaTheme.neonGreen : .white.opacity(0.55),
                        size: 26,
                        glowRadius: isOn ? 12 : 3
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isOn ? "Lamp is On" : "Lamp is Off")
                        .font(LuminaTheme.Typography.title2)
                        .foregroundColor(.white)
                    Text(isOn ? "Tap to turn off" : "Tap to wake your lamp")
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Text(isOn ? "ON" : "OFF")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, LuminaTheme.Spacing.md)
                    .padding(.vertical, LuminaTheme.Spacing.sm)
                    .background((isOn ? LuminaTheme.neonGreen : LuminaTheme.neonRed).opacity(0.85))
                    .clipShape(Capsule())
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
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var brightnessControl: some View {
        GlassSlider(
            value: $brightness,
            icon: "sun.max.fill",
            label: "Brightness"
        )
        .onChange(of: brightness) { _, _ in
            HapticManager.shared.selection()
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            ColorWheelPicker(selectedColor: $selectedColor)
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
