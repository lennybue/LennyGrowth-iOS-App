import Foundation
import SwiftData

@MainActor
final class DependencyContainer: ObservableObject {
    // MARK: - Singletons

    let keychainManager: KeychainManager
    let persistenceController: PersistenceController
    let networkMonitor: NetworkMonitor

    // MARK: - Network

    let apiClient: APIClientProtocol

    // MARK: - Repositories

    let authRepository: AuthRepositoryProtocol
    let contentRepository: ContentRepositoryProtocol
    let postRepository: PostRepositoryProtocol
    let aiRepository: AIRepositoryProtocol

    // MARK: - Use Cases

    let authUseCase: AuthUseCaseProtocol
    let fetchArticlesUseCase: FetchArticlesUseCaseProtocol
    let fetchProductsUseCase: FetchProductsUseCaseProtocol
    let createPostUseCase: CreatePostUseCaseProtocol
    let schedulePostUseCase: SchedulePostUseCaseProtocol
    let generateContentUseCase: GenerateContentUseCaseProtocol

    init() {
        // Infrastructure
        self.keychainManager = KeychainManager.shared
        self.persistenceController = PersistenceController.shared
        self.networkMonitor = NetworkMonitor.shared

        // Network
        self.apiClient = APIClient(
            baseURL: Constants.API.baseURL,
            keychainManager: keychainManager
        )

        // Repositories
        let modelContext = persistenceController.container.mainContext

        self.authRepository = AuthRepository(
            apiClient: apiClient,
            keychainManager: keychainManager
        )

        self.contentRepository = ContentRepository(
            apiClient: apiClient,
            modelContext: modelContext
        )

        self.postRepository = PostRepository(
            apiClient: apiClient,
            modelContext: modelContext
        )

        self.aiRepository = AIRepository(
            apiClient: apiClient,
            baseURL: Constants.API.baseURL
        )

        // Use Cases
        self.authUseCase = AuthUseCase(authRepository: authRepository)
        self.fetchArticlesUseCase = FetchArticlesUseCase(contentRepository: contentRepository)
        self.fetchProductsUseCase = FetchProductsUseCase(contentRepository: contentRepository)
        self.createPostUseCase = CreatePostUseCase(postRepository: postRepository)
        self.schedulePostUseCase = SchedulePostUseCase(postRepository: postRepository)
        self.generateContentUseCase = GenerateContentUseCase(aiRepository: aiRepository)
    }

    // MARK: - ViewModel Factories

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(fetchArticlesUseCase: fetchArticlesUseCase)
    }

    func makeProductsViewModel() -> ProductsViewModel {
        ProductsViewModel(fetchProductsUseCase: fetchProductsUseCase)
    }

    func makeComposerViewModel() -> ComposerViewModel {
        ComposerViewModel(
            createPostUseCase: createPostUseCase,
            schedulePostUseCase: schedulePostUseCase,
            generateContentUseCase: generateContentUseCase
        )
    }

    func makeAIAssistantViewModel() -> AIAssistantViewModel {
        AIAssistantViewModel(generateContentUseCase: generateContentUseCase)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            authUseCase: authUseCase,
            postRepository: postRepository
        )
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authUseCase: authUseCase)
    }
}
