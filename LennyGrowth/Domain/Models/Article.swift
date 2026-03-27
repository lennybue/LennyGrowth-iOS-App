import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var summary: String
    var content: String
    var author: ArticleAuthor
    var publishedAt: Date
    var updatedAt: Date?
    var imageURL: URL?
    var tags: [String]
    var category: ArticleCategory
    var readTimeMinutes: Int
    var sourceURL: URL?
    var isFeatured: Bool
    var isBookmarked: Bool

    enum ArticleCategory: String, Codable, CaseIterable, Identifiable {
        case marketing = "marketing"
        case socialMedia = "social_media"
        case contentCreation = "content_creation"
        case analytics = "analytics"
        case seo = "seo"
        case emailMarketing = "email_marketing"
        case branding = "branding"
        case growth = "growth"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .marketing: return "Marketing"
            case .socialMedia: return "Social Media"
            case .contentCreation: return "Content Creation"
            case .analytics: return "Analytics"
            case .seo: return "SEO"
            case .emailMarketing: return "Email Marketing"
            case .branding: return "Branding"
            case .growth: return "Growth"
            }
        }

        var iconSystemName: String {
            switch self {
            case .marketing: return "megaphone"
            case .socialMedia: return "bubble.left.and.bubble.right"
            case .contentCreation: return "pencil.and.outline"
            case .analytics: return "chart.bar"
            case .seo: return "magnifyingglass"
            case .emailMarketing: return "envelope"
            case .branding: return "paintbrush"
            case .growth: return "arrow.up.right"
            }
        }
    }
}

struct ArticleAuthor: Codable, Equatable {
    let id: String
    var name: String
    var bio: String?
    var avatarURL: URL?
}

extension Article {
    static func mock() -> Article {
        Article(
            id: UUID().uuidString,
            title: "On-Page SEO: Die 7 wichtigsten Rankingfaktoren 2026",
            summary: "Entdecke die wichtigsten Rankingfaktoren und optimiere deine Website für die Suchergebnisse.",
            content: mockBody,
            author: lenny,
            publishedAt: Date().addingTimeInterval(-86400),
            updatedAt: nil,
            imageURL: URL(string: "https://picsum.photos/800/450"),
            tags: ["seo", "onpage", "ranking"],
            category: .seo,
            readTimeMinutes: 7,
            sourceURL: nil,
            isFeatured: true,
            isBookmarked: false
        )
    }

    static func mockList() -> [Article] {
        let data: [(String, String, ArticleCategory, [String], Int, Bool)] = [
            ("On-Page SEO: Die 7 wichtigsten Rankingfaktoren 2026",
             "Entdecke die wichtigsten Rankingfaktoren und optimiere deine Website für Top-Rankings.",
             .seo, ["seo", "onpage", "ranking"], 7, true),
            ("Google Ads CPA senken: 5 bewährte Strategien",
             "Mit diesen Techniken reduzierst du deinen Cost-per-Acquisition nachhaltig.",
             .marketing, ["google ads", "sea", "cpa"], 6, false),
            ("KI-gestützte Marketing-Automatisierung: Praxisguide",
             "Wie KI dein Marketing effizienter macht – von Content bis Lead-Nurturing.",
             .growth, ["ki", "automation", "marketing"], 10, true),
            ("UX-Design für höhere Conversion Rates",
             "Kleine UX-Änderungen mit großer Wirkung auf deine Conversion Rate.",
             .contentCreation, ["ux", "cro", "design"], 5, false),
            ("Google Analytics 4: Die wichtigsten KPIs für E-Commerce",
             "Welche GA4-Metriken wirklich zählen und wie du sie richtig interpretierst.",
             .analytics, ["ga4", "analytics", "kpis"], 8, false),
            ("SEO-Content schreiben: Von der Keyword-Recherche zum Top-10-Ranking",
             "Schritt für Schritt zum Google-Top-10-Ranking mit strategischem Content.",
             .seo, ["seo", "content", "keywords"], 12, true),
            ("Local SEO: Wie du in Google Maps ganz oben rankst",
             "Lokale Sichtbarkeit maximieren und mehr Kunden aus deiner Region gewinnen.",
             .seo, ["local seo", "google maps", "local marketing"], 6, false),
            ("E-Mail-Marketing-Automation: Von der Willkommens-Mail zum Upsell",
             "Automatisierte E-Mail-Sequenzen, die Leads in Kunden verwandeln.",
             .emailMarketing, ["email", "automation", "upsell"], 9, false),
            ("Conversion-Rate-Optimierung: A/B-Testing Best Practices",
             "So gestaltest du A/B-Tests, die statistisch valide Ergebnisse liefern.",
             .analytics, ["cro", "ab-testing", "conversion"], 7, true),
            ("Content-Marketing-Strategie: Vom Redaktionsplan zur Lead-Generierung",
             "Ein durchdachter Content-Plan ist dein mächtigstes Marketing-Tool.",
             .contentCreation, ["content", "strategie", "leads"], 11, false),
            ("Google Ads Quality Score verbessern: 10 sofort umsetzbare Tipps",
             "Bessere Quality Scores bedeuten günstigere Klicks und bessere Platzierungen.",
             .marketing, ["google ads", "quality score", "sea"], 8, false),
        ]

        return data.enumerated().map { i, item in
            let (title, summary, cat, tags, readTime, featured) = item
            return Article(
                id: "article_\(i + 1)",
                title: title,
                summary: summary,
                content: mockBody,
                author: lenny,
                publishedAt: Date().addingTimeInterval(TimeInterval(-(i + 1) * 86400)),
                updatedAt: nil,
                imageURL: URL(string: "https://picsum.photos/seed/\(i + 10)/800/450"),
                tags: tags,
                category: cat,
                readTimeMinutes: readTime,
                sourceURL: URL(string: "https://lennardbuessow.digital/blog/\(i + 1)"),
                isFeatured: featured,
                isBookmarked: false
            )
        }
    }

    private static var lenny: ArticleAuthor {
        ArticleAuthor(
            id: "lennard",
            name: "Lennard Büssow",
            bio: "Digital Marketing Specialist & IT-Consultant aus dem DACH-Raum",
            avatarURL: nil
        )
    }

    private static var mockBody: String {
        """
        ## Einleitung

        SEO ist kein Geheimnis – aber viele unterschätzen, wie präzise Google die Qualität einer Seite bewertet.

        In diesem Artikel zeige ich dir die wichtigsten Faktoren, auf die du dich 2026 konzentrieren solltest.

        ## 1. E-E-A-T: Expertise, Experience, Authoritativeness, Trustworthiness

        Google bewertet zunehmend, ob du wirklich der Experte bist, als der du dich ausgibst.

        **Was das bedeutet:** Zeige deine Erfahrung durch konkrete Daten, Case Studies und echte Ergebnisse.

        ## 2. Core Web Vitals

        Ladezeit, Interaktivität und visuelle Stabilität sind messbare Ranking-Signale.

        - **LCP** (Largest Contentful Paint): < 2,5 Sekunden
        - **FID** (First Input Delay): < 100 ms
        - **CLS** (Cumulative Layout Shift): < 0,1

        ## 3. Semantische Struktur

        Nutze H1–H6 sinnvoll. Verlinke intern auf relevante Unterseiten. Google versteht Kontext.

        ## Fazit

        Wer diese 7 Faktoren konsequent umsetzt, hat einen signifikanten Vorteil gegenüber 90 % der Konkurrenz.
        """
    }
}
