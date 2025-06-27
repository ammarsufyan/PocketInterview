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
    
    // MARK: - API Calls
    
    private func createTavusConversation(data: TavusConversationRequest) async throws -> TavusConversationResponse {
        // UPDATED: Try multiple endpoint variations
        let possibleEndpoints = [
            "https://tavusapi.com/v2/conversations",
            "https://api.tavus.io/v2/conversations", 
            "https://platform.tavus.io/api/v2/conversations",
            "https://tavusapi.com/conversations",
            "https://api.tavus.io/conversations"
        ]
        
        let apiKey = try TavusConfig.getApiKey()
        
        print("🔑 DEBUG: API Key Detailed Analysis")
        print("  - Raw Length: \(apiKey.count)")
        print("  - First 15 chars: \(String(apiKey.prefix(15)))...")
        print("  - Last 10 chars: ...\(String(apiKey.suffix(10)))")
        print("  - Contains underscore: \(apiKey.contains("_"))")
        print("  - Contains dash: \(apiKey.contains("-"))")
        print("  - Is alphanumeric: \(apiKey.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" })")
        
        // Try each endpoint until one works
        for (index, endpoint) in possibleEndpoints.enumerated() {
            print("🌐 DEBUG: Trying endpoint \(index + 1)/\(possibleEndpoints.count): \(endpoint)")
            
            do {
                let response = try await makeAPIRequest(to: endpoint, with: apiKey, data: data)
                print("✅ SUCCESS: Endpoint \(endpoint) worked!")
                return response
            } catch let error as TavusError {
                print("❌ Endpoint \(endpoint) failed: \(error)")
                
                // If this is the last endpoint, throw the error
                if index == possibleEndpoints.count - 1 {
                    throw error
                }
                // Otherwise, continue to next endpoint
                continue
            }
        }
        
        throw TavusError.invalidURL
    }
    
    private func makeAPIRequest(to endpoint: String, with apiKey: String, data: TavusConversationRequest) async throws -> TavusConversationResponse {
        guard let url = URL(string: endpoint) else {
            throw TavusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        // UPDATED: Try different payload structures
        let payloads = [
            // Structure 1: Standard Tavus format
            TavusAPIPayload(
                conversationName: data.sessionName,
                conversationProperties: TavusConversationProperties(
                    category: data.category,
                    duration: data.duration,
                    cvContext: data.cvContext,
                    instructions: generateInstructions(for: data.category, cvContext: data.cvContext),
                    conversationType: "interview",
                    language: "en"
                )
            ),
            // Structure 2: Simplified format
            SimpleTavusPayload(
                name: data.sessionName,
                type: "interview",
                duration: data.duration,
                instructions: generateInstructions(for: data.category, cvContext: data.cvContext)
            )
        ]
        
        for (payloadIndex, payload) in payloads.enumerated() {
            do {
                let jsonData = try JSONEncoder().encode(payload)
                request.httpBody = jsonData
                
                // Debug: Print request details
                print("📤 DEBUG: Request Details (Payload \(payloadIndex + 1))")
                print("  - Method: \(request.httpMethod ?? "Unknown")")
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
                    // Success - try to parse response
                    return try parseSuccessResponse(responseData)
                    
                case 401:
                    print("🚨 401 UNAUTHORIZED - API Key Issues:")
                    print("  - Check if API key is complete and valid")
                    print("  - Verify API key format matches Tavus requirements")
                    print("  - Current API key preview: \(String(apiKey.prefix(15)))...")
                    throw TavusError.apiErrorWithMessage(401, "Invalid API key")
                    
                case 404:
                    print("🚨 404 NOT FOUND - Endpoint Issues:")
                    print("  - Endpoint: \(endpoint)")
                    print("  - This endpoint might not exist")
                    throw TavusError.apiErrorWithMessage(404, "Endpoint not found")
                    
                case 400:
                    print("🚨 400 BAD REQUEST - Payload Issues:")
                    if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                        throw TavusError.apiErrorWithMessage(400, errorData.message)
                    } else {
                        throw TavusError.apiErrorWithMessage(400, "Invalid request payload")
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
                print("❌ Payload \(payloadIndex + 1) failed: \(error)")
                if payloadIndex == payloads.count - 1 {
                    throw error
                }
                continue
            }
        }
        
        throw TavusError.invalidResponse
    }
    
    private func parseSuccessResponse(_ data: Data) throws -> TavusConversationResponse {
        // Try different response structures
        do {
            let tavusResponse = try JSONDecoder().decode(TavusAPIResponse.self, from: data)
            return TavusConversationResponse(
                conversationUrl: tavusResponse.conversationUrl,
                sessionId: tavusResponse.conversationId
            )
        } catch {
            // Try alternative response structure
            do {
                let altResponse = try JSONDecoder().decode(AlternativeTavusResponse.self, from: data)
                return TavusConversationResponse(
                    conversationUrl: altResponse.url ?? altResponse.conversationUrl ?? "",
                    sessionId: altResponse.id ?? altResponse.sessionId ?? ""
                )
            } catch {
                print("❌ Failed to parse response with any known structure")
                throw TavusError.decodingError
            }
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
        return TavusConfig.validateConfiguration()
    }
    
    // MARK: - Test API Key Function (ENHANCED)
    
    func testApiKey() async -> Bool {
        do {
            let apiKey = try TavusConfig.getApiKey()
            
            // Test multiple endpoints for API key validation
            let testEndpoints = [
                "https://tavusapi.com/v2/account",
                "https://api.tavus.io/v2/account",
                "https://platform.tavus.io/api/v2/account",
                "https://tavusapi.com/account",
                "https://api.tavus.io/account"
            ]
            
            print("🧪 Testing Tavus API Key...")
            print("🔑 Current API key preview: \(String(apiKey.prefix(15)))...")
            
            for (index, endpoint) in testEndpoints.enumerated() {
                print("🌐 Testing endpoint \(index + 1)/\(testEndpoints.count): \(endpoint)")
                
                guard let url = URL(string: endpoint) else {
                    print("❌ Invalid test URL: \(endpoint)")
                    continue
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📊 Endpoint \(endpoint) - Status: \(httpResponse.statusCode)")
                        
                        switch httpResponse.statusCode {
                        case 200, 201:
                            print("✅ API Key is valid! Endpoint: \(endpoint)")
                            return true
                        case 401:
                            print("❌ API Key invalid for endpoint: \(endpoint)")
                        case 404:
                            print("⚠️ Endpoint not found: \(endpoint)")
                        default:
                            print("⚠️ Unexpected status \(httpResponse.statusCode) for: \(endpoint)")
                        }
                    }
                } catch {
                    print("❌ Network error for \(endpoint): \(error)")
                }
            }
            
            print("❌ API Key test failed for all endpoints")
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

// MARK: - API Models (MULTIPLE STRUCTURES TO TRY)

struct TavusAPIPayload: Codable {
    let conversationName: String
    let conversationProperties: TavusConversationProperties
    
    enum CodingKeys: String, CodingKey {
        case conversationName = "conversation_name"
        case conversationProperties = "properties"
    }
}

struct SimpleTavusPayload: Codable {
    let name: String
    let type: String
    let duration: Int
    let instructions: String
}

struct TavusConversationProperties: Codable {
    let category: String
    let duration: Int
    let cvContext: String?
    let instructions: String
    let conversationType: String
    let language: String
    
    enum CodingKeys: String, CodingKey {
        case category
        case duration
        case cvContext = "cv_context"
        case instructions
        case conversationType = "conversation_type"
        case language
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

struct AlternativeTavusResponse: Codable {
    let id: String?
    let sessionId: String?
    let url: String?
    let conversationUrl: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case url
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