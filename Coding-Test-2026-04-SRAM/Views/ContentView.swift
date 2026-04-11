//
//  ContentView.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.stravaClientIdentity)
    private var stravaClientIdentity
    
    @EnvironmentObject //(\.stravaOauthService)
    private var stravaOauthService: StravaOAuthService
    
    @State
    private var client: LoadingState<StravaApiClient> = .notStarted
    
    @State
    private var showDemo = false
    
    
    var body: some View {
        if showDemo {
            HeatmapView(activities: .random(pastDaysToGenerate: 200))
        }
        else if case .success(let client) = client {
            if stravaOauthService.isAuthenticated {
                HeatmapLoadingView(client: client)
            }
            else {
                LoginView()
                    .onTapGesture(count: 5, perform: { showDemo = true })
            }
        }
        else {
            ProgressView()
                .task {
                    self.client = .loading
                    self.client = .success(StravaApiClient(auth: stravaOauthService))
                }
        }
    }
}
