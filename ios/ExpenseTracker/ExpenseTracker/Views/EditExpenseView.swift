import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager

    let expense: Expense

    @State private var amount: String
    @State private var merchant: String
    @State private var selectedCategory: ExpenseCategory
    @State private var notes: String
    @State private var date: Date

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    init(expense: Expense) {
        self.expense = expense
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _merchant = State(initialValue: expense.merchant)
        _selectedCategory = State(initialValue: ExpenseCategory(rawValue: expense.category) ?? .other)
        _notes = State(initialValue: expense.notes ?? "")
        _date = State(initialValue: Self.dayFormatter.date(from: expense.date) ?? Date())
    }

    var body: some View {
        ExpenseFormSheet(
            title: "Edit Expense",
            amount: $amount,
            merchant: $merchant,
            selectedCategory: $selectedCategory,
            notes: $notes,
            date: $date,
            isLoading: expenseManager.isLoading,
            errorMessage: expenseManager.errorMessage,
            onClose: { dismiss() },
            onSave: {
                let updated = Expense(
                    id: expense.id,
                    userId: authManager.userId,
                    amount: Double(amount) ?? 0,
                    merchant: merchant,
                    category: selectedCategory.rawValue,
                    date: Self.dayFormatter.string(from: date),
                    notes: notes.isEmpty ? nil : notes,
                    source: expense.source,
                    isExpense: expense.isExpense,
                    reasonIfNotExpense: expense.reasonIfNotExpense,
                    createdAt: expense.createdAt,
                    type: expense.type,
                    groupId: expense.groupId
                )
                expenseManager.updateExpense(updated, userID: authManager.userId) { success in
                    if success { dismiss() }
                }
            }
        )
    }
}
