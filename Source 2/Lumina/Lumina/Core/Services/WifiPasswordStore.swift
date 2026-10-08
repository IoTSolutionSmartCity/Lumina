import Foundation
import Security

enum WifiPasswordStore {
    private static let service = "LuminaWifi"
    private static let chosenKey = "luminaWifiChosen"

    static var hasChosen: Bool {
        UserDefaults.standard.bool(forKey: chosenKey)
    }

    static func markChosen() {
        UserDefaults.standard.set(true, forKey: chosenKey)
    }

    static func password(for ssid: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: ssid,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8),
              !password.isEmpty else {
            return nil
        }
        return password
    }

    static func save(_ password: String, for ssid: String) {
        guard !password.isEmpty else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: ssid
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = Data(password.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
}
