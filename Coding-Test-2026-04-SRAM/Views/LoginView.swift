//
//  LoginView.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky directing Claude 4.6 Sonnet on 2026-04-10.
//

import SwiftUI



/// Shown on first launch or after sign-out. Initiates the Strava OAuth flow on tap.
struct LoginView: View {

    @EnvironmentObject private var auth: StravaOAuthService
    @State private var isConnecting  = false
    @State private var error: Error?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 8) {
                Image(.loginIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120, maxHeight: 120)
                
                Text("Cadence")
                    .font(.largeTitle.bold())
                
                Text("Your Strava activity, visualized.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                if let error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task {
                        await connect()
                    }
                }
                label: {
                    HStack(spacing: 8) {
                        if isConnecting {
                            ProgressView().tint(.white)
                        }
                        
                        Text(isConnecting ? "Logging in…" : "Log in with Strava")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(isConnecting ? .gray : .accent))
                    .foregroundStyle(.white)
                }
                .disabled(isConnecting)
            }
            .padding(.horizontal).padding(.bottom, 40)
        }
    }

    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        
        error = nil
        
        do {
            try await auth.authorize()
        }
        catch {
            self.error = error
        }
    }
}
