import SwiftUI

struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var selectedArticle: Article? = nil

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .idle, .loading where viewModel.articles.isEmpty:
                skeletonView
            case .error(let error) where viewModel.articles.isEmpty:
                ErrorView(error: error) {
                    Task { await viewModel.refreshArticles() }
                }
            default:
                articleListView
            }
        }
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchQuery, prompt: "Search articles...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("All Categories") { viewModel.selectCategory(nil) }
                    Divider()
                    ForEach(Article.ArticleCategory.allCases) { category in
                        Button {
                            viewModel.selectCategory(category)
                        } label: {
                            HStack {
                                Text(category.displayName)
                                if viewModel.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: viewModel.selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(Color.primaryBrand)
                }
            }
        }
        .onFirstAppear {
            await viewModel.loadArticles()
        }
        .refreshable {
            await viewModel.refreshArticles()
        }
        .sheet(item: $selectedArticle) { article in
            NavigationStack {
                ArticleDetailView(article: article)
            }
        }
    }

    private var skeletonView: some View {
        ScrollView {
            categoryChips
            LazyVStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonCardView()
                        .padding(.horizontal)
                }
            }
        }
    }

    private var articleListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                categoryChips

                if viewModel.articles.isEmpty {
                    if viewModel.searchQuery.isEmpty {
                        EmptyStateView.noArticles { Task { await viewModel.refreshArticles() } }
                    } else {
                        EmptyStateView.noSearchResults(query: viewModel.searchQuery)
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.articles) { article in
                            ArticleCardView(article: article) {
                                Task { await viewModel.toggleBookmark(article: article) }
                            }
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedArticle = article
                            }
                            .onAppear {
                                viewModel.articleDidAppear(article)
                            }
                        }

                        if viewModel.isLoadingMore {
                            InlineLoadingView()
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }

                ForEach(Article.ArticleCategory.allCases) { category in
                    CategoryChip(
                        title: category.displayName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.primaryBrand : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    NavigationStack {
        FeedView(viewModel: FeedViewModel(fetchArticlesUseCase: PreviewFetchArticlesUseCase()))
    }
}

// MARK: - Preview Helper

private final class PreviewFetchArticlesUseCase: FetchArticlesUseCaseProtocol {
    func execute(page: Int, pageSize: Int, category: Article.ArticleCategory?, searchQuery: String?) async throws -> PaginatedResult<Article> {
        try await Task.sleep(nanoseconds: 500_000_000)
        return PaginatedResult(items: [.mock(), .mock(), .mock()], totalCount: 3, currentPage: 1, pageSize: 20)
    }
    func fetchArticle(id: String) async throws -> Article { .mock() }
    func toggleBookmark(articleID: String) async throws -> Article { .mock() }
    func fetchBookmarked() async throws -> [Article] { [] }
}
