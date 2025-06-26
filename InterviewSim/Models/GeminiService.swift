//
//  GeminiService.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

class GeminiService: ObservableObject {
    private let environmentManager = EnvironmentManager.shared
    
    private var apiKey: String {
        return environmentManager.geminiAPIKey
    }
    
    private var baseURL: String {
        return "\(environmentManager.geminiBaseURL)/\(environmentManager.geminiModel):generateContent"
    }
    
    func analyzeCV(text: String) async throws -> GeminiCVAnalysis {
        guard environmentManager.isGeminiConfigured else {
            throw GeminiError.missingAPIKey
        }
        
        let prompt = createCVAnalysisPrompt(cvText: text)
        let response = try await sendRequest(prompt: prompt)
        return try parseResponse(response)
    }
    
    private func createCVAnalysisPrompt(cvText: String) -> String {
        return """
        Analyze the following CV/Resume text and extract structured information. Return ONLY a valid JSON object with the following structure:

        {
          "technicalSkills": ["skill1", "skill2", ...],
          "softSkills": ["skill1", "skill2", ...],
          "workExperience": ["position1", "position2", ...],
          "yearsOfExperience": number,
          "education": ["degree1", "degree2", ...],
          "certifications": ["cert1", "cert2", ...],
          "projects": ["project1", "project2", ...],
          "achievements": ["achievement1", "achievement2", ...],
          "languages": ["language1", "language2", ...],
          "summary": "brief professional summary"
        }

        Guidelines for extraction:
        
        📊 TECHNICAL SKILLS:
        - Programming languages (Swift, Python, Java, JavaScript, etc.)
        - Frameworks and libraries (SwiftUI, React, Django, etc.)
        - Tools and platforms (Xcode, Git, AWS, Docker, etc.)
        - Databases (MySQL, PostgreSQL, MongoDB, etc.)
        - Operating systems and technologies
        
        🤝 SOFT SKILLS:
        - Leadership, communication, teamwork
        - Problem-solving, analytical thinking
        - Project management, time management
        - Creativity, adaptability, mentoring
        
        💼 WORK EXPERIENCE:
        - Extract job titles/positions only
        - Include seniority levels (Junior, Senior, Lead, etc.)
        - Focus on role names, not company names
        
        ⏰ YEARS OF EXPERIENCE:
        - Calculate total professional experience
        - Look for patterns like "5+ years", "2019-2024", etc.
        - Sum up all work periods mentioned
        
        🎓 EDUCATION:
        - Degrees with full details (Bachelor of Science in Computer Science)
        - Universities and institutions
        - Graduation years, GPAs if mentioned
        - Relevant coursework, thesis topics
        - Academic honors (Magna Cum Laude, Dean's List, etc.)
        
        🏆 CERTIFICATIONS:
        - Full certification names with issuing organizations
        - Include years obtained if mentioned
        - Professional certifications (AWS, Google Cloud, etc.)
        - Industry certifications (PMP, Scrum Master, etc.)
        
        🚀 PROJECTS:
        - Project names and brief descriptions
        - Personal, academic, or professional projects
        - Open source contributions
        - Notable achievements in projects
        
        ⭐ ACHIEVEMENTS:
        - Quantifiable accomplishments (increased performance by 40%)
        - Awards and recognitions
        - Publications, speaking engagements
        - Leadership accomplishments
        
        🌍 LANGUAGES:
        - Spoken languages with proficiency levels
        - Programming languages should go in technical skills
        
        📝 SUMMARY:
        - Create a 2-3 sentence professional summary
        - Include years of experience, key skills, and focus area
        - Make it compelling and accurate

        CV Text:
        """
        + cvText
    }
    
    private func sendRequest(prompt: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: environmentManager.geminiTemperature,
                topK: 1,
                topP: 1,
                maxOutputTokens: environmentManager.geminiMaxTokens
            )
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        print("🚀 Sending request to Gemini API...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("📡 Gemini API response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) {
                print("❌ Gemini API error response: \(errorData)")
            }
            throw GeminiError.apiError(httpResponse.statusCode)
        }
        
        return data
    }
    
    private func parseResponse(_ data: Data) throws -> GeminiCVAnalysis {
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let candidate = response.candidates.first,
              let part = candidate.content.parts.first else {
            throw GeminiError.noContent
        }
        
        // Extract JSON from the response text
        let responseText = part.text
        print("📝 Raw Gemini response: \(responseText)")
        
        // Find JSON object in the response
        guard let jsonStart = responseText.range(of: "{"),
              let jsonEnd = responseText.range(of: "}", options: .backwards) else {
            print("❌ No JSON found in response: \(responseText)")
            throw GeminiError.invalidJSON
        }
        
        let jsonString = String(responseText[jsonStart.lowerBound...jsonEnd.upperBound])
        print("🔍 Extracted JSON: \(jsonString)")
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }
        
        do {
            let analysis = try JSONDecoder().decode(GeminiCVAnalysis.self, from: jsonData)
            print("✅ Successfully parsed Gemini analysis")
            return analysis
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 JSON string: \(jsonString)")
            throw GeminiError.invalidJSON
        }
    }
}

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

// MARK: - Gemini CV Analysis Result
struct GeminiCVAnalysis: Codable {
    let technicalSkills: [String]
    let softSkills: [String]
    let workExperience: [String]
    let yearsOfExperience: Int
    let education: [String]
    let certifications: [String]
    let projects: [String]
    let achievements: [String]
    let languages: [String]
    let summary: String
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case noContent
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing or invalid. Please check your .env file."
        case .invalidURL:
            return "Invalid Gemini API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let code):
            return "Gemini API error: \(code). Check your API key and quota."
        case .noContent:
            return "No content in Gemini response"
        case .invalidJSON:
            return "Invalid JSON in Gemini response"
        }
    }
}