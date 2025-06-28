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
            // FIXED: Use a simpler approach - get raw JSON data directly
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
        // FIXED: Parse transcript_data from raw JSON with better error handling
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
    
    private func parseTranscriptData(_ rawData: Any) -> [TranscriptMessage]? {
        do {
            print("🔍 Parsing transcript data of type: \(type(of: rawData))")
            
            // Handle different data types from Supabase JSONB
            let jsonData: Data
            
            if let dataObject = rawData as? Data {
                jsonData = dataObject
                print("✅ Using Data object directly")
            } else if let stringData = rawData as? String {
                guard let data = stringData.data(using: .utf8) else {
                    print("❌ Failed to convert string to data")
                    return nil
                }
                jsonData = data
                print("✅ Converted string to data")
            } else {
                // Try to serialize the object to JSON data
                jsonData = try JSONSerialization.data(withJSONObject: rawData, options: [])
                print("✅ Serialized object to JSON data")
            }
            
            // Parse the JSON data
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
            
            guard let messageArray = jsonArray else {
                print("❌ Failed to parse as array of dictionaries")
                return nil
            }
            
            print("📊 Found \(messageArray.count) messages in transcript data")
            
            let messages = messageArray.compactMap { messageDict -> TranscriptMessage? in
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
            print("❌ Raw data type: \(type(of: rawData))")
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

// FIXED: Completely simplified TranscriptResponse that works with Supabase
private struct TranscriptResponse: Codable {
    let id: UUID
    let conversationId: String
    let transcriptData: [[String: String]] // FIXED: Use proper type that can be decoded
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