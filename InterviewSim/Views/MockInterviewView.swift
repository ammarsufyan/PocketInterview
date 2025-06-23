//
//  MockInterviewView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct MockInterviewView: View {
    @State private var selectedCategory = "Technical"
    @State private var selectedTechnicalType = "Software Engineering"
    @State private var showTechnicalTypes = false
    
    let categories = ["Technical", "Behavioral"]
    
    let technicalTypes = [
        TechnicalType(
            id: "software-engineering",
            title: "Software Engineering",
            subtitle: "Coding & Algorithms",
            description: "Data structures, algorithms, system design, and coding challenges",
            icon: "laptopcomputer",
            color: .blue
        ),
        TechnicalType(
            id: "ui-ux-design",
            title: "UI/UX Design",
            subtitle: "Design & User Experience",
            description: "Design principles, user research, prototyping, and design systems",
            icon: "paintbrush.fill",
            color: .purple
        ),
        TechnicalType(
            id: "product-management",
            title: "Product Management",
            subtitle: "Strategy & Execution",
            description: "Product strategy, roadmapping, metrics, and stakeholder management",
            icon: "chart.line.uptrend.xyaxis",
            color: .green
        ),
        TechnicalType(
            id: "data-science",
            title: "Data Science",
            subtitle: "Analytics & ML",
            description: "Statistics, machine learning, data analysis, and visualization",
            icon: "chart.bar.fill",
            color: .orange
        ),
        TechnicalType(
            id: "devops",
            title: "DevOps/SRE",
            subtitle: "Infrastructure & Operations",
            description: "Cloud platforms, CI/CD, monitoring, and system reliability",
            icon: "server.rack",
            color: .red
        ),
        TechnicalType(
            id: "cybersecurity",
            title: "Cybersecurity",
            subtitle: "Security & Compliance",
            description: "Security protocols, threat analysis, and risk assessment",
            icon: "lock.shield.fill",
            color: .indigo
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ready to Practice?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Choose your interview type and start practicing")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Interview Categories
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Interview Types")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Technical Category
                            Button(action: {
                                selectedCategory = "Technical"
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showTechnicalTypes.toggle()
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "laptopcomputer")
                                        .font(.title)
                                        .foregroundColor(selectedCategory == "Technical" ? .white : .blue)
                                        .frame(width: 50, height: 50)
                                        .background(selectedCategory == "Technical" ? Color.blue : Color(.systemGray6))
                                        .cornerRadius(12)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Technical")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(selectedCategory == "Technical" ? .white : .primary)
                                        
                                        Text("Multiple Tech Specializations")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedCategory == "Technical" ? .white.opacity(0.9) : .secondary)
                                        
                                        Text("Choose from various tech roles and specializations")
                                            .font(.caption)
                                            .foregroundColor(selectedCategory == "Technical" ? .white.opacity(0.8) : .secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: showTechnicalTypes ? "chevron.up" : "chevron.down")
                                        .font(.title3)
                                        .foregroundColor(selectedCategory == "Technical" ? .white : .secondary)
                                }
                                .padding()
                                .background(
                                    selectedCategory == "Technical" ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedCategory == "Technical" ? Color.clear : Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Technical Specializations (Expandable)
                            if showTechnicalTypes {
                                VStack(spacing: 8) {
                                    ForEach(technicalTypes, id: \.id) { techType in
                                        TechnicalTypeCard(
                                            techType: techType,
                                            isSelected: selectedTechnicalType == techType.title
                                        ) {
                                            selectedTechnicalType = techType.title
                                        }
                                    }
                                }
                                .padding(.leading, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Behavioral Category
                            CategoryCard(
                                title: "Behavioral",
                                subtitle: "Soft Skills & Experience",
                                description: "Master STAR method and showcase your experience",
                                icon: "person.2.fill",
                                isSelected: selectedCategory == "Behavioral"
                            ) {
                                selectedCategory = "Behavioral"
                                showTechnicalTypes = false
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Start Interview Button
                    VStack(spacing: 16) {
                        Button(action: {
                            // Start interview action
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Start \(selectedCategory == "Technical" ? selectedTechnicalType : selectedCategory) Interview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: selectedCategory == "Technical" ? [.blue, .cyan] : [.purple, .pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        Text("Selected: \(selectedCategory == "Technical" ? selectedTechnicalType : selectedCategory)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Mock Interview")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TechnicalType {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
}

struct TechnicalTypeCard: View {
    let techType: TechnicalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: techType.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : techType.color)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? techType.color : techType.color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(techType.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(techType.subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isSelected ? 
                techType.color : 
                Color(.systemGray6).opacity(0.5)
            )
            .cornerRadius(12)
        }
    }
}

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.purple : Color(.systemGray6))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding()
            .background(
                isSelected ? 
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .pink]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) : 
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

#Preview {
    MockInterviewView()
}