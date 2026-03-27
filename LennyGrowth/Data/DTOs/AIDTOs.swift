import Foundation

// MARK: - Requests

struct AIGenerateRequest: Encodable {
    let prompt: String
    let tone: String
    let platforms: [String]
    let context: String?
    let stream: Bool
}

struct AIRewriteRequest: Encodable {
    let content: String
    let tone: String
    let instruction: String
}

struct AIHashtagsRequest: Encodable {
    let content: String
    let platforms: [String]
}

struct AICaptionRequest: Encodable {
    let imageDescription: String
    let platform: String
    let tone: String
}

struct AIVariationsRequest: Encodable {
    let content: String
    let count: Int
    let platform: String
}

// MARK: - Responses

struct AIGenerateResponse: Decodable {
    let mainContent: String
    let platformVariants: [String: String]?
    let suggestedHashtags: [String]?
    let estimatedEngagement: String?
    let alternativeVersions: [String]?

    func toDomain() -> GeneratedContent {
        GeneratedContent(
            mainContent: mainContent,
            platformVariants: platformVariants ?? [:],
            suggestedHashtags: suggestedHashtags ?? [],
            estimatedEngagement: estimatedEngagement,
            alternativeVersions: alternativeVersions ?? []
        )
    }
}

struct AIHashtagsResponse: Decodable {
    let hashtags: [String]
}

struct AISentimentResponse: Decodable {
    let sentiment: String
    let confidence: Double
    let toneBreakdown: [String: Double]?

    func toDomain() -> SentimentAnalysis {
        SentimentAnalysis(
            sentiment: SentimentAnalysis.Sentiment(rawValue: sentiment) ?? .neutral,
            confidence: confidence,
            toneBreakdown: toneBreakdown ?? [:]
        )
    }
}

struct AIPostingTimesResponse: Decodable {
    let suggestedTimes: [String]

    func toDomain() -> [Date] {
        suggestedTimes.compactMap { ISO8601DateFormatter().date(from: $0) }
    }
}

struct AIVariationsResponse: Decodable {
    let variations: [AIGenerateResponse]
}
