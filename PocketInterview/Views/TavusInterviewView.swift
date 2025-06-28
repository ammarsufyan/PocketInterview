//
//  TavusInterviewView.swift
//  PocketInterview
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
        .ignoresSafeArea(.all, edges: .bottom) // Make the view fullscreen
        .interactiveDismissDisabled() // Prevent swipe-down dismissal
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