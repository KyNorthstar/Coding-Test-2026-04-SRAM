//
//  StravaClient + SwiftUI.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import SwiftUI



private extension StravaClient {
    struct Key: SwiftUI.EnvironmentKey {
        static let defaultValue: StravaClient = .placeholder
    }
}



extension EnvironmentValues {
    /// The current Strava-side app
    var stravaClient: StravaClient {
        get { self[StravaClient.Key.self] }
        set { self[StravaClient.Key.self] = newValue }
    }
}
