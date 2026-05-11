import SwiftUI

struct ControlCard: View {
    @Binding var brightness: Double
    @Binding var selectedColor: Color
    @Binding var isOn: Bool

    @State private var isExpanded = true

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
        HStack {
            HStack(spacing: LuminaTheme.Spacing.sm) {
                GlowIcon(systemName: "power", color: isOn ? LuminaTheme.neonGreen : .white.opacity(0.4), size: 20)
                Text("Power")
                    .font(LuminaTheme.Typography.headline)
                    .foregroundColor(.white)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isOn = newValue
                    }
                    HapticManager.shared.mediumImpact()
                }
            ))
            .toggleStyle(NeonToggleStyle(color: LuminaTheme.neonGreen))
            .labelsHidden()
        }
        .padding(.bottom, isOn ? 0 : LuminaTheme.Spacing.lg)
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
