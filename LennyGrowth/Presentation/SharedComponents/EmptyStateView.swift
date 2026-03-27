import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.primaryBrand)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                }
            }
        }
        .padding(Constants.UI.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    static func noArticles(onRefresh: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "newspaper",
            title: "No Articles Yet",
            description: "Check back soon for the latest marketing insights and growth strategies.",
            actionTitle: "Refresh",
            action: onRefresh
        )
    }

    static func noProducts() -> EmptyStateView {
        EmptyStateView(
            systemImage: "bag",
            title: "No Products Yet",
            description: "Our product catalog is being updated. Check back soon!"
        )
    }

    static func noDrafts(onCompose: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "doc.text",
            title: "No Drafts",
            description: "Start composing your first post to save drafts here.",
            actionTitle: "Compose Post",
            action: onCompose
        )
    }

    static func noScheduledPosts(onCompose: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "clock",
            title: "Nothing Scheduled",
            description: "Schedule posts ahead of time to maintain a consistent presence.",
            actionTitle: "Schedule a Post",
            action: onCompose
        )
    }

    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No Results",
            description: "No content found for \"\(query)\". Try a different search term."
        )
    }

    static func noConnectedAccounts(onConnect: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "person.2",
            title: "No Connected Accounts",
            description: "Connect your social media accounts to start posting and scheduling content.",
            actionTitle: "Connect Account",
            action: onConnect
        )
    }
}

#Preview {
    EmptyStateView.noArticles { }
}
