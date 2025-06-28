//
//  HistoryView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = InterviewHistoryManager()
    @StateObject private var transcriptManager = TranscriptManager()
    @StateObject private var scoreDetailsManager = ScoreDetailsManager()
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
                                HistoryFilterTab(
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
                        transcriptManager: transcriptManager,
                        scoreDetailsManager: scoreDetailsManager,
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
                await transcriptManager.refreshTranscripts()
                await scoreDetailsManager.refreshScoreDetails()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task {
                                await historyManager.refreshSessions()
                                await transcriptManager.refreshTranscripts()
                                await scoreDetailsManager.refreshScoreDetails()
                            }
                        }
                        
                        Button("Add Sample Data", systemImage: "plus.circle") {
                            Task {
                                await historyManager.addSampleData()
                            }
                        }
                        
                        if historyManager.errorMessage != nil {
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
                    await transcriptManager.loadTranscripts()
                    await scoreDetailsManager.loadScoreDetails()
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
    @ObservedObject var transcriptManager: TranscriptManager
    @ObservedObject var scoreDetailsManager: ScoreDetailsManager
    let onDelete: (InterviewSession) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(
                        session: session,
                        transcriptManager: transcriptManager,
                        scoreDetailsManager: scoreDetailsManager
                    )) {
                        HistorySessionCard(
                            session: session,
                            hasTranscript: transcriptManager.hasTranscript(for: session.conversationId),
                            hasScoreDetails: scoreDetailsManager.hasScoreDetails(for: session.conversationId),
                            onDelete: {
                                onDelete(session)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

struct HistoryFilterTab: View {
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
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var totalQuestions: Int {
        sessions.reduce(0) { $0 + $1.questionsAnswered }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            HistoryStatItem(title: "Avg Score", value: "\(averageScore)%", icon: "star.fill", color: .orange)
            HistoryStatItem(title: "Total Time", value: "\(totalDuration)m", icon: "clock.fill", color: .blue)
            HistoryStatItem(title: "Questions", value: "\(totalQuestions)", icon: "questionmark.circle.fill", color: .green)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct HistoryStatItem: View {
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

// MARK: - 🔥 CLEANED UP History Session Card
struct HistorySessionCard: View {
    let session: InterviewSession
    let hasTranscript: Bool
    let hasScoreDetails: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon (no score badge)
            Image(systemName: session.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                .font(.title2)
                .foregroundColor(session.categoryColor)
                .frame(width: 48, height: 48)
                .background(session.categoryColor.opacity(0.1))
                .cornerRadius(12)
                .symbolRenderingMode(.hierarchical)
            
            // Session Info - CLEANED UP
            VStack(alignment: .leading, spacing: 8) {
                // Session Name and Main Info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.sessionName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // SIMPLIFIED: Only show category and status
                        HStack(spacing: 8) {
                            Text(session.category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(session.categoryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(session.categoryColor.opacity(0.1))
                                .cornerRadius(4)
                            
                            Text(session.statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(session.statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(session.statusColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    // Score Display - CLEANED UP
                    VStack(alignment: .trailing, spacing: 4) {
                        if let score = session.score {
                            Text("\(score)%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(session.scoreColor)
                        } else {
                            Text("No Score")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // SIMPLIFIED: Only show date/time (removed duration)
                HStack(spacing: 16) {
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

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: InterviewSession
    @ObservedObject var transcriptManager: TranscriptManager
    @ObservedObject var scoreDetailsManager: ScoreDetailsManager
    @State private var transcript: InterviewTranscript?
    @State private var scoreDetails: ScoreDetails?
    @State private var isLoadingTranscript = false
    @State private var isLoadingScoreDetails = false
    
    private var categoryColor: Color {
        session.categoryColor
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Session Header
                VStack(spacing: 16) {
                    // Category Icon
                    Image(systemName: session.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor)
                        .frame(width: 100, height: 100)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(20)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text(session.sessionName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("\(session.category) Interview")
                            .font(.headline)
                            .foregroundColor(categoryColor)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 20)
                
                // Session Details Cards
                VStack(spacing: 16) {
                    // Score Card
                    DetailCard(
                        title: "Overall Score",
                        value: session.scoreText,
                        icon: "star.fill",
                        color: session.scoreColor
                    )
                    
                    // Duration Card
                    DetailCard(
                        title: "Duration",
                        value: session.durationText,
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    // Questions Card
                    DetailCard(
                        title: "Questions Answered",
                        value: "\(session.questionsAnswered)",
                        icon: "questionmark.circle.fill",
                        color: .green
                    )
                    
                    // Date Card
                    DetailCard(
                        title: "Date & Time",
                        value: "\(session.formattedDate) at \(session.formattedTime)",
                        icon: "calendar",
                        color: .purple
                    )
                }
                .padding(.horizontal, 20)
                
                // Score Details Section
                if let scoreDetails = scoreDetails {
                    ScoreDetailsCard(
                        scoreDetails: scoreDetails,
                        categoryColor: categoryColor
                    )
                    .padding(.horizontal, 20)
                } else if !isLoadingScoreDetails {
                    NoScoreDetailsCard()
                        .padding(.horizontal, 20)
                }
                
                // Transcript Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Transcript")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if isLoadingTranscript {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if let transcript = transcript {
                        TranscriptCard(
                            transcript: transcript,
                            session: session,
                            categoryColor: categoryColor
                        )
                        .padding(.horizontal, 20)
                    } else if !isLoadingTranscript {
                        NoTranscriptCard()
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadTranscript()
            loadScoreDetails()
        }
    }
    
    private func loadTranscript() {
        // Check if transcript is already loaded locally
        if let conversationId = session.conversationId,
           let localTranscript = transcriptManager.getLocalTranscript(for: conversationId) {
            self.transcript = localTranscript
            return
        }
        
        // Load from server
        guard let conversationId = session.conversationId else { return }
        
        isLoadingTranscript = true
        
        Task {
            let loadedTranscript = await transcriptManager.getTranscript(for: conversationId)
            
            await MainActor.run {
                self.transcript = loadedTranscript
                self.isLoadingTranscript = false
            }
        }
    }
    
    private func loadScoreDetails() {
        // Check if score details are already loaded locally
        if let conversationId = session.conversationId,
           let localScoreDetails = scoreDetailsManager.getLocalScoreDetails(for: conversationId) {
            self.scoreDetails = localScoreDetails
            return
        }
        
        // Load from server
        guard let conversationId = session.conversationId else { return }
        
        isLoadingScoreDetails = true
        
        Task {
            let loadedScoreDetails = await scoreDetailsManager.getScoreDetails(for: conversationId)
            
            await MainActor.run {
                self.scoreDetails = loadedScoreDetails
                self.isLoadingScoreDetails = false
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(12)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ScoreDetailsCard: View {
    let scoreDetails: ScoreDetails
    let categoryColor: Color
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(categoryColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Score Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let overallScore = scoreDetails.weightedScore {
                            Text("Overall: \(overallScore)%")
                                .font(.caption)
                                .foregroundColor(scoreDetails.overallColor)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Score Overview (Always Visible)
            HStack(spacing: 16) {
                ScoreItem(
                    title: "Substance",
                    score: scoreDetails.substanceScore,
                    color: scoreDetails.substanceColor,
                    weight: "50%"
                )
                
                ScoreItem(
                    title: "Clarity",
                    score: scoreDetails.clarityScore,
                    color: scoreDetails.clarityColor,
                    weight: "30%"
                )
                
                ScoreItem(
                    title: "Grammar",
                    score: scoreDetails.grammarScore,
                    color: scoreDetails.grammarColor,
                    weight: "20%"
                )
            }
            
            // Detailed Breakdown (Expandable)
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                    
                    VStack(spacing: 12) {
                        if let substanceScore = scoreDetails.substanceScore,
                           let substanceReason = scoreDetails.substanceReason {
                            ScoreDetailRow(
                                title: "Substance (\(substanceScore)%)",
                                reason: substanceReason,
                                color: scoreDetails.substanceColor
                            )
                        }
                        
                        if let clarityScore = scoreDetails.clarityScore,
                           let clarityReason = scoreDetails.clarityReason {
                            ScoreDetailRow(
                                title: "Clarity (\(clarityScore)%)",
                                reason: clarityReason,
                                color: scoreDetails.clarityColor
                            )
                        }
                        
                        if let grammarScore = scoreDetails.grammarScore,
                           let grammarReason = scoreDetails.grammarReason {
                            ScoreDetailRow(
                                title: "Grammar (\(grammarScore)%)",
                                reason: grammarReason,
                                color: scoreDetails.grammarColor
                            )
                        }
                    }
                }
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

struct ScoreItem: View {
    let title: String
    let score: Int?
    let color: Color
    let weight: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            if let score = score {
                Text("\(score)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            } else {
                Text("N/A")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            
            Text(weight)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ScoreDetailRow: View {
    let title: String
    let reason: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
}

struct NoScoreDetailsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("No AI Score Available")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("This session doesn't have AI-generated scores yet. Scores are generated automatically after interview completion.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TranscriptCard: View {
    let transcript: InterviewTranscript
    let session: InterviewSession
    let categoryColor: Color
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Transcript Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.title3)
                        .foregroundColor(categoryColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interview Transcript")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(transcript.messageCount) messages • \(transcript.userMessageCount) responses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(Array(transcript.transcriptData.prefix(10).enumerated()), id: \.element.id) { index, message in
                        CompactMessageBubble(
                            message: message,
                            messageNumber: index + 1,
                            categoryColor: categoryColor
                        )
                    }
                    
                    if transcript.transcriptData.count > 10 {
                        NavigationLink(destination: TranscriptDetailView(
                            transcript: transcript,
                            session: session
                        )) {
                            HStack {
                                Text("View Full Transcript (\(transcript.transcriptData.count - 10) more messages)")
                                    .font(.subheadline)
                                    .foregroundColor(categoryColor)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(categoryColor)
                            }
                            .padding(16)
                            .background(categoryColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
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

// MARK: - Compact Message Bubble (renamed to avoid conflicts)
private struct CompactMessageBubble: View {
    let message: TranscriptMessage
    let messageNumber: Int
    let categoryColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Message Number
            Text("\(messageNumber)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            // Message Content
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: message.role.icon)
                        .font(.caption2)
                        .foregroundColor(message.role.color)
                    
                    Text(message.role.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(message.role.color)
                    
                    Spacer()
                }
                
                // Content
                Text(message.content)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                message.role == .user ? 
                    Color.blue.opacity(0.1) : 
                    Color(.systemGray6)
            )
            .cornerRadius(12)
        }
    }
}

struct NoTranscriptCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("No Transcript Available")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("This session doesn't have a transcript yet. Transcripts are generated automatically during AI interviews.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HistoryView()
}