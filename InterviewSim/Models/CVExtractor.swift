//
//  CVExtractor.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

class CVExtractor: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isExtracting: Bool = false
    @Published var extractionError: String?
    @Published var cvAnalysis: CVAnalysis?
    
    func extractTextFromDocument(data: Data, fileName: String) {
        isExtracting = true
        extractionError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var extractedContent = ""
            
            // Determine file type based on file extension
            let fileExtension = (fileName as NSString).pathExtension.lowercased()
            
            switch fileExtension {
            case "pdf":
                extractedContent = self?.extractTextFromPDF(data: data) ?? ""
            case "doc", "docx":
                extractedContent = self?.extractTextFromWord(data: data) ?? ""
            default:
                DispatchQueue.main.async {
                    self?.extractionError = "Unsupported file format. Please use PDF, DOC, or DOCX."
                    self?.isExtracting = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.extractedText = extractedContent
                self?.analyzeCV(text: extractedContent)
                self?.isExtracting = false
                
                // Print extracted text for debugging
                print("=== CV EXTRACTION RESULTS ===")
                print("File: \(fileName)")
                print("Type: \(fileExtension.uppercased())")
                print("Text Length: \(extractedContent.count) characters")
                print("=== EXTRACTED TEXT ===")
                print(extractedContent)
                print("=== END EXTRACTION ===")
            }
        }
    }
    
    private func extractTextFromPDF(data: Data) -> String {
        guard let pdfDocument = PDFDocument(data: data) else {
            DispatchQueue.main.async {
                self.extractionError = "Failed to read PDF file"
            }
            return ""
        }
        
        var extractedText = ""
        let pageCount = pdfDocument.pageCount
        
        for pageIndex in 0..<pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                if let pageText = page.string {
                    extractedText += pageText + "\n"
                }
            }
        }
        
        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTextFromWord(data: Data) -> String {
        // For Word documents, we'll simulate extraction since iOS doesn't have built-in Word support
        // In a real app, you'd use a third-party library or server-side extraction
        
        // Simulate some extracted text for demo purposes
        let simulatedText = """
        John Doe
        Senior iOS Developer
        
        EXPERIENCE
        • 5+ years of iOS development experience
        • Expert in Swift, SwiftUI, and UIKit
        • Experience with Core Data, CloudKit, and REST APIs
        • Published 3 apps on the App Store
        
        TECHNICAL SKILLS
        • Programming Languages: Swift, Objective-C, Python
        • Frameworks: SwiftUI, UIKit, Combine, Core Data
        • Tools: Xcode, Git, Firebase, TestFlight
        • Architecture: MVVM, MVC, Clean Architecture
        
        EDUCATION
        • Bachelor of Computer Science
        • iOS Development Bootcamp Certificate
        
        PROJECTS
        • TaskManager Pro - Personal productivity app with 10k+ downloads
        • WeatherNow - Real-time weather app using CoreLocation
        • BudgetTracker - Financial management app with Core Data
        """
        
        return simulatedText
    }
    
    private func analyzeCV(text: String) {
        let analysis = CVAnalysis()
        
        // Extract skills
        analysis.technicalSkills = extractTechnicalSkills(from: text)
        analysis.softSkills = extractSoftSkills(from: text)
        
        // Extract experience
        analysis.workExperience = extractWorkExperience(from: text)
        analysis.yearsOfExperience = extractYearsOfExperience(from: text)
        
        // Extract education
        analysis.education = extractEducation(from: text)
        
        // Extract projects
        analysis.projects = extractProjects(from: text)
        
        self.cvAnalysis = analysis
        
        // Print analysis results
        print("=== CV ANALYSIS RESULTS ===")
        print("Technical Skills: \(analysis.technicalSkills)")
        print("Soft Skills: \(analysis.softSkills)")
        print("Years of Experience: \(analysis.yearsOfExperience)")
        print("Work Experience: \(analysis.workExperience)")
        print("Education: \(analysis.education)")
        print("Projects: \(analysis.projects)")
        print("=== END ANALYSIS ===")
    }
    
    private func extractTechnicalSkills(from text: String) -> [String] {
        let skillKeywords = [
            "Swift", "SwiftUI", "UIKit", "Objective-C", "Python", "Java", "JavaScript",
            "React", "Vue", "Angular", "Node.js", "Express", "MongoDB", "PostgreSQL",
            "MySQL", "Firebase", "AWS", "Docker", "Kubernetes", "Git", "Xcode",
            "Android", "Kotlin", "Flutter", "React Native", "Core Data", "CloudKit",
            "Combine", "RxSwift", "Alamofire", "Realm", "TestFlight", "Fastlane"
        ]
        
        var foundSkills: [String] = []
        let lowercasedText = text.lowercased()
        
        for skill in skillKeywords {
            if lowercasedText.contains(skill.lowercased()) {
                foundSkills.append(skill)
            }
        }
        
        return Array(Set(foundSkills)) // Remove duplicates
    }
    
    private func extractSoftSkills(from text: String) -> [String] {
        let softSkillKeywords = [
            "Leadership", "Communication", "Teamwork", "Problem Solving",
            "Project Management", "Agile", "Scrum", "Mentoring", "Training",
            "Collaboration", "Time Management", "Critical Thinking"
        ]
        
        var foundSkills: [String] = []
        let lowercasedText = text.lowercased()
        
        for skill in softSkillKeywords {
            if lowercasedText.contains(skill.lowercased()) {
                foundSkills.append(skill)
            }
        }
        
        return Array(Set(foundSkills))
    }
    
    private func extractWorkExperience(from text: String) -> [String] {
        // Simple regex to find job titles and companies
        let experiencePatterns = [
            "Senior iOS Developer", "iOS Developer", "Mobile Developer",
            "Software Engineer", "Lead Developer", "Tech Lead",
            "Frontend Developer", "Backend Developer", "Full Stack Developer"
        ]
        
        var experiences: [String] = []
        let lowercasedText = text.lowercased()
        
        for pattern in experiencePatterns {
            if lowercasedText.contains(pattern.lowercased()) {
                experiences.append(pattern)
            }
        }
        
        return experiences
    }
    
    private func extractYearsOfExperience(from text: String) -> Int {
        // Look for patterns like "5+ years", "3 years", etc.
        let regex = try? NSRegularExpression(pattern: "(\\d+)\\+?\\s*years?", options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let yearRange = Range(match.range(at: 1), in: text)
            if let yearRange = yearRange {
                let yearString = String(text[yearRange])
                return Int(yearString) ?? 0
            }
        }
        
        return 0
    }
    
    private func extractEducation(from text: String) -> [String] {
        let educationKeywords = [
            "Bachelor", "Master", "PhD", "Degree", "University", "College",
            "Computer Science", "Software Engineering", "Information Technology",
            "Bootcamp", "Certificate", "Certification"
        ]
        
        var education: [String] = []
        let lowercasedText = text.lowercased()
        
        for keyword in educationKeywords {
            if lowercasedText.contains(keyword.lowercased()) {
                education.append(keyword)
            }
        }
        
        return Array(Set(education))
    }
    
    private func extractProjects(from text: String) -> [String] {
        // Look for project names (usually capitalized words followed by descriptions)
        let lines = text.components(separatedBy: .newlines)
        var projects: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            // Look for lines that might be project names (start with bullet or are short and capitalized)
            if trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*") {
                if trimmedLine.count < 100 && trimmedLine.contains(" ") {
                    let projectName = trimmedLine.replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
                    if !projectName.isEmpty {
                        projects.append(projectName)
                    }
                }
            }
        }
        
        return projects
    }
}

