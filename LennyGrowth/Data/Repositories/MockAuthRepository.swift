import Foundation

final class MockAuthRepository: AuthRepositoryProtocol {
    private let keychain: KeychainWrapper
    private var _currentUser: User?

    // MARK: - AuthRepositoryProtocol

    var isAuthenticated: Bool {
        keychain.read(for: Constants.Keychain.accessTokenKey) != nil
    }

    init(keychain: KeychainWrapper) {
        self.keychain = keychain
    }

    func signIn(email: String, password: String) async throws -> User {
        try await Task.sleep(nanoseconds: 800_000_000)
        let user = User.mock()
        _currentUser = user
        persistSession(userID: user.id)
        return user
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: displayName,
            avatarURL: nil,
            bio: nil,
            connectedAccounts: [],
            subscriptionTier: .free,
            createdAt: .now
        )
        _currentUser = user
        persistSession(userID: user.id)
        return user
    }

    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User {
        try await Task.sleep(nanoseconds: 600_000_000)
        let user = User(
            id: UUID().uuidString,
            email: "apple@privaterelay.appleid.com",
            displayName: fullName ?? "Apple Nutzer",
            avatarURL: nil,
            bio: nil,
            connectedAccounts: [],
            subscriptionTier: .free,
            createdAt: .now
        )
        _currentUser = user
        persistSession(userID: user.id)
        return user
    }

    func signOut() async throws {
        _currentUser = nil
        keychain.clearAll()
    }

    func refreshToken() async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000)
        return "refreshed_mock_token_\(UUID().uuidString)"
    }

    func fetchCurrentUser() async throws -> User {
        if let user = _currentUser { return user }
        throw AuthError.notAuthenticated
    }

    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User {
        guard let user = _currentUser else { throw AuthError.notAuthenticated }
        let updated = User(
            id: user.id,
            email: user.email,
            displayName: displayName ?? user.displayName,
            avatarURL: avatarURL ?? user.avatarURL,
            bio: bio ?? user.bio,
            connectedAccounts: user.connectedAccounts,
            subscriptionTier: user.subscriptionTier,
            createdAt: user.createdAt
        )
        _currentUser = updated
        return updated
    }

    func deleteAccount() async throws {
        _currentUser = nil
        keychain.clearAll()
    }

    func resetPassword(email: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func getCurrentUserID() -> String? {
        keychain.read(for: Constants.Keychain.userIDKey)
    }

    // MARK: - Private

    private func persistSession(userID: String) {
        keychain.save("mock_access_token_\(UUID().uuidString)", for: Constants.Keychain.accessTokenKey)
        keychain.save("mock_refresh_token", for: Constants.Keychain.refreshTokenKey)
        keychain.save(userID, for: Constants.Keychain.userIDKey)
    }
}
