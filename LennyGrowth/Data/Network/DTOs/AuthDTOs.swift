import Foundation

// MARK: - Request DTOs

struct SignInRequest: Encodable {
    let email: String
    let password: String
}

struct SignUpRequest: Encodable {
    let email: String
    let password: String
    let displayName: String
}

struct SignInWithAppleRequest: Encodable {
    let identityToken: String
    let authorizationCode: String
    let fullName: String?
}

struct UpdateProfileRequest: Encodable {
    let displayName: String?
    let bio: String?
    let avatarURL: URL?
}

struct ResetPasswordRequest: Encodable {
    let email: String
}

// MARK: - Response DTOs

struct AuthResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: UserDTO
}

struct UserDTO: Decodable {
    let id: String
    let email: String
    let displayName: String
    let avatarUrl: URL?
    let bio: String?
    let connectedAccounts: [ConnectedAccountDTO]
    let subscriptionTier: String
    let createdAt: String

    func toDomain() -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            avatarURL: avatarUrl,
            bio: bio,
            connectedAccounts: connectedAccounts.map { $0.toDomain() },
            subscriptionTier: User.SubscriptionTier(rawValue: subscriptionTier) ?? .free,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
        )
    }
}

struct ConnectedAccountDTO: Decodable {
    let id: String
    let platform: String
    let username: String
    let profileImageUrl: URL?
    let isConnected: Bool
    let followerCount: Int?
    let lastSyncedAt: String?

    func toDomain() -> ConnectedAccount {
        ConnectedAccount(
            id: id,
            platform: SocialPlatform(rawValue: platform) ?? .twitter,
            username: username,
            profileImageURL: profileImageUrl,
            isConnected: isConnected,
            followerCount: followerCount,
            lastSyncedAt: lastSyncedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
}
