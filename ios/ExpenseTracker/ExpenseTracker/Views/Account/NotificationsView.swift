import SwiftUI

/// Notification preferences (design/mockups/Expense Tracker.dc.html line
/// 485-504), persisted to `notification_preferences`.
///
/// SCOPE NOTE: these toggles only store a preference row — no push
/// notification is actually sent on a new transaction or budget threshold.
/// Real delivery is unrelated future work; the caption below says this
/// explicitly rather than implying it's wired up.
struct NotificationsView: View {
    @ObservedObject var notificationPreferencesManager: NotificationPreferencesManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    private var newTransactionEnabled: Bool {
        notificationPreferencesManager.preferences?.newTransactionEnabled ?? true
    }

    private var budgetAlertEnabled: Bool {
        notificationPreferencesManager.preferences?.budgetAlertEnabled ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AccountSubHeader(title: "Notifications", onBack: { dismiss() })

                VStack(spacing: 0) {
                    HStack {
                        Text("New transaction detected")
                            .font(Theme.Font.ui(14))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { newTransactionEnabled },
                            set: { save(newTransactionEnabled: $0, budgetAlertEnabled: budgetAlertEnabled) }
                        ))
                        .labelsHidden()
                        .tint(Theme.primary)
                    }
                    .padding(14)

                    Divider().foregroundColor(Theme.divider)

                    HStack {
                        Text("Budget threshold alert")
                            .font(Theme.Font.ui(14))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { budgetAlertEnabled },
                            set: { save(newTransactionEnabled: newTransactionEnabled, budgetAlertEnabled: $0) }
                        ))
                        .labelsHidden()
                        .tint(Theme.primary)
                    }
                    .padding(14)
                }
                .background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(Theme.cardRadius)

                Text("These toggles only save your preference. Actual push delivery isn't wired up yet — that's separate, unrelated work.")
                    .font(Theme.Font.ui(12))
                    .foregroundColor(Theme.textTertiary)

                if let errorMessage = notificationPreferencesManager.errorMessage {
                    Text(errorMessage)
                        .font(Theme.Font.ui(12))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func save(newTransactionEnabled: Bool, budgetAlertEnabled: Bool) {
        let prefs = NotificationPreferences(
            userId: authManager.userId,
            newTransactionEnabled: newTransactionEnabled,
            budgetAlertEnabled: budgetAlertEnabled
        )
        notificationPreferencesManager.upsertPreferences(prefs)
    }
}
