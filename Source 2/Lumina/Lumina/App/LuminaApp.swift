import SwiftUI

@main
struct LuminaApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if !session.isOnboarded {
                    OnboardingView(isOnboarded: Binding(
                        get: { session.isOnboarded },
                        set: { session.isOnboarded = $0 }
                    ))
                } else if !session.isAuthenticated {
                    SignInView(isAuthenticated: Binding(
                        get: { session.isAuthenticated },
                        set: { session.isAuthenticated = $0 }
                    ))
                } else {
                    MainTabView()
                }
            }
            .preferredColorScheme(.dark)
            .environment(session)
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
