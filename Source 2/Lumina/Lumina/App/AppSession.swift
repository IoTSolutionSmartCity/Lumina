import Foundation

@MainActor
@Observable
final class AppSession {
    var isOnboarded: Bool {
        didSet { UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded") }
    }

    var isAuthenticated: Bool {
        didSet { UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated") }
    }

    init() {
        isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }

    func completeOnboarding() {
        isOnboarded = true
    }

    func completeSignIn() {
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
    }

    func restartOnboarding() {
        isOnboarded = false
    }
}
