import Foundation
import Combine

/// Local persistence for post drafts created while offline.
/// Uses UserDefaults with JSON encoding for simplicity (iOS 16+ compatible).
/// When connectivity is restored, the SyncCoordinator pushes pending drafts to the backend.
final class OfflineDraftStore {
    private let key = "com.lennardbuessow.lennygrowth.offlineDrafts"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Read

    func loadDrafts() -> [Post] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Post].self, from: data)) ?? []
    }

    // MARK: - Write

    func save(_ post: Post) {
        var drafts = loadDrafts()
        if let index = drafts.firstIndex(where: { $0.id == post.id }) {
            drafts[index] = post
        } else {
            drafts.append(post)
        }
        persist(drafts)
    }

    func delete(id: String) {
        var drafts = loadDrafts()
        drafts.removeAll { $0.id == id }
        persist(drafts)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Private

    private func persist(_ drafts: [Post]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(drafts) else { return }
        defaults.set(data, forKey: key)
    }
}

// MARK: - Sync Coordinator

/// Watches for network restoration and pushes offline drafts to the backend.
@MainActor
final class SyncCoordinator: ObservableObject {
    private let draftStore: OfflineDraftStore
    private let postRepository: any PostRepositoryProtocol
    private let networkMonitor: NetworkMonitor

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var isSyncing: Bool = false

    init(
        draftStore: OfflineDraftStore,
        postRepository: any PostRepositoryProtocol,
        networkMonitor: NetworkMonitor
    ) {
        self.draftStore = draftStore
        self.postRepository = postRepository
        self.networkMonitor = networkMonitor
        self.pendingCount = draftStore.loadDrafts().count

        // Observe connectivity changes
        Task { await self.observeConnectivity() }
    }

    func saveOfflineDraft(_ post: Post) {
        var draft = post
        // Tag as local-only until synced
        if !draft.id.hasPrefix("draft_local_") {
            draft = Post(
                id: "draft_local_\(UUID().uuidString)",
                content: draft.content,
                platforms: draft.platforms,
                status: .draft,
                scheduledAt: draft.scheduledAt,
                publishedAt: nil,
                createdAt: draft.createdAt,
                updatedAt: .now,
                mediaAttachments: draft.mediaAttachments,
                platformVariants: draft.platformVariants,
                metrics: nil,
                linkedArticleID: draft.linkedArticleID,
                linkedProductID: draft.linkedProductID,
                hashtags: draft.hashtags,
                isDraft: true
            )
        }
        draftStore.save(draft)
        pendingCount = draftStore.loadDrafts().count
    }

    func syncNow() async {
        guard !isSyncing, networkMonitor.isConnected else { return }
        let drafts = draftStore.loadDrafts()
        guard !drafts.isEmpty else { return }

        isSyncing = true
        for draft in drafts {
            do {
                _ = try await postRepository.saveDraft(draft)
                draftStore.delete(id: draft.id)
                pendingCount = draftStore.loadDrafts().count
            } catch {
                // Leave in store — retry next connectivity event
                break
            }
        }
        isSyncing = false
    }

    private func observeConnectivity() async {
        for await isConnected in networkMonitor.$isConnected.values {
            if isConnected && pendingCount > 0 {
                await syncNow()
            }
        }
    }
}
