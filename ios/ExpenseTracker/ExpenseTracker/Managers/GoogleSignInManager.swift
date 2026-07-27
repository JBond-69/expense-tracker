import Foundation
import AuthenticationServices
import CryptoKit

/// Real Gmail OAuth (client-only, no backend yet — token exchange normally
/// belongs server-side per Phase 3, but the installed-app/PKCE flow is a
/// public client by design, so this is a legitimate way to prove the
/// connection now). Fill in `clientID` from Google Cloud Console
/// (Credentials → OAuth client ID → iOS, bundle ID Tally.ExpenseTracker).
enum GoogleOAuthConfig {
    static let clientID = "203285563022-h5oelo4g5ruusv4j4gpcnh0sc05cgrq4.apps.googleusercontent.com"

    /// Google's convention for installed-app redirect URIs: the client ID
    /// with the ".apps.googleusercontent.com" suffix stripped, reversed into
    /// a custom URL scheme. ASWebAuthenticationSession intercepts this
    /// redirect itself — no CFBundleURLTypes registration needed.
    static var redirectURI: String {
        let prefix = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        return "com.googleusercontent.apps.\(prefix):/oauth2redirect"
    }

    static let scope = "openid email https://www.googleapis.com/auth/gmail.readonly"
}

struct GoogleAccount {
    let email: String
}

enum GoogleSignInError: Error {
    case cancelled
    case invalidCallback
    case tokenExchangeFailed
    case userInfoFailed
}

final class GoogleSignInManager: NSObject {
    private var session: ASWebAuthenticationSession?
    private var codeVerifier = ""

    func signIn(completion: @escaping (Result<GoogleAccount, Error>) -> Void) {
        codeVerifier = Self.randomURLSafeString(length: 64)
        let codeChallenge = Self.codeChallenge(for: codeVerifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: GoogleOAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: GoogleOAuthConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: GoogleOAuthConfig.scope),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "consent"),
        ]

        guard let authURL = components.url,
              let callbackScheme = URL(string: GoogleOAuthConfig.redirectURI)?.scheme else {
            completion(.failure(GoogleSignInError.invalidCallback))
            return
        }

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
            guard let self else { return }
            if let error {
                completion(.failure(error))
                return
            }
            guard let callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                completion(.failure(GoogleSignInError.invalidCallback))
                return
            }
            self.exchangeCodeForToken(code: code, completion: completion)
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        self.session = session
        session.start()
    }

    private func exchangeCodeForToken(code: String, completion: @escaping (Result<GoogleAccount, Error>) -> Void) {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            completion(.failure(GoogleSignInError.tokenExchangeFailed))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "code": code,
            "client_id": GoogleOAuthConfig.clientID,
            "redirect_uri": GoogleOAuthConfig.redirectURI,
            "grant_type": "authorization_code",
            "code_verifier": codeVerifier,
        ]
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self,
                  error == nil,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                DispatchQueue.main.async { completion(.failure(GoogleSignInError.tokenExchangeFailed)) }
                return
            }
            self.fetchUserInfo(accessToken: accessToken, completion: completion)
        }.resume()
    }

    private func fetchUserInfo(accessToken: String, completion: @escaping (Result<GoogleAccount, Error>) -> Void) {
        guard let url = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo") else {
            DispatchQueue.main.async { completion(.failure(GoogleSignInError.userInfoFailed)) }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let email = json["email"] as? String else {
                    completion(.failure(GoogleSignInError.userInfoFailed))
                    return
                }
                completion(.success(GoogleAccount(email: email)))
            }
        }.resume()
    }

    private static func randomURLSafeString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func codeChallenge(for verifier: String) -> String {
        let hashed = SHA256.hash(data: Data(verifier.utf8))
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension GoogleSignInManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}

struct SupabaseGoogleSession {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Double?
    let userId: String
    let email: String
}

/// Real login path: Supabase does the Google OAuth exchange server-side
/// (Auth → Providers → Google), so this app only needs to open Supabase's
/// `/authorize` endpoint and read the tokens off the redirect it sends back
/// — no Google client ID/secret involved on-device.
extension GoogleSignInManager {
    func signInWithSupabase(supabaseURL: String, supabaseKey: String, completion: @escaping (Result<SupabaseGoogleSession, Error>) -> Void) {
        let redirectScheme = "tally"
        var components = URLComponents(string: "\(supabaseURL)/auth/v1/authorize")!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: "\(redirectScheme)://login-callback"),
        ]
        guard let authURL = components.url else {
            completion(.failure(GoogleSignInError.invalidCallback))
            return
        }

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: redirectScheme) { [weak self] callbackURL, error in
            guard let self else { return }
            if let error {
                completion(.failure(error))
                return
            }
            guard let callbackURL,
                  let fragment = callbackURL.fragment,
                  let accessToken = Self.fragmentValue(for: "access_token", in: fragment) else {
                completion(.failure(GoogleSignInError.invalidCallback))
                return
            }
            let refreshToken = Self.fragmentValue(for: "refresh_token", in: fragment)
            let expiresIn = Self.fragmentValue(for: "expires_in", in: fragment).flatMap(Double.init)
            self.fetchSupabaseUser(supabaseURL: supabaseURL, supabaseKey: supabaseKey, accessToken: accessToken) { result in
                switch result {
                case .success(let (userId, email)):
                    completion(.success(SupabaseGoogleSession(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn, userId: userId, email: email)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        self.session = session
        session.start()
    }

    private func fetchSupabaseUser(supabaseURL: String, supabaseKey: String, accessToken: String, completion: @escaping (Result<(String, String), Error>) -> Void) {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else {
            completion(.failure(GoogleSignInError.userInfoFailed))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userId = json["id"] as? String,
                  let email = json["email"] as? String else {
                DispatchQueue.main.async { completion(.failure(GoogleSignInError.userInfoFailed)) }
                return
            }
            DispatchQueue.main.async { completion(.success((userId, email))) }
        }.resume()
    }

    private static func fragmentValue(for key: String, in fragment: String) -> String? {
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2, parts[0] == Substring(key) else { continue }
            return parts[1].removingPercentEncoding
        }
        return nil
    }
}
