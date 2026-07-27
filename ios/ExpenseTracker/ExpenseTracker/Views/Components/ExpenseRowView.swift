import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    private var category: ExpenseCategory { ExpenseCategory(rawValue: expense.category) ?? .other }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.symbolName)
                .font(.system(size: 16))
                .foregroundColor(category.tint.fg)
                .frame(width: 40, height: 40)
                .background(category.tint.bg)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(Theme.Font.ui(15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(category.rawValue)
                    .font(Theme.Font.ui(13))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(expense.amount, specifier: "%.2f")")
                    .font(Theme.Font.mono(15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(expense.date)
                    .font(Theme.Font.ui(12))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(14)
    }
}

/// Preserves the existing swipe-to-delete interaction (native List .onDelete
/// behavior) while letting rows live in a plain ScrollView/VStack so they can
/// be styled as cards instead of default List rows.
private struct SwipeToDeleteModifier: ViewModifier {
    let action: () -> Void
    @State private var offset: CGFloat = 0
    @State private var revealed = false

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: action) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
            }
            .opacity(revealed ? 1 : 0)

            content
                .background(Theme.surface)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard value.translation.width < 0 else { return }
                            offset = max(value.translation.width, -70)
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if value.translation.width < -35 {
                                    offset = -70
                                    revealed = true
                                } else {
                                    offset = 0
                                    revealed = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}

extension View {
    func swipeToDelete(action: @escaping () -> Void) -> some View {
        modifier(SwipeToDeleteModifier(action: action))
    }
}
