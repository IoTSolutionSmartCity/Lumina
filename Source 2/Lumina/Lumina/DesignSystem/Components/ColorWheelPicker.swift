import SwiftUI

struct ColorWheelPicker: View {
    @Binding var selectedColor: Color
    var onColorChange: ((Color) -> Void)?
    var isBreathing: Binding<Bool> = .constant(false)
    var isFlowing: Binding<Bool> = .constant(false)
    var onMode: ((UInt8, Color, Bool) -> Void)?
    var onEffectChange: (() -> Void)?

    @State private var isDragging = false
    @State private var presetHexColors: [String] = ColorWheelPicker.defaultPresetHexColors
    @State private var isEditingPresets = false
    @State private var colorMode: ColorMode = .color
    @State private var savedWheelColor = LuminaTheme.neonPurple
    @State private var ignoreModeChange = true
    @State private var breathColor = LampEffects.breathColor
    @State private var breathMinimum = LampEffects.breathMinimum
    @State private var breathMaximum = LampEffects.breathMaximum
    @State private var flowColors = LampEffects.flowColors
    @State private var flowBrightness = LampEffects.flowBrightness
    @State private var flowIndex = 0

    private static let presetStorageKey = "colorWheelPresetHexColors"
    private static let defaultPresetHexColors = ["7C3AED", "06B6D4", "EC4899", "10B981", "F59E0B", "FFFFFF"]
    private static let warmWhite = Color(hex: "FFB46E")
    private static let softWhite = Color(hex: "F6F1E7")
    private static let coolWhite = Color(hex: "D6E8FF")

    private enum ColorMode: String, CaseIterable {
        case color = "Color"
        case warm = "Warm"
        case soft = "Soft"
        case cool = "Cool"
        case breath = "Breath"
        case flow = "Flow"

        var deviceId: UInt8 {
            switch self {
            case .color: return 0
            case .warm: return 1
            case .soft: return 2
            case .cool: return 3
            case .breath: return 4
            case .flow: return 5
            }
        }

        var white: Color? {
            switch self {
            case .color, .breath, .flow: return nil
            case .warm: return ColorWheelPicker.warmWhite
            case .soft: return ColorWheelPicker.softWhite
            case .cool: return ColorWheelPicker.coolWhite
            }
        }
    }

    var body: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            header

            modePicker

            if colorMode != .color {
                effectCard
            }
            if colorMode == .breath || colorMode == .flow {
                effectControls
            }
            if colorMode == .color || colorMode == .breath || colorMode == .flow {
                colorWheel
            }

