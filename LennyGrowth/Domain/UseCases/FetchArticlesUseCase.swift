import Foundation

protocol FetchArticlesUseCaseProtocol {
    func execute(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article>
    func fetchArticle(id: String) async throws -> Article
    func toggleBookmark(articleID: String) async throws -> Article
    func fetchBookmarked() async throws -> [Article]
}

final class FetchArticlesUseCase: FetchArticlesUseCaseProtocol {
    private let contentRepository: ContentRepositoryProtocol

    init(contentRepository: ContentRepositoryProtocol) {
        self.contentRepository = contentRepository
    }

    func execute(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article> {
        let query = searchQuery?.trimmingCharacters(in: .whitespaces)
        let trimmedQuery = query.flatMap { $0.isEmpty ? nil : $0 }
        return try await contentRepository.fetchArticles(
            page: max(1, page),
            pageSize: min(50, max(1, pageSize)),
            category: category,
            searchQuery: trimmedQuery
        )
    }

    func fetchArticle(id: String) async throws -> Article {
        guard !id.isEmpty else {
            throw ContentError.invalidID
        }
        return try await contentRepository.fetchArticle(id: id)
    }

    func toggleBookmark(articleID: String) async throws -> Article {
        guard !articleID.isEmpty else {
            throw ContentError.invalidID
        }
        return try await contentRepository.toggleBookmark(articleID: articleID)
    }

    func fetchBookmarked() async throws -> [Article] {
        return try await contentRepository.fetchBookmarkedArticles()
    }
}

enum ContentError: LocalizedError {
    case invalidID
    case notFound
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidID: return "Invalid content identifier."
        case .notFound: return "Content not found."
        case .downloadFailed: return "Failed to download content. Please try again."
        }
    }
}
