import Foundation

// MARK: - Article

struct ArticleListResponse: Decodable {
    let items: [ArticleDTO]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
}

struct ArticleDTO: Decodable {
    let id: String
    let title: String
    let summary: String
    let content: String
    let author: ArticleAuthorDTO
    let publishedAt: String
    let updatedAt: String?
    let imageUrl: String?
    let tags: [String]
    let category: String
    let readTimeMinutes: Int
    let sourceUrl: String?
    let isFeatured: Bool

    func toDomain(isBookmarked: Bool = false) -> Article {
        Article(
            id: id,
            title: title,
            summary: summary,
            content: content,
            author: author.toDomain(),
            publishedAt: parseDate(publishedAt),
            updatedAt: updatedAt.flatMap { parseDate($0) },
            imageURL: imageUrl.flatMap { URL(string: $0) },
            tags: tags,
            category: Article.ArticleCategory(rawValue: category) ?? .growth,
            readTimeMinutes: readTimeMinutes,
            sourceURL: sourceUrl.flatMap { URL(string: $0) },
            isFeatured: isFeatured,
            isBookmarked: isBookmarked
        )
    }
}

struct ArticleAuthorDTO: Decodable {
    let id: String
    let name: String
    let bio: String?
    let avatarUrl: String?

    func toDomain() -> ArticleAuthor {
        ArticleAuthor(
            id: id,
            name: name,
            bio: bio,
            avatarURL: avatarUrl.flatMap { URL(string: $0) }
        )
    }
}

// MARK: - Product

struct ProductListResponse: Decodable {
    let items: [ProductDTO]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
}

struct ProductDTO: Decodable {
    let id: String
    let name: String
    let description: String
    let shortDescription: String
    let price: Double?
    let currency: String
    let isFree: Bool
    let category: String
    let imageUrl: String?
    let downloadUrl: String?
    let previewUrl: String?
    let tags: [String]
    let rating: Double?
    let reviewCount: Int
    let downloadCount: Int
    let fileType: String?
    let fileSize: Int?
    let createdAt: String
    let updatedAt: String?
    let isNew: Bool
    let isFeatured: Bool

    func toDomain() -> Product {
        Product(
            id: id,
            name: name,
            description: description,
            shortDescription: shortDescription,
            price: price.map { Decimal($0) },
            currency: currency,
            isFree: isFree,
            category: Product.ProductCategory(rawValue: category) ?? .guide,
            imageURL: imageUrl.flatMap { URL(string: $0) },
            downloadURL: downloadUrl.flatMap { URL(string: $0) },
            previewURL: previewUrl.flatMap { URL(string: $0) },
            tags: tags,
            rating: rating,
            reviewCount: reviewCount,
            downloadCount: downloadCount,
            fileType: fileType.flatMap { Product.ProductFileType(rawValue: $0) },
            fileSize: fileSize,
            createdAt: parseDate(createdAt),
            updatedAt: updatedAt.flatMap { parseDate($0) },
            isNew: isNew,
            isFeatured: isFeatured
        )
    }
}

struct ProductDownloadResponse: Decodable {
    let downloadUrl: String
    let expiresAt: String?
}

// MARK: - Helpers

private func parseDate(_ string: String) -> Date {
    ISO8601DateFormatter().date(from: string) ?? .now
}
