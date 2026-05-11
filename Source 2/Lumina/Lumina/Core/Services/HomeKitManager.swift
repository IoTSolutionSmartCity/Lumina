import Foundation
import HomeKit
import SwiftUI

@MainActor
@Observable
final class HomeKitManager: NSObject {
    var home: HMHome?
    var accessories: [HMAccessory] = []
    var isSetupComplete: Bool = false
    var errorMessage: String?

    private let homeManager = HMHomeManager()

    override init() {
        super.init()
        homeManager.delegate = self
    }

    var primaryHome: HMHome? {
        homeManager.homes.first
    }

    func triggerNativePairingFlow() async throws {
        // The native accessory setup API changed across iOS SDKs. Keep the manager
        // buildable and let onboarding continue through BLE until pairing is wired
        // to the current HomeKit setup flow.
        errorMessage = HomeKitError.unavailable.localizedDescription
        throw HomeKitError.unavailable
    }

    private func addAccessoryToHome(_ accessory: HMAccessory) {
        if let primaryHome = primaryHome {
            primaryHome.addAccessory(accessory) { [weak self] error in
                if error == nil {
                    Task { @MainActor [weak self] in
                        self?.accessories.append(accessory)
                        self?.saveHome()
                    }
                }
            }
        } else {
            createHome(named: "Lumina Home") { [weak self] home in
                home?.addAccessory(accessory) { [weak self] error in
                    if error == nil {
                        Task { @MainActor [weak self] in
                            self?.home = home
                            self?.accessories.append(accessory)
                            self?.saveHome()
                        }
                    }
                }
            }
        }
    }

    private func createHome(named name: String, completion: @escaping (HMHome?) -> Void) {
        homeManager.addHome(withName: name) { [weak self] home, error in
            Task { @MainActor [weak self] in
                if let home = home {
                    self?.home = home
                    self?.saveHome()
                }
                completion(home)
            }
        }
    }

    private func saveHome() {
        UserDefaults.standard.set(true, forKey: "homeKitSetupComplete")
    }

    func updateAccessory(_ accessory: HMAccessory, brightness: Double? = nil, color: Color? = nil, power: Bool? = nil) {
        for service in accessory.services {
            for characteristic in service.characteristics {
                if let brightness = brightness,
                   characteristic.characteristicType == HMCharacteristicTypeBrightness {
                    characteristic.writeValue(Int(brightness * 100)) { _ in }
                }
                if let power = power,
                   characteristic.characteristicType == HMCharacteristicTypePowerState {
                    characteristic.writeValue(power) { _ in }
                }
            }
        }
    }

    func removeAccessory(_ accessory: HMAccessory) {
        home?.removeAccessory(accessory) { [weak self] error in
            if error == nil {
                Task { @MainActor [weak self] in
                    self?.accessories.removeAll { $0.uniqueIdentifier == accessory.uniqueIdentifier }
                }
            }
        }
    }
}

extension HomeKitManager: HMHomeManagerDelegate {
    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task { @MainActor in
            self.home = self.primaryHome
            if let home = self.home {
                self.accessories = home.accessories
            }
        }
    }

    nonisolated func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        Task { @MainActor in
            self.home = manager.homes.first
        }
    }
}

enum HomeKitError: LocalizedError {
    case cancelled
    case unavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Setup was cancelled"
        case .unavailable: return "HomeKit pairing is not available in this build yet"
        case .unknown: return "An unknown error occurred"
        }
    }
}