            presetColors
        }
        .animation(nil, value: colorMode)
        .onAppear {
            loadPresets()
            if let match = ColorMode.allCases.first(where: { $0.white?.hexString == selectedColor.hexString }) {
                colorMode = match
            } else {
                savedWheelColor = selectedColor
                ignoreModeChange = false
            }
        }
        .onChange(of: colorMode) { oldMode, mode in
            if oldMode == .color {
                savedWheelColor = selectedColor
            }
            isBreathing.wrappedValue = mode == .breath
            isFlowing.wrappedValue = mode == .flow
            let color = mode == .breath || mode == .flow ? selectedColor : (mode.white ?? savedWheelColor)
            if mode != .breath && mode != .flow, color.hexString != selectedColor.hexString {
                selectedColor = color
            }
            guard !ignoreModeChange else {
                ignoreModeChange = false
                return
            }
            onMode?(mode.deviceId, color, mode == .breath)
            HapticManager.shared.selection()
        }
        .onChange(of: breathMinimum) { _, value in
            let limit = breathMaximum - 0.05
            guard value <= limit else {
                breathMinimum = max(0, limit)
                return
            }
            commitBreath()
        }
        .onChange(of: breathMaximum) { _, value in
            let limit = breathMinimum + 0.05
            guard value >= limit else {
                breathMaximum = min(1, limit)
                return
            }
            commitBreath()
        }
        .onChange(of: flowBrightness) { _, _ in
            commitFlow()
        }
        .onDisappear {
            isBreathing.wrappedValue = false
            isFlowing.wrappedValue = false
        }
    }

    private var colorWheel: some View {
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
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
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

                    Circle()
                        .fill(activeColor)
                        .frame(width: isDragging ? 34 : 28, height: isDragging ? 34 : 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: activeColor.opacity(0.8), radius: 12)
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
                            assignWheel(colorAt(point: value.location, in: geometry.size, wheelDiameter: size))
                        }
                        .onEnded { value in
                            assignWheel(colorAt(point: value.location, in: geometry.size, wheelDiameter: size))
                            if colorMode == .color {
                                onMode?(ColorMode.color.deviceId, selectedColor, false)
                            }
                            isDragging = false
                            HapticManager.shared.selection()
                        }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Color wheel")
                .accessibilityValue("Hex \(activeColor.hexString)")
                .accessibilityHint("Swipe up or down to adjust hue")
                .accessibilityAddTraits(.allowsDirectInteraction)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: adjustHue(by: 1.0 / 36)
                    case .decrement: adjustHue(by: -1.0 / 36)
                    @unknown default: break
                    }
                }
            }
        .aspectRatio(1, contentMode: .fit)
    }

    private var modePicker: some View {
        VStack(spacing: LuminaTheme.Spacing.sm) {
            HStack(spacing: LuminaTheme.Spacing.sm) {
                ForEach([ColorMode.color, .warm, .soft, .cool], id: \.self) { mode in
                    modeChip(mode)
                }
            }
            HStack(spacing: LuminaTheme.Spacing.sm) {
                modeChip(.breath)
                modeChip(.flow)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color mode")
    }

    private func modeChip(_ mode: ColorMode) -> some View {
        Button {
            colorMode = mode
        } label: {
            Text(mode.rawValue)
                .font(LuminaTheme.Typography.captionBold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(colorMode == mode ? .white : LuminaTheme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Capsule().fill(colorMode == mode ? LuminaTheme.neonPurple : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(colorMode == mode ? .isSelected : [])
    }

    private var effectCard: some View {
        RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xl)
            .fill(previewFill)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .overlay { effectCardLabel }
            .accessibilityElement(children: colorMode == .flow ? .contain : .ignore)
            .accessibilityLabel(modeTitle)
    }

    @ViewBuilder
    private var effectCardLabel: some View {
        if colorMode == .flow {
            HStack(spacing: 8) {
                ForEach(Array(flowColors.enumerated()), id: \.offset) { index, color in
                    Button {
                        flowIndex = min(index, max(flowColors.count - 1, 0))
                        HapticManager.shared.selection()
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(
                                    index == flowIndex ? Color.white : Color.black.opacity(0.25),
                                    lineWidth: index == flowIndex ? 3 : 1
                                )
                            )
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Flow color \(index + 1)")
                    .accessibilityAddTraits(index == flowIndex ? .isSelected : [])
                }
            }
        } else {
            Text(modeTitle)
                .font(LuminaTheme.Typography.headline)
                .foregroundColor(.black.opacity(0.72))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var effectControls: some View {
        if colorMode == .breath {
            GlassSlider(value: $breathMinimum, icon: "moon.fill", label: "Dim", tint: breathColor)
            GlassSlider(value: $breathMaximum, icon: "sun.max.fill", label: "Bright", tint: breathColor)
        } else if colorMode == .flow {
            HStack {
                Button("Add color") {
                    guard flowColors.count < 5 else { return }
                    flowColors.append(flowColors.last ?? Color(hex: "FFFFFF"))
                    flowIndex = flowColors.count - 1
                    commitFlow()
                }
                .disabled(flowColors.count >= 5)
                Spacer()
                Button("Remove") {
                    guard flowColors.count > 2, flowColors.indices.contains(flowIndex) else { return }
                    flowColors.remove(at: flowIndex)
                    flowIndex = min(flowIndex, flowColors.count - 1)
                    commitFlow()
                }
                .disabled(flowColors.count <= 2)
            }
            .font(LuminaTheme.Typography.captionBold)
            .foregroundColor(LuminaTheme.neonCyan)
            .frame(minHeight: 44)
            GlassSlider(value: $flowBrightness, icon: "sun.max.fill", label: "Brightness", tint: activeColor)
        }
    }

    private var modeTitle: String {
        switch colorMode {
        case .color: return "Color"
        case .warm: return "Warm white"
        case .soft: return "Soft white"
        case .cool: return "Cool white"
        case .breath: return "Breathing"
        case .flow: return "Flowing colors"
        }
    }

    private var previewFill: Color {
        switch colorMode {
        case .breath: return breathColor
        case .flow: return flowSwatch
        default: return selectedColor
        }
    }

    private var flowSwatch: Color {
        guard flowColors.indices.contains(flowIndex) else { return flowColors.first ?? selectedColor }
        return flowColors[flowIndex]
    }

    private var header: some View {
        HStack(spacing: LuminaTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Color")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white.opacity(0.75))
                Text("#\(activeColor.hexString)")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.textSecondary)
            }

            Spacer()

            Circle()
                .fill(activeColor)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 2))
                .shadow(color: activeColor.opacity(0.8), radius: 8)

            Button {
                toggleCurrentPreset()
            } label: {
                Image(systemName: containsCurrentColor ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(containsCurrentColor ? LuminaTheme.neonGreen : LuminaTheme.neonPurple)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(containsCurrentColor ? "Remove current color from presets" : "Add current color to presets")

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isEditingPresets.toggle()
                }
            } label: {
                Image(systemName: isEditingPresets ? "checkmark" : "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(LuminaTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(isEditingPresets ? "Done editing presets" : "Edit presets")
        }
    }

    private var presetColors: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            HStack {
                Text("Presets")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.textSecondary)
                Spacer()
                if isEditingPresets {
                    Button("Reset") {
                        resetPresets()
                    }
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(LuminaTheme.neonPurple)
                    .buttonStyle(.pressable)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LuminaTheme.Spacing.sm) {
                    ForEach(presetHexColors, id: \.self) { hex in
                        let color = Color(hex: hex)
                        let isSelected = activeColor.hexString == hex
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle().stroke(
                                        isSelected ? Color.white : Color.white.opacity(0.16),
                                        lineWidth: isSelected ? 2 : 1
                                    )
                                )
                                .shadow(color: color.opacity(0.6), radius: isSelected ? 8 : 0)
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                                .contentShape(Circle())
                                .onTapGesture {
                                    if colorMode == .breath || colorMode == .flow {
                                        assignWheel(color)
                                    } else if colorMode == .color {
                                        savedWheelColor = color
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedColor = color
                                        }
                                        onColorChange?(color)
                                        onMode?(ColorMode.color.deviceId, color, false)
                                    } else {
                                        savedWheelColor = color
                                        colorMode = .color
                                    }
                                    HapticManager.shared.lightImpact()
                                }
                                .accessibilityLabel("Preset color #\(hex)")
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAddTraits(isSelected ? [.isSelected] : [])

                            if isEditingPresets {
                                Button {
                                    removePreset(hex)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(LuminaTheme.neonRed)
                                        .background(Circle().fill(LuminaTheme.deepNavy))
                                        .frame(width: 44, height: 44, alignment: .topTrailing)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.pressable)
                                .accessibilityLabel("Remove preset color #\(hex)")
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: presetHexColors)
            }
        }
    }

    private var containsCurrentColor: Bool {
        presetHexColors.contains(activeColor.hexString)
    }

    private var activeColor: Color {
        switch colorMode {
        case .breath: return breathColor
        case .flow: return flowSwatch
        default: return selectedColor
        }
    }

    private func assignWheel(_ color: Color) {
        switch colorMode {
        case .breath:
            breathColor = color
            commitBreath()
        case .flow:
            guard flowColors.indices.contains(flowIndex) else { return }
            flowColors[flowIndex] = color
            commitFlow()
        default:
            selectedColor = color
            savedWheelColor = color
            onColorChange?(color)
        }
    }

    private func commitBreath() {
        LampEffects.saveBreath(color: breathColor, minimum: breathMinimum, maximum: breathMaximum)
        onEffectChange?()
    }

    private func commitFlow() {
        LampEffects.saveFlow(colors: flowColors, brightness: flowBrightness)
        onEffectChange?()
    }

    private func indicatorPosition(in size: CGSize, wheelDiameter: CGFloat) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = wheelDiameter / 2
        let hsba = activeColor.hsbaComponents
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
        return Color(hue: normalizedHue, saturation: saturation, brightness: 1)
    }

    private func adjustHue(by delta: Double) {
        let hsba = activeColor.hsbaComponents
        var hue = Double(hsba.hue) + delta
        hue = hue.truncatingRemainder(dividingBy: 1.0)
        if hue < 0 { hue += 1 }
        let saturation = max(0.08, Double(hsba.saturation))
        let color = Color(hue: hue, saturation: saturation, brightness: Double(hsba.brightness))
        assignWheel(color)
        HapticManager.shared.selection()
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
        let hex = activeColor.hexString
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
