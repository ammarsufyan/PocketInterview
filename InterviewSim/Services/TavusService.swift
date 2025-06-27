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
    
    private let apiKey = "YOUR_TAVUS_API_KEY" // Replace with your actual API key
    private let baseURL = "https://tavusapi.com/v2"
    
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
            
            return true
            
        } catch {
            print("❌ Error creating Tavus conversation: \(error)")
            self.errorMessage = "Failed to create interview session: \(error.localizedDescription)"
            return false
        }
        
        isLoading = false
    }
    
    // MARK: - API Calls
    
    private func createTavusConversation(data: TavusConversationRequest) async throws -> TavusConversationResponse {
        guard let url = URL(string: "\(baseURL)/conversations") else {
            throw TavusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the conversation payload
        let payload = TavusAPIPayload(
            conversationName: data.sessionName,
            replicaId: "r1234567890", // Replace with your replica ID
            conversationProperties: TavusConversationProperties(
                category: data.category,
                duration: data.duration,
                cvContext: data.cvContext,
                instructions: generateInstructions(for: data.category, cvContext: data.cvContext)
            )
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TavusError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw TavusError.apiError(httpResponse.statusCode)
        }
        
        let tavusResponse = try JSONDecoder().decode(TavusAPIResponse.self, from: responseData)
        
        return TavusConversationResponse(
            conversationUrl: tavusResponse.conversationUrl,
            sessionId: tavusResponse.conversationId
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateInstructions(for category: String, cvContext: String?) -> String {
        let baseInstructions = """
        You are an expert interviewer conducting a \(category.lowercased()) interview. 
        Be professional, encouraging, and provide constructive feedback.
        """
        
        let categorySpecificInstructions: String
        
        switch category {
        case "Technical":
            categorySpecificInstructions = """
            
            Focus on:
            - Technical skills and problem-solving abilities
            - Coding challenges appropriate to their experience level
            - System design questions
            - Best practices and architecture patterns
            - Ask follow-up questions to dive deeper into their technical knowledge
            """
        case "Behavioral":
            categorySpecificInstructions = """
            
            Focus on:
            - Past work experiences and achievements
            - Leadership and teamwork situations
            - Problem-solving in workplace scenarios
            - Use the STAR method (Situation, Task, Action, Result)
            - Ask for specific examples and details
            """
        default:
            categorySpecificInstructions = """
            
            Conduct a general interview focusing on the candidate's background and experience.
            """
        }
        
        let cvInstructions = if let cvContext = cvContext, !cvContext.isEmpty {
            """
            
            CANDIDATE BACKGROUND:
            \(cvContext)
            
            Use this information to ask personalized questions based on their experience, skills, and background.
            Reference specific items from their CV when appropriate.
            """
        } else {
            ""
        }
        
        return baseInstructions + categorySpecificInstructions + cvInstructions
    }
    
    func clearSession() {
        conversationUrl = nil
        sessionId = nil
        errorMessage = nil
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

struct TavusAPIPayload: Codable {
    let conversationName: String
    let replicaId: String
    let conversationProperties: TavusConversationProperties
    
    enum CodingKeys: String, CodingKey {
        case conversationName = "conversation_name"
        case replicaId = "replica_id"
        case conversationProperties = "properties"
    }
}

struct TavusConversationProperties: Codable {
    let category: String
    let duration: Int
    let cvContext: String?
    let instructions: String
    
    enum CodingKeys: String, CodingKey {
        case category
        case duration
        case cvContext = "cv_context"
        case instructions
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

// MARK: - Error Types

enum TavusError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API Error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}