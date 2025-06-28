//
//  TavusService.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import Combine

@MainActor
class TavusService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var conversationUrl: String?
    @Published var sessionId: String?
    @Published var createdSessionId: UUID? // Track the created Supabase session
    
    private let envConfig = EnvironmentConfig.shared
    private var isCreatingSession = false
    
    // MARK: - Create Conversation Session
    
    func createConversationSession(
        category: String,
        sessionName: String,
        duration: Int,
        cvContext: String? = nil,
        historyManager: InterviewHistoryManager
    ) async -> Bool {
        guard !isCreatingSession else {
            return false
        }
        
        isCreatingSession = true
        isLoading = true
        errorMessage = nil
        
        defer {
            isCreatingSession = false
        }
        
        do {
            let trimmedSessionName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSessionName.isEmpty else {
                throw TavusConfigError.invalidConfiguration
            }
            
            guard TavusConfig.validateConfiguration() else {
                throw TavusConfigError.invalidConfiguration
            }
            
            guard TavusConfig.validateReplicaId() else {
                throw TavusConfigError.invalidReplicaId
            }
            
            let conversationData = TavusConversationRequest(
                category: category,
                sessionName: trimmedSessionName,
                duration: duration,
                cvContext: cvContext
            )
            
            // Create Tavus conversation
            let response = try await createTavusConversation(data: conversationData)
            
            self.conversationUrl = response.conversationUrl
            self.sessionId = response.sessionId
            
            // Immediately create Supabase session record with conversation_id
            let supabaseSession = await historyManager.createSession(
                category: category,
                sessionName: trimmedSessionName,
                score: nil, // Will be updated later
                expectedDurationMinutes: duration, // Planned duration
                actualDurationMinutes: nil, // Will be set when completed
                questionsAnswered: 0, // Will be updated later
                conversationId: response.sessionId,
                sessionStatus: "created",
                endReason: nil
            )
            
            // Store the created session ID for later updates
            if let session = supabaseSession {
                self.createdSessionId = session.id
                print("✅ Created Supabase session record: \(session.id)")
            } else {
                print("⚠️ Failed to create Supabase session record")
            }
            
            isLoading = false
            return true
            
        } catch let error as TavusConfigError {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        } catch {
            self.errorMessage = "Failed to create interview session: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - End Conversation Session
    
    func endConversationSession() async -> Bool {
        guard let sessionId = sessionId else {
            return false
        }
        
        do {
            let success = try await endTavusConversation(conversationId: sessionId)
            
            if success {
                self.conversationUrl = nil
                self.sessionId = nil
            }
            
            return success
            
        } catch {
            self.conversationUrl = nil
            self.sessionId = nil
            return false
        }
    }
    
    // MARK: - Update Session with Final Data
    
    func updateSessionWithFinalData(
        historyManager: InterviewHistoryManager,
        actualDurationMinutes: Int,
        questionsAnswered: Int = 0,
        score: Int? = nil,
        endReason: String = "completed"
    ) async -> Bool {
        guard let sessionId = createdSessionId else {
            print("⚠️ No session ID to update")
            return false
        }
        
        let success = await historyManager.updateSession(
            sessionId: sessionId,
            score: score,
            actualDurationMinutes: actualDurationMinutes,
            questionsAnswered: questionsAnswered,
            sessionStatus: "completed",
            endReason: endReason,
            completedTimestamp: Date()
        )
        
        if success {
            print("✅ Updated session with final data")
        } else {
            print("❌ Failed to update session with final data")
        }
        
        return success
    }
    
    // MARK: - API Calls
    
    private func createTavusConversation(data: TavusConversationRequest) async throws -> TavusConversationResponse {
        let endpoint = "https://tavusapi.com/v2/conversations"
        
        let apiKey = try TavusConfig.getApiKey()
        
        guard let url = URL(string: endpoint) else {
            throw TavusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        let shortContext = generateShortInstructions(for: data.category, cvContext: data.cvContext)
        
        // Generate webhook URL for transcript callbacks
        let webhookUrl = generateWebhookUrl()
        
        let payload = TavusCreateConversationPayload(
            replicaId: TavusConfig.defaultReplicaId,
            conversationName: data.sessionName,
            conversationalContext: shortContext,
            callbackUrl: webhookUrl, // Added callback_url parameter
            properties: TavusConversationProperties(
                maxCallDuration: data.duration * 60,
                enableRecording: false,
                enableClosedCaptions: true,
                language: "english",
                participantLeftTimeout: 10,
                participantAbsentTimeout: 60
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavusError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                return try parseSuccessResponse(responseData)
                
            case 401:
                throw TavusError.apiErrorWithMessage(401, "Invalid API key. Please check your TAVUS_API_KEY in .env file.")
                
            case 404:
                throw TavusError.apiErrorWithMessage(404, "Replica not found. Please verify replica ID 'rf4703150052' exists in your Tavus dashboard.")
                
            case 400:
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(400, "Tavus API Error: \(errorData.message)")
                } else {
                    throw TavusError.apiErrorWithMessage(400, "Invalid request. Session name: '\(data.sessionName)'")
                }
                
            default:
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, errorData.message)
                } else {
                    let responseString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, responseString)
                }
            }
            
        } catch let encodingError as EncodingError {
            throw TavusError.decodingError
        } catch {
            throw error
        }
    }
    
    // MARK: - End Conversation API Call
    
    private func endTavusConversation(conversationId: String) async throws -> Bool {
        let endpoint = "https://tavusapi.com/v2/conversations/\(conversationId)/end"
        
        let apiKey = try TavusConfig.getApiKey()
        
        guard let url = URL(string: endpoint) else {
            throw TavusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        let endPayload = [
            "reason": "interview_completed"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: endPayload)
            request.httpBody = jsonData
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavusError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200, 201, 204:
                return true
                
            case 404:
                return true // Consider this a success since conversation is not active
                
            case 401:
                throw TavusError.apiErrorWithMessage(401, "Invalid API key for ending conversation")
                
            case 400:
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(400, errorData.message)
                } else {
                    throw TavusError.apiErrorWithMessage(400, "Invalid conversation ID or conversation already ended")
                }
                
            default:
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, errorData.message)
                } else {
                    let responseString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, responseString)
                }
            }
            
        } catch {
            throw error
        }
    }
    
    private func parseSuccessResponse(_ data: Data) throws -> TavusConversationResponse {
        do {
            let tavusResponse = try JSONDecoder().decode(TavusAPIResponse.self, from: data)
            
            return TavusConversationResponse(
                conversationUrl: tavusResponse.conversationUrl,
                sessionId: tavusResponse.conversationId
            )
        } catch {
            throw TavusError.decodingError
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateShortInstructions(for category: String, cvContext: String?) -> String {
        let baseInstructions: String
        
        switch category {
        case "Technical":
            baseInstructions = """
            You are a technical interviewer. Ask coding and problem-solving questions. 
            Focus on algorithms, data structures, and system design. 
            Encourage the candidate to think out loud and explain their approach.
            """
        case "Behavioral":
            baseInstructions = """
            You are conducting a behavioral interview. Ask about past experiences using the STAR method. 
            Focus on leadership, teamwork, and problem-solving situations. 
            Ask for specific examples and results.
            """
        default:
            baseInstructions = """
            You are an experienced interviewer. Ask relevant questions about the candidate's background. 
            Be encouraging and help them showcase their skills.
            """
        }
        
        if let cvContext = cvContext, !cvContext.isEmpty {
            let shortCvSummary = String(cvContext.prefix(200))
            return baseInstructions + " Candidate background: \(shortCvSummary)..."
        }
        
        return baseInstructions
    }
    
    private func generateWebhookUrl() -> String {
        // Get Supabase URL from environment
        let supabaseUrl = EnvironmentConfig.shared.supabaseURL ?? "https://your-project.supabase.co"
        
        // Construct webhook URL for the edge function
        return "\(supabaseUrl)/functions/v1/tavus-transcript-webhook"
    }
    
    func clearSession() {
        conversationUrl = nil
        sessionId = nil
        createdSessionId = nil
        errorMessage = nil
        isLoading = false
        isCreatingSession = false
    }
    
    func checkConfiguration() -> Bool {
        return TavusConfig.validateConfiguration() && TavusConfig.validateReplicaId()
    }
    
    func testApiKey() async -> Bool {
        do {
            let apiKey = try TavusConfig.getApiKey()
            let testEndpoint = "https://tavusapi.com/v2/replicas"
            
            guard let url = URL(string: testEndpoint) else {
                return false
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200, 201:
                        return true
                    case 401:
                        return false
                    case 404:
                        return true
                    default:
                        return false
                    }
                }
            } catch {
                return false
            }
            
            return false
            
        } catch {
            return false
        }
    }
}

