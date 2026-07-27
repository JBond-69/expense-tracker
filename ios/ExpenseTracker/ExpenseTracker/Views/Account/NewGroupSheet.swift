import SwiftUI

/// "New recurring group" creation sheet (design/mockups/Expense Tracker.dc.html
/// line 597-620) — name, type, recurring toggle only, matching the mockup's
/// form fields exactly (no category-ref picker in this sheet).
struct NewGroupSheet: View {
    @ObservedObject var groupManager: ExpenseGroupManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: TransactionType = .expense
    @State private var recurring = true

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("New recurring group")
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
            .padding(.bottom, 18)

            Text("Name")
                .font(Theme.Font.ui(12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 8)
            TextField("e.g. Date Nights", text: $name)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
                .padding(.bottom, 16)

            Text("Type")
                .font(Theme.Font.ui(12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 8)
            PillSegmentedControl(
                options: TransactionType.allCases.map { ($0, $0.label) },
                selection: $type
            )
            .padding(.bottom, 16)

            HStack {
                Text("Recurring")
                    .font(Theme.Font.ui(14))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Toggle("", isOn: $recurring)
                    .labelsHidden()
                    .tint(Theme.primary)
            }
            .padding(.bottom, 22)

            if let errorMessage = groupManager.errorMessage {
                Text(errorMessage)
                    .font(Theme.Font.ui(12))
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }

            Button(action: save) {
                Group {
                    if groupManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create group")
                            .font(Theme.Font.ui(15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(canSave ? Theme.primary : Theme.primary.opacity(0.4))
                .cornerRadius(Theme.controlRadius)
            }
            .disabled(!canSave || groupManager.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private func save() {
        let group = ExpenseGroup(
            id: UUID().uuidString,
            userId: authManager.userId,
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            recurring: recurring,
            catRef: nil,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        groupManager.addGroup(group, userID: authManager.userId) { success in
            if success { dismiss() }
        }
    }
}
