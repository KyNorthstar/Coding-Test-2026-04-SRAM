//
//  StravaClient + SwiftUI.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import SwiftUI



private extension StravaClientIdentity {
    struct Key: SwiftUI.EnvironmentKey {
        static let defaultValue: StravaClientIdentity = .placeholder
    }
}



extension EnvironmentValues {
    /// The current Strava-side app
    var stravaClientIdentity: StravaClientIdentity {
        get { self[StravaClientIdentity.Key.self] }
        set { self[StravaClientIdentity.Key.self] = newValue }
    }
}
