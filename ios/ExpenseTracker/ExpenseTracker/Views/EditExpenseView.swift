import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager

    let expense: Expense

    @State private var selectedType: TransactionType
    @State private var amount: String
    @State private var merchant: String
    @State private var selectedCategory: String
    @State private var selectedGroupId: String?
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
        _selectedType = State(initialValue: expense.type)
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _merchant = State(initialValue: expense.merchant)
        _selectedCategory = State(initialValue: expense.category)
        _selectedGroupId = State(initialValue: expense.groupId)
        _notes = State(initialValue: expense.notes ?? "")
        _date = State(initialValue: Self.dayFormatter.date(from: expense.date) ?? Date())
    }

    var body: some View {
        ExpenseFormSheet(
            title: "Edit transaction",
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
                let updated = Expense(
                    id: expense.id,
                    userId: authManager.userId,
                    amount: Double(amount) ?? 0,
                    merchant: merchant,
                    category: selectedCategory,
                    date: Self.dayFormatter.string(from: date),
                    notes: notes.isEmpty ? nil : notes,
                    source: expense.source,
                    isExpense: expense.isExpense,
                    reasonIfNotExpense: expense.reasonIfNotExpense,
                    createdAt: expense.createdAt,
                    type: selectedType,
                    groupId: selectedGroupId
                )
                expenseManager.updateExpense(updated, userID: authManager.userId) { success in
                    if success { dismiss() }
                }
            }
        )
    }
}
