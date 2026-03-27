import Foundation

struct Post: Identifiable, Codable, Equatable {
    let id: String
    var content: String
    var platforms: [SocialPlatform]
    var status: PostStatus
    var scheduledAt: Date?
    var publishedAt: Date?
    var createdAt: Date
    var updatedAt: Date?
    var mediaAttachments: [MediaAttachment]
    var platformVariants: [String: String]
    var metrics: PostMetrics?
    var linkedArticleID: String?
    var linkedProductID: String?
    var hashtags: [String]
    var isDraft: Bool

    enum PostStatus: String, Codable, CaseIterable {
        case draft = "draft"
        case scheduled = "scheduled"
        case publishing = "publishing"
        case published = "published"
        case failed = "failed"

        var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .scheduled: return "Scheduled"
            case .publishing: return "Publishing..."
            case .published: return "Published"
            case .failed: return "Failed"
            }
        }

        var iconSystemName: String {
            switch self {
            case .draft: return "doc.text"
            case .scheduled: return "clock"
            case .publishing: return "arrow.up.circle"
            case .published: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.circle.fill"
            }
        }
    }

    var characterCount: Int { content.count }

    func characterCount(for platform: SocialPlatform) -> Int {
        if let variant = platformVariants[platform.rawValue] {
            return variant.count
        }
        return content.count
    }

    func isWithinLimit(for platform: SocialPlatform) -> Bool {
        characterCount(for: platform) <= platform.characterLimit
    }
}

struct MediaAttachment: Identifiable, Codable, Equatable {
    let id: String
    var type: AttachmentType
    var url: URL?
    var localPath: String?
    var thumbnailURL: URL?
    var altText: String?
    var fileSize: Int?
    var width: Int?
    var height: Int?

    enum AttachmentType: String, Codable {
        case image = "image"
        case video = "video"
        case gif = "gif"
    }
}

struct PostMetrics: Codable, Equatable {
    var impressions: Int
    var reach: Int
    var likes: Int
    var comments: Int
    var shares: Int
    var clicks: Int
    var engagementRate: Double

    static var empty: PostMetrics {
        PostMetrics(impressions: 0, reach: 0, likes: 0, comments: 0, shares: 0, clicks: 0, engagementRate: 0)
    }
}

extension Post {
    static func mockList() -> [Post] {
        [
            Post(
                id: "post_1",
                content: "Ich habe heute eine Erkenntnis gehabt, die mein SEO-Denken verändert hat.\n\nGoogle bewertet nicht mehr nur Backlinks – E-E-A-T ist der neue Standard.\n\n3 sofort umsetzbare Tipps:\n→ Autorenbox mit echter Expertise\n→ Case Studies mit echten Daten\n→ Interne Verlinkung zum Thema\n\nWas ist deine größte SEO-Challenge?\n\n(Detaillierter Guide: erster Kommentar 👇)",
                platforms: [.linkedin],
                status: .scheduled,
                scheduledAt: Date().addingTimeInterval(2 * 3600),
                publishedAt: nil,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: nil,
                mediaAttachments: [],
                platformVariants: [:],
                metrics: nil,
                linkedArticleID: "article_1",
                linkedProductID: nil,
                hashtags: [],
                isDraft: false
            ),
            Post(
                id: "post_2",
                content: "Hot take: Die meisten Google Ads Accounts verbrennen 40 % ihres Budgets.\n\nDer Grund? Fehlende Negative Keywords.\n\n→ Mehr dazu: Link in Bio 🔗",
                platforms: [.threads],
                status: .draft,
                scheduledAt: nil,
                publishedAt: nil,
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: nil,
                mediaAttachments: [],
                platformVariants: [:],
                metrics: nil,
                linkedArticleID: nil,
                linkedProductID: nil,
                hashtags: [],
                isDraft: true
            ),
            Post(
                id: "post_3",
                content: "KI-Tools haben meinen Content-Workflow um 60 % beschleunigt.\n\nHier ist mein Stack 2026...\n\n#digitalmarketing #ki",
                platforms: [.linkedin],
                status: .published,
                scheduledAt: nil,
                publishedAt: Date().addingTimeInterval(-86400),
                createdAt: Date().addingTimeInterval(-90000),
                updatedAt: nil,
                mediaAttachments: [],
                platformVariants: [:],
                metrics: PostMetrics(impressions: 3240, reach: 2100, likes: 187, comments: 34, shares: 22, clicks: 91, engagementRate: 0.058),
                linkedArticleID: nil,
                linkedProductID: nil,
                hashtags: ["digitalmarketing", "ki"],
                isDraft: false
            )
        ]
    }

    static func draft() -> Post {
        Post(
            id: UUID().uuidString,
            content: "",
            platforms: [.twitter, .linkedin],
            status: .draft,
            scheduledAt: nil,
            publishedAt: nil,
            createdAt: Date(),
            updatedAt: nil,
            mediaAttachments: [],
            platformVariants: [:],
            metrics: nil,
            linkedArticleID: nil,
            linkedProductID: nil,
            hashtags: [],
            isDraft: true
        )
    }

    static func mock() -> Post {
        Post(
            id: UUID().uuidString,
            content: "Excited to share some amazing growth hacking tips for 2024! Thread below 👇\n\n#GrowthHacking #Marketing #SocialMedia",
            platforms: [.twitter, .linkedin],
            status: .scheduled,
            scheduledAt: Date().addingTimeInterval(3600),
            publishedAt: nil,
            createdAt: Date().addingTimeInterval(-600),
            updatedAt: nil,
            mediaAttachments: [],
            platformVariants: [:],
            metrics: nil,
            linkedArticleID: nil,
            linkedProductID: nil,
            hashtags: ["GrowthHacking", "Marketing", "SocialMedia"],
            isDraft: false
        )
    }
}
