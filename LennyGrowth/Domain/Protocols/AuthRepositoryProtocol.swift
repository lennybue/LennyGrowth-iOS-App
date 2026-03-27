import Foundation

protocol AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, displayName: String) async throws -> User
    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User
    func signOut() async throws
    func refreshToken() async throws -> String
    func fetchCurrentUser() async throws -> User
    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User
    func deleteAccount() async throws
    func resetPassword(email: String) async throws
    func getCurrentUserID() -> String?
    var isAuthenticated: Bool { get }
}
