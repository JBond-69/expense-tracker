import SwiftUI

/// Phase 1 explicitly excludes Insights/Account functionality — this stub
/// exists only so the 4-tab bar the design calls for isn't broken.
struct StubTabView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(Theme.textTertiary)
                Text(message)
                    .font(Theme.Font.ui(14))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle(title)
        }
    }
}
