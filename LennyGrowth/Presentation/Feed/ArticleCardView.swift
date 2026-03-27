import SwiftUI

struct ArticleCardView: View {
    let article: Article
    var onBookmark: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Featured image
            AsyncImage(url: article.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(16 / 9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.bgPrimary)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundColor(.textSecondary.opacity(0.4))
                    )
            }
            .clipped()
            .clipShape(
                .rect(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16)
            )

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    CategoryBadge(
                        text: article.category.displayName,
                        color: .iceBlue,
                        icon: article.category.iconSystemName
                    )
                    Spacer()
                    if article.isFeatured {
                        CategoryBadge(text: String(localized: "Featured"), color: .neonMagenta)
                    }
                }

                Text(article.title)
                    .font(.lgDisplaySM)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(article.summary)
                    .font(.lgBodySM)
                    .foregroundColor(.textSecondary)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    Label(
                        "\(article.readTimeMinutes) Min.",
                        systemImage: "clock"
                    )
                    .font(.lgCaption)
                    .foregroundColor(.textSecondary)

                    Text(article.publishedAt.relativeString)
                        .font(.lgCaption)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Button {
                        onBookmark?()
                    } label: {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(article.isBookmarked ? .neonMagenta : .textSecondary)
                            .if(article.isBookmarked) { $0.glow(color: .neonMagenta, radius: 6) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
        .background(Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.glassBorder, lineWidth: 1)
        )
    }
}
