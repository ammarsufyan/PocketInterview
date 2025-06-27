//
//  TavusConfig.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

struct TavusConfig {
    // MARK: - API Configuration (Using Environment Variables)
    
    /// Tavus API key from environment variables
    static var apiKey: String? {
        return EnvironmentConfig.shared.tavusApiKey
    }
    
    /// Tavus API base URL from environment variables
    static var baseURL: String {
        return EnvironmentConfig.shared.tavusBaseURL
    }
    
    // MARK: - Conversation Settings (FIXED: Explicit type annotations)
    
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
        let isValid = EnvironmentConfig.shared.validateTavusConfiguration()
        
        if !isValid {
            print("❌ Tavus Configuration Validation Failed")
            print("📋 Required Environment Variables:")
            print("  - TAVUS_API_KEY: \(apiKey != nil ? "✅ Found" : "❌ Missing")")
            print("  - TAVUS_BASE_URL: \(baseURL.isEmpty ? "❌ Missing" : "✅ Found")")
            
            if let apiKey = apiKey {
                print("🔑 API Key Debug Info:")
                print("  - Length: \(apiKey.count)")
                print("  - Starts with expected prefix: \(apiKey.hasPrefix("3d52ddd") ? "✅" : "❌")")
                print("  - Contains underscore: \(apiKey.contains("_") ? "✅" : "❌")")
            }
        }
        
        return isValid
    }
    
    // MARK: - Safe Configuration Access
    
    static func getApiKey() throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TavusConfigError.missingApiKey
        }
        
        // Validate API key format (Tavus keys typically have specific format)
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
    
    /// Default conversation settings (FIXED: Explicit type annotations)
    static let defaultSettings: [String: Any] = [
        "auto_start": true as Bool,
        "show_controls": true as Bool,
        "enable_fullscreen": true as Bool,
        "theme": "professional" as String
    ]
    
    // MARK: - Replica Configuration (UPDATED WITH YOUR REPLICA ID)
    
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
    
    /// Instructions for replica setup (updated)
    static let replicaSetupInstructions = """
    REPLICA SETUP COMPLETED ✅
    
    Current Replica ID: rf4703150052
    
    This replica ID has been configured and should work with your Tavus account.
    If you need to change it:
    
    1. Go to https://platform.tavus.io/replicas
    2. Select a different replica or create a new one
    3. Copy the replica ID
    4. Update TavusConfig.defaultReplicaId with the new ID
    
    Note: The replica represents the AI interviewer that will conduct the interview.
    Make sure this replica ID exists in your Tavus account.
    """
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
            return "Tavus API key not found. Please add TAVUS_API_KEY to your .env file."
        case .invalidConfiguration:
            return "Invalid Tavus configuration. Please check your environment variables."
        case .networkError:
            return "Network error occurred while connecting to Tavus API."
        case .invalidResponse:
            return "Invalid response received from Tavus API."
        case .invalidReplicaId:
            return "Invalid replica ID. Please check your replica ID in Tavus dashboard."
        }
    }
}

// MARK: - Setup Instructions (UPDATED)

/*
 TAVUS ENVIRONMENT SETUP INSTRUCTIONS:
 
 ✅ REPLICA ID CONFIGURED: rf4703150052
 
 1. Create a .env file in your project root with:
    TAVUS_API_KEY=your_actual_api_key_here
    TAVUS_BASE_URL=https://tavusapi.com/v2
 
 2. Your Tavus API Key should be working now
    - Make sure it's the complete key from https://platform.tavus.io/api-keys
    - The key should be in format: 3d52ddd842e6428...
 
 3. Replica ID is already configured: rf4703150052
    - This should match a replica in your Tavus dashboard
    - Verify at: https://platform.tavus.io/replicas
 
 4. Test the configuration:
    TavusConfig.validateConfiguration()
    TavusConfig.validateReplicaId()
 
 SECURITY NOTES:
 - Never commit .env file to version control
 - Add .env to your .gitignore file
 - Use different keys for development and production
 - Consider using Xcode build configurations for different environments
 */