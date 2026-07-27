import Foundation

/// A Gmail account connected for email-capture (design/mockups/
/// Expense Tracker.dc.html ACCOUNTS_SEED, line 756). OAuth token exchange is
/// server-side (Phase 3 Edge Function), so `access_token`/`refresh_token`
/// are intentionally not modeled here — the client only ever needs status.
struct ConnectedAccount: Identifiable, Codable {
    let id: String
    let userId: String
    let email: String
    let provider: String
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, provider, status
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
