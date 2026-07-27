import SwiftUI

/// Recurring group detail (design/mockups/Expense Tracker.dc.html line
/// 375-406) — type + "Recurring" badges, a total-across-all-months card, and
/// the list of transactions tagged with this group.
struct GroupDetailView: View {
    let group: ExpenseGroup
    @EnvironmentObject var expenseManager: ExpenseManager
    @Environment(\.dismiss) private var dismiss

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    private static let monthLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private var items: [Expense] {
        expenseManager.expenses
            .filter { $0.groupId == group.id }
            .sorted { $0.date > $1.date }
    }

    private var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(Theme.surface)
                            .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    Circle()
                        .fill(group.type.tint.fg)
                        .frame(width: 10, height: 10)
                    Text(group.name)
                        .font(Theme.Font.ui(17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                .padding(.bottom, 18)

                HStack(spacing: 6) {
                    PillBadge(text: group.type.label, fg: group.type.tint.fg, bg: group.type.tint.bg)
                    PillBadge(text: "Recurring", fg: Color(hex: "#2A4CC5"), bg: Color(hex: "#F1F4FE"))
                }
                .padding(.bottom, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total across all months")
                        .font(Theme.Font.ui(12))
                        .foregroundColor(Color(hex: "#2A4CC5"))
                    Text("₹\(total, specifier: "%.2f")")
                        .font(Theme.Font.mono(20, weight: .bold))
                        .foregroundColor(Color(hex: "#0D1F6E"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#F1F4FE"))
                .cornerRadius(Theme.cardRadius)
                .padding(.bottom, 20)

                if items.isEmpty {
                    Text("No transactions tagged with this group yet.")
                        .font(Theme.Font.ui(13))
                        .foregroundColor(Theme.textTertiary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(items) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.merchant)
                                        .font(Theme.Font.ui(14, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                    if let date = Self.dayFormatter.date(from: item.date) {
                                        Text("\(Self.monthLabelFormatter.string(from: date)) · \(Self.dayLabelFormatter.string(from: date))")
                                            .font(Theme.Font.ui(12))
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                                Spacer()
                                Text("₹\(item.amount, specifier: "%.2f")")
                                    .font(Theme.Font.mono(14, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                            .cornerRadius(Theme.cardRadius)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
