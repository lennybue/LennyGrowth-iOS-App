import SwiftUI

@main
struct LennyGrowthApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var storeKitManager  = StoreKitManager()
    @StateObject private var notificationMgr  = NotificationManager.shared
    @StateObject private var deepLinkHandler  = DeepLinkHandler()
    @StateObject private var oauthHandler     = OAuthCallbackHandler()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let keychain      = KeychainWrapper()
        let tokenManager  = TokenManager(keychain: keychain)
        let client        = APIClient(tokenManager: tokenManager)
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
                .environmentObject(storeKitManager)
                .environmentObject(notificationMgr)
                .environmentObject(deepLinkHandler)
                .environmentObject(oauthHandler)
                .preferredColorScheme(.dark)
                .task { await authViewModel.restoreSession() }
                .task { await storeKitManager.checkEntitlements() }
                .onOpenURL { url in
                    if url.scheme == "lennygrowth" {
                        deepLinkHandler.handle(url)
                    } else if url.host == "lennardbuessow.digital" {
                        deepLinkHandler.handleUniversalLink(url)
                    }
                }
        }
    }
}

// MARK: – Root view (onboarding gate + auth gate + offline banner)

struct RootView: View {
    @EnvironmentObject private var authViewModel:   AuthViewModel
    @EnvironmentObject private var networkMonitor:  NetworkMonitor
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView(onComplete: { hasCompletedOnboarding = true })
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                        .onReceive(deepLinkHandler.$pendingTab.compacted()) { tab in
                            // Forward to MainTabView via notification
                            NotificationCenter.default.post(
                                name: .navigateToTab,
                                object: tab
                            )
                        }
                } else {
                    AuthView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)

            // Offline banner
            if !networkMonitor.isConnected {
                OfflineBanner(pendingSyncs: syncCoordinator.pendingCount)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4), value: networkMonitor.isConnected)
    }
}

// MARK: – Offline Banner

struct OfflineBanner: View {
    let pendingSyncs: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .semibold))

            if pendingSyncs > 0 {
                Text("Offline – \(pendingSyncs) Entwurf(e) werden synchronisiert sobald du online bist.")
                    .font(.lgCaption)
            } else {
                Text("Keine Internetverbindung")
                    .font(.lgCaption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.85))
        .padding(.top, 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline-Modus aktiv")
    }
}

// MARK: – Notification name

extension Notification.Name {
    static let navigateToTab = Notification.Name("com.lennardbuessow.lennygrowth.navigateToTab")
}
