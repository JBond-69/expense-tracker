import SwiftUI

struct IgnoredView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager

    var ignoredExpenses: [Expense] {
        expenseManager.expenses.filter { !$0.isExpense }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if ignoredExpenses.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.textTertiary)
                        Text("No ignored transactions")
                            .font(Theme.Font.ui(14))
                            .foregroundColor(Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(ignoredExpenses) { expense in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.merchant)
                                        .font(Theme.Font.ui(15, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(expense.reasonIfNotExpense ?? "")
                                        .font(Theme.Font.ui(13))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                Divider()
                            }
                        }
                        .background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(Theme.cardRadius)
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Ignored")
        }
    }
}
