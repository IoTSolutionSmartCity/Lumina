import SwiftUI

struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @State private var deviceRepository = DeviceRepository.shared
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
                        ZStack {
                            Circle()
                                .fill(device.isConnected ? LuminaTheme.neonGreen.opacity(0.2) : LuminaTheme.neonRed.opacity(0.2))
                                .frame(width: 40, height: 40)

                            GlowIcon(
                                systemName: "lamp.desk.fill",
                                color: device.isConnected ? LuminaTheme.neonGreen : LuminaTheme.neonRed,
                                size: 18
                            )
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(LuminaTheme.Typography.headline)
                                .foregroundColor(.white)

                            Text(device.serialNumber)
                                .font(LuminaTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Circle()
                            .fill(device.isConnected ? LuminaTheme.neonGreen : LuminaTheme.neonRed)
                            .frame(width: 8, height: 8)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
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
            .listRowBackground(LuminaTheme.darkSurface)
        } header: {
            Text("Account")
                .foregroundColor(.white.opacity(0.5))
        }
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

    private func signOut() {
        session.signOut()
        dismiss()
    }
}

struct DeviceDetailView: View {
    let device: LampDevice
    let onForget: () -> Void
    @Environment(\.dismiss) private var dismiss

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
                            Text("Status")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(device.isConnected ? LuminaTheme.neonGreen : LuminaTheme.neonRed)
                                    .frame(width: 8, height: 8)
                                Text(device.isConnected ? "Connected" : "Disconnected")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } header: {
                        Text("Device Info")
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
        }
    }
}
