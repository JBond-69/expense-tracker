import SwiftUI

private struct MonthGroup: Identifiable {
    let id: String
    let label: String
    let expenses: [Expense]
    var total: Double { expenses.reduce(0) { $0 + $1.amount } }
}

struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showAddExpense = false
    @State private var editingExpense: Expense?

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    private static let monthLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private var trackedExpenses: [Expense] {
        expenseManager.expenses.filter(\.isExpense)
    }

    private var monthGroups: [MonthGroup] {
        let grouped = Dictionary(grouping: trackedExpenses) { expense -> String in
            String(expense.date.prefix(7)) // "yyyy-MM"
        }
        return grouped.keys.sorted(by: >).map { key in
            let expenses = grouped[key]!.sorted { $0.date > $1.date }
            let label = Self.dayFormatter.date(from: "\(key)-01").map { Self.monthLabelFormatter.string(from: $0) } ?? key
            return MonthGroup(id: key, label: label, expenses: expenses)
        }
    }

    private var currentMonthTotal: Double {
        let currentKey = Self.monthLabelFormatter.string(from: Date())
        return monthGroups.first(where: { $0.label == currentKey })?.total ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Expenses")
                            .font(Theme.Font.ui(28, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.top, 8)

                        VStack(spacing: 6) {
                            Text("This Month")
                                .font(Theme.Font.ui(12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                            Text("₹\(currentMonthTotal, specifier: "%.2f")")
                                .font(Theme.Font.mono(24, weight: .bold))
                                .foregroundColor(Theme.expenseFg)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(Theme.cardRadius)

                        if trackedExpenses.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 36))
                                    .foregroundColor(Theme.textTertiary)
                                Text("No expenses yet")
                                    .font(Theme.Font.ui(14))
                                    .foregroundColor(Theme.textSecondary)
                                Text("Tap + to add one")
                                    .font(Theme.Font.ui(13))
                                    .foregroundColor(Theme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(monthGroups) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.label)
                                        .font(Theme.Font.ui(13, weight: .semibold))
                                        .foregroundColor(Theme.textTertiary)
                                        .textCase(.uppercase)
                                        .padding(.top, 6)

                                    VStack(spacing: 0) {
                                        ForEach(Array(group.expenses.enumerated()), id: \.element.id) { index, expense in
                                            ExpenseRowView(expense: expense)
                                                .contentShape(Rectangle())
                                                .onTapGesture { editingExpense = expense }
                                                .swipeToDelete {
                                                    expenseManager.deleteExpense(id: expense.id, userID: authManager.userId)
                                                }
                                            if index < group.expenses.count - 1 {
                                                Divider().foregroundColor(Theme.divider)
                                            }
                                        }
                                    }
                                    .background(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                                    .cornerRadius(Theme.cardRadius)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                Button(action: { showAddExpense = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.primary)
                        .clipShape(Circle())
                        .shadow(color: Theme.primary.opacity(0.4), radius: 14, x: 0, y: 8)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
                    .environmentObject(expenseManager)
                    .environmentObject(authManager)
            }
            .sheet(item: $editingExpense) { expense in
                EditExpenseView(expense: expense)
                    .environmentObject(expenseManager)
                    .environmentObject(authManager)
            }
        }
    }
}
