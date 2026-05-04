import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct SignInView: View {
    @Binding var isAuthenticated: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            LuminaTheme.deepNavy.ignoresSafeArea()

            VStack(spacing: LuminaTheme.Spacing.xl) {
                Spacer()

                logoSection

                Spacer()

                signInOptionsSection

                Spacer()

                skipSection
            }
            .padding(.horizontal, LuminaTheme.Spacing.xl)
        }
        .preferredColorScheme(.dark)
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var logoSection: some View {
        VStack(spacing: LuminaTheme.Spacing.md) {
            AnimatedGlowIcon(systemName: "lamp.desk.fill", color: LuminaTheme.neonPurple, size: 64, glowRadius: 16)
                .frame(width: 120, height: 120)
                .glassCard(cornerRadius: LuminaTheme.CornerRadius.xxl)

            Text("Lumina")
                .font(LuminaTheme.Typography.display)
                .foregroundStyle(LuminaTheme.primaryGradient)

            Text("Smart Lamp Companion")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.5))
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

            Button {
                signInWithGoogle()
            } label: {
                HStack(spacing: LuminaTheme.Spacing.sm) {
                    GoogleLogo()
                    Text("Sign in with Google")
                        .font(LuminaTheme.Typography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, LuminaTheme.Spacing.sm)
            }
        }
    }

    private var skipSection: some View {
        Button {
            completeSignIn()
        } label: {
            Text("Skip for now")
                .font(LuminaTheme.Typography.subheadline)
                .foregroundColor(.white.opacity(0.4))
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

    private func signInWithGoogle() {
        isLoading = true
        // Google Sign-In requires additional setup with GoogleService-Info.plist
        // For now, complete auth to allow app usage
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            completeSignIn()
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

struct GoogleLogo: View {
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color(hex: "4285F4")).frame(width: 22, height: 22)
                Circle().fill(Color(hex: "EA4335")).frame(width: 22, height: 22).offset(x: -6)
                Circle().fill(Color(hex: "FBBC05")).frame(width: 22, height: 22).offset(x: 6)
                Circle().fill(Color(hex: "34A853")).frame(width: 22, height: 22)
            }
            .frame(width: 22, height: 22)
        }
    }
}
