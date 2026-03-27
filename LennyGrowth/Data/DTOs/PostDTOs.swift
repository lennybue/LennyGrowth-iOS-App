import Foundation

// MARK: - Requests

struct CreatePostRequest: Encodable {
    let content: String
    let platforms: [String]
    let platformVariants: [String: String]
    let scheduledAt: String?
    let hashtags: [String]
    let isDraft: Bool
    let mediaAttachmentIds: [String]
}

struct UpdatePostRequest: Encodable {
    let content: String?
    let platforms: [String]?
    let scheduledAt: String?
    let hashtags: [String]?
    let isDraft: Bool?
}

struct SchedulePostRequest: Encodable {
    let scheduledAt: String
}

struct ConnectSocialRequest: Encodable {
    let accessToken: String
    let platform: String
}

// MARK: - Responses

struct PostDTO: Decodable {
    let id: String
    let content: String
    let platforms: [String]
    let status: String
    let scheduledAt: String?
    let publishedAt: String?
    let createdAt: String
    let updatedAt: String?
    let mediaAttachments: [MediaAttachmentDTO]?
    let platformVariants: [String: String]?
    let metrics: PostMetricsDTO?
    let linkedArticleId: String?
    let linkedProductId: String?
    let hashtags: [String]?
    let isDraft: Bool

    func toDomain() -> Post {
        Post(
            id: id,
            content: content,
            platforms: platforms.compactMap { SocialPlatform(rawValue: $0) },
            status: Post.PostStatus(rawValue: status) ?? .draft,
            scheduledAt: scheduledAt.flatMap { parseISO8601($0) },
            publishedAt: publishedAt.flatMap { parseISO8601($0) },
            createdAt: parseISO8601(createdAt) ?? .now,
            updatedAt: updatedAt.flatMap { parseISO8601($0) },
            mediaAttachments: mediaAttachments?.map { $0.toDomain() } ?? [],
            platformVariants: platformVariants ?? [:],
            metrics: metrics?.toDomain(),
            linkedArticleID: linkedArticleId,
            linkedProductID: linkedProductId,
            hashtags: hashtags ?? [],
            isDraft: isDraft
        )
    }
}

struct MediaAttachmentDTO: Decodable {
    let id: String
    let type: String
    let url: String?
    let thumbnailUrl: String?
    let altText: String?
    let fileSize: Int?
    let width: Int?
    let height: Int?

    func toDomain() -> MediaAttachment {
        MediaAttachment(
            id: id,
            type: MediaAttachment.AttachmentType(rawValue: type) ?? .image,
            url: url.flatMap { URL(string: $0) },
            localPath: nil,
            thumbnailURL: thumbnailUrl.flatMap { URL(string: $0) },
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

struct ConnectedAccountResponse: Decodable {
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
            lastSyncedAt: lastSyncedAt.flatMap { parseISO8601($0) }
        )
    }
}

struct ConnectedAccountsResponse: Decodable {
    let accounts: [ConnectedAccountResponse]
}

// MARK: - Helper

private func parseISO8601(_ string: String) -> Date? {
    ISO8601DateFormatter().date(from: string)
}
