//
//  MockInterviewView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct MockInterviewView: View {
    @State private var selectedCategory = "Technical"
    @State private var selectedDifficulty = "Intermediate"
    
    let categories = ["Technical", "Behavioral"]
    let difficulties = ["Beginner", "Intermediate", "Advanced"]
    
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
                                
                                Text("Master technical skills and behavioral questions")
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
                    
                    // Quick Stats
                    HStack(spacing: 16) {
                        StatCard(title: "Sessions", value: "12", icon: "chart.bar.fill", color: .green)
                        StatCard(title: "Avg Score", value: "85%", icon: "star.fill", color: .orange)
                        StatCard(title: "Streak", value: "5 days", icon: "flame.fill", color: .red)
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
                            CategoryCard(
                                title: "Technical",
                                subtitle: "Coding & Problem Solving",
                                description: "Practice algorithms, data structures, and coding challenges",
                                icon: "laptopcomputer",
                                isSelected: selectedCategory == "Technical"
                            ) {
                                selectedCategory = "Technical"
                            }
                            
                            CategoryCard(
                                title: "Behavioral",
                                subtitle: "Soft Skills & Experience",
                                description: "Master STAR method and showcase your experience",
                                icon: "person.2.fill",
                                isSelected: selectedCategory == "Behavioral"
                            ) {
                                selectedCategory = "Behavioral"
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Difficulty Selection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Difficulty Level")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            ForEach(difficulties, id: \.self) { difficulty in
                                DifficultyButton(
                                    title: difficulty,
                                    isSelected: selectedDifficulty == difficulty
                                ) {
                                    selectedDifficulty = difficulty
                                }
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
                        
                        Text("Selected: \(selectedCategory) • \(selectedDifficulty)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Recent Practice Sessions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Continue Practice")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button("See All") {
                                // Navigate to history
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            RecentSessionCard(
                                category: "Technical",
                                difficulty: "Advanced",
                                score: 78,
                                date: "Today"
                            )
                            
                            RecentSessionCard(
                                category: "Behavioral",
                                difficulty: "Intermediate",
                                score: 92,
                                date: "Yesterday"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Mock Interview")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
                    .foregroundColor(isSelected ? .white : (title == "Technical" ? .blue : .purple))
                    .frame(width: 50, height: 50)
                    .background(isSelected ? (title == "Technical" ? Color.blue : Color.purple) : Color(.systemGray6))
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
                    gradient: Gradient(colors: title == "Technical" ? [.blue, .cyan] : [.purple, .pink]),
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

struct DifficultyButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct RecentSessionCard: View {
    let category: String
    let difficulty: String
    let score: Int
    let date: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category == "Technical" ? "laptopcomputer" : "person.2.fill")
                .font(.title2)
                .foregroundColor(category == "Technical" ? .blue : .purple)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(difficulty) • \(date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(score))
                
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70...89: return .orange
        default: return .red
        }
    }
}

#Preview {
    MockInterviewView()
}