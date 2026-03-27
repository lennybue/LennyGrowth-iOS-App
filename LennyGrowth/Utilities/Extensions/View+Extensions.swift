import SwiftUI

extension View {
    func cardStyle(cornerRadius: CGFloat = Constants.UI.cornerRadius) -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.08), radius: Constants.UI.cardShadowRadius, x: 0, y: 2)
    }

    func primaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primaryBrand)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(Constants.UI.cornerRadius)
    }

    func secondaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primaryBrand.opacity(0.1))
            .foregroundColor(Color.primaryBrand)
            .font(.headline)
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(Color.primaryBrand, lineWidth: 1)
            )
    }

    func shimmerEffect(isLoading: Bool) -> some View {
        self.modifier(ShimmerModifier(isLoading: isLoading))
    }

    func onFirstAppear(perform action: @escaping () async -> Void) -> some View {
        self.modifier(OnFirstAppearModifier(action: action))
    }

    func errorAlert(error: Binding<Error?>) -> some View {
        self.alert(
            "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            actions: {
                Button("OK") { error.wrappedValue = nil }
            },
            message: {
                if let err = error.wrappedValue {
                    Text(err.localizedDescription)
                }
            }
        )
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.6), location: 0.3),
                                .init(color: .clear, location: 0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                        .animation(
                            Animation.linear(duration: 1.2).repeatForever(autoreverses: false),
                            value: phase
                        )
                    }
                )
                .onAppear { phase = 1 }
                .clipped()
        } else {
            content
        }
    }
}

// MARK: - OnFirstAppear Modifier

struct OnFirstAppearModifier: ViewModifier {
    let action: () async -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.task {
            guard !hasAppeared else { return }
            hasAppeared = true
            await action()
        }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
