import SwiftUI

struct ProfileView: View {
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        ZStack {
            LuminaTheme.deepNavy.ignoresSafeArea()

            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: LuminaTheme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(LuminaTheme.primaryGradient)
                                    .frame(width: 80, height: 80)

                                Text(userInitials)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Circle()
                                    .stroke(LuminaTheme.glassBorder, lineWidth: 2)
                            )

                            Text(displayName.isEmpty ? "Lumina User" : displayName)
                                .font(LuminaTheme.Typography.title2)
                                .foregroundColor(.white)

                            Text(email.isEmpty ? "No email" : email)
                                .font(LuminaTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.vertical, LuminaTheme.Spacing.lg)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    HStack {
                        Text("Display Name")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("Your name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                            .tint(LuminaTheme.neonPurple)
                    }
                    .listRowBackground(LuminaTheme.darkSurface)

                    HStack {
                        Text("Email")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("your@email.com", text: $email)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                            .tint(LuminaTheme.neonPurple)
                            .keyboardType(.emailAddress)
                    }
                    .listRowBackground(LuminaTheme.darkSurface)
                } header: {
                    Text("Profile Information")
                        .foregroundColor(.white.opacity(0.5))
                }

                Section {
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .font(LuminaTheme.Typography.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(LuminaTheme.neonPurple)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            loadProfile()
        }
        .alert("Profile Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your profile has been updated successfully.")
        }
    }

    private var userInitials: String {
        let name = displayName.isEmpty ? "Lumina User" : displayName
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }

    private func loadProfile() {
        displayName = UserDefaults.standard.string(forKey: "userDisplayName") ?? ""
        email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    }

    private func saveProfile() {
        UserDefaults.standard.set(displayName, forKey: "userDisplayName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        showingSaveConfirmation = true
        HapticManager.shared.success()
    }
}
