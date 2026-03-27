import SwiftUI

struct PostQueueView: View {
    @StateObject var viewModel: ComposerViewModel
    @State private var showComposer = false
    @State private var selectedTab: QueueTab = .scheduled

    enum QueueTab: String, CaseIterable {
        case scheduled = "Scheduled"
        case drafts = "Drafts"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Queue Tab", selection: $selectedTab) {
                ForEach(QueueTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch selectedTab {
                case .scheduled:
                    scheduledView
                case .drafts:
                    draftsView
                }
            }
        }
        .navigationTitle("Post Queue")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showComposer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onFirstAppear {
            await viewModel.loadQueue()
        }
        .sheet(isPresented: $showComposer) {
            NavigationStack {
                ComposerView(viewModel: viewModel)
            }
        }
    }

    private var scheduledView: some View {
        Group {
            switch viewModel.queueLoadingState {
            case .loading where viewModel.scheduledPosts.isEmpty:
                LoadingView(message: "Loading scheduled posts...")
            case .error(let error) where viewModel.scheduledPosts.isEmpty:
                ErrorView(error: error) {
                    Task { await viewModel.loadQueue() }
                }
            default:
                if viewModel.scheduledPosts.isEmpty {
                    EmptyStateView.noScheduledPosts { showComposer = true }
                } else {
                    List {
                        ForEach(viewModel.scheduledPosts) { post in
                            PostQueueRow(post: post) {
                                Task { await viewModel.cancelScheduled(id: post.id) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
    }

    private var draftsView: some View {
        Group {
            if viewModel.drafts.isEmpty {
                EmptyStateView.noDrafts { showComposer = true }
            } else {
                List {
                    ForEach(viewModel.drafts) { post in
                        PostQueueRow(post: post, onDelete: {
                            Task { await viewModel.deleteDraft(id: post.id) }
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteDraft(id: post.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct PostQueueRow: View {
    let post: Post
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status + Platforms
            HStack {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: post.status.iconSystemName)
                        .font(.caption)
                    Text(post.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(post.status).opacity(0.15))
                .foregroundColor(statusColor(post.status))
                .cornerRadius(6)

                Spacer()

                // Platform icons
                HStack(spacing: 4) {
                    ForEach(post.platforms) { platform in
                        Image(systemName: platform.iconSystemName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Content preview
            Text(post.content)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(.primary)

            // Scheduled date
            if let scheduledDate = post.scheduledAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(scheduledDate.scheduledString)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(post.createdAt.relativeTimeString)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: Post.PostStatus) -> Color {
        switch status {
        case .draft: return .secondary
        case .scheduled: return Color.primaryBrand
        case .publishing: return .orange
        case .published: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    NavigationStack {
        PostQueueView(viewModel: ComposerViewModel(
            createPostUseCase: PreviewCreatePostUseCase(),
            schedulePostUseCase: PreviewSchedulePostUseCase(),
            generateContentUseCase: PreviewGenerateContentUseCase()
        ))
    }
}

// MARK: - Preview Helpers

private final class PreviewCreatePostUseCase: CreatePostUseCaseProtocol {
    func execute(_ post: Post) async throws -> Post { post }
    func saveDraft(_ post: Post) async throws -> Post { post }
    func fetchDrafts() async throws -> [Post] { [.draft(), .draft()] }
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
        GeneratedContent(mainContent: "Sample", platformVariants: [:], suggestedHashtags: [], estimatedEngagement: nil, alternativeVersions: [])
    }
    func generateStream(prompt: String, tone: AITone, platforms: [SocialPlatform], context: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func rewrite(content: String, tone: AITone, instruction: String) async throws -> String { content }
    func generateHashtags(for content: String, platforms: [SocialPlatform]) async throws -> [String] { [] }
    func suggestBestTimes(for platform: SocialPlatform) async throws -> [Date] { [] }
}
