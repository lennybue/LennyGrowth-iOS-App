import Foundation

struct Product: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String
    var shortDescription: String
    var price: Decimal?
    var currency: String
    var isFree: Bool
    var category: ProductCategory
    var imageURL: URL?
    var downloadURL: URL?
    var previewURL: URL?
    var tags: [String]
    var rating: Double?
    var reviewCount: Int
    var downloadCount: Int
    var fileType: ProductFileType?
    var fileSize: Int?
    var createdAt: Date
    var updatedAt: Date?
    var isNew: Bool
    var isFeatured: Bool

    var formattedPrice: String {
        if isFree { return "Free" }
        guard let price = price else { return "Free" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }

    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }
        if size < 1024 { return "\(size) B" }
        if size < 1024 * 1024 { return "\(size / 1024) KB" }
        return "\(size / (1024 * 1024)) MB"
    }

    enum ProductCategory: String, Codable, CaseIterable, Identifiable {
        case template = "template"
        case guide = "guide"
        case tool = "tool"
        case course = "course"
        case checklist = "checklist"
        case swipeFile = "swipe_file"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .template: return "Template"
            case .guide: return "Guide"
            case .tool: return "Tool"
            case .course: return "Course"
            case .checklist: return "Checklist"
            case .swipeFile: return "Swipe File"
            }
        }

        var iconSystemName: String {
            switch self {
            case .template: return "doc.text"
            case .guide: return "book"
            case .tool: return "wrench.and.screwdriver"
            case .course: return "play.rectangle"
            case .checklist: return "checklist"
            case .swipeFile: return "folder"
            }
        }
    }

    enum ProductFileType: String, Codable {
        case pdf = "pdf"
        case notion = "notion"
        case figma = "figma"
        case googleDocs = "google_docs"
        case airtable = "airtable"
        case video = "video"
        case zip = "zip"
    }
}

extension Product {
    static func mockFree() -> Product {
        Product(
            id: UUID().uuidString,
            name: "Social Media Content Calendar Template",
            description: "A comprehensive content calendar to plan and organize your social media posts across all platforms.",
            shortDescription: "Plan your content across all platforms",
            price: nil,
            currency: "USD",
            isFree: true,
            category: .template,
            imageURL: URL(string: "https://picsum.photos/400/300"),
            downloadURL: nil,
            previewURL: nil,
            tags: ["content calendar", "planning", "social media"],
            rating: 4.8,
            reviewCount: 234,
            downloadCount: 5420,
            fileType: .notion,
            fileSize: 512 * 1024,
            createdAt: Date().addingTimeInterval(-30 * 86400),
            updatedAt: nil,
            isNew: false,
            isFeatured: true
        )
    }

    static func mockPaid() -> Product {
        Product(
            id: UUID().uuidString,
            name: "The Complete Growth Hacking Playbook",
            description: "A step-by-step guide to growing your audience from 0 to 10K using proven strategies.",
            shortDescription: "Go from 0 to 10K followers with proven tactics",
            price: 29.99,
            currency: "USD",
            isFree: false,
            category: .guide,
            imageURL: URL(string: "https://picsum.photos/400/300"),
            downloadURL: nil,
            previewURL: nil,
            tags: ["growth", "strategy", "advanced"],
            rating: 4.9,
            reviewCount: 89,
            downloadCount: 1240,
            fileType: .pdf,
            fileSize: 5 * 1024 * 1024,
            createdAt: Date().addingTimeInterval(-15 * 86400),
            updatedAt: nil,
            isNew: true,
            isFeatured: true
        )
    }
}
