import SwiftUI

/// LennyGrowth brand color palette — Digital Noir
extension Color {
    // MARK: - Backgrounds
    static let bgPrimary   = Color(hex: "#0C1222")
    static let bgSurface   = Color(hex: "#111827")

    // MARK: - Accents
    static let neonMagenta = Color(hex: "#FF006E")  // Primary CTAs, Highlights
    static let neonTeal    = Color(hex: "#16E1C4")  // Secondary, NeuralGrowth Collective
    static let iceBlue     = Color(hex: "#4CC9F0")  // Links, Tags, Badges

    // MARK: - Text
    static let textPrimary   = Color(hex: "#FFFFFF")
    static let textSecondary = Color(hex: "#94A3B8")

    // MARK: - Glass
    static let glassSurface = Color.white.opacity(0.05)
    static let glassBorder  = Color.white.opacity(0.10)

    // MARK: - Semantic aliases
    static let lgPrimary   = Color.neonMagenta
    static let lgSecondary = Color.neonTeal
    static let lgAccent    = Color.iceBlue
}

// MARK: - Hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3:
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor convenience (for non-SwiftUI contexts)
extension UIColor {
    static let bgPrimary   = UIColor(Color.bgPrimary)
    static let bgSurface   = UIColor(Color.bgSurface)
    static let neonMagenta = UIColor(Color.neonMagenta)
    static let neonTeal    = UIColor(Color.neonTeal)
    static let iceBlue     = UIColor(Color.iceBlue)
}
