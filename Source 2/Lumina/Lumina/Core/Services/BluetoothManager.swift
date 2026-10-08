import Foundation
import CoreBluetooth

enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return msg
        }
    }
}

enum LampCommand: Equatable {
    case setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8, power: Bool)
    case setWifi(ssid: String, password: String)

    static let colorOpcode: UInt8 = 0x02
    static let wifiOpcode: UInt8 = 0x10

    var data: Data? {
        switch self {
        case .setColor(let red, let green, let blue, let brightness, let power):
            return Data([Self.colorOpcode, red, green, blue, brightness, power ? 1 : 0])
        case .setWifi(let ssid, let password):
            let ssidBytes = Data(ssid.utf8)
            let passwordBytes = Data(password.utf8)
            guard (1...32).contains(ssidBytes.count), passwordBytes.count <= 64 else { return nil }
            var data = Data([Self.wifiOpcode, UInt8(ssidBytes.count)])
            data.append(ssidBytes)
            data.append(UInt8(passwordBytes.count))
            data.append(passwordBytes)
            return data
        }
    }
}

enum LampLinkError: LocalizedError {
    case invalidCommand
    case notConnected
    case notReady
    case timedOut
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCommand: return "Check the Wi-Fi name and password length."
        case .notConnected: return "The lamp is not connected."
        case .notReady: return "The lamp is not ready for commands yet."
        case .timedOut: return "The lamp did not confirm. Try again."
        case .failed(let message): return message
        }
    }
}

struct DiscoveredPeripheral: Identifiable, Equatable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    var isConnectable: Bool

    init(peripheral: CBPeripheral, name: String, rssi: Int, isConnectable: Bool = true) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = name
        self.rssi = rssi
        self.isConnectable = isConnectable
    }

    static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
@Observable
final class BluetoothManager: NSObject {
    static let shared = BluetoothManager()

    static let serviceUUID = CBUUID(string: "4C554D49-4E41-4000-8000-000000000001")
    static let commandUUID = CBUUID(string: "4C554D49-4E41-4000-8000-000000000002")
    static let targetDeviceName = "Lumina ESP32S3 Lamp"
    static let homeKitSetupCode = "466-37-726"

    var discoveredDevices: [DiscoveredPeripheral] = []
    var connectionState: ConnectionState = .disconnected
    var isScanning: Bool = false
    var connectedDevice: DiscoveredPeripheral?
    var problemMessage: String?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var outgoing: [Outgoing] = []
    private var activeWrite: Outgoing?
    private var activeToken: UUID?
    private var isSending = false
    private var wantsScan = false

    private final class Outgoing {
        let data: Data
        let continuation: CheckedContinuation<Void, Error>?
        var resumed = false

        init(data: Data, continuation: CheckedContinuation<Void, Error>?) {
            self.data = data
            self.continuation = continuation
        }

