import Foundation
import Combine

class AuthManager: NSObject, ObservableObject {
    @Published var isLoggedIn = false
    @Published var userEmail = ""
    /// Real Supabase auth UUID from a verified OTP session. The `expenses`
    /// table's user_id column is UUID, so this — never the raw email — is
    /// what gets sent to Supabase.
    @Published var userId = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// The live session access token. Attached as the Authorization bearer
    /// header on every authenticated request — RLS checks auth.uid() against
    /// this, not against the apikey header.
    private(set) var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Date?

    let supabaseURL = "https://xpxngigfadfwypbawlbo.supabase.co"
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhweG5naWdmYWRmd3lwYmF3bGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzMzMzgsImV4cCI6MjEwMDY0OTMzOH0.HmvmC1fO0GmGpiCBNwjcvMuoJAAkPhcqNYM2n9a3xTw"

    private let accessTokenKey = "supabase_access_token"
    private let refreshTokenKey = "supabase_refresh_token"

    override init() {
        super.init()
        checkAuthStatus()
    }

    func checkAuthStatus() {
        guard
            let savedEmail = UserDefaults.standard.string(forKey: "userEmail"),
            let savedUserId = UserDefaults.standard.string(forKey: "userId"),
            let token = Keychain.get(accessTokenKey)
        else { return }

        userEmail = savedEmail
        userId = savedUserId
        accessToken = token
        refreshToken = Keychain.get(refreshTokenKey)
        expiresAt = UserDefaults.standard.object(forKey: "tokenExpiresAt") as? Date
        isLoggedIn = true

        if let expiresAt, expiresAt <= Date() {
            refreshSession { _ in }
        }
    }

    func signUpWithOTP(email: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/auth/v1/otp"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["email": email, "data": "{}"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to send OTP: \(error.localizedDescription)"
                } else {
                    self.userEmail = email
                }
            }
        }.resume()
    }

    func verifyOTP(email: String, token: String) {
        isLoading = true
        errorMessage = nil

        let urlString = "\(supabaseURL)/auth/v1/verify"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["email": email, "token": token, "type": "email"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to verify OTP: \(error.localizedDescription)"
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.errorMessage = "Invalid OTP"
                    return
                }
                guard let accessToken = json["access_token"] as? String,
                      let user = json["user"] as? [String: Any],
                      let realUserId = user["id"] as? String else {
                    self.errorMessage = (json["error_description"] as? String) ?? (json["msg"] as? String) ?? "Invalid OTP"
                    return
                }
                self.applySession(
                    accessToken: accessToken,
                    refreshToken: json["refresh_token"] as? String,
                    expiresIn: json["expires_in"] as? Double,
                    email: email,
                    userId: realUserId
                )
            }
        }.resume()
    }

    /// Entry point for the Google OAuth login path — same session shape as OTP,
    /// so the rest of the app (Home, Insights, etc.) needs no changes.
    func applyGoogleSession(accessToken: String, refreshToken: String?, expiresIn: Double?, email: String, userId: String) {
        isLoading = false
        errorMessage = nil
        applySession(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn, email: email, userId: userId)
    }

    private func applySession(accessToken: String, refreshToken: String?, expiresIn: Double?, email: String, userId: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = Date().addingTimeInterval(expiresIn ?? 3600)
        self.userEmail = email
        self.userId = userId
        self.isLoggedIn = true

        Keychain.set(accessToken, for: accessTokenKey)
        if let refreshToken {
            Keychain.set(refreshToken, for: refreshTokenKey)
        }
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(self.expiresAt, forKey: "tokenExpiresAt")
    }

    /// Exchanges the stored refresh token for a new access token. Called
    /// proactively on launch if the saved session has expired, and
    /// reactively by ExpenseManager on a 401 before it gives up.
    func refreshSession(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = refreshToken ?? Keychain.get(refreshTokenKey) else {
            completion(false)
            return
        }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let newAccessToken = json["access_token"] as? String,
                      let user = json["user"] as? [String: Any],
                      let userId = user["id"] as? String else {
                    self.logout()
                    completion(false)
                    return
                }
                self.applySession(
                    accessToken: newAccessToken,
                    refreshToken: json["refresh_token"] as? String ?? refreshToken,
                    expiresIn: json["expires_in"] as? Double,
                    email: self.userEmail,
                    userId: userId
                )
                completion(true)
            }
        }.resume()
    }

    func logout() {
        isLoggedIn = false
        userEmail = ""
        userId = ""
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "tokenExpiresAt")
        Keychain.delete(accessTokenKey)
        Keychain.delete(refreshTokenKey)
    }
}
