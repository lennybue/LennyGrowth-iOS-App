import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noInternetConnection
    case requestTimeout
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case unknown(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please check the request."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .requestTimeout:
            return "The request timed out. Please try again."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You do not have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let code, let message):
            return message ?? "Server error (\(code)). Please try again later."
        case .decodingError(let error):
            return "Failed to parse server response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        case .cancelled:
            return "Request was cancelled."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .requestTimeout, .serverError, .unknown:
            return true
        default:
            return false
        }
    }

    var requiresReAuthentication: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    static func from(statusCode: Int, data: Data?) -> NetworkError {
        let message: String?
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["message"] as? String {
            message = msg
        } else {
            message = nil
        }

        switch statusCode {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 408: return .requestTimeout
        default: return .serverError(statusCode: statusCode, message: message)
        }
    }
}
