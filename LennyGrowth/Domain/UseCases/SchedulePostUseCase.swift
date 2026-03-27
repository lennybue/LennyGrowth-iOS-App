import Foundation

protocol SchedulePostUseCaseProtocol {
    func schedule(_ post: Post, at date: Date) async throws -> Post
    func fetchScheduled() async throws -> [Post]
    func cancelScheduled(postID: String) async throws
    func reschedule(postID: String, newDate: Date) async throws -> Post
}

final class SchedulePostUseCase: SchedulePostUseCaseProtocol {
    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func schedule(_ post: Post, at date: Date) async throws -> Post {
        guard date > Date() else {
            throw ScheduleError.pastDate
        }
        guard !post.platforms.isEmpty else {
            throw PostError.noPlatformsSelected
        }
        guard !post.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PostError.emptyContent
        }
        return try await postRepository.schedulePost(post, scheduledAt: date)
    }

    func fetchScheduled() async throws -> [Post] {
        return try await postRepository.fetchScheduledPosts()
    }

    func cancelScheduled(postID: String) async throws {
        guard !postID.isEmpty else { throw PostError.invalidPost }
        let post = try await postRepository.fetchPost(id: postID)
        guard post.status == .scheduled else {
            throw ScheduleError.cannotCancel
        }
        try await postRepository.deletePost(id: postID)
    }

    func reschedule(postID: String, newDate: Date) async throws -> Post {
        guard newDate > Date() else {
            throw ScheduleError.pastDate
        }
        var post = try await postRepository.fetchPost(id: postID)
        post.scheduledAt = newDate
        return try await postRepository.schedulePost(post, scheduledAt: newDate)
    }
}

enum ScheduleError: LocalizedError {
    case pastDate
    case cannotCancel
    case invalidTimeSlot

    var errorDescription: String? {
        switch self {
        case .pastDate:
            return "Please select a future date and time."
        case .cannotCancel:
            return "Only scheduled posts can be cancelled."
        case .invalidTimeSlot:
            return "The selected time slot is not available."
        }
    }
}
