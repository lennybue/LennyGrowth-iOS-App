import Foundation

protocol ContentRepositoryProtocol {
    func fetchArticles(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article>
    func fetchArticle(id: String) async throws -> Article
    func toggleBookmark(articleID: String) async throws -> Article
    func fetchBookmarkedArticles() async throws -> [Article]
    func fetchProducts(page: Int, pageSize: Int, category: Product.ProductCategory?, isFree: Bool?) async throws -> PaginatedResult<Product>
    func fetchProduct(id: String) async throws -> Product
    func fetchFeaturedProducts() async throws -> [Product]
    func downloadProduct(id: String) async throws -> URL
}

struct PaginatedResult<T: Codable> {
    let items: [T]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
    var hasNextPage: Bool { (currentPage * pageSize) < totalCount }
    var hasPreviousPage: Bool { currentPage > 1 }
}
