//
//  InterviewHistoryManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class InterviewHistoryManager: ObservableObject {
    @Published var sessions: [InterviewSession] = []
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
            await loadSessions()
        case .signedOut:
            self.sessions = []
            self.errorMessage = nil
        default:
            break
        }
    }
    
    // MARK: - Data Operations
    
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [InterviewSession] = try await supabase
                .from("interview_sessions")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.sessions = response
        } catch {
            self.errorMessage = "Failed to load interview history"
            
            // Fallback to sample data for development
            self.sessions = createSampleSessions()
        }
        
        isLoading = false
    }
    
    @discardableResult
    func createSession(
        category: String,
        sessionName: String,
        score: Int? = nil,
        expectedDurationMinutes: Int,
        actualDurationMinutes: Int? = nil,
        questionsAnswered: Int = 0,
        conversationId: String? = nil,
        sessionStatus: String = "created",
        endReason: String? = nil
    ) async -> InterviewSession? {
        
        do {
            // Get current user session properly
            let currentSession = try await supabase.auth.session
            let userId = currentSession.user.id
            
            let newSession = InterviewSessionInsert(
                userId: userId,
                category: category,
                sessionName: sessionName,
                score: score,
                expectedDurationMinutes: expectedDurationMinutes,
                actualDurationMinutes: actualDurationMinutes,
                questionsAnswered: questionsAnswered,
                conversationId: conversationId,
                sessionStatus: sessionStatus,
                endReason: endReason
            )
            
            let response: InterviewSession = try await supabase
                .from("interview_sessions")
                .insert(newSession)
                .select()
                .single()
                .execute()
                .value
            
            // Add to local array
            self.sessions.insert(response, at: 0)
            
            return response
            
        } catch {
            self.errorMessage = "Failed to save interview session"
            return nil
        }
    }
    
    func updateSession(
        sessionId: UUID,
        score: Int? = nil,
        actualDurationMinutes: Int? = nil,
        questionsAnswered: Int? = nil,
        sessionStatus: String? = nil,
        endReason: String? = nil,
        completedTimestamp: Date? = nil
    ) async -> Bool {
        
        do {
            let updateData = SessionUpdateData(
                score: score,
                actualDurationMinutes: actualDurationMinutes,
                questionsAnswered: questionsAnswered,
                sessionStatus: sessionStatus,
                endReason: endReason,
                completedTimestamp: completedTimestamp
            )
            
            let response: InterviewSession = try await supabase
                .from("interview_sessions")
                .update(updateData)
                .eq("id", value: sessionId)
                .select()
                .single()
                .execute()
                .value
            
            // Update local array
            if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[index] = response
            }
            
            return true
            
        } catch {
            self.errorMessage = "Failed to update session"
            return false
        }
    }
    
    func deleteSession(_ session: InterviewSession) async -> Bool {
        do {
            try await supabase
                .from("interview_sessions")
                .delete()
                .eq("id", value: session.id)
                .execute()
            
            // Remove from local array
            sessions.removeAll { $0.id == session.id }
            
            return true
            
        } catch {
            self.errorMessage = "Failed to delete session"
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func refreshSessions() async {
        await loadSessions()
    }
    
    // MARK: - Sample Data (for development/testing)
    
    func addSampleData() async {
        let sampleSessions = [
            ("Technical", "iOS Development Practice", 78, 45, 12),
            ("Technical", "Data Structures Deep Dive", 85, 35, 10),
            ("Behavioral", "Leadership Experience", 92, 30, 8),
            ("Technical", "System Design Interview", 74, 50, 15),
            ("Behavioral", "Communication Skills", 88, 25, 6)
        ]
        
        for (category, name, score, duration, questions) in sampleSessions {
            _ = await createSession(
                category: category,
                sessionName: name,
                score: score,
                expectedDurationMinutes: duration,
                actualDurationMinutes: duration + Int.random(in: -5...5),
                questionsAnswered: questions,
                conversationId: "sample_conversation_\(UUID().uuidString.prefix(8))",
                sessionStatus: "completed",
                endReason: "manual"
            )
        }
    }
    
    private func createSampleSessions() -> [InterviewSession] {
        return [
            InterviewSession(
                id: UUID(),
                userId: UUID(),
                category: "Technical",
                sessionName: "iOS Development Practice",
                score: 78,
                expectedDurationMinutes: 45,
                actualDurationMinutes: 42,
                questionsAnswered: 12,
                createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
                conversationId: "sample_conv_123",
                completedTimestamp: Calendar.current.date(byAdding: .minute, value: -28, to: Date())!,
                sessionStatus: "completed",
                endReason: "manual"
            ),
            InterviewSession(
                id: UUID(),
                userId: UUID(),
                category: "Technical",
                sessionName: "Data Structures Deep Dive",
                score: 85,
                expectedDurationMinutes: 35,
                actualDurationMinutes: 38,
                questionsAnswered: 10,
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                conversationId: "sample_conv_456",
                completedTimestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
                sessionStatus: "completed",
                endReason: "timeout"
            ),
            InterviewSession(
                id: UUID(),
                userId: UUID(),
                category: "Behavioral",
                sessionName: "Leadership Experience",
                score: 92,
                expectedDurationMinutes: 30,
                actualDurationMinutes: 32,
                questionsAnswered: 8,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                conversationId: "sample_conv_789",
                completedTimestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                sessionStatus: "completed",
                endReason: "manual"
            )
        ]
    }
}

// MARK: - Helper Structs

// Updated InterviewSessionInsert struct
struct InterviewSessionInsert: Codable {
    let userId: UUID
    let category: String
    let sessionName: String
    let score: Int?
    let expectedDurationMinutes: Int
    let actualDurationMinutes: Int?
    let questionsAnswered: Int
    let conversationId: String?
    let sessionStatus: String
    let endReason: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case category
        case sessionName = "session_name"
        case score
        case expectedDurationMinutes = "expected_duration_minutes"
        case actualDurationMinutes = "actual_duration_minutes"
        case questionsAnswered = "questions_answered"
        case conversationId = "conversation_id"
        case sessionStatus = "session_status"
        case endReason = "end_reason"
    }
}

struct SessionUpdateData: Codable {
    let score: Int?
    let actualDurationMinutes: Int?
    let questionsAnswered: Int?
    let sessionStatus: String?
    let endReason: String?
    let completedTimestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case score
        case actualDurationMinutes = "actual_duration_minutes"
        case questionsAnswered = "questions_answered"
        case sessionStatus = "session_status"
        case endReason = "end_reason"
        case completedTimestamp = "completed_timestamp"
    }
    
    init(score: Int?, actualDurationMinutes: Int?, questionsAnswered: Int?, sessionStatus: String?, endReason: String?, completedTimestamp: Date?) {
        self.score = score
        self.actualDurationMinutes = actualDurationMinutes
        self.questionsAnswered = questionsAnswered
        self.sessionStatus = sessionStatus
        self.endReason = endReason
        
        // Convert Date to ISO string if provided
        if let timestamp = completedTimestamp {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.completedTimestamp = formatter.string(from: timestamp)
        } else {
            self.completedTimestamp = nil
        }
    }
}