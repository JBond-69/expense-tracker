import SwiftUI

/// Categories sub-page (design/mockups/Expense Tracker.dc.html line
/// 436-459) — expense/credit/investment tabs, a chip list scoped to the
/// selected type, and an add-a-category flow backed by `categories`.
struct CategoriesView: View {
    @ObservedObject var categoryManager: CategoryManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: TransactionType = .expense
    @State private var newCategoryName = ""

    private var chips: [Category] {
        categoryManager.categories
            .filter { $0.type == selectedType }
            .sorted { $0.name < $1.name }
    }

    private var canAdd: Bool {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !chips.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AccountSubHeader(title: "Categories", onBack: { dismiss() })

                PillSegmentedControl(
                    options: TransactionType.allCases.map { ($0, $0.label) },
                    selection: $selectedType
                )

                FlowLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(chips) { category in
                        Text(category.name)
                            .font(Theme.Font.ui(12, weight: .semibold))
                            .foregroundColor(Color(hex: category.colorFg))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: category.colorBg))
                            .cornerRadius(999)
                    }
                }

                if chips.isEmpty {
                    Text("No \(selectedType.label.lowercased()) categories yet.")
                        .font(Theme.Font.ui(13))
                        .foregroundColor(Theme.textTertiary)
                }

                HStack(spacing: 8) {
                    TextField("Add a category", text: $newCategoryName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))

                    Button(action: addCategory) {
                        Group {
                            if categoryManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 38, height: 38)
                        .background(canAdd ? Theme.primary : Theme.primary.opacity(0.4))
                        .cornerRadius(8)
                    }
                    .disabled(!canAdd || categoryManager.isLoading)
                }
                .padding(.top, 6)

                if let errorMessage = categoryManager.errorMessage {
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

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        // Falls back to the mockup's "Other" gray for any name outside its
        // hardcoded CAT_COLORS map (line 644) — there's no color picker in
        // this flow, matching the mockup's own add-category UI.
        let category = Category(
            id: UUID().uuidString,
            userId: authManager.userId,
            name: trimmed,
            type: selectedType,
            colorBg: "#E2E2E2",
            colorFg: "#221F1F",
            isDefault: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        categoryManager.addCategory(category, userID: authManager.userId) { success in
            if success { newCategoryName = "" }
        }
    }
}
