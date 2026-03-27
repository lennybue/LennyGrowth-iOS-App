import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var container: DependencyContainer
    @StateObject private var viewModel: ProfileViewModel

    init() {
        let keychain = KeychainWrapper()
        let authRepo = MockAuthRepository(keychain: keychain)
        let useCase = AuthUseCase(authRepository: authRepo)
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            postRepository: MockPostRepository(),
            authUseCase: useCase
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        userHeader
                        connectedAccountsSection
                        settingsSection
                        aboutSection
                        signOutButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        }
        .task {
            await viewModel.loadConnectedAccounts()
        }
    }

    // MARK: - User header

    private var userHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(colors: [.neonMagenta, .neonTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Text(authViewModel.currentUser.map { String($0.displayName.prefix(1)) } ?? "L")
                        .font(.lgDisplaySM)
                        .foregroundColor(.white)
                )
                .glow(color: .neonMagenta, radius: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.currentUser?.displayName ?? "Lennard Büssow")
                    .font(.lgDisplaySM)
                    .foregroundColor(.textPrimary)

                Text(authViewModel.currentUser?.email ?? "hello@lennardbuessow.digital")
                    .font(.lgBodySM)
                    .foregroundColor(.textSecondary)

                if let tier = authViewModel.currentUser?.subscriptionTier {
                    CategoryBadge(
                        text: tier.displayName,
                        color: tier == .pro ? .neonMagenta : .iceBlue
                    )
                }
            }

            Spacer()
        }
        .padding(16)
        .glassCard(padding: 0)
    }

    // MARK: - Connected accounts

    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Verbundene Accounts"))
                .font(.lgDisplaySM)
                .foregroundColor(.textPrimary)

            VStack(spacing: 1) {
                socialAccountRow(
                    platform: .linkedin,
                    account: viewModel.connectedAccounts.first(where: { $0.platform == .linkedin })
                )
                Divider().background(Color.glassBorder)
                socialAccountRow(
                    platform: .threads,
                    account: viewModel.connectedAccounts.first(where: { $0.platform == .threads })
                )
            }
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.glassBorder, lineWidth: 1)
            )
        }
    }

    private func socialAccountRow(platform: SocialPlatform, account: ConnectedAccount?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: platform.iconSystemName)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: platform.brandColorHex))
                .frame(width: 36, height: 36)
                .background(Color(hex: platform.brandColorHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(platform.displayName)
                    .font(.lgBodySemibold)
                    .foregroundColor(.textPrimary)
                if let acc = account {
                    Text(acc.displayHandle)
                        .font(.lgBodySM)
                        .foregroundColor(.neonTeal)
                    if let count = acc.followerCount {
                        Text("\(count.compactFormatted) Follower")
                            .font(.lgCaption)
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    Text(String(localized: "Nicht verbunden"))
                        .font(.lgBodySM)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            if account != nil {
                Button {
                    Task {
                        if let acc = account { await viewModel.disconnect(account: acc) }
                    }
                } label: {
                    Text(String(localized: "Trennen"))
                        .font(.lgCaption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Task {
                        if platform == .linkedin { await viewModel.connectLinkedIn() }
                        else { await viewModel.connectThreads() }
                    }
                } label: {
                    Text(String(localized: "Verbinden"))
                        .font(.lgCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.neonTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.neonTeal.opacity(0.1))
                        .overlay(
                            Capsule().strokeBorder(Color.neonTeal.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Einstellungen"))
                .font(.lgDisplaySM)
                .foregroundColor(.textPrimary)

            VStack(spacing: 1) {
                settingsRow(icon: "bell", title: String(localized: "Benachrichtigungen"))
                Divider().background(Color.glassBorder)
                Button {
                    viewModel.clearCache()
                } label: {
                    settingsRow(icon: "trash", title: String(localized: "Cache leeren"), isDestructive: false)
                }
                .buttonStyle(.plain)
                Divider().background(Color.glassBorder)
                Link(destination: Constants.URLs.support) {
                    settingsRow(icon: "questionmark.circle", title: String(localized: "Support"))
                }
                Divider().background(Color.glassBorder)
                Link(destination: Constants.URLs.privacyPolicy) {
                    settingsRow(icon: "hand.raised", title: String(localized: "Datenschutz"))
                }
            }
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.glassBorder, lineWidth: 1)
            )
        }
    }

    private func settingsRow(icon: String, title: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isDestructive ? .red : .textSecondary)
                .frame(width: 28)
            Text(title)
                .font(.lgBodyMD)
                .foregroundColor(isDestructive ? .red : .textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Über Lenny"))
                .font(.lgDisplaySM)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                Text(String(localized: "Lennard Büssow ist Digital Marketing Specialist & IT-Consultant aus dem DACH-Raum. Spezialist für SEO, SEA, KI-Marketing und Conversion Rate Optimization."))
                    .font(.lgBodySM)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: 10) {
                    Link(destination: Constants.URLs.website) {
                        LGButton(title: "Website", style: .ghost, icon: "globe") {}
                    }
                    Link(destination: Constants.URLs.linkHub) {
                        LGButton(title: "Links", style: .ghost, icon: "link") {}
                    }
                }
            }
            .padding(16)
            .glassCard(padding: 0)
        }
    }

    // MARK: - Sign out

    private var signOutButton: some View {
        LGButton(
            title: String(localized: "Abmelden"),
            style: .ghost,
            icon: "rectangle.portrait.and.arrow.right",
            isFullWidth: true
        ) {
            Task { await authViewModel.signOut() }
        }
        .padding(.top, 8)
    }
}
