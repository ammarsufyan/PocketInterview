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
    
    init(height: CGFloat = 28, scaleEffect: CGFloat = 0.95) {
        self.height = height
        self.scaleEffect = scaleEffect
    }
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://bolt.new") {
                UIApplication.shared.open(url)
            }
        }) {
            Image("bolt_badge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 3,
                    x: 0,
                    y: 2
                )
        }
        .scaleEffect(scaleEffect)
    }
}

#Preview {
    VStack(spacing: 20) {
        BoltBadgeImageView(height: 32, scaleEffect: 0.9) // Splash screen size
        BoltBadgeImageView(height: 28, scaleEffect: 0.95) // Main view size
        BoltBadgeImageView() // Default size
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}