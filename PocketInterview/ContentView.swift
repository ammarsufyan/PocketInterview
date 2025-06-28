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
        TabView {
            MockInterviewView()
                .tabItem {
                    Image(systemName: "mic.circle.fill")
                    Text("Mock Interview")
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
    }
}

#Preview {
    ContentView()
}