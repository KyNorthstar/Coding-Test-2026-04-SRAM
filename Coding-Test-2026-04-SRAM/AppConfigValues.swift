//
//  AppConfigValues.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import Foundation



@available(*, deprecated, renamed: "AppConfigValues")
typealias StravaConfig = AppConfigValues



/// This app's configuration for using the Strava API
enum AppConfigValues {}



extension AppConfigValues {
    static let redirectUri  = "cadence://oauth/callback"
    static let scope        = "activity:read_all"
}



extension AppConfigValues {
    enum URLs {
        static let authorize = URL(string: "https://www.strava.com/oauth/authorize")!
        static let token     = URL(string: "https://www.strava.com/oauth/token")!
        static let apiBase   = URL(string: "https://www.strava.com/api/v3")!
    }
}
