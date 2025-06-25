//
//  SupabaseConfig.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

// Temporarily comment out Supabase import until package is properly linked
// import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    // Temporarily comment out client until package is fixed
    // let client: SupabaseClient
    
    private init() {
        // Temporarily comment out until package is properly linked
        /*
        guard let url = URL(string: "https://icwmrtklyfnwrbpqhksm.supabase.co") else {
            fatalError("Invalid Supabase URL")
        }
        
        let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imljd21ydGtseWZud3JicHFoa3NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NTU5NjYsImV4cCI6MjA2NjQzMTk2Nn0.howPW3vqhNEWpX3o8eaYBhoaHDuvDM93WOSuzkcrPzI"
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: apiKey
        )
        */
    }
}