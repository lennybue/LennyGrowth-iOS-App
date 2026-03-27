import Foundation

enum APIEndpoint {
    // Auth
    case signIn
    case signUp
    case signInWithApple
    case signOut
    case refreshToken
    case currentUser
    case updateProfile
    case deleteAccount
    case resetPassword

    // Articles
    case articles(page: Int, pageSize: Int, category: String?, searchQuery: String?)
    case article(id: String)
    case toggleBookmark(articleID: String)
    case bookmarkedArticles

    // Products
    case products(page: Int, pageSize: Int, category: String?, isFree: Bool?)
    case product(id: String)
    case featuredProducts
    case downloadProduct(id: String)

    // Posts
    case createPost
    case updatePost(id: String)
    case deletePost(id: String)
    case posts(status: String?)
    case post(id: String)
    case schedulePost(id: String)
    case publishPost(id: String)
    case drafts
    case scheduledPosts

    // Social Accounts
    case connectAccount(platform: String)
    case disconnectAccount(id: String)
    case connectedAccounts

    // AI
    case generateContent
    case generateContentStream
    case rewriteContent
    case generateHashtags
    case analyzeSentiment
    case suggestPostingTimes(platform: String)

    var path: String {
        switch self {
        case .signIn: return "/auth/signin"
        case .signUp: return "/auth/signup"
        case .signInWithApple: return "/auth/apple"
        case .signOut: return "/auth/signout"
        case .refreshToken: return "/auth/refresh"
        case .currentUser: return "/auth/me"
        case .updateProfile: return "/auth/profile"
        case .deleteAccount: return "/auth/account"
        case .resetPassword: return "/auth/reset-password"

        case .articles: return "/content/articles"
        case .article(let id): return "/content/articles/\(id)"
        case .toggleBookmark(let id): return "/content/articles/\(id)/bookmark"
        case .bookmarkedArticles: return "/content/articles/bookmarked"

        case .products: return "/content/products"
        case .product(let id): return "/content/products/\(id)"
        case .featuredProducts: return "/content/products/featured"
        case .downloadProduct(let id): return "/content/products/\(id)/download"

        case .createPost: return "/posts"
        case .updatePost(let id): return "/posts/\(id)"
        case .deletePost(let id): return "/posts/\(id)"
        case .posts: return "/posts"
        case .post(let id): return "/posts/\(id)"
        case .schedulePost(let id): return "/posts/\(id)/schedule"
        case .publishPost(let id): return "/posts/\(id)/publish"
        case .drafts: return "/posts/drafts"
        case .scheduledPosts: return "/posts/scheduled"

        case .connectAccount(let platform): return "/accounts/\(platform)/connect"
        case .disconnectAccount(let id): return "/accounts/\(id)/disconnect"
        case .connectedAccounts: return "/accounts"

        case .generateContent: return "/ai/generate"
        case .generateContentStream: return "/ai/generate/stream"
        case .rewriteContent: return "/ai/rewrite"
        case .generateHashtags: return "/ai/hashtags"
        case .analyzeSentiment: return "/ai/sentiment"
        case .suggestPostingTimes(let platform): return "/ai/posting-times/\(platform)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .signIn, .signUp, .signInWithApple, .refreshToken, .createPost,
             .schedulePost, .publishPost, .connectAccount, .generateContent,
             .generateContentStream, .rewriteContent, .generateHashtags,
             .analyzeSentiment, .resetPassword:
            return .post
        case .updateProfile, .updatePost:
            return .put
        case .toggleBookmark:
            return .patch
        case .deletePost, .disconnectAccount, .deleteAccount:
            return .delete
        default:
            return .get
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .articles(let page, let pageSize, let category, let searchQuery):
            var params: [String: String] = ["page": "\(page)", "page_size": "\(pageSize)"]
            if let category = category { params["category"] = category }
            if let query = searchQuery { params["q"] = query }
            return params
        case .products(let page, let pageSize, let category, let isFree):
            var params: [String: String] = ["page": "\(page)", "page_size": "\(pageSize)"]
            if let category = category { params["category"] = category }
            if let isFree = isFree { params["is_free"] = "\(isFree)" }
            return params
        case .posts(let status):
            if let status = status { return ["status": status] }
            return nil
        default:
            return nil
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
