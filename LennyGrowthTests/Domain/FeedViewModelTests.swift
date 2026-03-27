import XCTest
@testable import LennyGrowth

@MainActor
final class FeedViewModelTests: XCTestCase {
    var sut: FeedViewModel!
    var mockUseCase: MockFetchArticlesUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockFetchArticlesUseCase()
        sut = FeedViewModel(fetchArticlesUseCase: mockUseCase)
    }

    override func tearDown() {
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    // MARK: - Load Articles

    func test_loadArticles_success_populatesArticles() async throws {
        // Given
        let expectedArticles = [Article.mock(), Article.mock(), Article.mock()]
        mockUseCase.articlesToReturn = expectedArticles

        // When
        await sut.loadArticles()

        // Then
        XCTAssertEqual(sut.articles.count, expectedArticles.count)
        if case .loaded = sut.loadingState { } else {
            XCTFail("Expected .loaded state, got \(sut.loadingState)")
        }
    }

    func test_loadArticles_failure_setsErrorState() async throws {
        // Given
        mockUseCase.errorToThrow = NetworkError.noInternetConnection

        // When
        await sut.loadArticles()

        // Then
        XCTAssertTrue(sut.articles.isEmpty)
        if case .error = sut.loadingState { } else {
            XCTFail("Expected .error state, got \(sut.loadingState)")
        }
    }

    func test_loadArticles_setsLoadingState() async throws {
        // Given
        mockUseCase.articlesToReturn = [.mock()]
        var observedStates: [Bool] = []

        // Record initial state
        observedStates.append(sut.loadingState.isLoading)

        // When
        await sut.loadArticles()

        // Then - loading completes to loaded state
        if case .loaded = sut.loadingState { } else {
            XCTFail("Expected loaded state")
        }
    }

    // MARK: - Pagination

    func test_loadMore_appendsArticles() async throws {
        // Given
        let firstPage = [Article.mock(), Article.mock()]
        let secondPage = [Article.mock()]
        mockUseCase.articlesToReturn = firstPage
        mockUseCase.paginationHasNextPage = true

        await sut.loadArticles()
        XCTAssertEqual(sut.articles.count, 2)

        // When
        mockUseCase.articlesToReturn = secondPage
        mockUseCase.paginationHasNextPage = false
        await sut.loadMore()

        // Then
        XCTAssertEqual(sut.articles.count, 3)
    }

    func test_loadMore_doesNotLoad_whenNoNextPage() async throws {
        // Given
        mockUseCase.articlesToReturn = [.mock()]
        mockUseCase.paginationHasNextPage = false
        await sut.loadArticles()

        let initialCount = sut.articles.count
        let initialCallCount = mockUseCase.callCount

        // When
        await sut.loadMore()

        // Then - no additional network call
        XCTAssertEqual(sut.articles.count, initialCount)
        XCTAssertEqual(mockUseCase.callCount, initialCallCount)
    }

    // MARK: - Refresh

    func test_refresh_replacesArticles() async throws {
        // Given
        mockUseCase.articlesToReturn = [.mock(), .mock()]
        await sut.loadArticles()
        XCTAssertEqual(sut.articles.count, 2)

        // When
        mockUseCase.articlesToReturn = [.mock()]
        await sut.refreshArticles()

        // Then
        XCTAssertEqual(sut.articles.count, 1)
    }

    // MARK: - Category Filter

    func test_selectCategory_triggersNewFetch() async throws {
        // Given
        mockUseCase.articlesToReturn = [.mock()]
        await sut.loadArticles()
        let initialCallCount = mockUseCase.callCount

        // When
        sut.selectCategory(.marketing)

        // Allow debounce to fire - this simulates waiting for Combine publisher
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertEqual(sut.selectedCategory, .marketing)
        // Call count should have increased (at least one more call)
        XCTAssertGreaterThan(mockUseCase.callCount, initialCallCount)
    }

    func test_selectCategory_nil_fetchesAllArticles() async throws {
        // Given
        sut.selectedCategory = .marketing
        mockUseCase.articlesToReturn = [.mock()]

        // When
        sut.selectCategory(nil)

        // Then
        XCTAssertNil(sut.selectedCategory)
    }

    // MARK: - Bookmark

    func test_toggleBookmark_updatesArticleInList() async throws {
        // Given
        var article = Article.mock()
        article = Article(
            id: "test-id",
            title: article.title,
            summary: article.summary,
            content: article.content,
            author: article.author,
            publishedAt: article.publishedAt,
            updatedAt: article.updatedAt,
            imageURL: article.imageURL,
            tags: article.tags,
            category: article.category,
            readTimeMinutes: article.readTimeMinutes,
            sourceURL: article.sourceURL,
            isFeatured: article.isFeatured,
            isBookmarked: false
        )
        mockUseCase.articlesToReturn = [article]
        mockUseCase.paginationHasNextPage = false
        await sut.loadArticles()

        var bookmarkedArticle = article
        // Simulate toggled article
        mockUseCase.bookmarkToReturn = Article(
            id: "test-id",
            title: article.title,
            summary: article.summary,
            content: article.content,
            author: article.author,
            publishedAt: article.publishedAt,
            updatedAt: article.updatedAt,
            imageURL: article.imageURL,
            tags: article.tags,
            category: article.category,
            readTimeMinutes: article.readTimeMinutes,
            sourceURL: article.sourceURL,
            isFeatured: article.isFeatured,
            isBookmarked: true
        )

        // When
        await sut.toggleBookmark(article: article)

        // Then
        XCTAssertEqual(sut.articles.first?.isBookmarked, true)
    }

    // MARK: - Search

    func test_searchQuery_passedToUseCase() async throws {
        // Given
        mockUseCase.articlesToReturn = [.mock()]
        await sut.loadArticles()

        // When
        sut.searchQuery = "growth"
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertEqual(mockUseCase.lastSearchQuery, "growth")
    }

    func test_emptySearchQuery_passesNilToUseCase() async throws {
        // Given
        mockUseCase.articlesToReturn = [.mock()]
        sut.searchQuery = "test"
        try await Task.sleep(nanoseconds: 500_000_000)

        // When
        sut.searchQuery = ""
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertNil(mockUseCase.lastSearchQuery)
    }
}

// MARK: - Mock Use Case

final class MockFetchArticlesUseCase: FetchArticlesUseCaseProtocol {
    var articlesToReturn: [Article] = [.mock()]
    var errorToThrow: Error? = nil
    var paginationHasNextPage: Bool = false
    var bookmarkToReturn: Article? = nil
    var callCount: Int = 0
    var lastSearchQuery: String? = nil
    var lastCategory: Article.ArticleCategory? = nil

    func execute(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article> {
        callCount += 1
        lastCategory = category
        lastSearchQuery = searchQuery

        if let error = errorToThrow {
            throw error
        }

        return PaginatedResult(
            items: articlesToReturn,
            totalCount: paginationHasNextPage ? articlesToReturn.count + pageSize : articlesToReturn.count,
            currentPage: page,
            pageSize: pageSize
        )
    }

    func fetchArticle(id: String) async throws -> Article {
        if let error = errorToThrow { throw error }
        return articlesToReturn.first ?? .mock()
    }

    func toggleBookmark(articleID: String) async throws -> Article {
        if let error = errorToThrow { throw error }
        if let bookmark = bookmarkToReturn { return bookmark }
        var article = articlesToReturn.first { $0.id == articleID } ?? .mock()
        return article
    }

    func fetchBookmarked() async throws -> [Article] {
        if let error = errorToThrow { throw error }
        return articlesToReturn.filter { $0.isBookmarked }
    }
}
