//
//  CVExtractionResultView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct CVExtractionResultView: View {
    @ObservedObject var cvExtractor: CVExtractor
    let category: String
    @Environment(\.dismiss) private var dismiss
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(categoryColor)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("CV Analysis Complete")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Here's what we extracted from your CV")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Analysis Results
                    if let analysis = cvExtractor.cvAnalysis {
                        VStack(spacing: 20) {
                            // Summary Card
                            if !analysis.summary.isEmpty {
                                AnalysisCard(
                                    title: "Summary",
                                    icon: "person.circle.fill",
                                    color: categoryColor,
                                    content: analysis.summary
                                )
                            }
                            
                            // Technical Skills
                            if !analysis.technicalSkills.isEmpty {
                                SkillsCard(
                                    title: "Technical Skills",
                                    icon: "laptopcomputer",
                                    color: .blue,
                                    skills: analysis.technicalSkills
                                )
                            }
                            
                            // Soft Skills
                            if !analysis.softSkills.isEmpty {
                                SkillsCard(
                                    title: "Soft Skills",
                                    icon: "person.2.fill",
                                    color: .purple,
                                    skills: analysis.softSkills
                                )
                            }
                            
                            // Work Experience
                            if !analysis.workExperience.isEmpty {
                                ListCard(
                                    title: "Work Experience",
                                    icon: "briefcase.fill",
                                    color: .orange,
                                    items: analysis.workExperience
                                )
                            }
                            
                            // Education
                            if !analysis.education.isEmpty {
                                ListCard(
                                    title: "Education",
                                    icon: "graduationcap.fill",
                                    color: .green,
                                    items: analysis.education
                                )
                            }
                            
                            // Certifications
                            if !analysis.certifications.isEmpty {
                                ListCard(
                                    title: "Certifications",
                                    icon: "award.fill",
                                    color: .yellow,
                                    items: analysis.certifications
                                )
                            }
                            
                            // Projects
                            if !analysis.projects.isEmpty {
                                ListCard(
                                    title: "Projects",
                                    icon: "folder.fill",
                                    color: .cyan,
                                    items: analysis.projects
                                )
                            }
                            
                            // Achievements
                            if !analysis.achievements.isEmpty {
                                ListCard(
                                    title: "Key Achievements",
                                    icon: "star.fill",
                                    color: .pink,
                                    items: analysis.achievements
                                )
                            }
                        }
                    }
                    
                    // Raw Extracted Text (Collapsible)
                    if !cvExtractor.extractedText.isEmpty {
                        RawTextCard(
                            extractedText: cvExtractor.extractedText,
                            categoryColor: categoryColor
                        )
                    }
                    
                    // Continue Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            
                            Text("Continue to Interview Setup")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [categoryColor, categoryColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: categoryColor.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("CV Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(categoryColor)
                }
            }
        }
    }
}

struct AnalysisCard: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SkillsCard: View {
    let title: String
    let icon: String
    let color: Color
    let skills: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(skills.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(skills, id: \.self) { skill in
                    Text(skill)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ListCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.prefix(5)), id: \.self) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                }
                
                if items.count > 5 {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Text("and \(items.count - 5) more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct RawTextCard: View {
    let extractedText: String
    let categoryColor: Color
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(categoryColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Raw Extracted Text")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(extractedText.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                ScrollView {
                    Text(extractedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .frame(maxHeight: 300)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(categoryColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    let extractor = CVExtractor()
    extractor.extractedText = "Sample extracted text from CV..."
    
    let analysis = CVAnalysis()
    analysis.technicalSkills = ["Swift", "SwiftUI", "iOS", "Xcode", "Python", "JavaScript"]
    analysis.softSkills = ["Leadership", "Communication", "Problem Solving"]
    analysis.workExperience = ["Senior iOS Developer", "Mobile Developer"]
    analysis.yearsOfExperience = 5
    analysis.education = ["Bachelor of Computer Science", "iOS Development Bootcamp"]
    analysis.projects = ["TaskManager Pro", "WeatherNow", "BudgetTracker"]
    analysis.certifications = ["AWS Certified Developer", "iOS Developer Certificate"]
    analysis.achievements = ["Increased app performance by 40%", "Led team of 5 developers"]
    extractor.cvAnalysis = analysis
    
    return CVExtractionResultView(cvExtractor: extractor, category: "Technical")
}