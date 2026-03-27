import SwiftUI

struct ComposerView: View {
    @StateObject var viewModel: ComposerViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Platform Selector
            platformSelector
                .padding(.horizontal)
                .padding(.top, 8)

            Divider()

            // Platform Tabs (when multiple platforms selected)
            if viewModel.selectedPlatforms.count > 1 {
                platformTabs
                Divider()
            }

            // Text Editor
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        if viewModel.postContent.isEmpty {
                            Text("What's on your mind? Share insights, tips, or updates...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $viewModel.postContent)
                            .frame(minHeight: 150)
                            .focused($isTextFieldFocused)
                    }
                    .padding(.horizontal, 4)

                    // Character count for each platform
                    ForEach(Array(viewModel.selectedPlatforms).sorted(by: { $0.displayName < $1.displayName })) { platform in
                        CharacterCountRow(
                            platform: platform,
                            count: viewModel.characterCount(for: platform),
                            limit: platform.characterLimit,
                            isWithinLimit: viewModel.isWithinLimit(for: platform)
                        )
                    }

                    // Hashtags
                    if !viewModel.hashtags.isEmpty {
                        hashtagsSection
                    }

                    // Media placeholders
                    if !viewModel.mediaAttachments.isEmpty {
                        mediaSection
                    }
                }
                .padding()
            }

            Divider()

            // Toolbar
            composerToolbar
        }
        .navigationTitle("Compose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if !viewModel.postContent.isEmpty {
                        Task { await viewModel.saveDraft() }
                    }
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.publish() }
                    } label: {
                        Label("Post Now", systemImage: "paperplane")
                    }
                    .disabled(!viewModel.canPost)

                    Button {
                        viewModel.showSchedulePicker = true
                    } label: {
                        Label("Schedule", systemImage: "clock")
                    }
                    .disabled(!viewModel.canPost)

                    Button {
                        Task { await viewModel.saveDraft() }
                    } label: {
                        Label("Save Draft", systemImage: "doc.text")
                    }
                } label: {
                    if viewModel.isPublishing {
                        ProgressView().tint(Color.primaryBrand)
                    } else {
                        Text("Post")
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.canPost ? Color.primaryBrand : .secondary)
                    }
                }
                .disabled(!viewModel.canPost || viewModel.isPublishing)
            }
        }
        .sheet(isPresented: $viewModel.showSchedulePicker) {
            NavigationStack {
                SchedulePickerView(selectedDate: Binding(
                    get: { viewModel.scheduledDate ?? Date.nextHour() },
                    set: { viewModel.scheduledDate = $0 }
                )) {
                    Task { await viewModel.schedulePost() }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAIAssistant) {
            AIAssistantSheet(
                viewModel: AIAssistantViewModel(generateContentUseCase: viewModel.generateContentUseCaseRef),
                onApply: { content in
                    viewModel.applyGeneratedContent(content)
                    viewModel.showAIAssistant = false
                }
            )
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("OK") { viewModel.saveError = nil }
        } message: {
            if let error = viewModel.saveError {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: viewModel.publishSuccess) { _, success in
            if success { dismiss() }
        }
    }

    private var platformSelector: some View {
        HStack(spacing: 8) {
            Text("Post to:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
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
            }
        }
        .padding(.vertical, 8)
    }

    private var platformTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(viewModel.selectedPlatforms).sorted(by: { $0.displayName < $1.displayName })) { platform in
                    Button {
                        viewModel.activePlatformTab = platform
                    } label: {
                        VStack(spacing: 4) {
                            Label(platform.displayName, systemImage: platform.iconSystemName)
                                .font(.caption)
                                .fontWeight(viewModel.activePlatformTab == platform ? .semibold : .regular)
                                .foregroundColor(viewModel.activePlatformTab == platform ? Color.primaryBrand : .secondary)
                            if viewModel.activePlatformTab == platform {
                                Rectangle()
                                    .fill(Color.primaryBrand)
                                    .frame(height: 2)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(minWidth: 80)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var hashtagsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hashtags")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            FlowLayout(spacing: 6) {
                ForEach(viewModel.hashtags, id: \.self) { tag in
                    HStack(spacing: 2) {
                        Text("#\(tag)")
                            .font(.caption)
                        Button {
                            viewModel.hashtags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryBrand.opacity(0.1))
                    .foregroundColor(Color.primaryBrand)
                    .cornerRadius(4)
                }
            }
        }
    }

    private var mediaSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.mediaAttachments) { attachment in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
        }
    }

    private var composerToolbar: some View {
        HStack(spacing: 20) {
            Button {
                // Image picker
            } label: {
                Image(systemName: "photo")
                    .foregroundColor(Color.primaryBrand)
            }

            Button {
                viewModel.showAIAssistant = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("AI")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color.primaryBrand)
            }

            Button {
                viewModel.showSchedulePicker = true
            } label: {
                Image(systemName: viewModel.scheduledDate != nil ? "clock.fill" : "clock")
                    .foregroundColor(viewModel.scheduledDate != nil ? Color.primaryBrand : .secondary)
            }

            Spacer()

            if let date = viewModel.scheduledDate {
                Text(date.scheduledString)
                    .font(.caption)
                    .foregroundColor(Color.primaryBrand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryBrand.opacity(0.1))
                    .cornerRadius(6)
            }

            Button {
                isTextFieldFocused = false
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Character Count Row

struct CharacterCountRow: View {
    let platform: SocialPlatform
    let count: Int
    let limit: Int
    let isWithinLimit: Bool

    private var progressValue: Double { Double(count) / Double(limit) }
    private var remaining: Int { limit - count }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: platform.iconSystemName)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(platform.displayName)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(remaining)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isWithinLimit ? .secondary : .red)

            ProgressView(value: min(progressValue, 1.0))
                .tint(isWithinLimit ? (progressValue > 0.85 ? .orange : .green) : .red)
                .frame(width: 40)
        }
    }
}

