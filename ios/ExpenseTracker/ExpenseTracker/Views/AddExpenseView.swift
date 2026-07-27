import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager

    @State private var amount = ""
    @State private var merchant = ""
    @State private var selectedCategory = ExpenseCategory.food
    @State private var notes = ""
    @State private var date = Date()

    var body: some View {
        ExpenseFormSheet(
            title: "Add Expense",
            amount: $amount,
            merchant: $merchant,
            selectedCategory: $selectedCategory,
            notes: $notes,
            date: $date,
            isLoading: expenseManager.isLoading,
            errorMessage: expenseManager.errorMessage,
            onClose: { dismiss() },
            onSave: {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.calendar = Calendar(identifier: .iso8601)

                let expense = Expense(
                    id: UUID().uuidString,
                    userId: authManager.userId,
                    amount: Double(amount) ?? 0,
                    merchant: merchant,
                    category: selectedCategory.rawValue,
                    date: dateFormatter.string(from: date),
                    notes: notes.isEmpty ? nil : notes,
                    source: "manual",
                    isExpense: true,
                    reasonIfNotExpense: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                expenseManager.addExpense(expense, userID: authManager.userId) { success in
                    if success { dismiss() }
                }
            }
        )
    }
}
