//
//  StravaApiClient.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky directing Claude 4.6 Sonnet on 2026-04-10.
//

import Foundation



private let athleteActivitiesSubpath = "/athlete/activities"
private let activityQueryItem_earliestTimestamp = "after"
private let activityQueryItem_latestTimestamp   = "before"
private let activityQueryItem_pageNumber        = "page"
private let activityQueryItem_pageSize          = "per_page"



/// Thin authenticated HTTP client for the Strava v3 REST API.
///
/// All requests obtain a fresh token from `StravaOAuthService.validAccessToken()` before
/// firing — token refresh is completely transparent to callers. Pagination is handled
/// internally for activity fetches; callers always receive the complete flat dataset.
///
/// To extend: add new `func fetch…() async throws` methods mirroring this pattern.
final class StravaApiClient {
    
    private let auth: StravaOAuthService
    private let session: URLSession
    
    /// Decoder configured to match Strava's snake_case JSON and ISO8601 timestamps.
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy  = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    
    /// Initialized with a shared session by default for convenience,
    /// but accepts any `URLSession` to support testing against a mock transport.
    init(auth: StravaOAuthService, session: URLSession = .shared) {
        self.auth    = auth
        self.session = session
    }
}



// MARK: - Activities

extension StravaApiClient {
    
    /// Fetches all activities within the given window, transparently iterating Strava's
    /// 200-per-page limit until the response is exhausted.
    ///
    /// - Parameters:
    ///   - after:  Fetch activities starting after this date. Defaults to 52 weeks ago.
    ///   - before: Fetch activities ending before this date. Defaults to now.
    func fetchActivities(
        after:  Date = Calendar.current.date(byAdding: .weekOfYear, value: -52, to: .now)!,
        before: Date = .now)
    async throws(ActivityLoadError) -> [Activity] {
        var all: [Activity] = []
        var page = 1
        var batch: [Activity]
        
        repeat {
            defer { page += 1 }
            
            do {
                batch = try await get(
                    path: athleteActivitiesSubpath,
                    queryItems: [
                        .init(name: activityQueryItem_earliestTimestamp, value: String(Int(after.timeIntervalSince1970))),
                        .init(name: activityQueryItem_latestTimestamp,   value: String(Int(before.timeIntervalSince1970))),
                        .init(name: activityQueryItem_pageNumber,        value: String(page)),
                        .init(name: activityQueryItem_pageSize,          value: "200"),
                    ]
                )
            }
            catch {
                throw .networkError(error: error)
            }
            
            all.append(contentsOf: batch)
        } while batch.count >= 200
        
        return all
    }
}



enum ActivityLoadError: Error {
    case networkError(error: Error)
}



extension ActivityLoadError: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError), .networkError(let rhsError)):
            (lhsError as NSError) == (rhsError as NSError)
        }
    }
}



// MARK: - Private conveniences

private extension StravaApiClient {
    /// Performs an authenticated GET and decodes the response body into `T`.
    func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let token = try await auth.validAccessToken()
        
        var components = URLComponents(
            url: AppConfigValues.URLs.apiBase.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !queryItems.isEmpty { components.queryItems = queryItems }
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw ApiError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw ApiError.httpError(http.statusCode, data)
        }
        
        return try decoder.decode(T.self, from: data)
    }
}



// MARK: - Errors

extension StravaApiClient {
    enum ApiError: LocalizedError {
        case invalidResponse
        case httpError(Int, Data)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Received a non-HTTP response"
            case .httpError(let code, let body):
                return "HTTP \(code): \(String(data: body, encoding: .utf8) ?? "no body")"
            }
        }
    }
}
