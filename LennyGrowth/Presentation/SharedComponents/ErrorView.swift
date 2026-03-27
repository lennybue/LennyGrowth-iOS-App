import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?

    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: errorIcon)
                .font(.system(size: 56))
                .foregroundColor(errorColor)

            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let retry = retryAction {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.primaryBrand)
            }
        }
        .padding(Constants.UI.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorIcon: String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noInternetConnection: return "wifi.slash"
            case .unauthorized: return "lock.circle"
            case .serverError: return "exclamationmark.triangle"
            default: return "exclamationmark.circle"
            }
        }
        return "exclamationmark.circle"
    }

    private var errorColor: Color {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noInternetConnection: return .orange
            case .unauthorized: return .red
            default: return .red
            }
        }
        return .red
    }

    private var errorTitle: String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noInternetConnection: return "No Internet Connection"
            case .unauthorized: return "Session Expired"
            case .serverError: return "Server Error"
            case .notFound: return "Not Found"
            default: return "Something Went Wrong"
            }
        }
        return "Something Went Wrong"
    }
}

struct InlineErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if let retry = retryAction {
                Button("Retry", action: retry)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryBrand)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(Constants.UI.smallCornerRadius)
    }
}

#Preview {
    ErrorView(error: NetworkError.noInternetConnection) {
        print("Retry tapped")
    }
}
