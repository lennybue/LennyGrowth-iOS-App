import Foundation

enum SocialPlatform: String, Codable, CaseIterable, Identifiable {
    case twitter = "twitter"
    case linkedin = "linkedin"
    case instagram = "instagram"
    case facebook = "facebook"
    case threads = "threads"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twitter: return "X (Twitter)"
        case .linkedin: return "LinkedIn"
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .threads: return "Threads"
        }
    }

    var characterLimit: Int {
        switch self {
        case .twitter: return 280
        case .linkedin: return 3000
        case .instagram: return 2200
        case .facebook: return 63206
        case .threads: return 500
        }
    }

    var iconSystemName: String {
        switch self {
        case .twitter: return "bird"
        case .linkedin: return "person.crop.square"
        case .instagram: return "camera"
        case .facebook: return "f.circle"
        case .threads: return "at.circle"
        }
    }

    var brandColor: String {
        switch self {
        case .twitter: return "#000000"
        case .linkedin: return "#0A66C2"
        case .instagram: return "#E4405F"
        case .facebook: return "#1877F2"
        case .threads: return "#000000"
        }
    }

    var supportsMedia: Bool {
        switch self {
        case .twitter, .instagram, .facebook, .threads: return true
        case .linkedin: return true
        }
    }

    var supportsScheduling: Bool { true }
}
