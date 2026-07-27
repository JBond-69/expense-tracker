import SwiftUI

/// Shared bottom-sheet form used by both Add and Edit, styled after the
/// showAddSheet block in design/mockups/Expense Tracker.dc.html (rounded
/// card, chip-style category picker, ₹-prefixed amount field) combined with
/// the richer Category Pill spec from design/ui_kit/components.md.
struct ExpenseFormSheet: View {
    let title: String
    @Binding var amount: String
    @Binding var merchant: String
    @Binding var selectedCategory: ExpenseCategory
    @Binding var notes: String
    @Binding var date: Date
    let isLoading: Bool
    let errorMessage: String?
    let onClose: () -> Void
    let onSave: () -> Void

    private var canSave: Bool { !merchant.isEmpty && !amount.isEmpty }

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
                    FieldLabel("Category")
                    CategoryChipGrid(selected: $selectedCategory)

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
                                Text("Save")
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

private struct CategoryChipGrid: View {
    @Binding var selected: ExpenseCategory
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(ExpenseCategory.allCases) { category in
                let isSelected = category == selected
                Button(action: { selected = category }) {
                    VStack(spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: category.symbolName)
                                .font(.system(size: 18))
                                .foregroundColor(category.tint.fg)
                                .frame(width: 44, height: 44)
                                .background(category.tint.bg)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? category.tint.fg : .clear, lineWidth: 2)
                                )
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(category.tint.fg)
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 4, y: -4)
                            }
                        }
                        Text(category.rawValue)
                            .font(Theme.Font.ui(11, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
