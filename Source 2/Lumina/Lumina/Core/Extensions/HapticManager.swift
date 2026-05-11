import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func heavyImpact() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
