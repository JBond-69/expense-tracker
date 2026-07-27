import SwiftUI

/// A single transaction row in the Home detail list view (design/mockups/
/// Expense Tracker.dc.html `detail.rows`, lines 150-163). Tapping the
/// checkbox toggles multi-select; tapping the rest of the row opens the
/// existing edit sheet.
struct ExpenseRowView: View {
    let expense: Expense
    let groupName: String
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onTap: () -> Void

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter
    }()

    private var dayLabel: String {
        guard let date = Self.dayFormatter.date(from: expense.date) else { return expense.date }
        return Self.dayLabelFormatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Theme.primary : Theme.textTertiary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(Theme.Font.ui(14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(groupName)
                    .font(Theme.Font.ui(11))
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormat.rounded(expense.amount))
                    .font(Theme.Font.mono(13, weight: .semibold))
                    .foregroundColor(expense.type.accentColor)
                Text(dayLabel)
                    .font(Theme.Font.ui(11))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
