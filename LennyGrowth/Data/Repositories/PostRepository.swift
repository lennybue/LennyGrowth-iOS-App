import Foundation
import SwiftData

final class PostRepository: PostRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let modelContext: ModelContext

    init(apiClient: APIClientProtocol, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    func createPost(_ post: Post) async throws -> Post {
        let request = post.toCreateRequest()
        let dto: PostDTO = try await apiClient.request(.createPost, body: request)
        return dto.toDomain()
    }

    func updatePost(_ post: Post) async throws -> Post {
        let request = post.toUpdateRequest()
        let dto: PostDTO = try await apiClient.request(.updatePost(id: post.id), body: request)
        return dto.toDomain()
    }

    func deletePost(id: String) async throws {
        try await apiClient.request(.deletePost(id: id), body: nil)
        deleteDraftFromCache(serverID: id)
    }

    func fetchPosts(status: Post.PostStatus?) async throws -> [Post] {
        let dtos: [PostDTO] = try await apiClient.request(.posts(status: status?.rawValue), body: nil)
        return dtos.map { $0.toDomain() }
    }

    func fetchPost(id: String) async throws -> Post {
        let dto: PostDTO = try await apiClient.request(.post(id: id), body: nil)
        return dto.toDomain()
    }

    func schedulePost(_ post: Post, scheduledAt: Date) async throws -> Post {
        let formatter = ISO8601DateFormatter()
        let request = SchedulePostRequest(scheduledAt: formatter.string(from: scheduledAt))
        let dto: PostDTO = try await apiClient.request(.schedulePost(id: post.id), body: request)
        let scheduled = dto.toDomain()
        deleteDraftFromCache(serverID: post.id)
        return scheduled
    }

    func publishPost(_ post: Post) async throws -> Post {
        let dto: PostDTO = try await apiClient.request(.publishPost(id: post.id), body: nil)
        return dto.toDomain()
    }

    func saveDraft(_ post: Post) async throws -> Post {
        let model = PostDraftSwiftDataModel.from(post)
        if let existingServerID = post.id.isEmpty ? nil : post.id {
            let descriptor = FetchDescriptor<PostDraftSwiftDataModel>(
                predicate: #Predicate { $0.serverID == existingServerID }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.content = model.content
                existing.platformsRaw = model.platformsRaw
                existing.hashtagsRaw = model.hashtagsRaw
                existing.platformVariantsData = model.platformVariantsData
                existing.updatedAt = Date()
                try? modelContext.save()
                return existing.toDomain()
            }
        }
        modelContext.insert(model)
        try? modelContext.save()

        do {
            let request = post.toCreateRequest()
            let dto: PostDTO = try await apiClient.request(.createPost, body: request)
            let serverPost = dto.toDomain()
            if let saved = (try? modelContext.fetch(FetchDescriptor<PostDraftSwiftDataModel>(predicate: #Predicate { $0.id == model.id })))?.first {
                saved.serverID = serverPost.id
                try? modelContext.save()
            }
            return serverPost
        } catch {
            return model.toDomain()
        }
    }

    func fetchDrafts() async throws -> [Post] {
        do {
            let dtos: [PostDTO] = try await apiClient.request(.drafts, body: nil)
            return dtos.map { $0.toDomain() }
        } catch {
            return fetchLocalDrafts()
        }
    }

    func fetchScheduledPosts() async throws -> [Post] {
        let dtos: [PostDTO] = try await apiClient.request(.scheduledPosts, body: nil)
        return dtos.map { $0.toDomain() }.sorted { ($0.scheduledAt ?? .distantFuture) < ($1.scheduledAt ?? .distantFuture) }
    }

    func connectSocialAccount(platform: SocialPlatform, accessToken: String) async throws -> ConnectedAccount {
        let request = ConnectAccountRequest(accessToken: accessToken, platform: platform.rawValue)
        let dto: ConnectedAccountDTO = try await apiClient.request(.connectAccount(platform: platform.rawValue), body: request)
        return dto.toDomain()
    }

    func disconnectSocialAccount(accountID: String) async throws {
        try await apiClient.request(.disconnectAccount(id: accountID), body: nil)
    }

    func fetchConnectedAccounts() async throws -> [ConnectedAccount] {
        let response: ConnectedAccountsResponse = try await apiClient.request(.connectedAccounts, body: nil)
        return response.accounts.map { $0.toDomain() }
    }

    // MARK: - Local Cache Helpers

    private func fetchLocalDrafts() -> [Post] {
        let descriptor = FetchDescriptor<PostDraftSwiftDataModel>(
            predicate: #Predicate { $0.isDraft == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor))?.map { $0.toDomain() } ?? []
    }

    private func deleteDraftFromCache(serverID: String) {
        let descriptor = FetchDescriptor<PostDraftSwiftDataModel>(
            predicate: #Predicate { $0.serverID == serverID }
        )
        if let toDelete = try? modelContext.fetch(descriptor) {
            toDelete.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }
}
