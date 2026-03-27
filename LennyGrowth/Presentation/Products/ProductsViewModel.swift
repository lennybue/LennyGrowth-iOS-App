import Foundation
import Combine

enum ProductFilter {
    case all
    case free
    case paid
}

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var featuredProducts: [Product] = []
    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var isLoadingMore: Bool = false
    @Published var selectedFilter: ProductFilter = .all
    @Published var selectedCategory: Product.ProductCategory? = nil
    @Published private(set) var hasNextPage: Bool = false

    private let fetchProductsUseCase: FetchProductsUseCaseProtocol
    private var currentPage = 1
    private let pageSize = Constants.API.defaultPageSize
    private var cancellables = Set<AnyCancellable>()

    init(fetchProductsUseCase: FetchProductsUseCaseProtocol) {
        self.fetchProductsUseCase = fetchProductsUseCase
        setupFilterObservers()
    }

    private func setupFilterObservers() {
        Publishers.CombineLatest($selectedFilter, $selectedCategory)
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.resetAndLoad()
            }
            .store(in: &cancellables)
    }

    func loadProducts() async {
        guard case .idle = loadingState else { return }
        await loadFeatured()
        loadingState = .loading
        await fetchPage(1, reset: true)
    }

    func refreshProducts() async {
        await loadFeatured()
        loadingState = .loading
        await fetchPage(1, reset: true)
    }

    func loadMore() async {
        guard hasNextPage, !isLoadingMore else { return }
        isLoadingMore = true
        await fetchPage(currentPage + 1, reset: false)
        isLoadingMore = false
    }

    func selectFilter(_ filter: ProductFilter) {
        selectedFilter = filter
    }

    func selectCategory(_ category: Product.ProductCategory?) {
        selectedCategory = category
    }

    func productDidAppear(_ product: Product) {
        guard let index = products.firstIndex(where: { $0.id == product.id }),
              index >= products.count - 5 else { return }
        Task { await loadMore() }
    }

    private func loadFeatured() async {
        do {
            featuredProducts = try await fetchProductsUseCase.fetchFeatured()
        } catch {
            // Featured products are supplementary; don't fail main flow
        }
    }

    private func resetAndLoad() {
        Task { [weak self] in
            guard let self = self else { return }
            self.loadingState = .loading
            await self.fetchPage(1, reset: true)
        }
    }

    private func fetchPage(_ page: Int, reset: Bool) async {
        do {
            let isFreeFilter: Bool?
            switch selectedFilter {
            case .all: isFreeFilter = nil
            case .free: isFreeFilter = true
            case .paid: isFreeFilter = false
            }

            let result = try await fetchProductsUseCase.execute(
                page: page,
                pageSize: pageSize,
                category: selectedCategory,
                isFree: isFreeFilter
            )

            if reset {
                products = result.items
            } else {
                products.append(contentsOf: result.items)
            }
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
            loadingState = .loaded
        } catch {
            if reset { products = [] }
            loadingState = .error(error)
        }
    }
}
