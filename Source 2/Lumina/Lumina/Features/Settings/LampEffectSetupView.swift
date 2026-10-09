import SwiftUI

struct LampEffectSetupView: View {
    @State private var bluetooth = BluetoothManager.shared
    @State private var breathColor = LampEffects.breathColor
    @State private var breathMinimum = LampEffects.breathMinimum
    @State private var breathMaximum = LampEffects.breathMaximum
    @State private var flowColors = LampEffects.flowColors
    @State private var flowBrightness = LampEffects.flowBrightness
    @State private var status = ""

    var body: some View {
        List {
            Section {
                ColorPicker("Breath color", selection: $breathColor, supportsOpacity: false)
                    .foregroundColor(.white)
                brightnessSlider("Dim end", value: $breathMinimum)
                brightnessSlider("Bright end", value: $breathMaximum)
                Button("Save and run breath") {
                    LampEffects.saveBreath(color: breathColor, minimum: breathMinimum, maximum: breathMaximum)
                    breathMinimum = LampEffects.breathMinimum
                    breathMaximum = LampEffects.breathMaximum
                    bluetooth.sendColor(LampEffects.breathCommand())
                    status = bluetooth.connectionState == .connected
                        ? "Breath is running on the lamp."
                        : "Breath is saved. Connect the lamp to run it."
                }
                .foregroundColor(LuminaTheme.neonPurple)
            } header: {
                Text("Breath")
                    .foregroundColor(LuminaTheme.textSecondary)
            } footer: {
                Text("The color fades between the dim end and the bright end. The test LED on the ESP32-S3 follows it.")
                    .foregroundColor(LuminaTheme.textSecondary)
            }
            .listRowBackground(LuminaTheme.darkSurface)

            Section {
                ForEach(flowColors.indices, id: \.self) { index in
                    HStack {
                        ColorPicker("Color \(index + 1)", selection: $flowColors[index], supportsOpacity: false)
                            .foregroundColor(.white)
                        if flowColors.count > 2 {
                            Button {
                                flowColors.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove color \(index + 1)")
                        }
                    }
                }
                if flowColors.count < 5 {
                    Button("Add color") {
                        flowColors.append(Color(hex: "FFFFFF"))
                    }
                    .foregroundColor(LuminaTheme.neonCyan)
                }
                brightnessSlider("Brightness", value: $flowBrightness)
                Button("Save and run flow") {
                    LampEffects.saveFlow(colors: flowColors, brightness: flowBrightness)
                    flowColors = LampEffects.flowColors
                    bluetooth.sendColor(LampEffects.flowCommand())
                    status = bluetooth.connectionState == .connected
                        ? "Flow is running on the lamp."
                        : "Flow is saved. Connect the lamp to run it."
                }
                .foregroundColor(LuminaTheme.neonPurple)
            } header: {
                Text("Flow")
                    .foregroundColor(LuminaTheme.textSecondary)
            } footer: {
                Text(status.isEmpty
                     ? "Colors blend from the first to the last, then repeat. Up to five colors."
                     : status)
                    .foregroundColor(LuminaTheme.textSecondary)
            }
            .listRowBackground(LuminaTheme.darkSurface)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .background(LuminaTheme.deepNavy.ignoresSafeArea())
        .navigationTitle("Breath and Flow")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: breathMinimum) { _, value in
            if value > breathMaximum - 0.05 {
                breathMinimum = max(0, breathMaximum - 0.05)
            }
        }
        .onChange(of: breathMaximum) { _, value in
            if value < breathMinimum + 0.05 {
                breathMaximum = min(1, breathMinimum + 0.05)
            }
        }
    }

    private func brightnessSlider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title) \(Int((value.wrappedValue * 100).rounded()))%")
                .font(LuminaTheme.Typography.caption)
                .foregroundColor(LuminaTheme.textSecondary)
            Slider(value: value, in: 0...1)
                .tint(LuminaTheme.neonPurple)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int((value.wrappedValue * 100).rounded())) percent")
    }
}
