import SwiftUI

// MARK: - PaywallView

struct PaywallView: View {
    @EnvironmentObject private var storeKitManager: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var showError = false
    @State private var errorMessage = ""

    private let features: [(icon: String, text: String)] = [
        ("infinity",                  "Unbegrenzte KI-Generierungen"),
        ("star.fill",                 "Alle Premium-Produkte & Templates"),
        ("chart.bar.xaxis",           "Erweiterte Analytics"),
        ("headphones",                "Priority Support")
    ]

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    contentSection
                }
            }

            // Loading overlay
            if storeKitManager.isPurchasing {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.neonMagenta)
                        .scaleEffect(1.4)
                    Text("Wird verarbeitet…")
                        .font(.lgBody)
                        .foregroundColor(.textSecondary)
                }
                .glassCard(cornerRadius: 20, padding: 32)
            }
        }
        .alert("Fehler", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await storeKitManager.loadProducts()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .topTrailing) {
            // Gradient background
            LinearGradient(
                colors: [.neonMagenta, .iceBlue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 260)
            .overlay(alignment: .center) {
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                        .glow(color: .white, radius: 20)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                    Text("LennyGrowth Pro")
                        .font(.lgLargeTitle)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }
            }

            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding([.top, .trailing], 20)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(spacing: 28) {
            // Features list
            VStack(alignment: .leading, spacing: 16) {
                Text("Alles inklusive")
                    .font(.lgHeadline)
                    .foregroundColor(.textPrimary)

                ForEach(features, id: \.text) { feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.neonTeal)
                            .frame(width: 24)
                            .glow(color: .neonTeal, radius: 6)

                        Text(feature.text)
                            .font(.lgBody)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .glassCard(cornerRadius: 20, padding: 20)
            .padding(.horizontal, 20)

            // Price display
            VStack(spacing: 4) {
                Text("€9,99/Monat")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.neonMagenta)
                    .glow(color: .neonMagenta, radius: 10)

                Text("Jederzeit kündbar")
                    .font(.lgCaption)
                    .foregroundColor(.textSecondary)
            }

            // CTA buttons
            VStack(spacing: 12) {
                LGButton(
                    title: "Pro werden",
                    style: .primary,
                    icon: "crown.fill",
                    isLoading: storeKitManager.isPurchasing,
                    isFullWidth: true
                ) {
                    purchasePro()
                }

                LGButton(
                    title: "Käufe wiederherstellen",
                    style: .ghost,
                    isFullWidth: true
                ) {
                    Task { await storeKitManager.restorePurchases() }
                }

                Button("Später") {
                    dismiss()
                }
                .font(.lgCaption)
                .foregroundColor(.textSecondary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)

            // Legal
            Text("Durch den Kauf stimmst du den Nutzungsbedingungen und Datenschutzrichtlinien von Apple zu. Das Abonnement verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ende der aktuellen Laufzeit gekündigt wird.")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .padding(.top, 28)
    }

    // MARK: - Actions

    private func purchasePro() {
        Task {
            do {
                try await storeKitManager.purchase()
                if storeKitManager.hasPro {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(StoreKitManager())
        .preferredColorScheme(.dark)
}