// MARK: - Platform Toggle Chip

struct PlatformToggleChip: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(platform.displayName, systemImage: platform.iconSystemName)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryBrand : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - ViewModel Extension for AI Sheet

extension ComposerViewModel {
    var generateContentUseCaseRef: GenerateContentUseCaseProtocol {
        generateContentUseCase
    }
}

#Preview {
    NavigationStack {
        ComposerView(viewModel: ComposerViewModel(
            createPostUseCase: PreviewCreatePostUseCase(),
            schedulePostUseCase: PreviewSchedulePostUseCase(),
            generateContentUseCase: PreviewGenerateContentUseCase()
        ))
    }
}

private final class PreviewCreatePostUseCase: CreatePostUseCaseProtocol {
    func execute(_ post: Post) async throws -> Post { post }
    func saveDraft(_ post: Post) async throws -> Post { post }
    func fetchDrafts() async throws -> [Post] { [.draft()] }
    func deletePost(id: String) async throws {}
}

private final class PreviewSchedulePostUseCase: SchedulePostUseCaseProtocol {
    func schedule(_ post: Post, at date: Date) async throws -> Post { post }
    func fetchScheduled() async throws -> [Post] { [.mock()] }
    func cancelScheduled(postID: String) async throws {}
    func reschedule(postID: String, newDate: Date) async throws -> Post { .mock() }
}

private final class PreviewGenerateContentUseCase: GenerateContentUseCaseProtocol {
    func generate(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) async throws -> GeneratedContent {
        GeneratedContent(mainContent: "Sample content", platformVariants: [:], suggestedHashtags: ["growth"], estimatedEngagement: nil, alternativeVersions: [])
    }
    func generateStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func rewrite(content: String, tone: AITone, instruction: String) async throws -> String { content }
    func generateHashtags(for content: String, platforms: [SocialPlatform]) async throws -> [String] { ["growth", "marketing"] }
    func suggestBestTimes(for platform: SocialPlatform) async throws -> [Date] { [Date()] }
}
