//
//  TavusConfig.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

struct TavusConfig {
    // MARK: - API Configuration (HARDCODED FOR TESTING)
    
    /// Hardcoded Tavus API key for testing
    static var apiKey: String? {
        // HARDCODED API KEY - REMOVE IN PRODUCTION
        return "3d52ddd842e64285b8982713be1e3896"
    }
    
    /// Tavus API base URL
    static var baseURL: String {
        return "https://tavusapi.com/v2"
    }
    
    // MARK: - Conversation Settings
    
    /// Default conversation properties
    static let defaultConversationProperties: [String: Any] = [
        "max_duration": 3600 as Int, // 1 hour in seconds
        "language": "en" as String,
        "conversation_type": "interview" as String,
        "enable_recording": true as Bool,
        "enable_transcription": true as Bool
    ]
    
    // MARK: - Interview Templates
    
    static let technicalInterviewPrompt = """
    You are an expert technical interviewer with years of experience in software engineering. 
    Your role is to conduct a comprehensive technical interview that evaluates the candidate's:
    
    1. Technical Knowledge & Skills
    2. Problem-Solving Approach
    3. Code Quality & Best Practices
    4. System Design Understanding
    5. Communication Skills
    
    Guidelines:
    - Start with a brief introduction and overview of the interview process
    - Ask questions that build upon each other logically
    - Encourage the candidate to think out loud
    - Provide hints if they get stuck, but let them work through problems
    - Ask follow-up questions to dive deeper into their knowledge
    - Be encouraging and constructive in your feedback
    - Adapt the difficulty based on their responses
    
    Interview Structure:
    1. Warm-up questions about their background (5 minutes)
    2. Technical knowledge questions (10-15 minutes)
    3. Coding/problem-solving challenge (15-20 minutes)
    4. System design or architecture discussion (10-15 minutes)
    5. Wrap-up and next steps (5 minutes)
    """
    
    static let behavioralInterviewPrompt = """
    You are an experienced HR professional and behavioral interviewer. 
    Your role is to assess the candidate's:
    
    1. Past Work Experience & Achievements
    2. Leadership & Teamwork Skills
    3. Problem-Solving in Real Situations
    4. Communication & Interpersonal Skills
    5. Cultural Fit & Values Alignment
    
    Guidelines:
    - Use the STAR method (Situation, Task, Action, Result) framework
    - Ask for specific examples and concrete details
    - Probe deeper when answers are too general
    - Listen for evidence of growth and learning
    - Assess both successes and how they handle challenges
    - Be empathetic and create a comfortable environment
    - Ask follow-up questions to understand their thought process
    
    Interview Structure:
    1. Introduction and background overview (5 minutes)
    2. Experience and achievements discussion (15-20 minutes)
    3. Situational and behavioral questions (15-20 minutes)
    4. Values and motivation exploration (5-10 minutes)
    5. Questions from candidate and wrap-up (5 minutes)
    """
    
    // MARK: - Helper Methods
    
    static func createPersonalizedPrompt(
        basePrompt: String,
        category: String,
        cvContext: String?
    ) -> String {
        var prompt = basePrompt
        
        if let cvContext = cvContext, !cvContext.isEmpty {
            prompt += """
            
            CANDIDATE BACKGROUND INFORMATION:
            \(cvContext)
            
            PERSONALIZATION INSTRUCTIONS:
            - Reference specific skills, technologies, and experiences from their background
            - Ask questions that are relevant to their experience level
            - Tailor the difficulty and focus areas based on their expertise
            - Use their past projects and achievements as conversation starters
            - Ask about specific technologies and frameworks they've mentioned
            """
        }
        
        return prompt
    }
    
    static func validateConfiguration() -> Bool {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            print("❌ TAVUS_API_KEY not found")
            return false
        }
        
        // Validate API key format
        if apiKey.count < 10 {
            print("⚠️ Warning: API key seems too short (\(apiKey.count) characters)")
        }
        
        print("✅ Tavus configuration is valid")
        print("  - API Key: \(String(apiKey.prefix(10)))... (length: \(apiKey.count))")
        print("  - Base URL: \(baseURL)")
        return true
    }
    
    // MARK: - Safe Configuration Access
    
    static func getApiKey() throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TavusConfigError.missingApiKey
        }
        
        // Validate API key format
        if apiKey.count < 10 {
            print("⚠️ Warning: API key seems too short (\(apiKey.count) characters)")
        }
        
        return apiKey
    }
    
    // MARK: - Additional Configuration Properties
    
    /// Default timeout for API requests (in seconds)
    static let apiTimeout: TimeInterval = 30.0
    
    /// Maximum conversation duration (in seconds)
    static let maxConversationDuration: Int = 3600 // 1 hour
    
    /// Supported conversation languages
    static let supportedLanguages: [String] = ["en", "es", "fr", "de", "it", "pt"]
    
    /// Default conversation settings
    static let defaultSettings: [String: Any] = [
        "auto_start": true as Bool,
        "show_controls": true as Bool,
        "enable_fullscreen": true as Bool,
        "theme": "professional" as String
    ]
    
    // MARK: - Replica Configuration
    
    /// Your actual replica ID from Tavus dashboard
    static let defaultReplicaId = "rf4703150052"
    
    /// Replica validation
    static func validateReplicaId(_ replicaId: String = defaultReplicaId) -> Bool {
        // Tavus replica IDs typically start with 'r' followed by alphanumeric characters
        let isValidFormat = replicaId.hasPrefix("r") && replicaId.count >= 8
        
        if !isValidFormat {
            print("⚠️ Warning: Replica ID '\(replicaId)' might not be in the correct format")
            print("   Expected format: r followed by alphanumeric characters (e.g., rf4703150052)")
        } else {
            print("✅ Replica ID '\(replicaId)' appears to be valid")
        }
        
        return isValidFormat
    }
}

// MARK: - Configuration Errors

enum TavusConfigError: Error, LocalizedError {
    case missingApiKey
    case invalidConfiguration
    case networkError
    case invalidResponse
    case invalidReplicaId
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Tavus API key not found. Please check your configuration."
        case .invalidConfiguration:
            return "Invalid Tavus configuration. Please check your settings."
        case .networkError:
            return "Network error occurred while connecting to Tavus API."
        case .invalidResponse:
            return "Invalid response received from Tavus API."
        case .invalidReplicaId:
            return "Invalid replica ID. Please check your replica ID in Tavus dashboard."
        }
    }
}