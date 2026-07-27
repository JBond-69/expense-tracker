import Foundation
import Combine

class ExpenseGroupManager: SupabaseManager {
    @Published var groups: [ExpenseGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchGroups(userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expense_groups?user_id=eq.\(userID)&order=created_at.desc"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "GET", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                if let data = data {
                    do {
                        self.groups = try JSONDecoder().decode([ExpenseGroup].self, from: data)
                    } catch {
                        self.errorMessage = "Failed to decode groups: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func addGroup(_ group: ExpenseGroup, userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expense_groups"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONEncoder().encode(group) else {
            errorMessage = "Failed to encode group"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "POST", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to add group: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchGroups(userID: userID)
                completion(true)
            }
        }
    }

    func updateGroup(_ group: ExpenseGroup, userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expense_groups?id=eq.\(group.id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONEncoder().encode(group) else {
            errorMessage = "Failed to encode group"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "PATCH", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update group: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchGroups(userID: userID)
                completion(true)
            }
        }
    }

    func deleteGroup(id: String, userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/expense_groups?id=eq.\(id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "DELETE", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to delete group: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                self.fetchGroups(userID: userID)
            }
        }
    }
}
