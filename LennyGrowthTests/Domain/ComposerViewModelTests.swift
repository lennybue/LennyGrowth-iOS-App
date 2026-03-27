import XCTest
@testable import LennyGrowth

@MainActor
final class ComposerViewModelTests: XCTestCase {
    var sut: ComposerViewModel!
    var mockCreatePostUseCase: MockCreatePostUseCase!
    var mockSchedulePostUseCase: MockSchedulePostUseCase!
    var mockGenerateContentUseCase: MockGenerateContentUseCase!

    override func setUp() {
        super.setUp()
        mockCreatePostUseCase = MockCreatePostUseCase()
        mockSchedulePostUseCase = MockSchedulePostUseCase()
        mockGenerateContentUseCase = MockGenerateContentUseCase()
        sut = ComposerViewModel(
            createPostUseCase: mockCreatePostUseCase,
            schedulePostUseCase: mockSchedulePostUseCase,
            generateContentUseCase: mockGenerateContentUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockCreatePostUseCase = nil
        mockSchedulePostUseCase = nil
        mockGenerateContentUseCase = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_hasDefaultPlatforms() {
        XCTAssertTrue(sut.selectedPlatforms.contains(.twitter))
        XCTAssertTrue(sut.selectedPlatforms.contains(.linkedin))
    }

    func test_initialState_emptyContent() {
        XCTAssertTrue(sut.postContent.isEmpty)
    }

    func test_canPost_false_whenContentEmpty() {
        sut.postContent = ""
        XCTAssertFalse(sut.canPost)
    }

    func test_canPost_true_whenContentNotEmpty() {
        sut.postContent = "Hello world"
        XCTAssertTrue(sut.canPost)
    }

    func test_canPost_false_whenNoPlatforms() {
        sut.postContent = "Hello world"
        sut.selectedPlatforms = []
        XCTAssertFalse(sut.canPost)
    }

    // MARK: - Platform Management

    func test_togglePlatform_addsPlatform() {
        let initialCount = sut.selectedPlatforms.count
        sut.togglePlatform(.instagram)
        XCTAssertTrue(sut.selectedPlatforms.contains(.instagram))
    }

    func test_togglePlatform_removesPlatform_whenMultipleSelected() {
        sut.selectedPlatforms = [.twitter, .linkedin, .instagram]
        sut.togglePlatform(.instagram)
        XCTAssertFalse(sut.selectedPlatforms.contains(.instagram))
    }

    func test_togglePlatform_doesNotRemove_lastPlatform() {
        sut.selectedPlatforms = [.twitter]
        sut.togglePlatform(.twitter)
        XCTAssertTrue(sut.selectedPlatforms.contains(.twitter))
        XCTAssertEqual(sut.selectedPlatforms.count, 1)
    }

    // MARK: - Character Count

    func test_characterCount_usesMainContent_whenNoVariant() {
        sut.postContent = "Hello world"
        let count = sut.characterCount(for: .twitter)
        XCTAssertEqual(count, "Hello world".count)
    }

    func test_characterCount_usesVariant_whenSet() {
        sut.postContent = "Main content"
        sut.setContent("Twitter variant", for: .twitter)
        let count = sut.characterCount(for: .twitter)
        XCTAssertEqual(count, "Twitter variant".count)
    }

    func test_isWithinLimit_true_whenUnderLimit() {
        sut.postContent = String(repeating: "a", count: 200)
        XCTAssertTrue(sut.isWithinLimit(for: .twitter))
    }

    func test_isWithinLimit_false_whenOverLimit() {
        sut.postContent = String(repeating: "a", count: 300)
        XCTAssertFalse(sut.isWithinLimit(for: .twitter))
    }

    func test_remainingCharacters_calculatesCorrectly() {
        sut.postContent = String(repeating: "a", count: 100)
        let remaining = sut.remainingCharacters(for: .twitter)
        XCTAssertEqual(remaining, 180) // 280 - 100
    }

    // MARK: - Save Draft

    func test_saveDraft_callsUseCase() async {
        // Given
        sut.postContent = "Draft content"

        // When
        await sut.saveDraft()

        // Then
        XCTAssertTrue(mockCreatePostUseCase.saveDraftCalled)
    }

    func test_saveDraft_setsErrorOnFailure() async {
        // Given
        sut.postContent = "Draft content"
        mockCreatePostUseCase.errorToThrow = PostError.emptyContent

        // When
        await sut.saveDraft()

        // Then
        XCTAssertNotNil(sut.saveError)
    }

    // MARK: - Publish

    func test_publish_success_setsPublishSuccess() async {
        // Given
        sut.postContent = "Published content"

        // When
        await sut.publish()

        // Then
        XCTAssertTrue(sut.publishSuccess)
    }

    func test_publish_success_resetsComposer() async {
        // Given
        sut.postContent = "Published content"
        sut.hashtags = ["growth", "marketing"]

        // When
        await sut.publish()

        // Then
        XCTAssertTrue(sut.postContent.isEmpty)
        XCTAssertTrue(sut.hashtags.isEmpty)
    }

    func test_publish_failure_setsError() async {
        // Given
        sut.postContent = "Content"
        mockCreatePostUseCase.errorToThrow = PostError.publishFailed

        // When
        await sut.publish()

        // Then
        XCTAssertNotNil(sut.saveError)
        XCTAssertFalse(sut.publishSuccess)
    }

    // MARK: - Schedule Post

    func test_schedulePost_callsScheduleUseCase() async {
        // Given
        sut.postContent = "Scheduled post"
        sut.scheduledDate = Date().adding(hours: 2)

        // When
        await sut.schedulePost()

        // Then
        XCTAssertTrue(mockSchedulePostUseCase.scheduleCalled)
    }

    func test_schedulePost_withoutDate_doesNotCallSchedule() async {
        // Given
        sut.postContent = "Content"
        sut.scheduledDate = nil

        // When
        await sut.schedulePost()

        // Then
        XCTAssertFalse(mockSchedulePostUseCase.scheduleCalled)
    }

    // MARK: - Apply Generated Content

    func test_applyGeneratedContent_setsMainContent() {
        // Given
        let content = GeneratedContent(
            mainContent: "Generated post content",
            platformVariants: ["twitter": "Twitter version"],
            suggestedHashtags: ["growth", "marketing"],
            estimatedEngagement: nil,
            alternativeVersions: []
        )

        // When
        sut.applyGeneratedContent(content)

        // Then
        XCTAssertEqual(sut.postContent, "Generated post content")
        XCTAssertEqual(sut.hashtags, ["growth", "marketing"])
    }

    func test_applyGeneratedContent_setsPlatformVariants() {
        // Given
        let content = GeneratedContent(
            mainContent: "Main content",
            platformVariants: ["twitter": "Twitter variant", "linkedin": "LinkedIn variant"],
            suggestedHashtags: [],
            estimatedEngagement: nil,
            alternativeVersions: []
        )

        // When
        sut.applyGeneratedContent(content)

        // Then
        XCTAssertEqual(sut.platformVariants[.twitter], "Twitter variant")
        XCTAssertEqual(sut.platformVariants[.linkedin], "LinkedIn variant")
    }

    // MARK: - Reset Composer

    func test_resetComposer_clearsAllFields() {
        // Given
        sut.postContent = "Some content"
        sut.scheduledDate = Date()
        sut.hashtags = ["test"]
        sut.selectedPlatforms = [.twitter, .instagram, .facebook]

        // When
        sut.resetComposer()

        // Then
        XCTAssertTrue(sut.postContent.isEmpty)
        XCTAssertNil(sut.scheduledDate)
        XCTAssertTrue(sut.hashtags.isEmpty)
        XCTAssertEqual(sut.selectedPlatforms, [.twitter, .linkedin])
    }

    // MARK: - Load Queue

    func test_loadQueue_fetchesDraftsAndScheduled() async {
        // Given
        mockCreatePostUseCase.draftsToReturn = [.draft(), .draft()]
        mockSchedulePostUseCase.scheduledPostsToReturn = [.mock()]

        // When
        await sut.loadQueue()

        // Then
        XCTAssertEqual(sut.drafts.count, 2)
        XCTAssertEqual(sut.scheduledPosts.count, 1)
        if case .loaded = sut.queueLoadingState { } else {
            XCTFail("Expected .loaded state")
        }
    }

    func test_loadQueue_failure_setsErrorState() async {
        // Given
        mockCreatePostUseCase.errorToThrow = NetworkError.noInternetConnection

        // When
        await sut.loadQueue()

        // Then
        if case .error = sut.queueLoadingState { } else {
            XCTFail("Expected .error state")
        }
    }

    // MARK: - Delete Draft

    func test_deleteDraft_removesFromList() async {
        // Given
        let draft = Post.draft()
        sut.drafts = [draft]

        // When
        await sut.deleteDraft(id: draft.id)

        // Then
        XCTAssertTrue(mockCreatePostUseCase.deletePostCalled)
        XCTAssertFalse(sut.drafts.contains(where: { $0.id == draft.id }))
    }
}

// MARK: - Mock Use Cases

final class MockCreatePostUseCase: CreatePostUseCaseProtocol {
    var errorToThrow: Error? = nil
    var draftsToReturn: [Post] = []
    var saveDraftCalled = false
    var deletePostCalled = false

    func execute(_ post: Post) async throws -> Post {
        if let error = errorToThrow { throw error }
        return post
    }

    func saveDraft(_ post: Post) async throws -> Post {
        saveDraftCalled = true
        if let error = errorToThrow { throw error }
        return post
    }

    func fetchDrafts() async throws -> [Post] {
        if let error = errorToThrow { throw error }
        return draftsToReturn
    }

    func deletePost(id: String) async throws {
        deletePostCalled = true
        if let error = errorToThrow { throw error }
    }
}

final class MockSchedulePostUseCase: SchedulePostUseCaseProtocol {
    var errorToThrow: Error? = nil
    var scheduledPostsToReturn: [Post] = []
    var scheduleCalled = false

    func schedule(_ post: Post, at date: Date) async throws -> Post {
        scheduleCalled = true
        if let error = errorToThrow { throw error }
        return post
    }

    func fetchScheduled() async throws -> [Post] {
        if let error = errorToThrow { throw error }
        return scheduledPostsToReturn
    }

    func cancelScheduled(postID: String) async throws {
        if let error = errorToThrow { throw error }
    }

    func reschedule(postID: String, newDate: Date) async throws -> Post {
        if let error = errorToThrow { throw error }
        return .mock()
    }
}

final class MockGenerateContentUseCase: GenerateContentUseCaseProtocol {
    var errorToThrow: Error? = nil
    var contentToReturn = GeneratedContent(
        mainContent: "Generated content",
        platformVariants: [:],
        suggestedHashtags: ["growth"],
        estimatedEngagement: nil,
        alternativeVersions: []
    )

    func generate(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent {
        if let error = errorToThrow { throw error }
        return contentToReturn
    }

    func generateStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error> {
        let content = contentToReturn.mainContent
        let error = errorToThrow
        return AsyncThrowingStream { continuation in
            if let error = error {
                continuation.finish(throwing: error)
            } else {
                continuation.yield(content)
                continuation.finish()
            }
        }
    }

    func rewrite(content: String, tone: AITone, instruction: String) async throws -> String {
        if let error = errorToThrow { throw error }
        return content
    }

    func generateHashtags(for content: String, platforms: [SocialPlatform]) async throws -> [String] {
        if let error = errorToThrow { throw error }
        return ["growth", "marketing"]
    }

    func suggestBestTimes(for platform: SocialPlatform) async throws -> [Date] {
        if let error = errorToThrow { throw error }
        return [Date()]
    }
}
