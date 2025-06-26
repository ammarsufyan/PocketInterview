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
    
    // Enhanced sample data with more specific timestamps and session names
    let sessions = [
        InterviewSession(
            id: 1, 
            category: "Technical", 
            sessionName: "iOS Developer Practice", 
            score: 78, 
            date: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!, 
            duration: 45, 
            questionsAnswered: 12
        ),
        InterviewSession(
            id: 2, 
            category: "Technical", 
            sessionName: "Swift Algorithms", 
            score: 85, 
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, 
            duration: 35, 
            questionsAnswered: 10
        ),
        InterviewSession(
            id: 3, 
            category: "Behavioral", 
            sessionName: "Leadership Questions", 
            score: 92, 
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 
            duration: 30, 
            questionsAnswered: 8
        ),
        InterviewSession(
            id: 4, 
            category: "Technical", 
            sessionName: "System Design", 
            score: 74, 
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 
            duration: 50, 
            questionsAnswered: 15
        ),
        InterviewSession(
            id: 5, 
            category: "Behavioral", 
            sessionName: "Team Collaboration", 
            score: 88, 
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 
            duration: 25, 
            questionsAnswered: 6
        )
    ]
    
    var filteredSessions: [InterviewSession] {
        let filtered = selectedFilter == "All" ? sessions : sessions.filter { $0.category == selectedFilter }
        
        if searchText.isEmpty {
            return filtered.sorted { $0.date > $1.date }
        } else {
            return filtered.filter { 
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.sessionName.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.date > $1.date }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Search sessions...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.subheadline)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterTab(
                                title: filter,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                
                // Statistics Overview
                if !filteredSessions.isEmpty {
                    HistoryStatsView(sessions: filteredSessions)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Sessions List
                if filteredSessions.isEmpty {
                    EmptyStateView(searchText: searchText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredSessions) { session in
                                HistorySessionCard(session: session)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
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
    let sessionName: String // New field for session title
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
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
                    radius: isSelected ? 4 : 0,
                    x: 0,
                    y: 2
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(title: "Avg Score", value: "\(averageScore)%", icon: "star.fill", color: .orange)
            StatItem(title: "Total Time", value: "\(totalDuration)m", icon: "clock.fill", color: .blue)
            StatItem(title: "Questions", value: "\(totalQuestions)", icon: "questionmark.circle.fill", color: .green)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .symbolRenderingMode(.hierarchical)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistorySessionCard: View {
    let session: InterviewSession
    
    private var categoryColor: Color {
        session.category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Image(systemName: session.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                .font(.title2)
                .foregroundColor(categoryColor)
                .frame(width: 48, height: 48)
                .background(categoryColor.opacity(0.1))
                .cornerRadius(12)
                .symbolRenderingMode(.hierarchical)
            
            // Session Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.sessionName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(session.category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(categoryColor)
                    }
                    
                    Spacer()
                    
                    Text("\(session.score)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(session.score))
                }
                
                HStack(spacing: 16) {
                    Label("\(session.duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(session.questionsAnswered) questions", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formatDate(session.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text(formatTime(session.date))
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70...89: return .orange
        default: return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "clock.badge.questionmark" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Sessions Yet" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "Start your first mock interview to see your history here" :
                     "Try adjusting your search or filter criteria"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    HistoryView()
}