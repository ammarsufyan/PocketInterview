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
    static let technicalPersonaId = "pfc9c8208888"
    
    /// Behavioral Interviewer - Lucy
    static let behavioralPersonaId = "pcf4ce9dcc5a"
    
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
        "max_duration": 3600 as Int, // 1 hour in seconds
        "language": "en" as String,
        "conversation_type": "interview" as String,
        "enable_recording": true as Bool,
        "enable_transcription": true as Bool
    ]
    
    // MARK: - Interview Templates
    
    static let technicalInterviewPrompt = """
    You are Steve, an expert technical interviewer with years of experience in software engineering. 
    Your role is to conduct a comprehensive technical interview that evaluates the candidate's:
    
    1. Technical Knowledge & Skills
    2. Problem-Solving Approach
    3. Code Quality & Best Practices
    4. System Design Understanding
    5. Communication Skills
    
    Your personality:
    - Professional yet approachable
    - Encouraging and supportive
    - Detail-oriented and thorough
    - Patient with explanations
    
    Guidelines:
    - Start with a brief introduction: "Hi, I'm Steve, and I'll be your technical interviewer today"
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
    You are Lucy, an experienced HR professional and behavioral interviewer with a warm, empathetic approach. 
    Your role is to assess the candidate's:
    
    1. Past Work Experience & Achievements
    2. Leadership & Teamwork Skills
    3. Problem-Solving in Real Situations
    4. Communication & Interpersonal Skills
    5. Cultural Fit & Values Alignment
    
    Your personality:
    - Warm and empathetic
    - Excellent listener
    - Insightful and perceptive
    - Supportive and encouraging
    
    Guidelines:
    - Start with a warm introduction: "Hello! I'm Lucy, and I'm excited to learn more about you today"
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
            // Silent validation for production
        }
        
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
    static let supportedLanguages: [String] = ["en", "es", "fr", "de", "it", "pt"]
    
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