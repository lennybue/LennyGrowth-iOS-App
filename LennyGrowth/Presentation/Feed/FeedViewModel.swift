import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    // MARK: - Published state
    @Published var articles: [Article] = []
    @Published var selectedCategory: Article.ArticleCategory? = nil
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var hasNextPage: Bool = false

    private let repository: any ContentRepositoryProtocol
    private var currentPage: Int = 1
    private let pageSize: Int = 10
    private var isLoadingMore: Bool = false

    init(repository: any ContentRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Load

    func loadArticles() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 1
        do {
            let result = try await repository.fetchArticles(
                page: currentPage,
                pageSize: pageSize,
                category: selectedCategory,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            articles = result.items
            hasNextPage = result.hasNextPage
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasNextPage else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let result = try await repository.fetchArticles(
                page: nextPage,
                pageSize: pageSize,
                category: selectedCategory,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            articles += result.items
            currentPage = nextPage
            hasNextPage = result.hasNextPage
        } catch {
            self.error = error
        }
        isLoadingMore = false
    }

    func selectCategory(_ category: Article.ArticleCategory?) async {
        selectedCategory = category
        await loadArticles()
    }

    func search(_ query: String) async {
        searchQuery = query
        await loadArticles()
    }

    func toggleBookmark(article: Article) async {
        do {
            let updated = try await repository.toggleBookmark(articleID: article.id)
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index] = updated
            }
        } catch {
            self.error = error
        }
    }
}
