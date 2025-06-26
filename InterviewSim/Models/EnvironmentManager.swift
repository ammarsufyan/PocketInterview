//
//  EnvironmentManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

class EnvironmentManager: Sendable {
    static let shared = EnvironmentManager()
    
    private let environmentVariables: [String: String]
    
    private init() {
        self.environmentVariables = Self.loadEnvironmentVariables()
    }
    
    private static func loadEnvironmentVariables() -> [String: String] {
        var variables: [String: String] = [:]
        
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ .env file not found. Using default configuration.")
            return variables
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines and comments
                guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else {
                    continue
                }
                
                // Parse key=value pairs
                let components = trimmedLine.components(separatedBy: "=")
                guard components.count >= 2 else { continue }
                
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                
                variables[key] = value
            }
            
            print("✅ Loaded \(variables.count) environment variables")
        } catch {
            print("❌ Error loading .env file: \(error)")
        }
        
        return variables
    }
    
    func getValue(for key: String) -> String? {
        return environmentVariables[key]
    }
    
    func getValue(for key: String, defaultValue: String) -> String {
        return environmentVariables[key] ?? defaultValue
    }
    
    // MARK: - Gemini API Configuration
    var geminiAPIKey: String {
        return getValue(for: "GEMINI_API_KEY") ?? ""
    }
    
    var geminiModel: String {
        return getValue(for: "GEMINI_MODEL", defaultValue: "gemini-1.5-flash-latest")
    }
    
    var geminiBaseURL: String {
        return getValue(for: "GEMINI_BASE_URL", defaultValue: "https://generativelanguage.googleapis.com/v1beta/models")
    }
    
    var geminiMaxTokens: Int {
        let value = getValue(for: "GEMINI_MAX_TOKENS", defaultValue: "2048")
        return Int(value) ?? 2048
    }
    
    var geminiTemperature: Double {
        let value = getValue(for: "GEMINI_TEMPERATURE", defaultValue: "0.1")
        return Double(value) ?? 0.1
    }
    
    // MARK: - Validation
    var isGeminiConfigured: Bool {
        let key = geminiAPIKey
        return !key.isEmpty && key != "YOUR_GEMINI_API_KEY_HERE"
    }
}