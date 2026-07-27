import Foundation

/// A category scoped to one transaction type (design/mockups/
/// Expense Tracker.dc.html CATS/CAT_COLORS, lines 636-648). Every user gets
/// the default set seeded on signup (see the migration's
/// `handle_new_user_categories` trigger) and can add custom ones on top.
struct Category: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let type: TransactionType
    let colorBg: String
    let colorFg: String
    let isDefault: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case userId = "user_id"
        case colorBg = "color_bg"
        case colorFg = "color_fg"
        case isDefault = "is_default"
        case createdAt = "created_at"
    }
}
