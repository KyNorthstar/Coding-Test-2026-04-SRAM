//
//  ContentView.swift
//  Coding-Test-2026-04-SRAM
//
//  Created by Ky on 2026-04-10.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.stravaClient)
    private var stravaClient
    
    var body: some View {
        VStack {
            Text("Client ID: \(stravaClient.id)")
            Text("Client Secret: \(stravaClient.secret)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
