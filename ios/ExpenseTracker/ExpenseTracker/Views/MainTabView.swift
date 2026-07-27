import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var expenseManager: ExpenseManager

    init(authManager: AuthManager) {
        _expenseManager = StateObject(wrappedValue: ExpenseManager(authManager: authManager))
    }

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            IgnoredView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Ignored", systemImage: "tray.fill")
                }

            StubTabView(title: "Insights", systemImage: "chart.bar.fill", message: "More views coming soon.")
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            StubTabView(title: "Account", systemImage: "person.crop.circle.fill", message: "Account settings coming soon.")
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(Theme.primary)
        .onAppear {
            expenseManager.fetchExpenses(userID: authManager.userId)
        }
    }
}

/// Phase 1 explicitly excludes Insights/Account functionality — this stub
/// exists only so the 4-tab bar the design calls for isn't broken.
struct StubTabView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(Theme.textTertiary)
                Text(message)
                    .font(Theme.Font.ui(14))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle(title)
        }
    }
}

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

struct ExpenseRowView: View {
    let expense: Expense
    private var category: ExpenseCategory { ExpenseCategory(rawValue: expense.category) ?? .other }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.symbolName)
                .font(.system(size: 16))
                .foregroundColor(category.tint.fg)
                .frame(width: 40, height: 40)
                .background(category.tint.bg)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(Theme.Font.ui(15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(category.rawValue)
                    .font(Theme.Font.ui(13))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(expense.amount, specifier: "%.2f")")
                    .font(Theme.Font.mono(15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(expense.date)
                    .font(Theme.Font.ui(12))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(14)
    }
}

/// Preserves the existing swipe-to-delete interaction (native List .onDelete
/// behavior) while letting rows live in a plain ScrollView/VStack so they can
/// be styled as cards instead of default List rows.
private struct SwipeToDeleteModifier: ViewModifier {
    let action: () -> Void
    @State private var offset: CGFloat = 0
    @State private var revealed = false

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: action) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
            }
            .opacity(revealed ? 1 : 0)

            content
                .background(Theme.surface)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard value.translation.width < 0 else { return }
                            offset = max(value.translation.width, -70)
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if value.translation.width < -35 {
                                    offset = -70
                                    revealed = true
                                } else {
                                    offset = 0
                                    revealed = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}

extension View {
    func swipeToDelete(action: @escaping () -> Void) -> some View {
        modifier(SwipeToDeleteModifier(action: action))
    }
}

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

#Preview {
    let authManager = AuthManager()
    MainTabView(authManager: authManager)
        .environmentObject(authManager)
}
