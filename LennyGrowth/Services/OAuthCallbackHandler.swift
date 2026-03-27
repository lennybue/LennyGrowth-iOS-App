import Foundation
import SwiftUI

@MainActor
final class OAuthCallbackHandler: ObservableObject {

    @Published var isConnecting = false
    @Published var connectedPlatform: String?
    @Published var errorMessage: String?

    // Replace with your actual LinkedIn Client ID from the LinkedIn Developer Portal
    private let linkedInClientId = "YOUR_LINKEDIN_CLIENT_ID"
    // Replace with your actual Threads / Meta App ID
    private let threadsAppId     = "YOUR_THREADS_APP_ID"

    // The iOS deep link redirect URI registered in LinkedIn/Threads OAuth settings
    private let redirectURI = "lennygrowth://oauth/callback"

    // MARK: – Authorization URLs

    func linkedInAuthURL() -> URL {
        var components = URLComponents(string: "https://www.linkedin.com/oauth/v2/authorization")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id",     value: linkedInClientId),
            URLQueryItem(name: "redirect_uri",  value: redirectURI),
            URLQueryItem(name: "scope",         value: "openid profile email w_member_social"),
            URLQueryItem(name: "platform",      value: "linkedin"),
            URLQueryItem(name: "state",         value: UUID().uuidString),
        ]
        return components.url!
    }

    func threadsAuthURL() -> URL {
        var components = URLComponents(string: "https://www.threads.net/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id",     value: threadsAppId),
            URLQueryItem(name: "redirect_uri",  value: redirectURI),
            URLQueryItem(name: "scope",         value: "threads_basic,threads_content_publish"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "platform",      value: "threads"),
            URLQueryItem(name: "state",         value: UUID().uuidString),
        ]
        return components.url!
    }

    // MARK: – Callback handling

    /// Called when the OAuth redirect brings back a code.
    /// Sends the auth code to our backend, which completes the exchange server-side.
    func handleCallback(code: String, platform: String, postRepository: any PostRepositoryProtocol) async {
        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }
        guard let socialPlatform = SocialPlatform(rawValue: platform) else {
            errorMessage = "Unbekannte Plattform: \(platform)"
            return
        }
        do {
            // The `accessToken` parameter carries the OAuth auth code.
            // The backend exchanges it for the real token server-side.
            _ = try await postRepository.connectSocialAccount(platform: socialPlatform, accessToken: code)
            connectedPlatform = platform
        } catch {
            errorMessage = "Verbindung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
