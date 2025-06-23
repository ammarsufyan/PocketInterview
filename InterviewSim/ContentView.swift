//
//  ContentView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MockInterviewView()
                .tabItem {
                    Image(systemName: "mic.circle.fill")
                    Text("Mock Interview")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}