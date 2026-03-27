import SwiftUI

// MARK: - Inline loading spinner

struct LGLoadingSpinner: View {
    var color: Color = .neonMagenta
    var size: CGFloat = 32

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(color)
            .scaleEffect(size / 20)
    }
}

// MARK: - Full screen loading overlay

struct FullScreenLoadingView: View {
    var message: String = String(localized: "Lädt…")

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            VStack(spacing: 20) {
                LGLoadingSpinner(size: 40)
                    .glow(color: .neonMagenta, radius: 12)
                Text(message)
                    .font(.lgBodyMD)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Empty state placeholder

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.textSecondary.opacity(0.6))

            VStack(spacing: 6) {
                Text(title)
                    .font(.lgDisplaySM)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.lgBodySM)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                LGButton(title: actionTitle, style: .primary, action: action)
                    .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

// MARK: - Error state view

struct ErrorStateView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: String(localized: "Fehler aufgetreten"),
            subtitle: error.localizedDescription,
            actionTitle: String(localized: "Erneut versuchen"),
            action: retryAction
        )
    }
}

// MARK: - Skeleton loading card

struct SkeletonCard: View {
    var height: CGFloat = 160

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.bgSurface)
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.glassBorder, lineWidth: 1)
            )
            .shimmer()
    }
}
