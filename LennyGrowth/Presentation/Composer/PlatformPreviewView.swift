import SwiftUI

struct PlatformPreviewView: View {
    let platform: SocialPlatform
    let content: String
    let username: String
    let userAvatarURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Platform header
            HStack {
                Image(systemName: platform.iconSystemName)
                    .font(.subheadline)
                Text("Preview on \(platform.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .foregroundColor(.secondary)

            // Preview Card
            VStack(alignment: .leading, spacing: 10) {
                platformContent
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            // Character count
            HStack {
                Spacer()
                let count = content.count
                let limit = platform.characterLimit
                let remaining = limit - count
                Text("\(remaining) characters remaining")
                    .font(.caption)
                    .foregroundColor(remaining < 0 ? .red : remaining < 50 ? .orange : .secondary)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var platformContent: some View {
        switch platform {
        case .twitter:
            twitterPreview
        case .linkedin:
            linkedInPreview
        case .instagram:
            instagramPreview
        case .facebook:
            facebookPreview
        case .threads:
            threadsPreview
        }
    }

    private var userRow: some View {
        HStack(spacing: 10) {
            AsyncImage(url: userAvatarURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.primaryBrand.opacity(0.3))
                    .overlay(
                        Text(username.prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primaryBrand)
                    )
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("@\(username.lowercased().replacingOccurrences(of: " ", with: "_"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var twitterPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            userRow
            Text(content)
                .font(.subheadline)
                .lineSpacing(3)
            HStack(spacing: 20) {
                Label("Reply", systemImage: "bubble.left")
                Label("Retweet", systemImage: "arrow.2.squarepath")
                Label("Like", systemImage: "heart")
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var linkedInPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            userRow
            Text(content.prefix(300) + (content.count > 300 ? "..." : ""))
                .font(.subheadline)
                .lineSpacing(4)
            HStack(spacing: 16) {
                Label("Like", systemImage: "hand.thumbsup")
                Label("Comment", systemImage: "text.bubble")
                Label("Share", systemImage: "arrow.turn.right.up")
                Label("Send", systemImage: "paperplane")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var instagramPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            userRow
            HStack(spacing: 16) {
                Image(systemName: "heart")
                Image(systemName: "bubble.right")
                Image(systemName: "paperplane")
                Spacer()
                Image(systemName: "bookmark")
            }
            .foregroundColor(.primary)
            Text("\(username.lowercased()) \(content.prefix(150))\(content.count > 150 ? "... more" : "")")
                .font(.caption)
                .lineSpacing(3)
        }
    }

    private var facebookPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            userRow
            Text(content)
                .font(.subheadline)
                .lineSpacing(4)
            Divider()
            HStack(spacing: 0) {
                Label("Like", systemImage: "hand.thumbsup")
                    .frame(maxWidth: .infinity)
                Label("Comment", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity)
                Label("Share", systemImage: "arrow.turn.right.up")
                    .frame(maxWidth: .infinity)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var threadsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            userRow
            Text(content.prefix(500) + (content.count > 500 ? "..." : ""))
                .font(.subheadline)
                .lineSpacing(3)
            HStack(spacing: 16) {
                Image(systemName: "heart")
                Image(systemName: "bubble.right")
                Image(systemName: "arrow.2.squarepath")
                Image(systemName: "paperplane")
            }
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ScrollView {
        PlatformPreviewView(
            platform: .twitter,
            content: "Just shipped a new feature for @LennyGrowth! Super excited to share our progress on the marketing content platform. Check it out! 🚀 #IndieHacker #SaaS",
            username: "LennyGrowth",
            userAvatarURL: nil
        )
    }
}
