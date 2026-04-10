//
//  StravaClient.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import Foundation



struct StravaClient {
    let id: String
    let secret: String
}



extension StravaClient {
    /// Place this where you need a non-`nil` value but don't have a valid one. For example, Xcode previews or pre-load environment values which are expected/guaranteed to be valid by the time the user sees a view.
    static var placeholder: Self {
        .init(id: "<clientId>", secret: "<clientSecret>")
    }
}
