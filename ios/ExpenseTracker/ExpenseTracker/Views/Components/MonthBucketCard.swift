import SwiftUI

/// One row in the Home summary view — a tappable month bucket showing
/// expense/credit/investment/savings subtotals (design/mockups/
/// Expense Tracker.dc.html `monthCards`, lines 87-117).
struct MonthBucket: Identifiable {
    let id: String // "yyyy-MM"
    let label: String
    let isCurrent: Bool
    let expenses: Double
    let credits: Double
    let investments: Double

    var savings: Double { credits - expenses - investments }
}

struct MonthBucketCard: View {
    let bucket: MonthBucket
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(bucket.label)
                        .font(Theme.Font.ui(15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    if bucket.isCurrent {
                        Text("CURRENT")
                            .font(Theme.Font.ui(10, weight: .bold))
                            .foregroundColor(Theme.savingsFg)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.savingsBg)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                }

                HStack(spacing: 8) {
                    MonthMetricChip(title: "Expenses", value: bucket.expenses, bg: Theme.expenseBg, fg: Theme.expenseFg)
                    MonthMetricChip(title: "Credits", value: bucket.credits, bg: Theme.creditBg, fg: Theme.creditFg)
                    MonthMetricChip(title: "Invest.", value: bucket.investments, bg: Theme.investmentBg, fg: Theme.investmentFg)
                    MonthMetricChip(title: "Savings", value: bucket.savings, bg: Theme.savingsBg, fg: Theme.savingsFg)
                }
            }
            .padding(14)
            .background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
            .cornerRadius(Theme.cardRadius)
        }
        .buttonStyle(.plain)
    }
}

private struct MonthMetricChip: View {
    let title: String
    let value: Double
    let bg: Color
    let fg: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Font.ui(10, weight: .semibold))
                .foregroundColor(fg)
            Text(CurrencyFormat.rounded(value))
                .font(Theme.Font.mono(11, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(bg)
        .cornerRadius(8)
    }
}
