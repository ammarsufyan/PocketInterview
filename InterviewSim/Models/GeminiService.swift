//
//  GeminiService.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation

class GeminiService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
    
    init() {
        // TODO: Add your Gemini API key here
        // You can get it from: https://makersuite.google.com/app/apikey
        self.apiKey = "YOUR_GEMINI_API_KEY_HERE"
    }
    
    func analyzeCV(text: String) async throws -> GeminiCVAnalysis {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
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

        Guidelines:
        - Extract ALL technical skills (programming languages, frameworks, tools, technologies)
        - Extract ALL soft skills (leadership, communication, teamwork, etc.)
        - List ALL work positions/titles mentioned
        - Calculate total years of experience from work history
        - Extract ALL educational qualifications (degrees, universities, GPAs, years)
        - Extract ALL certifications with issuing organizations and years if mentioned
        - List ALL projects mentioned
        - Extract ALL achievements, accomplishments, and quantifiable results
        - Extract ALL languages mentioned with proficiency levels
        - Create a concise professional summary

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
                temperature: 0.1,
                topK: 1,
                topP: 1,
                maxOutputTokens: 2048
            )
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
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
        
        // Find JSON object in the response
        guard let jsonStart = responseText.range(of: "{"),
              let jsonEnd = responseText.range(of: "}", options: .backwards) else {
            throw GeminiError.invalidJSON
        }
        
        let jsonString = String(responseText[jsonStart.lowerBound...jsonEnd.upperBound])
        let jsonData = jsonString.data(using: .utf8)!
        
        return try JSONDecoder().decode(GeminiCVAnalysis.self, from: jsonData)
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
            return "Gemini API key is missing. Please add your API key."
        case .invalidURL:
            return "Invalid Gemini API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let code):
            return "Gemini API error: \(code)"
        case .noContent:
            return "No content in Gemini response"
        case .invalidJSON:
            return "Invalid JSON in Gemini response"
        }
    }
}