import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @State private var showDownloadAlert = false
    @State private var isDownloading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero
                AsyncImage(url: product.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 240)
                            .clipped()
                    default:
                        ZStack {
                            LinearGradient(
                                colors: [Color.primaryBrand.opacity(0.7), Color.secondaryBrand.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: product.category.iconSystemName)
                                .font(.system(size: 56))
                                .foregroundColor(.white)
                        }
                        .frame(height: 240)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(product.category.displayName, systemImage: product.category.iconSystemName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.primaryBrand)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.primaryBrand.opacity(0.1))
                                .cornerRadius(6)

                            if product.isNew {
                                Text("NEW")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }

                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(product.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Stats Row
                    HStack(spacing: 0) {
                        if let rating = product.rating {
                            StatItem(
                                icon: "star.fill",
                                value: String(format: "%.1f", rating),
                                label: "\(product.reviewCount) reviews",
                                color: .orange
                            )
                        }

                        StatItem(
                            icon: "arrow.down.circle",
                            value: "\(product.downloadCount)",
                            label: "downloads",
                            color: Color.primaryBrand
                        )

                        if let fileSize = product.formattedFileSize {
                            StatItem(
                                icon: "doc",
                                value: fileSize,
                                label: product.fileType?.rawValue.uppercased() ?? "FILE",
                                color: .secondary
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(Constants.UI.cornerRadius)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(product.description)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Tags
                    if !product.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                            FlowLayout(spacing: 8) {
                                ForEach(product.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // CTA
                    VStack(spacing: 12) {
                        Button {
                            if product.isFree {
                                showDownloadAlert = true
                            } else {
                                // Handle purchase
                            }
                        } label: {
                            HStack {
                                if isDownloading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: product.isFree ? "arrow.down.circle" : "cart")
                                    Text(product.isFree ? "Download Free" : "Purchase – \(product.formattedPrice)")
                                }
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(isDownloading)

                        if let previewURL = product.previewURL {
                            Link(destination: previewURL) {
                                HStack {
                                    Image(systemName: "eye")
                                    Text("Preview")
                                }
                            }
                            .secondaryButtonStyle()
                        }
                    }
                }
                .padding(Constants.UI.defaultPadding)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Download Started", isPresented: $showDownloadAlert) {
            Button("OK") {}
        } message: {
            Text("Your download will begin shortly. Check your Files app when complete.")
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: .mockPaid())
    }
}
