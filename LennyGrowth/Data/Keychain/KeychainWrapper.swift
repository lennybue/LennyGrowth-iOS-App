import Foundation
import Security

/// Thin wrapper around Keychain Services.
/// All tokens are stored with kSecAttrAccessibleAfterFirstUnlock.
final class KeychainWrapper {

    func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrAccount:        key,
            kSecValueData:          data,
            kSecAttrAccessible:     kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(for key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:              kSecClassGenericPassword,
            kSecAttrAccount:        key,
            kSecReturnData:         true,
            kSecMatchLimit:         kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    func delete(for key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    func clearAll() {
        [Constants.Keychain.accessTokenKey,
         Constants.Keychain.refreshTokenKey,
         Constants.Keychain.userIDKey].forEach { delete(for: $0) }
    }
}
