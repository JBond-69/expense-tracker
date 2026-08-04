import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var expenseManager: ExpenseManager

    init(authManager: AuthManager) {
        _expenseManager = StateObject(wrappedValue: ExpenseManager(authManager: authManager))
    }

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            IgnoredView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Ignored", systemImage: "tray.fill")
                }

            InsightsView()
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            AccountView(authManager: authManager)
                .environmentObject(expenseManager)
                .environmentObject(authManager)
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(Theme.primary)
        .onAppear {
            expenseManager.fetchExpenses(userID: authManager.userId)
        }
    }
}

#Preview {
    let authManager = AuthManager()
    MainTabView(authManager: authManager)
        .environmentObject(authManager)
}
