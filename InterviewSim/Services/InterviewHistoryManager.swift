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
        durationMinutes: Int,
        questionsAnswered: Int = 0,
        sessionData: [String: Any] = [:]
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
                durationMinutes: durationMinutes,
                questionsAnswered: questionsAnswered,
                sessionData: sessionData
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
        questionsAnswered: Int? = nil,
        sessionData: [String: Any]? = nil
    ) async -> Bool {
        
        do {
            let updateData = SessionUpdateData(
                score: score,
                questionsAnswered: questionsAnswered,
                sessionData: sessionData
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
                durationMinutes: duration,
                questionsAnswered: questions,
                sessionData: [
                    "sample": true,
                    "created_by": "sample_data_generator"
                ]
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
                durationMinutes: 45,
                questionsAnswered: 12,
                sessionData: SafeAnyCodable([:]),
                createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
            ),
            InterviewSession(
                id: UUID(),
                userId: UUID(),
                category: "Technical",
                sessionName: "Data Structures Deep Dive",
                score: 85,
                durationMinutes: 35,
                questionsAnswered: 10,
                sessionData: SafeAnyCodable([:]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
            ),
            InterviewSession(
                id: UUID(),
                userId: UUID(),
                category: "Behavioral",
                sessionName: "Leadership Experience",
                score: 92,
                durationMinutes: 30,
                questionsAnswered: 8,
                sessionData: SafeAnyCodable([:]),
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            )
        ]
    }
}

// MARK: - Helper Structs

// Simplified InterviewSessionInsert struct
struct InterviewSessionInsert: Codable {
    let userId: UUID
    let category: String
    let sessionName: String
    let score: Int?
    let durationMinutes: Int
    let questionsAnswered: Int
    let sessionData: String // Store as JSON string
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case category
        case sessionName = "session_name"
        case score
        case durationMinutes = "duration_minutes"
        case questionsAnswered = "questions_answered"
        case sessionData = "session_data"
    }
    
    // Initialize with proper JSON encoding
    init(userId: UUID, category: String, sessionName: String, score: Int?, durationMinutes: Int, questionsAnswered: Int, sessionData: [String: Any]) {
        self.userId = userId
        self.category = category
        self.sessionName = sessionName
        self.score = score
        self.durationMinutes = durationMinutes
        self.questionsAnswered = questionsAnswered
        
        // Convert [String: Any] to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: sessionData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.sessionData = jsonString
        } else {
            self.sessionData = "{}"
        }
    }
}

struct SessionUpdateData: Codable {
    let score: Int?
    let questionsAnswered: Int?
    let sessionData: String?
    
    enum CodingKeys: String, CodingKey {
        case score
        case questionsAnswered = "questions_answered"
        case sessionData = "session_data"
    }
    
    init(score: Int?, questionsAnswered: Int?, sessionData: [String: Any]?) {
        self.score = score
        self.questionsAnswered = questionsAnswered
        
        // Convert sessionData to JSON string if provided
        if let sessionData = sessionData {
            if let jsonData = try? JSONSerialization.data(withJSONObject: sessionData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.sessionData = jsonString
            } else {
                self.sessionData = nil
            }
        } else {
            self.sessionData = nil
        }
    }
}

// Completely rewritten SafeAnyCodable to avoid encoding issues
struct SafeAnyCodable: Codable {
    private let jsonString: String
    
    init(_ value: Any) {
        if let data = try? JSONSerialization.data(withJSONObject: value),
           let string = String(data: data, encoding: .utf8) {
            self.jsonString = string
        } else {
            self.jsonString = "{}"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self.jsonString = string
        } else if let dict = try? container.decode([String: String].self) {
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let string = String(data: data, encoding: .utf8) {
                self.jsonString = string
            } else {
                self.jsonString = "{}"
            }
        } else {
            self.jsonString = "{}"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(jsonString)
    }
    
    // Helper to get the original value back
    var value: Any {
        guard let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return [:]
        }
        return object
    }
}