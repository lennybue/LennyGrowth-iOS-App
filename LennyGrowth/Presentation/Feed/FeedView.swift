import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var container: DependencyContainer
    @StateObject private var viewModel: FeedViewModel

    init() {
        // Placeholder — real VM is created in onAppear via environmentObject
        _viewModel = StateObject(wrappedValue: FeedViewModel(repository: MockContentRepository()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    // Category filter
                    categoryFilterStrip
                        .padding(.bottom, 4)

                    // Content
                    Group {
                        if viewModel.isLoading && viewModel.articles.isEmpty {
                            skeletonList
                        } else if let error = viewModel.error, viewModel.articles.isEmpty {
                            ErrorStateView(error: error) {
                                Task { await viewModel.loadArticles() }
                            }
                        } else if viewModel.articles.isEmpty {
                            EmptyStateView(
                                icon: "newspaper",
                                title: String(localized: "Keine Artikel"),
                                subtitle: String(localized: "Versuche eine andere Kategorie oder Suche.")
                            )
                        } else {
                            articleList
                        }
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .refreshable {
                await viewModel.loadArticles()
            }
        }
        .task {
            await viewModel.loadArticles()
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            Task { await viewModel.loadArticles() }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            TextField(String(localized: "Artikel suchen…"), text: $viewModel.searchQuery)
                .font(.lgBodyMD)
                .foregroundColor(.textPrimary)
                .tint(.neonMagenta)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.glassBorder, lineWidth: 1)
                )
        )
    }

    private var categoryFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    title: String(localized: "Alle"),
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    Task { await viewModel.selectCategory(nil) }
                }

                ForEach(Article.ArticleCategory.allCases) { cat in
                    CategoryPill(
                        title: cat.displayName,
                        isSelected: viewModel.selectedCategory == cat
                    ) {
                        Task { await viewModel.selectCategory(cat) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleCardView(article: article) {
                            Task { await viewModel.toggleBookmark(article: article) }
                        }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.hasNextPage {
                    ProgressView()
                        .tint(.neonMagenta)
                        .padding()
                        .task { await viewModel.loadMore() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonCard(height: 260)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Category pill

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.lgLabel)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.neonMagenta : Color.bgSurface)
                        .overlay(
                            Capsule()
                                .strokeBorder(isSelected ? Color.neonMagenta : Color.glassBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .if(isSelected) { $0.glow(color: .neonMagenta, radius: 6) }
    }
}
