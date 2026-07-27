import Foundation
import Combine

class CategoryManager: SupabaseManager {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchCategories(userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/categories?user_id=eq.\(userID)&order=type.asc,name.asc"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "GET", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                if let data = data {
                    do {
                        self.categories = try JSONDecoder().decode([Category].self, from: data)
                    } catch {
                        self.errorMessage = "Failed to decode categories: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Adds a custom category. `is_default` is always false here — the
    /// default set is seeded server-side (see the migration's
    /// `handle_new_user_categories` trigger), never created client-side.
    func addCategory(_ category: Category, userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/categories"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONEncoder().encode(category) else {
            errorMessage = "Failed to encode category"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "POST", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to add category: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchCategories(userID: userID)
                completion(true)
            }
        }
    }

    func deleteCategory(id: String, userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/categories?id=eq.\(id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "DELETE", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to delete category: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                self.fetchCategories(userID: userID)
            }
        }
    }
}
