import Foundation

// MARK: - Post Request DTOs

struct CreatePostRequest: Encodable {
    let content: String
    let platforms: [String]
    let platformVariants: [String: String]
    let hashtags: [String]
    let linkedArticleId: String?
    let linkedProductId: String?
    let isDraft: Bool
}

struct SchedulePostRequest: Encodable {
    let scheduledAt: String
}

struct UpdatePostRequest: Encodable {
    let content: String
    let platforms: [String]
    let platformVariants: [String: String]
    let hashtags: [String]
}

// MARK: - Post Response DTO

struct PostDTO: Decodable {
    let id: String
    let content: String
    let platforms: [String]
    let status: String
    let scheduledAt: String?
    let publishedAt: String?
    let createdAt: String
    let updatedAt: String?
    let mediaAttachments: [MediaAttachmentDTO]
    let platformVariants: [String: String]
    let metrics: PostMetricsDTO?
    let linkedArticleId: String?
    let linkedProductId: String?
    let hashtags: [String]
    let isDraft: Bool

    func toDomain() -> Post {
        let formatter = ISO8601DateFormatter()
        return Post(
            id: id,
            content: content,
            platforms: platforms.compactMap { SocialPlatform(rawValue: $0) },
            status: Post.PostStatus(rawValue: status) ?? .draft,
            scheduledAt: scheduledAt.flatMap { formatter.date(from: $0) },
            publishedAt: publishedAt.flatMap { formatter.date(from: $0) },
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: updatedAt.flatMap { formatter.date(from: $0) },
            mediaAttachments: mediaAttachments.map { $0.toDomain() },
            platformVariants: platformVariants,
            metrics: metrics?.toDomain(),
            linkedArticleID: linkedArticleId,
            linkedProductID: linkedProductId,
            hashtags: hashtags,
            isDraft: isDraft
        )
    }
}

struct MediaAttachmentDTO: Decodable {
    let id: String
    let type: String
    let url: URL?
    let thumbnailUrl: URL?
    let altText: String?
    let fileSize: Int?
    let width: Int?
    let height: Int?

    func toDomain() -> MediaAttachment {
        MediaAttachment(
            id: id,
            type: MediaAttachment.AttachmentType(rawValue: type) ?? .image,
            url: url,
            localPath: nil,
            thumbnailURL: thumbnailUrl,
            altText: altText,
            fileSize: fileSize,
            width: width,
            height: height
        )
    }
}

struct PostMetricsDTO: Decodable {
    let impressions: Int
    let reach: Int
    let likes: Int
    let comments: Int
    let shares: Int
    let clicks: Int
    let engagementRate: Double

    func toDomain() -> PostMetrics {
        PostMetrics(
            impressions: impressions,
            reach: reach,
            likes: likes,
            comments: comments,
            shares: shares,
            clicks: clicks,
            engagementRate: engagementRate
        )
    }
}

// MARK: - Connected Account DTOs

struct ConnectAccountRequest: Encodable {
    let accessToken: String
    let platform: String
}

struct ConnectedAccountsResponse: Decodable {
    let accounts: [ConnectedAccountDTO]
}

// MARK: - Post to DTO Conversion

extension Post {
    func toCreateRequest() -> CreatePostRequest {
        CreatePostRequest(
            content: content,
            platforms: platforms.map { $0.rawValue },
            platformVariants: platformVariants,
            hashtags: hashtags,
            linkedArticleId: linkedArticleID,
            linkedProductId: linkedProductID,
            isDraft: isDraft
        )
    }

    func toUpdateRequest() -> UpdatePostRequest {
        UpdatePostRequest(
            content: content,
            platforms: platforms.map { $0.rawValue },
            platformVariants: platformVariants,
            hashtags: hashtags
        )
    }
}
