import Foundation
import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    var showWifiSetup = false
    var isConnecting = false

    private let bluetooth = BluetoothManager.shared

    var discoveredDevices: [DiscoveredPeripheral] { bluetooth.discoveredDevices }
    var connectionState: ConnectionState { bluetooth.connectionState }
    var problemMessage: String? { bluetooth.problemMessage }
    var isScanning: Bool { bluetooth.isScanning }

    var heroDevice: DiscoveredPeripheral? {
        bluetooth.discoveredDevices.max { $0.rssi < $1.rssi }
    }

    func beginDiscovery() {
        bluetooth.startScanning()
    }

    func stopScanning() {
        bluetooth.stopScanning()
    }

    func connectToHero() {
        guard let hero = heroDevice, !isConnecting else { return }
        isConnecting = true
        Task {
            await bluetooth.connect(to: hero)
            isConnecting = false
            if bluetooth.connectionState == .connected {
                remember(hero)
                showWifiSetup = true
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        }
    }

    private func remember(_ device: DiscoveredPeripheral) {
        let lamp = LampDevice(
            id: device.id,
            name: device.name,
            serialNumber: "LUMINA-S3-001",
            manufacturer: "Lumina",
            model: "ESP32S3-N16R8",
            pairingCode: "46637726",
            isConnected: true,
            brightness: 0.75,
            color: LuminaTheme.neonPurple,
            isOn: true
        )
        DeviceRepository.shared.addDevice(lamp)
        DeviceRepository.shared.selectDevice(lamp)
    }
}
