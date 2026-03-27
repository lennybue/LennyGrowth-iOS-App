import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var summary: String
    var content: String
    var author: ArticleAuthor
    var publishedAt: Date
    var updatedAt: Date?
    var imageURL: URL?
    var tags: [String]
    var category: ArticleCategory
    var readTimeMinutes: Int
    var sourceURL: URL?
    var isFeatured: Bool
    var isBookmarked: Bool

    enum ArticleCategory: String, Codable, CaseIterable, Identifiable {
        case marketing = "marketing"
        case socialMedia = "social_media"
        case contentCreation = "content_creation"
        case analytics = "analytics"
        case seo = "seo"
        case emailMarketing = "email_marketing"
        case branding = "branding"
        case growth = "growth"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .marketing: return "Marketing"
            case .socialMedia: return "Social Media"
            case .contentCreation: return "Content Creation"
            case .analytics: return "Analytics"
            case .seo: return "SEO"
            case .emailMarketing: return "Email Marketing"
            case .branding: return "Branding"
            case .growth: return "Growth"
            }
        }

        var iconSystemName: String {
            switch self {
            case .marketing: return "megaphone"
            case .socialMedia: return "bubble.left.and.bubble.right"
            case .contentCreation: return "pencil.and.outline"
            case .analytics: return "chart.bar"
            case .seo: return "magnifyingglass"
            case .emailMarketing: return "envelope"
            case .branding: return "paintbrush"
            case .growth: return "arrow.up.right"
            }
        }
    }
}

struct ArticleAuthor: Codable, Equatable {
    let id: String
    var name: String
    var bio: String?
    var avatarURL: URL?
}

extension Article {
    static func mock() -> Article {
        Article(
            id: UUID().uuidString,
            title: "10 Proven Strategies to Grow Your Social Media Following in 2024",
            summary: "Discover actionable techniques to boost engagement and grow your audience across all major platforms.",
            content: "Growing your social media presence requires a consistent strategy...",
            author: ArticleAuthor(id: "1", name: "Sarah Mitchell", bio: "Marketing expert with 10 years experience", avatarURL: nil),
            publishedAt: Date().addingTimeInterval(-86400),
            updatedAt: nil,
            imageURL: URL(string: "https://picsum.photos/800/400"),
            tags: ["growth", "social media", "strategy"],
            category: .socialMedia,
            readTimeMinutes: 5,
            sourceURL: nil,
            isFeatured: true,
            isBookmarked: false
        )
    }
}
