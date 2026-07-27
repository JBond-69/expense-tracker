import Foundation
import Combine

class ExpenseManager: NSObject, ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authManager: AuthManager

    let supabaseURL = "https://xpxngigfadfwypbawlbo.supabase.co"
    /// Anon/publishable key — identifies the project via the `apikey`
    /// header. Never used as the bearer token: RLS checks auth.uid() against
    /// the *user's* access token, which comes from authManager.
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhweG5naWdmYWRmd3lwYmF3bGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzMzMzgsImV4cCI6MjEwMDY0OTMzOH0.HmvmC1fO0GmGpiCBNwjcvMuoJAAkPhcqNYM2n9a3xTw"

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    private func authorizedRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authManager.accessToken ?? supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        return request
    }

    /// Surfaces the real Supabase error body instead of silently treating
    /// any non-network-error response as success.
    private func checkResponse(_ data: Data?, _ response: URLResponse?) -> String? {
        guard let http = response as? HTTPURLResponse else { return nil }
        guard !(200...299).contains(http.statusCode) else { return nil }
        if let data = data, let body = String(data: data, encoding: .utf8), !body.isEmpty {
            return "Supabase error \(http.statusCode): \(body)"
        }
        return "Supabase error \(http.statusCode)"
    }

    /// Runs an authorized request; on a 401 (expired access token) refreshes
    /// the session once and retries before giving up.
    private func performRequest(
        url: URL,
        method: String,
        body: Data?,
        retrying: Bool = false,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        var request = authorizedRequest(url: url, method: method)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if !retrying, let http = response as? HTTPURLResponse, http.statusCode == 401 {
                self.authManager.refreshSession { refreshed in
                    if refreshed {
                        self.performRequest(url: url, method: method, body: body, retrying: true, completion: completion)
                    } else {
                        completion(data, response, error)
                    }
                }
            } else {
                completion(data, response, error)
            }
        }.resume()
    }

    func fetchExpenses(userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses?user_id=eq.\(userID)&order=date.desc"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "GET", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to fetch expenses: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                if let data = data {
                    do {
                        self.expenses = try JSONDecoder().decode([Expense].self, from: data)
                    } catch {
                        self.errorMessage = "Failed to decode expenses: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func addExpense(_ expense: Expense, userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONEncoder().encode(expense) else {
            errorMessage = "Failed to encode expense"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "POST", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to add expense: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchExpenses(userID: userID)
                completion(true)
            }
        }
    }

    func updateExpense(_ expense: Expense, userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses?id=eq.\(expense.id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONEncoder().encode(expense) else {
            errorMessage = "Failed to encode expense"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "PATCH", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update expense: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchExpenses(userID: userID)
                completion(true)
            }
        }
    }

    func deleteExpense(id: String, userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses?id=eq.\(id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "DELETE", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to delete expense: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                self.fetchExpenses(userID: userID)
            }
        }
    }
}
