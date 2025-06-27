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
            print("✅ Loaded \(response.count) sessions from Supabase")
        } catch {
            print("❌ Error loading sessions: \(error)")
            self.errorMessage = "Failed to load interview history"
            
            // Fallback to sample data for development
            self.sessions = createSampleSessions()
        }
        
        isLoading = false
    }
    
    func createSession(
        category: String,
        sessionName: String,
        score: Int? = nil,
        durationMinutes: Int,
        questionsAnswered: Int = 0,
        sessionData: [String: Any] = [:]
    ) async -> InterviewSession? {
        
        do {
            // Get current user - FIXED: Call the function and access user property
            let currentUser = try await supabase.auth.user
            
            let newSession = InterviewSessionInsert(
                userId: currentUser.id,
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
            
            print("✅ Created session: \(response.sessionName)")
            return response
            
        } catch {
            print("❌ Error creating session: \(error)")
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
            var updates: [String: Any] = [:]
            
            if let score = score {
                updates["score"] = score
            }
            if let questionsAnswered = questionsAnswered {
                updates["questions_answered"] = questionsAnswered
            }
            if let sessionData = sessionData {
                updates["session_data"] = sessionData
            }
            
            let response: InterviewSession = try await supabase
                .from("interview_sessions")
                .update(updates)
                .eq("id", value: sessionId)
                .select()
                .single()
                .execute()
                .value
            
            // Update local array
            if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[index] = response
            }
            
            print("✅ Updated session: \(response.sessionName)")
            return true
            
        } catch {
            print("❌ Error updating session: \(error)")
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
            
            print("✅ Deleted session: \(session.sessionName)")
            return true
            
        } catch {
            print("❌ Error deleting session: \(error)")
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
            await createSession(
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
                sessionData: AnyCodable([:]),
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
                sessionData: AnyCodable([:]),
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
                sessionData: AnyCodable([:]),
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            )
        ]
    }
}

// MARK: - Helper Structs

struct InterviewSessionInsert: Codable {
    let userId: UUID
    let category: String
    let sessionName: String
    let score: Int?
    let durationMinutes: Int
    let questionsAnswered: Int
    let sessionData: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case category
        case sessionName = "session_name"
        case score
        case durationMinutes = "duration_minutes"
        case questionsAnswered = "questions_answered"
        case sessionData = "session_data"
    }
    
    // FIXED: Custom encoding for sessionData
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        try container.encode(category, forKey: .category)
        try container.encode(sessionName, forKey: .sessionName)
        try container.encodeIfPresent(score, forKey: .score)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(questionsAnswered, forKey: .questionsAnswered)
        
        // Convert [String: Any] to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: sessionData)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .sessionData)
    }
}

// Helper for handling dynamic JSON data
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            let codableArray = arrayValue.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictValue as [String: Any]:
            let codableDict = dictValue.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            try container.encode([String: String]())
        }
    }
}