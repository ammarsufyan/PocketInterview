//
//  InterviewSession.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import SwiftUI

struct InterviewSession: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let category: String
    let sessionName: String
    let score: Int?
    let expectedDurationMinutes: Int
    let actualDurationMinutes: Int?
    let questionsAnswered: Int
    let createdAt: Date
    let updatedAt: Date
    let conversationId: String?
    let completedTimestamp: Date?
    let sessionStatus: String
    let endReason: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case sessionName = "session_name"
        case score
        case expectedDurationMinutes = "expected_duration_minutes"
        case actualDurationMinutes = "actual_duration_minutes"
        case questionsAnswered = "questions_answered"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case conversationId = "conversation_id"
        case completedTimestamp = "completed_timestamp"
        case sessionStatus = "session_status"
        case endReason = "end_reason"
    }
    
    // MARK: - Computed Properties
    
    var duration: Int {
        return actualDurationMinutes ?? expectedDurationMinutes
    }
    
    var date: Date {
        return completedTimestamp ?? createdAt
    }
    
    var isCompleted: Bool {
        return sessionStatus == "completed"
    }
    
    var isActive: Bool {
        return sessionStatus == "active"
    }
    
    // MARK: - Equatable
    
    static func == (lhs: InterviewSession, rhs: InterviewSession) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensions for UI

extension InterviewSession {
    var categoryColor: Color {
        switch category {
        case "Technical":
            return .blue
        case "Behavioral":
            return .purple
        default:
            return .gray
        }
    }
    
    var scoreColor: Color {
        guard let score = score else { return .gray }
        
        switch score {
        case 90...100:
            return .green
        case 70...89:
            return .orange
        default:
            return .red
        }
    }
    
    var statusColor: Color {
        switch sessionStatus {
        case "completed":
            return .green
        case "active":
            return .blue
        case "created":
            return .orange
        case "cancelled":
            return .red
        case "error":
            return .red
        default:
            return .gray
        }
    }
    
    var formattedDate: String {
        let targetDate = completedTimestamp ?? createdAt
        let calendar = Calendar.current
        
        if calendar.isDateInToday(targetDate) {
            return "Today"
        } else if calendar.isDateInYesterday(targetDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: targetDate)
        }
    }
    
    // MARK: - 🔥 NEW: Actual date format (e.g., "25 June")
    var actualFormattedDate: String {
        let targetDate = completedTimestamp ?? createdAt
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: targetDate)
    }
    
    var formattedTime: String {
        let targetDate = completedTimestamp ?? createdAt
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: targetDate)
    }
    
    var scoreText: String {
        guard let score = score else { return "N/A" }
        return "\(score)%"
    }
    
    var statusText: String {
        switch sessionStatus {
        case "created":
            return "Created"
        case "active":
            return "In Progress"
        case "completed":
            return "Completed"
        case "cancelled":
            return "Cancelled"
        case "error":
            return "Error"
        default:
            return sessionStatus.capitalized
        }
    }
    
    var durationText: String {
        let minutes = duration
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else {
            return "\(minutes)m"
        }
    }
}