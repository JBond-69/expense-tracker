import Foundation

/// One row per user (design/mockups/Expense Tracker.dc.html
/// state.notifications, line 774).
struct NotificationPreferences: Codable {
    let userId: String
    let newTransactionEnabled: Bool
    let budgetAlertEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case newTransactionEnabled = "new_transaction_enabled"
        case budgetAlertEnabled = "budget_alert_enabled"
    }
}
