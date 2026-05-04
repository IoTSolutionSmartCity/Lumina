import Foundation
import SwiftUI

struct LampDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let serialNumber: String
    let manufacturer: String
    let model: String
    let pairingCode: String
    var isConnected: Bool
    var brightness: Double
    var color: Color
    var isOn: Bool

    static let sample = LampDevice(
        id: UUID(),
        name: "Lumina ESP32S3 Lamp",
        serialNumber: "LUMINA-S3-001",
        manufacturer: "Lumina",
        model: "ESP32S3-N16R8",
        pairingCode: "46637726",
        isConnected: false,
        brightness: 0.75,
        color: LuminaTheme.neonPurple,
        isOn: false
    )
}
