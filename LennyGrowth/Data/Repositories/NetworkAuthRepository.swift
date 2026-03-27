import Foundation

/// Real network implementation of AuthRepositoryProtocol.
/// All tokens are stored in Keychain. Social platform tokens never reach the device.
final class NetworkAuthRepository: AuthRepositoryProtocol {
    private let client: APIClient
    private let tokenManager: TokenManager
    private let keychain: KeychainWrapper   // for sync isAuthenticated check
    private var _cachedUser: User?

    init(client: APIClient, tokenManager: TokenManager, keychain: KeychainWrapper) {
        self.client = client
        self.tokenManager = tokenManager
        self.keychain = keychain
    }

    // MARK: - AuthRepositoryProtocol

    /// Synchronous — reads Keychain directly (no actor hop needed)
    var isAuthenticated: Bool {
        keychain.read(for: Constants.Keychain.accessTokenKey) != nil
    }

    func signIn(email: String, password: String) async throws -> User {
        let response: AuthResponse = try await client.request(
            .login,
            body: LoginRequest(email: email, password: password)
        )
        await persist(response)
        let user = response.user.toDomain()
        _cachedUser = user
        return user
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let response: AuthResponse = try await client.request(
            .register,
            body: RegisterRequest(email: email, password: password, displayName: displayName)
        )
        await persist(response)
        let user = response.user.toDomain()
        _cachedUser = user
        return user
    }

    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User {
        let response: AuthResponse = try await client.request(
            .loginApple,
            body: AppleAuthRequest(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                fullName: fullName
            )
        )
        await persist(response)
        let user = response.user.toDomain()
        _cachedUser = user
        return user
    }

    func signOut() async throws {
        // Best-effort — don't throw even if the server call fails
        try? await client.requestVoid(.logout)
        await tokenManager.clear()
        _cachedUser = nil
    }

    func refreshToken() async throws -> String {
        try await tokenManager.validAccessToken { [weak self] rt in
            guard let self else { throw NetworkError.cancelled }
            return try await self.client.request(
                .refreshToken,
                body: RefreshTokenRequest(refreshToken: rt)
            )
        }
    }

    func fetchCurrentUser() async throws -> User {
        if let cached = _cachedUser { return cached }
        let dto: UserDTO = try await client.request(.userProfile)
        let user = dto.toDomain()
        _cachedUser = user
        return user
    }

    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User {
        let dto: UserDTO = try await client.request(
            .updateProfile,
            body: UpdateProfileRequest(
                displayName: displayName,
                bio: bio,
                avatarUrl: avatarURL?.absoluteString
            )
        )
        let user = dto.toDomain()
        _cachedUser = user
        return user
    }

    func deleteAccount() async throws {
        try await client.requestVoid(.logout)
        await tokenManager.clear()
        _cachedUser = nil
    }

    func resetPassword(email: String) async throws {
        struct ResetRequest: Encodable { let email: String }
        try await client.requestVoid(.login, body: ResetRequest(email: email))
    }

    func getCurrentUserID() -> String? {
        keychain.read(for: Constants.Keychain.userIDKey)
    }

    // MARK: - Private

    private func persist(_ response: AuthResponse) async {
        await tokenManager.save(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userID: response.user.id
        )
    }
}
