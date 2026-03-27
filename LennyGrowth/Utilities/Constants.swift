import Foundation
import SwiftUI

enum Constants {
    enum API {
        static let baseURLString = "https://api.lennygrowth.com/v1"
        static var baseURL: URL { URL(string: baseURLString)! }
        static let defaultPageSize = 20
        static let maxPageSize = 50
        static let requestTimeout: TimeInterval = 30
    }

    enum App {
        static let name = "LennyGrowth"
        static let bundleID = "com.lennygrowth.app"
        static let appStoreID = "0000000000"
        static let supportEmail = "support@lennygrowth.com"
        static let privacyPolicyURL = URL(string: "https://lennygrowth.com/privacy")!
        static let termsOfServiceURL = URL(string: "https://lennygrowth.com/terms")!
        static let websiteURL = URL(string: "https://lennygrowth.com")!
    }

    enum Storage {
        static let cacheExpirySeconds: TimeInterval = 3600 // 1 hour
        static let maxCachedArticles = 100
        static let maxCachedProducts = 50
    }

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cardShadowRadius: CGFloat = 4
        static let animationDuration: Double = 0.3
        static let feedGridColumns = 2
    }

    enum Subscription {
        static let freeMonthlyPosts = 10
        static let freeScheduledPostsLimit = 3
        static let freeAIGenerationsPerMonth = 5
        static let proMonthlyPrice = 19.99
        static let proAnnualPrice = 179.99
    }

    enum Notifications {
        static let postPublishedCategory = "POST_PUBLISHED"
        static let postScheduledCategory = "POST_SCHEDULED"
        static let postFailedCategory = "POST_FAILED"
    }
}

// MARK: - App Colors (SwiftUI)

extension Color {
    static let lgPrimary = Color("PrimaryColor", bundle: nil)
    static let lgSecondary = Color("SecondaryColor", bundle: nil)
    static let lgAccent = Color("AccentColor", bundle: nil)
    static let lgBackground = Color("BackgroundColor", bundle: nil)
    static let lgCardBackground = Color("CardBackgroundColor", bundle: nil)
    static let lgTextPrimary = Color.primary
    static let lgTextSecondary = Color.secondary

    // Fallback colors for when asset catalog entries don't exist
    static let primaryBrand = Color(red: 0.27, green: 0.44, blue: 0.95)
    static let secondaryBrand = Color(red: 0.45, green: 0.30, blue: 0.90)
    static let accentGreen = Color(red: 0.15, green: 0.78, blue: 0.55)
    static let warningOrange = Color(red: 1.0, green: 0.60, blue: 0.10)
    static let errorRed = Color(red: 0.95, green: 0.23, blue: 0.25)
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let postPublished = Notification.Name("postPublished")
    static let postScheduled = Notification.Name("postScheduled")
    static let subscriptionUpdated = Notification.Name("subscriptionUpdated")
}
