//
//  HelpSupportView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingContactForm = false
    @State private var showingFeedbackForm = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Help Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Help")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HelpActionRow(
                                icon: "questionmark.circle.fill",
                                title: "Frequently Asked Questions",
                                subtitle: "Find answers to common questions",
                                color: .blue
                            ) {
                                // Open FAQ
                            }
                            
                            HelpActionRow(
                                icon: "play.circle.fill",
                                title: "Getting Started Guide",
                                subtitle: "Learn how to use PocketInterview",
                                color: .green
                            ) {
                                // Open getting started guide
                            }
                            
                            HelpActionRow(
                                icon: "video.circle.fill",
                                title: "Video Tutorials",
                                subtitle: "Watch step-by-step tutorials",
                                color: .purple
                            ) {
                                // Open video tutorials
                            }
                        }
                    }
                    
                    // Contact Support Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Support")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HelpActionRow(
                                icon: "envelope.circle.fill",
                                title: "Email Support",
                                subtitle: "Get help via email within 24 hours",
                                color: .orange
                            ) {
                                showingContactForm = true
                            }
                            
                            HelpActionRow(
                                icon: "message.circle.fill",
                                title: "Live Chat",
                                subtitle: "Chat with our support team",
                                color: .cyan
                            ) {
                                // Open live chat
                            }
                            
                            HelpActionRow(
                                icon: "phone.circle.fill",
                                title: "Phone Support",
                                subtitle: "Call us during business hours",
                                color: .red
                            ) {
                                // Open phone support
                            }
                        }
                    }
                    
                    // Feedback Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Feedback")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HelpActionRow(
                                icon: "heart.circle.fill",
                                title: "Send Feedback",
                                subtitle: "Help us improve the app",
                                color: .pink
                            ) {
                                showingFeedbackForm = true
                            }
                            
                            HelpActionRow(
                                icon: "star.circle.fill",
                                title: "Rate the App",
                                subtitle: "Rate us on the App Store",
                                color: .yellow
                            ) {
                                // Open App Store rating
                            }
                            
                            HelpActionRow(
                                icon: "exclamationmark.triangle.circle.fill",
                                title: "Report a Bug",
                                subtitle: "Report technical issues",
                                color: .red
                            ) {
                                // Open bug report form
                            }
                        }
                    }
                    
                    // Resources Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Resources")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HelpActionRow(
                                icon: "doc.circle.fill",
                                title: "User Manual",
                                subtitle: "Complete guide to all features",
                                color: .indigo
                            ) {
                                // Open user manual
                            }
                            
                            HelpActionRow(
                                icon: "globe.circle.fill",
                                title: "Community Forum",
                                subtitle: "Connect with other users",
                                color: .teal
                            ) {
                                // Open community forum
                            }
                            
                            HelpActionRow(
                                icon: "newspaper.circle.fill",
                                title: "Release Notes",
                                subtitle: "See what's new in each update",
                                color: .brown
                            ) {
                                // Open release notes
                            }
                        }
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ContactInfoCard(
                                icon: "envelope.fill",
                                title: "Email",
                                value: "support@pocketinterview.app",
                                color: .blue
                            )
                            
                            ContactInfoCard(
                                icon: "clock.fill",
                                title: "Support Hours",
                                value: "Mon-Fri, 9:00 AM - 6:00 PM PST",
                                color: .green
                            )
                            
                            ContactInfoCard(
                                icon: "location.fill",
                                title: "Response Time",
                                value: "Within 24 hours",
                                color: .orange
                            )
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingContactForm) {
                ContactSupportView()
            }
            .sheet(isPresented: $showingFeedbackForm) {
                FeedbackView()
            }
        }
    }
}

struct HelpActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(10)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// Placeholder views for sheets
struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Contact Support Form")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This would be a contact form")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Feedback Form")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This would be a feedback form")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HelpSupportView()
}