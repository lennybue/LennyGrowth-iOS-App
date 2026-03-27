import SwiftUI

// MARK: - Button Styles

enum LGButtonStyle {
    case primary    // Neon Magenta, filled
    case secondary  // Neon Teal, filled
    case ghost      // Transparent with border
    case destructive
}

struct LGButton: View {
    let title: String
    let style: LGButtonStyle
    var icon: String? = nil
    var isLoading: Bool = false
    var isFullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.8)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.lgBodySemibold)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(borderView)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .if(style == .primary) { $0.glow(color: .neonMagenta, radius: 8) }
        .if(style == .secondary) { $0.glow(color: .neonTeal, radius: 8) }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:     Color.neonMagenta
        case .secondary:   Color.neonTeal
        case .ghost:       Color.clear
        case .destructive: Color.red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary: .white
        case .ghost:               .textPrimary
        case .destructive:         .red
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .ghost:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.glassBorder, lineWidth: 1)
        case .destructive:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Conditional modifier helper

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}
