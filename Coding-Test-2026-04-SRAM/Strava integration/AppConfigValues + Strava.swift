//
//  AppConfigValues + Strava.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import Foundation

import Introspection



extension AppConfigValues {
    static let client: StravaClientIdentity? = {
        guard let id: String = Introspection.Bundle["STRAVA_CLIENT_ID"],
              let secret: String = Introspection.Bundle["STRAVA_CLIENT_SECRET"]
        else {
            return nil
        }
        
        return .init(id: id, secret: secret)
    }()
    
    static var clientId: String? { client?.id }
    static var clientSecret: String? { client?.secret }
}
