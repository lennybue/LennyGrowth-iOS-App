import Foundation

/// Central dependency container using protocol-based DI.
/// Swap mock implementations for real network implementations when the backend is ready.
final class DependencyContainer: ObservableObject {
    let authRepository: any AuthRepositoryProtocol
    let contentRepository: any ContentRepositoryProtocol
    let postRepository: any PostRepositoryProtocol
    let aiRepository: any AIRepositoryProtocol
    let keychain: KeychainWrapper

    init() {
        let keychain = KeychainWrapper()
        self.keychain = keychain
        self.authRepository = MockAuthRepository(keychain: keychain)
        self.contentRepository = MockContentRepository()
        self.postRepository = MockPostRepository()
        self.aiRepository = MockAIRepository()
    }
}
