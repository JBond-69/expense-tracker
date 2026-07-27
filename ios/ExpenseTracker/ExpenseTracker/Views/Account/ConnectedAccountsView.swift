import SwiftUI

/// Connected accounts list (design/mockups/Expense Tracker.dc.html line
/// 408-434), backed by CRUD against `connected_accounts`.
///
/// "Add Google account" runs real Gmail OAuth client-side (PKCE via
/// GoogleSignInManager) and records the resulting email with status
/// "connected". Token exchange happening on-device rather than in a Phase 3
/// Edge Function is a deliberate early step, not the end state — the access
/// token itself is discarded once we have the email, nothing is persisted
/// or used to read mail yet. A manual-entry fallback remains below it for
/// testing without going through the consent screen. Status can be changed
/// via a context menu (long-press a row) and a row can be removed with its
/// trash button, so all four CRUD operations are exercised against the real
/// table.
struct ConnectedAccountsView: View {
    @ObservedObject var connectedAccountManager: ConnectedAccountManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSheet = false

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
                        ConnectedAccountRow(
                            account: account,
                            onDelete: { connectedAccountManager.deleteAccount(id: account.id, userID: authManager.userId) }
                        )
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

/// Pulled out of `ConnectedAccountsView`'s `ForEach` body — the inline
/// modifier chain there was slow enough for the type-checker to time out
/// once this branch was merged alongside the other screen-rebuild threads.
///
/// Deletes via an explicit trash button rather than swipe-to-delete: the
/// shared `View.swipeToDelete` helper this originally used was removed by
/// the Home-rebuild thread (replaced there with bulk-select delete), so
/// reusing it here would reintroduce a dependency the codebase moved away
/// from.
private struct ConnectedAccountRow: View {
    let account: ConnectedAccount
    let onDelete: () -> Void

    private var statusColors: (fg: Color, bg: Color) {
        switch account.status {
        case "connected": return (Theme.creditFg, Theme.creditBg)
        case "syncing": return (Color(hex: "#2A4CC5"), Color(hex: "#E5F5FF"))
        case "error": return (Theme.expenseFg, Theme.expenseBg)
        default: return (Theme.textSecondary, Theme.pillBackground)
        }
    }

    var body: some View {
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

            PillBadge(text: account.status.capitalized, fg: statusColors.fg, bg: statusColors.bg)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(Theme.cardRadius)
    }
}

private struct AddConnectedAccountSheet: View {
    @ObservedObject var connectedAccountManager: ConnectedAccountManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var googleSignInError: String?
    // @State, not a plain `let` — this view is reinitialized whenever authManager's
    // @Published properties change, which would otherwise deallocate an in-flight
    // ASWebAuthenticationSession mid-flow (see LoginView for the failure this causes).
    @State private var googleSignInManager = GoogleSignInManager()

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

            Button(action: signInWithGoogle) {
                Group {
                    if connectedAccountManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign in with Google")
                            .font(Theme.Font.ui(15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.primary)
                .cornerRadius(Theme.controlRadius)
            }
            .disabled(connectedAccountManager.isLoading)
            .padding(.bottom, 8)

            if let googleSignInError {
                Text(googleSignInError)
                    .font(Theme.Font.ui(12))
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }

            Text("or add a row manually (test-only fallback — no real Gmail connection):")
                .font(Theme.Font.ui(12))
                .foregroundColor(Theme.textSecondary)
                .padding(.top, 8)
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

    private func signInWithGoogle() {
        googleSignInError = nil
        googleSignInManager.signIn { result in
            switch result {
            case .success(let account):
                connectedAccountManager.addAccount(email: account.email, provider: "gmail", status: "connected", userID: authManager.userId) { success in
                    if success { dismiss() }
                }
            case .failure(let error):
                googleSignInError = "Google sign-in failed: \(error.localizedDescription)"
            }
        }
    }
}
