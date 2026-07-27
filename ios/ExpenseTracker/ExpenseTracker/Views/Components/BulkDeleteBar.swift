import SwiftUI
import UIKit

/// Floating bar shown when one or more rows are multi-selected (design/
/// mockups/Expense Tracker.dc.html `bulkBarVisible`, lines 514-519).
struct BulkDeleteBar: View {
    let count: Int
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("\(count) selected")
                .font(Theme.Font.ui(13, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button(action: onDelete) {
                Text("Delete")
                    .font(Theme.Font.ui(13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.expenseFg)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Theme.textPrimary)
        .cornerRadius(14)
        .shadow(color: Theme.textPrimary.opacity(0.3), radius: 14, x: 0, y: 8)
        .padding(.horizontal, 16)
    }
}

/// Confirmation sheet before a bulk delete actually runs (design/mockups/
/// Expense Tracker.dc.html `confirmDelete`, lines 521-530).
struct BulkDeleteConfirmation {
    let ids: [String]
    let count: Int
    let totalFmt: String
}

struct DeleteConfirmationDialog: View {
    let confirmation: BulkDeleteConfirmation
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var plural: String { confirmation.count > 1 ? "s" : "" }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text("Delete \(confirmation.count) transaction\(plural)?")
                        .font(Theme.Font.ui(17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.bottom, 10)

                    Text("This removes \(confirmation.count) transaction\(plural) totaling \(confirmation.totalFmt). This can't be undone.")
                        .font(Theme.Font.ui(13))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.bottom, 20)

                    HStack(spacing: 10) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(Theme.Font.ui(14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(Theme.controlRadius)
                        }

                        Button(action: onConfirm) {
                            Text("Delete")
                                .font(Theme.Font.ui(14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Theme.expenseFg)
                                .cornerRadius(Theme.controlRadius)
                        }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 28, trailing: 20))
                .background(Theme.surface)
                .cornerRadius(Theme.sheetRadius, corners: [.topLeft, .topRight])
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
