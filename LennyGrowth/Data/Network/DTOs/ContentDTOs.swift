import Foundation

// MARK: - Paginated Response

struct PaginatedResponseDTO<T: Decodable>: Decodable {
    let items: [T]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
}

// MARK: - Article DTOs

struct ArticleDTO: Decodable {
    let id: String
    let title: String
    let summary: String
    let content: String
    let author: ArticleAuthorDTO
    let publishedAt: String
    let updatedAt: String?
    let imageUrl: URL?
    let tags: [String]
    let category: String
    let readTimeMinutes: Int
    let sourceUrl: URL?
    let isFeatured: Bool
    let isBookmarked: Bool

    func toDomain() -> Article {
        let formatter = ISO8601DateFormatter()
        return Article(
            id: id,
            title: title,
            summary: summary,
            content: content,
            author: author.toDomain(),
            publishedAt: formatter.date(from: publishedAt) ?? Date(),
            updatedAt: updatedAt.flatMap { formatter.date(from: $0) },
            imageURL: imageUrl,
            tags: tags,
            category: Article.ArticleCategory(rawValue: category) ?? .marketing,
            readTimeMinutes: readTimeMinutes,
            sourceURL: sourceUrl,
            isFeatured: isFeatured,
            isBookmarked: isBookmarked
        )
    }
}

struct ArticleAuthorDTO: Decodable {
    let id: String
    let name: String
    let bio: String?
    let avatarUrl: URL?

    func toDomain() -> ArticleAuthor {
        ArticleAuthor(id: id, name: name, bio: bio, avatarURL: avatarUrl)
    }
}

// MARK: - Product DTOs

struct ProductDTO: Decodable {
    let id: String
    let name: String
    let description: String
    let shortDescription: String
    let price: Double?
    let currency: String
    let isFree: Bool
    let category: String
    let imageUrl: URL?
    let downloadUrl: URL?
    let previewUrl: URL?
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
        let formatter = ISO8601DateFormatter()
        return Product(
            id: id,
            name: name,
            description: description,
            shortDescription: shortDescription,
            price: price.map { Decimal($0) },
            currency: currency,
            isFree: isFree,
            category: Product.ProductCategory(rawValue: category) ?? .guide,
            imageURL: imageUrl,
            downloadURL: downloadUrl,
            previewURL: previewUrl,
            tags: tags,
            rating: rating,
            reviewCount: reviewCount,
            downloadCount: downloadCount,
            fileType: fileType.flatMap { Product.ProductFileType(rawValue: $0) },
            fileSize: fileSize,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: updatedAt.flatMap { formatter.date(from: $0) },
            isNew: isNew,
            isFeatured: isFeatured
        )
    }
}

// MARK: - Download Response

struct DownloadURLResponse: Decodable {
    let downloadUrl: URL
    let expiresAt: String
}
