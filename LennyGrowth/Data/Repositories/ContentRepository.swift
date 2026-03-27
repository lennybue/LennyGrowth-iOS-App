import Foundation
import SwiftData

final class ContentRepository: ContentRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let modelContext: ModelContext

    init(apiClient: APIClientProtocol, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    func fetchArticles(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article> {
        do {
            let response: PaginatedResponseDTO<ArticleDTO> = try await apiClient.request(
                .articles(page: page, pageSize: pageSize, category: category?.rawValue, searchQuery: searchQuery),
                body: nil
            )
            let articles = response.items.map { $0.toDomain() }
            await cacheArticles(articles)
            return PaginatedResult(
                items: articles,
                totalCount: response.totalCount,
                currentPage: response.currentPage,
                pageSize: response.pageSize
            )
        } catch let error as NetworkError {
            if case .noInternetConnection = error {
                let cached = try fetchCachedArticles(category: category, searchQuery: searchQuery)
                let sliced = Array(cached.dropFirst((page - 1) * pageSize).prefix(pageSize))
                return PaginatedResult(items: sliced, totalCount: cached.count, currentPage: page, pageSize: pageSize)
            }
            throw error
        }
    }

    func fetchArticle(id: String) async throws -> Article {
        do {
            let dto: ArticleDTO = try await apiClient.request(.article(id: id), body: nil)
            return dto.toDomain()
        } catch let error as NetworkError {
            if case .noInternetConnection = error, let cached = fetchCachedArticle(id: id) {
                return cached
            }
            throw error
        }
    }

    func toggleBookmark(articleID: String) async throws -> Article {
        let dto: ArticleDTO = try await apiClient.request(.toggleBookmark(articleID: articleID), body: nil)
        let article = dto.toDomain()
        await updateCachedArticle(article)
        return article
    }

    func fetchBookmarkedArticles() async throws -> [Article] {
        let dtos: [ArticleDTO] = try await apiClient.request(.bookmarkedArticles, body: nil)
        return dtos.map { $0.toDomain() }
    }

    func fetchProducts(page: Int, pageSize: Int, category: Product.ProductCategory?, isFree: Bool?) async throws -> PaginatedResult<Product> {
        do {
            let response: PaginatedResponseDTO<ProductDTO> = try await apiClient.request(
                .products(page: page, pageSize: pageSize, category: category?.rawValue, isFree: isFree),
                body: nil
            )
            let products = response.items.map { $0.toDomain() }
            await cacheProducts(products)
            return PaginatedResult(
                items: products,
                totalCount: response.totalCount,
                currentPage: response.currentPage,
                pageSize: response.pageSize
            )
        } catch let error as NetworkError {
            if case .noInternetConnection = error {
                let cached = try fetchCachedProducts(category: category, isFree: isFree)
                let sliced = Array(cached.dropFirst((page - 1) * pageSize).prefix(pageSize))
                return PaginatedResult(items: sliced, totalCount: cached.count, currentPage: page, pageSize: pageSize)
            }
            throw error
        }
    }

    func fetchProduct(id: String) async throws -> Product {
        do {
            let dto: ProductDTO = try await apiClient.request(.product(id: id), body: nil)
            return dto.toDomain()
        } catch let error as NetworkError {
            if case .noInternetConnection = error, let cached = fetchCachedProduct(id: id) {
                return cached
            }
            throw error
        }
    }

    func fetchFeaturedProducts() async throws -> [Product] {
        let dtos: [ProductDTO] = try await apiClient.request(.featuredProducts, body: nil)
        return dtos.map { $0.toDomain() }
    }

    func downloadProduct(id: String) async throws -> URL {
        let response: DownloadURLResponse = try await apiClient.request(.downloadProduct(id: id), body: nil)
        return response.downloadUrl
    }

    // MARK: - Cache Management

    @MainActor
    private func cacheArticles(_ articles: [Article]) {
        for article in articles {
            let model = ArticleSwiftDataModel.from(article)
            let descriptor = FetchDescriptor<ArticleSwiftDataModel>(
                predicate: #Predicate { $0.id == article.id }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.title = model.title
                existing.summary = model.summary
                existing.content = model.content
                existing.isBookmarked = model.isBookmarked
                existing.isFeatured = model.isFeatured
                existing.cachedAt = Date()
            } else {
                modelContext.insert(model)
            }
        }
        try? modelContext.save()
    }

    @MainActor
    private func cacheProducts(_ products: [Product]) {
        for product in products {
            let model = ProductSwiftDataModel.from(product)
            let descriptor = FetchDescriptor<ProductSwiftDataModel>(
                predicate: #Predicate { $0.id == product.id }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.name = model.name
                existing.productDescription = model.productDescription
                existing.rating = model.rating
                existing.downloadCount = model.downloadCount
                existing.cachedAt = Date()
            } else {
                modelContext.insert(model)
            }
        }
        try? modelContext.save()
    }

    @MainActor
    private func updateCachedArticle(_ article: Article) {
        let descriptor = FetchDescriptor<ArticleSwiftDataModel>(
            predicate: #Predicate { $0.id == article.id }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.isBookmarked = article.isBookmarked
            try? modelContext.save()
        }
    }

    private func fetchCachedArticles(category: Article.ArticleCategory?, searchQuery: String?) throws -> [Article] {
        let descriptor = FetchDescriptor<ArticleSwiftDataModel>(
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all
            .filter { model in
                if let cat = category, model.categoryRaw != cat.rawValue { return false }
                if let query = searchQuery, !query.isEmpty {
                    return model.title.localizedCaseInsensitiveContains(query) ||
                           model.summary.localizedCaseInsensitiveContains(query)
                }
                return true
            }
            .map { $0.toDomain() }
    }

    private func fetchCachedArticle(id: String) -> Article? {
        let descriptor = FetchDescriptor<ArticleSwiftDataModel>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor).first)?.toDomain()
    }

    private func fetchCachedProducts(category: Product.ProductCategory?, isFree: Bool?) throws -> [Product] {
        let descriptor = FetchDescriptor<ProductSwiftDataModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all
            .filter { model in
                if let cat = category, model.categoryRaw != cat.rawValue { return false }
                if let free = isFree, model.isFree != free { return false }
                return true
            }
            .map { $0.toDomain() }
    }

    private func fetchCachedProduct(id: String) -> Product? {
        let descriptor = FetchDescriptor<ProductSwiftDataModel>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor).first)?.toDomain()
    }
}
