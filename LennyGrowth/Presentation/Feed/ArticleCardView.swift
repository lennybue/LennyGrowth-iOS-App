import SwiftUI

struct ArticleCardView: View {
    let article: Article
    var onBookmarkToggle: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image
            AsyncImage(url: article.imageURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo.slash")
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(Constants.UI.cornerRadius, corners: [.topLeft, .topRight])

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Category + Featured badge
                HStack {
                    Label(article.category.displayName, systemImage: article.category.iconSystemName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primaryBrand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryBrand.opacity(0.1))
                        .cornerRadius(6)

                    if article.isFeatured {
                        Label("Featured", systemImage: "star.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }

                    Spacer()

                    Button(action: { onBookmarkToggle?() }) {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(article.isBookmarked ? Color.primaryBrand : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(article.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Author + Meta
                HStack(spacing: 12) {
                    AsyncImage(url: article.author.avatarURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color(.systemGray4))
                            .overlay(Text(article.author.name.prefix(1)).font(.caption).fontWeight(.semibold))
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())

                    Text(article.author.name)
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("·")
                        .foregroundColor(.secondary)

                    Text(article.publishedAt.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Label("\(article.readTimeMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
        }
        .cardStyle()
    }
}

#Preview {
    ScrollView {
        ArticleCardView(article: .mock())
            .padding()
    }
}
