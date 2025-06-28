//
//  TavusLoadingView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct TavusLoadingView: View {
    let category: String
    let interviewerName: String
    
    @State private var loadingText = "Connecting to interview..."
    @State private var dots = ""
    @State private var isAnimating = false
    
    private let loadingTexts = [
        "Connecting to interview...",
        "Setting up your session...",
        "Preparing your interviewer...",
        "Almost ready..."
    ]
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // Loading animation
            ZStack {
                Circle()
                    .stroke(categoryColor.opacity(0.2), lineWidth: 14)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(categoryColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                
                Image(systemName: category == "Technical" ? "laptopcomputer" : "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundColor(categoryColor)
                    .symbolRenderingMode(.hierarchical)
            }
            
            VStack(spacing: 16) {
                Text("\(loadingText)\(dots)")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Your \(category) interview with \(interviewerName) is being prepared")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    LoadingTip(icon: "checkmark.circle.fill", text: "Camera access granted")
                    LoadingTip(icon: "checkmark.circle.fill", text: "Microphone access granted")
                }
                
                HStack(spacing: 20) {
                    LoadingTip(icon: "wifi", text: "Internet connection stable")
                    LoadingTip(icon: "person.fill", text: "Interviewer is ready")
                }
            }
            .padding(.top, 20)
        }
        .padding(32)
        .onAppear {
            isAnimating = true
            animateDots()
            animateText()
        }
    }
    
    private func animateDots() {
        var dotsCount = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            dotsCount = (dotsCount + 1) % 4
            dots = String(repeating: ".", count: dotsCount)
        }
    }
    
    private func animateText() {
        var textIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            textIndex = (textIndex + 1) % loadingTexts.count
            loadingText = loadingTexts[textIndex]
        }
    }
}

struct LoadingTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    TavusLoadingView(category: "Technical", interviewerName: "Steve")
}