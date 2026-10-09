import SwiftUI

@MainActor
@Observable
final class IslandCenter {
    static let shared = IslandCenter()

    var notice: IslandNotice?
    var pulseColor = Color.white
    var pulseToken = 0
    var route: IslandRoute?
    var routeToken = 0

    private var dismissTask: Task<Void, Never>?
    private var hadLink = false

    func note(_ state: ConnectionState) {
        switch state {
        case .scanning:
            show(.searching, sticky: true)
        case .connecting:
            show(.connecting, sticky: true)
        case .connected:
            hadLink = true
            show(.connected, sticky: false)
        case .disconnected, .error:
            guard hadLink else {
                clearTransient()
                return
            }
            hadLink = false
            show(.disconnected, sticky: false, seconds: 3.2)
        }
    }

    func noteDiscovered(_ count: Int) {
        guard count > 0 else { return }
        switch notice {
        case .connecting, .connected, .disconnected:
            return
        default:
            show(.discovered(count), sticky: true)
        }
    }

    func open() {
        guard let notice else { return }
        switch notice {
        case .discovered, .searching:
            route = .discover
        case .connecting, .connected, .disconnected:
            route = .device
        }
        routeToken += 1
    }

    func pulse(_ color: Color) {
        pulseColor = color
        pulseToken += 1
    }

    private func show(_ notice: IslandNotice, sticky: Bool, seconds: Double = 2.6) {
        dismissTask?.cancel()
        self.notice = notice
        guard !sticky else { return }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self.notice = nil
        }
    }

    private func clearTransient() {
        switch notice {
        case .searching, .connecting, .discovered:
            dismissTask?.cancel()
            notice = nil
        default:
            break
        }
    }
}

enum IslandRoute: Equatable {
    case device
    case discover
}

enum IslandNotice: Equatable {
    case searching
    case connecting
    case connected
    case disconnected
    case discovered(Int)

    var title: String { headline }

    var headline: String {
        switch self {
        case .searching: return "搜尋中"
        case .connecting: return "連線中"
        case .connected: return "已連結"
        case .disconnected: return "已中斷"
        case .discovered: return "發現新設備"
        }
    }

    var symbol: String {
        switch self {
        case .searching: return "dot.radiowaves.left.and.right"
        case .connecting: return "lamp.desk"
        case .connected: return "lamp.desk.fill"
        case .disconnected: return "lamp.desk.slash"
        case .discovered: return "lamp.desk.fill"
        }
    }

    var badge: String {
        switch self {
        case .searching: return "magnifyingglass"
        case .connecting: return "link"
        case .connected: return "checkmark"
        case .disconnected: return "xmark"
        case .discovered: return "plus"
        }
    }

    var tint: Color {
        switch self {
        case .searching, .connecting: return LuminaTheme.neonOrange
        case .connected: return LuminaTheme.neonGreen
        case .disconnected: return LuminaTheme.neonRed
        case .discovered: return LuminaTheme.neonCyan
        }
    }
}

struct LuminaIsland: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppSession.self) private var session
    @State private var center = IslandCenter.shared
    @State private var bluetooth = BluetoothManager.shared
    @State private var ringOpacity: Double = 0
    @State private var ringHold = 0

    var body: some View {
        let link = bluetooth.connectionState
        let found = bluetooth.discoveredDevices.count

        ZStack(alignment: .top) {
            if let notice = center.notice {
                Button {
                    guard session.isOnboarded, session.isAuthenticated else { return }
                    HapticManager.shared.lightImpact()
                    center.open()
                } label: {
                    capsule(notice)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.5, anchor: .center).combined(with: .opacity))
            }

            Capsule()
                .stroke(center.pulseColor, lineWidth: 4)
                .frame(width: 126, height: 37)
                .opacity(ringOpacity)
                .allowsHitTesting(false)
        }
        .padding(.top, 11)
        .frame(maxWidth: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .animation(capsuleAnimation, value: center.notice)
        .onAppear {
            center.note(link)
            if found > 0 { center.noteDiscovered(found) }
        }
        .onChange(of: link) { _, state in
            center.note(state)
            if found > 0 { center.noteDiscovered(found) }
        }
        .onChange(of: found) { _, count in
            center.noteDiscovered(count)
        }
        .onChange(of: center.pulseToken) { _, token in
            guard token > 0 else { return }
            ringHold += 1
            let hold = ringHold
            ringOpacity = 1
            Task {
                try? await Task.sleep(for: .milliseconds(1100))
                guard hold == ringHold else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    ringOpacity = 0
                }
            }
        }
    }

    private var capsuleAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.42, bounce: 0.18)
    }

    private func capsule(_ notice: IslandNotice) -> some View {
        HStack(spacing: 0) {
            Image(systemName: notice.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(notice.tint)
                .frame(width: 44, height: 37)

            Color.clear
                .frame(width: 118, height: 37)

            Image(systemName: notice.badge)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(notice.tint)
                .frame(width: 44, height: 37)
        }
        .frame(height: 37)
        .fixedSize(horizontal: true, vertical: false)
        .background(.black, in: Capsule())
        .contentShape(Capsule())
        .accessibilityLabel(notice.headline)
        .accessibilityHint("Opens the lamp screen")
    }
}
