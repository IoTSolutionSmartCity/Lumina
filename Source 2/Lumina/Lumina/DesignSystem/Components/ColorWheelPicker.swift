import SwiftUI

struct ColorWheelPicker: View {
    @Binding var selectedColor: Color
    var onColorChange: ((Color) -> Void)?

    @State private var touchLocation: CGPoint = .zero
    @State private var isDragging = false
    @State private var wheelSize: CGFloat = 0

    var body: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            HStack {
                Text("Color")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Circle()
                    .fill(selectedColor)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                    .shadow(color: selectedColor.opacity(0.8), radius: 8)
            }

            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "FF0000"), Color(hex: "FFFF00"),
                                    Color(hex: "00FF00"), Color(hex: "00FFFF"),
                                    Color(hex: "0000FF"), Color(hex: "FF00FF"),
                                    Color(hex: "FF0000")
                                ]),
                                center: .center
                            )
                        )
                        .overlay(
                            RadialGradient(
                                gradient: Gradient(colors: [.white, .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: size / 2
                            )
                        )
                        .frame(width: size, height: size)

                    Circle()
                        .fill(selectedColor)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: selectedColor.opacity(0.8), radius: 12)
                        .position(indicatorPosition(in: geometry.size))
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2), value: isDragging)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            touchLocation = value.location
                            let color = colorAt(point: value.location, in: geometry.size)
                            selectedColor = color
                            onColorChange?(color)
                            HapticManager.shared.selection()
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .onAppear {
                    wheelSize = size
                }
            }
            .aspectRatio(1, contentMode: .fit)

            presetColors
        }
    }

    private var presetColors: some View {
        HStack(spacing: LuminaTheme.Spacing.sm) {
            ForEach(presetColorSet, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().stroke(
                            selectedColor == color ? Color.white : Color.clear,
                            lineWidth: 2
                        )
                    )
                    .shadow(color: color.opacity(0.6), radius: selectedColor == color ? 8 : 0)
                    .onTapGesture {
                        selectedColor = color
                        onColorChange?(color)
                        HapticManager.shared.lightImpact()
                    }
            }
        }
    }

    private var presetColorSet: [Color] {
        [
            LuminaTheme.neonPurple,
            LuminaTheme.neonCyan,
            LuminaTheme.neonPink,
            LuminaTheme.neonGreen,
            LuminaTheme.neonOrange,
            .white
        ]
    }

    private func indicatorPosition(in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2
        let hue = colorHue(for: selectedColor)
        let angle = Angle(degrees: hue * 360 - 90)
        let x = center.x + cos(angle.radians) * radius * 0.8
        let y = center.y + sin(angle.radians) * radius * 0.8
        return CGPoint(x: x, y: y)
    }

    private func colorAt(point: CGPoint, in size: CGSize) -> Color {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let angle = atan2(dy, dx)
        let degrees = Double(angle * 180 / .pi)
        let hue = (degrees + 90).truncatingRemainder(dividingBy: 360) / 360.0
        let normalizedHue = hue < 0 ? hue + 1 : hue
        let saturation = min(sqrt(dx * dx + dy * dy) / (min(size.width, size.height) / 2), 1.0)
        return Color(hue: normalizedHue, saturation: saturation, brightness: 1.0)
    }

    private func colorHue(for color: Color) -> Double {
        let uiColor = UIColor(color)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Double(h)
    }
}
