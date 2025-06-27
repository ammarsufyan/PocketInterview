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
    let onBackToSetup: () -> Void // NEW: Back to setup callback
    
    @StateObject private var tavusService = TavusService()
    @EnvironmentObject private var historyManager: InterviewHistoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEndConfirmation = false
    @State private var sessionStartTime = Date()
    @State private var isSessionActive = false
    @State private var sessionEndReason: String = "manual"
    @State private var hasSessionStarted = false
    @State private var isEndingSession = false
    @State private var isShowingAlert = false
    
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
                            handleSessionStart()
                        },
                        onSessionEnd: {
                            handleSessionEnd(reason: "tavus_end")
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
                
                // Loading overlay when ending session
                if isEndingSession {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        
                        Text("Ending Interview...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                }
            }
            .navigationTitle("AI Interview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // ENHANCED: Different buttons based on state
                    if tavusService.conversationUrl != nil {
                        // Show End Interview when webview is loaded
                        Button("End Interview") {
                            if !isShowingAlert && !isEndingSession {
                                sessionEndReason = "manual"
                                isShowingAlert = true
                                showingEndConfirmation = true
                            }
                        }
                        .foregroundColor(.red)
                        .disabled(isEndingSession || isShowingAlert)
                    } else {
                        // ENHANCED: Show Back to Setup instead of Cancel
                        Button("Back to Setup") {
                            onBackToSetup()
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
                Button("Continue", role: .cancel) {
                    isShowingAlert = false
                }
                Button("End Interview", role: .destructive) {
                    isShowingAlert = false
                    Task {
                        await endInterviewWithAPI(reason: sessionEndReason)
                    }
                }
            } message: {
                Text("Are you sure you want to end the interview? Your progress will be saved.")
            }
        }
        .onAppear {
            // ENHANCED: Debug session data on appear
            print("🔧 DEBUG: TavusInterviewView appeared")
            print("  - Category: '\(category)'")
            print("  - Session Name: '\(sessionName)'")
            print("  - Duration: \(duration)")
            print("  - CV Context: \(cvContext != nil ? "Provided" : "None")")
            
            if !sessionName.isEmpty {
                Task {
                    await startTavusSession()
                }
            } else {
                print("❌ Session name is empty, not starting session")
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
    
    // MARK: - Session Management Methods
    
    private func handleSessionStart() {
        guard !hasSessionStarted else {
            print("🔧 Session already started")
            return
        }
        
        print("🎬 Session start confirmed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !self.hasSessionStarted {
                self.sessionStartTime = Date()
                self.isSessionActive = true
                self.hasSessionStarted = true
                print("🎬 Session officially started")
            }
        }
    }
    
    private func handleSessionEnd(reason: String) {
        guard hasSessionStarted && isSessionActive && !isEndingSession else {
            print("🔧 Session end ignored - invalid state")
            return
        }
        
        print("🏁 Session end triggered - Reason: \(reason)")
        
        Task {
            await endInterviewWithAPI(reason: reason)
        }
    }
    
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
        print("🧪 Testing API Key...")
        let isValid = await tavusService.testApiKey()
        print("🧪 Result: \(isValid ? "✅ Valid" : "❌ Invalid")")
    }
    
    // MARK: - End Interview with API Call
    
    private func endInterviewWithAPI(reason: String = "manual") async {
        guard hasSessionStarted && !isEndingSession else {
            print("🔧 Cannot end - invalid state")
            if !hasSessionStarted {
                dismiss()
            }
            return
        }
        
        isEndingSession = true
        
        print("🔚 Ending interview...")
        print("  - Reason: \(reason)")
        
        // Step 1: End Tavus conversation
        let apiSuccess = await tavusService.endConversationSession()
        
        // Step 2: Calculate duration
        let actualDuration = Int(Date().timeIntervalSince(sessionStartTime) / 60)
        
        print("📊 Interview ended:")
        print("  - Duration: \(actualDuration) minutes")
        print("  - API Success: \(apiSuccess)")
        
        // Step 3: Save to history
        await historyManager.createSession(
            category: category,
            sessionName: sessionName,
            score: nil,
            durationMinutes: max(actualDuration, 1),
            questionsAnswered: 0,
            sessionData: [
                "tavus_session_id": tavusService.sessionId ?? "",
                "end_reason": reason,
                "api_end_success": apiSuccess
            ]
        )
        
        // Step 4: Reset state
        isSessionActive = false
        hasSessionStarted = false
        isEndingSession = false
        isShowingAlert = false
        
        // Step 5: Clear service
        tavusService.clearSession()
        
        print("✅ Interview end completed")
        
        // Step 6: Dismiss
        dismiss()
    }
}

// MARK: - Supporting Views (keeping existing implementations)

struct TavusLoadingView: View {
    let category: String
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        VStack(spacing: 24) {
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
                
                TipsCard(category: category, categoryColor: categoryColor)
                    .padding(.horizontal, 20)
                
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
        cvContext: "Senior iOS Developer with 5+ years experience",
        onBackToSetup: {
            print("Back to setup")
        }
    )
    .environmentObject(InterviewHistoryManager())
}