import SwiftUI

struct ProductCardView: View {
    let product: Product
    var isDownloaded: Bool = false
    var isDownloading: Bool = false
    var onDownload: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            AsyncImage(url: product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(4 / 3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.bgPrimary)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay(
                        Image(systemName: product.category.iconSystemName)
                            .font(.system(size: 32))
                            .foregroundColor(.textSecondary.opacity(0.4))
                    )
            }
            .clipped()
            .clipShape(
                .rect(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16)
            )

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    priceBadge
                    Spacer()
                    if product.isNew {
                        CategoryBadge(text: "NEU", color: .neonMagenta)
                    }
                    if let rating = product.rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.lgCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                Text(product.name)
                    .font(.lgBodySemibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Text(product.shortDescription)
                    .font(.lgBodySM)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let fileSize = product.formattedFileSize {
                        Label(fileSize, systemImage: "doc")
                            .font(.lgCaption)
                            .foregroundColor(.textSecondary)
                    }
                    if let fileType = product.fileType {
                        Text(fileType.rawValue.uppercased())
                            .font(.lgCaption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text("\(product.downloadCount.compactFormatted) Downloads")
                        .font(.lgCaption)
                        .foregroundColor(.textSecondary)
                }

                downloadButton
            }
            .padding(14)
        }
        .background(Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.glassBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(product.name), \(product.isFree ? "Kostenlos" : product.formattedPrice)")
        .accessibilityHint(isDownloaded ? "Bereits heruntergeladen" : "Tippe zum Herunterladen")
    }

    // MARK: - Sub-components

    private var priceBadge: some View {
        Group {
            if product.isFree {
                CategoryBadge(text: String(localized: "Kostenlos"), color: .neonTeal)
            } else {
                CategoryBadge(text: product.formattedPrice, color: .neonMagenta)
            }
        }
    }

    private var downloadButton: some View {
        Button {
            onDownload?()
        } label: {
            HStack(spacing: 6) {
                if isDownloading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                        .tint(.white)
                } else if isDownloaded {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(isDownloaded ? String(localized: "Heruntergeladen") : (product.isFree ? String(localized: "Kostenlos herunterladen") : String(localized: "Kaufen")))
                    .font(.lgBodySemibold)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isDownloaded ? Color.neonTeal : (product.isFree ? Color.neonTeal : Color.neonMagenta))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDownloaded || isDownloading)
        .if(!isDownloaded && product.isFree) { $0.glow(color: .neonTeal, radius: 6) }
        .if(!isDownloaded && !product.isFree) { $0.glow(color: .neonMagenta, radius: 6) }
        .accessibilityLabel(isDownloaded ? "Heruntergeladen" : (product.isFree ? "Kostenlos herunterladen" : "Kaufen für \(product.formattedPrice)"))
        .accessibilityAddTraits(.isButton)
    }
}
