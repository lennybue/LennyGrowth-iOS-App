import Foundation

protocol PostRepositoryProtocol {
    func createPost(_ post: Post) async throws -> Post
    func updatePost(_ post: Post) async throws -> Post
    func deletePost(id: String) async throws
    func fetchPosts(status: Post.PostStatus?) async throws -> [Post]
    func fetchPost(id: String) async throws -> Post
    func schedulePost(_ post: Post, scheduledAt: Date) async throws -> Post
    func publishPost(_ post: Post) async throws -> Post
    func saveDraft(_ post: Post) async throws -> Post
    func fetchDrafts() async throws -> [Post]
    func fetchScheduledPosts() async throws -> [Post]
    func connectSocialAccount(platform: SocialPlatform, accessToken: String) async throws -> ConnectedAccount
    func disconnectSocialAccount(accountID: String) async throws
    func fetchConnectedAccounts() async throws -> [ConnectedAccount]
}
