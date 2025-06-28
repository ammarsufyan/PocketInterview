//
//  TavusErrorView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct TavusErrorView: View {
    let message: String
    let categoryColor: Color
    let onRetry: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 16) {
                Text("Connection Error")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                // Retry button
                Button(action: onRetry) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        
                        Text("Try Again")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [categoryColor, categoryColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(
                        color: categoryColor.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                
                // Cancel button
                Button(action: onCancel) {
                    Text("Back to Setup")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            
            // Troubleshooting tips
            VStack(alignment: .leading, spacing: 16) {
                Text("Troubleshooting Tips:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    TroubleshootingTip(text: "Check your internet connection")
                    TroubleshootingTip(text: "Ensure camera and microphone permissions are granted")
                    TroubleshootingTip(text: "Try restarting the app")
                    TroubleshootingTip(text: "Make sure your device is not in low power mode")
                }
            }
            .padding(20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .padding(32)
    }
}

struct TroubleshootingTip: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.secondary)
                .padding(.top, 6)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    TavusErrorView(
        message: "Unable to connect to the interview server. Please check your internet connection and try again.",
        categoryColor: .blue,
        onRetry: {},
        onCancel: {}
    )
}