import Foundation

@MainActor
@Observable
final class DeviceRepository {
    static let shared = DeviceRepository()

    var devices: [LampDevice] = []
    var selectedDevice: LampDevice?

    private let userDefaultsKey = "savedLampDevices"

    private init() {
        loadDevices()
    }

    func addDevice(_ device: LampDevice) {
        if !devices.contains(where: { $0.id == device.id }) {
            devices.append(device)
            saveDevices()
        }
    }

    func updateDevice(_ device: LampDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
            if selectedDevice?.id == device.id {
                selectedDevice = device
            }
            saveDevices()
        }
    }

    func removeDevice(_ device: LampDevice) {
        devices.removeAll { $0.id == device.id }
        if selectedDevice?.id == device.id {
            selectedDevice = devices.first
        }
        saveDevices()
    }

    func selectDevice(_ device: LampDevice) {
        selectedDevice = device
    }

    private func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices.map { $0.id.uuidString }) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadDevices() {
        if let saved = UserDefaults.standard.data(forKey: userDefaultsKey),
           (try? JSONDecoder().decode([String].self, from: saved)) != nil {
            // IDs restored; actual device data comes from Bluetooth/HomeKit
        }
    }
}
