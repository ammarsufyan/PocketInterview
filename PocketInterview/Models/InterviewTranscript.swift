//
//  InterviewTranscript.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import SwiftUI

struct InterviewTranscript: Identifiable, Codable, Equatable {
    let id: UUID
    let conversationId: String
    let transcriptData: [TranscriptMessage]
    let messageCount: Int
    let userMessageCount: Int
    let assistantMessageCount: Int
    let webhookTimestamp: Date
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case transcriptData = "transcript_data"
        case messageCount = "message_count"
        case userMessageCount = "user_message_count"
        case assistantMessageCount = "assistant_message_count"
        case webhookTimestamp = "webhook_timestamp"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    var duration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        
        // Estimate duration based on message count (rough estimate)
        let estimatedSeconds = messageCount * 30 // 30 seconds per message exchange
        return formatter.string(from: TimeInterval(estimatedSeconds)) ?? "\(estimatedSeconds)s"
    }
    
    var averageMessageLength: Int {
        guard messageCount > 0 else { return 0 }
        let totalLength = transcriptData.reduce(0) { $0 + $1.content.count }
        return totalLength / messageCount
    }
    
    var hasTranscript: Bool {
        return !transcriptData.isEmpty
    }
    
    // MARK: - Equatable
    
    static func == (lhs: InterviewTranscript, rhs: InterviewTranscript) -> Bool {
        return lhs.id == rhs.id
    }
}

struct TranscriptMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    
    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }
    
    enum MessageRole: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
        
        var displayName: String {
            switch self {
            case .user:
                return "You"
            case .assistant:
                return "AI Interviewer"
            }
        }
        
        var color: Color {
            switch self {
            case .user:
                return .blue
            case .assistant:
                return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .user:
                return "person.circle.fill"
            case .assistant:
                return "brain.head.profile"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    var characterCount: Int {
        return content.count
    }
    
    var isQuestion: Bool {
        return content.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")
    }
    
    // MARK: - Equatable
    
    static func == (lhs: TranscriptMessage, rhs: TranscriptMessage) -> Bool {
        return lhs.role == rhs.role && lhs.content == rhs.content
    }
}

// MARK: - Extensions for UI

extension InterviewTranscript {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var summary: String {
        return "\(messageCount) messages • \(userMessageCount) responses • \(assistantMessageCount) questions"
    }
    
    var userQuestions: [TranscriptMessage] {
        return transcriptData.filter { $0.role == .user && $0.isQuestion }
    }
    
    var assistantQuestions: [TranscriptMessage] {
        return transcriptData.filter { $0.role == .assistant && $0.isQuestion }
    }
    
    var longestUserResponse: TranscriptMessage? {
        return transcriptData
            .filter { $0.role == .user }
            .max { $0.wordCount < $1.wordCount }
    }
    
    var averageUserResponseLength: Int {
        let userMessages = transcriptData.filter { $0.role == .user }
        guard !userMessages.isEmpty else { return 0 }
        
        let totalWords = userMessages.reduce(0) { $0 + $1.wordCount }
        return totalWords / userMessages.count
    }
}

// MARK: - Sample Data for Development

extension InterviewTranscript {
    static func sampleTechnicalTranscript() -> InterviewTranscript {
        let messages = [
            TranscriptMessage(role: .assistant, content: "Hello! I'm excited to conduct your technical interview today. Let's start with a simple question: Can you tell me about your experience with iOS development?"),
            TranscriptMessage(role: .user, content: "I have about 5 years of experience with iOS development. I've worked with both UIKit and SwiftUI, and I'm particularly experienced with MVVM architecture and Core Data."),
            TranscriptMessage(role: .assistant, content: "That's great! Now, let's dive into a coding challenge. Can you explain how you would implement a simple caching mechanism for network requests in iOS?"),
            TranscriptMessage(role: .user, content: "I would use NSCache for in-memory caching combined with URLCache for HTTP response caching. For custom caching, I'd create a protocol-based cache manager that can store data both in memory and on disk using FileManager."),
            TranscriptMessage(role: .assistant, content: "Excellent approach! Can you walk me through the time complexity of common operations in different data structures?"),
            TranscriptMessage(role: .user, content: "Sure! Arrays have O(1) for access by index but O(n) for insertion at the beginning. Hash tables have O(1) average case for lookup, insertion, and deletion. Binary search trees have O(log n) for balanced trees but can degrade to O(n) if unbalanced.")
        ]
        
        return InterviewTranscript(
            id: UUID(),
            conversationId: "sample_tech_conv_123",
            transcriptData: messages,
            messageCount: messages.count,
            userMessageCount: messages.filter { $0.role == .user }.count,
            assistantMessageCount: messages.filter { $0.role == .assistant }.count,
            webhookTimestamp: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func sampleBehavioralTranscript() -> InterviewTranscript {
        let messages = [
            TranscriptMessage(role: .assistant, content: "Welcome to your behavioral interview! I'd like to start by learning about your leadership experience. Can you tell me about a time when you had to lead a challenging project?"),
            TranscriptMessage(role: .user, content: "Last year, I led a team of 6 developers to migrate our legacy iOS app to SwiftUI. The challenge was that we had a tight 3-month deadline and the team was initially resistant to the change."),
            TranscriptMessage(role: .assistant, content: "That sounds like a significant challenge. How did you handle the team's resistance to the migration?"),
            TranscriptMessage(role: .user, content: "I organized weekly knowledge-sharing sessions where team members could learn SwiftUI together. I also paired experienced developers with those who were new to SwiftUI. This created a collaborative learning environment and reduced anxiety about the new technology."),
            TranscriptMessage(role: .assistant, content: "Great approach! What was the outcome of the project?"),
            TranscriptMessage(role: .user, content: "We completed the migration 2 weeks ahead of schedule. The app's performance improved by 30%, and the team became much more confident with SwiftUI. Three team members even became SwiftUI advocates and helped train other teams in the company.")
        ]
        
        return InterviewTranscript(
            id: UUID(),
            conversationId: "sample_behavioral_conv_456",
            transcriptData: messages,
            messageCount: messages.count,
            userMessageCount: messages.filter { $0.role == .user }.count,
            assistantMessageCount: messages.filter { $0.role == .assistant }.count,
            webhookTimestamp: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}