//
//  App.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import SwiftUI

import CollectionTools



@main
struct App: SwiftUI.App {
    
    var body: some Scene {
        WindowGroup {
            if let stravaClientId = AppConfigValues.clientId?.nonEmptyOrNil,
               let stravaClientSecret = AppConfigValues.clientSecret?.nonEmptyOrNil {
                ContentView()
                    .environment(\.stravaClientIdentity, StravaClientIdentity(id: stravaClientId, secret: stravaClientSecret))
                    .environmentObject(StravaOAuthService())
            }
            else {
                Text(try! AttributedString(markdown: """
                    **Developer error!**
                    
                    You did nothing wrong. If restarting the app doesn't fix this error, tell the dev that the client ID & secret aren't loading properly.
                    """, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .returnPartiallyParsedIfPossible)))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.red)
            }
        }
    }
}
