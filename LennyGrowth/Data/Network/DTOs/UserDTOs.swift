import Foundation

// MARK: - AI Request DTOs

struct GenerateContentRequest: Encodable {
    let prompt: String
    let tone: String
    let platforms: [String]
    let context: String?
}

struct RewriteContentRequest: Encodable {
    let content: String
    let tone: String
    let instruction: String
}

struct GenerateHashtagsRequest: Encodable {
    let content: String
    let platforms: [String]
}

struct AnalyzeSentimentRequest: Encodable {
    let content: String
}

// MARK: - AI Response DTOs

struct GeneratedContentDTO: Decodable {
    let mainContent: String
    let platformVariants: [String: String]
    let suggestedHashtags: [String]
    let estimatedEngagement: String?
    let alternativeVersions: [String]

    func toDomain() -> GeneratedContent {
        GeneratedContent(
            mainContent: mainContent,
            platformVariants: platformVariants,
            suggestedHashtags: suggestedHashtags,
            estimatedEngagement: estimatedEngagement,
            alternativeVersions: alternativeVersions
        )
    }
}

struct RewriteContentResponse: Decodable {
    let content: String
}

struct GenerateHashtagsResponse: Decodable {
    let hashtags: [String]
}

struct SentimentAnalysisDTO: Decodable {
    let sentiment: String
    let confidence: Double
    let toneBreakdown: [String: Double]

    func toDomain() -> SentimentAnalysis {
        SentimentAnalysis(
            sentiment: SentimentAnalysis.Sentiment(rawValue: sentiment) ?? .neutral,
            confidence: confidence,
            toneBreakdown: toneBreakdown
        )
    }
}

struct PostingTimesResponse: Decodable {
    let times: [String]

    func toDomain() -> [Date] {
        let formatter = ISO8601DateFormatter()
        return times.compactMap { formatter.date(from: $0) }
    }
}

// MARK: - Subscription DTOs

struct SubscriptionDTO: Decodable {
    let tier: String
    let expiresAt: String?
    let features: [String]

    func toTier() -> User.SubscriptionTier {
        User.SubscriptionTier(rawValue: tier) ?? .free
    }
}
