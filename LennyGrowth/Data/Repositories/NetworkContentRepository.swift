import Foundation

/// Real network implementation of ContentRepositoryProtocol.
/// Uses If-Modified-Since for article list caching and tracks bookmarks locally
/// until the backend bookmark endpoint is available.
final class NetworkContentRepository: ContentRepositoryProtocol {
    private let client: APIClient
    private var lastArticlesFetch: Date? = nil
    private var bookmarkedIDs: Set<String> = []

    init(client: APIClient) {
        self.client = client
    }

    // MARK: - Articles

    func fetchArticles(
        page: Int,
        pageSize: Int,
        category: Article.ArticleCategory?,
        searchQuery: String?
    ) async throws -> PaginatedResult<Article> {
        // Send If-Modified-Since only for page 1 (index page) when we have a previous fetch time
        let ims: Date? = (page == 1) ? lastArticlesFetch : nil

        let endpoint = APIEndpoint.articles(
            page: page,
            pageSize: pageSize,
            category: category?.rawValue,
            search: searchQuery,
            ifModifiedSince: ims
        )

        // 304 Not Modified → return empty result; caller must use cached data
        let data = try await client.requestData(endpoint)
        if data.isEmpty {
            // 304 — signal caller with empty result
            return PaginatedResult(items: [], totalCount: 0, currentPage: page, pageSize: pageSize)
        }

        let decoder = makeDecoder()
        let response = try decoder.decode(ArticleListResponse.self, from: data)
        if page == 1 { lastArticlesFetch = .now }

        let items = response.items.map { dto in
            dto.toDomain(isBookmarked: bookmarkedIDs.contains(dto.id))
        }
        return PaginatedResult(
            items: items,
            totalCount: response.totalCount,
            currentPage: response.currentPage,
            pageSize: response.pageSize
        )
    }

    func fetchArticle(id: String) async throws -> Article {
        let dto: ArticleDTO = try await client.request(.article(id: id))
        return dto.toDomain(isBookmarked: bookmarkedIDs.contains(id))
    }

    func toggleBookmark(articleID: String) async throws -> Article {
        // Optimistically toggle local state; persist to backend when bookmark API is ready
        if bookmarkedIDs.contains(articleID) {
            bookmarkedIDs.remove(articleID)
        } else {
            bookmarkedIDs.insert(articleID)
        }
        return try await fetchArticle(id: articleID)
    }

    func fetchBookmarkedArticles() async throws -> [Article] {
        // Fetch each bookmarked article — replace with a dedicated endpoint when available
        return try await withThrowingTaskGroup(of: Article?.self) { group in
            for id in bookmarkedIDs {
                group.addTask { try? await self.fetchArticle(id: id) }
            }
            return try await group.reduce(into: []) { if let a = $1 { $0.append(a) } }
        }
    }

    // MARK: - Products

    func fetchProducts(
        page: Int,
        pageSize: Int,
        category: Product.ProductCategory?,
        isFree: Bool?
    ) async throws -> PaginatedResult<Product> {
        let endpoint = APIEndpoint.products(
            page: page,
            pageSize: pageSize,
            category: category?.rawValue,
            isFree: isFree
        )
        let response: ProductListResponse = try await client.request(endpoint)
        return PaginatedResult(
            items: response.items.map { $0.toDomain() },
            totalCount: response.totalCount,
            currentPage: response.currentPage,
            pageSize: response.pageSize
        )
    }

    func fetchProduct(id: String) async throws -> Product {
        let dto: ProductDTO = try await client.request(.product(id: id))
        return dto.toDomain()
    }

    func fetchFeaturedProducts() async throws -> [Product] {
        // Fetch first page of products and filter featured ones
        let result = try await fetchProducts(page: 1, pageSize: 20, category: nil, isFree: nil)
        return result.items.filter { $0.isFeatured }
    }

    func downloadProduct(id: String) async throws -> URL {
        let response: ProductDownloadResponse = try await client.request(.productDownload(id: id))
        guard let url = URL(string: response.downloadUrl) else {
            throw NetworkError.noData
        }
        return try await downloadFile(from: url, filename: "\(id).pdf")
    }

    // MARK: - Private

    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func downloadFile(from url: URL, filename: String) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NetworkError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
        let destination = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }
}
