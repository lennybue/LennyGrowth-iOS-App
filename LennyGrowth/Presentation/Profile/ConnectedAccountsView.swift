import SwiftUI

struct ConnectedAccountsView: View {
    @StateObject var viewModel: ProfileViewModel
    @State private var showConnectSheet = false
    @State private var selectedPlatform: SocialPlatform? = nil

    var body: some View {
        List {
            ForEach(SocialPlatform.allCases) { platform in
                let account = viewModel.connectedAccounts.first(where: { $0.platform == platform })
                ConnectedAccountRow(
                    platform: platform,
                    account: account,
                    isLoading: viewModel.isUpdating
                ) {
                    if account != nil {
                        if let acc = account {
                            Task { await viewModel.disconnectAccount(acc) }
                        }
                    } else {
                        selectedPlatform = platform
                        showConnectSheet = true
                    }
                }
            }
        }
        .navigationTitle("Connected Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.updateError != nil },
            set: { if !$0 { viewModel.updateError = nil } }
        )) {
            Button("OK") { viewModel.updateError = nil }
        } message: {
            if let error = viewModel.updateError {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $showConnectSheet) {
            if let platform = selectedPlatform {
                ConnectAccountSheet(platform: platform) { accessToken in
                    Task { await viewModel.connectAccount(platform, accessToken: accessToken) }
                }
            }
        }
    }
}

struct ConnectedAccountRow: View {
    let platform: SocialPlatform
    let account: ConnectedAccount?
    let isLoading: Bool
    let action: () -> Void

    var isConnected: Bool { account?.isConnected == true }

    var body: some View {
        HStack(spacing: 14) {
            // Platform icon
            ZStack {
                Circle()
                    .fill(Color(hex: platform.brandColor).opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: platform.iconSystemName)
                    .foregroundColor(Color(hex: platform.brandColor))
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(platform.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let account = account {
                    Text(account.displayHandle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let count = account.followerCount {
                        Text("\(count) followers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Not connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: action) {
                if isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Text(isConnected ? "Disconnect" : "Connect")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isConnected ? .red : Color.primaryBrand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isConnected ? Color.red : Color.primaryBrand, lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct ConnectAccountSheet: View {
    let platform: SocialPlatform
    let onConnect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var accessToken: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Platform header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: platform.brandColor).opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: platform.iconSystemName)
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: platform.brandColor))
                    }
                    Text("Connect \(platform.displayName)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Enter your API access token to connect your \(platform.displayName) account.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                LGTextField(
                    title: "Access Token",
                    placeholder: "Paste your access token here",
                    text: $accessToken,
                    textContentType: .password,
                    isSecure: true
                )
                .padding(.horizontal)

                Button {
                    onConnect(accessToken)
                    dismiss()
                } label: {
                    Label("Connect \(platform.displayName)", systemImage: "link")
                }
                .primaryButtonStyle()
                .padding(.horizontal)
                .disabled(accessToken.isEmpty)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NavigationStack {
        ConnectedAccountsView(viewModel: ProfileViewModel(
            authUseCase: PreviewAuthUseCase(),
            postRepository: PreviewPostRepository()
        ))
    }
}

private final class PreviewAuthUseCase: AuthUseCaseProtocol {
    var isAuthenticated: Bool = true
    func signIn(email: String, password: String) async throws -> User { .empty() }
    func signUp(email: String, password: String, displayName: String) async throws -> User { .empty() }
    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User { .empty() }
    func signOut() async throws {}
    func fetchCurrentUser() async throws -> User { .empty() }
    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User { .empty() }
    func resetPassword(email: String) async throws {}
}

private final class PreviewPostRepository: PostRepositoryProtocol {
    func createPost(_ post: Post) async throws -> Post { post }
    func updatePost(_ post: Post) async throws -> Post { post }
    func deletePost(id: String) async throws {}
    func fetchPosts(status: Post.PostStatus?) async throws -> [Post] { [] }
    func fetchPost(id: String) async throws -> Post { .draft() }
    func schedulePost(_ post: Post, scheduledAt: Date) async throws -> Post { post }
    func publishPost(_ post: Post) async throws -> Post { post }
    func saveDraft(_ post: Post) async throws -> Post { post }
    func fetchDrafts() async throws -> [Post] { [] }
    func fetchScheduledPosts() async throws -> [Post] { [] }
    func connectSocialAccount(platform: SocialPlatform, accessToken: String) async throws -> ConnectedAccount {
        ConnectedAccount(id: UUID().uuidString, platform: platform, username: "testuser", profileImageURL: nil, isConnected: true)
    }
    func disconnectSocialAccount(accountID: String) async throws {}
    func fetchConnectedAccounts() async throws -> [ConnectedAccount] { [] }
}
