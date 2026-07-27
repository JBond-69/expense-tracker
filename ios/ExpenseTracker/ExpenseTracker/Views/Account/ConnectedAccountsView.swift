import SwiftUI

/// Connected accounts list (design/mockups/Expense Tracker.dc.html line
/// 408-434), backed by CRUD against `connected_accounts`.
///
/// DEVIATION FROM MOCKUP: "Add Google account" does not run real Gmail
/// OAuth — that's Phase 3 (docs/PROJECT_CONTEXT.md roadmap). It opens a
/// manual-entry sheet that says so explicitly and just inserts a row with
/// the email you type, status "connected". Status can be changed via a
/// context menu (long-press a row) and a row can be removed with swipe-to-
/// delete, so all four CRUD operations are exercised against the real table.
struct ConnectedAccountsView: View {
    @ObservedObject var connectedAccountManager: ConnectedAccountManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSheet = false

    private func statusColors(_ status: String) -> (fg: Color, bg: Color) {
        switch status {
        case "connected": return (Theme.creditFg, Theme.creditBg)
        case "syncing": return (Color(hex: "#2A4CC5"), Color(hex: "#E5F5FF"))
        case "error": return (Theme.expenseFg, Theme.expenseBg)
        default: return (Theme.textSecondary, Theme.pillBackground)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AccountSubHeader(title: "Connected accounts", onBack: { dismiss() })

                if connectedAccountManager.accounts.isEmpty {
                    Text("No Gmail accounts connected yet.")
                        .font(Theme.Font.ui(13))
                        .foregroundColor(Theme.textTertiary)
                }

                VStack(spacing: 8) {
                    ForEach(connectedAccountManager.accounts) { account in
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundColor(Theme.primary)
                                .font(.system(size: 15, weight: .medium))
                                .frame(width: 34, height: 34)
                                .background(Color(hex: "#F1F4FE"))
                                .cornerRadius(9)

                            Text(account.email)
                                .font(Theme.Font.ui(13, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            PillBadge(text: account.status.capitalized, fg: statusColors(account.status).fg, bg: statusColors(account.status).bg)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(Theme.cardRadius)
                        .swipeToDelete {
                            connectedAccountManager.deleteAccount(id: account.id, userID: authManager.userId)
                        }
                        .contextMenu {
                            ForEach(["connected", "syncing", "error", "disconnected"], id: \.self) { status in
                                Button(status.capitalized) {
                                    connectedAccountManager.updateStatus(id: account.id, status: status, userID: authManager.userId)
                                }
                            }
                        }
                    }

                    AccountAddRow(label: "Add Google account") { showAddSheet = true }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            AddConnectedAccountSheet(connectedAccountManager: connectedAccountManager)
                .environmentObject(authManager)
        }
    }
}

private struct AddConnectedAccountSheet: View {
    @ObservedObject var connectedAccountManager: ConnectedAccountManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    private var canSave: Bool {
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Add Google account")
                    .font(Theme.Font.ui(17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Theme.pillBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 12)

            // This is the explicit stub called out in the brief — no OAuth
            // consent screen exists yet, this just writes a row.
            Text("Manual entry stub — real Gmail OAuth is planned for Phase 3. This just records an email/status row; nothing is actually connected to Gmail.")
                .font(Theme.Font.ui(12))
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 16)

            Text("Email")
                .font(Theme.Font.ui(12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 8)
            TextField("you@gmail.com", text: $email)
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 44)
                .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
                .padding(.bottom, 20)

            if let errorMessage = connectedAccountManager.errorMessage {
                Text(errorMessage)
                    .font(Theme.Font.ui(12))
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }

            Button(action: save) {
                Group {
                    if connectedAccountManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Add account")
                            .font(Theme.Font.ui(15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(canSave ? Theme.primary : Theme.primary.opacity(0.4))
                .cornerRadius(Theme.controlRadius)
            }
            .disabled(!canSave || connectedAccountManager.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private func save() {
        connectedAccountManager.addAccount(email: email.trimmingCharacters(in: .whitespaces), provider: "gmail", status: "connected", userID: authManager.userId) { success in
            if success { dismiss() }
        }
    }
}
