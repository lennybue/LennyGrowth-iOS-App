import Foundation

// MARK: - Environment

enum AppEnvironment {
    /// Uses local mock data — no network calls. Default for Xcode Previews & unit tests.
    case mock
    /// Uses real URLSession against https://api.lennardbuessow.digital/v1
    case production

    /// Active environment — flip to `.mock` for local development without a backend.
    static var current: AppEnvironment {
        #if DEBUG
        // Set LENNYGROWTH_ENV=mock in scheme environment variables to force mock mode
        if ProcessInfo.processInfo.environment["LENNYGROWTH_ENV"] == "mock" { return .mock }
        #endif
        return .production
    }
}

// MARK: - DependencyContainer

/// Central dependency container. Protocol-based — all properties are typed as protocols,
/// making it trivial to swap mock ↔ network implementations.
final class DependencyContainer: ObservableObject {
    // Public repositories (protocol types)
    let authRepository: any AuthRepositoryProtocol
    let contentRepository: any ContentRepositoryProtocol
    let postRepository: any PostRepositoryProtocol
    let aiRepository: any AIRepositoryProtocol

    // Shared infrastructure
    let keychain: KeychainWrapper
    let networkMonitor: NetworkMonitor
    let syncCoordinator: SyncCoordinator

    init(environment: AppEnvironment = AppEnvironment.current) {
        let keychain = KeychainWrapper()
        self.keychain = keychain

        let monitor = NetworkMonitor()
        self.networkMonitor = monitor

        switch environment {
        case .mock:
            authRepository    = MockAuthRepository(keychain: keychain)
            contentRepository = MockContentRepository()
            postRepository    = MockPostRepository()
            aiRepository      = MockAIRepository()

        case .production:
            let tokenManager = TokenManager(keychain: keychain)
            let client = APIClient(tokenManager: tokenManager)

            authRepository    = NetworkAuthRepository(client: client, tokenManager: tokenManager, keychain: keychain)
            contentRepository = NetworkContentRepository(client: client)
            postRepository    = NetworkPostRepository(client: client)
            aiRepository      = NetworkAIRepository(client: client)
        }

        syncCoordinator = SyncCoordinator(
            draftStore: OfflineDraftStore(),
            postRepository: postRepository,
            networkMonitor: monitor
        )
    }
}
