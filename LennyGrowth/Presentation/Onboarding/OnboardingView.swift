import SwiftUI

// MARK: - Onboarding Slide Model

private struct OnboardingSlide {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "rocket.fill",
            title: "Dein KI-gestützter\nContent Assistant",
            subtitle: "Erstelle viralen Content für LinkedIn & Threads in Sekunden",
            accentColor: .neonMagenta
        ),
        OnboardingSlide(
            icon: "chart.line.uptrend.xyaxis",
            title: "Smarte Planung\n& Analytics",
            subtitle: "Plane Posts für optimale Reichweite und tracke deine Performance",
            accentColor: .neonTeal
        ),
        OnboardingSlide(
            icon: "person.fill.checkmark",
            title: "Lerne von\nLennard Büssow",
            subtitle: "Exklusive Artikel, Templates & Playbooks vom DACH Growth-Experten",
            accentColor: .iceBlue
        )
    ]

    var isLastSlide: Bool { currentPage == slides.count - 1 }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if !isLastSlide {
                        Button("Überspringen") {
                            completeOnboarding()
                        }
                        .font(.lgBody)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 52)

                // Slide pager
                TabView(selection: $currentPage) {
                    ForEach(slides.indices, id: \.self) { index in
                        SlideView(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Dot indicator
                HStack(spacing: 8) {
                    ForEach(slides.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? slides[currentPage].accentColor : Color.glassBorder)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action buttons
                VStack(spacing: 12) {
                    LGButton(
                        title: isLastSlide ? "Loslegen" : "Weiter",
                        style: .primary,
                        icon: isLastSlide ? "arrow.right.circle.fill" : nil,
                        isFullWidth: true
                    ) {
                        if isLastSlide {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    if isLastSlide {
                        Button("Ich habe bereits ein Konto") {
                            completeOnboarding()
                        }
                        .font(.lgCaption)
                        .foregroundColor(.textSecondary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - SlideView

private struct SlideView: View {
    let slide: OnboardingSlide
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon card
            ZStack {
                Circle()
                    .fill(slide.accentColor.opacity(0.12))
                    .frame(width: 140, height: 140)

                Circle()
                    .strokeBorder(slide.accentColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 140, height: 140)

                Image(systemName: slide.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [slide.accentColor, slide.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .glow(color: slide.accentColor, radius: 16)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            // Text content
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.lgTitle)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(slide.subtitle)
                    .font(.lgBody)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .glassCard(cornerRadius: 20, padding: 24)
            .padding(.horizontal, 24)
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
