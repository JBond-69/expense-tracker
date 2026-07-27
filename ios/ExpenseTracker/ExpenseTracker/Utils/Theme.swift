import SwiftUI

/// Design tokens pulled directly from design/mockups/Expense Tracker.dc.html
/// and design/ui_kit/components.md. Keep these as the single source of truth
/// so screens stay visually consistent instead of drifting to system defaults.
enum Theme {
    static let primary = Color(hex: "#4869EC")
    static let background = Color(hex: "#F6F8FB")
    static let pillBackground = Color(hex: "#EDEFF3")
    static let surface = Color.white
    static let border = Color(hex: "#D7D8DD")
    static let divider = Color(hex: "#F0F1F3")

    static let textPrimary = Color(hex: "#101116")
    static let textSecondary = Color(hex: "#4E566C")
    static let textTertiary = Color(hex: "#A4A7B0")

    static let expenseFg = Color(hex: "#BF1D30")
    static let expenseBg = Color(hex: "#FBEAEB")
    static let creditFg = Color(hex: "#037C5A")
    static let creditBg = Color(hex: "#E3F7EB")
    static let investmentFg = Color(hex: "#5C25F7")
    static let investmentBg = Color(hex: "#F2DCFA")
    static let savingsFg = Color(hex: "#2A4CC5")
    static let savingsBg = Color(hex: "#F1F4FE")

    static let loginBackground = Color(hex: "#07133E")

    enum Font {
        /// Mockup uses 'Poppins' for UI text; falls back to system rounded,
        /// which is the closest built-in match for its geometry.
        static func ui(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        /// Mockup uses 'Roboto Mono' for all numeric/amount values.
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }

    static let cardRadius: CGFloat = 14
    static let controlRadius: CGFloat = 10
    static let sheetRadius: CGFloat = 20
}

extension ExpenseCategory {
    /// Foreground/background tint pair per design/ui_kit/components.md's
    /// Category Mapping table.
    var tint: (fg: Color, bg: Color) {
        switch self {
        case .food: return (Color(hex: "#BF1D30"), Color(hex: "#FBEAEB"))
        case .transport: return (Color(hex: "#2A4CC5"), Color(hex: "#E5F5FF"))
        case .shopping: return (Color(hex: "#B8710A"), Color(hex: "#FFF5E5"))
        case .bills: return (Color(hex: "#4E566C"), Color(hex: "#F5F5F5"))
        case .travel: return (Color(hex: "#037C5A"), Color(hex: "#E3F7EB"))
        case .entertainment: return (Color(hex: "#5C25F7"), Color(hex: "#F2DCFA"))
        case .health: return (Color(hex: "#C22868"), Color(hex: "#FFE5F5"))
        case .other: return (Color(hex: "#4E566C"), Color(hex: "#F5F5F5"))
        }
    }

    var symbolName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .bills: return "doc.text.fill"
        case .travel: return "airplane"
        case .entertainment: return "film.fill"
        case .health: return "cross.case.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

extension TransactionType {
    /// Accent/tint pair per design/mockups/Expense Tracker.dc.html TYPE_META
    /// (line 649) — used for amount text and summary-card chips.
    var accentColor: Color {
        switch self {
        case .expense: return Theme.expenseFg
        case .credit: return Theme.creditFg
        case .investment: return Theme.investmentFg
        }
    }

    var tintBg: Color {
        switch self {
        case .expense: return Theme.expenseBg
        case .credit: return Theme.creditBg
        case .investment: return Theme.investmentBg
        }
    }

    /// Same pair as (accentColor, tintBg), as a tuple — used by the Account
    /// tab's recurring-group and category-tab badges.
    var tint: (fg: Color, bg: Color) { (accentColor, tintBg) }
}

/// Matches the mockup's `fmt(n)` helper (Roboto Mono, en-IN grouping, no
/// decimals) so month/category subtotals render identically to the design.
enum CurrencyFormat {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        f.maximumFractionDigits = 0
        return f
    }()

    static func rounded(_ value: Double) -> String {
        let rounded = value.rounded()
        return "₹" + (formatter.string(from: NSNumber(value: rounded)) ?? String(Int(rounded)))
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
