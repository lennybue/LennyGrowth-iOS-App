import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User? = nil
    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var isUpdating: Bool = false
    @Published private(set) var updateError: Error? = nil
    @Published private(set) var connectedAccounts: [ConnectedAccount] = []

    // Edit fields
    @Published var editDisplayName: String = ""
    @Published var editBio: String = ""

    private let authUseCase: AuthUseCaseProtocol
    private let postRepository: PostRepositoryProtocol

    init(authUseCase: AuthUseCaseProtocol, postRepository: PostRepositoryProtocol) {
        self.authUseCase = authUseCase
        self.postRepository = postRepository
    }

    func loadProfile() async {
        guard case .idle = loadingState else { return }
        loadingState = .loading
        do {
            let fetchedUser = try await authUseCase.fetchCurrentUser()
            user = fetchedUser
            editDisplayName = fetchedUser.displayName
            editBio = fetchedUser.bio ?? ""
            connectedAccounts = fetchedUser.connectedAccounts
            loadingState = .loaded
        } catch {
            loadingState = .error(error)
        }
    }

    func updateProfile() async {
        isUpdating = true
        updateError = nil
        defer { isUpdating = false }

        do {
            let updated = try await authUseCase.updateProfile(
                displayName: editDisplayName.isEmpty ? nil : editDisplayName,
                bio: editBio.isEmpty ? nil : editBio,
                avatarURL: nil
            )
            user = updated
        } catch {
            updateError = error
        }
    }

    func signOut() async {
        do {
            try await authUseCase.signOut()
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        } catch {
            updateError = error
        }
    }

    func connectAccount(_ platform: SocialPlatform, accessToken: String) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            let account = try await postRepository.connectSocialAccount(platform: platform, accessToken: accessToken)
            if let index = connectedAccounts.firstIndex(where: { $0.platform == platform }) {
                connectedAccounts[index] = account
            } else {
                connectedAccounts.append(account)
            }
            // Update user
            if var currentUser = user {
                if let index = currentUser.connectedAccounts.firstIndex(where: { $0.platform == platform }) {
                    currentUser.connectedAccounts[index] = account
                } else {
                    currentUser.connectedAccounts.append(account)
                }
                user = currentUser
            }
        } catch {
            updateError = error
        }
    }

    func disconnectAccount(_ account: ConnectedAccount) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            try await postRepository.disconnectSocialAccount(accountID: account.id)
            connectedAccounts.removeAll { $0.id == account.id }
            if var currentUser = user {
                currentUser.connectedAccounts.removeAll { $0.id == account.id }
                user = currentUser
            }
        } catch {
            updateError = error
        }
    }

    var subscriptionTier: User.SubscriptionTier {
        user?.subscriptionTier ?? .free
    }

    var isProUser: Bool {
        subscriptionTier == .pro
    }
}
