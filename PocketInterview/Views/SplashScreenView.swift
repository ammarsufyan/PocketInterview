//
//  SplashScreenView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isLogoAnimated = false
    @State private var isTextAnimated = false
    @State private var isBadgeAnimated = false
    @State private var showMainApp = false
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        // 🔥 FIXED: Use conditional view to prevent back navigation to splash
        if showMainApp {
            ContentView()
                .environmentObject(authManager)
                .transition(.opacity)
        } else {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.3),
                        Color(red: 0.15, green: 0.2, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and App Name Section
                    VStack(spacing: 32) {
                        // 🔥 UPDATED: Use AppIcon from Assets
                        AppIconLogo()
                            .scaleEffect(isLogoAnimated ? 1.0 : 0.3)
                            .opacity(isLogoAnimated ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0),
                                value: isLogoAnimated
                            )
                        
                        // App Name and Tagline
                        VStack(spacing: 12) {
                            Text("PocketInterview")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(isTextAnimated ? 1.0 : 0.0)
                                .offset(y: isTextAnimated ? 0 : 20)
                            
                            Text("Master Your Interview Skills")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(isTextAnimated ? 1.0 : 0.0)
                                .offset(y: isTextAnimated ? 0 : 20)
                        }
                        .animation(
                            .easeOut(duration: 0.8).delay(0.3),
                            value: isTextAnimated
                        )
                    }
                    
                    Spacer()
                    
                    // Built by Bolt.new Badge - Using Asset Image
                    BoltBadgeImageView(height: 60, scaleEffect: 0.9)
                        .opacity(isBadgeAnimated ? 1.0 : 0.0)
                        .offset(y: isBadgeAnimated ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.6).delay(0.8),
                            value: isBadgeAnimated
                        )
                        .padding(.bottom, 50)
                }
            }
            .onAppear {
                startAnimationSequence()
            }
            .transition(.opacity)
        }
    }
    
    private func startAnimationSequence() {
        // Logo animation
        withAnimation {
            isLogoAnimated = true
        }
        
        // Text animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isTextAnimated = true
            }
        }
        
        // Badge animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                isBadgeAnimated = true
            }
        }
        
        // 🔥 FIXED: Navigate to main app with smooth transition (no back navigation possible)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.smooth(duration: 0.5)) {
                showMainApp = true
            }
        }
    }
}

// 🔥 UPDATED: Clean AppIcon Logo without background circle
struct AppIconLogo: View {
    var body: some View {
        // App Icon from Assets - Clean without background circle
        Image("PocketInterviewFull")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 26.4))
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

#Preview {
    SplashScreenView()
}