        func finish(_ result: Result<Void, Error>) {
            guard !resumed else { return }
            resumed = true
            switch result {
            case .success:
                continuation?.resume()
            case .failure(let error):
                continuation?.resume(throwing: error)
            }
        }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: nil, queue: .main)
        centralManager.delegate = self
    }

    var isBluetoothOn: Bool { centralManager.state == .poweredOn }

    func startScanning() {
        wantsScan = true
        guard centralManager.state == .poweredOn else {
            if centralManager.state == .poweredOff {
                connectionState = .error("Bluetooth is off")
                problemMessage = "Turn on Bluetooth to find the lamp."
            }
            return
        }
        guard !isScanning else { return }
        discoveredDevices.removeAll()
        isScanning = true
        if connectionState != .connected && connectionState != .connecting {
            connectionState = .scanning
        }
        centralManager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        wantsScan = false
        centralManager.stopScan()
        isScanning = false
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    func connect(to device: DiscoveredPeripheral) async {
        wantsScan = false
        centralManager.stopScan()
        isScanning = false
        connectionState = .connecting
        connectedDevice = device
        centralManager.connect(device.peripheral, options: nil)

        let deadline = Date().addingTimeInterval(10)
        while connectionState == .connecting && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
        if connectionState == .connecting {
            centralManager.cancelPeripheralConnection(device.peripheral)
            connectionState = .error("Connection timed out")
        }
    }

    func scanAndConnect(timeout: TimeInterval = 8) async {
        if connectionState == .connected { return }
        startScanning()
        let deadline = Date().addingTimeInterval(timeout)
        while discoveredDevices.isEmpty && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(200))
        }
        guard let device = discoveredDevices.max(by: { $0.rssi < $1.rssi }) else {
            stopScanning()
            return
        }
        await connect(to: device)
    }

    func sendColor(_ command: LampCommand) {
        guard let data = command.data else { return }
        outgoing.removeAll { $0.continuation == nil && $0.data.first == LampCommand.colorOpcode }
        outgoing.append(Outgoing(data: data, continuation: nil))
        pump()
    }

    func sendWifi(ssid: String, password: String) async throws {
        guard let data = LampCommand.setWifi(ssid: ssid, password: password).data else {
            throw LampLinkError.invalidCommand
        }
        guard connectionState == .connected else { throw LampLinkError.notConnected }
        if writeCharacteristic == nil {
            let ready = await waitForCharacteristic()
            guard ready else { throw LampLinkError.notReady }
        }
        try await withCheckedThrowingContinuation { continuation in
            outgoing.append(Outgoing(data: data, continuation: continuation))
            pump()
        }
    }

    private func waitForCharacteristic() async -> Bool {
        let deadline = Date().addingTimeInterval(5)
        while writeCharacteristic == nil && connectionState == .connected && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
        return writeCharacteristic != nil
    }

    private func pump() {
        guard !isSending, activeWrite == nil, let next = outgoing.first else { return }
        guard connectionState == .connected,
              let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral else { return }

        outgoing.removeFirst()
        activeWrite = next
        isSending = true
        let token = UUID()
        activeToken = token
        peripheral.writeValue(next.data, for: characteristic, type: .withResponse)

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard let self, self.activeToken == token else { return }
            self.isSending = false
            self.activeWrite = nil
            self.activeToken = nil
            next.finish(.failure(LampLinkError.timedOut))
            self.pump()
        }
    }

    private func failQueued(_ error: Error) {
        activeToken = nil
        isSending = false
        activeWrite?.finish(.failure(error))
        activeWrite = nil
        let queued = outgoing
        outgoing.removeAll()
        queued.forEach { $0.finish(.failure(error)) }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                problemMessage = nil
                if wantsScan { startScanning() }
            case .poweredOff:
                problemMessage = "Turn on Bluetooth to find the lamp."
                connectionState = .error("Bluetooth is off")
            case .unauthorized:
                problemMessage = "Allow Bluetooth for Lumina in Settings."
                connectionState = .error("Bluetooth unauthorized")
            case .unsupported:
                problemMessage = "This iPhone does not support Bluetooth."
                connectionState = .error("Bluetooth unsupported")
            default:
                problemMessage = nil
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let advertised = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            let name = peripheral.name ?? advertised ?? BluetoothManager.targetDeviceName
            let device = DiscoveredPeripheral(peripheral: peripheral, name: name, rssi: RSSI.intValue)
            if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                discoveredDevices[index] = device
            } else {
                discoveredDevices.append(device)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            connectedPeripheral = peripheral
            peripheral.delegate = self
            connectionState = .connected
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            connectionState = .error("Failed to connect")
            failQueued(LampLinkError.failed("Failed to connect"))
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            connectionState = .disconnected
            connectedPeripheral = nil
            connectedDevice = nil
            writeCharacteristic = nil
            failQueued(LampLinkError.notConnected)
            if wantsScan { startScanning() }
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let services = peripheral.services else { return }
            for service in services where service.uuid == Self.serviceUUID {
                peripheral.discoverCharacteristics([Self.commandUUID], for: service)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            if let characteristics = service.characteristics {
                for characteristic in characteristics where characteristic.uuid == Self.commandUUID {
                    writeCharacteristic = characteristic
                }
            }
            pump()
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard let active = activeWrite else { return }
            activeToken = nil
            isSending = false
            activeWrite = nil
            if let error {
                active.finish(.failure(error))
            } else {
                active.finish(.success(()))
            }
            pump()
        }
    }
}
