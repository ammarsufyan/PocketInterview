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
    
    private let envConfig = EnvironmentConfig.shared
    
    // MARK: - Create Conversation Session
    
    func createConversationSession(
        category: String,
        sessionName: String,
        duration: Int,
        cvContext: String? = nil
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // ENHANCED: Validate session name first
            let trimmedSessionName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSessionName.isEmpty else {
                throw TavusConfigError.invalidConfiguration
            }
            
            print("🔧 DEBUG: Session Name Validation")
            print("  - Original: '\(sessionName)'")
            print("  - Trimmed: '\(trimmedSessionName)'")
            print("  - Length: \(trimmedSessionName.count)")
            
            // Enhanced debug: Print configuration
            print("🔧 DEBUG: Tavus Configuration Check")
            envConfig.printLoadedVariables()
            
            // Validate configuration first
            guard TavusConfig.validateConfiguration() else {
                throw TavusConfigError.invalidConfiguration
            }
            
            // Validate replica ID
            guard TavusConfig.validateReplicaId() else {
                throw TavusConfigError.invalidReplicaId
            }
            
            let conversationData = TavusConversationRequest(
                category: category,
                sessionName: trimmedSessionName, // Use trimmed name
                duration: duration,
                cvContext: cvContext
            )
            
            let response = try await createTavusConversation(data: conversationData)
            
            self.conversationUrl = response.conversationUrl
            self.sessionId = response.sessionId
            
            print("✅ Tavus conversation created successfully")
            print("🔗 Conversation URL: \(response.conversationUrl)")
            print("🆔 Session ID: \(response.sessionId)")
            print("📝 Session Name Used: '\(trimmedSessionName)'")
            
            isLoading = false
            return true
            
        } catch let error as TavusConfigError {
            print("❌ Tavus configuration error: \(error)")
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        } catch {
            print("❌ Error creating Tavus conversation: \(error)")
            self.errorMessage = "Failed to create interview session: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - End Conversation Session
    
    func endConversationSession() async -> Bool {
        guard let sessionId = sessionId else {
            print("❌ Cannot end conversation: No session ID available")
            return false
        }
        
        print("🔚 Attempting to end Tavus conversation: \(sessionId)")
        
        do {
            let success = try await endTavusConversation(conversationId: sessionId)
            
            if success {
                print("✅ Tavus conversation ended successfully")
                // Clear session data after successful end
                self.conversationUrl = nil
                self.sessionId = nil
            } else {
                print("⚠️ Tavus conversation end returned false")
            }
            
            return success
            
        } catch {
            print("❌ Error ending Tavus conversation: \(error)")
            // Even if API call fails, we should clear local session data
            self.conversationUrl = nil
            self.sessionId = nil
            return false
        }
    }
    
    // MARK: - API Calls
    
    private func createTavusConversation(data: TavusConversationRequest) async throws -> TavusConversationResponse {
        // FIXED: Use official Tavus API endpoint
        let endpoint = "https://tavusapi.com/v2/conversations"
        
        let apiKey = try TavusConfig.getApiKey()
        
        print("🔑 DEBUG: API Key Detailed Analysis")
        print("  - Raw Length: \(apiKey.count)")
        print("  - First 15 chars: \(String(apiKey.prefix(15)))...")
        print("  - Last 10 chars: ...\(String(apiKey.suffix(10)))")
        
        guard let url = URL(string: endpoint) else {
            throw TavusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // FIXED: Use x-api-key header as per Tavus documentation
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        // FIXED: Generate shorter, concise conversational context
        let shortContext = generateShortInstructions(for: data.category, cvContext: data.cvContext)
        
        // ENHANCED: Debug session name before creating payload
        print("🔧 DEBUG: Pre-Payload Session Name Check")
        print("  - Session Name: '\(data.sessionName)'")
        print("  - Is Empty: \(data.sessionName.isEmpty)")
        print("  - Character Count: \(data.sessionName.count)")
        
        // ENHANCED: Use user's session name directly in conversation_name
        let payload = TavusCreateConversationPayload(
            replicaId: TavusConfig.defaultReplicaId,
            conversationName: data.sessionName, // CRITICAL: Use exact user input
            conversationalContext: shortContext,
            properties: TavusConversationProperties(
                maxCallDuration: data.duration * 60, // Convert minutes to seconds
                enableRecording: false, // Disable recording for privacy
                enableClosedCaptions: true,
                language: "english",
                participantLeftTimeout: 10,  // 10 seconds timeout when participant leaves
                participantAbsentTimeout: 60 // 60 seconds timeout if no one joins
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            // ENHANCED: Detailed payload debugging
            print("📤 DEBUG: Complete Request Analysis")
            print("  - Method: \(request.httpMethod ?? "Unknown")")
            print("  - URL: \(endpoint)")
            print("  - Replica ID: \(TavusConfig.defaultReplicaId)")
            print("  - Session Name in Payload: '\(data.sessionName)'")
            print("  - Context Length: \(shortContext.count) characters")
            print("  - Participant Left Timeout: 10 seconds")
            print("  - Participant Absent Timeout: 60 seconds")
            print("  - Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            // CRITICAL: Show exact JSON payload being sent
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("📦 EXACT JSON PAYLOAD:")
                print(bodyString)
                
                // ENHANCED: Parse and verify the JSON contains our session name
                if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    if let conversationName = jsonObject["conversation_name"] as? String {
                        print("✅ Verified conversation_name in JSON: '\(conversationName)'")
                    } else {
                        print("❌ conversation_name NOT FOUND in JSON payload!")
                    }
                }
            }
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavusError.invalidResponse
            }
            
            print("📥 DEBUG: Response Details")
            print("  - Status Code: \(httpResponse.statusCode)")
            print("  - Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("  - Response Body: \(responseString)")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200, 201:
                // Success - parse response
                return try parseSuccessResponse(responseData)
                
            case 401:
                print("🚨 401 UNAUTHORIZED - API Key Issues:")
                print("  - Check if API key is complete and valid")
                print("  - Verify API key format matches Tavus requirements")
                print("  - Current API key preview: \(String(apiKey.prefix(15)))...")
                throw TavusError.apiErrorWithMessage(401, "Invalid API key. Please check your TAVUS_API_KEY in .env file.")
                
            case 404:
                print("🚨 404 NOT FOUND - Possible Issues:")
                print("  - Endpoint: \(endpoint)")
                print("  - Replica ID: \(TavusConfig.defaultReplicaId)")
                print("  - Check if replica ID exists in your Tavus dashboard")
                throw TavusError.apiErrorWithMessage(404, "Replica not found. Please verify replica ID 'rf4703150052' exists in your Tavus dashboard.")
                
            case 400:
                print("🚨 400 BAD REQUEST - Payload Issues:")
                print("  - Session Name: '\(data.sessionName)'")
                print("  - Context Length: \(shortContext.count) characters")
                print("  - Duration: \(data.duration) minutes")
                
                // ENHANCED: Try to parse specific error from Tavus
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    print("  - Tavus Error: \(errorData.message)")
                    throw TavusError.apiErrorWithMessage(400, "Tavus API Error: \(errorData.message)")
                } else {
                    throw TavusError.apiErrorWithMessage(400, "Invalid request. Session name: '\(data.sessionName)'")
                }
                
            default:
                // Try to parse error response
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, errorData.message)
                } else {
                    let responseString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, responseString)
                }
            }
            
        } catch let encodingError as EncodingError {
            print("❌ JSON Encoding Error: \(encodingError)")
            print("  - Session Name: '\(data.sessionName)'")
            throw TavusError.decodingError
        } catch {
            print("❌ Network Error: \(error)")
            throw error
        }
    }
    
    // MARK: - End Conversation API Call
    
    private func endTavusConversation(conversationId: String) async throws -> Bool {
        let endpoint = "https://tavusapi.com/v2/conversations/\(conversationId)/end"
        
        let apiKey = try TavusConfig.getApiKey()
        
        print("🔚 DEBUG: End Conversation Request")
        print("  - Conversation ID: \(conversationId)")
        print("  - Endpoint: \(endpoint)")
        print("  - API Key: \(String(apiKey.prefix(15)))...")
        
        guard let url = URL(string: endpoint) else {
            throw TavusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        // End conversation API typically doesn't require a body, but let's add empty JSON
        request.httpBody = "{}".data(using: .utf8)
        
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavusError.invalidResponse
            }
            
            print("📥 DEBUG: End Conversation Response")
            print("  - Status Code: \(httpResponse.statusCode)")
            print("  - Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("  - Body: \(responseString)")
            }
            
            // Handle response codes for end conversation
            switch httpResponse.statusCode {
            case 200, 201, 204:
                // Success - conversation ended
                print("✅ Conversation ended successfully")
                return true
                
            case 404:
                // Conversation not found or already ended
                print("⚠️ Conversation not found or already ended")
                return true // Consider this a success since conversation is not active
                
            case 401:
                print("🚨 401 UNAUTHORIZED - API Key Issues")
                throw TavusError.apiErrorWithMessage(401, "Invalid API key for ending conversation")
                
            case 400:
                print("🚨 400 BAD REQUEST - Invalid conversation ID or state")
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(400, errorData.message)
                } else {
                    throw TavusError.apiErrorWithMessage(400, "Invalid conversation ID or conversation already ended")
                }
                
            default:
                // Try to parse error response
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, errorData.message)
                } else {
                    let responseString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                    throw TavusError.apiErrorWithMessage(httpResponse.statusCode, responseString)
                }
            }
            
        } catch {
            print("❌ Network Error ending conversation: \(error)")
            throw error
        }
    }
    
    private func parseSuccessResponse(_ data: Data) throws -> TavusConversationResponse {
        do {
            let tavusResponse = try JSONDecoder().decode(TavusAPIResponse.self, from: data)
            
            // ENHANCED: Log the response to verify session name
            print("✅ Parsed Tavus Response:")
            print("  - Conversation ID: \(tavusResponse.conversationId)")
            print("  - Conversation URL: \(tavusResponse.conversationUrl)")
            print("  - Status: \(tavusResponse.status)")
            
            return TavusConversationResponse(
                conversationUrl: tavusResponse.conversationUrl,
                sessionId: tavusResponse.conversationId
            )
        } catch {
            print("❌ Failed to parse Tavus response: \(error)")
            print("❌ Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw TavusError.decodingError
        }
    }
    
    // MARK: - Helper Methods (FIXED: Shorter Instructions)
    
    private func generateShortInstructions(for category: String, cvContext: String?) -> String {
        // FIXED: Much shorter, concise instructions to avoid payload size issues
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
        
        // Add brief CV context if available (keep it short)
        if let cvContext = cvContext, !cvContext.isEmpty {
            let shortCvSummary = String(cvContext.prefix(200)) // Limit to 200 chars
            return baseInstructions + " Candidate background: \(shortCvSummary)..."
        }
        
        return baseInstructions
    }
    
    private func generateInstructions(for category: String, cvContext: String?) -> String {
        // Keep the old method for backward compatibility, but use short version
        return generateShortInstructions(for: category, cvContext: cvContext)
    }
    
    func clearSession() {
        conversationUrl = nil
        sessionId = nil
        errorMessage = nil
    }
    
    // MARK: - Configuration Check
    
    func checkConfiguration() -> Bool {
        return TavusConfig.validateConfiguration() && TavusConfig.validateReplicaId()
    }
    
    // MARK: - Test API Key Function (ENHANCED with x-api-key)
    
    func testApiKey() async -> Bool {
        do {
            let apiKey = try TavusConfig.getApiKey()
            
            // Test with official Tavus API endpoint
            let testEndpoint = "https://tavusapi.com/v2/replicas"
            
            print("🧪 Testing Tavus API Key...")
            print("🔑 Current API key preview: \(String(apiKey.prefix(15)))...")
            print("🌐 Testing endpoint: \(testEndpoint)")
            print("🎭 Using replica ID: \(TavusConfig.defaultReplicaId)")
            
            guard let url = URL(string: testEndpoint) else {
                print("❌ Invalid test URL: \(testEndpoint)")
                return false
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            // FIXED: Use x-api-key header for testing
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 API Test Result: Status \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 200, 201:
                        print("✅ API Key is valid!")
                        print("🎭 Replica ID validation: \(TavusConfig.validateReplicaId() ? "✅ Valid" : "⚠️ Check format")")
                        return true
                    case 401:
                        print("❌ Invalid API key. Please check your TAVUS_API_KEY in .env file.")
                        return false
                    case 404:
                        print("⚠️ Endpoint not found, but API key might be valid")
                        print("🎭 Replica ID validation: \(TavusConfig.validateReplicaId() ? "✅ Valid" : "⚠️ Check format")")
                        return true // Sometimes 404 means endpoint doesn't exist but auth is OK
                    default:
                        print("⚠️ Unexpected status \(httpResponse.statusCode)")
                        return false
                    }
                }
            } catch {
                print("❌ Network error: \(error)")
                return false
            }
            
            return false
            
        } catch {
            print("❌ API Key test failed: \(error)")
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

// MARK: - API Models (ENHANCED: Added Timeout Properties)

struct TavusCreateConversationPayload: Codable {
    let replicaId: String
    let conversationName: String
    let conversationalContext: String
    let properties: TavusConversationProperties
    
    enum CodingKeys: String, CodingKey {
        case replicaId = "replica_id"
        case conversationName = "conversation_name"
        case conversationalContext = "conversational_context"
        case properties
    }
}

struct TavusConversationProperties: Codable {
    let maxCallDuration: Int
    let enableRecording: Bool
    let enableClosedCaptions: Bool
    let language: String
    let participantLeftTimeout: Int    // Timeout when participant leaves (seconds)
    let participantAbsentTimeout: Int  // Timeout when no one joins (seconds)
    
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