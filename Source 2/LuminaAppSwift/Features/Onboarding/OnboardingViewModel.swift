import Foundation
import CoreBluetooth
import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    var discoveredDevices: [DiscoveredPeripheral] = []
    var connectionState: ConnectionState = .disconnected
    var isBluetoothEnabled: Bool = false
    var connectingDevice: DiscoveredPeripheral?

    private let bluetoothManager = BluetoothManager()

    func onAppear() {
        checkBluetoothState()
        if isBluetoothEnabled {
            startScanning()
        }
    }

    private func checkBluetoothState() {
        // In real implementation, check CBCentralManager authorization
        isBluetoothEnabled = true
    }

    func startScanning() {
        discoveredDevices.removeAll()
        connectionState = .scanning

        Task {
            await bluetoothManager.startScanning()
            await MainActor.run {
                discoveredDevices = bluetoothManager.discoveredDevices
                if connectionState == .scanning {
                    connectionState = .disconnected
                }
            }
        }
    }

    func stopScanning() {
        bluetoothManager.stopScanning()
    }

    func connect(to device: DiscoveredPeripheral) {
        connectingDevice = device
        connectionState = .connecting

        Task {
            await bluetoothManager.connect(to: device)
            await MainActor.run {
                connectionState = bluetoothManager.connectionState
                if case .connected = connectionState {
                    UserDefaults.standard.set(true, forKey: "isOnboarded")
                    HapticManager.shared.success()
                } else if case .error(let msg) = connectionState {
                    connectionState = .error(msg)
                    HapticManager.shared.error()
                }
                connectingDevice = nil
            }
        }
    }
}
