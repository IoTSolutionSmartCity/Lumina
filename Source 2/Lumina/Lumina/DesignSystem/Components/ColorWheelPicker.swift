import SwiftUI

struct ColorWheelPicker: View {
    @Binding var selectedColor: Color
    var onColorChange: ((Color) -> Void)?

    @State private var isDragging = false
    @State private var presetHexColors: [String] = ColorWheelPicker.defaultPresetHexColors
    @State private var isEditingPresets = false

    private static let presetStorageKey = "colorWheelPresetHexColors"
    private static let defaultPresetHexColors = ["7C3AED", "06B6D4", "EC4899", "10B981", "F59E0B", "FFFFFF"]

    var body: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            header

            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
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
                        .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
                        .shadow(color: selectedColor.opacity(isDragging ? 0.5 : 0.24), radius: isDragging ? 22 : 14)

                    Circle()
                        .fill(selectedColor)
                        .frame(width: isDragging ? 34 : 28, height: isDragging ? 34 : 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: selectedColor.opacity(0.8), radius: 12)
                        .position(indicatorPosition(in: geometry.size, wheelDiameter: size))
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2), value: isDragging)

                    if isDragging {
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            .frame(width: size * 0.18, height: size * 0.18)
                            .position(center)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let color = colorAt(point: value.location, in: geometry.size, wheelDiameter: size)
                            selectedColor = color
                            onColorChange?(color)
                        }
                        .onEnded { value in
                            selectedColor = colorAt(point: value.location, in: geometry.size, wheelDiameter: size)
                            onColorChange?(selectedColor)
                            isDragging = false
                            HapticManager.shared.selection()
                        }
                )
            }
            .aspectRatio(1, contentMode: .fit)

            presetColors
        }
        .onAppear(perform: loadPresets)
    }

    private var header: some View {
        HStack(spacing: LuminaTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Color")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white.opacity(0.75))
                Text("#\(selectedColor.hexString)")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            Circle()
                .fill(selectedColor)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 2))
                .shadow(color: selectedColor.opacity(0.8), radius: 8)

            Button {
                toggleCurrentPreset()
            } label: {
                Image(systemName: containsCurrentColor ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(containsCurrentColor ? LuminaTheme.neonGreen : LuminaTheme.neonPurple)
            }

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isEditingPresets.toggle()
                }
            } label: {
                Image(systemName: isEditingPresets ? "checkmark" : "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private var presetColors: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            HStack {
                Text("Presets")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                if isEditingPresets {
                    Button("Reset") {
                        resetPresets()
                    }
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(LuminaTheme.neonPurple)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LuminaTheme.Spacing.sm) {
                    ForEach(presetHexColors, id: \.self) { hex in
                        let color = Color(hex: hex)
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(
                                        selectedColor.hexString == hex ? Color.white : Color.white.opacity(0.16),
                                        lineWidth: selectedColor.hexString == hex ? 2 : 1
                                    )
                                )
                                .shadow(color: color.opacity(0.6), radius: selectedColor.hexString == hex ? 8 : 0)
                                .onTapGesture {
                                    selectedColor = color
                                    onColorChange?(color)
                                    HapticManager.shared.lightImpact()
                                }

                            if isEditingPresets {
                                Button {
                                    removePreset(hex)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(LuminaTheme.neonRed)
                                        .background(Circle().fill(LuminaTheme.deepNavy))
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var containsCurrentColor: Bool {
        presetHexColors.contains(selectedColor.hexString)
    }

    private func indicatorPosition(in size: CGSize, wheelDiameter: CGFloat) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = wheelDiameter / 2
        let hsba = selectedColor.hsbaComponents
        let hue = Double(hsba.hue)
        let saturation = max(0.08, Double(hsba.saturation))
        let angle = Angle(degrees: hue * 360 - 90)
        let x = center.x + cos(angle.radians) * radius * saturation
        let y = center.y + sin(angle.radians) * radius * saturation
        return CGPoint(x: x, y: y)
    }

    private func colorAt(point: CGPoint, in size: CGSize, wheelDiameter: CGFloat) -> Color {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let angle = atan2(dy, dx)
        let degrees = Double(angle * 180 / .pi)
        let hue = (degrees + 90).truncatingRemainder(dividingBy: 360) / 360.0
        let normalizedHue = hue < 0 ? hue + 1 : hue
        let distance = sqrt(dx * dx + dy * dy)
        let saturation = min(max(distance / (wheelDiameter / 2), 0.02), 1.0)
        let brightness = 1.0 - max(0, 0.18 - saturation) * 0.35
        return Color(hue: normalizedHue, saturation: saturation, brightness: brightness)
    }

    private func loadPresets() {
        if let saved = UserDefaults.standard.array(forKey: Self.presetStorageKey) as? [String],
           !saved.isEmpty {
            presetHexColors = saved
        }
    }

    private func savePresets() {
        UserDefaults.standard.set(presetHexColors, forKey: Self.presetStorageKey)
    }

    private func toggleCurrentPreset() {
        let hex = selectedColor.hexString
        if !presetHexColors.contains(hex) {
            presetHexColors.append(hex)
            savePresets()
            HapticManager.shared.success()
        }
    }

    private func removePreset(_ hex: String) {
        guard presetHexColors.count > 1 else { return }
        presetHexColors.removeAll { $0 == hex }
        savePresets()
        HapticManager.shared.lightImpact()
    }

    private func resetPresets() {
        presetHexColors = Self.defaultPresetHexColors
        savePresets()
        HapticManager.shared.mediumImpact()
    }
}
