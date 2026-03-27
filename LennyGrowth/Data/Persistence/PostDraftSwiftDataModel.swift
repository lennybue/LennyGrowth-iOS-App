import Foundation
import SwiftData

@Model
final class PostDraftSwiftDataModel {
    @Attribute(.unique) var id: String
    var content: String
    var platformsRaw: [String]
    var statusRaw: String
    var scheduledAt: Date?
    var publishedAt: Date?
    var createdAt: Date
    var updatedAt: Date?
    var platformVariantsData: Data?
    var linkedArticleID: String?
    var linkedProductID: String?
    var hashtagsRaw: [String]
    var isDraft: Bool
    var serverID: String?

    init(
        id: String,
        content: String,
        platformsRaw: [String],
        statusRaw: String = "draft",
        scheduledAt: Date? = nil,
        publishedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        platformVariantsData: Data? = nil,
        linkedArticleID: String? = nil,
        linkedProductID: String? = nil,
        hashtagsRaw: [String] = [],
        isDraft: Bool = true,
        serverID: String? = nil
    ) {
        self.id = id
        self.content = content
        self.platformsRaw = platformsRaw
        self.statusRaw = statusRaw
        self.scheduledAt = scheduledAt
        self.publishedAt = publishedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.platformVariantsData = platformVariantsData
        self.linkedArticleID = linkedArticleID
        self.linkedProductID = linkedProductID
        self.hashtagsRaw = hashtagsRaw
        self.isDraft = isDraft
        self.serverID = serverID
    }

    func toDomain() -> Post {
        let platformVariants: [String: String]
        if let data = platformVariantsData,
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            platformVariants = decoded
        } else {
            platformVariants = [:]
        }

        return Post(
            id: serverID ?? id,
            content: content,
            platforms: platformsRaw.compactMap { SocialPlatform(rawValue: $0) },
            status: Post.PostStatus(rawValue: statusRaw) ?? .draft,
            scheduledAt: scheduledAt,
            publishedAt: publishedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            mediaAttachments: [],
            platformVariants: platformVariants,
            metrics: nil,
            linkedArticleID: linkedArticleID,
            linkedProductID: linkedProductID,
            hashtags: hashtagsRaw,
            isDraft: isDraft
        )
    }

    static func from(_ post: Post) -> PostDraftSwiftDataModel {
        let variantsData = try? JSONEncoder().encode(post.platformVariants)
        return PostDraftSwiftDataModel(
            id: UUID().uuidString,
            content: post.content,
            platformsRaw: post.platforms.map { $0.rawValue },
            statusRaw: post.status.rawValue,
            scheduledAt: post.scheduledAt,
            publishedAt: post.publishedAt,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            platformVariantsData: variantsData,
            linkedArticleID: post.linkedArticleID,
            linkedProductID: post.linkedProductID,
            hashtagsRaw: post.hashtags,
            isDraft: post.isDraft,
            serverID: post.id.isEmpty ? nil : post.id
        )
    }
}
