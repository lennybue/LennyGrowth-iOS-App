import Foundation

/// Real network implementation of PostRepositoryProtocol.
final class NetworkPostRepository: PostRepositoryProtocol {
    private let client: APIClient
    private let encoder: JSONEncoder

    init(client: APIClient) {
        self.client = client
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    // MARK: - CRUD

    func createPost(_ post: Post) async throws -> Post {
        let dto: PostDTO = try await client.request(.createPost, body: postToRequest(post, isDraft: post.isDraft))
        return dto.toDomain()
    }

    func updatePost(_ post: Post) async throws -> Post {
        let dto: PostDTO = try await client.request(
            .updatePost(id: post.id),
            body: UpdatePostRequest(
                content: post.content,
                platforms: post.platforms.map { $0.rawValue },
                scheduledAt: post.scheduledAt.map { iso($0) },
                hashtags: post.hashtags,
                isDraft: post.isDraft
            )
        )
        return dto.toDomain()
    }

    func deletePost(id: String) async throws {
        try await client.requestVoid(.deletePost(id: id))
    }

    func fetchPosts(status: Post.PostStatus?) async throws -> [Post] {
        let response: [PostDTO] = try await client.request(.posts(status: status?.rawValue))
        return response.map { $0.toDomain() }
    }

    func fetchPost(id: String) async throws -> Post {
        let dto: PostDTO = try await client.request(.post(id: id))
        return dto.toDomain()
    }

    // MARK: - Scheduling

    func schedulePost(_ post: Post, scheduledAt: Date) async throws -> Post {
        let dto: PostDTO = try await client.request(
            .updatePost(id: post.id),
            body: SchedulePostRequest(scheduledAt: iso(scheduledAt))
        )
        return dto.toDomain()
    }

    func publishPost(_ post: Post) async throws -> Post {
        let dto: PostDTO = try await client.request(.publishPost(id: post.id))
        return dto.toDomain()
    }

    func saveDraft(_ post: Post) async throws -> Post {
        if post.id.isEmpty || post.id.hasPrefix("draft_local_") {
            return try await createPost(post)
        }
        return try await updatePost(post)
    }

    func fetchDrafts() async throws -> [Post] {
        let response: [PostDTO] = try await client.request(.posts(status: Post.PostStatus.draft.rawValue))
        return response.map { $0.toDomain() }
    }

    func fetchScheduledPosts() async throws -> [Post] {
        let response: [PostDTO] = try await client.request(.posts(status: Post.PostStatus.scheduled.rawValue))
        return response.map { $0.toDomain() }.sorted {
            ($0.scheduledAt ?? .distantFuture) < ($1.scheduledAt ?? .distantFuture)
        }
    }

    // MARK: - Social accounts

    func connectSocialAccount(platform: SocialPlatform, accessToken: String) async throws -> ConnectedAccount {
        // Auth code flow: server exchanges token with platform — device never stores platform token
        let response: ConnectedAccountResponse = try await client.request(
            .connectSocial(platform: platform.rawValue),
            body: ConnectSocialRequest(accessToken: accessToken, platform: platform.rawValue)
        )
        guard let account = response.toDomain() else {
            throw NetworkError.noData
        }
        return account
    }

    func disconnectSocialAccount(accountID: String) async throws {
        // Find platform from ID (passed as platform raw value in this API design)
        try await client.requestVoid(.disconnectSocial(platform: accountID))
    }

    func fetchConnectedAccounts() async throws -> [ConnectedAccount] {
        let response: ConnectedAccountsResponse = try await client.request(.connectedAccounts)
        return response.accounts.compactMap { $0.toDomain() }
    }

    // MARK: - Analytics

    func fetchPostAnalytics(id: String) async throws -> PostMetrics {
        let dto: PostMetricsDTO = try await client.request(.postAnalytics(id: id))
        return dto.toDomain()
    }

    // MARK: - Private helpers

    private func postToRequest(_ post: Post, isDraft: Bool) -> CreatePostRequest {
        CreatePostRequest(
            content: post.content,
            platforms: post.platforms.map { $0.rawValue },
            platformVariants: post.platformVariants,
            scheduledAt: post.scheduledAt.map { iso($0) },
            hashtags: post.hashtags,
            isDraft: isDraft,
            mediaAttachmentIds: post.mediaAttachments.map { $0.id }
        )
    }

    private func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
