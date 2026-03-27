import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var isBookmarked: Bool

    init(article: Article) {
        self.article = article
        _isBookmarked = State(initialValue: article.isBookmarked)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                AsyncImage(url: article.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryBrand.opacity(0.6), Color.secondaryBrand.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 260)
                            .overlay(
                                Image(systemName: article.category.iconSystemName)
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Category + Read time
                    HStack {
                        Label(article.category.displayName, systemImage: article.category.iconSystemName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.primaryBrand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.primaryBrand.opacity(0.1))
                            .cornerRadius(6)

                        Spacer()

                        Label("\(article.readTimeMinutes) min read", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Title
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)

                    // Author info
                    HStack(spacing: 12) {
                        AsyncImage(url: article.author.avatarURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.primaryBrand.opacity(0.2))
                                .overlay(
                                    Text(article.author.name.prefix(1))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryBrand)
                                )
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.author.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if let bio = article.author.bio {
                                Text(bio)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Text(article.publishedAt.relativeTimeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Summary
                    Text(article.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Content
                    Text(article.content)
                        .font(.body)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    // Tags
                    if !article.tags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            FlowLayout(spacing: 8) {
                                ForEach(article.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Source link
                    if let sourceURL = article.sourceURL {
                        Divider()

                        Link(destination: sourceURL) {
                            HStack {
                                Image(systemName: "link")
                                Text("View Original Source")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color.primaryBrand)
                        }
                    }
                }
                .padding(Constants.UI.defaultPadding)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        isBookmarked.toggle()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? Color.primaryBrand : .primary)
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = article.sourceURL {
                ShareSheet(items: [article.title, url])
            } else {
                ShareSheet(items: [article.title, article.summary])
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                height += currentRowHeight + spacing
                currentX = 0
                currentRowHeight = 0
            }
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        height += currentRowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += currentRowHeight + spacing
                currentX = bounds.minX
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: .mock())
    }
}
