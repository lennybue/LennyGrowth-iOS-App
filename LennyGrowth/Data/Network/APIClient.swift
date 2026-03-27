import Foundation

/// Core networking client — URLSession + async/await.
/// Responsibilities:
///   - Inject Bearer token into every request
///   - Auto-refresh token on 401, then retry once
///   - Map HTTP errors → NetworkError
///   - Provide a streaming bytes interface for SSE/AI endpoints
final class APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let tokenManager: TokenManager
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URL(string: Constants.API.baseURL)!,
        tokenManager: TokenManager,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenManager = tokenManager
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Typed request (standard JSON)

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil
    ) async throws -> T {
        let data = try await performRequest(endpoint: endpoint, body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    /// Request that returns raw Data (e.g. file downloads)
    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        return try await performRequest(endpoint: endpoint, body: nil)
    }

    /// Void request (DELETE, logout, etc.)
    func requestVoid(_ endpoint: APIEndpoint, body: (any Encodable)? = nil) async throws {
        _ = try await performRequest(endpoint: endpoint, body: body)
    }

    // MARK: - Streaming (SSE / chunked for AI generation)

    /// Returns an AsyncThrowingStream of decoded SSE text chunks.
    /// Backend must send `data: <text>\n\n` formatted SSE events.
    func stream(_ endpoint: APIEndpoint, body: (any Encodable)? = nil) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try await self.buildRequest(endpoint: endpoint, body: body)
                    let (bytes, response) = try await self.session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NetworkError.noData)
                        return
                    }
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: NetworkError.from(statusCode: httpResponse.statusCode, body: nil))
                        return
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        // SSE format: "data: <content>" or "data: [DONE]"
                        guard line.hasPrefix("data: ") else { continue }
                        let content = String(line.dropFirst(6))
                        if content == "[DONE]" { break }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: NetworkError.unknown(error))
                }
            }
        }
    }

    // MARK: - Private core

    private func performRequest(
        endpoint: APIEndpoint,
        body: (any Encodable)?,
        isRetry: Bool = false
    ) async throws -> Data {
        let request = try await buildRequest(endpoint: endpoint, body: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.noInternetConnection
            case .timedOut:
                throw NetworkError.requestTimeout
            case .cancelled:
                throw NetworkError.cancelled
            default:
                throw NetworkError.unknown(urlError)
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        // 304 Not Modified — caller handles empty data
        if http.statusCode == 304 { return Data() }

        guard (200..<300).contains(http.statusCode) else {
            // 401: try token refresh once, then retry
            if http.statusCode == 401 && !isRetry {
                try await refreshToken()
                return try await performRequest(endpoint: endpoint, body: body, isRetry: true)
            }
            throw NetworkError.from(statusCode: http.statusCode, body: data)
        }

        return data
    }

    private func buildRequest(endpoint: APIEndpoint, body: (any Encodable)?) async throws -> URLRequest {
        guard let url = endpoint.url(base: baseURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: Constants.API.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Inject Bearer token (only if we have one — login/register skip this)
        if let token = await tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Extra headers (If-Modified-Since etc.)
        for (key, value) in endpoint.extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func refreshToken() async throws {
        _ = try await tokenManager.validAccessToken { refreshToken in
            // Call the refresh endpoint without auth header injection
            guard let url = APIEndpoint.refreshToken.url(base: self.baseURL) else {
                throw NetworkError.invalidURL
            }
            var req = URLRequest(url: url, timeoutInterval: Constants.API.timeout)
            req.httpMethod = HTTPMethod.POST.rawValue
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            req.httpBody = try encoder.encode(["refreshToken": refreshToken])

            let (data, response) = try await self.session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                await self.tokenManager.clear()
                throw NetworkError.unauthorized
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(TokenResponse.self, from: data)
        }
    }
}