// MARK: - CV Analysis Model
class CVAnalysis: ObservableObject, Equatable {
    @Published var technicalSkills: [String] = []
    @Published var softSkills: [String] = []
    @Published var workExperience: [String] = []
    @Published var yearsOfExperience: Int = 0
    @Published var education: [String] = []
    @Published var projects: [String] = []
    
    var summary: String {
        var summaryParts: [String] = []
        
        if yearsOfExperience > 0 {
            summaryParts.append("\(yearsOfExperience)+ years of experience")
        }
        
        if !technicalSkills.isEmpty {
            let topSkills = Array(technicalSkills.prefix(3))
            summaryParts.append("Skills: \(topSkills.joined(separator: ", "))")
        }
        
        if !workExperience.isEmpty {
            summaryParts.append("Experience: \(workExperience.first ?? "")")
        }
        
        return summaryParts.joined(separator: " • ")
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: CVAnalysis, rhs: CVAnalysis) -> Bool {
        return lhs.technicalSkills == rhs.technicalSkills &&
               lhs.softSkills == rhs.softSkills &&
               lhs.workExperience == rhs.workExperience &&
               lhs.yearsOfExperience == rhs.yearsOfExperience &&
               lhs.education == rhs.education &&
               lhs.projects == rhs.projects
    }
}