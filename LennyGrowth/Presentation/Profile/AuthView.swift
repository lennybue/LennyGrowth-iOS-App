import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject var viewModel: AuthViewModel
    @State private var showForgotPassword = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                // Tab Picker
                Picker("Auth Mode", selection: $viewModel.selectedTab) {
                    ForEach(AuthViewModel.AuthTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                // Form
                VStack(spacing: 16) {
                    if viewModel.selectedTab == .signIn {
                        signInForm
                    } else {
                        signUpForm
                    }

                    // Error message
                    if let error = viewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }

                    // Submit button
                    Button {
                        Task {
                            if viewModel.selectedTab == .signIn {
                                await viewModel.signIn()
                            } else {
                                await viewModel.signUp()
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(viewModel.selectedTab == .signIn ? "Sign In" : "Create Account")
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(viewModel.selectedTab == .signIn ? !viewModel.canSignIn : !viewModel.canSignUp)
                    .disabled(viewModel.isLoading)

                    // Divider
                    HStack {
                        Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await viewModel.handleSignInWithApple(result: result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(Constants.UI.cornerRadius)

                    // Forgot password
                    if viewModel.selectedTab == .signIn {
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.primaryBrand)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTab)
                .animation(.easeInOut(duration: 0.2), value: viewModel.error?.localizedDescription)

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email address", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Button("Send Reset Link") {
                Task { await viewModel.resetPassword() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .onChange(of: viewModel.selectedTab) { _, _ in
            viewModel.clearFields()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryBrand, Color.secondaryBrand],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Text("LG")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text("LennyGrowth")
                .font(.title2)
                .fontWeight(.bold)

            Text("Grow your audience with smarter content")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var signInForm: some View {
        VStack(spacing: 14) {
            LGTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .none
            )

            LGTextField(
                title: "Password",
                placeholder: "••••••••",
                text: $viewModel.password,
                textContentType: .password,
                isSecure: true
            )
        }
    }

    private var signUpForm: some View {
        VStack(spacing: 14) {
            LGTextField(
                title: "Full Name",
                placeholder: "Your name",
                text: $viewModel.displayName,
                textContentType: .name,
                autocapitalization: .words
            )

            LGTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .none
            )

            LGTextField(
                title: "Password",
                placeholder: "At least 8 characters",
                text: $viewModel.password,
                textContentType: .newPassword,
                isSecure: true
            )

            LGTextField(
                title: "Confirm Password",
                placeholder: "Repeat your password",
                text: $viewModel.confirmPassword,
                textContentType: .newPassword,
                isSecure: true,
                validationState: viewModel.passwordMismatch ? .error("Passwords don't match") : .none
            )
        }
    }
}

// MARK: - LGTextField

struct LGTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var validationState: ValidationState = .none

    enum ValidationState {
        case none
        case error(String)
        case success

        var message: String? {
            if case .error(let msg) = self { return msg }
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )

            if case .error(let message) = validationState {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var borderColor: Color {
        switch validationState {
        case .error: return .red
        case .success: return .green
        case .none: return Color(.systemGray4)
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(authUseCase: PreviewAuthUseCase()))
}

private final class PreviewAuthUseCase: AuthUseCaseProtocol {
    var isAuthenticated: Bool = false
    func signIn(email: String, password: String) async throws -> User { .empty() }
    func signUp(email: String, password: String, displayName: String) async throws -> User { .empty() }
    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> User { .empty() }
    func signOut() async throws {}
    func fetchCurrentUser() async throws -> User { .empty() }
    func updateProfile(displayName: String?, bio: String?, avatarURL: URL?) async throws -> User { .empty() }
    func resetPassword(email: String) async throws {}
}
