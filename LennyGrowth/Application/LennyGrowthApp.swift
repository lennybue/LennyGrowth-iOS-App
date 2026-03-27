import SwiftUI

@main
struct LennyGrowthApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var authViewModel: AuthViewModel

    init() {
        // Auth is constructed independently so it's available before container is fully wired.
        // Uses the same keychain instance as the container.
        let keychain = KeychainWrapper()
        let tokenManager = TokenManager(keychain: keychain)
        let client = APIClient(tokenManager: tokenManager)
        let authRepo: any AuthRepositoryProtocol

        switch AppEnvironment.current {
        case .mock:
            authRepo = MockAuthRepository(keychain: keychain)
        case .production:
            authRepo = NetworkAuthRepository(client: client, tokenManager: tokenManager, keychain: keychain)
        }

        _authViewModel = StateObject(
            wrappedValue: AuthViewModel(authUseCase: AuthUseCase(authRepository: authRepo))
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(authViewModel)
                .environmentObject(container.networkMonitor)
                .environmentObject(container.syncCoordinator)
                .preferredColorScheme(.dark)
                .task { await authViewModel.restoreSession() }
        }
    }
}

// MARK: - Root view (auth gate + offline banner)

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var syncCoordinator: SyncCoordinator

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    AuthView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)

            // Offline banner
            if !networkMonitor.isConnected {
                OfflineBanner(pendingSyncs: syncCoordinator.pendingCount)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4), value: networkMonitor.isConnected)
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if !isAuth {
                // Clear sensitive data on logout
            }
        }
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    let pendingSyncs: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .semibold))

            if pendingSyncs > 0 {
                Text(String(localized: "Offline – \(pendingSyncs) Entwurf(e) werden synchronisiert sobald du online bist."))
                    .font(.lgCaption)
            } else {
                Text(String(localized: "Keine Internetverbindung"))
                    .font(.lgCaption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.85))
        .padding(.top, 1) // below Dynamic Island / notch
    }
}
