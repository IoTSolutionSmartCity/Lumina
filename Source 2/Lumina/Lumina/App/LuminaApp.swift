import SwiftUI

@main
struct LuminaApp: App {
    @State private var session = AppSession()
    @State private var island = IslandCenter.shared

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
            .overlay(alignment: .top) {
                LuminaIsland()
                    .zIndex(1)
            }
            .statusBarHidden(island.notice != nil)
            .environment(session)
        }
    }
}

struct MainTabView: View {
    @State private var tab = 0
    @State private var island = IslandCenter.shared

    var body: some View {
        TabView(selection: $tab) {
            MainDashboardView()
                .tabItem {
                    Label("Lamp", systemImage: "lamp.desk.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(LuminaTheme.neonPurple)
        .onChange(of: island.routeToken) { _, token in
            guard token > 0 else { return }
            switch island.route {
            case .device, .discover:
                tab = 1
            case nil:
                break
            }
        }
    }
}
