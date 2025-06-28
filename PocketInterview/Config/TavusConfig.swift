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
    
    // MARK: - Persona Configuration
    
    /// Technical Interviewer - Steve
    static let technicalPersonaId = "p76c770451a6"
    
    /// Behavioral Interviewer - Lucy
    static let behavioralPersonaId = "p67d83202798"
    
    /// Get persona ID based on interview category
    static func getPersonaId(for category: String) -> String {
        switch category {
        case "Technical":
            return technicalPersonaId
        case "Behavioral":
            return behavioralPersonaId
        default:
            return technicalPersonaId // Default to technical
        }
    }
    
    /// Get interviewer name based on category
    static func getInterviewerName(for category: String) -> String {
        switch category {
        case "Technical":
            return "Steve"
        case "Behavioral":
            return "Lucy"
        default:
            return "AI Interviewer"
        }
    }
    
    /// Get interviewer description based on category
    static func getInterviewerDescription(for category: String) -> String {
        switch category {
        case "Technical":
            return "Steve is your technical interviewer with expertise in software engineering, algorithms, and system design."
        case "Behavioral":
            return "Lucy is your behavioral interviewer specializing in leadership assessment, team dynamics, and career development."
        default:
            return "Your AI interviewer will guide you through the interview process."
        }
    }
    
    // MARK: - Conversation Settings
    
    /// Default conversation properties
    static let defaultConversationProperties: [String: Any] = [
        "max_call_duration": 3600 as Int, // 1 hour in seconds
        "language": "english" as String,
        "enable_recording": false as Bool,
        "enable_closed_captions": true as Bool,
        "participant_left_timeout": 10 as Int,
        "participant_absent_timeout": 60 as Int
    ]
    
    // MARK: - Helper Methods
    
    /// Create personalized context for the conversation
    static func createPersonalizedContext(
        category: String,
        cvContext: String?
    ) -> String? {
        // If CV context is provided, create a brief personalized context
        guard let cvContext = cvContext, !cvContext.isEmpty else {
            return nil // Let the persona handle the conversation without additional context
        }
        
        // Create a concise context based on CV information
        let contextPrefix = "CANDIDATE BACKGROUND:\n"
        let contextSuffix = "\n\nPlease tailor your questions based on their background and experience level."
        
        // Limit context to avoid overwhelming the persona
        let maxLength = 2000
        let truncatedContext = cvContext.count > maxLength ? 
            String(cvContext.prefix(maxLength)) + "..." : 
            cvContext
        
        return contextPrefix + truncatedContext + contextSuffix
    }
    
    static func validateConfiguration() -> Bool {
        let isValid = EnvironmentConfig.shared.validateTavusConfiguration()
        return isValid
    }
    
    // MARK: - Safe Configuration Access
    
    static func getApiKey() throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TavusConfigError.missingApiKey
        }
        
        return apiKey
    }
    
    // MARK: - Additional Configuration Properties
    
    /// Default timeout for API requests (in seconds)
    static let apiTimeout: TimeInterval = 30.0
    
    /// Maximum conversation duration (in seconds)
    static let maxConversationDuration: Int = 3600 // 1 hour
    
    /// Supported conversation languages
    static let supportedLanguages: [String] = ["english", "spanish", "french", "german", "italian", "portuguese"]
    
    /// Default conversation settings
    static let defaultSettings: [String: Any] = [
        "auto_start": true as Bool,
        "show_controls": true as Bool,
        "enable_fullscreen": true as Bool,
        "theme": "professional" as String
    ]
    
    // MARK: - Persona Validation
    
    /// Validate persona IDs
    static func validatePersonaIds() -> Bool {
        let technicalValid = !technicalPersonaId.isEmpty && technicalPersonaId.hasPrefix("p")
        let behavioralValid = !behavioralPersonaId.isEmpty && behavioralPersonaId.hasPrefix("p")
        
        return technicalValid && behavioralValid
    }
    
    /// Instructions for persona setup
    static let personaSetupInstructions = """
    PERSONA SETUP COMPLETED ✅
    
    Technical Interviewer - Steve: pfc9c8208888
    Behavioral Interviewer - Lucy: pcf4ce9dcc5a
    
    These personas are now configured and will provide personalized interview experiences:
    
    Steve (Technical):
    - Expert in software engineering and system design
    - Professional yet approachable demeanor
    - Focuses on coding challenges and technical depth
    
    Lucy (Behavioral):
    - Experienced HR professional with empathetic approach
    - Specializes in STAR method and leadership assessment
    - Creates comfortable environment for sharing experiences
    
    The app will automatically select the appropriate persona based on interview type.
    """
}

// MARK: - Configuration Errors

enum TavusConfigError: Error, LocalizedError {
    case missingApiKey
    case invalidConfiguration
    case networkError
    case invalidResponse
    case invalidPersonaId
    
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
        case .invalidPersonaId:
            return "Invalid persona ID. Please check your persona IDs in Tavus dashboard."
        }
    }
}
