//
//  EnvironmentConfig.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    
    private var envVariables: [String: String] = [:]
    
    private init() {
        loadEnvironmentVariables()
    }
    
    // MARK: - Environment Loading
    
    private func loadEnvironmentVariables() {
        // Try to load from .env file first
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            loadFromFile(path: envPath)
        }
        
        // Also load from Info.plist for production builds
        loadFromInfoPlist()
        
        // Fallback to system environment variables
        loadFromSystemEnvironment()
    }
    
    private func loadFromFile(path: String) {
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse key=value pairs
                let components = trimmedLine.components(separatedBy: "=")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components.dropFirst().joined(separator: "=")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    envVariables[key] = value
                }
            }
            
            print("✅ Loaded environment variables from .env file")
        } catch {
            print("⚠️ Could not load .env file: \(error)")
        }
    }
    
    private func loadFromInfoPlist() {
        guard let infoPlist = Bundle.main.infoDictionary else { return }
        
        // Load specific keys from Info.plist
        let envKeys = [
            "TAVUS_API_KEY",
            "TAVUS_REPLICA_ID",
            "TAVUS_BASE_URL",
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY"
        ]
        
        for key in envKeys {
            if let value = infoPlist[key] as? String, !value.isEmpty {
                envVariables[key] = value
            }
        }
    }
    
    private func loadFromSystemEnvironment() {
        let envKeys = [
            "TAVUS_API_KEY",
            "TAVUS_REPLICA_ID",
            "TAVUS_BASE_URL",
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY"
        ]
        
        for key in envKeys {
            if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
                envVariables[key] = value
            }
        }
    }
    
    // MARK: - Public Access Methods
    
    func getValue(for key: String) -> String? {
        return envVariables[key]
    }
    
    func getValue(for key: String, defaultValue: String) -> String {
        return envVariables[key] ?? defaultValue
    }
    
    func getBoolValue(for key: String, defaultValue: Bool = false) -> Bool {
        guard let stringValue = envVariables[key] else { return defaultValue }
        return ["true", "1", "yes", "on"].contains(stringValue.lowercased())
    }
    
    func getIntValue(for key: String, defaultValue: Int = 0) -> Int {
        guard let stringValue = envVariables[key],
              let intValue = Int(stringValue) else { return defaultValue }
        return intValue
    }
    
    // MARK: - Tavus Configuration
    
    var tavusApiKey: String? {
        return getValue(for: "TAVUS_API_KEY")
    }
    
    var tavusReplicaId: String? {
        return getValue(for: "TAVUS_REPLICA_ID")
    }
    
    var tavusBaseURL: String {
        return getValue(for: "TAVUS_BASE_URL", defaultValue: "https://tavusapi.com/v2")
    }
    
    // MARK: - Supabase Configuration
    
    var supabaseURL: String? {
        return getValue(for: "SUPABASE_URL")
    }
    
    var supabaseAnonKey: String? {
        return getValue(for: "SUPABASE_ANON_KEY")
    }
    
    // MARK: - Validation
    
    func validateTavusConfiguration() -> Bool {
        guard let apiKey = tavusApiKey, !apiKey.isEmpty else {
            print("❌ TAVUS_API_KEY not found in environment")
            return false
        }
        
        guard let replicaId = tavusReplicaId, !replicaId.isEmpty else {
            print("❌ TAVUS_REPLICA_ID not found in environment")
            return false
        }
        
        print("✅ Tavus configuration is valid")
        return true
    }
    
    func validateSupabaseConfiguration() -> Bool {
        guard let url = supabaseURL, !url.isEmpty else {
            print("❌ SUPABASE_URL not found in environment")
            return false
        }
        
        guard let key = supabaseAnonKey, !key.isEmpty else {
            print("❌ SUPABASE_ANON_KEY not found in environment")
            return false
        }
        
        print("✅ Supabase configuration is valid")
        return true
    }
    
    // MARK: - Debug Information
    
    func printLoadedVariables() {
        print("🔧 Loaded Environment Variables:")
        for (key, value) in envVariables {
            // Mask sensitive values
            let maskedValue = key.contains("KEY") || key.contains("SECRET") ? 
                String(repeating: "*", count: min(value.count, 8)) : value
            print("  \(key): \(maskedValue)")
        }
    }
}