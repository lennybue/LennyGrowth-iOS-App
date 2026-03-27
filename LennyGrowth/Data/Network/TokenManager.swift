import Foundation

/// Manages JWT access + refresh token lifecycle.
/// Thread-safe via actor isolation.
actor TokenManager {
    private let keychain: KeychainWrapper

    // In-flight refresh task — prevents multiple concurrent refresh calls
    private var refreshTask: Task<String, Error>? = nil

    init(keychain: KeychainWrapper) {
        self.keychain = keychain
    }

    // MARK: - Read

    var accessToken: String? {
        keychain.read(for: Constants.Keychain.accessTokenKey)
    }

    var refreshToken: String? {
        keychain.read(for: Constants.Keychain.refreshTokenKey)
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    // MARK: - Write

    func save(accessToken: String, refreshToken: String, userID: String? = nil) {
        keychain.save(accessToken, for: Constants.Keychain.accessTokenKey)
        keychain.save(refreshToken, for: Constants.Keychain.refreshTokenKey)
        if let userID { keychain.save(userID, for: Constants.Keychain.userIDKey) }
    }

    func clear() {
        keychain.clearAll()
    }

    // MARK: - Refresh (deduped)

    /// Returns a valid access token.
    /// If the current token is expired and a refresh is needed, this
    /// coalesces concurrent calls into a single network request.
    func validAccessToken(refresher: (String) async throws -> TokenResponse) async throws -> String {
        if let task = refreshTask {
            return try await task.value
        }

        guard let rt = refreshToken else {
            throw NetworkError.unauthorized
        }

        let task = Task<String, Error> {
            defer { Task { await self.clearRefreshTask() } }
            let response = try await refresher(rt)
            keychain.save(response.accessToken, for: Constants.Keychain.accessTokenKey)
            keychain.save(response.refreshToken, for: Constants.Keychain.refreshTokenKey)
            return response.accessToken
        }
        refreshTask = task
        return try await task.value
    }

    private func clearRefreshTask() {
        refreshTask = nil
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}
