//
//  MockInterviewView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct MockInterviewView: View {
    @State private var selectedCategory = "Technical"
    
    let categories = ["Technical", "Behavioral"]
    
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
                            CategoryCard(
                                title: "Technical",
                                subtitle: "Technical & Problem Solving",
                                description: "Practice technical skills and problem-solving abilities",
                                icon: "laptopcomputer",
                                color: .blue,
                                isSelected: selectedCategory == "Technical"
                            ) {
                                selectedCategory = "Technical"
                            }
                            
                            // Behavioral Category
                            CategoryCard(
                                title: "Behavioral",
                                subtitle: "Soft Skills & Experience",
                                description: "Master STAR method and showcase your experience",
                                icon: "person.2.fill",
                                color: .purple,
                                isSelected: selectedCategory == "Behavioral"
                            ) {
                                selectedCategory = "Behavioral"
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // CV Upload Section (for Technical interviews)
                    if selectedCategory == "Technical" {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Personalize Your Interview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Upload Your CV")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("We'll analyze your background and tailor questions accordingly")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // CV upload action
                                    }) {
                                        Text("Upload")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Start Interview Button
                    VStack(spacing: 16) {
                        Button(action: {
                            // Start interview action
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Start \(selectedCategory) Interview")
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
                        
                        Text("Selected: \(selectedCategory)")
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

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? color : Color(.systemGray6))
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
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
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