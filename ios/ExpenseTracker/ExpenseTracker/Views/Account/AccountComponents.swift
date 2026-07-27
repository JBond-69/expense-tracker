import SwiftUI

/// Shared pieces reused across the Account root screen and its five
/// sub-pages (design/mockups/Expense Tracker.dc.html lines 290-509), so each
/// sub-page file only needs its own list/form content.

/// Root-screen nav row (Recurring groups / Connected accounts / Categories /
/// Export / Notifications), line 302-341 of the mockup.
struct AccountNavRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 34, height: 34)
                .background(Color(hex: "#F1F4FE"))
                .cornerRadius(9)

            Text(title)
                .font(Theme.Font.ui(14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(value)
                .font(Theme.Font.ui(12))
                .foregroundColor(Theme.textTertiary)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.border, lineWidth: 1))
        .cornerRadius(Theme.cardRadius)
    }
}

/// Custom circular back button + title used by every sub-page instead of the
/// system nav bar, matching the mockup's `closeSub`/`closeGroupDetail`
/// buttons (e.g. line 350-353) and this app's existing convention of hiding
/// the native nav bar (see HomeView/IgnoredView).
struct AccountSubHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                    .clipShape(Circle())
            }
            Text(title)
                .font(Theme.Font.ui(18, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

/// Dashed "add new" row (New group / Add Google account), line 367-370.
struct AccountAddRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(label)
                    .font(Theme.Font.ui(13, weight: .semibold))
            }
            .foregroundColor(Theme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#F1F4FE"))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .strokeBorder(Color(hex: "#BECFF6"), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .cornerRadius(Theme.cardRadius)
        }
        .buttonStyle(.plain)
    }
}

/// Pill-shaped segmented control matching the mockup's tab styling (e.g.
/// line 444-448) — the native `.segmented` Picker style renders as a
/// system-blue control that doesn't match this design system at all.
struct PillSegmentedControl<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                Button(action: { selection = option.value }) {
                    Text(option.label)
                        .font(Theme.Font.ui(12, weight: .semibold))
                        .foregroundColor(selection == option.value ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(selection == option.value ? Theme.surface : Color.clear)
                        .cornerRadius(999)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Theme.pillBackground)
        .cornerRadius(999)
    }
}

/// Small rounded status/type badge (e.g. "Recurring", "Connected"), line 387-388.
struct PillBadge: View {
    let text: String
    let fg: Color
    let bg: Color

    var body: some View {
        Text(text)
            .font(Theme.Font.ui(11, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(bg)
            .cornerRadius(999)
    }
}

/// Wrapping chip row (category chips, export range chips) — SwiftUI's
/// `HStack` doesn't wrap, and the mockup's chip rows (line 449-453, 469-473)
/// need to flow onto multiple lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let totalHeight = y + rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Wraps `UIActivityViewController` so Export can hand the generated CSV to
/// the native share sheet (Mail, Files, AirDrop, etc.) instead of the
/// mockup's browser-download `runExport` action — there's no browser here.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
