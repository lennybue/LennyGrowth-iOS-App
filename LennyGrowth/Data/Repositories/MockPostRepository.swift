import Foundation

final class MockPostRepository: PostRepositoryProtocol {
    private var posts: [Post] = Post.mockList()
    private var connectedAccounts: [ConnectedAccount] = []

    func createPost(_ post: Post) async throws -> Post {
        var new = post
        new = Post(
            id: UUID().uuidString,
            content: post.content,
            platforms: post.platforms,
            status: .draft,
            scheduledAt: post.scheduledAt,
            publishedAt: nil,
            createdAt: .now,
            updatedAt: nil,
            mediaAttachments: post.mediaAttachments,
            platformVariants: post.platformVariants,
            metrics: nil,
            linkedArticleID: nil,
            linkedProductID: nil,
            hashtags: post.hashtags,
            isDraft: true
        )
        posts.append(new)
        return new
    }

    func updatePost(_ post: Post) async throws -> Post {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
            throw PostError.notFound
        }
        posts[index] = post
        return post
    }

    func deletePost(id: String) async throws {
        posts.removeAll { $0.id == id }
    }

    func fetchPosts(status: Post.PostStatus?) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 400_000_000)
        if let status { return posts.filter { $0.status == status } }
        return posts
    }

    func fetchPost(id: String) async throws -> Post {
        guard let post = posts.first(where: { $0.id == id }) else {
            throw PostError.notFound
        }
        return post
    }

    func schedulePost(_ post: Post, scheduledAt: Date) async throws -> Post {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
            throw PostError.notFound
        }
        let updated = Post(
            id: post.id, content: post.content, platforms: post.platforms,
            status: .scheduled, scheduledAt: scheduledAt, publishedAt: nil,
            createdAt: post.createdAt, updatedAt: .now,
            mediaAttachments: post.mediaAttachments,
            platformVariants: post.platformVariants,
            metrics: nil, linkedArticleID: nil, linkedProductID: nil,
            hashtags: post.hashtags, isDraft: false
        )
        posts[index] = updated
        return updated
    }

    func publishPost(_ post: Post) async throws -> Post {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
            throw PostError.notFound
        }
        let updated = Post(
            id: post.id, content: post.content, platforms: post.platforms,
            status: .published, scheduledAt: nil, publishedAt: .now,
            createdAt: post.createdAt, updatedAt: .now,
            mediaAttachments: post.mediaAttachments,
            platformVariants: post.platformVariants,
            metrics: PostMetrics(impressions: 0, reach: 0, likes: 0, comments: 0, shares: 0, clicks: 0, engagementRate: 0),
            linkedArticleID: nil, linkedProductID: nil,
            hashtags: post.hashtags, isDraft: false
        )
        posts[index] = updated
        return updated
    }

    func saveDraft(_ post: Post) async throws -> Post {
        if posts.contains(where: { $0.id == post.id }) {
            return try await updatePost(post)
        } else {
            return try await createPost(post)
        }
    }

    func fetchDrafts() async throws -> [Post] {
        return posts.filter { $0.isDraft || $0.status == .draft }
    }

    func fetchScheduledPosts() async throws -> [Post] {
        return posts.filter { $0.status == .scheduled }.sorted {
            ($0.scheduledAt ?? .distantFuture) < ($1.scheduledAt ?? .distantFuture)
        }
    }

    func connectSocialAccount(platform: SocialPlatform, accessToken: String) async throws -> ConnectedAccount {
        try await Task.sleep(nanoseconds: 800_000_000)
        let account = ConnectedAccount(
            id: UUID().uuidString,
            platform: platform,
            username: "lennybue",
            profileImageURL: nil,
            isConnected: true,
            followerCount: 4200,
            lastSyncedAt: .now
        )
        connectedAccounts.removeAll { $0.platform == platform }
        connectedAccounts.append(account)
        return account
    }

    func disconnectSocialAccount(accountID: String) async throws {
        connectedAccounts.removeAll { $0.id == accountID }
    }

    func fetchConnectedAccounts() async throws -> [ConnectedAccount] {
        return connectedAccounts
    }
}

enum PostError: LocalizedError {
    case notFound
    var errorDescription: String? {
        switch self { case .notFound: return String(localized: "Post nicht gefunden.") }
    }
}
