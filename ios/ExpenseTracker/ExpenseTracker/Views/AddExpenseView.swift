import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedType: TransactionType
    @State private var amount: String
    @State private var merchant: String
    @State private var selectedCategory: String
    @State private var selectedGroupId: String?
    @State private var notes: String
    @State private var date: Date

    /// Set only via `init(prefillFrom:)` — the original ignored row being
    /// confirmed. Preserves its id/source/createdAt so saving updates that
    /// row in place instead of inserting a duplicate.
    private let confirmingIgnoredExpense: Expense?

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    init() {
        _selectedType = State(initialValue: .expense)
        _amount = State(initialValue: "")
        _merchant = State(initialValue: "")
        _selectedCategory = State(initialValue: "")
        _selectedGroupId = State(initialValue: nil)
        _notes = State(initialValue: "")
        _date = State(initialValue: Date())
        confirmingIgnoredExpense = nil
    }

    /// Additive initializer, not wired to any screen yet: opens the form
    /// pre-filled from an ignored transaction so the user can confirm it as
    /// real. NOTE FOR THE IGNORED-TAB THREAD: call
    /// `AddExpenseView(prefillFrom: ignoredExpense)` from the row's
    /// "confirm" action once that screen exists — saving will update the
    /// original row (same id, `is_expense` flipped to true,
    /// `reason_if_not_expense` cleared) rather than inserting a new one.
    init(prefillFrom ignoredExpense: Expense) {
        _selectedType = State(initialValue: ignoredExpense.type)
        _amount = State(initialValue: String(format: "%.2f", ignoredExpense.amount))
        _merchant = State(initialValue: ignoredExpense.merchant)
        _selectedCategory = State(initialValue: ignoredExpense.category)
        _selectedGroupId = State(initialValue: ignoredExpense.groupId)
        _notes = State(initialValue: ignoredExpense.notes ?? "")
        _date = State(initialValue: Self.dayFormatter.date(from: ignoredExpense.date) ?? Date())
        confirmingIgnoredExpense = ignoredExpense
    }

    var body: some View {
        ExpenseFormSheet(
            title: confirmingIgnoredExpense != nil ? "Confirm transaction" : "Add transaction",
            selectedType: $selectedType,
            amount: $amount,
            merchant: $merchant,
            selectedCategory: $selectedCategory,
            selectedGroupId: $selectedGroupId,
            notes: $notes,
            date: $date,
            isLoading: expenseManager.isLoading,
            errorMessage: expenseManager.errorMessage,
            authManager: authManager,
            onClose: { dismiss() },
            onSave: {
                if let original = confirmingIgnoredExpense {
                    let updated = Expense(
                        id: original.id,
                        userId: authManager.userId,
                        amount: Double(amount) ?? 0,
                        merchant: merchant,
                        category: selectedCategory,
                        date: Self.dayFormatter.string(from: date),
                        notes: notes.isEmpty ? nil : notes,
                        source: original.source,
                        isExpense: true,
                        reasonIfNotExpense: nil,
                        createdAt: original.createdAt,
                        type: selectedType,
                        groupId: selectedGroupId
                    )
                    expenseManager.updateExpense(updated, userID: authManager.userId) { success in
                        if success { dismiss() }
                    }
                } else {
                    let expense = Expense(
                        id: UUID().uuidString,
                        userId: authManager.userId,
                        amount: Double(amount) ?? 0,
                        merchant: merchant,
                        category: selectedCategory,
                        date: Self.dayFormatter.string(from: date),
                        notes: notes.isEmpty ? nil : notes,
                        source: "manual",
                        isExpense: true,
                        reasonIfNotExpense: nil,
                        createdAt: ISO8601DateFormatter().string(from: Date()),
                        type: selectedType,
                        groupId: selectedGroupId
                    )
                    expenseManager.addExpense(expense, userID: authManager.userId) { success in
                        if success { dismiss() }
                    }
                }
            }
        )
    }
}
