import SwiftUI

struct AIAssistantSheet: View {
    @StateObject var viewModel: AIAssistantViewModel
    let onApply: (GeneratedContent) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var promptFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Prompt Input
                    promptSection

                    // Tone Selector
                    toneSection

                    // Platform Selector
                    platformSection

                    // Context (optional)
                    contextSection

                    // Generate Button
                    generateButton

                    // Generated Output
                    if !viewModel.generatedContent.isEmpty || viewModel.isGenerating {
                        generatedOutputSection
                    }

                    // Error
                    if let error = viewModel.error {
                        InlineErrorView(message: error.localizedDescription) {
                            viewModel.generateContent()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI Content Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if !viewModel.generatedContent.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") { viewModel.clearContent() }
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear { promptFocused = true }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What do you want to write about?", systemImage: "pencil")
                .font(.subheadline)
                .fontWeight(.semibold)

            ZStack(alignment: .topLeading) {
                if viewModel.prompt.isEmpty {
                    Text("e.g. Share tips about growing your Twitter audience...")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.top, 10)
                        .padding(.leading, 6)
                }
                TextEditor(text: $viewModel.prompt)
                    .frame(minHeight: 100)
                    .focused($promptFocused)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tone", systemImage: "speaker.wave.2")
                .font(.subheadline)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AITone.allCases) { tone in
                        ToneChip(
                            tone: tone,
                            isSelected: viewModel.selectedTone == tone
                        ) {
                            viewModel.selectedTone = tone
                        }
                    }
                }
            }
        }
    }

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Platforms", systemImage: "antenna.radiowaves.left.and.right")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                ForEach(SocialPlatform.allCases) { platform in
                    PlatformToggleChip(
                        platform: platform,
                        isSelected: viewModel.selectedPlatforms.contains(platform)
                    ) {
                        viewModel.togglePlatform(platform)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { viewModel.showContextInput.toggle() }
            } label: {
                HStack {
                    Label("Add context (optional)", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: viewModel.showContextInput ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }

            if viewModel.showContextInput {
                TextEditor(text: $viewModel.contextText)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(Constants.UI.cornerRadius)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var generateButton: some View {
        Button {
            promptFocused = false
            viewModel.generateContent()
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                    Text("Generating...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate Content")
                }
            }
        }
        .primaryButtonStyle()
        .disabled(!viewModel.canGenerate || viewModel.isGenerating)
    }

    private var generatedOutputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Generated Content", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isGenerating {
                    Button {
                        viewModel.stopGeneration()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    Button {
                        viewModel.regenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(Color.primaryBrand)
                    }
                }
            }

            // Main content
            Text(viewModel.generatedContent.isEmpty ? "Generating..." : viewModel.generatedContent)
                .font(.body)
                .lineSpacing(4)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(Constants.UI.cornerRadius)
                .overlay(
                    viewModel.isGenerating ? streamingCursor : nil
                )

            // Hashtag suggestions
            if !viewModel.suggestedHashtags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggested Hashtags")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(viewModel.suggestedHashtags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primaryBrand.opacity(0.1))
                                .foregroundColor(Color.primaryBrand)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            // Alternative versions
            if !viewModel.alternativeVersions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alternative Versions")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    ForEach(Array(viewModel.alternativeVersions.enumerated()), id: \.offset) { index, version in
                        Text(version)
                            .font(.caption)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
            }

            // Apply button
            if let result = viewModel.generatedResult, !viewModel.isGenerating {
                Button {
                    onApply(result)
                } label: {
                    Label("Use This Content", systemImage: "checkmark")
                }
                .primaryButtonStyle()
            }
        }
    }

    private var streamingCursor: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(8)
            }
        }
    }
}

struct ToneChip: View {
    let tone: AITone
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tone.emoji)
                Text(tone.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.primaryBrand : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

#Preview {
    AIAssistantSheet(
        viewModel: AIAssistantViewModel(generateContentUseCase: PreviewGenerateUseCase()),
        onApply: { _ in }
    )
}

private final class PreviewGenerateUseCase: GenerateContentUseCaseProtocol {
    func generate(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return GeneratedContent(
            mainContent: "Excited to share some amazing growth hacking tips for 2024! Whether you're just starting out or scaling up, these strategies will help you grow faster. Thread below 👇",
            platformVariants: ["twitter": "Thread: Growth hacking tips for 2024 👇"],
            suggestedHashtags: ["GrowthHacking", "Marketing", "SaaS"],
            estimatedEngagement: "High",
            alternativeVersions: ["Alternative version 1", "Alternative version 2"]
        )
    }
    func generateStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let words = ["Excited", " to", " share", " some", " amazing", " growth", " tips!"]
                for word in words {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    continuation.yield(word)
                }
                continuation.finish()
            }
        }
    }
    func rewrite(content: String, tone: AITone, instruction: String) async throws -> String { content }
    func generateHashtags(for content: String, platforms: [SocialPlatform]) async throws -> [String] { ["growth"] }
    func suggestBestTimes(for platform: SocialPlatform) async throws -> [Date] { [Date()] }
}
