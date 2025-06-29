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
    
    var body: some View {
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
                    // Logo
                    InterviewSimLogo()
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
                BoltBadgeImageView(height: 32, scaleEffect: 0.9)
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
        .fullScreenCover(isPresented: $showMainApp) {
            AuthenticationView()
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
        
        // Navigate to authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showMainApp = true
            }
        }
    }
}

struct InterviewSimLogo: View {
    var body: some View {
        ZStack {
            // Outer Circle - Background
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.cyan.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(
                    color: Color.blue.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            
            // Inner Circle - Accent
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            // Main Icon - Microphone with Person
            VStack(spacing: 4) {
                // Microphone Icon
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
                
                // Small indicator dots
                HStack(spacing: 3) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}