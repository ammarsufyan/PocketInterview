//
//  BoltBadgeView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct BoltBadgeImageView: View {
    let height: CGFloat
    let scaleEffect: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    init(height: CGFloat = 28, scaleEffect: CGFloat = 0.95) {
        self.height = height
        self.scaleEffect = scaleEffect
    }
    
    // MARK: - Dynamic Image Selection Based on Color Scheme
    
    private var badgeImageName: String {
        switch colorScheme {
        case .dark:
            return "white_circle_360x360"  // White circle for dark mode
        case .light:
            return "black_circle_360x360"  // Black circle for light mode
        @unknown default:
            return "white_circle_360x360"  // Default fallback
        }
    }
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://bolt.new") {
                UIApplication.shared.open(url)
            }
        }) {
            Image(badgeImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
                .shadow(
                    color: shadowColor,
                    radius: 3,
                    x: 0,
                    y: 2
                )
        }
        .scaleEffect(scaleEffect)
    }
    
    // MARK: - Dynamic Shadow Color
    
    private var shadowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.15)  // Light shadow for dark mode
        case .light:
            return Color.black.opacity(0.15)  // Dark shadow for light mode
        @unknown default:
            return Color.black.opacity(0.15)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Preview in different color schemes
        Group {
            BoltBadgeImageView(height: 32, scaleEffect: 0.9) // Splash screen size
            BoltBadgeImageView(height: 28, scaleEffect: 0.95) // Main view size
            BoltBadgeImageView() // Default size
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        
        // Preview with different backgrounds to test visibility
        VStack(spacing: 10) {
            Text("Light Background")
                .font(.caption)
                .foregroundColor(.secondary)
            
            BoltBadgeImageView()
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            
            Text("Dark Background")
                .font(.caption)
                .foregroundColor(.secondary)
            
            BoltBadgeImageView()
                .padding()
                .background(Color.black)
                .cornerRadius(8)
        }
    }
    .padding()
}