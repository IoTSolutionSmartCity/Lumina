import SwiftUI

struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @State private var deviceRepository = DeviceRepository.shared
    @State private var bluetooth = BluetoothManager.shared
    @AppStorage("luminaDebugLed") private var debugLed = false
    @State private var showDeviceDetail: LampDevice?
    @State private var showAddDevice = false
    @State private var showSignOutConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LuminaTheme.deepNavy.ignoresSafeArea()

                List {
                    devicesSection
                    debugSection
                    accountSection
                    appSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $showDeviceDetail) { device in
                DeviceDetailView(device: device) {
                    deviceRepository.removeDevice(device)
                    showDeviceDetail = nil
                }
            }
            .sheet(isPresented: $showAddDevice) {
                OnboardingView(isOnboarded: Binding(
                    get: { session.isOnboarded },
                    set: { session.isOnboarded = $0 }
                ))
            }
            .confirmationDialog("Sign out of Lumina?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You can sign in again or continue anonymously later.")
            }
        }
    }

    private var devicesSection: some View {
        Section {
            if deviceRepository.devices.isEmpty {
                VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
                    Text("No saved lamps")
                        .font(LuminaTheme.Typography.headline)
                        .foregroundColor(.white)
                    Text("Add your Lumina ESP32-S3 lamp to control it from this phone.")
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.vertical, LuminaTheme.Spacing.sm)
                .listRowBackground(LuminaTheme.darkSurface)
            }

            ForEach(deviceRepository.devices) { device in
                Button {
                    showDeviceDetail = device
                } label: {
                    HStack(spacing: LuminaTheme.Spacing.md) {
                        let live = bluetooth.isLive(id: device.id)
                        ZStack {
                            Circle()
                                .fill(live ? LuminaTheme.neonGreen.opacity(0.2) : Color.white.opacity(0.08))
                                .frame(width: 40, height: 40)

                            GlowIcon(
                                systemName: "lamp.desk.fill",
                                color: live ? LuminaTheme.neonGreen : .white.opacity(0.7),
                                size: 18,
                                glowRadius: live ? 8 : 0
                            )
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(LuminaTheme.Typography.headline)
                                .foregroundColor(.white)

                            Text(live ? "Connected" : "Saved")
                                .font(LuminaTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        if live {
                            Circle()
                                .fill(LuminaTheme.neonGreen)
                                .frame(width: 8, height: 8)
                                .accessibilityLabel("Connected now")
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .buttonStyle(.pressable)
                .listRowBackground(LuminaTheme.darkSurface)
            }

            Button {
                showAddDevice = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(LuminaTheme.neonPurple)
                    Text("Add New Device")
                        .foregroundColor(LuminaTheme.neonPurple)
                }
            }
            .buttonStyle(.pressable)
            .listRowBackground(LuminaTheme.darkSurface)
        } header: {
            Text("Devices")
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var accountSection: some View {
        Section {
            NavigationLink {
                ProfileView()
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(LuminaTheme.primaryGradient)
                            .frame(width: 40, height: 40)
                            .shadow(color: LuminaTheme.neonPurple.opacity(0.4), radius: 6)

                        Text(userInitials)
                            .font(LuminaTheme.Typography.headline)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userDisplayName)
                            .font(LuminaTheme.Typography.headline)
                            .foregroundColor(.white)

                        Text(userEmail)
                            .font(LuminaTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .listRowBackground(LuminaTheme.darkSurface)

            Button(role: .destructive) {
                showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .foregroundColor(LuminaTheme.neonRed)
            }
            .buttonStyle(.pressable)
            .listRowBackground(LuminaTheme.darkSurface)
        } header: {
            Text("Account")
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var debugSection: some View {
        Section {
            Toggle("Onboard LED follows color", isOn: $debugLed)
                .tint(LuminaTheme.neonPurple)
                .foregroundColor(.white)
                .onChange(of: debugLed) { _, _ in
                    pushDebugColor()
                }
        } header: {
            Text("Debug")
                .foregroundColor(.white.opacity(0.5))
        } footer: {
            Text("When this is on, the LED on the ESP32-S3 board shows the color from the lamp controls. Turn it off to restore the red, orange, and green status light.")
                .foregroundColor(.white.opacity(0.45))
        }
        .listRowBackground(LuminaTheme.darkSurface)
    }

    private var appSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundColor(.white)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.white.opacity(0.5))
            }
            .listRowBackground(LuminaTheme.darkSurface)

            NavigationLink {
                Text("Help & Support")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LuminaTheme.deepNavy.ignoresSafeArea())
            } label: {
                Text("Help & Support")
                    .foregroundColor(.white)
            }
            .listRowBackground(LuminaTheme.darkSurface)
        } header: {
            Text("App")
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Lumina Smart Lamp")
                    .foregroundColor(.white)
                Spacer()
                Text("Made with ❤️")
                    .foregroundColor(.white.opacity(0.5))
            }
            .listRowBackground(LuminaTheme.darkSurface)
        } header: {
            Text("About")
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var userDisplayName: String {
        UserDefaults.standard.string(forKey: "userDisplayName") ?? "Lumina User"
    }

    private var userEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "No email"
    }

    private var userInitials: String {
        let name = userDisplayName
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }

    private func pushDebugColor() {
        let lamp = deviceRepository.selectedDevice ?? deviceRepository.devices.first
        let color = lamp?.color ?? LuminaTheme.neonPurple
        let parts = color.components
        let level = UInt8(min(255, max(0, Int(((lamp?.brightness ?? 1) * 255).rounded()))))
        bluetooth.sendColor(.setColor(
            red: parts.red,
            green: parts.green,
            blue: parts.blue,
            brightness: level,
            power: lamp?.isOn ?? true,
            debugLed: debugLed
        ))
    }

    private func signOut() {
        session.signOut()
        dismiss()
    }
}

struct DeviceDetailView: View {
    let device: LampDevice
    let onForget: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var bluetooth = BluetoothManager.shared
    @State private var isConnecting = false
    @State private var statusMessage: String?
    @State private var showWifi = false

    private var isLive: Bool { bluetooth.isLive(id: device.id) }

    var body: some View {
        NavigationStack {
            ZStack {
                LuminaTheme.deepNavy.ignoresSafeArea()

                List {
                    Section {
                        HStack {
                            Text("Manufacturer")
                            Spacer()
                            Text(device.manufacturer)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        HStack {
                            Text("Model")
                            Spacer()
                            Text(device.model)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        HStack {
                            Text("Serial Number")
                            Spacer()
                            Text(device.serialNumber)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        HStack {
                            Text("Pairing Code")
                            Spacer()
                            Text(device.pairingCode)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        HStack {
                            Text("Bluetooth")
                            Spacer()
                            HStack(spacing: 6) {
                                if isLive {
                                    Circle()
                                        .fill(LuminaTheme.neonGreen)
                                        .frame(width: 8, height: 8)
                                }
                                Text(isLive ? "Connected" : "Not connected")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } header: {
                        Text("Device Info")
                    }
                    .listRowBackground(LuminaTheme.darkSurface)

                    Section {
                        Button {
                            Task { await connect() }
                        } label: {
                            HStack {
                                Spacer()
                                if isConnecting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isLive ? "Connected" : "Scan and connect")
                                }
                                Spacer()
                            }
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.pressable)
                        .disabled(isConnecting || isLive)
                        .foregroundColor(LuminaTheme.neonCyan)

                        if let statusMessage {
                            Text(statusMessage)
                                .font(LuminaTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.55))
                        }

                        Button {
                            showWifi = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Change Wi-Fi")
                                Spacer()
                            }
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.pressable)
                        .disabled(!isLive)
                        .foregroundColor(isLive ? LuminaTheme.neonPurple : .white.opacity(0.35))
                    } header: {
                        Text("Connection")
                    } footer: {
                        Text("Green means this phone is linked to the lamp over Bluetooth right now. Tap Scan and connect, then change the Wi-Fi name and password.")
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .listRowBackground(LuminaTheme.darkSurface)

                    Section {
                        Button(role: .destructive) {
                            onForget()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Forget Device")
                                Spacer()
                            }
                        }
                        .buttonStyle(.pressable)
                    }
                    .listRowBackground(LuminaTheme.darkSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(device.name)
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(LuminaTheme.neonPurple)
                }
            }
            .sheet(isPresented: $showWifi) {
                NavigationStack {
                    WifiSetupView(onFinished: { showWifi = false })
                }
            }
        }
    }

    private func connect() async {
        isConnecting = true
        statusMessage = nil
        await bluetooth.reconnect(to: device.id)
        isConnecting = false
        if bluetooth.isLive(id: device.id) {
            statusMessage = nil
            HapticManager.shared.success()
        } else {
            statusMessage = bluetooth.problemMessage ?? "The lamp is not nearby."
            HapticManager.shared.error()
        }
    }
}
