import SwiftUI

/// Shared bottom-sheet form used by both Add and Edit, extended to cover all
/// three transaction kinds per the showAddSheet block in design/mockups/
/// Expense Tracker.dc.html (~lines 552-595, logic ~lines 894-900,
/// 1160-1231): a type selector, a category picker scoped to the selected
/// type (read from the `categories` table, not a hardcoded enum), and an
/// optional recurring-group assignment scoped the same way.
///
/// Owns its `CategoryManager`/`ExpenseGroupManager` instances rather than
/// receiving them via `@EnvironmentObject`, because `authManager` (needed to
/// construct them) is only resolved once `AddExpenseView`/`EditExpenseView`'s
/// `body` runs — by then it's safe to pass as a plain init parameter here,
/// which lets this view build its `@StateObject`s correctly without any
/// changes to MainTabView/HomeView's environment-object wiring.
struct ExpenseFormSheet: View {
    let title: String
    @Binding var selectedType: TransactionType
    @Binding var amount: String
    @Binding var merchant: String
    @Binding var selectedCategory: String
    @Binding var selectedGroupId: String?
    @Binding var notes: String
    @Binding var date: Date
    let isLoading: Bool
    let errorMessage: String?
    let onClose: () -> Void
    let onSave: () -> Void

    @StateObject private var categoryManager: CategoryManager
    @StateObject private var groupManager: ExpenseGroupManager
    private let authManager: AuthManager

    init(
        title: String,
        selectedType: Binding<TransactionType>,
        amount: Binding<String>,
        merchant: Binding<String>,
        selectedCategory: Binding<String>,
        selectedGroupId: Binding<String?>,
        notes: Binding<String>,
        date: Binding<Date>,
        isLoading: Bool,
        errorMessage: String?,
        authManager: AuthManager,
        onClose: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.title = title
        _selectedType = selectedType
        _amount = amount
        _merchant = merchant
        _selectedCategory = selectedCategory
        _selectedGroupId = selectedGroupId
        _notes = notes
        _date = date
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.authManager = authManager
        self.onClose = onClose
        self.onSave = onSave
        _categoryManager = StateObject(wrappedValue: CategoryManager(authManager: authManager))
        _groupManager = StateObject(wrappedValue: ExpenseGroupManager(authManager: authManager))
    }

    private var filteredCategories: [Category] {
        categoryManager.categories.filter { $0.type == selectedType }
    }

    private var groupChipItems: [GroupChipItem] {
        let matching = groupManager.groups.filter { $0.type == selectedType }
        return [GroupChipItem(id: "misc", groupId: nil, name: "Miscellaneous")]
            + matching.map { GroupChipItem(id: $0.id, groupId: $0.id, name: $0.name) }
    }

    private var canSave: Bool {
        !selectedCategory.isEmpty
            && !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (Double(amount) ?? 0) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(Theme.Font.ui(17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Theme.pillBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FieldLabel("Type")
                    TypeSelector(selected: $selectedType)

                    FieldLabel("Category")
                    if filteredCategories.isEmpty {
                        Text(categoryManager.isLoading ? "Loading categories…" : "No categories yet for this type")
                            .font(Theme.Font.ui(12))
                            .foregroundColor(Theme.textTertiary)
                    } else {
                        ChipFlowGrid(items: filteredCategories) { category in
                            ChipButton(
                                label: category.name,
                                isSelected: category.name == selectedCategory,
                                action: { selectedCategory = category.name }
                            )
                        }
                    }

                    FieldLabel("Merchant")
                    TextField("e.g. Coffee Shop", text: $merchant)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))

                    FieldLabel("Amount")
                    HStack(spacing: 6) {
                        Text("₹")
                            .foregroundColor(Theme.textSecondary)
                            .font(Theme.Font.mono(15))
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(Theme.Font.mono(15))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))

                    FieldLabel("Date")
                    HStack {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))

                    FieldLabel("Notes")
                    TextField("Optional notes", text: $notes)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))

                    FieldLabel("Assign to group")
                    ChipFlowGrid(items: groupChipItems) { item in
                        ChipButton(
                            label: item.name,
                            isSelected: item.groupId == selectedGroupId,
                            action: { selectedGroupId = item.groupId }
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.Font.ui(12))
                            .foregroundColor(.red)
                    }

                    Button(action: onSave) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save transaction")
                                    .font(Theme.Font.ui(15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canSave ? Theme.primary : Theme.primary.opacity(0.4))
                        .cornerRadius(Theme.controlRadius)
                    }
                    .disabled(!canSave || isLoading)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .onAppear {
            categoryManager.fetchCategories(userID: authManager.userId)
            groupManager.fetchGroups(userID: authManager.userId)
        }
        .onChange(of: selectedType) { _, _ in
            // Mirrors the mockup's setAddType (line 899): switching type
            // invalidates the previously selected category/group since both
            // are scoped to the old type.
            selectedCategory = ""
            selectedGroupId = nil
        }
    }
}

private struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(Theme.Font.ui(12, weight: .semibold))
            .foregroundColor(Theme.textSecondary)
    }
}

/// Segmented pill control for Expense/Credit/Investment, styled after the
/// mockup's `pillBtn` style function (line 1083): #EDEFF3 pill container,
/// active segment gets a white background + subtle shadow, inactive
/// segments are transparent with muted text.
private struct TypeSelector: View {
    @Binding var selected: TransactionType

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TransactionType.allCases) { type in
                let isActive = type == selected
                Button(action: { selected = type }) {
                    Text(type.label)
                        .font(Theme.Font.ui(12, weight: .semibold))
                        .foregroundColor(isActive ? Theme.textPrimary : Color(hex: "#7585A0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(isActive ? Color.white : Color.clear)
                        .clipShape(Capsule())
                        .shadow(color: isActive ? Color.black.opacity(0.12) : .clear, radius: 3, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Theme.pillBackground)
        .clipShape(Capsule())
    }
}

/// A selectable chip, styled after the mockup's `chipStyle` function
/// (line 1163): active gets a blue border/tint/text, inactive is a plain
/// gray-bordered pill. Used for both category and group chips — the mockup
/// applies the exact same style function to both (lines 1164, 1166).
private struct ChipButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Font.ui(12, weight: .semibold))
                .foregroundColor(isSelected ? Color(hex: "#2A4CC5") : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#E3E8FC") : Theme.surface)
                .overlay(Capsule().stroke(isSelected ? Theme.primary : Theme.border, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Wraps chips left-to-right, multiple per row, sized to their own content
/// — the closest native SwiftUI equivalent of the mockup's
/// `flex-wrap:wrap` chip rows (lines 571, 587) without a custom layout.
private struct ChipFlowGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

private struct GroupChipItem: Identifiable {
    let id: String
    /// The real `expense_groups.id` to assign, or nil for "Miscellaneous"
    /// (design/mockups/Expense Tracker.dc.html line 1166).
    let groupId: String?
    let name: String
}
