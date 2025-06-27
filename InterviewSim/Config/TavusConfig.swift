//
//  TavusConfig.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

struct TavusConfig {
    // MARK: - API Configuration
    
    /// Replace with your actual Tavus API key
    /// Get it from: https://platform.tavus.io/api-keys
    static let apiKey = "YOUR_TAVUS_API_KEY"
    
    /// Tavus API base URL
    static let baseURL = "https://tavusapi.com/v2"
    
    /// Replace with your actual Replica ID
    /// Create a replica at: https://platform.tavus.io/replicas
    static let defaultReplicaId = "r1234567890"
    
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
        guard !apiKey.isEmpty && apiKey != "YOUR_TAVUS_API_KEY" else {
            print("❌ Tavus API key not configured")
            return false
        }
        
        guard !defaultReplicaId.isEmpty && defaultReplicaId != "r1234567890" else {
            print("❌ Tavus Replica ID not configured")
            return false
        }
        
        return true
    }
}

// MARK: - Configuration Instructions

/*
 TAVUS SETUP INSTRUCTIONS:
 
 1. Get your Tavus API Key:
    - Go to https://platform.tavus.io/api-keys
    - Create a new API key
    - Replace "YOUR_TAVUS_API_KEY" with your actual key
 
 2. Create a Replica:
    - Go to https://platform.tavus.io/replicas
    - Create a new replica (AI interviewer persona)
    - Copy the Replica ID
    - Replace "r1234567890" with your actual replica ID
 
 3. Test the Configuration:
    - Run TavusConfig.validateConfiguration() to check setup
    - Test with a simple conversation creation
 
 4. Customize Interview Prompts:
    - Modify technicalInterviewPrompt for your technical interview style
    - Modify behavioralInterviewPrompt for your behavioral interview approach
    - Add company-specific questions or requirements
 
 SECURITY NOTE:
 - Never commit your actual API keys to version control
 - Consider using environment variables or secure storage
 - For production apps, store keys securely in Keychain
 */