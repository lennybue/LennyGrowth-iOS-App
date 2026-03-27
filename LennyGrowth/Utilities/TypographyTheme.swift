import SwiftUI

/// LennyGrowth typography system — SF Pro Display / Text / Mono
extension Font {
    // MARK: - Display (SF Pro Display)
    static let lgDisplayXL  = Font.system(size: 40, weight: .heavy, design: .default)
    static let lgDisplayLG  = Font.system(size: 32, weight: .bold,  design: .default)
    static let lgDisplayMD  = Font.system(size: 24, weight: .bold,  design: .default)
    static let lgDisplaySM  = Font.system(size: 20, weight: .bold,  design: .default)

    // MARK: - Body (SF Pro Text)
    static let lgBodyLG     = Font.system(size: 17, weight: .regular, design: .default)
    static let lgBodyMD     = Font.system(size: 15, weight: .regular, design: .default)
    static let lgBodySM     = Font.system(size: 13, weight: .regular, design: .default)
    static let lgBodyMedium = Font.system(size: 15, weight: .medium,  design: .default)
    static let lgBodySemibold = Font.system(size: 15, weight: .semibold, design: .default)

    // MARK: - Label / Caption
    static let lgLabel     = Font.system(size: 12, weight: .medium,  design: .default)
    static let lgCaption   = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Code / Tech (SF Mono)
    static let lgMono      = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let lgMonoSM    = Font.system(size: 11, weight: .regular, design: .monospaced)
}

// MARK: - Text style modifiers
extension View {
    func lgHeadline() -> some View {
        self.font(.lgDisplayMD).foregroundColor(.textPrimary)
    }

    func lgSubheadline() -> some View {
        self.font(.lgBodySemibold).foregroundColor(.textPrimary)
    }

    func lgBody() -> some View {
        self.font(.lgBodyMD).foregroundColor(.textPrimary)
    }

    func lgCaption() -> some View {
        self.font(.lgCaption).foregroundColor(.textSecondary)
    }

    func lgSecondaryText() -> some View {
        self.font(.lgBodySM).foregroundColor(.textSecondary)
    }
}
