import Foundation

protocol AuthUseCaseProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, displayName: String) async throws -> User
    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User
    func signOut() async throws
    func fetchCurrentUser() async throws -> User
    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User
    func resetPassword(email: String) async throws
    var isAuthenticated: Bool { get }
}

final class AuthUseCase: AuthUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func signIn(email: String, password: String) async throws -> User {
        guard !email.isEmpty, email.contains("@") else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        return try await authRepository.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        guard !email.isEmpty, email.contains("@") else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidDisplayName
        }
        return try await authRepository.signUp(email: email, password: password, displayName: displayName)
    }

    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User {
        return try await authRepository.signInWithApple(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            fullName: fullName
        )
    }

    func signOut() async throws {
        try await authRepository.signOut()
    }

    func fetchCurrentUser() async throws -> User {
        return try await authRepository.fetchCurrentUser()
    }

    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User {
        if let displayName = displayName, displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            throw AuthError.invalidDisplayName
        }
        return try await authRepository.updateProfile(displayName: displayName, bio: bio, avatarURL: avatarURL)
    }

    func resetPassword(email: String) async throws {
        guard !email.isEmpty, email.contains("@") else {
            throw AuthError.invalidEmail
        }
        try await authRepository.resetPassword(email: email)
    }

    var isAuthenticated: Bool { authRepository.isAuthenticated }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidDisplayName
    case notAuthenticated
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Please enter a valid email address."
        case .weakPassword: return "Password must be at least 8 characters long."
        case .invalidDisplayName: return "Please enter a display name."
        case .notAuthenticated: return "You must be signed in to perform this action."
        case .tokenExpired: return "Your session has expired. Please sign in again."
        }
    }
}
