import SwiftUI

struct AIAssistantView: View {
    var onApply: ((String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AIAssistantViewModel
    @State private var selectedDetent: PresentationDetent = .medium

    init(onApply: ((String) -> Void)? = nil) {
        self.onApply = onApply
        _viewModel = StateObject(wrappedValue: AIAssistantViewModel(aiRepository: MockAIRepository()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Platform + Tone pills
                        platformAndToneRow

                        // Prompt input
                        promptSection

                        // Template suggestions
                        if viewModel.streamingText.isEmpty && !viewModel.isGenerating {
                            templateSection
                        }

                        // Streaming output
                        if !viewModel.streamingText.isEmpty || viewModel.isGenerating {
                            outputSection
                        }

                        // Hashtag suggestions
                        if !viewModel.suggestedHashtags.isEmpty {
                            hashtagSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("KI-Assistent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Schließen")) {
                        viewModel.cancelGeneration()
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.bgPrimary)
    }

    // MARK: - Subviews

    private var platformAndToneRow: some View {
        VStack(spacing: 10) {
            // Platform
            HStack(spacing: 8) {
                Text(String(localized: "Plattform:"))
                    .font(.lgLabel)
                    .foregroundColor(.textSecondary)
                ForEach([SocialPlatform.linkedin, .threads], id: \.self) { p in
                    Button {
                        viewModel.selectedPlatform = p
                    } label: {
                        Text(p.displayName)
                            .font(.lgCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.selectedPlatform == p ? .white : .textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedPlatform == p
                                          ? Color(hex: p.brandColorHex)
                                          : Color.bgSurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            // Tone
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text(String(localized: "Ton:"))
                        .font(.lgLabel)
                        .foregroundColor(.textSecondary)
                    ForEach(AITone.allCases) { tone in
                        Button {
                            viewModel.selectedTone = tone
                        } label: {
                            HStack(spacing: 4) {
                                Text(tone.emoji)
                                Text(tone.displayName)
                                    .font(.lgCaption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(viewModel.selectedTone == tone ? .white : .textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedTone == tone ? Color.neonMagenta : Color.bgSurface)
                                    .overlay(
                                        Capsule().strokeBorder(
                                            viewModel.selectedTone == tone ? Color.clear : Color.glassBorder,
                                            lineWidth: 1
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            LGTextEditor(
                title: String(localized: "Thema"),
                text: $viewModel.prompt,
                placeholder: String(localized: "Über was soll der Post sein?")
            )

            HStack(spacing: 10) {
                LGButton(
                    title: viewModel.isGenerating ? String(localized: "Generiert…") : String(localized: "Generieren"),
                    style: .primary,
                    icon: "sparkles",
                    isLoading: viewModel.isGenerating,
                    isFullWidth: true
                ) {
                    Task {
                        selectedDetent = .large
                        await viewModel.generate()
                    }
                }
                .disabled(viewModel.prompt.isEmpty)
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Templates"))
                .font(.lgDisplaySM)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.templates, id: \.title) { template in
                Button {
                    viewModel.applyTemplate(template)
                    selectedDetent = .large
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: template.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.neonMagenta)
                            .frame(width: 36, height: 36)
                            .background(Color.neonMagenta.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(template.title)
                            .font(.lgBodySemibold)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(12)
                    .glassCard(padding: 0)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Generierter Text"))
                    .font(.lgDisplaySM)
                    .foregroundColor(.textPrimary)
                Spacer()
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.neonMagenta)
                        .scaleEffect(0.8)
                }
            }

            Text(viewModel.streamingText)
                .font(.lgBodyMD)
                .foregroundColor(.textPrimary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.glassBorder, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.05), value: viewModel.streamingText)

            if !viewModel.isGenerating && !viewModel.streamingText.isEmpty {
                HStack(spacing: 10) {
                    LGButton(title: String(localized: "Übernehmen"), style: .secondary, isFullWidth: true) {
                        onApply?(viewModel.streamingText)
                        dismiss()
                    }
                    LGButton(title: String(localized: "Neu"), style: .ghost) {
                        Task { await viewModel.regenerate() }
                    }
                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var hashtagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Hashtag-Vorschläge"))
                .font(.lgLabel)
                .foregroundColor(.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.suggestedHashtags, id: \.self) { tag in
                        CategoryBadge(text: tag, color: .iceBlue)
                    }
                }
            }
        }
    }
}
