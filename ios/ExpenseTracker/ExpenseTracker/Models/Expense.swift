import Foundation

/// One of the three transaction kinds tracked by the app (design/mockups/
/// Expense Tracker.dc.html TYPE_META, line 649). Savings = credits - expenses
/// - investments is computed from this at the screen layer, not stored.
enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case credit
    case investment

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: return "Expense"
        case .credit: return "Credit"
        case .investment: return "Investment"
        }
    }
}

struct Expense: Identifiable, Codable {
    let id: String
    let userId: String
    let amount: Double
    let merchant: String
    let category: String
    let date: String
    let notes: String?
    let source: String
    let isExpense: Bool
    let reasonIfNotExpense: String?
    let createdAt: String
    let type: TransactionType
    /// Optional recurring group this transaction belongs to (e.g. "Rent",
    /// "Salary") — nil for one-off transactions.
    let groupId: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, merchant, category, date, notes, source, type
        case userId = "user_id"
        case isExpense = "is_expense"
        case reasonIfNotExpense = "reason_if_not_expense"
        case createdAt = "created_at"
        case groupId = "group_id"
    }
}

enum ExpenseCategory: String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }

    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case travel = "Travel"
    case entertainment = "Entertainment"
    case health = "Health"
    case other = "Other"

    var color: String {
        switch self {
        case .food: return "#FFE5E5"
        case .transport: return "#E5F5FF"
        case .shopping: return "#FFF5E5"
        case .bills: return "#F5F5F5"
        case .travel: return "#E5FFE5"
        case .entertainment: return "#F5E5FF"
        case .health: return "#FFE5F5"
        case .other: return "#F5F5F5"
        }
    }
}
