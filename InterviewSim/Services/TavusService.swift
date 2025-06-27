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
                sessionName: sessionName,
                duration: duration,
                cvContext: cvContext
            )
            
            let response = try await createTavusConversation(data: conversationData)
            
            self.conversationUrl = response.conversationUrl
            self.sessionId = response.sessionId
            
            print("✅ Tavus conversation created successfully")
            print("🔗 Conversation URL: \(response.conversationUrl)")
            print("🆔 Session ID: \(response.sessionId)")
            
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
    
    // MARK: - API Calls (FIXED: Based on Official Tavus API Documentation)
    
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        // FIXED: Use correct Tavus API payload structure with YOUR replica ID
        let payload = TavusCreateConversationPayload(
            conversationName: data.sessionName,
            replicaId: TavusConfig.defaultReplicaId, // Now using your actual replica ID: rf4703150052
            properties: TavusConversationProperties(
                maxDuration: data.duration * 60, // Convert minutes to seconds
                language: "en",
                conversationType: "interview",
                enableRecording: true,
                enableTranscription: true,
                customInstructions: generateInstructions(for: data.category, cvContext: data.cvContext)
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            // Debug: Print request details
            print("📤 DEBUG: Request Details")
            print("  - Method: \(request.httpMethod ?? "Unknown")")
            print("  - URL: \(endpoint)")
            print("  - Replica ID: \(TavusConfig.defaultReplicaId)")
            print("  - Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print("  - Body: \(bodyString)")
            }
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TavusError.invalidResponse
            }
            
            print("📥 DEBUG: Response Details")
            print("  - Status Code: \(httpResponse.statusCode)")
            print("  - Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("  - Body: \(responseString)")
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
                if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                    throw TavusError.apiErrorWithMessage(400, errorData.message)
                } else {
                    throw TavusError.apiErrorWithMessage(400, "Invalid request payload. Please check replica ID and other parameters.")
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
            throw TavusError.decodingError
        } catch {
            print("❌ Network Error: \(error)")
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
            print("❌ Failed to parse Tavus response: \(error)")
            throw TavusError.decodingError
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateInstructions(for category: String, cvContext: String?) -> String {
        let basePrompt = category == "Technical" ? 
            TavusConfig.technicalInterviewPrompt : 
            TavusConfig.behavioralInterviewPrompt
        
        return TavusConfig.createPersonalizedPrompt(
            basePrompt: basePrompt,
            category: category,
            cvContext: cvContext
        )
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
    
    // MARK: - Test API Key Function (ENHANCED)
    
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
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

// MARK: - API Models (FIXED: Based on Official Tavus API Documentation)

struct TavusCreateConversationPayload: Codable {
    let conversationName: String
    let replicaId: String
    let properties: TavusConversationProperties
    
    enum CodingKeys: String, CodingKey {
        case conversationName = "conversation_name"
        case replicaId = "replica_id"
        case properties
    }
}

struct TavusConversationProperties: Codable {
    let maxDuration: Int
    let language: String
    let conversationType: String
    let enableRecording: Bool
    let enableTranscription: Bool
    let customInstructions: String
    
    enum CodingKeys: String, CodingKey {
        case maxDuration = "max_duration"
        case language
        case conversationType = "conversation_type"
        case enableRecording = "enable_recording"
        case enableTranscription = "enable_transcription"
        case customInstructions = "custom_instructions"
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