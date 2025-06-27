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
        let baseURL = envConfig.tavusBaseURL
        guard let url = URL(string: "\(baseURL)/conversations") else {
            throw TavusError.invalidURL
        }
        
        // Get API key from environment with detailed debugging
        let apiKey = try TavusConfig.getApiKey()
        
        print("🔑 DEBUG: API Key Detailed Analysis")
        print("  - Raw Length: \(apiKey.count)")
        print("  - First 15 chars: \(String(apiKey.prefix(15)))...")
        print("  - Last 10 chars: ...\(String(apiKey.suffix(10)))")
        print("  - Contains underscore: \(apiKey.contains("_"))")
        print("  - Contains dash: \(apiKey.contains("-"))")
        print("  - Is alphanumeric: \(apiKey.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" })")
        print("🌐 DEBUG: Request URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InterviewSim/1.0", forHTTPHeaderField: "User-Agent")
        
        // UPDATED: Use correct Tavus API payload structure
        let payload = TavusAPIPayload(
            conversationName: data.sessionName,
            conversationProperties: TavusConversationProperties(
                category: data.category,
                duration: data.duration,
                cvContext: data.cvContext,
                instructions: generateInstructions(for: data.category, cvContext: data.cvContext),
                conversationType: "interview",
                language: "en"
            )
        )
        
        let jsonData = try JSONEncoder().encode(payload)
        request.httpBody = jsonData
        
        // Debug: Print request details
        print("📤 DEBUG: Request Details")
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
        
        // ENHANCED: Better error handling for 401
        if httpResponse.statusCode == 401 {
            print("🚨 401 UNAUTHORIZED - API Key Issues:")
            print("  - Check if API key is complete and valid")
            print("  - Verify API key format matches Tavus requirements")
            print("  - Ensure no extra spaces or characters in .env file")
            print("  - Current API key preview: \(String(apiKey.prefix(15)))...")
            
            throw TavusError.apiErrorWithMessage(401, "Invalid API key. Please check your TAVUS_API_KEY in .env file.")
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            // Try to parse error response
            if let errorData = try? JSONDecoder().decode(TavusErrorResponse.self, from: responseData) {
                throw TavusError.apiErrorWithMessage(httpResponse.statusCode, errorData.message)
            } else {
                let responseString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                throw TavusError.apiErrorWithMessage(httpResponse.statusCode, responseString)
            }
        }
        
        let tavusResponse = try JSONDecoder().decode(TavusAPIResponse.self, from: responseData)
        
        return TavusConversationResponse(
            conversationUrl: tavusResponse.conversationUrl,
            sessionId: tavusResponse.conversationId
        )
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
    
    // MARK: - Test API Key Function
    
    func testApiKey() async -> Bool {
        do {
            let apiKey = try TavusConfig.getApiKey()
            let baseURL = envConfig.tavusBaseURL
            
            // Test with a simple API call (like getting account info)
            guard let url = URL(string: "\(baseURL)/account") else {
                print("❌ Invalid test URL")
                return false
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🧪 API Key Test Result: Status \(httpResponse.statusCode)")
                return httpResponse.statusCode != 401
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

// MARK: - API Models (UPDATED FOR TAVUS API STRUCTURE)

struct TavusAPIPayload: Codable {
    let conversationName: String
    let conversationProperties: TavusConversationProperties
    
    enum CodingKeys: String, CodingKey {
        case conversationName = "conversation_name"
        case conversationProperties = "properties"
    }
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

struct TavusErrorResponse: Codable {
    let message: String
    let code: String?
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