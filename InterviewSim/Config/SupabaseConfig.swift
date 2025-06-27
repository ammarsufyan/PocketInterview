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
        
        // Try to get URL and key from environment first
        let supabaseURL = envConfig.supabaseURL ?? "https://icwmrtklyfnwrbpqhksm.supabase.co"
        let apiKey = envConfig.supabaseAnonKey ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imljd21ydGtseWZud3JicHFoa3NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NTU5NjYsImV4cCI6MjA2NjQzMTk2Nn0.howPW3vqhNEWpX3o8eaYBhoaHDuvDM93WOSuzkcrPzI"
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: apiKey
        )
        
        print("✅ Supabase client initialized with URL: \(supabaseURL)")
    }
}