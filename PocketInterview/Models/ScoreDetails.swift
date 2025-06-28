//
//  ScoreDetails.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 28/06/25.
//

import Foundation
import SwiftUI

struct ScoreDetails: Identifiable, Codable, Equatable {
    let id: UUID
    let conversationId: String
    let clarityScore: Int?
    let clarityReason: String?
    let grammarScore: Int?
    let grammarReason: String?
    let substanceScore: Int?
    let substanceReason: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case clarityScore = "clarity_score"
        case clarityReason = "clarity_reason"
        case grammarScore = "grammar_score"
        case grammarReason = "grammar_reason"
        case substanceScore = "substance_score"
        case substanceReason = "substance_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    var hasScores: Bool {
        return clarityScore != nil || grammarScore != nil || substanceScore != nil
    }
    
    var averageScore: Int? {
        let scores = [clarityScore, grammarScore, substanceScore].compactMap { $0 }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / scores.count
    }
    
    var weightedScore: Int? {
        guard let clarity = clarityScore,
              let grammar = grammarScore,
              let substance = substanceScore else {
            return nil
        }
        
        // Formula: 0.5 * substance + 0.3 * clarity + 0.2 * grammar
        let weighted = (0.5 * Double(substance)) + (0.3 * Double(clarity)) + (0.2 * Double(grammar))
        return Int(weighted.rounded())
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ScoreDetails, rhs: ScoreDetails) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensions for UI

extension ScoreDetails {
    var clarityColor: Color {
        guard let score = clarityScore else { return .gray }
        return scoreColor(for: score)
    }
    
    var grammarColor: Color {
        guard let score = grammarScore else { return .gray }
        return scoreColor(for: score)
    }
    
    var substanceColor: Color {
        guard let score = substanceScore else { return .gray }
        return scoreColor(for: score)
    }
    
    var overallColor: Color {
        guard let score = weightedScore else { return .gray }
        return scoreColor(for: score)
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 80...89:
            return .blue
        case 70...79:
            return .orange
        case 60...69:
            return .yellow
        default:
            return .red
        }
    }
    
    var clarityText: String {
        guard let score = clarityScore else { return "N/A" }
        return "\(score)%"
    }
    
    var grammarText: String {
        guard let score = grammarScore else { return "N/A" }
        return "\(score)%"
    }
    
    var substanceText: String {
        guard let score = substanceScore else { return "N/A" }
        return "\(score)%"
    }
    
    var overallText: String {
        guard let score = weightedScore else { return "N/A" }
        return "\(score)%"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Sample Data for Development

extension ScoreDetails {
    static func sampleTechnicalScore() -> ScoreDetails {
        return ScoreDetails(
            id: UUID(),
            conversationId: "sample_tech_conv_123",
            clarityScore: 78,
            clarityReason: "Good explanation of technical concepts, but could be more concise in some areas.",
            grammarScore: 92,
            grammarReason: "Excellent grammar and vocabulary usage throughout the interview.",
            substanceScore: 85,
            substanceReason: "Strong technical knowledge demonstrated with good problem-solving approach.",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func sampleBehavioralScore() -> ScoreDetails {
        return ScoreDetails(
            id: UUID(),
            conversationId: "sample_behavioral_conv_456",
            clarityScore: 88,
            clarityReason: "Clear and structured responses using STAR method effectively.",
            grammarScore: 85,
            grammarReason: "Good language skills with minor grammatical errors.",
            substanceScore: 90,
            substanceReason: "Excellent examples from experience with strong leadership insights.",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}