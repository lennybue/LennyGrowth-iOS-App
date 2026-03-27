import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - State
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var showSignUp: Bool = false

    // MARK: - Form
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""

    private let authUseCase: any AuthUseCaseProtocol

    init(authUseCase: any AuthUseCaseProtocol) {
        self.authUseCase = authUseCase
    }

    // MARK: - Session restore

    func restoreSession() async {
        if authUseCase.isAuthenticated {
            do {
                let user = try await authUseCase.fetchCurrentUser()
                currentUser = user
                isAuthenticated = true
            } catch {
                isAuthenticated = false
            }
        }
    }

    // MARK: - Auth actions

    func signIn() async {
        isLoading = true
        error = nil
        do {
            let user = try await authUseCase.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch let authError as AuthError {
            error = authError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signUp() async {
        isLoading = true
        error = nil
        do {
            let user = try await authUseCase.signUp(email: email, password: password, displayName: displayName)
            currentUser = user
            isAuthenticated = true
        } catch let authError as AuthError {
            error = authError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signInWithApple(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        switch result {
        case .success(let auth):
            guard
                let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = cred.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let codeData = cred.authorizationCode,
                let code = String(data: codeData, encoding: .utf8)
            else {
                error = String(localized: "Apple Sign-In fehlgeschlagen.")
                isLoading = false
                return
            }
            let fullName = [cred.fullName?.givenName, cred.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            do {
                let user = try await authUseCase.signInWithApple(
                    identityToken: token,
                    authorizationCode: code,
                    fullName: fullName.isEmpty ? nil : fullName
                )
                currentUser = user
                isAuthenticated = true
            } catch {
                self.error = error.localizedDescription
            }
        case .failure(let err):
            if (err as NSError).code != ASAuthorizationError.canceled.rawValue {
                self.error = err.localizedDescription
            }
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await authUseCase.signOut()
        } catch {}
        currentUser = nil
        isAuthenticated = false
        email = ""
        password = ""
    }

    func resetPassword() async {
        guard !email.isEmpty else {
            error = String(localized: "Bitte gib deine E-Mail-Adresse ein.")
            return
        }
        isLoading = true
        error = nil
        do {
            try await authUseCase.resetPassword(email: email)
        } catch let authError as AuthError {
            error = authError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func clearError() { error = nil }
}
