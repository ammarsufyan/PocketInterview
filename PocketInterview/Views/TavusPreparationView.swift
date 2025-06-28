//
//  TavusPreparationView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct TavusPreparationView: View {
    let category: String
    let sessionName: String
    let duration: Int
    let categoryColor: Color
    let interviewerName: String
    let interviewerDescription: String
    let onStart: () -> Void
    let onCancel: () -> Void
    
    @State private var isReady = false
    @State private var showingTips = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: category == "Technical" ? "laptopcomputer" : "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor)
                        .frame(width: 100, height: 100)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(20)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text("Ready for Your Interview?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(category) Interview with \(interviewerName)")
                            .font(.headline)
                            .foregroundColor(categoryColor)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 20)
                
                // Session Info
                VStack(spacing: 16) {
                    InfoCard(
                        title: "Session Details",
                        icon: "info.circle.fill",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(label: "Session Name", value: sessionName)
                            DetailRow(label: "Duration", value: "\(duration) minutes")
                            DetailRow(label: "Category", value: category)
                            DetailRow(label: "Interviewer", value: interviewerName)
                        }
                    }
                    
                    InfoCard(
                        title: "Your Interviewer",
                        icon: "person.fill",
                        color: categoryColor
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(interviewerDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    InfoCard(
                        title: "Before You Start",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        isCollapsible: true,
                        isCollapsed: $showingTips
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            TipRow(text: "Find a quiet place with good lighting")
                            TipRow(text: "Test your camera and microphone")
                            TipRow(text: "Have a glass of water nearby")
                            TipRow(text: "Dress professionally")
                            TipRow(text: "Prepare a notepad for notes")
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Start Button
                VStack(spacing: 16) {
                    Button(action: onStart) {
                        HStack(spacing: 12) {
                            Image(systemName: "video.fill")
                                .font(.title3)
                            
                            Text("Start Interview Now")
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
                    
                    Button(action: onCancel) {
                        Text("Back to Setup")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical, 20)
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    var isCollapsible: Bool = false
    @Binding var isCollapsed: Bool
    let content: () -> Content
    
    init(
        title: String,
        icon: String,
        color: Color,
        isCollapsible: Bool = false,
        isCollapsed: Binding<Bool> = .constant(false),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isCollapsible = isCollapsible
        self._isCollapsed = isCollapsed
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                if isCollapsible {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isCollapsed.toggle()
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isCollapsible {
                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if !isCollapsed {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    TavusPreparationView(
        category: "Technical",
        sessionName: "iOS Development Practice",
        duration: 30,
        categoryColor: .blue,
        interviewerName: "Steve",
        interviewerDescription: "Steve is your technical interviewer with expertise in software engineering, algorithms, and system design.",
        onStart: {},
        onCancel: {}
    )
}