import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @State private var isBookmarked: Bool
    @State private var showShareSheet: Bool = false

    init(article: Article) {
        self.article = article
        _isBookmarked = State(initialValue: article.isBookmarked)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                AsyncImage(url: article.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(16 / 9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.bgPrimary)
                        .aspectRatio(16 / 9, contentMode: .fit)
                }
                .clipped()

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            CategoryBadge(
                                text: article.category.displayName,
                                color: .iceBlue,
                                icon: article.category.iconSystemName
                            )
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.lgCaption)
                                Text("\(article.readTimeMinutes) Min. Lesezeit")
                                    .font(.lgCaption)
                            }
                            .foregroundColor(.textSecondary)
                        }

                        Text(article.title)
                            .font(.lgDisplayLG)
                            .foregroundColor(.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.neonMagenta.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(article.author.name.prefix(1)))
                                        .font(.lgBodySemibold)
                                        .foregroundColor(.neonMagenta)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(article.author.name)
                                    .font(.lgBodySemibold)
                                    .foregroundColor(.textPrimary)
                                Text(article.publishedAt.readableDateString)
                                    .font(.lgCaption)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Divider()
                        .background(Color.glassBorder)
                        .padding(.horizontal, 20)

                    // Article body (Markdown rendered via AttributedString)
                    if let attributed = try? AttributedString(
                        markdown: article.content,
                        options: .init(interpretedSyntax: .inlinesOnlyPreservingWhitespace)
                    ) {
                        Text(attributed)
                            .font(.lgBodyLG)
                            .foregroundColor(.textPrimary)
                            .tint(.iceBlue)
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                    } else {
                        Text(article.content)
                            .font(.lgBodyLG)
                            .foregroundColor(.textPrimary)
                            .lineSpacing(6)
                            .padding(.horizontal, 20)
                    }

                    // Tags
                    if !article.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(article.tags, id: \.self) { tag in
                                    CategoryBadge(text: "#\(tag)", color: .iceBlue)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 80)
                }
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        isBookmarked.toggle()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .neonMagenta : .textSecondary)
                    }
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = article.sourceURL {
                ShareSheet(items: [article.title, url])
            } else {
                ShareSheet(items: [article.title])
            }
        }
    }
}

// MARK: - ShareSheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
