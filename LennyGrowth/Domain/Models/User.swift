import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var displayName: String
    var avatarURL: URL?
    var bio: String?
    var connectedAccounts: [ConnectedAccount]
    var subscriptionTier: SubscriptionTier
    var createdAt: Date

    enum SubscriptionTier: String, Codable, CaseIterable {
        case free = "free"
        case pro = "pro"

        var displayName: String {
            switch self {
            case .free: return "Free"
            case .pro: return "Pro"
            }
        }

        var postsPerMonth: Int {
            switch self {
            case .free: return 10
            case .pro: return Int.max
            }
        }

        var scheduledPostsLimit: Int {
            switch self {
            case .free: return 3
            case .pro: return Int.max
            }
        }

        var aiGenerationsPerMonth: Int {
            switch self {
            case .free: return 5
            case .pro: return 100
            }
        }
    }

    static func empty() -> User {
        User(
            id: "",
            email: "",
            displayName: "",
            avatarURL: nil,
            bio: nil,
            connectedAccounts: [],
            subscriptionTier: .free,
            createdAt: Date()
        )
    }

    static func mock() -> User {
        User(
            id: "user_lenny",
            email: "lennard@lennardbuessow.digital",
            displayName: "Lennard Büssow",
            avatarURL: nil,
            bio: "Digital Marketing Specialist & IT-Consultant | SEO · SEA · KI | DACH-Raum",
            connectedAccounts: [
                ConnectedAccount(
                    id: "li_1",
                    platform: .linkedin,
                    username: "lennardbuessow",
                    profileImageURL: nil,
                    isConnected: true,
                    followerCount: 4200,
                    lastSyncedAt: .now
                )
            ],
            subscriptionTier: .free,
            createdAt: Date().addingTimeInterval(-180 * 86400)
        )
    }
}

struct ConnectedAccount: Identifiable, Codable, Equatable {
    let id: String
    let platform: SocialPlatform
    var username: String
    var profileImageURL: URL?
    var isConnected: Bool
    var followerCount: Int?
    var lastSyncedAt: Date?

    var displayHandle: String {
        "@\(username)"
    }
}
