import Foundation
import CoreSpotlight

final class SpotlightManager {

    static let shared = SpotlightManager()
    private init() {}

    private let domainIdentifier = "com.lennardbuessow.lennygrowth"

    // MARK: – Articles

    func indexArticles(_ articles: [Article]) {
        let items: [CSSearchableItem] = articles.map { article in
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title             = article.title
            attrs.contentDescription = article.summary
            attrs.keywords          = article.tags
            attrs.thumbnailURL      = article.imageUrl.flatMap { URL(string: $0) }
            return CSSearchableItem(
                uniqueIdentifier: "article_\(article.id)",
                domainIdentifier: "\(domainIdentifier).articles",
                attributeSet: attrs
            )
        }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error { print("Spotlight articles indexing error: \(error)") }
        }
    }

    // MARK: – Products

    func indexProducts(_ products: [Product]) {
        let items: [CSSearchableItem] = products.map { product in
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title             = product.name
            attrs.contentDescription = product.shortDescription
            attrs.keywords          = product.tags
            attrs.thumbnailURL      = product.imageUrl.flatMap { URL(string: $0) }
            return CSSearchableItem(
                uniqueIdentifier: "product_\(product.id)",
                domainIdentifier: "\(domainIdentifier).products",
                attributeSet: attrs
            )
        }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error { print("Spotlight products indexing error: \(error)") }
        }
    }

    // MARK: – Cleanup

    func deindexAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error { print("Spotlight deindex error: \(error)") }
        }
    }

    func deindexArticle(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["article_\(id)"]) { _ in }
    }

    func deindexProduct(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["product_\(id)"]) { _ in }
    }
}
