import Foundation

final class AuthRepository: AuthRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let keychainManager: KeychainManager
    private var _currentUserID: String?

    var isAuthenticated: Bool {
        keychainManager.hasValidTokens
    }

    init(apiClient: APIClientProtocol, keychainManager: KeychainManager) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
        self._currentUserID = keychainManager.getUserID()
    }

    func signIn(email: String, password: String) async throws -> User {
        let request = SignInRequest(email: email, password: password)
        let response: AuthResponseDTO = try await apiClient.request(.signIn, body: request)
        saveTokens(from: response)
        return response.user.toDomain()
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let request = SignUpRequest(email: email, password: password, displayName: displayName)
        let response: AuthResponseDTO = try await apiClient.request(.signUp, body: request)
        saveTokens(from: response)
        return response.user.toDomain()
    }

    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User {
        let request = SignInWithAppleRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            fullName: fullName
        )
        let response: AuthResponseDTO = try await apiClient.request(.signInWithApple, body: request)
        saveTokens(from: response)
        return response.user.toDomain()
    }

    func signOut() async throws {
        try await apiClient.request(.signOut, body: nil)
        keychainManager.clearAll()
        _currentUserID = nil
    }

    func refreshToken() async throws -> String {
        guard let refreshToken = keychainManager.getRefreshToken() else {
            throw NetworkError.unauthorized
        }
        struct RefreshRequest: Encodable { let refreshToken: String }
        struct RefreshResponse: Decodable { let accessToken: String; let refreshToken: String? }
        let request = RefreshRequest(refreshToken: refreshToken)
        let response: RefreshResponse = try await apiClient.request(.refreshToken, body: request)
        keychainManager.saveAccessToken(response.accessToken)
        if let newRefresh = response.refreshToken {
            keychainManager.saveRefreshToken(newRefresh)
        }
        return response.accessToken
    }

    func fetchCurrentUser() async throws -> User {
        let dto: UserDTO = try await apiClient.request(.currentUser, body: nil)
        let user = dto.toDomain()
        _currentUserID = user.id
        keychainManager.saveUserID(user.id)
        return user
    }

    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User {
        let request = UpdateProfileRequest(displayName: displayName, bio: bio, avatarURL: avatarURL)
        let dto: UserDTO = try await apiClient.request(.updateProfile, body: request)
        return dto.toDomain()
    }

    func deleteAccount() async throws {
        try await apiClient.request(.deleteAccount, body: nil)
        keychainManager.clearAll()
        _currentUserID = nil
    }

    func resetPassword(email: String) async throws {
        let request = ResetPasswordRequest(email: email)
        try await apiClient.request(.resetPassword, body: request)
    }

    func getCurrentUserID() -> String? {
        return _currentUserID ?? keychainManager.getUserID()
    }

    private func saveTokens(from response: AuthResponseDTO) {
        keychainManager.saveAccessToken(response.accessToken)
        keychainManager.saveRefreshToken(response.refreshToken)
        let user = response.user.toDomain()
        keychainManager.saveUserID(user.id)
        _currentUserID = user.id
    }
}
