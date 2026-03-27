import Foundation
import Combine

enum LoadingState {
    case idle
    case loading
    case loaded
    case error(Error)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: Error? {
        if case .error(let e) = self { return e }
        return nil
    }
}

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var articles: [Article] = []
    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var isLoadingMore: Bool = false
    @Published var selectedCategory: Article.ArticleCategory? = nil
    @Published var searchQuery: String = ""
    @Published private(set) var hasNextPage: Bool = false

    private let fetchArticlesUseCase: FetchArticlesUseCaseProtocol
    private var currentPage = 1
    private let pageSize = Constants.API.defaultPageSize
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(fetchArticlesUseCase: FetchArticlesUseCaseProtocol) {
        self.fetchArticlesUseCase = fetchArticlesUseCase
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.resetAndLoad()
            }
            .store(in: &cancellables)

        $selectedCategory
            .dropFirst()
            .sink { [weak self] _ in
                self?.resetAndLoad()
            }
            .store(in: &cancellables)
    }

    func loadArticles() async {
        guard case .idle = loadingState else { return }
        loadingState = .loading
        await fetchPage(1, reset: true)
    }

    func refreshArticles() async {
        loadingState = .loading
        await fetchPage(1, reset: true)
    }

    func loadMore() async {
        guard hasNextPage, !isLoadingMore else { return }
        isLoadingMore = true
        await fetchPage(currentPage + 1, reset: false)
        isLoadingMore = false
    }

    func selectCategory(_ category: Article.ArticleCategory?) {
        selectedCategory = category
    }

    func toggleBookmark(article: Article) async {
        do {
            let updated = try await fetchArticlesUseCase.toggleBookmark(articleID: article.id)
            if let index = articles.firstIndex(where: { $0.id == updated.id }) {
                articles[index] = updated
            }
        } catch {
            // Bookmark failure is non-critical; silently fail
        }
    }

    func articleDidAppear(_ article: Article) {
        guard let index = articles.firstIndex(where: { $0.id == article.id }),
              index >= articles.count - 5 else { return }
        Task { await loadMore() }
    }

    private func resetAndLoad() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self = self else { return }
            self.loadingState = .loading
            await self.fetchPage(1, reset: true)
        }
    }

    private func fetchPage(_ page: Int, reset: Bool) async {
        do {
            let result = try await fetchArticlesUseCase.execute(
                page: page,
                pageSize: pageSize,
                category: selectedCategory,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            if reset {
                articles = result.items
            } else {
                articles.append(contentsOf: result.items)
            }
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
            loadingState = .loaded
        } catch {
            if reset { articles = [] }
            loadingState = .error(error)
        }
    }
}
