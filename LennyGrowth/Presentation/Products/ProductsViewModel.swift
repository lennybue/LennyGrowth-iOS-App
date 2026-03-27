import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    enum Segment { case free, paid }

    @Published var freeProducts: [Product] = []
    @Published var paidProducts: [Product] = []
    @Published var selectedSegment: Segment = .free
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var downloadedIDs: Set<String> = []
    @Published var downloadingID: String? = nil
    @Published var showCrossSellToast: Bool = false
    @Published var crossSellMessage: String = ""

    private let repository: any ContentRepositoryProtocol

    init(repository: any ContentRepositoryProtocol) {
        self.repository = repository
    }

    var displayedProducts: [Product] {
        selectedSegment == .free ? freeProducts : paidProducts
    }

    var downloadProgress: Double {
        guard !freeProducts.isEmpty else { return 0 }
        return Double(downloadedIDs.count) / Double(freeProducts.count)
    }

    var badgeTitle: String {
        let count = downloadedIDs.count
        if count >= Constants.Gamification.totalFreeProducts { return Constants.Gamification.BadgeTitles.expert }
        if count >= 3 { return Constants.Gamification.BadgeTitles.profi }
        return Constants.Gamification.BadgeTitles.starter
    }

    // MARK: - Load

    func loadProducts() async {
        isLoading = true
        error = nil
        do {
            async let freeResult = repository.fetchProducts(page: 1, pageSize: 20, category: nil, isFree: true)
            async let paidResult = repository.fetchProducts(page: 1, pageSize: 20, category: nil, isFree: false)
            let (freeRes, paidRes) = try await (freeResult, paidResult)
            freeProducts = freeRes.items
            paidProducts = paidRes.items
        } catch {
            self.error = error
        }
        isLoading = false
    }

    // MARK: - Download

    func download(product: Product) async {
        guard !downloadedIDs.contains(product.id), downloadingID == nil else { return }
        downloadingID = product.id
        do {
            _ = try await repository.downloadProduct(id: product.id)
            downloadedIDs.insert(product.id)
            triggerCrossSell(after: product)
        } catch {
            self.error = error
        }
        downloadingID = nil
    }

    private func triggerCrossSell(after product: Product) {
        let remaining = freeProducts.count - downloadedIDs.count
        if remaining > 0 {
            crossSellMessage = String(localized: "🎯 Noch \(remaining) kostenlose Resources verfügbar!")
        } else {
            crossSellMessage = String(localized: "🏆 Alle Freebies heruntergeladen – du bist Marketing-Experte!")
        }
        showCrossSellToast = true
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showCrossSellToast = false
        }
    }
}
