//
//  SessionNameGenerator.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

struct SessionNameGenerator {
    
    // MARK: - Technical Session Names
    private static let technicalTopics = [
        "iOS Development",
        "Swift Programming",
        "Data Structures",
        "Algorithms",
        "System Design",
        "Database Design",
        "API Development",
        "Mobile Architecture",
        "Performance Optimization",
        "Security Practices",
        "Testing Strategies",
        "Code Review",
        "Git & Version Control",
        "Design Patterns",
        "Memory Management",
        "Networking",
        "Core Data",
        "SwiftUI",
        "UIKit",
        "Combine Framework"
    ]
    
    private static let technicalFormats = [
        "Practice",
        "Deep Dive",
        "Fundamentals",
        "Advanced Topics",
        "Problem Solving",
        "Code Challenge",
        "Technical Review",
        "Concepts",
        "Implementation",
        "Best Practices"
    ]
    
    // MARK: - Behavioral Session Names
    private static let behavioralTopics = [
        "Leadership",
        "Team Collaboration",
        "Problem Solving",
        "Communication",
        "Conflict Resolution",
        "Project Management",
        "Time Management",
        "Adaptability",
        "Decision Making",
        "Customer Focus",
        "Innovation",
        "Work-Life Balance",
        "Career Growth",
        "Mentoring",
        "Cross-functional Work",
        "Remote Work",
        "Stakeholder Management",
        "Change Management",
        "Cultural Fit",
        "Goal Setting"
    ]
    
    private static let behavioralFormats = [
        "Questions",
        "Scenarios",
        "STAR Method",
        "Experience Review",
        "Situational Practice",
        "Competency Check",
        "Soft Skills",
        "Interview Prep",
        "Behavioral Assessment",
        "Professional Stories"
    ]
    
    // MARK: - Session Name Generation
    static func generateSessionName(
        for category: String,
        sessionCount: Int = 0,
        date: Date = Date(),
        customFocus: String? = nil
    ) -> String {
        
        switch category.lowercased() {
        case "technical":
            return generateTechnicalSessionName(
                sessionCount: sessionCount,
                date: date,
                customFocus: customFocus
            )
        case "behavioral":
            return generateBehavioralSessionName(
                sessionCount: sessionCount,
                date: date,
                customFocus: customFocus
            )
        default:
            return generateDefaultSessionName(
                category: category,
                sessionCount: sessionCount,
                date: date
            )
        }
    }
    
    private static func generateTechnicalSessionName(
        sessionCount: Int,
        date: Date,
        customFocus: String?
    ) -> String {
        
        // If user provided custom focus
        if let focus = customFocus, !focus.isEmpty {
            let format = technicalFormats.randomElement() ?? "Practice"
            return "\(focus) \(format)"
        }
        
        // Generate based on session count and time
        let topic = selectTechnicalTopic(for: sessionCount)
        let format = selectTechnicalFormat(for: date)
        
        return "\(topic) \(format)"
    }
    
    private static func generateBehavioralSessionName(
        sessionCount: Int,
        date: Date,
        customFocus: String?
    ) -> String {
        
        // If user provided custom focus
        if let focus = customFocus, !focus.isEmpty {
            let format = behavioralFormats.randomElement() ?? "Questions"
            return "\(focus) \(format)"
        }
        
        // Generate based on session count and time
        let topic = selectBehavioralTopic(for: sessionCount)
        let format = selectBehavioralFormat(for: date)
        
        return "\(topic) \(format)"
    }
    
    private static func generateDefaultSessionName(
        category: String,
        sessionCount: Int,
        date: Date
    ) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: date)
        
        return "\(category) Session #\(sessionCount + 1) - \(timeString)"
    }
    
    // MARK: - Smart Topic Selection
    private static func selectTechnicalTopic(for sessionCount: Int) -> String {
        // Rotate through topics based on session count to avoid repetition
        let index = sessionCount % technicalTopics.count
        return technicalTopics[index]
    }
    
    private static func selectBehavioralTopic(for sessionCount: Int) -> String {
        // Rotate through topics based on session count to avoid repetition
        let index = sessionCount % behavioralTopics.count
        return behavioralTopics[index]
    }
    
    private static func selectTechnicalFormat(for date: Date) -> String {
        // Select format based on time of day
        let hour = Calendar.current.component(.hour, from: date)
        
        switch hour {
        case 6..<12:   // Morning - Fundamentals
            return ["Fundamentals", "Practice", "Concepts"].randomElement() ?? "Practice"
        case 12..<17:  // Afternoon - Deep work
            return ["Deep Dive", "Advanced Topics", "Problem Solving"].randomElement() ?? "Deep Dive"
        case 17..<22:  // Evening - Review
            return ["Code Challenge", "Technical Review", "Implementation"].randomElement() ?? "Code Challenge"
        default:       // Night/Early morning - Quick practice
            return ["Practice", "Concepts", "Best Practices"].randomElement() ?? "Practice"
        }
    }
    
    private static func selectBehavioralFormat(for date: Date) -> String {
        // Select format based on day of week
        let weekday = Calendar.current.component(.weekday, from: date)
        
        switch weekday {
        case 1, 7:     // Weekend - Reflection
            return ["Experience Review", "Professional Stories", "Career Growth"].randomElement() ?? "Experience Review"
        case 2, 3:     // Monday/Tuesday - Fresh start
            return ["STAR Method", "Scenarios", "Questions"].randomElement() ?? "STAR Method"
        case 4, 5:     // Wednesday/Thursday - Mid-week focus
            return ["Competency Check", "Situational Practice", "Soft Skills"].randomElement() ?? "Competency Check"
        case 6:        // Friday - Wrap up
            return ["Interview Prep", "Behavioral Assessment", "Questions"].randomElement() ?? "Interview Prep"
        default:
            return "Questions"
        }
    }
    
    // MARK: - Session Numbering for Same Day
    static func generateUniqueSessionName(
        for category: String,
        existingSessions: [InterviewSession],
        date: Date = Date(),
        customFocus: String? = nil
    ) -> String {
        
        let calendar = Calendar.current
        let sameDaySessions = existingSessions.filter { session in
            calendar.isDate(session.date, inSameDayAs: date) && 
            session.category.lowercased() == category.lowercased()
        }
        
        let sessionCount = sameDaySessions.count
        let baseName = generateSessionName(
            for: category,
            sessionCount: sessionCount,
            date: date,
            customFocus: customFocus
        )
        
        // If multiple sessions on same day, add number
        if sessionCount > 0 {
            return "\(baseName) #\(sessionCount + 1)"
        }
        
        return baseName
    }
}

// MARK: - Extensions for Better Integration
extension SessionNameGenerator {
    
    // Get suggested topics for user selection
    static func getSuggestedTopics(for category: String) -> [String] {
        switch category.lowercased() {
        case "technical":
            return Array(technicalTopics.prefix(10)) // Top 10 most common
        case "behavioral":
            return Array(behavioralTopics.prefix(10)) // Top 10 most common
        default:
            return []
        }
    }
    
    // Get random topic for quick start
    static func getRandomTopic(for category: String) -> String? {
        switch category.lowercased() {
        case "technical":
            return technicalTopics.randomElement()
        case "behavioral":
            return behavioralTopics.randomElement()
        default:
            return nil
        }
    }
}