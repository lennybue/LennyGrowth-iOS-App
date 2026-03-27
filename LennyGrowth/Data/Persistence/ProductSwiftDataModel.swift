import Foundation
import SwiftData

@Model
final class ProductSwiftDataModel {
    @Attribute(.unique) var id: String
    var name: String
    var productDescription: String
    var shortDescription: String
    var priceValue: Double?
    var currency: String
    var isFree: Bool
    var categoryRaw: String
    var imageURLString: String?
    var downloadURLString: String?
    var previewURLString: String?
    var tags: [String]
    var rating: Double?
    var reviewCount: Int
    var downloadCount: Int
    var fileTypeRaw: String?
    var fileSize: Int?
    var createdAt: Date
    var updatedAt: Date?
    var isNew: Bool
    var isFeatured: Bool
    var cachedAt: Date

    init(
        id: String,
        name: String,
        productDescription: String,
        shortDescription: String,
        priceValue: Double? = nil,
        currency: String = "USD",
        isFree: Bool = true,
        categoryRaw: String,
        imageURLString: String? = nil,
        downloadURLString: String? = nil,
        previewURLString: String? = nil,
        tags: [String] = [],
        rating: Double? = nil,
        reviewCount: Int = 0,
        downloadCount: Int = 0,
        fileTypeRaw: String? = nil,
        fileSize: Int? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        isNew: Bool = false,
        isFeatured: Bool = false,
        cachedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.productDescription = productDescription
        self.shortDescription = shortDescription
        self.priceValue = priceValue
        self.currency = currency
        self.isFree = isFree
        self.categoryRaw = categoryRaw
        self.imageURLString = imageURLString
        self.downloadURLString = downloadURLString
        self.previewURLString = previewURLString
        self.tags = tags
        self.rating = rating
        self.reviewCount = reviewCount
        self.downloadCount = downloadCount
        self.fileTypeRaw = fileTypeRaw
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isNew = isNew
        self.isFeatured = isFeatured
        self.cachedAt = cachedAt
    }

    func toDomain() -> Product {
        Product(
            id: id,
            name: name,
            description: productDescription,
            shortDescription: shortDescription,
            price: priceValue.map { Decimal($0) },
            currency: currency,
            isFree: isFree,
            category: Product.ProductCategory(rawValue: categoryRaw) ?? .guide,
            imageURL: imageURLString.flatMap { URL(string: $0) },
            downloadURL: downloadURLString.flatMap { URL(string: $0) },
            previewURL: previewURLString.flatMap { URL(string: $0) },
            tags: tags,
            rating: rating,
            reviewCount: reviewCount,
            downloadCount: downloadCount,
            fileType: fileTypeRaw.flatMap { Product.ProductFileType(rawValue: $0) },
            fileSize: fileSize,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isNew: isNew,
            isFeatured: isFeatured
        )
    }

    static func from(_ product: Product) -> ProductSwiftDataModel {
        ProductSwiftDataModel(
            id: product.id,
            name: product.name,
            productDescription: product.description,
            shortDescription: product.shortDescription,
            priceValue: product.price.map { (($0 as NSDecimalNumber).doubleValue) },
            currency: product.currency,
            isFree: product.isFree,
            categoryRaw: product.category.rawValue,
            imageURLString: product.imageURL?.absoluteString,
            downloadURLString: product.downloadURL?.absoluteString,
            previewURLString: product.previewURL?.absoluteString,
            tags: product.tags,
            rating: product.rating,
            reviewCount: product.reviewCount,
            downloadCount: product.downloadCount,
            fileTypeRaw: product.fileType?.rawValue,
            fileSize: product.fileSize,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            isNew: product.isNew,
            isFeatured: product.isFeatured,
            cachedAt: Date()
        )
    }
}
