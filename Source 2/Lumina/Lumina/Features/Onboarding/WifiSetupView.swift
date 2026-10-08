import SwiftUI

struct WifiSetupView: View {
    var onFinished: () -> Void

    @State private var ssid = ""
    @State private var password = ""
    @State private var isSaving = false
    @State private var saved = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case ssid
        case password
    }

    var body: some View {
        ZStack {
            LuminaTheme.backgroundGradient.ignoresSafeArea()

            if saved {
                savedContent
            } else {
                formContent
            }
        }
        .navigationTitle("Lamp Wi-Fi")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LuminaTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
                    Text("Join your home Wi-Fi")
                        .font(LuminaTheme.Typography.title)
                        .foregroundColor(.white)
                    Text("The lamp needs this network before a HomePod mini can add it in Apple Home.")
                        .font(LuminaTheme.Typography.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: LuminaTheme.Spacing.md) {
                    TextField("Wi-Fi name", text: $ssid)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.none)
                        .focused($focusedField, equals: .ssid)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                        .wifiFieldStyle()

                    HStack(spacing: LuminaTheme.Spacing.sm) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { save() }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                    .wifiFieldStyle()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(LuminaTheme.neonRed)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NeonButton(isSaving ? "Sending…" : "Save to lamp", icon: "wifi") {
                    save()
                }
                .disabled(isSaving || ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                Button("Not now") {
                    onFinished()
                }
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.55))
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(LuminaTheme.Spacing.lg)
        }
    }

    private var savedContent: some View {
        VStack(spacing: LuminaTheme.Spacing.lg) {
            Spacer()

            LampPreview3D(color: .white, brightness: 1, isOn: true, showsReadout: false)
                .frame(height: 220)
                .accessibilityHidden(true)

            VStack(spacing: LuminaTheme.Spacing.sm) {
                Text("Lamp is joining Wi-Fi")
                    .font(LuminaTheme.Typography.title)
                    .foregroundColor(.white)
                Text("On the iPhone for your HomePod mini, open the Home app, add an accessory, and enter this code.")
                    .font(LuminaTheme.Typography.subheadline)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LuminaTheme.Spacing.lg)

            Text(BluetoothManager.homeKitSetupCode)
                .font(.system(.largeTitle, design: .monospaced, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, LuminaTheme.Spacing.lg)
                .padding(.vertical, LuminaTheme.Spacing.md)
                .glassCard(cornerRadius: LuminaTheme.CornerRadius.lg)
                .accessibilityLabel("HomeKit code \(BluetoothManager.homeKitSetupCode)")

            NeonButton("Continue", icon: "arrow.right") {
                onFinished()
            }
            .padding(.horizontal, LuminaTheme.Spacing.lg)

            Spacer()
        }
    }

    private func save() {
        let network = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !network.isEmpty, !isSaving else { return }
        focusedField = nil
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await BluetoothManager.shared.sendWifi(ssid: network, password: password)
                saved = true
                HapticManager.shared.success()
            } catch {
                errorMessage = error.localizedDescription
                HapticManager.shared.error()
            }
            isSaving = false
        }
    }
}

private extension View {
    func wifiFieldStyle() -> some View {
        self
            .foregroundColor(.white)
            .tint(LuminaTheme.neonPurple)
            .padding(.horizontal, LuminaTheme.Spacing.md)
            .frame(minHeight: 52)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.md)
                    .stroke(LuminaTheme.glassBorder, lineWidth: 1)
            )
    }
}
