//
//  TavusInterviewView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI
import WebKit

struct TavusInterviewView: View {
    @ObservedObject var sessionData: SessionData
    let cvContext: String?
    let onBackToSetup: () -> Void
    
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
    
    @State private var showPreparationView = true
    @State private var hasAttemptedStart = false
    
    private var categoryColor: Color {
        sessionData.category == "Technical" ? .blue : .purple
    }
    
    private var interviewerName: String {
        TavusConfig.getInterviewerName(for: sessionData.category)
    }
    
    private var interviewerDescription: String {
        TavusConfig.getInterviewerDescription(for: sessionData.category)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if showPreparationView {
                    TavusPreparationView(
                        category: sessionData.category,
                        sessionName: sessionData.sessionName,
                        duration: sessionData.duration,
                        categoryColor: categoryColor,
                        interviewerName: interviewerName,
                        interviewerDescription: interviewerDescription,
                        onStart: {
                            showPreparationView = false
                            hasAttemptedStart = true
                            
                            Task {
                                await startTavusSession()
                            }
                        },
                        onCancel: {
                            onBackToSetup()
                        }
                    )
                } else if tavusService.isLoading {
                    TavusLoadingView(
                        category: sessionData.category,
                        interviewerName: interviewerName
                    )
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
                        onCancel: {
                            onBackToSetup()
                        }
                    )
                } else if hasAttemptedStart {
                    TavusLoadingView(
                        category: sessionData.category,
                        interviewerName: interviewerName
                    )
                }
                
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
                    if tavusService.conversationUrl != nil {
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
            if !sessionData.isValid {
                // Could show an error or go back to setup
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if tavusService.isLoading && !hasSessionStarted {
                Task {
                    tavusService.clearSession()
                }
            }
        }
        .onDisappear {
            resetAllState()
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
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !self.hasSessionStarted && self.tavusService.conversationUrl != nil {
                self.sessionStartTime = Date()
                self.isSessionActive = true
                self.hasSessionStarted = true
            }
        }
    }
    
    private func handleSessionEnd(reason: String) {
        guard hasSessionStarted && isSessionActive && !isEndingSession else {
            return
        }
        
        Task {
            await endInterviewWithAPI(reason: reason)
        }
    }
    
    private func startTavusSession() async {
        guard !tavusService.isLoading else {
            return
        }
        
        guard sessionData.isValid else {
            return
        }
        
        let success = await tavusService.createConversationSession(
            category: sessionData.category,
            sessionName: sessionData.sessionName,
            duration: sessionData.duration,
            cvContext: cvContext,
            historyManager: historyManager
        )
        
        if !success {
            // Error handling is done in TavusService
        }
    }
    
    // MARK: - End Interview with API Call
    
    private func endInterviewWithAPI(reason: String = "manual") async {
        guard hasSessionStarted && !isEndingSession else {
            if !hasSessionStarted {
                dismiss()
            }
            return
        }
        
        isEndingSession = true
        
        // End the Tavus conversation
        _ = await tavusService.endConversationSession()
        
        let actualDuration = Int(Date().timeIntervalSince(sessionStartTime) / 60)
        
        // Update the existing session record with final data
        _ = await tavusService.updateSessionWithFinalData(
            historyManager: historyManager,
            actualDurationMinutes: max(actualDuration, 1),
            questionsAnswered: 0,
            score: nil,
            endReason: reason
        )
        
        resetAllState()
        dismiss()
    }
    
    // MARK: - State Reset
    
    private func resetAllState() {
        isSessionActive = false
        hasSessionStarted = false
        isEndingSession = false
        isShowingAlert = false
        
        showPreparationView = true
        hasAttemptedStart = false
        showingEndConfirmation = false
        
        sessionStartTime = Date()
        sessionEndReason = "manual"
        
        tavusService.clearSession()
    }
}

// MARK: - Supporting Views

struct TavusLoadingView: View {
    let category: String
    let interviewerName: String
    
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
                Text("Connecting to \(interviewerName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Setting up your personalized \(category.lowercased()) interview...")
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
                
                Button(action: onCancel) {
                    Text("Back to Setup")
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
    let interviewerName: String
    let interviewerDescription: String
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
                        Text("Meet Your Interviewer")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(interviewerName)
                            .font(.title)
                            .foregroundColor(categoryColor)
                            .fontWeight(.bold)
                        
                        Text(interviewerDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
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
                    
                    SessionDetailRow(
                        icon: "brain.head.profile",
                        title: "AI Interviewer",
                        value: interviewerName,
                        color: categoryColor
                    )
                }
                .padding(.horizontal, 20)
                
                TipsCard(category: category, categoryColor: categoryColor)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button(action: {
                        onStart()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            
                            Text("Start Interview with \(interviewerName)")
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
                    
                    Button(action: {
                        onCancel()
                    }) {
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