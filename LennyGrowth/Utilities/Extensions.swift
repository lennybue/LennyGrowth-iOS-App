import Foundation
import SwiftUI

// MARK: - Date

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    var readableDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: self)
    }

    var isOptimalLinkedInTime: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self) // 1=Sun, 3=Tue, 4=Wed, 5=Thu
        let hour = calendar.component(.hour, from: self)
        let isTueThuRange = [3, 4, 5].contains(weekday)
        let isOptimalHour = (8...10).contains(hour)
        return isTueThuRange && isOptimalHour
    }
}

// MARK: - String

extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return self.range(of: regex, options: .regularExpression) != nil
    }

    var lineCount: Int {
        components(separatedBy: "\n").count
    }

    var hasHashtag: Bool {
        contains("#")
    }

    var hasURL: Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: self, range: NSRange(self.startIndex..., in: self))
        return (matches?.count ?? 0) > 0
    }
}

// MARK: - Int

extension Int {
    /// Format large numbers compactly: 1500 → "1,5K"
    var compactFormatted: String {
        let value = Double(self)
        switch value {
        case 1_000_000...:
            let formatted = String(format: "%.1f", value / 1_000_000)
            return "\(formatted)M"
        case 1_000...:
            let formatted = String(format: "%.1f", value / 1_000)
            return "\(formatted)K"
        default:
            return "\(self)"
        }
    }
}

// MARK: - Double

extension Double {
    /// Format as DACH currency string: 2500.0 → "2.500 EUR"
    var eurFormatted: String {
        if self == 0 { return String(localized: "Kostenlos") }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "de_DE")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        return "\(formatted) EUR"
    }
}

// MARK: - View

extension View {
    func tabItemLabel(title: LocalizedStringKey, icon: String) -> some View {
        self.tabItem {
            Label(title, systemImage: icon)
        }
    }
}

// MARK: - Binding<String> char limit

extension Binding where Value == String {
    func max(_ limit: Int) -> Binding<String> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = String(newValue.prefix(limit))
            }
        )
    }
}
