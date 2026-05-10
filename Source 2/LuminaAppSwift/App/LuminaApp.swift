import SwiftUI

@main
struct LuminaApp: App {
    @State private var isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
    @State private var isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")

    var body: some Scene {
        WindowGroup {
            Group {
                if !isOnboarded {
                    OnboardingView(isOnboarded: $isOnboarded)
                } else if !isAuthenticated {
                    SignInView(isAuthenticated: $isAuthenticated)
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            MainDashboardView()
                .tabItem {
                    Label("Lamp", systemImage: "lamp.desk.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(LuminaTheme.neonPurple)
    }
}
