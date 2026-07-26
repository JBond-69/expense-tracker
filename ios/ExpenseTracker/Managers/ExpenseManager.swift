import Foundation
import Combine

class ExpenseManager: NSObject, ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let supabaseURL = "https://xpxngigfadfwypbawlbo.supabase.co"
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhweG5naWdmYWRmd3lwYmF3bGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzMzMzgsImV4cCI6MjEwMDY0OTMzOH0.HmvmC1fO0GmGpiCBNwjcvMuoJAAkPhcqNYM2n9a3xTw"

    func fetchExpenses(userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses?user_id=eq.\(userID)&order=date.desc"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to fetch expenses: \(error.localizedDescription)"
                } else if let data = data {
                    do {
                        self.expenses = try JSONDecoder().decode([Expense].self, from: data)
                    } catch {
                        self.errorMessage = "Failed to decode expenses: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }

    func addExpense(_ expense: Expense, userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        do {
            request.httpBody = try JSONEncoder().encode(expense)
        } catch {
            errorMessage = "Failed to encode expense"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to add expense: \(error.localizedDescription)"
                } else {
                    self.fetchExpenses(userID: userID)
                }
            }
        }.resume()
    }

    func updateExpense(_ expense: Expense, userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expenses?id=eq.\(expense.id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        do {
            request.httpBody = try JSONEncoder().encode(expense)
        } catch {
            errorMessage = "Failed to encode expense"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update expense: \(error.localizedDescription)"
                } else {
                    self.fetchExpenses(userID: userID)
                }
            }
        }.resume()
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

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to delete expense: \(error.localizedDescription)"
                } else {
                    self.fetchExpenses(userID: userID)
                }
            }
        }.resume()
    }
}
