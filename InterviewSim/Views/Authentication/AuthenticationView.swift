//
//  AuthenticationView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingSignUp = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                if showingSignUp {
                    SignUpView(authManager: authManager, showingSignUp: $showingSignUp)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    SignInView(authManager: authManager, showingSignUp: $showingSignUp)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .trailing)
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: showingSignUp)
    }
}

#Preview {
    AuthenticationView()
}