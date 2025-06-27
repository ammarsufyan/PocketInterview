//
//  TranscriptDetailView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct TranscriptDetailView: View {
    let transcript: InterviewTranscript
    let session: InterviewSession?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedMessageType: MessageTypeFilter = .all
    
    enum MessageTypeFilter: String, CaseIterable {
        case all = "All"
        case user = "Your Responses"
        case assistant = "AI Questions"
        
        var icon: String {
            switch self {
            case .all:
                return "text.bubble"
            case .user:
                return "person.circle"
            case .assistant:
                return "brain.head.profile"
            }
        }
    }
    
    private var filteredMessages: [TranscriptMessage] {
        var messages = transcript.transcriptData
        
        // Filter by message type
        switch selectedMessageType {
        case .all:
            break
        case .user:
            messages = messages.filter { $0.role == .user }
        case .assistant:
            messages = messages.filter { $0.role == .assistant }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            messages = messages.filter { 
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return messages
    }
    
    private var categoryColor: Color {
        session?.categoryColor ?? .blue
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Stats
                TranscriptStatsHeader(transcript: transcript, session: session)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Search and Filter
                VStack(spacing: 12) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        TextField("Search transcript...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.subheadline)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MessageTypeFilter.allCases, id: \.self) { filter in
                                FilterTab(
                                    title: filter.rawValue,
                                    icon: filter.icon,
                                    isSelected: selectedMessageType == filter,
                                    color: categoryColor
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMessageType = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Messages List
                if filteredMessages.isEmpty {
                    EmptyTranscriptView(
                        searchText: searchText,
                        messageType: selectedMessageType
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredMessages.enumerated()), id: \.element.id) { index, message in
                                MessageBubble(
                                    message: message,
                                    messageNumber: index + 1,
                                    categoryColor: categoryColor
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Interview Transcript")
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

struct TranscriptStatsHeader: View {
    let transcript: InterviewTranscript
    let session: InterviewSession?
    
    var body: some View {
        VStack(spacing: 16) {
            // Session Info
            if let session = session {
                HStack(spacing: 12) {
                    Image(systemName: session.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                        .font(.title3)
                        .foregroundColor(session.categoryColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.sessionName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("\(session.category) Interview")
                            .font(.caption)
                            .foregroundColor(session.categoryColor)
                    }
                    
                    Spacer()
                    
                    Text(session.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Transcript Stats
            HStack(spacing: 16) {
                StatItem(
                    title: "Messages",
                    value: "\(transcript.messageCount)",
                    icon: "text.bubble.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "Your Responses",
                    value: "\(transcript.userMessageCount)",
                    icon: "person.circle.fill",
                    color: .green
                )
                
                StatItem(
                    title: "AI Questions",
                    value: "\(transcript.assistantMessageCount)",
                    icon: "brain.head.profile",
                    color: .purple
                )
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .symbolRenderingMode(.hierarchical)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray6))
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : Color.clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: 2
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct MessageBubble: View {
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
                .frame(width: 24, height: 24)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            // Message Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: message.role.icon)
                        .font(.caption)
                        .foregroundColor(message.role.color)
                    
                    Text(message.role.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(message.role.color)
                    
                    Spacer()
                    
                    Text("\(message.wordCount) words")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Content
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                message.role == .user ? 
                    Color.blue.opacity(0.1) : 
                    Color(.systemGray6)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        message.role == .user ? 
                            Color.blue.opacity(0.3) : 
                            Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

struct EmptyTranscriptView: View {
    let searchText: String
    let messageType: TranscriptDetailView.MessageTypeFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "text.bubble.fill" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Messages" : "No Results Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "No \(messageType.rawValue.lowercased()) found in this transcript" :
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
    TranscriptDetailView(
        transcript: InterviewTranscript.sampleTechnicalTranscript(),
        session: nil
    )
}