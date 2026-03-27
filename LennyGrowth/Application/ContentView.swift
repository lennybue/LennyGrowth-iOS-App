import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DependencyContainer
    @StateObject private var authViewModel: AuthViewModel
    @State private var selectedTab: AppTab = .feed
    @State private var showComposer = false

    init() {
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authUseCase: AuthUseCase(authRepository: EmptyAuthRepository())))
    }

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
            } else {
                AuthView(viewModel: container.makeAuthViewModel())
                    .onReceive(NotificationCenter.default.publisher(for: .userDidSignIn)) { _ in
                        authViewModel.checkAuthentication()
                    }
            }
        }
        .onAppear {
            authViewModel.updateUseCase(container.authUseCase)
            authViewModel.checkAuthentication()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            authViewModel.checkAuthentication()
        }
    }

    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    FeedView(viewModel: container.makeFeedViewModel())
                }
                .tag(AppTab.feed)
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }

                NavigationStack {
                    ProductsView(viewModel: container.makeProductsViewModel())
                }
                .tag(AppTab.products)
                .tabItem {
                    Label("Products", systemImage: "bag")
                }

                Color.clear
                    .tag(AppTab.compose)
                    .tabItem {
                        Label("Compose", systemImage: "plus.circle.fill")
                    }

                NavigationStack {
                    PostQueueView(viewModel: container.makeComposerViewModel())
                }
                .tag(AppTab.queue)
                .tabItem {
                    Label("Queue", systemImage: "clock")
                }

                NavigationStack {
                    ProfileView(viewModel: container.makeProfileViewModel())
                }
                .tag(AppTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .compose {
                    showComposer = true
                    selectedTab = .feed
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            NavigationStack {
                ComposerView(viewModel: container.makeComposerViewModel())
            }
        }
    }
}

enum AppTab: Int, CaseIterable {
    case feed = 0
    case products = 1
    case compose = 2
    case queue = 3
    case profile = 4
}

// Empty repository used only for the pre-container init stub
private final class EmptyAuthRepository: AuthRepositoryProtocol {
    var isAuthenticated: Bool { false }
    func signIn(email: String, password: String) async throws -> User { User.empty() }
    func signUp(email: String, password: String, displayName: String) async throws -> User { User.empty() }
    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User { User.empty() }
    func signOut() async throws {}
    func refreshToken() async throws -> String { "" }
    func fetchCurrentUser() async throws -> User { User.empty() }
    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User { User.empty() }
    func deleteAccount() async throws {}
    func resetPassword(email: String) async throws {}
    func getCurrentUserID() -> String? { nil }
}
