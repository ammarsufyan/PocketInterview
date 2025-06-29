//
//  ContentView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var historyManager = InterviewHistoryManager()
    
    var body: some View {
        // 🔥 FIXED: Monitor auth state and redirect to auth view when not authenticated
        Group {
            if authManager.isAuthenticated {
                TabView {
                    MockInterviewView()
                        .tabItem {
                            Image(systemName: "mic.circle.fill")
                            Text("Interview")
                        }
                        .environmentObject(historyManager)
                    
                    HistoryView()
                        .tabItem {
                            Image(systemName: "clock.fill")
                            Text("History")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.circle.fill")
                            Text("Profile")
                        }
                }
                .accentColor(.blue)
                .environmentObject(authManager)
            } else {
                // 🔥 FIXED: Show authentication view when not authenticated
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}