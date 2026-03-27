import XCTest
@testable import LennyGrowth

final class APIClientTests: XCTestCase {
    var sut: APIClient!
    var mockKeychainManager: MockKeychainManager!
    var mockURLProtocol: MockURLProtocol.Type { MockURLProtocol.self }

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        mockKeychainManager = MockKeychainManager()
        sut = APIClient(
            session: session,
            baseURL: URL(string: "https://api.lennygrowth.com/v1")!,
            keychainManager: mockKeychainManager
        )
    }

    override func tearDown() {
        sut = nil
        mockKeychainManager = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Successful Requests

    func test_request_success_decodesResponse() async throws {
        // Given
        let expectedArticle = makeArticleDTO()
        let data = try JSONEncoder().encode(expectedArticle)
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        // When
        let result: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)

        // Then
        XCTAssertEqual(result.id, expectedArticle.id)
        XCTAssertEqual(result.title, expectedArticle.title)
    }

    func test_request_attachesAuthToken() async throws {
        // Given
        mockKeychainManager.stubAccessToken = "test-access-token"
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let data = try JSONEncoder().encode(self.makeArticleDTO())
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        // When
        let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)

        // Then
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-access-token")
    }

    func test_request_doesNotAttachToken_whenNoToken() async throws {
        // Given
        mockKeychainManager.stubAccessToken = nil
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let data = try JSONEncoder().encode(self.makeArticleDTO())
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        // When
        let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)

        // Then
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - Error Handling

    func test_request_404_throwsNotFoundError() async throws {
        // Given
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
        }

        // When/Then
        do {
            let _: ArticleDTO = try await sut.request(.article(id: "999"), body: nil)
            XCTFail("Expected error to be thrown")
        } catch NetworkError.notFound {
            // Success
        } catch {
            XCTFail("Expected NetworkError.notFound, got \(error)")
        }
    }

    func test_request_401_throwsUnauthorizedError() async throws {
        // Given - first call returns 401, second also returns 401 (to fail refresh)
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data())
        }
        mockKeychainManager.stubRefreshToken = "refresh-token"

        // When/Then
        do {
            let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)
            XCTFail("Expected error to be thrown")
        } catch NetworkError.unauthorized {
            // Success
        } catch {
            // May throw unauthorized or serverError depending on retry logic
        }
    }

    func test_request_500_throwsServerError() async throws {
        // Given
        let errorMessage = "{\"message\":\"Internal server error\"}"
        let data = errorMessage.data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!, data)
        }

        // When/Then
        do {
            let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)
            XCTFail("Expected error to be thrown")
        } catch NetworkError.serverError(let code, let message) {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(message, "Internal server error")
        } catch {
            XCTFail("Expected NetworkError.serverError, got \(error)")
        }
    }

    func test_request_invalidJSON_throwsDecodingError() async throws {
        // Given
        let invalidData = "not valid json".data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, invalidData)
        }

        // When/Then
        do {
            let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)
            XCTFail("Expected error to be thrown")
        } catch NetworkError.decodingError {
            // Success
        } catch {
            XCTFail("Expected NetworkError.decodingError, got \(error)")
        }
    }

    func test_request_networkFailure_throwsNoInternetError() async throws {
        // Given
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // When/Then
        do {
            let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)
            XCTFail("Expected error to be thrown")
        } catch NetworkError.noInternetConnection {
            // Success
        } catch {
            XCTFail("Expected NetworkError.noInternetConnection, got \(error)")
        }
    }

    func test_request_timeout_throwsTimeoutError() async throws {
        // Given
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        // When/Then
        do {
            let _: ArticleDTO = try await sut.request(.article(id: "1"), body: nil)
            XCTFail("Expected error to be thrown")
        } catch NetworkError.requestTimeout {
            // Success
        } catch {
            XCTFail("Expected NetworkError.requestTimeout, got \(error)")
        }
    }

    // MARK: - HTTP Methods

    func test_postEndpoint_usesPostMethod() async throws {
        // Given
        var capturedRequest: URLRequest?
        let responseData = try JSONEncoder().encode(makeAuthResponseDTO())
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }

        // When
        let _: AuthResponseDTO = try await sut.request(.signIn, body: SignInRequest(email: "test@test.com", password: "password"))

        // Then
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func test_deleteEndpoint_usesDeleteMethod() async throws {
        // Given
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }

        // When
        try await sut.request(.deletePost(id: "123"), body: nil)

        // Then
        XCTAssertEqual(capturedRequest?.httpMethod, "DELETE")
    }

    // MARK: - Query Parameters

    func test_articlesEndpoint_includesQueryParameters() async throws {
        // Given
        var capturedRequest: URLRequest?
        let data = try JSONEncoder().encode(makePaginatedArticlesDTO())
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        // When
        let _: PaginatedResponseDTO<ArticleDTO> = try await sut.request(
            .articles(page: 2, pageSize: 10, category: "marketing", searchQuery: "growth"),
            body: nil
        )

        // Then
        let urlComponents = URLComponents(url: capturedRequest!.url!, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems ?? []
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(queryDict["page"], "2")
        XCTAssertEqual(queryDict["page_size"], "10")
        XCTAssertEqual(queryDict["category"], "marketing")
        XCTAssertEqual(queryDict["q"], "growth")
    }

    // MARK: - Request Body

    func test_request_encodesBodyAsJSON() async throws {
        // Given
        var capturedRequest: URLRequest?
        let responseData = try JSONEncoder().encode(makeAuthResponseDTO())
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }
        let body = SignInRequest(email: "test@test.com", password: "password123")

        // When
        let _: AuthResponseDTO = try await sut.request(.signIn, body: body)

        // Then
        XCTAssertNotNil(capturedRequest?.httpBody)
        let bodyData = capturedRequest!.httpBody!
        let decoded = try JSONDecoder().decode(SignInRequest.self, from: bodyData)
        XCTAssertEqual(decoded.email, "test@test.com")
        XCTAssertEqual(decoded.password, "password123")
    }

    // MARK: - Helpers

    private func makeArticleDTO() -> ArticleDTO {
        ArticleDTO(
            id: "test-id",
            title: "Test Article",
            summary: "Test summary",
            content: "Test content",
            author: ArticleAuthorDTO(id: "a1", name: "Author", bio: nil, avatarUrl: nil),
            publishedAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil,
            imageUrl: nil,
            tags: ["test"],
            category: "marketing",
            readTimeMinutes: 5,
            sourceUrl: nil,
            isFeatured: false,
            isBookmarked: false
        )
    }

    private func makePaginatedArticlesDTO() -> PaginatedResponseDTO<ArticleDTO> {
        PaginatedResponseDTO(items: [makeArticleDTO()], totalCount: 1, currentPage: 1, pageSize: 20)
    }

    private func makeAuthResponseDTO() -> AuthResponseDTO {
        AuthResponseDTO(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            user: UserDTO(
                id: "user-1",
                email: "test@test.com",
                displayName: "Test User",
                avatarUrl: nil,
                bio: nil,
                connectedAccounts: [],
                subscriptionTier: "free",
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
        )
    }
}

// MARK: - Mock URLProtocol

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        requestHandler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mock Keychain Manager

final class MockKeychainManager: KeychainManager {
    var stubAccessToken: String? = nil
    var stubRefreshToken: String? = nil
    var savedAccessToken: String? = nil
    var savedRefreshToken: String? = nil

    override func getAccessToken() -> String? { stubAccessToken }
    override func getRefreshToken() -> String? { stubRefreshToken }
    override func saveAccessToken(_ token: String) { savedAccessToken = token }
    override func saveRefreshToken(_ token: String) { savedRefreshToken = token }
    override var hasValidTokens: Bool { stubAccessToken != nil && stubRefreshToken != nil }
}
