import SwiftUI

struct ProductsView: View {
    @StateObject private var viewModel: ProductsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ProductsViewModel(repository: MockContentRepository()))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Gamification progress
                    if viewModel.selectedSegment == .free {
                        gamificationBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    // Segmented control
                    Picker(String(localized: "Produkte"), selection: $viewModel.selectedSegment) {
                        Text(String(localized: "Kostenlos")).tag(ProductsViewModel.Segment.free)
                        Text(String(localized: "Premium")).tag(ProductsViewModel.Segment.paid)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .tint(.neonMagenta)

                    // Product grid
                    if viewModel.isLoading && viewModel.displayedProducts.isEmpty {
                        skeletonGrid
                    } else if viewModel.displayedProducts.isEmpty {
                        EmptyStateView(
                            icon: "bag",
                            title: String(localized: "Keine Produkte"),
                            subtitle: String(localized: "Schau bald wieder vorbei.")
                        )
                    } else {
                        productGrid
                    }
                }

                // Cross-sell toast
                if viewModel.showCrossSellToast {
                    toastView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Produkte")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .animation(.spring(response: 0.4), value: viewModel.showCrossSellToast)
        }
        .task {
            await viewModel.loadProducts()
        }
    }

    // MARK: - Subviews

    private var gamificationBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(viewModel.badgeTitle, systemImage: "star.circle.fill")
                    .font(.lgBodySemibold)
                    .foregroundColor(.neonTeal)
                Spacer()
                Text("\(viewModel.downloadedIDs.count)/\(viewModel.freeProducts.count)")
                    .font(.lgCaption)
                    .foregroundColor(.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.bgSurface)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.neonTeal, .iceBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.downloadProgress)
                        .animation(.spring(response: 0.6), value: viewModel.downloadProgress)
                }
                .frame(height: 6)
            }
            .frame(height: 6)
        }
        .padding(12)
        .glassCard(padding: 0)
    }

    private var productGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(viewModel.displayedProducts) { product in
                    ProductCardView(
                        product: product,
                        isDownloaded: viewModel.downloadedIDs.contains(product.id),
                        isDownloading: viewModel.downloadingID == product.id
                    ) {
                        Task { await viewModel.download(product: product) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var skeletonGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in SkeletonCard(height: 280) }
            }
            .padding(.horizontal, 16)
        }
    }

    private var toastView: some View {
        Text(viewModel.crossSellMessage)
            .font(.lgBodySemibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.neonTeal)
                    .shadow(color: .neonTeal.opacity(0.5), radius: 12)
            )
    }
}
