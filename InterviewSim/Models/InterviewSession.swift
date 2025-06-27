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
    let durationMinutes: Int
    let questionsAnswered: Int
    let sessionData: SafeAnyCodable
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case sessionName = "session_name"
        case score
        case durationMinutes = "duration_minutes"
        case questionsAnswered = "questions_answered"
        case sessionData = "session_data"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    var duration: Int {
        return durationMinutes
    }
    
    var date: Date {
        return createdAt
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
    
    var formattedDate: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: createdAt)
        }
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var scoreText: String {
        guard let score = score else { return "N/A" }
        return "\(score)%"
    }
}