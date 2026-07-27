import SwiftUI

/// Recurring groups list (design/mockups/Expense Tracker.dc.html line
/// 347-373) — each row pushes to GroupDetailView; "New group" opens a
/// creation sheet.
struct RecurringGroupsView: View {
    @ObservedObject var groupManager: ExpenseGroupManager
    @EnvironmentObject var expenseManager: ExpenseManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var showNewGroupSheet = false

    private func total(for group: ExpenseGroup) -> Double {
        expenseManager.expenses.filter { $0.groupId == group.id }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AccountSubHeader(title: "Recurring groups", onBack: { dismiss() })

                if groupManager.groups.isEmpty {
                    Text("No recurring groups yet.")
                        .font(Theme.Font.ui(13))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 20)
                }

                VStack(spacing: 8) {
                    ForEach(groupManager.groups) { group in
                        NavigationLink {
                            GroupDetailView(group: group)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(group.type.tint.fg)
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.name)
                                        .font(Theme.Font.ui(14, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("\(group.type.label) · Recurring")
                                        .font(Theme.Font.ui(12))
                                        .foregroundColor(Theme.textTertiary)
                                }
                                Spacer()
                                Text("₹\(total(for: group), specifier: "%.2f")")
                                    .font(Theme.Font.mono(13, weight: .semibold))
                                    .foregroundColor(Theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.textTertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                            .cornerRadius(Theme.cardRadius)
                        }
                        .buttonStyle(.plain)
                    }

                    AccountAddRow(label: "New group") { showNewGroupSheet = true }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewGroupSheet) {
            NewGroupSheet(groupManager: groupManager)
                .environmentObject(authManager)
        }
    }
}
