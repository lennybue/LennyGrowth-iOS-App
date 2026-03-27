import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var container: DependencyContainer
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tag(0)
                .tabItem {
                    Label(String(localized: "Feed"), systemImage: selectedTab == 0 ? "newspaper.fill" : "newspaper")
                }

            ProductsView()
                .tag(1)
                .tabItem {
                    Label(String(localized: "Produkte"), systemImage: selectedTab == 1 ? "bag.fill" : "bag")
                }

            ComposerView()
                .tag(2)
                .tabItem {
                    Label(String(localized: "Compose"), systemImage: selectedTab == 2 ? "plus.circle.fill" : "plus.circle")
                }

            AIAssistantTabView()
                .tag(3)
                .tabItem {
                    Label(String(localized: "KI"), systemImage: selectedTab == 3 ? "sparkles" : "sparkle")
                }

            ProfileView()
                .tag(4)
                .tabItem {
                    Label(String(localized: "Profil"), systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
        }
        .tint(.neonMagenta)
        .onAppear {
            styleTabBar()
        }
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bgSurface)

        let normalAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.textSecondary)
        ]
        let selectedAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.neonMagenta)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedAttr

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - AI Assistant as standalone tab

struct AIAssistantTabView: View {
    @State private var showSheet: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(.neonMagenta)
                        .glow(color: .neonMagenta, radius: 20)

                    VStack(spacing: 10) {
                        Text(String(localized: "KI-Assistent"))
                            .font(.lgDisplayLG)
                            .foregroundColor(.textPrimary)
                        Text(String(localized: "Generiere LinkedIn- und Threads-Posts\nmit KI-Unterstützung."))
                            .font(.lgBodyMD)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    LGButton(
                        title: String(localized: "Post generieren"),
                        style: .primary,
                        icon: "sparkles",
                        isFullWidth: false
                    ) {
                        showSheet = true
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationTitle("KI")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .sheet(isPresented: $showSheet) {
                AIAssistantView()
            }
        }
    }
}
