import Foundation
import Combine

class ConnectedAccountManager: SupabaseManager {
    @Published var accounts: [ConnectedAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchAccounts(userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/connected_accounts?user_id=eq.\(userID)&order=created_at.asc"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "GET", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to fetch connected accounts: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                if let data = data {
                    do {
                        self.accounts = try JSONDecoder().decode([ConnectedAccount].self, from: data)
                    } catch {
                        self.errorMessage = "Failed to decode connected accounts: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Inserts a connected-account row (status only — the OAuth token
    /// exchange itself happens server-side, see ConnectedAccount.swift).
    func addAccount(email: String, provider: String = "gmail", status: String = "connected", userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/connected_accounts"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONSerialization.data(withJSONObject: [
            "user_id": userID, "email": email, "provider": provider, "status": status
        ]) else {
            errorMessage = "Failed to encode connected account"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "POST", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to add connected account: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchAccounts(userID: userID)
                completion(true)
            }
        }
    }

    func updateStatus(id: String, status: String, userID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/connected_accounts?id=eq.\(id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            completion(false)
            return
        }

        guard let body = try? JSONSerialization.data(withJSONObject: ["status": status]) else {
            errorMessage = "Failed to encode status"
            isLoading = false
            completion(false)
            return
        }

        performRequest(url: url, method: "PATCH", body: body) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update connected account: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    completion(false)
                    return
                }
                self.fetchAccounts(userID: userID)
                completion(true)
            }
        }
    }

    func deleteAccount(id: String, userID: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/rest/v1/connected_accounts?id=eq.\(id)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        performRequest(url: url, method: "DELETE", body: nil) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to delete connected account: \(error.localizedDescription)"
                    return
                }
                if let httpError = self.checkResponse(data, response) {
                    self.errorMessage = httpError
                    return
                }
                self.fetchAccounts(userID: userID)
            }
        }
    }
}
