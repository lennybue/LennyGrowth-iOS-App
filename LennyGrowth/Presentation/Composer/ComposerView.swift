import SwiftUI

struct ComposerView: View {
    @StateObject private var viewModel: ComposerViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ComposerViewModel(
            postRepository: MockPostRepository(),
            aiRepository: MockAIRepository()
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        platformSelector
                        textEditor
                        mediaPicker
                        warningBanners
                        toneSelector
                        actionRow
                        queueSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Compose")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            viewModel.showPostPreview = true
                        } label: {
                            Image(systemName: "eye")
                                .foregroundColor(.textSecondary)
                        }
                        .disabled(viewModel.content.isEmpty)
                        .accessibilityLabel("Vorschau anzeigen")

                        Button(String(localized: "Entwurf")) {
                            Task { await viewModel.saveDraft() }
                        }
                        .font(.lgBodyMD)
                        .foregroundColor(.iceBlue)
                        .disabled(viewModel.content.isEmpty || viewModel.isSaving)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPostPreview) {
                if let platform = viewModel.selectedPlatforms.first {
                    PostPreviewView(
                        content: viewModel.content,
                        platform: platform,
                        hashtags: viewModel.content
                            .components(separatedBy: .whitespaces)
                            .filter { $0.hasPrefix("#") }
                            .map { String($0.dropFirst()) }
                    )
                    .presentationDetents([.large])
                }
            }
            .sheet(isPresented: $viewModel.showScheduler) {
                schedulerSheet
            }
        }
        .task {
            await viewModel.loadQueue()
        }
    }

    // MARK: - Platform selector

    private var platformSelector: some View {
        HStack(spacing: 12) {
            ForEach([SocialPlatform.linkedin, .threads], id: \.self) { platform in
                Button {
                    viewModel.togglePlatform(platform)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: platform.iconSystemName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(platform.displayName)
                            .font(.lgBodySemibold)

                        if viewModel.selectedPlatforms.contains(platform) {
                            let count = platform == .linkedin ? viewModel.linkedInCharCount : viewModel.threadsCharCount
                            let limit = platform.characterLimit
                            Text("\(count)/\(limit)")
                                .font(.lgCaption)
                                .foregroundColor(count > limit ? .red : .white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundColor(viewModel.selectedPlatforms.contains(platform) ? .white : .textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(viewModel.selectedPlatforms.contains(platform)
                                  ? Color(hex: platform.brandColorHex).opacity(0.85)
                                  : Color.bgSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        viewModel.selectedPlatforms.contains(platform)
                                        ? Color.clear : Color.glassBorder,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Text editor

    private var textEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text(String(localized: "Worüber möchtest du schreiben?"))
                        .font(.lgBodyMD)
                        .foregroundColor(.textSecondary.opacity(0.5))
                        .padding(.top, 14)
                        .padding(.leading, 14)
                }
                TextEditor(text: $viewModel.content)
                    .font(.lgBodyMD)
                    .foregroundColor(.textPrimary)
                    .frame(minHeight: 160)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .tint(.neonMagenta)
                    .onChange(of: viewModel.content) { _, _ in
                        viewModel.validateContent()
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.glassBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Media picker

    private var mediaPicker: some View {
        MediaPickerView(items: $viewModel.mediaItems)
    }

    // MARK: - Warnings

    @ViewBuilder
    private var warningBanners: some View {
        VStack(spacing: 8) {
            if viewModel.showLinkWarning {
                WarningBanner(
                    icon: "link",
                    text: String(localized: "Denk daran: Link in den ersten Kommentar (innerhalb 60 Sek.)"),
                    color: .neonMagenta
                )
            }
            if viewModel.showHashtagWarning {
                WarningBanner(
                    icon: "number",
                    text: String(localized: "Hashtags booten Reichweite auf Threads nicht"),
                    color: .yellow
                )
            }
            if viewModel.showLineCountWarning {
                WarningBanner(
                    icon: "text.alignleft",
                    text: String(localized: "Mehr als 6 Zeilen – kürze den Post für bessere Reichweite auf Threads"),
                    color: .yellow
                )
            }
        }
    }

    // MARK: - Tone selector

    private var toneSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Ton"))
                .font(.lgLabel)
                .foregroundColor(.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AITone.allCases) { tone in
                        Button {
                            viewModel.selectedTone = tone
                        } label: {
                            HStack(spacing: 5) {
                                Text(tone.emoji)
                                Text(tone.displayName)
                                    .font(.lgBodySemibold)
                            }
                            .foregroundColor(viewModel.selectedTone == tone ? .white : .textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedTone == tone ? Color.neonMagenta : Color.bgSurface)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(viewModel.selectedTone == tone ? Color.clear : Color.glassBorder, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 12) {
            // AI button
            Button {
                viewModel.showAIAssistant = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text(String(localized: "KI-Assistent"))
                        .font(.lgBodySemibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.neonMagenta)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .glow(color: .neonMagenta, radius: 10)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $viewModel.showAIAssistant) {
                AIAssistantView(onApply: { text in
                    viewModel.applyGeneratedContent(text)
                })
            }

            // Schedule button
            Button {
                viewModel.showScheduler = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                    Text(String(localized: "Planen"))
                        .font(.lgBodySemibold)
                }
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.glassBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canPost)
        }
    }

    // MARK: - Queue section

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Geplante Posts"))
                .font(.lgDisplaySM)
                .foregroundColor(.textPrimary)

            if viewModel.scheduledPosts.isEmpty && viewModel.draftPosts.isEmpty {
                Text(String(localized: "Keine geplanten Posts oder Entwürfe."))
                    .font(.lgBodySM)
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.scheduledPosts + viewModel.draftPosts) { post in
                    PostQueueCard(post: post) {
                        Task { await viewModel.deletePost(id: post.id) }
                    }
                }
            }
        }
    }

    // MARK: - Scheduler sheet

    private var schedulerSheet: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 24) {
                    DatePicker(
                        String(localized: "Datum & Uhrzeit"),
                        selection: $viewModel.scheduledDate,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.neonMagenta)
                    .colorScheme(.dark)

                    if viewModel.scheduledDate.isOptimalLinkedInTime {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.neonTeal)
                            Text(String(localized: "Optimale LinkedIn-Zeit (Di–Do, 8–10 Uhr)"))
                                .font(.lgBodySM)
                                .foregroundColor(.neonTeal)
                        }
                        .padding(10)
                        .background(Color.neonTeal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    LGButton(
                        title: String(localized: "Post planen"),
                        style: .primary,
                        icon: "calendar.badge.plus",
                        isLoading: viewModel.isScheduling,
                        isFullWidth: true
                    ) {
                        Task { await viewModel.schedulePost() }
                    }
                }
                .padding(24)
            }
            .navigationTitle(String(localized: "Zeitpunkt wählen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Abbrechen")) {
                        viewModel.showScheduler = false
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Warning Banner

struct WarningBanner: View {
    let icon: String
    let text: String
    var color: Color = .yellow

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.lgBodySM)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Post Queue Card

struct PostQueueCard: View {
    let post: Post
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StatusDot(status: post.status)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ForEach(post.platforms, id: \.self) { platform in
                        PlatformBadge(platform: platform)
                    }
                    Spacer()
                    if let date = post.scheduledAt {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(date.readableDateString)
                                .font(.lgCaption)
                                .foregroundColor(.textSecondary)
                            Text(date.timeString)
                                .font(.lgCaption)
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text(String(localized: "Entwurf"))
                            .font(.lgCaption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Text(post.content)
                    .font(.lgBodySM)
                    .foregroundColor(.textPrimary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .glassCard(padding: 0)
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label(String(localized: "Löschen"), systemImage: "trash")
            }
        }
    }
}
