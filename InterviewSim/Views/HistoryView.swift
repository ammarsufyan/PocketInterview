//
//  HistoryView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    
    let filters = ["All", "Technical", "Behavioral"]
    
    // Sample data - focused on Technical and Behavioral only
    let sessions = [
        InterviewSession(id: 1, category: "Technical", difficulty: "Advanced", score: 78, date: Date(), duration: 45, questionsAnswered: 12),
        InterviewSession(id: 2, category: "Behavioral", difficulty: "Intermediate", score: 92, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, duration: 30, questionsAnswered: 8),
        InterviewSession(id: 3, category: "Technical", difficulty: "Intermediate", score: 85, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, duration: 35, questionsAnswered: 10),
        InterviewSession(id: 4, category: "Behavioral", difficulty: "Beginner", score: 88, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, duration: 25, questionsAnswered: 6),
        InterviewSession(id: 5, category: "Technical", difficulty: "Advanced", score: 74, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, duration: 50, questionsAnswered: 15)
    ]
    
    var filteredSessions: [InterviewSession] {
        let filtered = selectedFilter == "All" ? sessions : sessions.filter { $0.category == selectedFilter }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.category.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search sessions...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterTab(
                                title: filter,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Statistics Overview
                if !filteredSessions.isEmpty {
                    HistoryStatsView(sessions: filteredSessions)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                
                // Sessions List
                if filteredSessions.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            HistorySessionCard(session: session)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct InterviewSession: Identifiable {
    let id: Int
    let category: String
    let difficulty: String
    let score: Int
    let date: Date
    let duration: Int // in minutes
    let questionsAnswered: Int
}

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

struct HistoryStatsView: View {
    let sessions: [InterviewSession]
    
    var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.score } / sessions.count
    }
    
    var totalDuration: Int {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var totalQuestions: Int {
        sessions.reduce(0) { $0 + $1.questionsAnswered }
    }
    
    var technicalSessions: Int {
        sessions.filter { $0.category == "Technical" }.count
    }
    
    var behavioralSessions: Int {
        sessions.filter { $0.category == "Behavioral" }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Stats
            HStack(spacing: 16) {
                StatItem(title: "Avg Score", value: "\(averageScore)%", icon: "star.fill", color: .orange)
                StatItem(title: "Total Time", value: "\(totalDuration)m", icon: "clock.fill", color: .blue)
                StatItem(title: "Questions", value: "\(totalQuestions)", icon: "questionmark.circle.fill", color: .green)
            }
            
            // Category Breakdown
            HStack(spacing: 16) {
                CategoryStatItem(title: "Technical", count: technicalSessions, icon: "laptopcomputer", color: .blue)
                CategoryStatItem(title: "Behavioral", count: behavioralSessions, icon: "person.2.fill", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryStatItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistorySessionCard: View {
    let session: InterviewSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: session.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                    .font(.title2)
                    .foregroundColor(session.category == "Technical" ? .blue : .purple)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.category)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(session.difficulty)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.score)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(session.score))
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                Label("\(session.duration) min", systemImage: "clock")
                Label("\(session.questionsAnswered) questions", systemImage: "questionmark.circle")
                
                Spacer()
                
                Text(formatDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .foregroundColor(.secondary)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Sessions Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start your first mock interview to see your history here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    HistoryView()
}