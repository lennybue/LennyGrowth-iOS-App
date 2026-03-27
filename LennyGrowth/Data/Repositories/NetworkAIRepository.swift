import Foundation

/// Real network implementation of AIRepositoryProtocol.
/// AI generation uses Server-Sent Events (SSE) streamed via URLSession.bytes.
/// The backend sends: `data: <text chunk>\n\n` and `data: [DONE]\n\n`
final class NetworkAIRepository: AIRepositoryProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    // MARK: - Generation (non-streaming convenience)

    func generateContent(
        prompt: String,
        tone: AITone,
        platforms: [SocialPlatform],
        context: String?
    ) async throws -> GeneratedContent {
        let response: AIGenerateResponse = try await client.request(
            .aiGenerate,
            body: AIGenerateRequest(
                prompt: prompt,
                tone: tone.rawValue,
                platforms: platforms.map { $0.rawValue },
                context: context,
                stream: false
            )
        )
        return response.toDomain()
    }

    // MARK: - Streaming generation (SSE via APIClient.stream)

    func generateContentStream(
        prompt: String,
        tone: AITone,
        platforms: [SocialPlatform],
        context: String?
    ) -> AsyncThrowingStream<String, Error> {
        client.stream(
            .aiGenerate,
            body: AIGenerateRequest(
                prompt: prompt,
                tone: tone.rawValue,
                platforms: platforms.map { $0.rawValue },
                context: context,
                stream: true
            )
        )
    }

    // MARK: - Rewrite

    func rewriteContent(content: String, tone: AITone, instruction: String) async throws -> String {
        let response: AIGenerateResponse = try await client.request(
            .aiRewrite,
            body: AIRewriteRequest(content: content, tone: tone.rawValue, instruction: instruction)
        )
        return response.mainContent
    }

    // MARK: - Hashtags

    func generateHashtags(content: String, platforms: [SocialPlatform]) async throws -> [String] {
        let response: AIHashtagsResponse = try await client.request(
            .aiHashtags,
            body: AIHashtagsRequest(content: content, platforms: platforms.map { $0.rawValue })
        )
        return response.hashtags
    }

    // MARK: - Sentiment
    // No dedicated /ai/sentiment endpoint yet — derive from text properties client-side.
    // When backend adds the endpoint, swap to a real network call.

    func analyzeSentiment(content: String) async throws -> SentimentAnalysis {
        let positiveKeywords = ["erfolgreich", "wachstum", "gewinn", "top", "best", "super", "excellent"]
        let negativeKeywords = ["fehler", "problem", "verlust", "schlecht", "failed", "error"]
        let lower = content.lowercased()
        let posHits = positiveKeywords.filter { lower.contains($0) }.count
        let negHits = negativeKeywords.filter { lower.contains($0) }.count
        let sentiment: SentimentAnalysis.Sentiment = negHits > posHits ? .negative : posHits > 0 ? .positive : .neutral
        let confidence = min(0.95, 0.6 + Double(abs(posHits - negHits)) * 0.1)
        return SentimentAnalysis(
            sentiment: sentiment,
            confidence: confidence,
            toneBreakdown: ["Professionell": 0.6, "Informativ": 0.4]
        )
    }

    // MARK: - Posting time suggestions
    // Rule-based per LinkedIn/Threads best-practice — no network call needed.

    func suggestBestPostingTime(platform: SocialPlatform) async throws -> [Date] {
        var results: [Date] = []
        let cal = Calendar.current
        for offset in 0..<14 {
            let day = Date.now.addingTimeInterval(TimeInterval(offset * 86400))
            let weekday = cal.component(.weekday, from: day) // 1=Sun
            let isOptimal: Bool
            switch platform {
            case .linkedin: isOptimal = [3, 4, 5].contains(weekday) // Tue–Thu
            case .threads:  isOptimal = [4, 5].contains(weekday)    // Wed–Thu
            default:        isOptimal = [3, 4, 5].contains(weekday)
            }
            guard isOptimal else { continue }
            var components = cal.dateComponents([.year, .month, .day], from: day)
            components.hour = 9
            components.minute = 0
            if let date = cal.date(from: components) { results.append(date) }
        }
        return results
    }
}
