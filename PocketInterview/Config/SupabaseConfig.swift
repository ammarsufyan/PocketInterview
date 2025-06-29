//
//  SupabaseConfig.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        let envConfig = EnvironmentConfig.shared
        
        // Get URL and key from environment variables
        guard let supabaseURL = envConfig.supabaseURL, !supabaseURL.isEmpty else {
            fatalError("SUPABASE_URL not found in environment variables. Please add it to your .env file.")
        }
        
        guard let apiKey = envConfig.supabaseAnonKey, !apiKey.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not found in environment variables. Please add it to your .env file.")
        }
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: apiKey
        )
    }
    
    // MARK: - Configuration Validation
    
    static func validateConfiguration() -> Bool {
        return EnvironmentConfig.shared.validateSupabaseConfiguration()
    }
}
