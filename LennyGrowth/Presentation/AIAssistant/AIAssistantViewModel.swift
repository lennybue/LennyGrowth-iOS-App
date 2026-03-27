import Foundation

@MainActor
final class AIAssistantViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var selectedTone: AITone = .professional
    @Published var selectedPlatforms: Set<SocialPlatform> = [.twitter, .linkedin]
    @Published var contextText: String = ""

    @Published private(set) var generatedContent: String = ""
    @Published private(set) var generatedResult: GeneratedContent? = nil
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var error: Error? = nil
    @Published var showContextInput: Bool = false

    private let generateContentUseCase: GenerateContentUseCaseProtocol
    private var streamTask: Task<Void, Never>?

    init(generateContentUseCase: GenerateContentUseCaseProtocol) {
        self.generateContentUseCase = generateContentUseCase
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedPlatforms.isEmpty
    }

    func generateContent() {
        streamTask?.cancel()
        generatedContent = ""
        generatedResult = nil
        error = nil
        isGenerating = true

        streamTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let stream = self.generateContentUseCase.generateStream(
                    prompt: self.prompt,
                    tone: self.selectedTone,
                    platforms: Array(self.selectedPlatforms),
                    context: self.contextText.isEmpty ? nil : self.contextText
                )

                for try await chunk in stream {
                    self.generatedContent += chunk
                }

                // After streaming, also fetch full structured result
                let fullResult = try await self.generateContentUseCase.generate(
                    prompt: self.prompt,
                    tone: self.selectedTone,
                    platforms: Array(self.selectedPlatforms),
                    context: self.contextText.isEmpty ? nil : self.contextText
                )
                self.generatedResult = fullResult
                self.generatedContent = fullResult.mainContent
                self.isGenerating = false
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.isGenerating = false
                }
            }
        }
    }

    func regenerate() {
        generateContent()
    }

    func stopGeneration() {
        streamTask?.cancel()
        isGenerating = false
    }

    func togglePlatform(_ platform: SocialPlatform) {
        if selectedPlatforms.contains(platform) {
            if selectedPlatforms.count > 1 {
                selectedPlatforms.remove(platform)
            }
        } else {
            selectedPlatforms.insert(platform)
        }
    }

    func clearContent() {
        generatedContent = ""
        generatedResult = nil
        error = nil
        prompt = ""
    }

    var alternativeVersions: [String] {
        generatedResult?.alternativeVersions ?? []
    }

    var suggestedHashtags: [String] {
        generatedResult?.suggestedHashtags ?? []
    }

    deinit {
        streamTask?.cancel()
    }
}
