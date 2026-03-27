import Foundation
import SwiftData

@Model
final class ArticleSwiftDataModel {
    @Attribute(.unique) var id: String
    var title: String
    var summary: String
    var content: String
    var authorID: String
    var authorName: String
    var authorBio: String?
    var authorAvatarURLString: String?
    var publishedAt: Date
    var updatedAt: Date?
    var imageURLString: String?
    var tags: [String]
    var categoryRaw: String
    var readTimeMinutes: Int
    var sourceURLString: String?
    var isFeatured: Bool
    var isBookmarked: Bool
    var cachedAt: Date

    init(
        id: String,
        title: String,
        summary: String,
        content: String,
        authorID: String,
        authorName: String,
        authorBio: String? = nil,
        authorAvatarURLString: String? = nil,
        publishedAt: Date,
        updatedAt: Date? = nil,
        imageURLString: String? = nil,
        tags: [String] = [],
        categoryRaw: String,
        readTimeMinutes: Int,
        sourceURLString: String? = nil,
        isFeatured: Bool = false,
        isBookmarked: Bool = false,
        cachedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.authorID = authorID
        self.authorName = authorName
        self.authorBio = authorBio
        self.authorAvatarURLString = authorAvatarURLString
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.imageURLString = imageURLString
        self.tags = tags
        self.categoryRaw = categoryRaw
        self.readTimeMinutes = readTimeMinutes
        self.sourceURLString = sourceURLString
        self.isFeatured = isFeatured
        self.isBookmarked = isBookmarked
        self.cachedAt = cachedAt
    }

    func toDomain() -> Article {
        Article(
            id: id,
            title: title,
            summary: summary,
            content: content,
            author: ArticleAuthor(
                id: authorID,
                name: authorName,
                bio: authorBio,
                avatarURL: authorAvatarURLString.flatMap { URL(string: $0) }
            ),
            publishedAt: publishedAt,
            updatedAt: updatedAt,
            imageURL: imageURLString.flatMap { URL(string: $0) },
            tags: tags,
            category: Article.ArticleCategory(rawValue: categoryRaw) ?? .marketing,
            readTimeMinutes: readTimeMinutes,
            sourceURL: sourceURLString.flatMap { URL(string: $0) },
            isFeatured: isFeatured,
            isBookmarked: isBookmarked
        )
    }

    static func from(_ article: Article) -> ArticleSwiftDataModel {
        ArticleSwiftDataModel(
            id: article.id,
            title: article.title,
            summary: article.summary,
            content: article.content,
            authorID: article.author.id,
            authorName: article.author.name,
            authorBio: article.author.bio,
            authorAvatarURLString: article.author.avatarURL?.absoluteString,
            publishedAt: article.publishedAt,
            updatedAt: article.updatedAt,
            imageURLString: article.imageURL?.absoluteString,
            tags: article.tags,
            categoryRaw: article.category.rawValue,
            readTimeMinutes: article.readTimeMinutes,
            sourceURLString: article.sourceURL?.absoluteString,
            isFeatured: article.isFeatured,
            isBookmarked: article.isBookmarked,
            cachedAt: Date()
        )
    }
}
