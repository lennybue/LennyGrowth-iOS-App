import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""
    @Published var selectedTab: AuthTab = .signIn

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error? = nil
    @Published private(set) var isAuthenticated: Bool = false

    private var authUseCase: AuthUseCaseProtocol

    enum AuthTab: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
    }

    init(authUseCase: AuthUseCaseProtocol) {
        self.authUseCase = authUseCase
        self.isAuthenticated = authUseCase.isAuthenticated
    }

    func updateUseCase(_ useCase: AuthUseCaseProtocol) {
        self.authUseCase = useCase
        self.isAuthenticated = useCase.isAuthenticated
    }

    func checkAuthentication() {
        isAuthenticated = authUseCase.isAuthenticated
    }

    var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    var canSignUp: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        password == confirmPassword
    }

    var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    func signIn() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            _ = try await authUseCase.signIn(email: email, password: password)
            isAuthenticated = true
            NotificationCenter.default.post(name: .userDidSignIn, object: nil)
        } catch {
            self.error = error
        }
    }

    func signUp() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            _ = try await authUseCase.signUp(email: email, password: password, displayName: displayName)
            isAuthenticated = true
            NotificationCenter.default.post(name: .userDidSignIn, object: nil)
        } catch {
            self.error = error
        }
    }

    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let codeData = credential.authorizationCode,
                  let code = String(data: codeData, encoding: .utf8) else {
                self.error = AuthError.notAuthenticated
                return
            }

            let fullName: String?
            if let nameComponents = credential.fullName {
                let parts = [nameComponents.givenName, nameComponents.familyName].compactMap { $0 }
                fullName = parts.isEmpty ? nil : parts.joined(separator: " ")
            } else {
                fullName = nil
            }

            isLoading = true
            error = nil
            defer { isLoading = false }

            do {
                _ = try await authUseCase.signInWithApple(
                    identityToken: token,
                    authorizationCode: code,
                    fullName: fullName
                )
                isAuthenticated = true
                NotificationCenter.default.post(name: .userDidSignIn, object: nil)
            } catch {
                self.error = error
            }

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                self.error = error
            }
        }
    }

    func resetPassword() async {
        guard !email.isEmpty else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await authUseCase.resetPassword(email: email)
        } catch {
            self.error = error
        }
    }

    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        error = nil
    }
}
