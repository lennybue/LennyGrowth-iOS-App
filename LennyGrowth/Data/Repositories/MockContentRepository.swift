import Foundation

final class MockContentRepository: ContentRepositoryProtocol {
    private var bookmarkedIDs: Set<String> = []
    private let allArticles: [Article] = Article.mockList()
    private let allProducts: [Product] = Product.mockList()

    func fetchArticles(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article> {
        try await Task.sleep(nanoseconds: 600_000_000)
        var filtered = allArticles

        if let category {
            filtered = filtered.filter { $0.category == category }
        }
        if let query = searchQuery, !query.isEmpty {
            let q = query.lowercased()
            filtered = filtered.filter {
                $0.title.lowercased().contains(q) ||
                $0.summary.lowercased().contains(q) ||
                $0.tags.contains(where: { $0.lowercased().contains(q) })
            }
        }

        let start = (page - 1) * pageSize
        let end = min(start + pageSize, filtered.count)
        let slice = start < filtered.count ? Array(filtered[start..<end]) : []

        return PaginatedResult(
            items: slice,
            totalCount: filtered.count,
            currentPage: page,
            pageSize: pageSize
        )
    }

    func fetchArticle(id: String) async throws -> Article {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let article = allArticles.first(where: { $0.id == id }) else {
            throw ContentError.notFound
        }
        return article
    }

    func toggleBookmark(articleID: String) async throws -> Article {
        guard var article = allArticles.first(where: { $0.id == articleID }) else {
            throw ContentError.notFound
        }
        if bookmarkedIDs.contains(articleID) {
            bookmarkedIDs.remove(articleID)
            article.isBookmarked = false
        } else {
            bookmarkedIDs.insert(articleID)
            article.isBookmarked = true
        }
        return article
    }

    func fetchBookmarkedArticles() async throws -> [Article] {
        return allArticles.filter { bookmarkedIDs.contains($0.id) }
    }

    func fetchProducts(page: Int, pageSize: Int, category: Product.ProductCategory?, isFree: Bool?) async throws -> PaginatedResult<Product> {
        try await Task.sleep(nanoseconds: 500_000_000)
        var filtered = allProducts
        if let category { filtered = filtered.filter { $0.category == category } }
        if let isFree   { filtered = filtered.filter { $0.isFree == isFree } }

        let start = (page - 1) * pageSize
        let end = min(start + pageSize, filtered.count)
        let slice = start < filtered.count ? Array(filtered[start..<end]) : []

        return PaginatedResult(items: slice, totalCount: filtered.count, currentPage: page, pageSize: pageSize)
    }

    func fetchProduct(id: String) async throws -> Product {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let product = allProducts.first(where: { $0.id == id }) else {
            throw ContentError.notFound
        }
        return product
    }

    func fetchFeaturedProducts() async throws -> [Product] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return allProducts.filter { $0.isFeatured }
    }

    func downloadProduct(id: String) async throws -> URL {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(id).pdf")
        return url
    }
}

enum ContentError: LocalizedError {
    case notFound
    var errorDescription: String? {
        switch self { case .notFound: return String(localized: "Inhalt nicht gefunden.") }
    }
}
