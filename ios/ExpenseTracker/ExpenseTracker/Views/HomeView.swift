import SwiftUI

/// Home tab entry point. MainTabView constructs this with no arguments, so
/// `authManager` is only available once the environment is injected — the
/// actual content (and its @StateObject managers) live in `HomeContentView`,
/// which takes `authManager` as an explicit init parameter the same way
/// MainTabView -> ExpenseManager already does.
struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        HomeContentView(authManager: authManager)
            .environmentObject(expenseManager)
            .environmentObject(authManager)
    }
}

private enum DetailViewMode {
    case list
    case groups
}

private struct CategoryAccumulator {
    let name: String
    let type: TransactionType
    var items: [Expense] = []
}

private struct HomeContentView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var categoryManager: CategoryManager
    @StateObject private var groupManager: ExpenseGroupManager

    @State private var openMonthKey: String?
    @State private var viewMode: DetailViewMode = .list
    @State private var searchText = ""
    @State private var expandedCategoryKeys: Set<String> = []
    @State private var selectedIDs: Set<String> = []
    @State private var confirmDelete: BulkDeleteConfirmation?
    @State private var showAddExpense = false
    @State private var editingExpense: Expense?

    init(authManager: AuthManager) {
        _categoryManager = StateObject(wrappedValue: CategoryManager(authManager: authManager))
        _groupManager = StateObject(wrappedValue: ExpenseGroupManager(authManager: authManager))
    }

    private static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

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

    private static func monthKeyDate(_ key: String) -> Date? {
        monthKeyFormatter.date(from: key)
    }

    // MARK: - Derived data

    private var trackedExpenses: [Expense] {
        expenseManager.expenses.filter(\.isExpense)
    }

    private var monthBuckets: [MonthBucket] {
        let grouped = Dictionary(grouping: trackedExpenses) { String($0.date.prefix(7)) }
        let currentKey = String(Self.dayFormatter.string(from: Date()).prefix(7))
        return grouped.keys.sorted(by: >).map { key in
            let items = grouped[key] ?? []
            let expenses = items.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let credits = items.filter { $0.type == .credit }.reduce(0) { $0 + $1.amount }
            let investments = items.filter { $0.type == .investment }.reduce(0) { $0 + $1.amount }
            let label = Self.monthKeyDate(key).map { Self.monthLabelFormatter.string(from: $0) } ?? key
            return MonthBucket(id: key, label: label, isCurrent: key == currentKey, expenses: expenses, credits: credits, investments: investments)
        }
    }

    private var openMonthLabel: String {
        guard let key = openMonthKey, let date = Self.monthKeyDate(key) else { return "" }
        return Self.monthLabelFormatter.string(from: date)
    }

    private var openMonthExpenses: [Expense] {
        guard let key = openMonthKey else { return [] }
        return trackedExpenses.filter { $0.date.hasPrefix(key) }
    }

    private func groupName(for groupId: String?) -> String {
        guard let groupId, let group = groupManager.groups.first(where: { $0.id == groupId }) else {
            return "Miscellaneous"
        }
        return group.name
    }

    private func categoryTint(type: TransactionType, name: String) -> (bg: Color, fg: Color) {
        if let cat = categoryManager.categories.first(where: { $0.type == type && $0.name == name }) {
            return (Color(hex: cat.colorBg), Color(hex: cat.colorFg))
        }
        return (Theme.pillBackground, Theme.textSecondary)
    }

    private var filteredDetailRows: [Expense] {
        let rows = openMonthExpenses.sorted { $0.date > $1.date }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return rows }
        return rows.filter {
            $0.merchant.lowercased().contains(q) ||
            $0.category.lowercased().contains(q) ||
            groupName(for: $0.groupId).lowercased().contains(q)
        }
    }

    private var detailSubtotal: (expenses: Double, credits: Double, investments: Double, savings: Double) {
        var e = 0.0, c = 0.0, i = 0.0
        for row in filteredDetailRows {
            switch row.type {
            case .expense: e += row.amount
            case .credit: c += row.amount
            case .investment: i += row.amount
            }
        }
        return (e, c, i, c - e - i)
    }

    private var categoryGroupBuckets: [CategoryGroupBucket] {
        var buckets: [String: CategoryAccumulator] = [:]
        for row in openMonthExpenses {
            let key = "\(row.type.rawValue)|\(row.category)"
            buckets[key, default: CategoryAccumulator(name: row.category, type: row.type)].items.append(row)
        }
        return buckets.map { key, value in
            let total = value.items.reduce(0) { $0 + $1.amount }
            return CategoryGroupBucket(
                id: key,
                name: value.name,
                type: value.type,
                tint: categoryTint(type: value.type, name: value.name),
                total: total,
                items: value.items
            )
        }.sorted { $0.total > $1.total }
    }

    // MARK: - Actions

    private func openMonth(_ key: String) {
        openMonthKey = key
        viewMode = .list
        searchText = ""
        expandedCategoryKeys = []
        selectedIDs = []
    }

    private func closeDetail() {
        openMonthKey = nil
        selectedIDs = []
    }

    private func toggleSelected(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func requestBulkDelete() {
        guard !selectedIDs.isEmpty else { return }
        let rows = openMonthExpenses.filter { selectedIDs.contains($0.id) }
        let total = rows.reduce(0) { $0 + $1.amount }
        confirmDelete = BulkDeleteConfirmation(ids: Array(selectedIDs), count: selectedIDs.count, totalFmt: CurrencyFormat.rounded(total))
    }

    private func performBulkDelete() {
        guard let confirmDelete else { return }
        expenseManager.deleteExpenses(ids: confirmDelete.ids, userID: authManager.userId) { _ in
            selectedIDs.removeAll()
        }
        self.confirmDelete = nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()

                Group {
                    if openMonthKey == nil {
                        summaryView
                    } else {
                        detailView
                    }
                }

                if !selectedIDs.isEmpty {
                    BulkDeleteBar(count: selectedIDs.count, onDelete: requestBulkDelete)
                        .padding(.bottom, 20)
                } else {
                    fab
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }

                if let confirmDelete {
                    DeleteConfirmationDialog(
                        confirmation: confirmDelete,
                        onCancel: { self.confirmDelete = nil },
                        onConfirm: performBulkDelete
                    )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                categoryManager.fetchCategories(userID: authManager.userId)
                groupManager.fetchGroups(userID: authManager.userId)
            }
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

    private var fab: some View {
        Button(action: { showAddExpense = true }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Theme.primary)
                .clipShape(Circle())
                .shadow(color: Theme.primary.opacity(0.4), radius: 14, x: 0, y: 8)
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Expenses")
                    .font(Theme.Font.ui(28, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.top, 8)

                if monthBuckets.isEmpty {
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
                    VStack(spacing: 10) {
                        ForEach(monthBuckets) { bucket in
                            MonthBucketCard(bucket: bucket, action: { openMonth(bucket.id) })
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
        }
    }

    // MARK: - Detail

    private var detailView: some View {
        VStack(spacing: 0) {
            detailHeader

            if viewMode == .list {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    listBody
                        .padding(.horizontal, 16)
                        .padding(.bottom, 110)
                }
            } else {
                ScrollView {
                    groupsBody
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 110)
                }
            }
        }
    }

    private var detailHeader: some View {
        HStack {
            Button(action: closeDetail) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                    .clipShape(Circle())
            }

            Spacer()

            Text(openMonthLabel)
                .font(Theme.Font.ui(15, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            HStack(spacing: 2) {
                viewModeButton(title: "List", mode: .list)
                viewModeButton(title: "Card", mode: .groups)
            }
            .padding(3)
            .background(Theme.pillBackground)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private func viewModeButton(title: String, mode: DetailViewMode) -> some View {
        let active = viewMode == mode
        return Button(action: { viewMode = mode }) {
            Text(title)
                .font(Theme.Font.ui(12, weight: .semibold))
                .foregroundColor(active ? Theme.textPrimary : Theme.textSecondary)
                .frame(width: 52, height: 30)
                .background(active ? Theme.surface : Color.clear)
                .clipShape(Capsule())
                .shadow(color: active ? Theme.textTertiary.opacity(0.25) : .clear, radius: 3, x: 0, y: 1)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(Theme.textTertiary)
            TextField("Search \(openMonthLabel)", text: $searchText)
                .font(Theme.Font.ui(13))
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(Theme.controlRadius)
    }

    private var listBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer().frame(width: 18)
                Text("Description").frame(maxWidth: .infinity, alignment: .leading)
                Text("Group").frame(width: 80, alignment: .leading)
                Text("Amount").frame(width: 70, alignment: .trailing)
                Text("Date").frame(width: 44, alignment: .trailing)
            }
            .font(Theme.Font.ui(10, weight: .bold))
            .foregroundColor(Theme.textTertiary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)

            if filteredDetailRows.isEmpty {
                Text("No transactions match your search.")
                    .font(Theme.Font.ui(13))
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredDetailRows.enumerated()), id: \.element.id) { index, expense in
                        ExpenseRowView(
                            expense: expense,
                            groupName: groupName(for: expense.groupId),
                            isSelected: selectedIDs.contains(expense.id),
                            onToggleSelect: { toggleSelected(expense.id) },
                            onTap: { editingExpense = expense }
                        )
                        if index < filteredDetailRows.count - 1 {
                            Divider().foregroundColor(Theme.divider)
                        }
                    }

                    subtotalFooter
                }
                .background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(Theme.cardRadius)
            }
        }
    }

    private var subtotalFooter: some View {
        let subtotal = detailSubtotal
        return HStack(spacing: 6) {
            subtotalCell(title: "DEBIT", value: subtotal.expenses, color: Theme.expenseFg)
            subtotalCell(title: "CREDIT", value: subtotal.credits, color: Theme.creditFg)
            subtotalCell(title: "INVEST.", value: subtotal.investments, color: Theme.investmentFg)
            subtotalCell(title: "SAVINGS", value: subtotal.savings, color: Theme.savingsFg)
        }
        .padding(10)
        .background(Theme.background)
    }

    private func subtotalCell(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(Theme.Font.ui(9, weight: .bold))
                .foregroundColor(color)
            Text(CurrencyFormat.rounded(value))
                .font(Theme.Font.mono(12, weight: .bold))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var groupsBody: some View {
        VStack(spacing: 10) {
            if categoryGroupBuckets.isEmpty {
                Text("No transactions this month.")
                    .font(Theme.Font.ui(13))
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(categoryGroupBuckets) { bucket in
                    CategoryGroupCard(
                        bucket: bucket,
                        isExpanded: expandedCategoryKeys.contains(bucket.id),
                        onToggle: {
                            if expandedCategoryKeys.contains(bucket.id) {
                                expandedCategoryKeys.remove(bucket.id)
                            } else {
                                expandedCategoryKeys.insert(bucket.id)
                            }
                        }
                    )
                }
            }
        }
    }
}
