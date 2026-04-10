//
//  App.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import SwiftUI



@main
struct App: SwiftUI.App {
    
    var body: some Scene {
        WindowGroup {
            if let stravaClientId = StravaConfiguration.clientId,
               let stravaClientSecret = StravaConfiguration.clientSecret {
                ContentView()
                    .environment(\.stravaClient, StravaClient(id: stravaClientId, secret: stravaClientSecret))
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
