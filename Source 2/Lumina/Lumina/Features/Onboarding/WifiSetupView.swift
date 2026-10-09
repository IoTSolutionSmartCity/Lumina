import SwiftUI

struct WifiSetupView: View {
    var onFinished: () -> Void

    @State private var password = ""
    @State private var manualSsid = ""
    @State private var isSaving = false
    @State private var isScanningNetworks = true
    @State private var saved = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var prompt: Prompt?
    @FocusState private var focusedField: Field?

    private var bluetooth: BluetoothManager { .shared }

    private enum Field: Hashable {
        case password
        case manualSsid
    }

    private enum Prompt: Identifiable {
        case secured(LampWifiNetwork)
        case manual

        var id: String {
            switch self {
            case .secured(let network): return network.ssid
            case .manual: return "manual"
            }
        }
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
        .toolbar {
            if !saved {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { onFinished() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await refresh()
        }
        .sheet(item: $prompt) { prompt in
            passwordSheet(prompt)
        }
    }

    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: LuminaTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
                    Text("Choose a network")
                        .font(LuminaTheme.Typography.title)
                        .foregroundColor(.white)
                    Text("The lamp lists the Wi-Fi it can join. A password saved in Lumina is sent for you. A new network asks for the password.")
                        .font(LuminaTheme.Typography.subheadline)
                        .foregroundColor(LuminaTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                networkList

                if let errorMessage {
                    Text(errorMessage)
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(LuminaTheme.neonRed)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GlassButton(isScanningNetworks ? "Scanning…" : "Scan again", icon: "arrow.clockwise") {
                    Task { await refresh() }
                }
                .disabled(isScanningNetworks || isSaving)
                .opacity(isScanningNetworks || isSaving ? 0.5 : 1)

                Button("Other network") {
                    manualSsid = ""
                    password = ""
                    showPassword = false
                    prompt = .manual
                }
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(LuminaTheme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(isSaving)
            }
            .padding(LuminaTheme.Spacing.lg)
        }
    }

    private var networkList: some View {
        VStack(spacing: 0) {
            if bluetooth.nearbyNetworks.isEmpty {
                HStack(spacing: LuminaTheme.Spacing.sm) {
                    if isScanningNetworks {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isScanningNetworks ? "Looking for networks…" : "No networks found.")
                        .font(LuminaTheme.Typography.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .padding(.horizontal, LuminaTheme.Spacing.md)
            } else {
                ForEach(bluetooth.nearbyNetworks) { network in
                    networkRow(network)
                    if network.id != bluetooth.nearbyNetworks.last?.id {
                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }
            }
        }
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.lg)
    }

    private func networkRow(_ network: LampWifiNetwork) -> some View {
        let savedPassword = network.secured ? WifiPasswordStore.password(for: network.ssid) : nil
        return HStack(spacing: LuminaTheme.Spacing.sm) {
            Button {
                choose(network)
            } label: {
                HStack(spacing: LuminaTheme.Spacing.md) {
                    Image(systemName: "wifi", variableValue: signal(network.rssi))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(LuminaTheme.neonCyan)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(network.ssid)
                            .font(LuminaTheme.Typography.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(detail(for: network, savedPassword: savedPassword != nil))
                            .font(LuminaTheme.Typography.caption)
                            .foregroundColor(LuminaTheme.textSecondary)
                    }
                    Spacer(minLength: LuminaTheme.Spacing.sm)
                    if network.secured && savedPassword == nil {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LuminaTheme.textSecondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .disabled(isSaving)
            .accessibilityLabel(accessibilityLabel(for: network, hasSavedPassword: savedPassword != nil))

            if savedPassword != nil {
                Button("Edit") {
                    password = ""
                    showPassword = false
                    prompt = .secured(network)
                }
                .font(LuminaTheme.Typography.captionBold)
                .foregroundColor(LuminaTheme.neonPurpleLight)
                .frame(minWidth: 44, minHeight: 44)
                .disabled(isSaving)
                .accessibilityLabel("Enter a different password for \(network.ssid)")
            }
        }
        .padding(.horizontal, LuminaTheme.Spacing.md)
        .frame(minHeight: 60)
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
                Text("Open the Home app, add an accessory, and enter this code.")
                    .font(LuminaTheme.Typography.subheadline)
                    .foregroundColor(LuminaTheme.textSecondary)
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

    private func passwordSheet(_ prompt: Prompt) -> some View {
        NavigationStack {
            ZStack {
                LuminaTheme.backgroundGradient.ignoresSafeArea()
                VStack(alignment: .leading, spacing: LuminaTheme.Spacing.lg) {
                    Text(promptTitle(prompt))
                        .font(LuminaTheme.Typography.title)
                        .foregroundColor(.white)
                    Text(promptMessage(prompt))
                        .font(LuminaTheme.Typography.subheadline)
                        .foregroundColor(LuminaTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if case .manual = prompt {
                        TextField("Wi-Fi name", text: $manualSsid)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .manualSsid)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .wifiFieldStyle()
                    }

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
                        .onSubmit { confirm(prompt) }

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

                    NeonButton(isSaving ? "Sending…" : "Save to lamp", icon: "wifi") {
                        confirm(prompt)
                    }
                    .disabled(!canConfirm(prompt) || isSaving)
                    .opacity(!canConfirm(prompt) || isSaving ? 0.5 : 1)

                    Spacer()
                }
                .padding(LuminaTheme.Spacing.lg)
            }
            .navigationTitle("Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { self.prompt = nil }
                        .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func refresh() async {
        guard !isSaving else { return }
        isScanningNetworks = true
        errorMessage = nil
        do {
            try await bluetooth.requestWifiScan()
        } catch {
            errorMessage = error.localizedDescription
        }
        isScanningNetworks = false
    }

    private func choose(_ network: LampWifiNetwork) {
        guard !isSaving else { return }
        if !network.secured {
            submit(ssid: network.ssid, password: "", remember: false)
            return
        }
        if let savedPassword = WifiPasswordStore.password(for: network.ssid) {
            submit(ssid: network.ssid, password: savedPassword, remember: false)
            return
        }
        password = ""
        showPassword = false
        prompt = .secured(network)
    }

    private func confirm(_ prompt: Prompt) {
        switch prompt {
        case .secured(let network):
            let typed = password
            self.prompt = nil
            submit(ssid: network.ssid, password: typed, remember: true)
        case .manual:
            let network = manualSsid.trimmingCharacters(in: .whitespacesAndNewlines)
            let typed = password
            self.prompt = nil
            submit(ssid: network, password: typed, remember: !typed.isEmpty)
        }
    }

    private func submit(ssid: String, password: String, remember: Bool) {
        let network = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !network.isEmpty, !isSaving else { return }
        focusedField = nil
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await BluetoothManager.shared.sendWifi(ssid: network, password: password)
                WifiPasswordStore.markChosen()
                if remember {
                    WifiPasswordStore.save(password, for: network)
                }
                saved = true
                HapticManager.shared.success()
            } catch {
                errorMessage = error.localizedDescription
                HapticManager.shared.error()
            }
            isSaving = false
        }
    }

    private func canConfirm(_ prompt: Prompt) -> Bool {
        switch prompt {
        case .secured:
            return !password.isEmpty
        case .manual:
            return !manualSsid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func promptTitle(_ prompt: Prompt) -> String {
        switch prompt {
        case .secured(let network): return network.ssid
        case .manual: return "Other network"
        }
    }

    private func promptMessage(_ prompt: Prompt) -> String {
        switch prompt {
        case .secured:
            return "This iPhone does not have this password saved in Lumina yet."
        case .manual:
            return "Use this when the network is hidden. Leave the password empty if the network is open."
        }
    }

    private func detail(for network: LampWifiNetwork, savedPassword: Bool) -> String {
        if !network.secured { return "No password" }
        if savedPassword { return "Saved password" }
        return "Needs a password"
    }

    private func accessibilityLabel(for network: LampWifiNetwork, hasSavedPassword: Bool) -> String {
        if !network.secured { return "\(network.ssid), open network" }
        if hasSavedPassword { return "\(network.ssid), send saved password" }
        return "\(network.ssid), enter password"
    }

    private func signal(_ rssi: Int) -> Double {
        let clamped = min(max(rssi, -90), -40)
        return Double(clamped + 90) / 50
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
