//
//  InterviewSimApp.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

@main
struct PocketInterviewApp: App {
    // 🔥 FIXED: Create a single AuthenticationManager instance for the entire app
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authManager) // 🔥 Pass the auth manager to splash screen
        }
    }
}