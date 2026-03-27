import SwiftUI

struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Product Image
            AsyncImage(url: product.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                default:
                    ZStack {
                        LinearGradient(
                            colors: [Color.primaryBrand.opacity(0.7), Color.secondaryBrand.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: product.category.iconSystemName)
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(height: 140)
                }
            }
            .cornerRadius(Constants.UI.cornerRadius, corners: [.topLeft, .topRight])
            .overlay(alignment: .topTrailing) {
                if product.isNew {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentGreen)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Category
                Text(product.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryBrand)

                // Name
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Short description
                Text(product.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()

                // Footer: Price + Rating
                HStack {
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(product.isFree ? Color.accentGreen : .primary)

                    Spacer()

                    if let rating = product.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HStack {
        ProductCardView(product: .mockFree())
        ProductCardView(product: .mockPaid())
    }
    .padding()
}
