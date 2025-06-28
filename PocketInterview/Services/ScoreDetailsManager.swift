//
//  ScoreDetailsManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 28/06/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class ScoreDetailsManager: ObservableObject {
    @Published var scoreDetails: [ScoreDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthListener()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            await loadScoreDetails()
        case .signedOut:
            self.scoreDetails = []
            self.errorMessage = nil
        default:
            break
        }
    }
    
    // MARK: - Data Operations
    
    func loadScoreDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [ScoreDetails] = try await supabase
                .from("score_details")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.scoreDetails = response
            print("✅ Loaded \(response.count) score details")
            
        } catch {
            self.errorMessage = "Failed to load score details"
            print("❌ Failed to load score details: \(error)")
            
            // Fallback to sample data for development
            self.scoreDetails = createSampleScoreDetails()
        }
        
        isLoading = false
    }
    
    func getScoreDetails(for conversationId: String) async -> ScoreDetails? {
        do {
            let response: ScoreDetails = try await supabase
                .from("score_details")
                .select()
                .eq("conversation_id", value: conversationId)
                .single()
                .execute()
                .value
            
            return response
            
        } catch {
            print("❌ Failed to load score details for conversation \(conversationId): \(error)")
            return nil
        }
    }
    
    func getScoreDetailsForSession(_ session: InterviewSession) async -> ScoreDetails? {
        guard let conversationId = session.conversationId else {
            return nil
        }
        
        return await getScoreDetails(for: conversationId)
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func refreshScoreDetails() async {
        await loadScoreDetails()
    }
    
    func hasScoreDetails(for conversationId: String?) -> Bool {
        guard let conversationId = conversationId else { return false }
        return scoreDetails.contains { $0.conversationId == conversationId }
    }
    
    func getLocalScoreDetails(for conversationId: String) -> ScoreDetails? {
        return scoreDetails.first { $0.conversationId == conversationId }
    }
    
    // MARK: - Sample Data (for development/testing)
    
    private func createSampleScoreDetails() -> [ScoreDetails] {
        return [
            ScoreDetails.sampleTechnicalScore(),
            ScoreDetails.sampleBehavioralScore()
        ]
    }
}