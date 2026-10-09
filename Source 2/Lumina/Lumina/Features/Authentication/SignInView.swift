import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            LuminaTheme.deepNavy.ignoresSafeArea()

            VStack(spacing: LuminaTheme.Spacing.xl) {
                Spacer()

                logoSection
                    .scaleEffect(reduceMotion || hasAppeared ? 1 : 0.85)
                    .opacity(reduceMotion || hasAppeared ? 1 : 0)

                Spacer()

                signInOptionsSection
                    .opacity(reduceMotion || hasAppeared ? 1 : 0)
                    .offset(y: reduceMotion || hasAppeared ? 0 : 16)

                Spacer()

                skipSection
                    .opacity(reduceMotion || hasAppeared ? 1 : 0)
            }
            .padding(.horizontal, LuminaTheme.Spacing.xl)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                hasAppeared = true
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var logoSection: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            AnimatedGlowIcon(systemName: "lamp.desk.fill", color: LuminaTheme.neonPurple, size: 64)
                .frame(width: 120, height: 120)
                .glassCard(cornerRadius: LuminaTheme.CornerRadius.xxl)

            Text("Lumina")
                .font(LuminaTheme.Typography.display)
                .foregroundStyle(LuminaTheme.primaryGradient)

            Text("Smart Lamp Companion")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(LuminaTheme.textSecondary)
        }
    }

    private var signInOptionsSection: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var skipSection: some View {
        Button {
            completeSignIn()
        } label: {
            Text("Skip for now")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(LuminaTheme.textSecondary)
        }
        .padding(.bottom, LuminaTheme.Spacing.xl)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                print("Apple Sign In successful: \(userIdentifier)")
                saveUser(email: appleIDCredential.email, name: fullName?.givenName)
                completeSignIn()
            }
        case .failure(let error):
            showError(message: error.localizedDescription)
        }
    }

    private func completeSignIn() {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        isAuthenticated = true
        HapticManager.shared.success()
    }

    private func saveUser(email: String?, name: String?) {
        let displayName = [name, email].compactMap { $0 }.joined(separator: " ")
        UserDefaults.standard.set(displayName, forKey: "userDisplayName")
        UserDefaults.standard.set(email, forKey: "userEmail")
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
        HapticManager.shared.error()
    }
}
