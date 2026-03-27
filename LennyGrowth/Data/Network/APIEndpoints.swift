import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

/// All backend endpoints for LennyGrowth API v1.
/// Base: https://api.lennardbuessow.digital/v1
enum APIEndpoint {
    // MARK: - Auth
    case register
    case login
    case loginApple
    case refreshToken
    case logout

    // MARK: - Content
    case articles(page: Int, pageSize: Int, category: String?, search: String?, ifModifiedSince: Date?)
    case article(id: String)
    case products(page: Int, pageSize: Int, category: String?, isFree: Bool?)
    case product(id: String)
    case productDownload(id: String)

    // MARK: - Posts
    case createPost
    case posts(status: String?)
    case post(id: String)
    case updatePost(id: String)
    case deletePost(id: String)
    case publishPost(id: String)
    case postAnalytics(id: String)

    // MARK: - Social
    case connectSocial(platform: String)
    case disconnectSocial(platform: String)
    case connectedAccounts

    // MARK: - AI
    case aiGenerate
    case aiRewrite
    case aiHashtags
    case aiCaption
    case aiVariations

    // MARK: - User
    case userProfile
    case updateProfile
    case userPurchases
    case userDownloads

    // MARK: - Computed

    var path: String {
        switch self {
        case .register:               return "/auth/register"
        case .login:                  return "/auth/login"
        case .loginApple:             return "/auth/apple"
        case .refreshToken:           return "/auth/refresh"
        case .logout:                 return "/auth/logout"

        case .articles:               return "/articles"
        case .article(let id):        return "/articles/\(id)"
        case .products:               return "/products"
        case .product(let id):        return "/products/\(id)"
        case .productDownload(let id):return "/products/\(id)/download"

        case .createPost:             return "/posts"
        case .posts:                  return "/posts"
        case .post(let id):           return "/posts/\(id)"
        case .updatePost(let id):     return "/posts/\(id)"
        case .deletePost(let id):     return "/posts/\(id)"
        case .publishPost(let id):    return "/posts/\(id)/publish"
        case .postAnalytics(let id):  return "/posts/\(id)/analytics"

        case .connectSocial(let p):   return "/social/connect/\(p)"
        case .disconnectSocial(let p):return "/social/disconnect/\(p)"
        case .connectedAccounts:      return "/social/accounts"

        case .aiGenerate:             return "/ai/generate"
        case .aiRewrite:              return "/ai/rewrite"
        case .aiHashtags:             return "/ai/hashtags"
        case .aiCaption:              return "/ai/caption"
        case .aiVariations:           return "/ai/variations"

        case .userProfile:            return "/user/profile"
        case .updateProfile:          return "/user/profile"
        case .userPurchases:          return "/user/purchases"
        case .userDownloads:          return "/user/downloads"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .articles, .article, .products, .product,
             .posts, .post, .postAnalytics,
             .connectedAccounts, .userProfile, .userPurchases, .userDownloads:
            return .GET
        case .register, .login, .loginApple, .refreshToken,
             .createPost, .publishPost, .productDownload,
             .connectSocial,
             .aiGenerate, .aiRewrite, .aiHashtags, .aiCaption, .aiVariations:
            return .POST
        case .updatePost, .updateProfile:
            return .PUT
        case .logout, .deletePost, .disconnectSocial:
            return .DELETE
        }
    }

    /// Build query-parameterised URL against given base URL
    func url(base: URL) -> URL? {
        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = []

        switch self {
        case .articles(let page, let size, let cat, let search, _):
            items.append(.init(name: "page", value: "\(page)"))
            items.append(.init(name: "pageSize", value: "\(size)"))
            if let cat   { items.append(.init(name: "category", value: cat)) }
            if let search { items.append(.init(name: "search", value: search)) }
        case .products(let page, let size, let cat, let isFree):
            items.append(.init(name: "page", value: "\(page)"))
            items.append(.init(name: "pageSize", value: "\(size)"))
            if let cat    { items.append(.init(name: "category", value: cat)) }
            if let isFree { items.append(.init(name: "isFree", value: "\(isFree)")) }
        case .posts(let status):
            if let status { items.append(.init(name: "status", value: status)) }
        default:
            break
        }

        components?.queryItems = items.isEmpty ? nil : items
        return components?.url
    }

    /// Extra HTTP headers for this endpoint (e.g. If-Modified-Since)
    var extraHeaders: [String: String] {
        if case .articles(_, _, _, _, let ims) = self, let ims {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            fmt.locale = Locale(identifier: "en_US")
            return ["If-Modified-Since": fmt.string(from: ims)]
        }
        return [:]
    }

    /// Whether this endpoint streams the response body
    var isStreaming: Bool {
        switch self {
        case .aiGenerate: return true
        default: return false
        }
    }
}
