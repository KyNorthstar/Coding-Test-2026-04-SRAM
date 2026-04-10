//
//  StravaOAuthService.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky directing Claude on 2026-04-10.
//

import AuthenticationServices
import Combine
import Foundation

import CollectionTools



/// Manages the full Strava OAuth 2.0 lifecycle: authorization, code exchange, and silent refresh.
///
/// Instantiate once in `AppContainer` and inject as an environment object. The session
/// is persisted in the Keychain so users only authenticate once. Token refresh is
/// transparent — callers only interact with `validAccessToken()`, which handles expiry
/// silently. The 60-second buffer before expiry prevents clock-skew failures.
///
/// Usage:
/// ```swift
/// try await oauthService.authorize()          // shows browser sheet
/// let token = try await oauthService.validAccessToken() // never stale
/// try oauthService.signOut()
/// ```
@MainActor
final class StravaOAuthService: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Reactive auth gate — observe this to conditionally show `AuthView` vs. `MainTabView`.
    @Published private(set) var isAuthenticated = false
    
    
    
    // MARK: Stored Session
    
    private var accessToken:  String?
    private var refreshToken: String?
    private var expiresAt:    Date?
    
    /// Holds a strong reference to the active auth session to prevent premature deallocation.
    /// Nilled out on completion or cancellation.
    private var authSession: ASWebAuthenticationSession?
    
    
    // MARK: Init
    
    override init() {
        super.init()
        restorePersistedSession()
    }
}



// MARK: - Public Interface

extension StravaOAuthService {
    
    /// Presents the Strava authorization URL in an `ASWebAuthenticationSession` browser sheet,
    /// then exchanges the returned code for access + refresh tokens.
    ///
    /// On success, tokens are written to the Keychain and `isAuthenticated` flips to `true`.
    /// The caller is responsible for handling `OAuthError` and surfacing it to the user.
    func authorize() async throws {
        let code   = try await presentAuthSession()
        let tokens = try await exchange(code: code)
        persist(tokens)
        isAuthenticated = true
    }
    
    
    /// Returns a guaranteed-fresh access token, performing a silent refresh if within
    /// the 60-second expiry buffer. Throws `OAuthError.notAuthenticated` when no session exists.
    func validAccessToken() async throws -> String {
        if let expiry = expiresAt,
           expiry > Date.now.addingTimeInterval(60),
           let token = accessToken {
            return token
        }
        else {
            guard let refresh = refreshToken else { throw OAuthError.notAuthenticated }
            let tokens = try await performRefresh(using: refresh)
            persist(tokens)
            return tokens.accessToken
        }
    }
    
    
    /// Purges all stored credentials from the Keychain and resets session state.
    func signOut() throws {
        try Keychain.delete(forKey: Key.access)
        try Keychain.delete(forKey: Key.refresh)
        try Keychain.delete(forKey: Key.expiry)
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
        isAuthenticated = false
    }
}



// MARK: - Errors

extension StravaOAuthService {
    enum OAuthError: LocalizedError {
        case invalidCallback
        case notAuthenticated
        case tokenExchangeFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidCallback:              return "OAuth callback was invalid or missing a code"
            case .notAuthenticated:             return "No active session — call authorize() first"
            case .tokenExchangeFailed(let msg): return "Token exchange failed: \(msg)"
            }
        }
    }
}


// MARK: - Private

private extension StravaOAuthService {

