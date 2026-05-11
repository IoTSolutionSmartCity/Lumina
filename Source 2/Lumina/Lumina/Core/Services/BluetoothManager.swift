import Foundation
import CoreBluetooth
import SwiftUI

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
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

enum LampCommand: Equatable {
    case setPower(Bool)
    case setBrightness(Double)
    case setColor(red: UInt8, green: UInt8, blue: UInt8)

    var data: Data {
        switch self {
        case .setPower(let on):
            return Data([on ? 0x01 : 0x00])
        case .setBrightness(let level):
            return Data([UInt8(level * 255.0)])
        case .setColor(let r, let g, let b):
            return Data([0x02, r, g, b])
        }
    }
}

struct DiscoveredPeripheral: Identifiable, Equatable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    var isConnectable: Bool

    init(peripheral: CBPeripheral, rssi: Int, isConnectable: Bool = true) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Lumina Device"
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
    var discoveredDevices: [DiscoveredPeripheral] = []
    var connectionState: ConnectionState = .disconnected
    var isScanning: Bool = false
    var connectedDevice: DiscoveredPeripheral?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var commandQueue: [LampCommand] = []
    private var isSending = false

    private let lampServiceUUID = CBUUID(string: "180A")
    private let writeCharacteristicUUID = CBUUID(string: "2A58")

    /// The exact advertised name the ESP32-S3 HomeSpan device reports during BLE discovery.
    static let targetDeviceName = "Lumina ESP32S3 Lamp"

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: nil, queue: .main)
        centralManager.delegate = self
    }

    func startScanning() async {
        guard centralManager.state == .poweredOn else {
            connectionState = .error("Bluetooth is not available")
            return
        }
        discoveredDevices.removeAll()
        isScanning = true
        connectionState = .scanning
        // Scan specifically for the Device Information service (180A) exposed by HomeSpan.
        // This avoids flooding with non-Lumina peripherals and ensures we only find
        // the ESP32-S3 once it advertises its GATT service.
        centralManager.scanForPeripherals(
            withServices: [lampServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        try? await Task.sleep(for: .seconds(15))
        if isScanning {
            stopScanning()
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    func connect(to device: DiscoveredPeripheral) async {
        stopScanning()
        connectionState = .connecting
        connectedDevice = device
        centralManager.connect(device.peripheral, options: nil)

        try? await Task.sleep(for: .seconds(10))
        if connectionState == .connecting {
            centralManager.cancelPeripheralConnection(device.peripheral)
            connectionState = .error("Connection timed out")
        }
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        connectedDevice = nil
        writeCharacteristic = nil
        connectionState = .disconnected
    }

    func sendCommand(_ command: LampCommand) async {
        commandQueue.append(command)
        await processQueue()
    }

    private func processQueue() async {
        guard !isSending, !commandQueue.isEmpty, connectionState == .connected else { return }
        isSending = true
        let command = commandQueue.removeFirst()

        if let characteristic = writeCharacteristic,
           let peripheral = connectedPeripheral {
            peripheral.writeValue(command.data, for: characteristic, type: .withResponse)
        }
        isSending = false
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                break
            case .poweredOff:
                connectionState = .error("Bluetooth is off")
            case .unauthorized:
                connectionState = .error("Bluetooth unauthorized")
            case .unsupported:
                connectionState = .error("Bluetooth unsupported")
            default:
                connectionState = .disconnected
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String

            // Match only "Lumina ESP32S3 Lamp" — the exact name of the HomeSpan ESP32-S3 device
            let isLumina = name == BluetoothManager.targetDeviceName
                || name?.lowercased() == BluetoothManager.targetDeviceName.lowercased()

            guard isLumina else { return }

            let device = DiscoveredPeripheral(peripheral: peripheral, rssi: RSSI.intValue)
            if !discoveredDevices.contains(where: { $0.id == device.id }) {
                discoveredDevices.append(device)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            connectedPeripheral = peripheral
            peripheral.delegate = self
            connectionState = .connected
            peripheral.discoverServices([lampServiceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            connectionState = .error("Failed to connect")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            connectionState = .disconnected
            connectedPeripheral = nil
            connectedDevice = nil
            writeCharacteristic = nil
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let services = peripheral.services else { return }
            for service in services {
                peripheral.discoverCharacteristics([writeCharacteristicUUID], for: service)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid == writeCharacteristicUUID {
                        writeCharacteristic = characteristic
                    }
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            isSending = false
            if !commandQueue.isEmpty {
                await processQueue()
            }
        }
    }
}
