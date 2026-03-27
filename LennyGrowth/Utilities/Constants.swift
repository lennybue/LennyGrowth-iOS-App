import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://api.lennardbuessow.digital/v1"
        static let timeout: TimeInterval = 30
    }

    enum Keychain {
        static let accessTokenKey  = "com.lennardbuessow.lennygrowth.accessToken"
        static let refreshTokenKey = "com.lennardbuessow.lennygrowth.refreshToken"
        static let userIDKey       = "com.lennardbuessow.lennygrowth.userID"
    }

    enum Cache {
        static let articleListTTL: TimeInterval = 3600      // 1 hour
        static let articleBodyTTL: TimeInterval = 86400     // 24 hours
    }

    enum LinkedIn {
        static let maxCharacters = 3000
        static let apiDailyLimit = 100
        static let optimalPostingDays = [3, 4, 5]           // Tue–Thu (Calendar weekday)
        static let optimalPostingHoursStart = 8
        static let optimalPostingHoursEnd   = 10
    }

    enum Threads {
        static let maxCharacters = 500
        static let maxLinesRecommended = 6
        static let callsPerHour = 250
        static let postsPerDay  = 25
    }

    enum AI {
        static let dailyFreeLimit      = 20
        static let dailyPremiumLimit   = Int.max
    }

    enum Gamification {
        static let totalFreeProducts = 5
        enum BadgeTitles {
            static let starter  = "Starter"
            static let profi    = "Profi"
            static let expert   = "Marketing-Experte"
        }
    }

    enum URLs {
        static let website    = URL(string: "https://lennardbuessow.digital")!
        static let linkHub    = URL(string: "https://beacons.ai/growthbylenny")!
        static let shop       = URL(string: "https://growthbylenny.gumroad.com")!
        static let privacyPolicy = URL(string: "https://lennardbuessow.digital/privacy")!
        static let support    = URL(string: "mailto:hello@lennardbuessow.digital")!
    }
}
