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
    
    
    var body: some View {
        if case .success(let client) = client {
            if stravaOauthService.isAuthenticated {
                HeatmapView(client: client)
            }
            else {
                LoginView()
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



#Preview {
    ContentView()
}
