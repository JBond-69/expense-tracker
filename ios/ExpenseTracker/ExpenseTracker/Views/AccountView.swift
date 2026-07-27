import SwiftUI

/// Account tab root — profile header + sign out, and a nav list to the five
/// sub-pages (design/mockups/Expense Tracker.dc.html lines 290-509). Owns
/// the four new managers (groups/categories/connected accounts/notification
/// prefs) added in feature/data-foundation; `expenseManager`/`authManager`
/// come from the shared environment MainTabView already injects.
///
/// Not wired into MainTabView.swift by this branch — see docs/PROJECT_CONTEXT.md
/// session log for why (avoids a guaranteed merge conflict across the six
/// parallel screen-rebuild threads; left for final integration).
struct AccountView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var expenseManager: ExpenseManager

    @StateObject private var groupManager: ExpenseGroupManager
    @StateObject private var categoryManager: CategoryManager
    @StateObject private var connectedAccountManager: ConnectedAccountManager
    @StateObject private var notificationPreferencesManager: NotificationPreferencesManager

    init(authManager: AuthManager) {
        _groupManager = StateObject(wrappedValue: ExpenseGroupManager(authManager: authManager))
        _categoryManager = StateObject(wrappedValue: CategoryManager(authManager: authManager))
        _connectedAccountManager = StateObject(wrappedValue: ConnectedAccountManager(authManager: authManager))
        _notificationPreferencesManager = StateObject(wrappedValue: NotificationPreferencesManager(authManager: authManager))
    }

    private var initial: String {
        String(authManager.userEmail.prefix(1)).uppercased()
    }

    private var notifSummary: String {
        guard let prefs = notificationPreferencesManager.preferences else { return "—" }
        let onCount = [prefs.newTransactionEnabled, prefs.budgetAlertEnabled].filter { $0 }.count
        return onCount == 0 ? "Off" : "\(onCount) on"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        Text(initial)
                            .font(Theme.Font.ui(18, weight: .bold))
                            .foregroundColor(Color(hex: "#2A4CC5"))
                            .frame(width: 52, height: 52)
                            .background(Color(hex: "#E3E8FC"))
                            .clipShape(Circle())

                        // Mockup shows a display name above the email
                        // ("Prannoy"); the app only collects an email at
                        // OTP login, so that line is dropped rather than
                        // faked — deviation noted in the session log.
                        Text(authManager.userEmail)
                            .font(Theme.Font.ui(15, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(.bottom, 26)

                    VStack(spacing: 8) {
                        NavigationLink {
                            RecurringGroupsView(groupManager: groupManager)
                        } label: {
                            AccountNavRow(icon: "square.stack.3d.up", title: "Recurring groups", value: groupManager.groups.count == 1 ? "1 group" : "\(groupManager.groups.count) groups")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ConnectedAccountsView(connectedAccountManager: connectedAccountManager)
                        } label: {
                            AccountNavRow(icon: "envelope", title: "Connected accounts", value: "\(connectedAccountManager.accounts.count) linked")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CategoriesView(categoryManager: categoryManager)
                        } label: {
                            AccountNavRow(icon: "tag", title: "Categories", value: "\(categoryManager.categories.count)")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ExportView()
                        } label: {
                            AccountNavRow(icon: "square.and.arrow.up", title: "Export", value: "CSV")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            NotificationsView(notificationPreferencesManager: notificationPreferencesManager)
                        } label: {
                            AccountNavRow(icon: "bell", title: "Notifications", value: notifSummary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 20)

                    Button(action: { authManager.logout() }) {
                        Text("Sign out")
                            .font(Theme.Font.ui(14, weight: .semibold))
                            .foregroundColor(Theme.expenseFg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
                            .cornerRadius(Theme.controlRadius)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .environmentObject(expenseManager)
        .onAppear {
            groupManager.fetchGroups(userID: authManager.userId)
            categoryManager.fetchCategories(userID: authManager.userId)
            connectedAccountManager.fetchAccounts(userID: authManager.userId)
            notificationPreferencesManager.fetchPreferences(userID: authManager.userId)
        }
    }
}

#Preview {
    let authManager = AuthManager()
    AccountView(authManager: authManager)
        .environmentObject(authManager)
        .environmentObject(ExpenseManager(authManager: authManager))
}
