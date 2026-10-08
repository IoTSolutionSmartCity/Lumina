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
    var showWifiSetup: Bool = false

    private let bluetooth = BluetoothManager.shared
    private let homeKitManager = HomeKitManager()
    private let deviceRepository = DeviceRepository.shared
    private var pendingUpdateTask: Task<Void, Never>?

    func onAppear() {
        if deviceRepository.devices.isEmpty {
            showOnboarding = true
        } else if let first = deviceRepository.devices.first {
            connectedDevice = first
            connectionState = .disconnected
            brightness = first.brightness
            selectedColor = first.color
            isOn = first.isOn
        }
        if !showOnboarding {
            Task { await reconnect() }
        }
    }

    private func reconnect() async {
        await bluetooth.scanAndConnect()
        connectionState = bluetooth.connectionState
        if let discovered = bluetooth.connectedDevice {
            remember(discovered)
        }
        if !WifiPasswordStore.hasChosen {
            showWifiSetup = true
        }
    }

    private func remember(_ discovered: DiscoveredPeripheral) {
        let device = LampDevice(
            id: discovered.id,
            name: discovered.name,
            serialNumber: "LUMINA-S3-001",
            manufacturer: "Lumina",
            model: "ESP32S3-N16R8",
            pairingCode: "46637726",
            isConnected: true,
            brightness: brightness,
            color: selectedColor,
            isOn: isOn
        )
        connectedDevice = device
        if deviceRepository.devices.contains(where: { $0.id == device.id }) {
            deviceRepository.updateDevice(device)
        } else {
            deviceRepository.addDevice(device)
        }
        deviceRepository.selectDevice(device)
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
        if var updated = connectedDevice {
            updated.brightness = brightness
            updated.color = selectedColor
            updated.isOn = isOn
            deviceRepository.updateDevice(updated)
            connectedDevice = updated
        }

        let components = selectedColor.components
        let level = UInt8(min(255, max(0, Int((brightness * 255).rounded()))))
        bluetooth.sendColor(.setColor(
            red: components.red,
            green: components.green,
            blue: components.blue,
            brightness: level,
            power: isOn
        ))
        connectionState = bluetooth.connectionState
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
