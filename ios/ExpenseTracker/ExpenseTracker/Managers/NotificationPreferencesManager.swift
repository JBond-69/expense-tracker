import Foundation
import Combine

/// `notification_preferences` is one row per user (user_id is the primary
/// key), so writes are an upsert rather than separate insert/update paths.
class NotificationPreferencesManager: SupabaseManager {
    @Published var preferences: NotificationPreferences?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchPreferences(userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/notification_preferences?user_id=eq.\(userID)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "GET", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to fetch notification preferences: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                if let data = data {
                    do {
                        self.preferences = try JSONDecoder().decode([NotificationPreferences].self, from: data).first
                    } catch {
                        self.errorMessage = "Failed to decode notification preferences: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func upsertPreferences(_ preferences: NotificationPreferences, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/notification_preferences?on_conflict=user_id"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONEncoder().encode(preferences) else {
            errorMessage = "Failed to encode notification preferences"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "POST", body: body, prefer: "resolution=merge-duplicates,return=representation") { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to save notification preferences: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.preferences = preferences
                completion(true)
            }
        }
    }
}
