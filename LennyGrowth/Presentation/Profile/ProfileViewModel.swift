import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var connectedAccounts: [ConnectedAccount] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var showDeleteAccountAlert: Bool = false

    private let postRepository: any PostRepositoryProtocol
    private let authUseCase: any AuthUseCaseProtocol

    init(postRepository: any PostRepositoryProtocol, authUseCase: any AuthUseCaseProtocol) {
        self.postRepository = postRepository
        self.authUseCase = authUseCase
    }

    func loadConnectedAccounts() async {
        isLoading = true
        do {
            connectedAccounts = try await postRepository.fetchConnectedAccounts()
        } catch { self.error = error }
        isLoading = false
    }

    func disconnect(account: ConnectedAccount) async {
        do {
            try await postRepository.disconnectSocialAccount(accountID: account.id)
            connectedAccounts.removeAll { $0.id == account.id }
        } catch { self.error = error }
    }

    func connectLinkedIn() async {
        do {
            let account = try await postRepository.connectSocialAccount(
                platform: .linkedin, accessToken: "mock_oauth_token"
            )
            connectedAccounts.removeAll { $0.platform == .linkedin }
            connectedAccounts.append(account)
        } catch { self.error = error }
    }

    func connectThreads() async {
        do {
            let account = try await postRepository.connectSocialAccount(
                platform: .threads, accessToken: "mock_oauth_token"
            )
            connectedAccounts.removeAll { $0.platform == .threads }
            connectedAccounts.append(account)
        } catch { self.error = error }
    }

    func clearCache() {
        // Clear URLSession cache
        URLCache.shared.removeAllCachedResponses()
    }
}
