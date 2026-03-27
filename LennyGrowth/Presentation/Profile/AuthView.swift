import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            // Background gradient glow
            RadialGradient(
                colors: [Color.neonMagenta.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + tagline
                VStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.neonMagenta)
                        .glow(color: .neonMagenta, radius: 20)

                    Text("LennyGrowth")
                        .font(.lgDisplayXL)
                        .foregroundColor(.textPrimary)

                    Text(String(localized: "Marketing mit KI. Content mit System."))
                        .font(.lgBodyMD)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 48)

                // Auth cards
                if authViewModel.showSignUp {
                    SignUpCard()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    LoginCard()
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .trailing)
                        ))
                }

                Spacer()

                // Legal
                Text(String(localized: "Mit der Anmeldung stimmst du unserer [Datenschutzrichtlinie](https://lennardbuessow.digital/privacy) zu."))
                    .font(.lgCaption)
                    .foregroundColor(.textSecondary)
                    .tint(.iceBlue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
            .animation(.spring(response: 0.4), value: authViewModel.showSignUp)
        }
    }
}

// MARK: - Login Card

struct LoginCard: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @FocusState private var focus: Field?

    enum Field { case email, password }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                LGTextField(
                    title: String(localized: "E-Mail"),
                    text: $authViewModel.email,
                    placeholder: "hello@example.de",
                    keyboardType: .emailAddress,
                    submitLabel: .next
                ) { focus = .password }

                LGTextField(
                    title: String(localized: "Passwort"),
                    text: $authViewModel.password,
                    placeholder: "••••••••",
                    isSecure: true,
                    submitLabel: .go
                ) { Task { await authViewModel.signIn() } }
            }

            if let error = authViewModel.error {
                Text(error)
                    .font(.lgBodySM)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            LGButton(
                title: String(localized: "Anmelden"),
                style: .primary,
                isLoading: authViewModel.isLoading,
                isFullWidth: true
            ) {
                Task { await authViewModel.signIn() }
            }

            HStack(alignment: .center) {
                Rectangle().fill(Color.glassBorder).frame(height: 1)
                Text(String(localized: "oder")).font(.lgCaption).foregroundColor(.textSecondary).padding(.horizontal, 12)
                Rectangle().fill(Color.glassBorder).frame(height: 1)
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await authViewModel.signInWithApple(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                authViewModel.showSignUp = true
            } label: {
                HStack(spacing: 4) {
                    Text(String(localized: "Noch kein Account?"))
                        .foregroundColor(.textSecondary)
                    Text(String(localized: "Registrieren"))
                        .foregroundColor(.iceBlue)
                        .fontWeight(.semibold)
                }
                .font(.lgBodySM)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .glassCard(padding: 0)
        .padding(.horizontal, 24)
    }
}

// MARK: - Sign Up Card

struct SignUpCard: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                LGTextField(
                    title: String(localized: "Name"),
                    text: $authViewModel.displayName,
                    placeholder: "Lennard Büssow",
                    submitLabel: .next
                )
                LGTextField(
                    title: String(localized: "E-Mail"),
                    text: $authViewModel.email,
                    placeholder: "hello@example.de",
                    keyboardType: .emailAddress,
                    submitLabel: .next
                )
                LGTextField(
                    title: String(localized: "Passwort"),
                    text: $authViewModel.password,
                    placeholder: "Mind. 8 Zeichen",
                    isSecure: true,
                    submitLabel: .go
                ) { Task { await authViewModel.signUp() } }
            }

            if let error = authViewModel.error {
                Text(error)
                    .font(.lgBodySM)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            LGButton(
                title: String(localized: "Account erstellen"),
                style: .primary,
                isLoading: authViewModel.isLoading,
                isFullWidth: true
            ) {
                Task { await authViewModel.signUp() }
            }

            Button {
                authViewModel.showSignUp = false
            } label: {
                HStack(spacing: 4) {
                    Text(String(localized: "Bereits registriert?"))
                        .foregroundColor(.textSecondary)
                    Text(String(localized: "Anmelden"))
                        .foregroundColor(.iceBlue)
                        .fontWeight(.semibold)
                }
                .font(.lgBodySM)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .glassCard(padding: 0)
        .padding(.horizontal, 24)
    }
}
