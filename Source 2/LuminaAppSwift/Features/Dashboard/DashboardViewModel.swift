import Foundation
import SwiftUI
import Combine

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
    private let deviceRepository = DeviceRepository()

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

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

    private func setupBindings() {
        bluetoothManager.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        bluetoothManager.$connectedDevice
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] discovered in
                self?.handleDeviceConnected(discovered)
            }
            .store(in: &cancellables)
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

    func sendUpdate() {
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
        }
    }

    func applyFocusScene() {
        isOn = true
        brightness = 0.9
        selectedColor = LuminaTheme.neonCyan
        sendUpdate()
    }

    func applyRelaxScene() {
        isOn = true
        brightness = 0.4
        selectedColor = LuminaTheme.neonPurpleLight
        sendUpdate()
    }

    func applyPartyScene() {
        isOn = true
        brightness = 1.0
        selectedColor = LuminaTheme.neonPink
        sendUpdate()
    }

    func turnOff() {
        isOn = false
        brightness = 0
        sendUpdate()
    }
}
