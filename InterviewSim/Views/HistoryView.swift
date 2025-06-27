//
//  HistoryView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = InterviewHistoryManager()
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: InterviewSession?
    
    let filters = ["All", "Technical", "Behavioral"]
    
    var filteredSessions: [InterviewSession] {
        let filtered = selectedFilter == "All" ? 
            historyManager.sessions : 
            historyManager.sessions.filter { $0.category == selectedFilter }
        
        if searchText.isEmpty {
            return filtered.sorted { $0.createdAt > $1.createdAt }
        } else {
            return filtered.filter { 
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.sessionName.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Statistics Summary
                VStack(spacing: 20) {
                    // Statistics Overview
                    if !filteredSessions.isEmpty {
                        HistoryStatsView(sessions: filteredSessions)
                            .padding(.horizontal, 20)
                    }
                    
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
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Content
                if historyManager.isLoading {
                    LoadingView()
                } else if filteredSessions.isEmpty {
                    EmptyStateView(
                        searchText: searchText,
                        hasData: !historyManager.sessions.isEmpty
                    )
                } else {
                    SessionsList(
                        sessions: filteredSessions,
                        onDelete: { session in
                            sessionToDelete = session
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await historyManager.refreshSessions()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task {
                                await historyManager.refreshSessions()
                            }
                        }
                        
                        Button("Add Sample Data", systemImage: "plus.circle") {
                            Task {
                                await historyManager.addSampleData()
                            }
                        }
                        
                        if let errorMessage = historyManager.errorMessage {
                            Button("Clear Error", systemImage: "xmark.circle") {
                                historyManager.clearError()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Session", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await historyManager.deleteSession(session)
                        }
                    }
                    sessionToDelete = nil
                }
            } message: {
                if let session = sessionToDelete {
                    Text("Are you sure you want to delete '\(session.sessionName)'? This action cannot be undone.")
                }
            }
            .onAppear {
                Task {
                    await historyManager.loadSessions()
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your interview history...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct SessionsList: View {
    let sessions: [InterviewSession]
    let onDelete: (InterviewSession) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sessions) { session in
                    HistorySessionCard(
                        session: session,
                        onDelete: {
                            onDelete(session)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
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
        let sessionsWithScores = sessions.compactMap { $0.score }
        guard !sessionsWithScores.isEmpty else { return 0 }
        return sessionsWithScores.reduce(0, +) / sessionsWithScores.count
    }
    
    var totalDuration: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
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
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Image(systemName: session.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                .font(.title2)
                .foregroundColor(session.categoryColor)
                .frame(width: 48, height: 48)
                .background(session.categoryColor.opacity(0.1))
                .cornerRadius(12)
                .symbolRenderingMode(.hierarchical)
            
            // Session Info
            VStack(alignment: .leading, spacing: 8) {
                // Session Name and Score
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.sessionName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(session.category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(session.categoryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(session.categoryColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(session.scoreText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(session.scoreColor)
                }
                
                // Session Details
                HStack(spacing: 16) {
                    Label("\(session.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(session.questionsAnswered) questions", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(session.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text(session.formattedTime)
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
        .contextMenu {
            Button("Delete Session", systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    let hasData: Bool
    
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
                     (hasData ? "No sessions match your current filter" : "Start your first mock interview to see your history here") :
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