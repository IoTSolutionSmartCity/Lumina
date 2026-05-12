import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var originalDisplayName: String = ""
    @State private var originalEmail: String = ""
    @State private var showingSaveConfirmation = false
    @State private var validationMessage: String?

    var body: some View {
        ZStack {
            LuminaTheme.deepNavy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LuminaTheme.Spacing.lg) {
                    profileHeader
                    profileFields
                    accountStatusCard
                    actionButtons
                }
                .padding(LuminaTheme.Spacing.lg)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
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

    private var profileHeader: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(LuminaTheme.primaryGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: LuminaTheme.neonPurple.opacity(0.45), radius: 20)

                Text(userInitials)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            .overlay(Circle().stroke(LuminaTheme.glassBorder, lineWidth: 2))

            VStack(spacing: 4) {
                Text(displayName.isEmpty ? "Lumina User" : displayName)
                    .font(LuminaTheme.Typography.title)
                    .foregroundColor(.white)

                Text(email.isEmpty ? "Anonymous account" : email)
                    .font(LuminaTheme.Typography.subheadline)
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LuminaTheme.Spacing.xl)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.xxl)
    }

    private var profileFields: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.md) {
            fieldLabel("Display Name")
            TextField("Lumina User", text: $displayName)
                .textInputAutocapitalization(.words)
                .profileTextFieldStyle()

            fieldLabel("Email")
            TextField("your@email.com", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .profileTextFieldStyle()

            if let validationMessage {
                Text(validationMessage)
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(LuminaTheme.neonRed)
            }
        }
        .padding(LuminaTheme.Spacing.lg)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.xl)
    }

    private var accountStatusCard: some View {
        HStack(spacing: LuminaTheme.Spacing.md) {
            GlowIcon(systemName: email.isEmpty ? "person.crop.circle.badge.questionmark" : "checkmark.seal.fill", color: email.isEmpty ? LuminaTheme.neonOrange : LuminaTheme.neonGreen, size: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(email.isEmpty ? "Using anonymous mode" : "Profile ready")
                    .font(LuminaTheme.Typography.headline)
                    .foregroundColor(.white)
                Text(email.isEmpty ? "You can still control your lamp. Add an email later if you want account sync." : "Your saved profile will appear in Settings.")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()
        }
        .padding(LuminaTheme.Spacing.lg)
        .glassCard(cornerRadius: LuminaTheme.CornerRadius.xl)
    }

    private var actionButtons: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            NeonButton("Save Changes", icon: "checkmark.circle.fill") {
                saveProfile()
            }
            .opacity(hasChanges ? 1 : 0.55)
            .disabled(!hasChanges)

            GlassButton("Discard Changes", icon: "arrow.uturn.backward") {
                loadProfile()
                dismiss()
            }
            .opacity(hasChanges ? 1 : 0.45)
            .disabled(!hasChanges)
        }
    }

    private var userInitials: String {
        let name = displayName.isEmpty ? "Lumina User" : displayName
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }

    private var hasChanges: Bool {
        displayName != originalDisplayName || email != originalEmail
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(LuminaTheme.Typography.captionBold)
            .foregroundColor(.white.opacity(0.65))
    }

    private func loadProfile() {
        displayName = UserDefaults.standard.string(forKey: "userDisplayName") ?? ""
        email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        originalDisplayName = displayName
        originalEmail = email
        validationMessage = nil
    }

    private func saveProfile() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedEmail.isEmpty && !trimmedEmail.contains("@") {
            validationMessage = "Enter a valid email address or leave it blank for anonymous mode."
            HapticManager.shared.error()
            return
        }

        UserDefaults.standard.set(trimmedName, forKey: "userDisplayName")
        UserDefaults.standard.set(trimmedEmail, forKey: "userEmail")
        displayName = trimmedName
        email = trimmedEmail
        originalDisplayName = trimmedName
        originalEmail = trimmedEmail
        validationMessage = nil
        showingSaveConfirmation = true
        HapticManager.shared.success()
    }
}

private extension View {
    func profileTextFieldStyle() -> some View {
        self
            .foregroundColor(.white)
            .tint(LuminaTheme.neonPurple)
            .padding(LuminaTheme.Spacing.md)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.md)
                    .stroke(LuminaTheme.glassBorder, lineWidth: 1)
            )
    }
}
