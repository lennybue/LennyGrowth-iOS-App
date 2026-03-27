import Foundation

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable?) async throws -> T
    func request(_ endpoint: APIEndpoint, body: Encodable?) async throws
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let keychainManager: KeychainManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?

    init(
        session: URLSession = .shared,
        baseURL: URL,
        keychainManager: KeychainManager
    ) {
        self.session = session
        self.baseURL = baseURL
        self.keychainManager = keychainManager
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws -> T {
        let urlRequest = try buildRequest(for: endpoint, body: body)
        return try await performRequest(urlRequest, endpoint: endpoint)
    }

    func request(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws {
        let urlRequest = try buildRequest(for: endpoint, body: body)
        let _: EmptyResponse = try await performRequest(urlRequest, endpoint: endpoint)
    }

    private func buildRequest(for endpoint: APIEndpoint, body: Encodable?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }

        if let params = endpoint.queryParameters {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = keychainManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest, endpoint: APIEndpoint) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }

            if httpResponse.statusCode == 401 {
                let newToken = try await refreshAccessToken()
                var retryRequest = request
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await session.data(for: retryRequest)
                guard let retryHTTPResponse = retryResponse as? HTTPURLResponse else {
                    throw NetworkError.unknown(URLError(.badServerResponse))
                }
                if retryHTTPResponse.statusCode == 401 {
                    throw NetworkError.unauthorized
                }
                return try decode(retryData, statusCode: retryHTTPResponse.statusCode)
            }

            return try decode(data, statusCode: httpResponse.statusCode)
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.noInternetConnection
            case .timedOut:
                throw NetworkError.requestTimeout
            case .cancelled:
                throw NetworkError.cancelled
            default:
                throw NetworkError.unknown(error)
            }
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    private func decode<T: Decodable>(_ data: Data, statusCode: Int) throws -> T {
        guard (200...299).contains(statusCode) else {
            throw NetworkError.from(statusCode: statusCode, data: data)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func refreshAccessToken() async throws -> String {
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task<String, Error> {
            defer { refreshTask = nil }
            guard let refreshToken = keychainManager.getRefreshToken() else {
                throw NetworkError.unauthorized
            }
            let body = RefreshTokenRequest(refreshToken: refreshToken)
            let response: RefreshTokenResponse = try await request(.refreshToken, body: body)
            keychainManager.saveAccessToken(response.accessToken)
            if let newRefresh = response.refreshToken {
                keychainManager.saveRefreshToken(newRefresh)
            }
            return response.accessToken
        }

        refreshTask = task
        return try await task.value
    }
}

// MARK: - Helper Types

private struct EmptyResponse: Decodable {}

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

private struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

private struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
}
