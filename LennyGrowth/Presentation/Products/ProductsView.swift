import SwiftUI

struct ProductsView: View {
    @StateObject var viewModel: ProductsViewModel
    @State private var selectedProduct: Product? = nil
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .idle, .loading where viewModel.products.isEmpty:
                loadingGrid
            case .error(let error) where viewModel.products.isEmpty:
                ErrorView(error: error) {
                    Task { await viewModel.refreshProducts() }
                }
            default:
                productGrid
            }
        }
        .navigationTitle("Products")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("All Categories") { viewModel.selectCategory(nil) }
                    Divider()
                    ForEach(Product.ProductCategory.allCases) { cat in
                        Button {
                            viewModel.selectCategory(cat)
                        } label: {
                            HStack {
                                Text(cat.displayName)
                                if viewModel.selectedCategory == cat {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: viewModel.selectedCategory != nil
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                    .foregroundColor(Color.primaryBrand)
                }
            }
        }
        .onFirstAppear {
            await viewModel.loadProducts()
        }
        .refreshable {
            await viewModel.refreshProducts()
        }
        .sheet(item: $selectedProduct) { product in
            NavigationStack {
                ProductDetailView(product: product)
            }
        }
    }

    private var filterSegment: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            Text("All").tag(ProductFilter.all)
            Text("Free").tag(ProductFilter.free)
            Text("Paid").tag(ProductFilter.paid)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var productGrid: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Featured Section
                if !viewModel.featuredProducts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Featured")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.featuredProducts) { product in
                                    ProductCardView(product: product)
                                        .frame(width: 180)
                                        .onTapGesture { selectedProduct = product }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }

                Section {
                    if viewModel.products.isEmpty {
                        EmptyStateView.noProducts()
                            .frame(minHeight: 300)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.products) { product in
                                ProductCardView(product: product)
                                    .onTapGesture { selectedProduct = product }
                                    .onAppear { viewModel.productDidAppear(product) }
                            }
                        }
                        .padding(.horizontal)

                        if viewModel.isLoadingMore {
                            InlineLoadingView()
                        }
                    }
                } header: {
                    filterSegment
                        .background(Color(.systemBackground))
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var loadingGrid: some View {
        ScrollView {
            filterSegment

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    SkeletonCardView()
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        ProductsView(viewModel: ProductsViewModel(fetchProductsUseCase: PreviewFetchProductsUseCase()))
    }
}

private final class PreviewFetchProductsUseCase: FetchProductsUseCaseProtocol {
    func execute(page: Int, pageSize: Int, category: Product.ProductCategory?, isFree: Bool?) async throws -> PaginatedResult<Product> {
        try await Task.sleep(nanoseconds: 300_000_000)
        return PaginatedResult(items: [.mockFree(), .mockPaid(), .mockFree()], totalCount: 3, currentPage: 1, pageSize: 20)
    }
    func fetchProduct(id: String) async throws -> Product { .mockFree() }
    func fetchFeatured() async throws -> [Product] { [.mockFeatured()] }
    func downloadProduct(id: String) async throws -> URL { URL(string: "https://example.com")! }
}

private extension Product {
    static func mockFeatured() -> Product {
        var p = mockPaid()
        return p
    }
}
