//
//  TavusInterviewView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI
import WebKit

struct TavusInterviewView: View {
    let category: String
    let sessionName: String
    let duration: Int
    let cvContext: String?
    
    @StateObject private var tavusService = TavusService()
    @EnvironmentObject private var historyManager: InterviewHistoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEndConfirmation = false
    @State private var sessionStartTime = Date()
    @State private var isSessionActive = false
    @State private var showingApiKeyTest = false
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if tavusService.isLoading {
                    TavusLoadingView(category: category)
                } else if let conversationUrl = tavusService.conversationUrl {
                    TavusWebView(
                        url: conversationUrl,
                        onSessionStart: {
                            sessionStartTime = Date()
                            isSessionActive = true
                        },
                        onSessionEnd: {
                            endInterview()
                        }
                    )
                } else if let errorMessage = tavusService.errorMessage {
                    TavusErrorView(
                        message: errorMessage,
                        categoryColor: categoryColor,
                        onRetry: {
                            Task {
                                await startTavusSession()
                            }
                        },
                        onTestApiKey: {
                            Task {
                                await testApiKey()
                            }
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                } else {
                    TavusPreparationView(
                        category: category,
                        sessionName: sessionName,
                        duration: duration,
                        categoryColor: categoryColor,
                        onStart: {
                            Task {
                                await startTavusSession()
                            }
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("AI Interview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSessionActive {
                        Button("End Interview") {
                            showingEndConfirmation = true
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(categoryColor)
                    }
                }
                
                if isSessionActive {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 8) {
                            Image(systemName: "record.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text(timeElapsed)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .alert("End Interview", isPresented: $showingEndConfirmation) {
                Button("Continue", role: .cancel) { }
                Button("End Interview", role: .destructive) {
                    endInterview()
                }
            } message: {
                Text("Are you sure you want to end the interview? Your progress will be saved.")
            }
            .alert("API Key Test Result", isPresented: $showingApiKeyTest) {
                Button("OK") { }
            } message: {
                Text("Check the console for detailed API key test results.")
            }
        }
        .onAppear {
            // Auto-start if we have all required data
            if !sessionName.isEmpty {
                Task {
                    await startTavusSession()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeElapsed: String {
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Methods
    
    private func startTavusSession() async {
        let success = await tavusService.createConversationSession(
            category: category,
            sessionName: sessionName,
            duration: duration,
            cvContext: cvContext
        )
        
        if !success {
            print("❌ Failed to create Tavus session")
        }
    }
    
    private func testApiKey() async {
        print("🧪 Testing Tavus API Key...")
        let isValid = await tavusService.testApiKey()
        print("🧪 API Key Test Result: \(isValid ? "✅ Valid" : "❌ Invalid")")
        showingApiKeyTest = true
    }
    
    private func endInterview() {
        let actualDuration = Int(Date().timeIntervalSince(sessionStartTime) / 60)
        
        // Save session to history
        Task {
            await historyManager.createSession(
                category: category,
                sessionName: sessionName,
                score: nil, // Score will be determined later
                durationMinutes: actualDuration,
                questionsAnswered: 0, // Will be updated based on Tavus data
                sessionData: [
                    "tavus_session_id": tavusService.sessionId ?? "",
                    "conversation_url": tavusService.conversationUrl ?? "",
                    "cv_context_provided": cvContext != nil
                ]
            )
        }
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct TavusLoadingView: View {
    let category: String
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Logo
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 50))
                    .foregroundColor(categoryColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
            
            VStack(spacing: 12) {
                Text("Preparing Your AI Interviewer")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Setting up personalized \(category.lowercased()) interview...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(categoryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct TavusErrorView: View {
    let message: String
    let categoryColor: Color
    let onRetry: () -> Void
    let onTestApiKey: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 12) {
                Text("Connection Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                        Text("Try Again")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(categoryColor)
                    .cornerRadius(12)
                }
                
                // ADDED: Test API Key Button for debugging
                Button(action: onTestApiKey) {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.headline)
                        Text("Test API Key")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(categoryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(categoryColor.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(categoryColor, lineWidth: 1)
                    )
                }
                
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct TavusPreparationView: View {
    let category: String
    let sessionName: String
    let duration: Int
    let categoryColor: Color
    let onStart: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: category == "Technical" ? "laptopcomputer" : "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text("Ready to Start?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(category) Interview with AI")
                            .font(.headline)
                            .foregroundColor(categoryColor)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 40)
                
                // Session Details
                VStack(spacing: 16) {
                    SessionDetailRow(
                        icon: "text.quote",
                        title: "Session Name",
                        value: sessionName,
                        color: categoryColor
                    )
                    
                    SessionDetailRow(
                        icon: "clock.fill",
                        title: "Duration",
                        value: "\(duration) minutes",
                        color: categoryColor
                    )
                    
                    SessionDetailRow(
                        icon: "person.fill",
                        title: "Interview Type",
                        value: category,
                        color: categoryColor
                    )
                }
                .padding(.horizontal, 20)
                
                // Tips
                TipsCard(category: category, categoryColor: categoryColor)
                    .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onStart) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            
                            Text("Start AI Interview")
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
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
        }
    }
}

struct SessionDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TipsCard: View {
    let category: String
    let categoryColor: Color
    
    private var tips: [String] {
        switch category {
        case "Technical":
            return [
                "Think out loud while solving problems",
                "Ask clarifying questions",
                "Explain your approach before coding",
                "Consider edge cases and optimization"
            ]
        case "Behavioral":
            return [
                "Use the STAR method (Situation, Task, Action, Result)",
                "Provide specific examples from your experience",
                "Be honest about challenges and learnings",
                "Show your problem-solving process"
            ]
        default:
            return [
                "Be authentic and confident",
                "Listen carefully to questions",
                "Take your time to think",
                "Ask questions if unclear"
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(categoryColor)
                
                Text("Interview Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(categoryColor.opacity(0.2), lineWidth: 1)
            )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    TavusInterviewView(
        category: "Technical",
        sessionName: "iOS Development Practice",
        duration: 30,
        cvContext: "Senior iOS Developer with 5+ years experience in Swift, SwiftUI, and UIKit"
    )
    .environmentObject(InterviewHistoryManager())
}