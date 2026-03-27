import Foundation

protocol GenerateContentUseCaseProtocol {
    func generate(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent
    func generateStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error>
    func rewrite(content: String, tone: AITone, instruction: String) async throws -> String
    func generateHashtags(for content: String, platforms: [SocialPlatform]) async throws -> [String]
    func suggestBestTimes(for platform: SocialPlatform) async throws -> [Date]
}

final class GenerateContentUseCase: GenerateContentUseCaseProtocol {
    private let aiRepository: AIRepositoryProtocol

    init(aiRepository: AIRepositoryProtocol) {
        self.aiRepository = aiRepository
    }

    func generate(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw AIError.emptyPrompt
        }
        guard !platforms.isEmpty else {
            throw PostError.noPlatformsSelected
        }
        return try await aiRepository.generateContent(prompt: trimmedPrompt, tone: tone, platforms: platforms, context: context)
    }

    func generateStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error> {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: AIError.emptyPrompt)
            }
        }
        return aiRepository.generateContentStream(prompt: trimmedPrompt, tone: tone, platforms: platforms, context: context)
    }

    func rewrite(content: String, tone: AITone, instruction: String) async throws -> String {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIError.emptyContent
        }
        return try await aiRepository.rewriteContent(content: content, tone: tone, instruction: instruction)
    }

    func generateHashtags(for content: String, platforms: [SocialPlatform]) async throws -> [String] {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIError.emptyContent
        }
        return try await aiRepository.generateHashtags(content: content, platforms: platforms)
    }

    func suggestBestTimes(for platform: SocialPlatform) async throws -> [Date] {
        return try await aiRepository.suggestBestPostingTime(platform: platform)
    }
}

enum AIError: LocalizedError {
    case emptyPrompt
    case emptyContent
    case generationFailed
    case rateLimitExceeded
    case streamInterrupted

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Please enter a prompt to generate content."
        case .emptyContent:
            return "Content cannot be empty."
        case .generationFailed:
            return "AI content generation failed. Please try again."
        case .rateLimitExceeded:
            return "You've reached your AI generation limit for this month. Upgrade to Pro for more generations."
        case .streamInterrupted:
            return "Content generation was interrupted. Please try again."
        }
    }
}
