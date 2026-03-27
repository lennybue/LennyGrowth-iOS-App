import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case unauthorized                       // 401 — after token refresh also failed
    case forbidden                          // 403
    case notFound                           // 404
    case rateLimitExceeded(retryAfter: Int?) // 429
    case serverError(statusCode: Int, message: String?)
    case noInternetConnection
    case requestTimeout
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Ungültige URL.")
        case .noData:
            return String(localized: "Keine Daten erhalten.")
        case .decodingFailed(let error):
            return String(localized: "Fehler beim Verarbeiten der Antwort: \(error.localizedDescription)")
        case .unauthorized:
            return String(localized: "Sitzung abgelaufen. Bitte erneut anmelden.")
        case .forbidden:
            return String(localized: "Zugriff verweigert.")
        case .notFound:
            return String(localized: "Ressource nicht gefunden.")
        case .rateLimitExceeded(let retry):
            if let retry { return String(localized: "Rate-Limit erreicht. Bitte in \(retry) Sekunden erneut versuchen.") }
            return String(localized: "Rate-Limit erreicht. Bitte kurz warten.")
        case .serverError(let code, let msg):
            return String(localized: "Serverfehler (\(code)): \(msg ?? "Unbekannter Fehler")")
        case .noInternetConnection:
            return String(localized: "Keine Internetverbindung.")
        case .requestTimeout:
            return String(localized: "Zeitüberschreitung. Bitte erneut versuchen.")
        case .cancelled:
            return String(localized: "Anfrage abgebrochen.")
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    /// Whether the user should be logged out as a result of this error
    var requiresLogout: Bool { self == .unauthorized }

    static func from(statusCode: Int, body: Data?) -> NetworkError {
        let message = body.flatMap { try? JSONDecoder().decode(APIErrorResponse.self, from: $0) }?.message
        switch statusCode {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 429:
            return .rateLimitExceeded(retryAfter: nil)
        default:  return .serverError(statusCode: statusCode, message: message)
        }
    }
}

extension NetworkError: Equatable {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.noInternetConnection, .noInternetConnection),
             (.requestTimeout, .requestTimeout),
             (.cancelled, .cancelled):
            return true
        case (.serverError(let lc, _), .serverError(let rc, _)):
            return lc == rc
        default:
            return false
        }
    }
}

struct APIErrorResponse: Codable {
    let message: String?
    let error: String?
    let statusCode: Int?
}
