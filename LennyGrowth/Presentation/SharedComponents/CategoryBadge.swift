import SwiftUI

struct CategoryBadge: View {
    let text: String
    var color: Color = .iceBlue
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.lgCaption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let status: PostStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .glow(color: color, radius: 4)
    }

    private var color: Color {
        switch status {
        case .scheduled:  .iceBlue
        case .published:  .neonTeal
        case .failed:     .red
        case .draft:      .textSecondary
        case .publishing: .neonMagenta
        }
    }
}

// MARK: - Platform Badge

struct PlatformBadge: View {
    let platform: SocialPlatform

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: platform.iconName)
                .font(.system(size: 11, weight: .semibold))
            Text(platform.displayName)
                .font(.lgCaption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(hex: platform.brandColorHex).opacity(0.85))
        )
    }
}
