import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var expenseManager = ExpenseManager()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet")
                }

            IgnoredView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Ignored", systemImage: "checkmark.circle")
                }

            SettingsView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            expenseManager.fetchExpenses(userID: authManager.userEmail)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showAddExpense = false

    var currentMonthExpenses: [Expense] {
        expenseManager.expenses.filter { $0.isExpense }
    }

    var currentMonthTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 12) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("₹\(currentMonthTotal, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()

                if currentMonthExpenses.isEmpty {
                    VStack {
                        Text("No expenses yet")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(currentMonthExpenses) { expense in
                            ExpenseRowView(expense: expense)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let expense = currentMonthExpenses[index]
                                expenseManager.deleteExpense(id: expense.id, userID: authManager.userEmail)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
                    .environmentObject(expenseManager)
                    .environmentObject(authManager)
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.merchant)
                    .fontWeight(.semibold)
                Text(expense.category)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(expense.amount, specifier: "%.2f")")
                    .fontWeight(.semibold)
                Text(expense.date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
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
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                }

                Section("Merchant") {
                    TextField("Where did you spend?", text: $merchant)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }

                Button(action: {
                    let expense = Expense(
                        id: UUID().uuidString,
                        userId: authManager.userEmail,
                        amount: Double(amount) ?? 0,
                        merchant: merchant,
                        category: selectedCategory.rawValue,
                        date: date.formatted(date: .numeric, time: .omitted),
                        notes: notes.isEmpty ? nil : notes,
                        source: "manual",
                        isExpense: true,
                        reasonIfNotExpense: nil,
                        createdAt: ISO8601DateFormatter().string(from: Date())
                    )
                    expenseManager.addExpense(expense, userID: authManager.userEmail)
                    dismiss()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
        }
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
            VStack {
                if ignoredExpenses.isEmpty {
                    VStack {
                        Text("No ignored transactions")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(ignoredExpenses) { expense in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(expense.merchant)
                                    .fontWeight(.semibold)
                                Text(expense.reasonIfNotExpense ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ignored")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account")
                        .font(.headline)
                    Text("Email: \(authManager.userEmail)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                Button(role: .destructive) {
                    authManager.logout()
                } label: {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
