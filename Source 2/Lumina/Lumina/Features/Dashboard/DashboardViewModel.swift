import Foundation
import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
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
    private var colorPulseTask: Task<Void, Never>?
    private var didPromptWifi = false
    private var skipLiveColor = false
    var isBreathing = false

    var connectionState: ConnectionState { bluetooth.connectionState }

    func onAppear() {
        if deviceRepository.devices.isEmpty {
            showOnboarding = true
        } else if let first = deviceRepository.devices.first {
            connectedDevice = first
            brightness = first.brightness
            selectedColor = first.color
            isOn = first.isOn
        }
    }

    /// Looks for the saved lamp. Later passes stay quiet so a miss does not
    /// replace the screen with an error every 10 seconds.
    func refreshLink(reportFailure: Bool) async {
        guard !showOnboarding else { return }
        guard let id = deviceRepository.selectedDevice?.id ?? deviceRepository.devices.first?.id else { return }
        await bluetooth.reconnect(to: id, timeout: 10, reportFailure: reportFailure)
        if bluetooth.connectionState == .connected, let discovered = bluetooth.connectedDevice {
            remember(discovered)
        }
        if bluetooth.connectionState == .connected, !didPromptWifi, !WifiPasswordStore.hasChosen {
            didPromptWifi = true
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
            isConnected: false,
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

    func scheduleColorPulse() {
        colorPulseTask?.cancel()
        colorPulseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(280))
            guard let self, !Task.isCancelled else { return }
            IslandCenter.shared.pulse(selectedColor)
        }
    }

    func sendUpdate(debounced: Bool = true) {
        if skipLiveColor {
            skipLiveColor = false
            return
        }
        pendingUpdateTask?.cancel()
        if !isOn {
            isBreathing = false
        }
        if isBreathing && isOn {
            publishMode(id: 4, color: selectedColor, breath: true)
            return
        }

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
            power: isOn,
            debugLed: UserDefaults.standard.bool(forKey: "luminaDebugLed")
        ))
    }

    func runSavedMode(id: UInt8, color: Color, breath: Bool) {
        pendingUpdateTask?.cancel()
        if color.hexString != selectedColor.hexString {
            skipLiveColor = true
        }
        selectedColor = color
        isBreathing = breath && isOn
        publishMode(id: id, color: color, breath: breath && isOn)
    }

    private func publishMode(id: UInt8, color: Color, breath: Bool) {
        let components = color.components
        let level = UInt8(min(255, max(0, Int((brightness * 255).rounded()))))
        bluetooth.sendColor(.runMode(
            id: id,
            red: components.red,
            green: components.green,
            blue: components.blue,
            brightness: level,
            breath: breath
        ))
    }

    func applyFocusScene() {
        isBreathing = false
        isOn = true
        brightness = 0.9
        selectedColor = LuminaTheme.neonCyan
        sendUpdate(debounced: false)
    }

    func applyRelaxScene() {
        isBreathing = false
        isOn = true
        brightness = 0.4
        selectedColor = LuminaTheme.neonPurpleLight
        sendUpdate(debounced: false)
    }

    func applyPartyScene() {
        isBreathing = false
        isOn = true
        brightness = 1.0
        selectedColor = LuminaTheme.neonPink
        sendUpdate(debounced: false)
    }

    func turnOff() {
        isOn = false
        isBreathing = false
        brightness = 0
        sendUpdate(debounced: false)
    }
}
