import Foundation

// MARK: - Requests

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let displayName: String
}

struct AppleAuthRequest: Encodable {
    let identityToken: String
    let authorizationCode: String
    let fullName: String?
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct UpdateProfileRequest: Encodable {
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
}

struct ResetPasswordRequest: Encodable {
    let email: String
}

// MARK: - Responses

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: UserDTO
}

struct UserDTO: Decodable {
    let id: String
    let email: String
    let displayName: String
    let avatarUrl: String?
    let bio: String?
    let subscriptionTier: String
    let connectedAccounts: [ConnectedAccountDTO]?
    let createdAt: String

    func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            avatarURL: avatarUrl.flatMap { URL(string: $0) },
            bio: bio,
            connectedAccounts: connectedAccounts?.compactMap { $0.toDomain() } ?? [],
            subscriptionTier: subscriptionTier == "pro" ? .pro : .free,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? .now
        )
    }
}

struct ConnectedAccountDTO: Decodable {
    let id: String
    let platform: String
    let username: String
    let profileImageUrl: String?
    let isConnected: Bool
    let followerCount: Int?
    let lastSyncedAt: String?

    func toDomain() -> ConnectedAccount? {
        guard let platform = SocialPlatform(rawValue: platform) else { return nil }
        return ConnectedAccount(
            id: id,
            platform: platform,
            username: username,
            profileImageURL: profileImageUrl.flatMap { URL(string: $0) },
            isConnected: isConnected,
            followerCount: followerCount,
            lastSyncedAt: lastSyncedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
}
