import SwiftUI

private struct CategorySpendItem: Identifiable {
    let id: String
    let category: ExpenseCategory
    let amount: Double
    let pct: Double
}

private struct MonthTrendItem: Identifiable {
    let id: String
    let label: String
    let shortAmount: String
    let pct: Double
    let isLatest: Bool
}

/// Bar color for non-latest months in the trend chart (design/mockups/
/// Expense Tracker.dc.html line 1155's `barColor` for i !== latestMonthIndex).
/// Screen-specific, so it lives here rather than in the shared Theme.
private let trendBarInactive = Color(hex: "#BECFF6")

struct InsightsView: View {
    @EnvironmentObject var expenseManager: ExpenseManager

    private static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    private static let monthKeyDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    private static let monthAbbrFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let latestMonthLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    /// Mirrors HomeView's `trackedExpenses`, plus the type filter this task
    /// specifies — credits/investments and ignored rows aren't spend.
    private var trackedExpenseSpend: [Expense] {
        expenseManager.expenses.filter { $0.isExpense && $0.type == .expense }
    }

    /// Trailing 4 calendar months ending at the current month, oldest first —
    /// same window shape as the mockup's fixed MONTHS_META (line 654-659),
    /// computed from today instead of hardcoded test dates.
    private var trendMonthKeys: [String] {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        return (0..<4).reversed().compactMap { offset -> String? in
            calendar.date(byAdding: .month, value: -offset, to: now)
                .map { Self.monthKeyFormatter.string(from: $0) }
        }
    }

    private var latestMonthKey: String {
        trendMonthKeys.last ?? Self.monthKeyFormatter.string(from: Date())
    }

    private var latestMonthLabel: String {
        Self.monthKeyDayFormatter.date(from: "\(latestMonthKey)-01")
            .map { Self.latestMonthLabelFormatter.string(from: $0) }
            ?? latestMonthKey
    }

    /// design/mockups line 1148-1151: sum the latest month's expenses by
    /// category, sort desc, keep the top 6, bar width relative to the
    /// largest category that month.
    private var categorySpend: [CategorySpendItem] {
        var totals: [ExpenseCategory: Double] = [:]
        for expense in trackedExpenseSpend where String(expense.date.prefix(7)) == latestMonthKey {
            let category = ExpenseCategory(rawValue: expense.category) ?? .other
            totals[category, default: 0] += expense.amount
        }
        let maxAmount = max(1, totals.values.max() ?? 1)
        return totals.sorted { $0.value > $1.value }
            .prefix(6)
            .map { CategorySpendItem(id: $0.key.rawValue, category: $0.key, amount: $0.value, pct: $0.value / maxAmount * 100) }
    }

