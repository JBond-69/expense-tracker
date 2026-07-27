import Foundation

/// A recurring group a transaction can optionally belong to (e.g. "Rent",
/// "Salary", "SIP - Index Fund" — design/mockups/Expense Tracker.dc.html
/// GROUPS_SEED, line 660).
struct ExpenseGroup: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let type: TransactionType
    let recurring: Bool
    let catRef: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, type, recurring
        case userId = "user_id"
        case catRef = "cat_ref"
        case createdAt = "created_at"
    }
}
