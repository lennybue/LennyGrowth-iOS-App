import Foundation

final class AIRepository: AIRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL: URL

    init(apiClient: APIClientProtocol, baseURL: URL) {
        self.apiClient = apiClient
        self.baseURL = baseURL
    }

    func generateContent(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent {
        let request = GenerateContentRequest(
            prompt: prompt,
            tone: tone.rawValue,
            platforms: platforms.map { $0.rawValue },
            context: context
        )
        let dto: GeneratedContentDTO = try await apiClient.request(.generateContent, body: request)
        return dto.toDomain()
    }

    func generateContentStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: self.baseURL.absoluteString + APIEndpoint.generateContentStream.path) else {
                        continuation.finish(throwing: NetworkError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let body = GenerateContentRequest(
                        prompt: prompt,
                        tone: tone.rawValue,
                        platforms: platforms.map { $0.rawValue },
                        context: context
                    )
                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    request.httpBody = try encoder.encode(body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: NetworkError.serverError(statusCode: 500, message: nil))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            if let jsonData = data.data(using: .utf8),
                               let event = try? JSONDecoder().decode(StreamChunk.self, from: jsonData) {
                                continuation.yield(event.content)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func rewriteContent(content: String, tone: AITone, instruction: String) async throws -> String {
        let request = RewriteContentRequest(content: content, tone: tone.rawValue, instruction: instruction)
        let response: RewriteContentResponse = try await apiClient.request(.rewriteContent, body: request)
        return response.content
    }

    func generateHashtags(content: String, platforms: [SocialPlatform]) async throws -> [String] {
        let request = GenerateHashtagsRequest(content: content, platforms: platforms.map { $0.rawValue })
        let response: GenerateHashtagsResponse = try await apiClient.request(.generateHashtags, body: request)
        return response.hashtags
    }

    func analyzeSentiment(content: String) async throws -> SentimentAnalysis {
        let request = AnalyzeSentimentRequest(content: content)
        let dto: SentimentAnalysisDTO = try await apiClient.request(.analyzeSentiment, body: request)
        return dto.toDomain()
    }

    func suggestBestPostingTime(platform: SocialPlatform) async throws -> [Date] {
        let response: PostingTimesResponse = try await apiClient.request(
            .suggestPostingTimes(platform: platform.rawValue),
            body: nil
        )
        return response.toDomain()
    }
}

private struct StreamChunk: Decodable {
    let content: String
    let isFinished: Bool?
}
