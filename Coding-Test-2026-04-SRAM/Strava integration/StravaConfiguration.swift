//
//  StravaConfiguration.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import Foundation

import CollectionTools



/// This app's configuration for using the Strava API
enum StravaConfiguration {
    static let clientId: String? = {
        (Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_ID") as? String)?.nonEmptyOrNil
    }()
    static let clientSecret: String? = {
        (Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_SECRET") as? String)?.nonEmptyOrNil
    }()
    
    enum URLs {
        static let authorize = URL(string: "https://www.strava.com/oauth/authorize")!
        static let token     = URL(string: "https://www.strava.com/oauth/token")!
        static let apiBase   = URL(string: "https://www.strava.com/api/v3")!
    }
}
