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
    static let technicalPersonaId = "p28aa4c7a505"
    
    /// Behavioral Interviewer - Lucy
    static let behavioralPersonaId = "pd8e1d0e7a85"
    
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
    
    // MARK: - Custom Greeting Configuration
    
    /// Get personalized greeting based on category and session details
    static func getCustomGreeting(
        for category: String,
        sessionName: String,
        duration: Int,
        candidateName: String? = nil
    ) -> String {
        let interviewerName = getInterviewerName(for: category)
        let greeting = candidateName != nil ? "Hi \(candidateName!)!" : "Hello there!"
        
        switch category {
        case "Technical":
            return "\(greeting) I'm \(interviewerName), and I'll be your technical interviewer today. We have \(duration) minutes for our '\(sessionName)' session. I'm excited to explore your technical skills and problem-solving approach. Are you ready to get started?"
            
        case "Behavioral":
            return "\(greeting) Welcome! I'm \(interviewerName), your behavioral interviewer. Today we'll spend \(duration) minutes discussing your experiences in our '\(sessionName)' session. I'm looking forward to learning about your leadership style and how you handle different workplace situations. Shall we begin?"
            
        default:
            return "\(greeting) I'm \(interviewerName), and I'll be conducting your interview today. We have \(duration) minutes for our '\(sessionName)' session. I'm here to help you showcase your best self. Ready to start?"
        }
    }
    
    /// Get fallback greeting if session details are not available
    static func getDefaultGreeting(for category: String) -> String {
        let interviewerName = getInterviewerName(for: category)
        
        switch category {
        case "Technical":
            return "Hello! I'm \(interviewerName), your technical interviewer. I'm excited to explore your technical skills and problem-solving abilities today. Are you ready to begin?"
            
        case "Behavioral":
            return "Hi there! I'm \(interviewerName), and I'll be your behavioral interviewer today. I'm looking forward to learning about your experiences and how you approach different workplace situations. Shall we get started?"
            
        default:
            return "Hello! I'm \(interviewerName), and I'll be conducting your interview today. I'm here to help you showcase your abilities. Ready to begin?"
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
        sessionName: String,
        durationMinutes: Int,
        cvContext: String?
    ) -> String? {
        var contextParts: [String] = []
        
        // Add session information
        contextParts.append("SESSION INFORMATION:")
        contextParts.append("- Interview Type: \(category)")
        contextParts.append("- Session Name: \(sessionName)")
        contextParts.append("- Duration: \(durationMinutes) minutes")
        contextParts.append("- Interviewer: \(getInterviewerName(for: category))")
        
        // Add CV context if provided
        if let cvContext = cvContext, !cvContext.isEmpty {
            contextParts.append("")
            contextParts.append("CANDIDATE BACKGROUND:")
            
            // Limit CV context to avoid overwhelming the persona
            let maxLength = 1500
            let truncatedContext = cvContext.count > maxLength ? 
                String(cvContext.prefix(maxLength)) + "..." : 
                cvContext
            
            contextParts.append(truncatedContext)
            contextParts.append("")
            contextParts.append("Please tailor your questions based on their background and experience level.")
        }
        
        // Add category-specific instructions
        let categoryInstructions = createCategoryInstructions(for: category)
        contextParts.append("")
        contextParts.append("INTERVIEW GUIDELINES:")
        contextParts.append(categoryInstructions)
        
        return contextParts.joined(separator: "\n")
    }
    
    /// Create category-specific instructions
    private static func createCategoryInstructions(for category: String) -> String {
        switch category {
        case "Technical":
            return """
            - Start with easier questions and gradually increase difficulty
            - Ask candidates to explain their thought process
            - Include coding problems appropriate for the time available
            - Focus on problem-solving approach, not just correct answers
            - Ask about trade-offs and optimization when relevant
            """
            
        case "Behavioral":
            return """
            - Use the STAR method (Situation, Task, Action, Result) framework
            - Ask for specific examples from their experience
            - Probe for details about challenges and learnings
            - Focus on leadership, teamwork, and problem-solving scenarios
            - Ask follow-up questions to understand their decision-making process
            """
            
        default:
            return """
            - Maintain a professional yet friendly tone
            - Ask clear, specific questions
            - Allow time for thoughtful responses
            - Provide constructive feedback when appropriate
            """
        }
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
