import SwiftUI

/// Export sub-page (design/mockups/Expense Tracker.dc.html line 461-483).
///
/// DEVIATION FROM MOCKUP: `runExport` there triggers a browser file
/// download. There's no browser here, so this builds the CSV in memory from
/// the already-fetched `expenseManager.expenses`, writes it to a temp file,
/// and hands it to the native share sheet (Mail, Files, AirDrop, etc.).
struct ExportView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @Environment(\.dismiss) private var dismiss

    private enum Range: String, CaseIterable, Identifiable {
        case thisMonth, lastMonth, last3Months, allTime, custom
        var id: String { rawValue }
        var label: String {
            switch self {
            case .thisMonth: return "This Month"
            case .lastMonth: return "Last Month"
            case .last3Months: return "Last 3 Months"
            case .allTime: return "All Time"
            case .custom: return "Custom"
            }
        }
    }

    @State private var selectedRange: Range = .thisMonth
    @State private var customFrom = Date()
    @State private var customTo = Date()
    @State private var shareItems: [Any]?

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()

    private var interval: (from: String, to: String)? {
        let calendar = Calendar.current
        let today = Date()
        switch selectedRange {
        case .thisMonth:
            guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return nil }
            return (Self.dayFormatter.string(from: start), Self.dayFormatter.string(from: today))
        case .lastMonth:
            guard let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
                  let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart),
                  let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart) else { return nil }
            return (Self.dayFormatter.string(from: lastMonthStart), Self.dayFormatter.string(from: lastMonthEnd))
        case .last3Months:
            guard let start = calendar.date(byAdding: .month, value: -3, to: today) else { return nil }
            return (Self.dayFormatter.string(from: start), Self.dayFormatter.string(from: today))
        case .allTime:
            return nil
        case .custom:
            return (Self.dayFormatter.string(from: customFrom), Self.dayFormatter.string(from: customTo))
        }
    }

    private var filteredExpenses: [Expense] {
        guard let interval else { return expenseManager.expenses }
        return expenseManager.expenses.filter { $0.date >= interval.from && $0.date <= interval.to }
    }

    private var total: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AccountSubHeader(title: "Export", onBack: { dismiss() })

                FlowLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(Range.allCases) { range in
                        Button(action: { selectedRange = range }) {
                            Text(range.label)
                                .font(Theme.Font.ui(12, weight: .semibold))
                                .foregroundColor(selectedRange == range ? .white : Theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selectedRange == range ? Theme.primary : Theme.pillBackground)
                                .cornerRadius(999)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedRange == .custom {
                    HStack(spacing: 8) {
                        DatePicker("From", selection: $customFrom, displayedComponents: .date)
                            .labelsHidden()
                        DatePicker("To", selection: $customTo, displayedComponents: .date)
                            .labelsHidden()
                    }
                }

                Text("\(filteredExpenses.count) transactions · ₹\(total, specifier: "%.2f")")
                    .font(Theme.Font.ui(12))
                    .foregroundColor(Theme.textTertiary)

                Button(action: exportCSV) {
                    Text("Export CSV")
                        .font(Theme.Font.ui(14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(filteredExpenses.isEmpty ? Theme.primary.opacity(0.4) : Theme.primary)
                        .cornerRadius(Theme.controlRadius)
                }
                .disabled(filteredExpenses.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: Binding(
            get: { shareItems != nil },
            set: { if !$0 { shareItems = nil } }
        )) {
            ActivityView(items: shareItems ?? [])
        }
    }

    private func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func exportCSV() {
        var rows = ["Date,Type,Category,Merchant,Amount,Notes,Group"]
        for expense in filteredExpenses.sorted(by: { $0.date < $1.date }) {
            let row = [
                expense.date,
                expense.type.label,
                expense.category,
                expense.merchant,
                String(format: "%.2f", expense.amount),
                expense.notes ?? "",
                expense.groupId ?? ""
            ].map(csvField).joined(separator: ",")
            rows.append(row)
        }
        let csv = rows.joined(separator: "\n")

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("expenses_export.csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            shareItems = [fileURL]
        } catch {
            // Nothing else writes to this file concurrently and the temp
            // directory is always writable, so a failure here would be an
            // unexpected environment issue rather than something to recover
            // from in the UI.
        }
    }
}
