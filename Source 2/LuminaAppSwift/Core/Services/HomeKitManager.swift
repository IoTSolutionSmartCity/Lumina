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
    private let accessorySetupManager = HMAccessorySetupManager()

    override init() {
        super.init()
        homeManager.delegate = self
    }

    var primaryHome: HMHome? {
        homeManager.primaryHome ?? homeManager.homes.first
    }

    func triggerNativePairingFlow() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                self.accessorySetupManager.startAccessorySetup(
                    withPayload: nil,
                    completionHandler: { [weak self] completion in
                        switch completion {
                        case .didFinishWithNewAccessories(let accessories):
                            if let first = accessories.first {
                                self?.addAccessoryToHome(first)
                            }
                            self?.isSetupComplete = true
                            continuation.resume()
                        case .didFinishWithAccessories(let accessories):
                            for accessory in accessories {
                                self?.addAccessoryToHome(accessory)
                            }
                            self?.isSetupComplete = true
                            continuation.resume()
                        case .didCancel:
                            continuation.resume(throwing: HomeKitError.cancelled)
                        case .didFailWithError(let error):
                            continuation.resume(throwing: error)
                        @unknown default:
                            continuation.resume(throwing: HomeKitError.unknown)
                        }
                    }
                )
            }
        }
    }

    private func addAccessoryToHome(_ accessory: HMAccessory) {
        if let primaryHome = primaryHome {
            primaryHome.addAccessory(accessory) { [weak self] error in
                if error == nil {
                    Task { @MainActor in
                        self?.accessories.append(accessory)
                        self?.saveHome()
                    }
                }
            }
        } else {
            createHome(named: "Lumina Home") { [weak self] home in
                home?.addAccessory(accessory) { [weak self] error in
                    if error == nil {
                        Task { @MainActor in
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
            if let home = home {
                self?.home = home
                self?.homeManager.primaryHome = home
                self?.saveHome()
            }
            completion(home)
        }
    }

    private func saveHome() {
        UserDefaults.standard.set(true, forKey: "homeKitSetupComplete")
    }

    func updateAccessory(_ accessory: HMAccessory, brightness: Double? = nil, color: Color? = nil, power: Bool? = nil) {
        for service in accessory.services {
            for characteristic in service.characteristics {
                if let brightness = brightness,
                   characteristic.characteristicType == HMCharacteristicType.brightness {
                    characteristic.writeValue(Int(brightness * 100)) { _ in }
                }
                if let power = power,
                   characteristic.characteristicType == HMCharacteristicType.powerState {
                    characteristic.writeValue(power) { _ in }
                }
            }
        }
    }

    func removeAccessory(_ accessory: HMAccessory) {
        home?.removeAccessory(accessory) { [weak self] error in
            if error == nil {
                Task { @MainActor in
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
            self.home = manager.primaryHome
        }
    }
}

enum HomeKitError: LocalizedError {
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Setup was cancelled"
        case .unknown: return "An unknown error occurred"
        }
    }
}