    /// Presents the Strava authorization URL and resolves with the returned `code` parameter.
    ///
    /// Wraps `ASWebAuthenticationSession` in a checked continuation so callers participate
    /// naturally in Swift's structured concurrency. Task cancellation tears down the browser
    /// sheet cleanly via `withTaskCancellationHandler`.
    private func presentAuthSession() async throws -> String {
        var components = URLComponents(url: AppConfigValues.URLs.authorize,
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "client_id",       value: AppConfigValues.client?.id),
            .init(name: "redirect_uri",    value: AppConfigValues.redirectUri),
            .init(name: "response_type",   value: "code"),
            .init(name: "approval_prompt", value: "auto"),
            .init(name: "scope",           value: AppConfigValues.scope)
        ]

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let session = ASWebAuthenticationSession(
                    url: components.url!,
                    callbackURLScheme: "cadence"
                ) { [weak self] callbackURL, error in
                    defer { self?.authSession = nil }
                    if let error { continuation.resume(throwing: error); return }
                    guard
                        let url  = callbackURL,
                        let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                                        .queryItems?.first(where: { $0.name == "code" })?.value
                    else {
                        continuation.resume(throwing: OAuthError.invalidCallback); return
                    }
                    continuation.resume(returning: code)
                }
                session.prefersEphemeralWebBrowserSession = false
                session.presentationContextProvider = self
                session.start()
                authSession = session
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                self?.authSession?.cancel()
                self?.authSession = nil
            }
        }
    }
    
    
    private func exchange(code: String) async throws -> TokenResponse {
        var request = URLRequest(url: AppConfigValues.URLs.token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "client_id": AppConfigValues.clientId, "client_secret": AppConfigValues.clientSecret,
            "code": code, "grant_type": "authorization_code"
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
    
    
    private func performRefresh(using refresh: String) async throws -> TokenResponse {
        var request = URLRequest(url: AppConfigValues.URLs.token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "client_id": AppConfigValues.clientId, "client_secret": AppConfigValues.clientSecret,
            "refresh_token": refresh, "grant_type": "refresh_token"
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
    
    
    private func persist(_ tokens: TokenResponse) {
        accessToken  = tokens.accessToken
        refreshToken = tokens.refreshToken
        expiresAt    = Date(timeIntervalSince1970: TimeInterval(tokens.expiresAt))
        try? Keychain.save(tokens.accessToken,  forKey: Key.access)
        try? Keychain.save(tokens.refreshToken, forKey: Key.refresh)
        try? Keychain.save(String(tokens.expiresAt), forKey: Key.expiry)
    }
    
    
    /// Rehydrates an existing session from the Keychain on cold launch.
    private func restorePersistedSession() {
        guard
            let access  = try? Keychain.load(forKey: Key.access),
            let refresh = try? Keychain.load(forKey: Key.refresh),
            let expStr  = try? Keychain.load(forKey: Key.expiry),
            let expTS   = TimeInterval(expStr)
        else { return }
        accessToken  = access
        refreshToken = refresh
        expiresAt    = Date(timeIntervalSince1970: expTS)
        isAuthenticated = true
    }
}



// MARK: - Presentation Anchor

extension StravaOAuthService: ASWebAuthenticationPresentationContextProviding {
    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // `ASWebAuthenticationSession` always calls this on the main thread from a UI event, so the `UIApplication`
        // access here is safe despite the `nonisolated` annotation.
        
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        
        // Make sure we're at least operating in an environment where scenes have loaded
        guard let firstWindowScene = windowScenes.first else {
            return UIWindow() //deprecated: We don't have much of a choice here. The deprecation notice says that we
                              // should pass a window scene, but we've just confirmed there aren't any yet. Would
                              // return `nil`, but the `ASWebAuthenticationPresentationContextProviding` protocol
                              // requires we return _something_, and I ain't boutta crash the app just because there
                              // aren't yet any scenes. That's a recipe for a crash "loop".
        }
        
        // Find all the windows and put them all in one flat array
        let allWindows = windowScenes.flatMap { $0.windows }
        
        // Make sure there's at least one window
        guard let firstWindow = allWindows.first else {
            // Again, the protocol requires _something_ to be returned even if there's no windows for this app, might
            // as well return a dummy window in the most-reasonable scene.
            return UIWindow(windowScene: windowScenes.first { $0.isFirstResponder } ?? firstWindowScene)
        }
        
        return allWindows.first { $0.isKeyWindow }
//            ?? allWindows.first { $0.isFirstResponder }
//            ?? allWindows.first { $0.isFocused }
            ?? firstWindow
    }
}

// MARK: - TokenResponse

/// Wire-format model for Strava's token exchange and refresh responses.
private struct TokenResponse: Decodable {
    let accessToken:  String
    let refreshToken: String
    let expiresAt:    Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt    = "expires_at"
    }
}



// MARK: - Key

private extension StravaOAuthService {
    
    enum Key {
        static let access  = "strava_access_token"
        static let refresh = "strava_refresh_token"
        static let expiry  = "strava_token_expiry"
    }
}
