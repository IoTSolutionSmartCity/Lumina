import SwiftUI

@MainActor
@Observable
final class IslandCenter {
    static let shared = IslandCenter()

    var notice: IslandNotice?
    var pulseColor = Color.white
    var pulseToken = 0

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
            guard hadLink else { return }
            hadLink = false
            show(.disconnected, sticky: false, seconds: 3.2)
        }
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
}

enum IslandNotice: Equatable {
    case searching
    case connecting
    case connected
    case disconnected

    var title: String { headline }

    var headline: String {
        switch self {
        case .searching: return "Searching"
        case .connecting: return "Connecting"
        case .connected: return "Lamp connected"
        case .disconnected: return "Lamp disconnected"
        }
    }

    var isProminent: Bool {
        self == .connected || self == .disconnected
    }

    var width: CGFloat {
        switch self {
        case .searching, .connecting: return 196
        case .connected: return 280
        case .disconnected: return 330
        }
    }

    var height: CGFloat {
        switch self {
        case .searching, .connecting: return 37
        case .connected: return 88
        case .disconnected: return 112
        }
    }

    var fill: Color {
        switch self {
        case .disconnected: return Color(red: 0.45, green: 0.05, blue: 0.08)
        case .connected: return Color(red: 0.02, green: 0.22, blue: 0.12)
        default: return .black
        }
    }

    var symbol: String {
        switch self {
        case .searching: return "dot.radiowaves.left.and.right"
        case .connecting: return "lamp.desk"
        case .connected: return "lamp.desk.fill"
        case .disconnected: return "lamp.desk.slash"
        }
    }

    var tint: Color {
        switch self {
        case .searching, .connecting: return LuminaTheme.neonOrange
        case .connected: return LuminaTheme.neonGreen
        case .disconnected: return LuminaTheme.neonRed
        }
    }
}

struct LuminaIsland: View {
    @State private var center = IslandCenter.shared
    @State private var bluetooth = BluetoothManager.shared
    @State private var ringOpacity: Double = 0
    @State private var ringHold = 0

    var body: some View {
        let link = bluetooth.connectionState

        ZStack(alignment: .top) {
            if let notice = center.notice {
                noticeLabel(notice)
                    .frame(width: notice.width, height: notice.height)
                    .transition(.opacity)
            }

            Capsule()
                .stroke(center.pulseColor, lineWidth: 4)
                .frame(width: 126, height: 37)
                .opacity(ringOpacity)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 11)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: center.notice)
        .onAppear {
            center.note(link)
        }
        .onChange(of: link) { _, state in
            center.note(state)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(center.notice?.title ?? "Lamp status")
    }

    private func noticeLabel(_ notice: IslandNotice) -> some View {
        HStack(spacing: 10) {
            Image(systemName: notice.symbol)
                .font(.system(size: notice.isProminent ? 26 : 15, weight: .semibold))
                .foregroundStyle(notice.tint)
            Text(notice.headline)
                .font(.system(size: notice.isProminent ? 20 : 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, notice.isProminent ? 16 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: notice.isProminent ? .bottom : .center)
        .background(notice.fill, in: Capsule())
        .overlay {
            Capsule().stroke(notice.tint, lineWidth: notice.isProminent ? 3 : 0)
        }
        .shadow(color: notice.tint.opacity(notice.isProminent ? 0.55 : 0), radius: 16, y: 6)
    }
}
