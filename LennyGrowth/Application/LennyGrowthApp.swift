import SwiftUI

@main
struct LennyGrowthApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let keychain = KeychainWrapper()
        let authRepo = MockAuthRepository(keychain: keychain)
        let useCase = AuthUseCase(authRepository: authRepo)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authUseCase: useCase))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(container)
                        .environmentObject(authViewModel)
                } else {
                    AuthView()
                        .environmentObject(container)
                        .environmentObject(authViewModel)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await authViewModel.restoreSession()
            }
        }
    }
}
