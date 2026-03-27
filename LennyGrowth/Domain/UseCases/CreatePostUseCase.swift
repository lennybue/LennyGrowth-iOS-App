import Foundation

protocol CreatePostUseCaseProtocol {
    func execute(_ post: Post) async throws -> Post
    func saveDraft(_ post: Post) async throws -> Post
    func fetchDrafts() async throws -> [Post]
    func deletePost(id: String) async throws
}

final class CreatePostUseCase: CreatePostUseCaseProtocol {
    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ post: Post) async throws -> Post {
        try validatePost(post)
        return try await postRepository.createPost(post)
    }

    func saveDraft(_ post: Post) async throws -> Post {
        guard !post.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
              !post.mediaAttachments.isEmpty else {
            throw PostError.emptyContent
        }
        return try await postRepository.saveDraft(post)
    }

    func fetchDrafts() async throws -> [Post] {
        return try await postRepository.fetchDrafts()
    }

    func deletePost(id: String) async throws {
        guard !id.isEmpty else { throw PostError.invalidPost }
        try await postRepository.deletePost(id: id)
    }

    private func validatePost(_ post: Post) throws {
        guard !post.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PostError.emptyContent
        }
        guard !post.platforms.isEmpty else {
            throw PostError.noPlatformsSelected
        }
        for platform in post.platforms {
            let count = post.characterCount(for: platform)
            if count > platform.characterLimit {
                throw PostError.characterLimitExceeded(platform: platform, count: count, limit: platform.characterLimit)
            }
        }
    }
}

enum PostError: LocalizedError {
    case emptyContent
    case noPlatformsSelected
    case characterLimitExceeded(platform: SocialPlatform, count: Int, limit: Int)
    case schedulingConflict
    case invalidPost
    case publishFailed

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Post content cannot be empty."
        case .noPlatformsSelected:
            return "Please select at least one platform to post to."
        case .characterLimitExceeded(let platform, let count, let limit):
            return "\(platform.displayName) has a \(limit) character limit. Your post has \(count) characters."
        case .schedulingConflict:
            return "A post is already scheduled for that time."
        case .invalidPost:
            return "Invalid post data."
        case .publishFailed:
            return "Failed to publish post. Please try again."
        }
    }
}
