import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .idle, .loading where viewModel.user == nil:
                LoadingView(message: "Loading profile...")
            case .error(let error) where viewModel.user == nil:
                ErrorView(error: error) {
                    Task { await viewModel.loadProfile() }
                }
            default:
                profileContent
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.user != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .onFirstAppear {
            await viewModel.loadProfile()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(viewModel: viewModel)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                Task { await viewModel.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var profileContent: some View {
        List {
            // Profile Header
            Section {
                profileHeader
            }

            // Subscription
            Section("Subscription") {
                subscriptionRow
            }

            // Social Accounts
            Section("Connected Accounts") {
                NavigationLink {
                    ConnectedAccountsView(viewModel: viewModel)
                } label: {
                    HStack {
                        Label("Manage Accounts", systemImage: "person.2")
                        Spacer()
                        let connectedCount = viewModel.connectedAccounts.filter { $0.isConnected }.count
                        if connectedCount > 0 {
                            Text("\(connectedCount) connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Settings
            Section("App") {
                NavigationLink {
                    Text("Notifications Settings")
                        .navigationTitle("Notifications")
                } label: {
                    Label("Notifications", systemImage: "bell")
                }

                Link(destination: Constants.App.privacyPolicyURL) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .foregroundColor(.primary)
                }

                Link(destination: Constants.App.termsOfServiceURL) {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundColor(.primary)
                }

                Link(destination: URL(string: "mailto:\(Constants.App.supportEmail)")!) {
                    Label("Contact Support", systemImage: "envelope")
                        .foregroundColor(.primary)
                }
            }

            // Sign Out
            Section {
                Button(role: .destructive) {
                    showSignOutAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            }

            // Version
            Section {
                HStack {
                    Text("Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            AsyncImage(url: viewModel.user?.avatarURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryBrand, Color.secondaryBrand],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    if let name = viewModel.user?.displayName, !name.isEmpty {
                        Text(String(name.prefix(1)).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            VStack(spacing: 4) {
                Text(viewModel.user?.displayName ?? "")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(viewModel.user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let bio = viewModel.user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var subscriptionRow: some View {
        HStack {
            Label(
                viewModel.subscriptionTier.displayName,
                systemImage: viewModel.isProUser ? "star.fill" : "star"
            )
            .foregroundColor(viewModel.isProUser ? .orange : .primary)

            Spacer()

            if !viewModel.isProUser {
                Button("Upgrade to Pro") {
                    // Handle upgrade
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.primaryBrand)
            } else {
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}

struct EditProfileSheet: View {
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Your name", text: $viewModel.editDisplayName)
                        .autocorrectionDisabled()
                }

                Section("Bio") {
                    TextEditor(text: $viewModel.editBio)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.updateProfile()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isUpdating)
                }
            }
            .overlay {
                if viewModel.isUpdating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding(20)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(viewModel: ProfileViewModel(
            authUseCase: PreviewAuthUseCase(),
            postRepository: PreviewPostRepository()
        ))
    }
}

private final class PreviewAuthUseCase: AuthUseCaseProtocol {
    var isAuthenticated: Bool = true
    func signIn(email: String, password: String) async throws -> User { previewUser() }
    func signUp(email: String, password: String, displayName: String) async throws -> User { previewUser() }
    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User { previewUser() }
    func signOut() async throws {}
    func fetchCurrentUser() async throws -> User { previewUser() }
    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User { previewUser() }
    func resetPassword(email: String) async throws {}

    private func previewUser() -> User {
        User(id: "1", email: "sarah@example.com", displayName: "Sarah Mitchell",
             avatarURL: nil, bio: "Marketing expert & content creator",
             connectedAccounts: [], subscriptionTier: .pro, createdAt: Date())
    }
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
