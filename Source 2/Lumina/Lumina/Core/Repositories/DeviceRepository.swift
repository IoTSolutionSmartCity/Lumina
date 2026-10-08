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
        guard let saved = UserDefaults.standard.data(forKey: userDefaultsKey),
              let ids = try? JSONDecoder().decode([String].self, from: saved) else { return }
        devices = ids.compactMap { raw in
            guard let id = UUID(uuidString: raw) else { return nil }
            return LampDevice(
                id: id,
                name: BluetoothManager.targetDeviceName,
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
        selectedDevice = devices.first
    }
}
