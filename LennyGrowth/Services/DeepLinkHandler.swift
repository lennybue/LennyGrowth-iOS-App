import Foundation
import SwiftUI

/// Handles custom URL scheme `lennygrowth://` and universal links
/// from `https://lennardbuessow.digital/app/*`
@MainActor
final class DeepLinkHandler: ObservableObject {

    @Published var pendingTab: Int?
    @Published var pendingOAuthCode: String?
    @Published var pendingOAuthPlatform: String?
    @Published var pendingArticleId: String?

    // MARK: – Custom scheme: lennygrowth://

    func handle(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch components.host {
        case "feed":
            pendingTab = 0
        case "compose":
            pendingTab = 2
        case "ai":
            pendingTab = 3
        case "profile":
            pendingTab = 4
        case "oauth":
            handleOAuth(components: components)
        case "article":
            pendingArticleId = components.queryItems?.first(where: { $0.name == "id" })?.value
            pendingTab = 0
        default:
            break
        }
    }

    // MARK: – Universal links: https://lennardbuessow.digital/app/*

    func handleUniversalLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let path = components.path

        if path.hasPrefix("/app/feed") {
            pendingTab = 0
        } else if path.hasPrefix("/app/compose") {
            pendingTab = 2
        } else if path.hasPrefix("/app/profile") {
            pendingTab = 4
        } else if path.hasPrefix("/app/oauth") {
            handleOAuth(components: components)
        }
    }

    // MARK: – OAuth callback

    private func handleOAuth(components: URLComponents) {
        let code     = components.queryItems?.first(where: { $0.name == "code" })?.value
        let platform = components.queryItems?.first(where: { $0.name == "platform" })?.value
        guard let code, let platform else { return }
        pendingOAuthCode     = code
        pendingOAuthPlatform = platform
    }

    func clearOAuthCallback() {
        pendingOAuthCode     = nil
        pendingOAuthPlatform = nil
    }
}
