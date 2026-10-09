import SwiftUI

struct LampPreview3D: View {
    var color: Color
    var brightness: Double
    var isOn: Bool
    var showsReadout: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            lampGlow

            VStack(spacing: 0) {
                Spacer()

                lampShade
                    .padding(.bottom, -8)

                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.full)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.75), .white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 12, height: 92)

                Ellipse()
                    .fill(LinearGradient(
                        colors: [LuminaTheme.darkCard, LuminaTheme.darkSurface],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 132, height: 26)
                    .overlay(Ellipse().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    .padding(.top, -2)

                Spacer()
            }
            .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 18)

            if showsReadout {
                VStack {
                    Spacer()
                    Text(isOn ? "\(Int(brightness * 100))% brightness" : "Lamp off")
                        .font(LuminaTheme.Typography.captionBold)
                        .foregroundColor(LuminaTheme.textSecondary)
                        .padding(.bottom, LuminaTheme.Spacing.md)
                }
            }
        }
        .frame(height: 300)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isOn)
    }

    private var lampShade: some View {
        ZStack {
            Ellipse()
                .fill(isOn ? color.opacity(0.55 * brightness) : LuminaTheme.darkCard)
                .frame(width: 150, height: 58)
                .opacity(isOn ? 1 : 0)

            Trapezoid()
                .fill(LinearGradient(
                    colors: [
                        isOn ? color.opacity(0.95) : LuminaTheme.darkCard,
                        LuminaTheme.darkSurface
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 150, height: 92)
                .overlay(Trapezoid().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
    }

    private var lampGlow: some View {
        Circle()
            .fill(RadialGradient(
                colors: [
                    color.opacity(isOn ? 0.5 * brightness : 0),
                    color.opacity(isOn ? 0.16 * brightness : 0),
                    .clear
                ],
                center: .center,
                startRadius: 12,
                endRadius: 150
            ))
            .frame(width: 260, height: 260)
    }
}

struct Trapezoid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct LampPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                .fill(Color.black.opacity(0.2))

            VStack(spacing: 12) {
                AnimatedGlowIcon(systemName: "lamp.desk.fill", color: LuminaTheme.neonPurple, size: 48)
                Text("Lamp Preview")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.textSecondary)
            }
        }
        .frame(height: 300)
    }
}
