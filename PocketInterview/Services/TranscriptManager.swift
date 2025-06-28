//
//  TranscriptManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class TranscriptManager: ObservableObject {
    @Published var transcripts: [InterviewTranscript] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthListener()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            await loadTranscripts()
        case .signedOut:
            self.transcripts = []
            self.errorMessage = nil
        default:
            break
        }
    }
    
    // MARK: - Data Operations
    
    func loadTranscripts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load transcripts for user's interview sessions
            let response: [InterviewTranscript] = try await supabase
                .from("interview_transcripts")
                .select("""
                    id,
                    conversation_id,
                    transcript_data,
                    message_count,
                    user_message_count,
                    assistant_message_count,
                    webhook_timestamp,
                    created_at,
                    updated_at
                """)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.transcripts = response
            print("✅ Loaded \(response.count) transcripts")
            
        } catch {
            self.errorMessage = "Failed to load transcripts"
            print("❌ Failed to load transcripts: \(error)")
            
            // Fallback to sample data for development
            self.transcripts = createSampleTranscripts()
        }
        
        isLoading = false
    }
    
    func getTranscript(for conversationId: String) async -> InterviewTranscript? {
        do {
            let response: InterviewTranscript = try await supabase
                .from("interview_transcripts")
                .select("""
                    id,
                    conversation_id,
                    transcript_data,
                    message_count,
                    user_message_count,
                    assistant_message_count,
                    webhook_timestamp,
                    created_at,
                    updated_at
                """)
                .eq("conversation_id", value: conversationId)
                .single()
                .execute()
                .value
            
            return response
            
        } catch {
            print("❌ Failed to load transcript for conversation \(conversationId): \(error)")
            return nil
        }
    }
    
    func getTranscriptForSession(_ session: InterviewSession) async -> InterviewTranscript? {
        guard let conversationId = session.conversationId else {
            return nil
        }
        
        return await getTranscript(for: conversationId)
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func refreshTranscripts() async {
        await loadTranscripts()
    }
    
    func hasTranscript(for conversationId: String?) -> Bool {
        guard let conversationId = conversationId else { return false }
        return transcripts.contains { $0.conversationId == conversationId }
    }
    
    func getLocalTranscript(for conversationId: String) -> InterviewTranscript? {
        return transcripts.first { $0.conversationId == conversationId }
    }
    
    // MARK: - Analytics
    
    func getTranscriptAnalytics() -> TranscriptAnalytics {
        let totalTranscripts = transcripts.count
        let totalMessages = transcripts.reduce(0) { $0 + $1.messageCount }
        let totalUserMessages = transcripts.reduce(0) { $0 + $1.userMessageCount }
        let totalAssistantMessages = transcripts.reduce(0) { $0 + $1.assistantMessageCount }
        
        let averageMessagesPerSession = totalTranscripts > 0 ? totalMessages / totalTranscripts : 0
        let averageUserResponsesPerSession = totalTranscripts > 0 ? totalUserMessages / totalTranscripts : 0
        
        return TranscriptAnalytics(
            totalTranscripts: totalTranscripts,
            totalMessages: totalMessages,
            totalUserMessages: totalUserMessages,
            totalAssistantMessages: totalAssistantMessages,
            averageMessagesPerSession: averageMessagesPerSession,
            averageUserResponsesPerSession: averageUserResponsesPerSession
        )
    }
    
    // MARK: - Sample Data (for development/testing)
    
    private func createSampleTranscripts() -> [InterviewTranscript] {
        return [
            InterviewTranscript.sampleTechnicalTranscript(),
            InterviewTranscript.sampleBehavioralTranscript()
        ]
    }
}

// MARK: - Analytics Model

struct TranscriptAnalytics {
    let totalTranscripts: Int
    let totalMessages: Int
    let totalUserMessages: Int
    let totalAssistantMessages: Int
    let averageMessagesPerSession: Int
    let averageUserResponsesPerSession: Int
    
    var engagementRate: Double {
        guard totalMessages > 0 else { return 0.0 }
        return Double(totalUserMessages) / Double(totalMessages)
    }
    
    var averageResponseLength: String {
        return "\(averageUserResponsesPerSession) responses per session"
    }
}