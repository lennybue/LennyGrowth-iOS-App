import Foundation

final class MockAIRepository: AIRepositoryProtocol {

    func generateContent(
        prompt: String,
        tone: AITone,
        platforms: [SocialPlatform],
        context: String?
    ) async throws -> GeneratedContent {
        try await Task.sleep(nanoseconds: 900_000_000)
        let platform = platforms.first ?? .linkedin
        let text = mockGeneratedPost(platform: platform, tone: tone, topic: prompt)
        return GeneratedContent(
            mainContent: text,
            platformVariants: buildVariants(text: text, platforms: platforms, tone: tone),
            suggestedHashtags: mockHashtags(for: prompt),
            estimatedEngagement: "Hoch (2–4 %)",
            alternativeVersions: []
        )
    }

    func generateContentStream(
        prompt: String,
        tone: AITone,
        platforms: [SocialPlatform],
        context: String?
    ) -> AsyncThrowingStream<String, Error> {
        let platform = platforms.first ?? .linkedin
        let fullText = mockGeneratedPost(platform: platform, tone: tone, topic: prompt)
        let words = fullText.components(separatedBy: " ")

        return AsyncThrowingStream { continuation in
            Task {
                for word in words {
                    try await Task.sleep(nanoseconds: 45_000_000)
                    continuation.yield(word + " ")
                }
                continuation.finish()
            }
        }
    }

    func rewriteContent(content: String, tone: AITone, instruction: String) async throws -> String {
        try await Task.sleep(nanoseconds: 700_000_000)
        return "✍️ [\(tone.displayName)]\n\n\(content.prefix(150))...\n\n→ Überarbeitet gemäß: \(instruction)"
    }

    func generateHashtags(content: String, platforms: [SocialPlatform]) async throws -> [String] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockHashtags(for: content)
    }

    func analyzeSentiment(content: String) async throws -> SentimentAnalysis {
        try await Task.sleep(nanoseconds: 400_000_000)
        return SentimentAnalysis(
            sentiment: .positive,
            confidence: 0.88,
            toneBreakdown: ["Professionell": 0.6, "Motivierend": 0.3, "Informativ": 0.1]
        )
    }

    func suggestBestPostingTime(platform: SocialPlatform) async throws -> [Date] {
        try await Task.sleep(nanoseconds: 300_000_000)
        let cal = Calendar.current
        var result: [Date] = []
        for dayOffset in 0..<7 {
            guard var components = cal.dateComponents(
                [.year, .month, .day],
                from: .now.addingTimeInterval(TimeInterval(dayOffset * 86400))
            ) as DateComponents? else { continue }
            let weekday = cal.component(.weekday, from: .now.addingTimeInterval(TimeInterval(dayOffset * 86400)))
            if [3, 4, 5].contains(weekday) { // Tue–Thu
                components.hour = 9
                components.minute = 0
                if let date = cal.date(from: components) { result.append(date) }
            }
        }
        return result
    }

    // MARK: - Private helpers

    private func buildVariants(text: String, platforms: [SocialPlatform], tone: AITone) -> [String: String] {
        var variants: [String: String] = [:]
        for platform in platforms {
            if platform == .threads {
                variants[platform.rawValue] = String(text.prefix(Constants.Threads.maxCharacters))
            } else {
                variants[platform.rawValue] = text
            }
        }
        return variants
    }

    private func mockGeneratedPost(platform: SocialPlatform, tone: AITone, topic: String) -> String {
        switch platform {
        case .linkedin:
            return """
            Ich habe etwas über \(topic) gelernt, das mein Denken verändert hat.

            Viele Marketer machen denselben Fehler: Sie starten mit Features, nicht mit dem Problem.

            3 Dinge, die ich dabei gelernt habe:

            → Daten sind dein bester Freund
            → Konsistenz schlägt Perfektion
            → Community > Reichweite

            Was ist deine größte Lektion in diesem Bereich?

            (Den Link zur tieferen Analyse findest du im ersten Kommentar 👇)
            """
        case .threads:
            return """
            Hot take über \(topic):

            Die meisten unterschätzen den Compounding-Effekt.

            30 Tage Konsistenz > 1 viraler Post.

            → Mehr dazu: Link in Bio 🔗
            """
        default:
            return "Spannende Insights zu \(topic) – bald mehr dazu. #\(topic.replacingOccurrences(of: " ", with: ""))"
        }
    }

    private func mockHashtags(for topic: String) -> [String] {
        ["#marketing", "#digitalmarketing", "#seo", "#contentmarketing",
         "#wachstum", "#linkedintips", "#growthmarketing", "#dachmarketing",
         "#onlinemarketing", "#socialmedia"].shuffled().prefix(6).map { $0 }
    }
}
