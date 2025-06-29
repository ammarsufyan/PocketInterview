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
    
    // 🔥 NEW: Supabase config manager for remote configs
    private let supabaseConfigManager = SupabaseConfigManager()
    
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
        
        // 🔥 NEW: Load remote configs from Supabase
        Task {
            await supabaseConfigManager.loadConfigs()
        }
    }
    
    private func loadFromFile(path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
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
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) // Remove quotes
                    
                    envVariables[key] = value
                }
            }
        } catch {
            // Silently handle file loading errors
        }
    }
    
    private func loadFromInfoPlist() {
        guard let infoPlist = Bundle.main.infoDictionary else { return }
        
        // Load specific keys from Info.plist
        let envKeys = [
            "TAVUS_API_KEY",
            "TAVUS_BASE_URL",
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY",
            "SUPABASE_SERVICE_ROLE_KEY"
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
            "TAVUS_BASE_URL",
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY",
            "SUPABASE_SERVICE_ROLE_KEY"
        ]
        
        for key in envKeys {
            if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
                envVariables[key] = value
            }
        }
    }
    
    // MARK: - Public Access Methods
    
    func getValue(for key: String) -> String? {
        // 🔥 UPDATED: Check Supabase configs first, then local env
        if let supabaseValue = supabaseConfigManager.configs[key], !supabaseValue.isEmpty {
            return supabaseValue
        }
        
        return envVariables[key]
    }
    
    func getValue(for key: String, defaultValue: String) -> String {
        return getValue(for: key) ?? defaultValue
    }
    
    func getBoolValue(for key: String, defaultValue: Bool = false) -> Bool {
        // 🔥 UPDATED: Check Supabase configs first
        if !supabaseConfigManager.configs.isEmpty {
            return supabaseConfigManager.getBoolValue(for: key, defaultValue: defaultValue)
        }
        
        guard let stringValue = envVariables[key] else { return defaultValue }
        return ["true", "1", "yes", "on"].contains(stringValue.lowercased())
    }
    
    func getIntValue(for key: String, defaultValue: Int = 0) -> Int {
        // 🔥 UPDATED: Check Supabase configs first
        if !supabaseConfigManager.configs.isEmpty {
            return supabaseConfigManager.getIntValue(for: key, defaultValue: defaultValue)
        }
        
        guard let stringValue = envVariables[key],
              let intValue = Int(stringValue) else { return defaultValue }
        return intValue
    }
    
    // MARK: - Tavus Configuration
    
    var tavusApiKey: String? {
        return getValue(for: "TAVUS_API_KEY")
    }
    
    var tavusBaseURL: String {
        // 🔥 UPDATED: Prefer Supabase config, fallback to local
        return supabaseConfigManager.tavusBaseURL.isEmpty ? 
            getValue(for: "TAVUS_BASE_URL", defaultValue: "https://tavusapi.com/v2") :
            supabaseConfigManager.tavusBaseURL
    }
    
    // MARK: - Supabase Configuration
    
    var supabaseURL: String? {
        return getValue(for: "SUPABASE_URL")
    }
    
    var supabaseAnonKey: String? {
        return getValue(for: "SUPABASE_ANON_KEY")
    }
    
    var supabaseServiceRoleKey: String? {
        return getValue(for: "SUPABASE_SERVICE_ROLE_KEY")
    }
    
    // MARK: - 🔥 NEW: Remote Config Access
    
    var maxSessionDuration: Int {
        return supabaseConfigManager.maxSessionDuration
    }
    
    var supportedLanguages: [String] {
        return supabaseConfigManager.supportedLanguages
    }
    
    var enableAnalytics: Bool {
        return supabaseConfigManager.enableAnalytics
    }
    
    var appVersion: String {
        return supabaseConfigManager.appVersion
    }
    
    // MARK: - 🔥 NEW: Remote Config Management
    
    func refreshRemoteConfigs() async {
        await supabaseConfigManager.loadConfigs(forceRefresh: true)
    }
    
    var isLoadingRemoteConfigs: Bool {
        return supabaseConfigManager.isLoading
    }
    
    var remoteConfigError: String? {
        return supabaseConfigManager.errorMessage
    }
    
    // MARK: - Validation
    
    func validateTavusConfiguration() -> Bool {
        guard let apiKey = tavusApiKey, !apiKey.isEmpty else {
            return false
        }
        return true
    }
    
    func validateSupabaseConfiguration() -> Bool {
        guard let url = supabaseURL, !url.isEmpty else {
            return false
        }
        
        guard let key = supabaseAnonKey, !key.isEmpty else {
            return false
        }
        
        return true
    }
    
    func validateSupabaseAdminConfiguration() -> Bool {
        guard validateSupabaseConfiguration() else { return false }
        guard let serviceKey = supabaseServiceRoleKey, !serviceKey.isEmpty else { return false }
        return true
    }
}