import Foundation

protocol AIRepositoryProtocol {
    func generateContent(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent
    func generateContentStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error>
    func rewriteContent(content: String, tone: AITone, instruction: String) async throws -> String
    func generateHashtags(content: String, platforms: [SocialPlatform]) async throws -> [String]
    func analyzeSentiment(content: String) async throws -> SentimentAnalysis
    func suggestBestPostingTime(platform: SocialPlatform) async throws -> [Date]
}

enum AITone: String, Codable, CaseIterable, Identifiable {
    case professional = "professional"
    case casual = "casual"
    case humorous = "humorous"
    case inspirational = "inspirational"
    case educational = "educational"
    case promotional = "promotional"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .humorous: return "Humorous"
        case .inspirational: return "Inspirational"
        case .educational: return "Educational"
        case .promotional: return "Promotional"
        }
    }

    var emoji: String {
        switch self {
        case .professional: return "💼"
        case .casual: return "😊"
        case .humorous: return "😄"
        case .inspirational: return "✨"
        case .educational: return "📚"
        case .promotional: return "📣"
        }
    }
}

struct GeneratedContent: Codable {
    var mainContent: String
    var platformVariants: [String: String]
    var suggestedHashtags: [String]
    var estimatedEngagement: String?
    var alternativeVersions: [String]
}

struct SentimentAnalysis: Codable {
    var sentiment: Sentiment
    var confidence: Double
    var toneBreakdown: [String: Double]

    enum Sentiment: String, Codable {
        case positive, neutral, negative
    }
}
