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
    
    /// Tavus Replica ID from environment variables
    static var defaultReplicaId: String? {
        return EnvironmentConfig.shared.tavusReplicaId
    }
    
    // MARK: - Conversation Settings
    
    /// Default conversation properties
    static let defaultConversationProperties = [
        "max_duration": 3600, // 1 hour in seconds
        "language": "en",
        "voice_settings": [
            "stability": 0.8,
            "similarity_boost": 0.8,
            "style": 0.2
        ]
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
        return EnvironmentConfig.shared.validateTavusConfiguration()
    }
    
    // MARK: - Safe Configuration Access
    
    static func getApiKey() throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TavusConfigError.missingApiKey
        }
        return apiKey
    }
    
    static func getReplicaId() throws -> String {
        guard let replicaId = defaultReplicaId, !replicaId.isEmpty else {
            throw TavusConfigError.missingReplicaId
        }
        return replicaId
    }
}

// MARK: - Configuration Errors

enum TavusConfigError: Error, LocalizedError {
    case missingApiKey
    case missingReplicaId
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Tavus API key not found. Please add TAVUS_API_KEY to your .env file."
        case .missingReplicaId:
            return "Tavus Replica ID not found. Please add TAVUS_REPLICA_ID to your .env file."
        case .invalidConfiguration:
            return "Invalid Tavus configuration. Please check your environment variables."
        }
    }
}

// MARK: - Setup Instructions

/*
 TAVUS ENVIRONMENT SETUP INSTRUCTIONS:
 
 1. Create a .env file in your project root with:
    TAVUS_API_KEY=your_actual_api_key_here
    TAVUS_REPLICA_ID=your_actual_replica_id_here
    TAVUS_BASE_URL=https://tavusapi.com/v2
 
 2. Get your Tavus API Key:
    - Go to https://platform.tavus.io/api-keys
    - Create a new API key
    - Add it to your .env file
 
 3. Create a Replica:
    - Go to https://platform.tavus.io/replicas
    - Create a new replica (AI interviewer persona)
    - Copy the Replica ID
    - Add it to your .env file
 
 4. For production builds, add these keys to Info.plist:
    <key>TAVUS_API_KEY</key>
    <string>$(TAVUS_API_KEY)</string>
    <key>TAVUS_REPLICA_ID</key>
    <string>$(TAVUS_REPLICA_ID)</string>
 
 5. Test the configuration:
    TavusConfig.validateConfiguration()
 
 SECURITY NOTES:
 - Never commit .env file to version control
 - Add .env to your .gitignore file
 - Use different keys for development and production
 - Consider using Xcode build configurations for different environments
 */