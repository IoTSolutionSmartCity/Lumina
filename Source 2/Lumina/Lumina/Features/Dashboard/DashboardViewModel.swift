import Foundation
import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
    var connectionState: ConnectionState = .disconnected
    var connectedDevice: LampDevice?
    var brightness: Double = 0.75
    var selectedColor: Color = LuminaTheme.neonPurple
    var isOn: Bool = true
    var showOnboarding: Bool = false

    private let bluetoothManager = BluetoothManager()
    private let homeKitManager = HomeKitManager()
    private let deviceRepository = DeviceRepository.shared
    private var pendingUpdateTask: Task<Void, Never>?

    func onAppear() {
        if deviceRepository.devices.isEmpty {
            showOnboarding = true
        } else if let first = deviceRepository.devices.first {
            connectedDevice = first
            connectionState = first.isConnected ? .connected : .disconnected
            brightness = first.brightness
            selectedColor = first.color
            isOn = first.isOn
        }
    }

    private func handleDeviceConnected(_ discovered: DiscoveredPeripheral) {
        let device = LampDevice(
            id: discovered.id,
            name: discovered.name,
            serialNumber: "LUMINA-S3-\(discovered.id.uuidString.prefix(4).uppercased())",
            manufacturer: "Lumina",
            model: "ESP32S3-N16R8",
            pairingCode: "46637726",
            isConnected: true,
            brightness: brightness,
            color: selectedColor,
            isOn: isOn
        )
        connectedDevice = device
        deviceRepository.addDevice(device)
        HapticManager.shared.success()
    }

    func sendUpdate(debounced: Bool = true) {
        pendingUpdateTask?.cancel()

        guard debounced else {
            performSendUpdate()
            return
        }

        pendingUpdateTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.performSendUpdate()
        }
    }

    private func performSendUpdate() {
        guard let device = connectedDevice else { return }
        var updated = device
        updated.brightness = brightness
        updated.color = selectedColor
        updated.isOn = isOn
        deviceRepository.updateDevice(updated)
        connectedDevice = updated

        let components = selectedColor.components
        Task {
            await bluetoothManager.sendCommand(.setPower(isOn))
            await bluetoothManager.sendCommand(.setBrightness(brightness))
            await bluetoothManager.sendCommand(.setColor(red: components.red, green: components.green, blue: components.blue))
            connectionState = bluetoothManager.connectionState
            if let discovered = bluetoothManager.connectedDevice {
                handleDeviceConnected(discovered)
            }
        }
    }

    func applyFocusScene() {
        isOn = true
        brightness = 0.9
        selectedColor = LuminaTheme.neonCyan
        sendUpdate(debounced: false)
    }

    func applyRelaxScene() {
        isOn = true
        brightness = 0.4
        selectedColor = LuminaTheme.neonPurpleLight
        sendUpdate(debounced: false)
    }

    func applyPartyScene() {
        isOn = true
        brightness = 1.0
        selectedColor = LuminaTheme.neonPink
        sendUpdate(debounced: false)
    }

    func turnOff() {
        isOn = false
        brightness = 0
        sendUpdate(debounced: false)
    }
}
