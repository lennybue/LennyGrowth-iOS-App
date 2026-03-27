import Foundation

protocol FetchProductsUseCaseProtocol {
    func execute(page: Int, pageSize: Int, category: Product.ProductCategory?, isFree: Bool?) async throws -> PaginatedResult<Product>
    func fetchProduct(id: String) async throws -> Product
    func fetchFeatured() async throws -> [Product]
    func downloadProduct(id: String) async throws -> URL
}

final class FetchProductsUseCase: FetchProductsUseCaseProtocol {
    private let contentRepository: ContentRepositoryProtocol

    init(contentRepository: ContentRepositoryProtocol) {
        self.contentRepository = contentRepository
    }

    func execute(page: Int, pageSize: Int, category: Product.ProductCategory?, isFree: Bool?) async throws -> PaginatedResult<Product> {
        return try await contentRepository.fetchProducts(
            page: max(1, page),
            pageSize: min(50, max(1, pageSize)),
            category: category,
            isFree: isFree
        )
    }

    func fetchProduct(id: String) async throws -> Product {
        guard !id.isEmpty else {
            throw ContentError.invalidID
        }
        return try await contentRepository.fetchProduct(id: id)
    }

    func fetchFeatured() async throws -> [Product] {
        return try await contentRepository.fetchFeaturedProducts()
    }

    func downloadProduct(id: String) async throws -> URL {
        guard !id.isEmpty else {
            throw ContentError.invalidID
        }
        return try await contentRepository.downloadProduct(id: id)
    }
}
