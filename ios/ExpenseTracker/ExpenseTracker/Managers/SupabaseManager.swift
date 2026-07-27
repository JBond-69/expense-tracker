import Foundation
import Combine

/// Shared REST plumbing for talking to Supabase as the signed-in user.
/// Every concrete manager (ExpenseManager, ExpenseGroupManager,
/// CategoryManager, ConnectedAccountManager, NotificationPreferencesManager)
/// subclasses this instead of re-implementing the same auth/retry logic.
class SupabaseManager: NSObject, ObservableObject {
    let authManager: AuthManager

    let supabaseURL = "https://xpxngigfadfwypbawlbo.supabase.co"
    /// Anon/publishable key — identifies the project via the `apikey`
    /// header. Never used as the bearer token: RLS checks auth.uid() against
    /// the *user's* access token, which comes from authManager.
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhweG5naWdmYWRmd3lwYmF3bGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzMzMzgsImV4cCI6MjEwMDY0OTMzOH0.HmvmC1fO0GmGpiCBNwjcvMuoJAAkPhcqNYM2n9a3xTw"

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func authorizedRequest(url: URL, method: String, prefer: String = "return=representation") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authManager.accessToken ?? supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue(prefer, forHTTPHeaderField: "Prefer")
        return request
    }

    /// Surfaces the real Supabase error body instead of silently treating
    /// any non-network-error response as success.
    func checkResponse(_ data: Data?, _ response: URLResponse?) -> String? {
        guard let http = response as? HTTPURLResponse else { return nil }
        guard !(200...299).contains(http.statusCode) else { return nil }
        if let data = data, let body = String(data: data, encoding: .utf8), !body.isEmpty {
            return "Supabase error \(http.statusCode): \(body)"
        }
        return "Supabase error \(http.statusCode)"
    }

    /// Runs an authorized request; on a 401 (expired access token) refreshes
    /// the session once and retries before giving up.
    func performRequest(
        url: URL,
        method: String,
        body: Data?,
        prefer: String = "return=representation",
        retrying: Bool = false,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        var request = authorizedRequest(url: url, method: method, prefer: prefer)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if !retrying, let http = response as? HTTPURLResponse, http.statusCode == 401 {
                self.authManager.refreshSession { refreshed in
                    if refreshed {
                        self.performRequest(url: url, method: method, body: body, prefer: prefer, retrying: true, completion: completion)
                    } else {
                        completion(data, response, error)
                    }
                }
            } else {
                completion(data, response, error)
            }
        }.resume()
    }
}
