import Foundation
import Combine

class AuthManager: NSObject, ObservableObject {
    @Published var isLoggedIn = false
    @Published var userEmail = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    let supabaseURL = "https://xpxngigfadfwypbawlbo.supabase.co"
    let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhweG5naWdmYWRmd3lwYmF3bGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzMzMzgsImV4cCI6MjEwMDY0OTMzOH0.HmvmC1fO0GmGpiCBNwjcvMuoJAAkPhcqNYM2n9a3xTw"

    override init() {
        super.init()
        checkAuthStatus()
    }

    func checkAuthStatus() {
        if let savedEmail = UserDefaults.standard.string(forKey: "userEmail") {
            self.userEmail = savedEmail
            self.isLoggedIn = true
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

        let body: [String: String] = ["email": email, "token": token, "type": "otp"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to verify OTP: \(error.localizedDescription)"
                } else if let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          json["access_token"] != nil {
                    self.userEmail = email
                    self.isLoggedIn = true
                    UserDefaults.standard.set(email, forKey: "userEmail")
                } else {
                    self.errorMessage = "Invalid OTP"
                }
            }
        }.resume()
    }

    func logout() {
        isLoggedIn = false
        userEmail = ""
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}
