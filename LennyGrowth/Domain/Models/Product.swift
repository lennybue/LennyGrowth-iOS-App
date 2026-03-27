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
    static func mockList() -> [Product] {
        [mockFree1(), mockFree2(), mockFree3(), mockFree4(), mockFree5(), mockPaid()]
    }

    private static func mockFree1() -> Product {
        Product(
            id: "product_free_1",
            name: "50+ KI-Prompts für Marketer",
            description: "Die besten KI-Prompts für Content-Erstellung, SEO-Texte, Ad-Copies und mehr. Sofort einsatzbereit für ChatGPT und Claude.",
            shortDescription: "Sofort einsatzbereit für ChatGPT & Claude",
            price: nil, currency: "EUR", isFree: true,
            category: .swipeFile,
            imageURL: URL(string: "https://picsum.photos/seed/prod1/400/300"),
            downloadURL: nil, previewURL: nil,
            tags: ["ki", "prompts", "marketing", "chatgpt"],
            rating: 4.9, reviewCount: 312, downloadCount: 8240,
            fileType: .pdf, fileSize: 2 * 1024 * 1024,
            createdAt: Date().addingTimeInterval(-60 * 86400), updatedAt: nil,
            isNew: false, isFeatured: true
        )
    }

    private static func mockFree2() -> Product {
        Product(
            id: "product_free_2",
            name: "AI Growth Playbook – 30 Tage Experimente",
            description: "30-Tage-Experiment-Plan für datengetriebenes Wachstum mit KI-Tools.",
            shortDescription: "30-Tage Wachstums-Experimente mit KI",
            price: nil, currency: "EUR", isFree: true,
            category: .guide,
            imageURL: URL(string: "https://picsum.photos/seed/prod2/400/300"),
            downloadURL: nil, previewURL: nil,
            tags: ["growth", "ki", "playbook"],
            rating: 4.7, reviewCount: 189, downloadCount: 5120,
            fileType: .pdf, fileSize: 3 * 1024 * 1024,
            createdAt: Date().addingTimeInterval(-45 * 86400), updatedAt: nil,
            isNew: false, isFeatured: true
        )
    }

    private static func mockFree3() -> Product {
        Product(
            id: "product_free_3",
            name: "SEO-Checkliste 2026",
            description: "Vollständige On-Page und Off-Page SEO-Checkliste für maximale Sichtbarkeit.",
            shortDescription: "On-Page & Off-Page SEO kompakt",
            price: nil, currency: "EUR", isFree: true,
            category: .checklist,
            imageURL: URL(string: "https://picsum.photos/seed/prod3/400/300"),
            downloadURL: nil, previewURL: nil,
            tags: ["seo", "checkliste", "onpage"],
            rating: 4.8, reviewCount: 445, downloadCount: 12300,
            fileType: .pdf, fileSize: 1024 * 1024,
            createdAt: Date().addingTimeInterval(-30 * 86400), updatedAt: nil,
            isNew: false, isFeatured: false
        )
    }

    private static func mockFree4() -> Product {
        Product(
            id: "product_free_4",
            name: "Google Ads Audit Template",
            description: "Strukturiertes Template für einen vollständigen Google Ads Account Audit.",
            shortDescription: "Account-Audit leicht gemacht",
            price: nil, currency: "EUR", isFree: true,
            category: .template,
            imageURL: URL(string: "https://picsum.photos/seed/prod4/400/300"),
            downloadURL: nil, previewURL: nil,
            tags: ["google ads", "audit", "template"],
            rating: 4.6, reviewCount: 98, downloadCount: 3200,
            fileType: .googleDocs, fileSize: 512 * 1024,
            createdAt: Date().addingTimeInterval(-20 * 86400), updatedAt: nil,
            isNew: true, isFeatured: false
        )
    }

    private static func mockFree5() -> Product {
        Product(
            id: "product_free_5",
            name: "Content-Marketing-Kalender",
            description: "Jahresplanung für deinen Content: Blog, LinkedIn, Threads, E-Mail.",
            shortDescription: "Jahresplanung für alle Kanäle",
            price: nil, currency: "EUR", isFree: true,
            category: .template,
            imageURL: URL(string: "https://picsum.photos/seed/prod5/400/300"),
            downloadURL: nil, previewURL: nil,
            tags: ["content", "kalender", "planung"],
            rating: 4.5, reviewCount: 231, downloadCount: 6700,
            fileType: .googleDocs, fileSize: 768 * 1024,
            createdAt: Date().addingTimeInterval(-15 * 86400), updatedAt: nil,
            isNew: false, isFeatured: false
        )
    }

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
