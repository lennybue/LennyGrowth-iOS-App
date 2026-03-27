import Foundation
import SwiftUI

@MainActor
final class ComposerViewModel: ObservableObject {
    // MARK: - Editor state
    @Published var content: String = ""
    @Published var selectedPlatforms: Set<SocialPlatform> = [.linkedin]
    @Published var selectedTone: AITone = .professional
    @Published var scheduledDate: Date = .now.addingTimeInterval(3600)
    @Published var isScheduling: Bool = false
    @Published var showScheduler: Bool = false
    @Published var showAIAssistant: Bool = false

    // MARK: - Queue
    @Published var scheduledPosts: [Post] = []
    @Published var draftPosts: [Post] = []
    @Published var isLoadingQueue: Bool = false

    // MARK: - Warnings / Alerts
    @Published var showLinkWarning: Bool = false
    @Published var showHashtagWarning: Bool = false
    @Published var showLineCountWarning: Bool = false
    @Published var isSaving: Bool = false
    @Published var error: Error? = nil

    // MARK: - Services
    private let postRepository: any PostRepositoryProtocol
    private let aiRepository: any AIRepositoryProtocol

    // MARK: - Computed

    var linkedInCharCount: Int { content.count }
    var threadsCharCount: Int { content.count }

    var isLinkedInOverLimit: Bool { linkedInCharCount > Constants.LinkedIn.maxCharacters }
    var isThreadsOverLimit: Bool { threadsCharCount > Constants.Threads.maxCharacters }

    var threadLineCount: Int { content.lineCount }
    var isThreadsOverLineLimit: Bool { threadLineCount > Constants.Threads.maxLinesRecommended }

    var isLinkedInSelected: Bool { selectedPlatforms.contains(.linkedin) }
    var isThreadsSelected:  Bool { selectedPlatforms.contains(.threads) }
    var isBothSelected: Bool { isLinkedInSelected && isThreadsSelected }

    var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedPlatforms.isEmpty &&
        !isLinkedInOverLimit
    }

    // MARK: - Init

    init(postRepository: any PostRepositoryProtocol, aiRepository: any AIRepositoryProtocol) {
        self.postRepository = postRepository
        self.aiRepository = aiRepository
    }

    // MARK: - Content validation

    func validateContent() {
        // LinkedIn: warn if URL in body
        if isLinkedInSelected && content.hasURL {
            showLinkWarning = true
        } else {
            showLinkWarning = false
        }
        // Threads: warn on hashtag
        if isThreadsSelected && content.hasHashtag {
            showHashtagWarning = true
        } else {
            showHashtagWarning = false
        }
        // Threads: warn on >6 lines
        if isThreadsSelected && isThreadsOverLineLimit {
            showLineCountWarning = true
        } else {
            showLineCountWarning = false
        }
    }

    // MARK: - Actions

    func togglePlatform(_ platform: SocialPlatform) {
        if selectedPlatforms.contains(platform) {
            if selectedPlatforms.count > 1 {
                selectedPlatforms.remove(platform)
            }
        } else {
            selectedPlatforms.insert(platform)
        }
        validateContent()
    }

    func applyGeneratedContent(_ text: String) {
        content = text
        validateContent()
    }

    func saveDraft() async {
        guard !content.isEmpty else { return }
        isSaving = true
        let post = Post(
            id: UUID().uuidString,
            content: content,
            platforms: Array(selectedPlatforms),
            status: .draft,
            scheduledAt: nil,
            publishedAt: nil,
            createdAt: .now,
            updatedAt: nil,
            mediaAttachments: [],
            platformVariants: [:],
            metrics: nil,
            linkedArticleID: nil,
            linkedProductID: nil,
            hashtags: [],
            isDraft: true
        )
        do {
            _ = try await postRepository.saveDraft(post)
            await loadQueue()
        } catch { self.error = error }
        isSaving = false
    }

    func schedulePost() async {
        guard canPost else { return }
        isScheduling = true
        let post = Post(
            id: UUID().uuidString,
            content: content,
            platforms: Array(selectedPlatforms),
            status: .draft,
            scheduledAt: scheduledDate,
            publishedAt: nil,
            createdAt: .now,
            updatedAt: nil,
            mediaAttachments: [],
            platformVariants: [:],
            metrics: nil,
            linkedArticleID: nil,
            linkedProductID: nil,
            hashtags: [],
            isDraft: false
        )
        do {
            let created = try await postRepository.createPost(post)
            _ = try await postRepository.schedulePost(created, scheduledAt: scheduledDate)
            content = ""
            showScheduler = false
            await loadQueue()
        } catch { self.error = error }
        isScheduling = false
    }

    func deletePost(id: String) async {
        do {
            try await postRepository.deletePost(id: id)
            scheduledPosts.removeAll { $0.id == id }
            draftPosts.removeAll { $0.id == id }
        } catch { self.error = error }
    }

    func loadQueue() async {
        isLoadingQueue = true
        do {
            async let scheduled = postRepository.fetchScheduledPosts()
            async let drafts = postRepository.fetchDrafts()
            let (s, d) = try await (scheduled, drafts)
            scheduledPosts = s
            draftPosts = d
        } catch { self.error = error }
        isLoadingQueue = false
    }
}
