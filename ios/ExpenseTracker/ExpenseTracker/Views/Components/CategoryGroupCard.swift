import SwiftUI

/// One expandable category bucket in the Home detail "Card" view (design/
/// mockups/Expense Tracker.dc.html `computeMonthGroupsView`, line 996) —
/// transactions in the open month bucketed by type+category, sorted by total.
struct CategoryGroupBucket: Identifiable {
    let id: String // "type|category"
    let name: String
    let type: TransactionType
    let tint: (bg: Color, fg: Color)
    let total: Double
    let items: [Expense]
}

struct CategoryGroupCard: View {
    let bucket: CategoryGroupBucket
    let isExpanded: Bool
    let onToggle: () -> Void

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

    private func dayLabel(_ dateString: String) -> String {
        guard let date = Self.dayFormatter.date(from: dateString) else { return dateString }
        return Self.dayLabelFormatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(bucket.tint.fg)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bucket.name)
                            .font(Theme.Font.ui(14, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("\(bucket.type.label) · \(bucket.items.count) transaction\(bucket.items.count == 1 ? "" : "s")")
                            .font(Theme.Font.ui(12))
                            .foregroundColor(Theme.textTertiary)
                    }

                    Spacer()

                    Text(CurrencyFormat.rounded(bucket.total))
                        .font(Theme.Font.mono(14, weight: .semibold))
                        .foregroundColor(bucket.type.accentColor)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(bucket.items.sorted(by: { $0.date > $1.date })) { item in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.merchant)
                                    .font(Theme.Font.ui(13))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                Text(dayLabel(item.date))
                                    .font(Theme.Font.ui(11))
                                    .foregroundColor(Theme.textTertiary)
                            }
                            Spacer()
                            Text(CurrencyFormat.rounded(item.amount))
                                .font(Theme.Font.mono(13))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .padding(.top, 2)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.divider), alignment: .top)
            }
        }
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(Theme.cardRadius)
    }
}
