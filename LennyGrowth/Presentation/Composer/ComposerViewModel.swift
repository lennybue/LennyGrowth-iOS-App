import Foundation
import Combine

@MainActor
final class ComposerViewModel: ObservableObject {
    // MARK: - Post State
    @Published var postContent: String = ""
    @Published var selectedPlatforms: Set<SocialPlatform> = [.twitter, .linkedin]
    @Published var platformVariants: [SocialPlatform: String] = [:]
    @Published var scheduledDate: Date? = nil
    @Published var hashtags: [String] = []
    @Published var mediaAttachments: [MediaAttachment] = []

    // MARK: - UI State
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isPublishing: Bool = false
    @Published private(set) var saveError: Error? = nil
    @Published private(set) var publishSuccess: Bool = false
    @Published var showSchedulePicker: Bool = false
    @Published var showAIAssistant: Bool = false
    @Published var activePlatformTab: SocialPlatform = .twitter

    // MARK: - Queue State
    @Published private(set) var drafts: [Post] = []
    @Published private(set) var scheduledPosts: [Post] = []
    @Published private(set) var queueLoadingState: LoadingState = .idle

    private let createPostUseCase: CreatePostUseCaseProtocol
    private let schedulePostUseCase: SchedulePostUseCaseProtocol
    private let generateContentUseCase: GenerateContentUseCaseProtocol

    init(
        createPostUseCase: CreatePostUseCaseProtocol,
        schedulePostUseCase: SchedulePostUseCaseProtocol,
        generateContentUseCase: GenerateContentUseCaseProtocol
    ) {
        self.createPostUseCase = createPostUseCase
        self.schedulePostUseCase = schedulePostUseCase
        self.generateContentUseCase = generateContentUseCase
    }

    // MARK: - Character Count

    func characterCount(for platform: SocialPlatform) -> Int {
        if let variant = platformVariants[platform] {
            return variant.count
        }
        return postContent.count
    }

    func isWithinLimit(for platform: SocialPlatform) -> Bool {
        characterCount(for: platform) <= platform.characterLimit
    }

    func remainingCharacters(for platform: SocialPlatform) -> Int {
        platform.characterLimit - characterCount(for: platform)
    }

    var canPost: Bool {
        !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedPlatforms.isEmpty
            && selectedPlatforms.allSatisfy { isWithinLimit(for: $0) }
    }

    // MARK: - Platform Management

    func togglePlatform(_ platform: SocialPlatform) {
        if selectedPlatforms.contains(platform) {
            if selectedPlatforms.count > 1 {
                selectedPlatforms.remove(platform)
                platformVariants.removeValue(forKey: platform)
            }
        } else {
            selectedPlatforms.insert(platform)
            if activePlatformTab == platform { return }
        }
    }

    func content(for platform: SocialPlatform) -> String {
        platformVariants[platform] ?? postContent
    }

    func setContent(_ content: String, for platform: SocialPlatform) {
        platformVariants[platform] = content
    }

    // MARK: - Actions

    func saveDraft() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            let post = buildPost(isDraft: true)
            let saved = try await createPostUseCase.saveDraft(post)
            if !drafts.contains(where: { $0.id == saved.id }) {
                drafts.insert(saved, at: 0)
            }
        } catch {
            saveError = error
        }
    }

    func publish() async {
        isPublishing = true
        saveError = nil
        defer { isPublishing = false }

        do {
            let post = buildPost(isDraft: false)
            _ = try await createPostUseCase.execute(post)
            publishSuccess = true
            resetComposer()
        } catch {
            saveError = error
        }
    }

    func schedulePost() async {
        guard let date = scheduledDate else { return }
        isPublishing = true
        saveError = nil
        defer { isPublishing = false }

        do {
            let post = buildPost(isDraft: false)
            let created = try await createPostUseCase.execute(post)
            let scheduled = try await schedulePostUseCase.schedule(created, at: date)
            scheduledPosts.append(scheduled)
            scheduledPosts.sort { ($0.scheduledAt ?? .distantFuture) < ($1.scheduledAt ?? .distantFuture) }
            publishSuccess = true
            resetComposer()
        } catch {
            saveError = error
        }
    }

    func deleteDraft(id: String) async {
        do {
            try await createPostUseCase.deletePost(id: id)
            drafts.removeAll { $0.id == id }
        } catch {
            saveError = error
        }
    }

    func cancelScheduled(id: String) async {
        do {
            try await schedulePostUseCase.cancelScheduled(postID: id)
            scheduledPosts.removeAll { $0.id == id }
        } catch {
            saveError = error
        }
    }

    func loadQueue() async {
        guard case .idle = queueLoadingState else { return }
        queueLoadingState = .loading
        do {
            async let draftsTask = createPostUseCase.fetchDrafts()
            async let scheduledTask = schedulePostUseCase.fetchScheduled()
            let (fetchedDrafts, fetchedScheduled) = try await (draftsTask, scheduledTask)
            drafts = fetchedDrafts
            scheduledPosts = fetchedScheduled
            queueLoadingState = .loaded
        } catch {
            queueLoadingState = .error(error)
        }
    }

    func applyGeneratedContent(_ content: GeneratedContent) {
        postContent = content.mainContent
        for (platformRaw, variant) in content.platformVariants {
            if let platform = SocialPlatform(rawValue: platformRaw) {
                platformVariants[platform] = variant
            }
        }
        hashtags = content.suggestedHashtags
    }

    func resetComposer() {
        postContent = ""
        selectedPlatforms = [.twitter, .linkedin]
        platformVariants = [:]
        scheduledDate = nil
        hashtags = []
        mediaAttachments = []
        showSchedulePicker = false
        showAIAssistant = false
    }

    // MARK: - Private Helpers

    private func buildPost(isDraft: Bool) -> Post {
        var variantsDict: [String: String] = [:]
        for (platform, content) in platformVariants {
            variantsDict[platform.rawValue] = content
        }
        return Post(
            id: "",
            content: postContent,
            platforms: Array(selectedPlatforms),
            status: isDraft ? .draft : .publishing,
            scheduledAt: scheduledDate,
            publishedAt: nil,
            createdAt: Date(),
            updatedAt: nil,
            mediaAttachments: mediaAttachments,
            platformVariants: variantsDict,
            metrics: nil,
            linkedArticleID: nil,
            linkedProductID: nil,
            hashtags: hashtags,
            isDraft: isDraft
        )
    }
}
