import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let service: String
    private let accessGroup: String?

    private enum Key {
        static let accessToken = "com.lennygrowth.access_token"
        static let refreshToken = "com.lennygrowth.refresh_token"
        static let userID = "com.lennygrowth.user_id"
    }

    init(service: String = Bundle.main.bundleIdentifier ?? "com.lennygrowth.app", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Token Management

    func saveAccessToken(_ token: String) {
        save(token, forKey: Key.accessToken)
    }

    func getAccessToken() -> String? {
        return get(forKey: Key.accessToken)
    }

    func saveRefreshToken(_ token: String) {
        save(token, forKey: Key.refreshToken)
    }

    func getRefreshToken() -> String? {
        return get(forKey: Key.refreshToken)
    }

    func saveUserID(_ userID: String) {
        save(userID, forKey: Key.userID)
    }

    func getUserID() -> String? {
        return get(forKey: Key.userID)
    }

    func clearAll() {
        delete(forKey: Key.accessToken)
        delete(forKey: Key.refreshToken)
        delete(forKey: Key.userID)
    }

    var hasValidTokens: Bool {
        return getAccessToken() != nil && getRefreshToken() != nil
    }

    // MARK: - Generic CRUD

    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        var query = baseQuery(forKey: key)

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            let attributes: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            return updateStatus == errSecSuccess
        } else {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
    }

    func get(forKey key: String) -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Private Helpers

    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }
}