// MARK: - Data Models

struct TavusConversationRequest {
    let category: String
    let sessionName: String
    let duration: Int
    let cvContext: String?
}

struct TavusConversationResponse {
    let conversationUrl: String
    let sessionId: String
}

// MARK: - API Models

struct TavusCreateConversationPayload: Codable {
    let replicaId: String
    let conversationName: String
    let conversationalContext: String
    let callbackUrl: String // Added callback_url parameter
    let properties: TavusConversationProperties
    
    enum CodingKeys: String, CodingKey {
        case replicaId = "replica_id"
        case conversationName = "conversation_name"
        case conversationalContext = "conversational_context"
        case callbackUrl = "callback_url" // Maps to callback_url in JSON
        case properties
    }
}

struct TavusConversationProperties: Codable {
    let maxCallDuration: Int
    let enableRecording: Bool
    let enableClosedCaptions: Bool
    let language: String
    let participantLeftTimeout: Int
    let participantAbsentTimeout: Int
    
    enum CodingKeys: String, CodingKey {
        case maxCallDuration = "max_call_duration"
        case enableRecording = "enable_recording"
        case enableClosedCaptions = "enable_closed_captions"
        case language
        case participantLeftTimeout = "participant_left_timeout"
        case participantAbsentTimeout = "participant_absent_timeout"
    }
}

struct TavusAPIResponse: Codable {
    let conversationId: String
    let conversationUrl: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case conversationUrl = "conversation_url"
        case status
    }
}

struct TavusErrorResponse: Codable {
    let message: String
    let code: String?
    let error: String?
}

// MARK: - Error Types

enum TavusError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case apiErrorWithMessage(Int, String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API Error: \(code)"
        case .apiErrorWithMessage(let code, let message):
            return "API Error \(code): \(message)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}