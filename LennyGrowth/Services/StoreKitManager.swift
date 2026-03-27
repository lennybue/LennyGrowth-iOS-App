import StoreKit

// MARK: - StoreKitManager

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Product IDs

    private enum ProductID {
        static let proMonthly = "com.lennardbuessow.lennygrowth.pro_monthly"
    }

    // MARK: - Published State

    @Published var proProduct: Product?
    @Published var isPurchasing = false
    @Published var hasPro = false

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    init() {
        transactionListenerTask = listenForTransactions()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Public API

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [ProductID.proMonthly])
            proProduct = products.first
        } catch {
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    func purchase() async throws {
        guard let product = proProduct else {
            throw StoreError.productNotFound
        }

        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            hasPro = true
            await transaction.finish()

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            print("[StoreKit] Restore failed: \(error)")
        }
    }

    func checkEntitlements() async {
        var hasActivePro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == ProductID.proMonthly,
               transaction.revocationDate == nil {
                hasActivePro = true
            }
        }
        hasPro = hasActivePro
    }

    // MARK: - Private Helpers

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.checkEntitlements()
                    await transaction.finish()
                } catch {
                    print("[StoreKit] Unverified transaction: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

// MARK: - StoreError

enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Produkt konnte nicht gefunden werden."
        case .purchaseFailed(let reason):
            return "Kauf fehlgeschlagen: \(reason)"
        }
    }
}
