import Foundation

@MainActor
final class AIAssistantViewModel: ObservableObject {
    // MARK: - State
    @Published var prompt: String = ""
    @Published var selectedTone: AITone = .professional
    @Published var selectedPlatform: SocialPlatform = .linkedin
    @Published var streamingText: String = ""
    @Published var isGenerating: Bool = false
    @Published var error: Error? = nil
    @Published var generatedContent: GeneratedContent? = nil
    @Published var suggestedHashtags: [String] = []

    // MARK: - Template prompts
    let templates: [(icon: String, title: String, prompt: String)] = [
        ("person.badge.key", "LinkedIn Goldformat – Confession Hook",
         "Schreibe einen LinkedIn-Post im Goldformat: Confession-Hook → Kontrast → 3 Learnings → CTA"),
        ("chart.bar.xaxis", "Threads Hook – Daten-Fakt mit Twist",
         "Schreibe einen Threads-Post mit einem überraschenden Daten-Fakt und einem unerwarteten Twist"),
        ("list.number", "5-Punkte-Listicle für LinkedIn",
         "Schreibe einen 5-Punkte-Listicle-Post für LinkedIn mit konkreten Marketing-Tipps"),
        ("arrow.triangle.2.circlepath", "Story-Post: Fehler + Learnings",
         "Schreibe einen persönlichen Story-Post über einen Marketing-Fehler und was ich daraus gelernt habe"),
        ("tag", "Product-CTA Post (1x pro 5 Posts)",
         "Schreibe einen subtilen Product-CTA-Post, der einen Mehrwert bietet ohne zu pushy zu sein"),
    ]

    private let aiRepository: any AIRepositoryProtocol
    private var generationTask: Task<Void, Never>? = nil

    init(aiRepository: any AIRepositoryProtocol) {
        self.aiRepository = aiRepository
    }

    // MARK: - Actions

    func applyTemplate(_ template: (icon: String, title: String, prompt: String)) {
        prompt = template.prompt
    }

    func generate() async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        generationTask?.cancel()
        isGenerating = true
        streamingText = ""
        error = nil
        generatedContent = nil

        generationTask = Task {
            let stream = aiRepository.generateContentStream(
                prompt: prompt,
                tone: selectedTone,
                platforms: [selectedPlatform],
                context: nil
            )
            do {
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    streamingText += chunk
                }
                if !Task.isCancelled {
                    generatedContent = GeneratedContent(
                        mainContent: streamingText,
                        platformVariants: [:],
                        suggestedHashtags: [],
                        estimatedEngagement: nil,
                        alternativeVersions: []
                    )
                    // Fetch hashtags concurrently
                    let hashtags = try await aiRepository.generateHashtags(
                        content: streamingText,
                        platforms: [selectedPlatform]
                    )
                    suggestedHashtags = hashtags
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                }
            }
            isGenerating = false
        }
    }

    func regenerate() async {
        streamingText = ""
        await generate()
    }

    func cancelGeneration() {
        generationTask?.cancel()
        isGenerating = false
    }

    func clear() {
        streamingText = ""
        generatedContent = nil
        suggestedHashtags = []
    }
}