    /// design/mockups line 1153-1155: total expense per trailing month, bar
    /// height relative to the largest month in the window (min 6% floor so a
    /// zero-spend month still shows a sliver), latest month highlighted.
    private var monthTrend: [MonthTrendItem] {
        let keys = trendMonthKeys
        let totalsByKey = keys.reduce(into: [String: Double]()) { result, key in
            result[key] = trackedExpenseSpend
                .filter { String($0.date.prefix(7)) == key }
                .reduce(0) { $0 + $1.amount }
        }
        let maxAmount = max(1, totalsByKey.values.max() ?? 1)
        return keys.map { key in
            let amount = totalsByKey[key] ?? 0
            let label = Self.monthKeyDayFormatter.date(from: "\(key)-01")
                .map { Self.monthAbbrFormatter.string(from: $0) }
                ?? key
            let shortAmount = amount >= 1000 ? "₹\(Int((amount / 1000).rounded()))k" : "₹\(Int(amount.rounded()))"
            return MonthTrendItem(id: key, label: label, shortAmount: shortAmount, pct: max(6, amount / maxAmount * 100), isLatest: key == latestMonthKey)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if trackedExpenseSpend.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.textTertiary)
                        Text("No expense data yet")
                            .font(Theme.Font.ui(14))
                            .foregroundColor(Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights")
                                .font(Theme.Font.ui(28, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.top, 8)
                            Text("More views coming soon.")
                                .font(Theme.Font.ui(13))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.bottom, 6)

                            categoryCard
                            trendCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spend by category · \(latestMonthLabel)")
                .font(Theme.Font.ui(13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            if categorySpend.isEmpty {
                Text("No spend recorded this month")
                    .font(Theme.Font.ui(13))
                    .foregroundColor(Theme.textTertiary)
            } else {
                VStack(spacing: 10) {
                    ForEach(categorySpend) { item in
                        VStack(spacing: 4) {
                            HStack {
                                Text(item.category.rawValue)
                                    .font(Theme.Font.ui(12))
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text("₹\(item.amount, specifier: "%.2f")")
                                    .font(Theme.Font.mono(12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.divider)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.category.tint.fg)
                                        .frame(width: geo.size.width * CGFloat(item.pct / 100))
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(Theme.cardRadius)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Expense trend")
                .font(Theme.Font.ui(13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(monthTrend) { item in
                    VStack(spacing: 6) {
                        Text(item.shortAmount)
                            .font(Theme.Font.mono(10))
                            .foregroundColor(Theme.textTertiary)
                        VStack {
                            Spacer(minLength: 0)
                            UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 5)
                                .fill(item.isLatest ? Theme.primary : trendBarInactive)
                                .frame(height: 60 * CGFloat(item.pct / 100))
                        }
                        .frame(height: 60)
                        Text(item.label)
                            .font(Theme.Font.ui(11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(Theme.cardRadius)
    }
}

private func previewExpense(
    _ merchant: String,
    _ category: String,
    _ amount: Double,
    monthsAgo: Int,
    day: Int
) -> Expense {
    let calendar = Calendar(identifier: .iso8601)
    let now = Date()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        return formatter
    }()

    let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
    var components = calendar.dateComponents([.year, .month], from: monthDate)
    components.day = day
    let date = calendar.date(from: components) ?? monthDate
    let dateString = dateFormatter.string(from: date)

    return Expense(
        id: UUID().uuidString,
        userId: "preview-user",
        amount: amount,
        merchant: merchant,
        category: category,
        date: dateString,
        notes: nil,
        source: "manual",
        isExpense: true,
        reasonIfNotExpense: nil,
        createdAt: dateString,
        type: .expense,
        groupId: nil
    )
}

#Preview("With data") {
    let authManager = AuthManager()
    let expenseManager = ExpenseManager(authManager: authManager)

    expenseManager.expenses = [
        // Latest month — enough categories to exercise the top-6 + sort.
        previewExpense("Whole Foods", "Food", 4200, monthsAgo: 0, day: 3),
        previewExpense("Local Diner", "Food", 1850, monthsAgo: 0, day: 12),
        previewExpense("Uber", "Transport", 2600, monthsAgo: 0, day: 5),
        previewExpense("Metro Card", "Transport", 900, monthsAgo: 0, day: 20),
        previewExpense("Amazon", "Shopping", 3400, monthsAgo: 0, day: 8),
        previewExpense("Electricity Board", "Bills", 2100, monthsAgo: 0, day: 15),
        previewExpense("Flight Booking", "Travel", 8600, monthsAgo: 0, day: 22),
        previewExpense("Movie Night", "Entertainment", 750, monthsAgo: 0, day: 18),
        previewExpense("Pharmacy", "Health", 540, monthsAgo: 0, day: 10),
        // Prior months, for the trend chart.
        previewExpense("Groceries", "Food", 12000, monthsAgo: 1, day: 10),
        previewExpense("Rent", "Bills", 18000, monthsAgo: 1, day: 1),
        previewExpense("Groceries", "Food", 9000, monthsAgo: 2, day: 8),
        previewExpense("Rent", "Bills", 18000, monthsAgo: 2, day: 1),
        previewExpense("Flight", "Travel", 22000, monthsAgo: 3, day: 14),
        previewExpense("Rent", "Bills", 18000, monthsAgo: 3, day: 1),
    ]

    return InsightsView()
        .environmentObject(expenseManager)
}

#Preview("Empty state") {
    let authManager = AuthManager()
    let expenseManager = ExpenseManager(authManager: authManager)
    expenseManager.expenses = []

    return InsightsView()
        .environmentObject(expenseManager)
}
