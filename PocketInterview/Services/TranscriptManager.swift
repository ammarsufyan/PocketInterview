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
            // FIXED: Simplified query to get raw JSONB data
            let response: [TranscriptResponse] = try await supabase
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
            
            // FIXED: Convert response to proper InterviewTranscript objects
            self.transcripts = response.compactMap { transcriptResponse in
                return convertToInterviewTranscript(from: transcriptResponse)
            }
            
            print("✅ Loaded \(self.transcripts.count) transcripts")
            
            // Debug: Print loaded transcripts
            for transcript in self.transcripts {
                print("📄 Transcript: \(transcript.conversationId) - \(transcript.messageCount) messages")
            }
            
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
            let response: TranscriptResponse = try await supabase
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
            
            let transcript = convertToInterviewTranscript(from: response)
            print("✅ Loaded transcript for conversation \(conversationId): \(transcript?.messageCount ?? 0) messages")
            return transcript
            
        } catch {
            print("❌ Failed to load transcript for conversation \(conversationId): \(error)")
            return nil
        }
    }
    
    func getTranscriptForSession(_ session: InterviewSession) async -> InterviewTranscript? {
        guard let conversationId = session.conversationId else {
            print("⚠️ No conversation ID for session: \(session.sessionName)")
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
        let hasIt = transcripts.contains { $0.conversationId == conversationId }
        print("🔍 Checking transcript for \(conversationId): \(hasIt)")
        return hasIt
    }
    
    func getLocalTranscript(for conversationId: String) -> InterviewTranscript? {
        let transcript = transcripts.first { $0.conversationId == conversationId }
        print("🔍 Getting local transcript for \(conversationId): \(transcript != nil)")
        return transcript
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
    
    // MARK: - Data Conversion
    
    private func convertToInterviewTranscript(from response: TranscriptResponse) -> InterviewTranscript? {
        // FIXED: Parse transcript_data from JSONB with better error handling
        guard let transcriptData = parseTranscriptData(response.transcriptData) else {
            print("❌ Failed to parse transcript data for conversation: \(response.conversationId)")
            return nil
        }
        
        return InterviewTranscript(
            id: response.id,
            conversationId: response.conversationId,
            transcriptData: transcriptData,
            messageCount: response.messageCount,
            userMessageCount: response.userMessageCount,
            assistantMessageCount: response.assistantMessageCount,
            webhookTimestamp: response.webhookTimestamp,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )
    }
    
    private func parseTranscriptData(_ jsonData: Any) -> [TranscriptMessage]? {
        do {
            print("🔍 Parsing transcript data of type: \(type(of: jsonData))")
            
            // Handle different data types from Supabase JSONB
            let jsonArray: [[String: Any]]
            
            if let directArray = jsonData as? [[String: Any]] {
                jsonArray = directArray
                print("✅ Direct array conversion successful")
            } else if let dataObject = jsonData as? Data {
                jsonArray = try JSONSerialization.jsonObject(with: dataObject) as? [[String: Any]] ?? []
                print("✅ Data object conversion successful")
            } else {
                // Try to serialize and deserialize
                let data = try JSONSerialization.data(withJSONObject: jsonData)
                jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                print("✅ Serialization conversion successful")
            }
            
            print("📊 Found \(jsonArray.count) messages in transcript data")
            
            let messages = jsonArray.compactMap { messageDict -> TranscriptMessage? in
                guard let roleString = messageDict["role"] as? String,
                      let content = messageDict["content"] as? String,
                      let role = TranscriptMessage.MessageRole(rawValue: roleString) else {
                    print("⚠️ Skipping invalid message: \(messageDict)")
                    return nil
                }
                
                // Create message without ID (it will be generated automatically)
                return TranscriptMessage(role: role, content: content)
            }
            
            print("✅ Successfully parsed \(messages.count) transcript messages")
            return messages
            
        } catch {
            print("❌ Error parsing transcript data: \(error)")
            print("❌ Raw data: \(jsonData)")
            return nil
        }
    }
    
    // MARK: - Sample Data (for development/testing)
    
    private func createSampleTranscripts() -> [InterviewTranscript] {
        return [
            InterviewTranscript.sampleTechnicalTranscript(),
            InterviewTranscript.sampleBehavioralTranscript()
        ]
    }
}

// MARK: - Helper Structs for Database Response

private struct TranscriptResponse: Codable {
    let id: UUID
    let conversationId: String
    let transcriptData: Any // This will be JSONB from database
    let messageCount: Int
    let userMessageCount: Int
    let assistantMessageCount: Int
    let webhookTimestamp: Date
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case transcriptData = "transcript_data"
        case messageCount = "message_count"
        case userMessageCount = "user_message_count"
        case assistantMessageCount = "assistant_message_count"
        case webhookTimestamp = "webhook_timestamp"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        messageCount = try container.decode(Int.self, forKey: .messageCount)
        userMessageCount = try container.decode(Int.self, forKey: .userMessageCount)
        assistantMessageCount = try container.decode(Int.self, forKey: .assistantMessageCount)
        webhookTimestamp = try container.decode(Date.self, forKey: .webhookTimestamp)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // FIXED: Better handling of JSONB data from Supabase
        transcriptData = try container.decode(AnyCodable.self, forKey: .transcriptData).value
    }
}

// FIXED: Improved AnyCodable helper for decoding JSONB
private struct AnyCodable: Codable {
    let value: Any
    
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
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if value is NSNull {
            try container.encodeNil()
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
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