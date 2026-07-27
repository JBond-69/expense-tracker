import Foundation
import Combine

class ExpenseManager: SupabaseManager {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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

    /// Deletes multiple expenses in a single PostgREST request (`id=in.(...)`)
    /// instead of one DELETE per row, so a bulk-select delete from the Home
    /// detail view doesn't fire N sequential requests/refetches.
    func deleteExpenses(ids: [String], userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard !ids.isEmpty else {
            completion(true)
            return
        }
        isLoading = true
        errorMessage = nil

        let idList = ids.joined(separator: ",")
        let urlString = "\(supabaseURL)/rest/v1/expenses?id=in.(\(idList))"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "DELETE", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to delete expenses: \(error.localizedDescription)"
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
