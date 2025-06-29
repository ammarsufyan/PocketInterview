//
//  SupabaseConfigManager.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import Foundation
import Supabase

@MainActor
class SupabaseConfigManager: ObservableObject {
    @Published var configs: [String: String] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.shared.client
    private let cacheKey = "supabase_configs_cache"
    private let cacheExpiryKey = "supabase_configs_cache_expiry"
    private let cacheExpiryHours: TimeInterval = 24 * 60 * 60 // 24 hours
    
    init() {
        loadCachedConfigs()
    }
    
    // MARK: - Public Methods
    
    func loadConfigs(forceRefresh: Bool = false) async {
        if !forceRefresh && isCacheValid() {
            print("✅ Using cached configs")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [AppConfigRow] = try await supabase
                .from("app_config")
                .select()
                .eq("is_public", value: true)
                .execute()
                .value
            
            let newConfigs = Dictionary(uniqueKeysWithValues: 
                response.map { ($0.keyName, $0.keyValue) }
            )
            
            self.configs = newConfigs
            cacheConfigs(newConfigs)
            
            print("✅ Loaded \(newConfigs.count) configs from Supabase")
            
        } catch {
            self.errorMessage = "Failed to load app configuration"
            print("❌ Failed to load configs: \(error)")
            
            // Fallback to cached configs if available
            if configs.isEmpty {
                loadCachedConfigs()
            }
        }
        
        isLoading = false
    }
    
    func getValue(for key: String, defaultValue: String = "") -> String {
        return configs[key] ?? defaultValue
    }
    
    func getBoolValue(for key: String, defaultValue: Bool = false) -> Bool {
        guard let stringValue = configs[key] else { return defaultValue }
        return ["true", "1", "yes", "on"].contains(stringValue.lowercased())
    }
    
    func getIntValue(for key: String, defaultValue: Int = 0) -> Int {
        guard let stringValue = configs[key],
              let intValue = Int(stringValue) else { return defaultValue }
        return intValue
    }
    
    // MARK: - Specific Config Getters
    
    var tavusBaseURL: String {
        return getValue(for: "TAVUS_BASE_URL", defaultValue: "https://tavusapi.com/v2")
    }
    
    var appVersion: String {
        return getValue(for: "APP_VERSION", defaultValue: "1.0.0")
    }
    
    var supportedLanguages: [String] {
        let languagesString = getValue(for: "SUPPORTED_LANGUAGES", defaultValue: "english")
        return languagesString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var maxSessionDuration: Int {
        return getIntValue(for: "MAX_SESSION_DURATION_MINUTES", defaultValue: 60)
    }
    
    var enableAnalytics: Bool {
        return getBoolValue(for: "ENABLE_ANALYTICS", defaultValue: false)
    }
    
    // MARK: - Cache Management
    
    private func loadCachedConfigs() {
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedConfigs = try? JSONDecoder().decode([String: String].self, from: cachedData) {
            self.configs = cachedConfigs
            print("✅ Loaded cached configs: \(cachedConfigs.count) items")
        }
    }
    
    private func cacheConfigs(_ configs: [String: String]) {
        if let encoded = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheExpiryKey)
        }
    }
    
    private func isCacheValid() -> Bool {
        guard let cacheDate = UserDefaults.standard.object(forKey: cacheExpiryKey) as? Date else {
            return false
        }
        
        return Date().timeIntervalSince(cacheDate) < cacheExpiryHours
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpiryKey)
        configs.removeAll()
    }
}

// MARK: - Data Models

struct AppConfigRow: Codable {
    let id: UUID
    let keyName: String
    let keyValue: String
    let isPublic: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case keyName = "key_name"
        case keyValue = "key_value"
        case isPublic = "is_public"
        case createdAt = "created_at"
    }
}