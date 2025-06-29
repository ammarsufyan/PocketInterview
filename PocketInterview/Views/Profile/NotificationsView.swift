//
//  NotificationsView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pushNotifications = true
    @State private var emailNotifications = false
    @State private var interviewReminders = true
    @State private var weeklyReports = false
    @State private var achievementAlerts = true
    @State private var systemUpdates = true
    @State private var marketingEmails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Push Notifications Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Push Notifications")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            NotificationToggleRow(
                                icon: "bell.circle.fill",
                                title: "Enable Push Notifications",
                                subtitle: "Receive notifications on your device",
                                color: .blue,
                                isOn: $pushNotifications
                            )
                            
                            NotificationToggleRow(
                                icon: "clock.circle.fill",
                                title: "Interview Reminders",
                                subtitle: "Get reminded about scheduled interviews",
                                color: .orange,
                                isOn: $interviewReminders,
                                isEnabled: pushNotifications
                            )
                            
                            NotificationToggleRow(
                                icon: "trophy.circle.fill",
                                title: "Achievement Alerts",
                                subtitle: "Celebrate your interview milestones",
                                color: .yellow,
                                isOn: $achievementAlerts,
                                isEnabled: pushNotifications
                            )
                        }
                    }
                    
                    // Email Notifications Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Email Notifications")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            NotificationToggleRow(
                                icon: "envelope.circle.fill",
                                title: "Enable Email Notifications",
                                subtitle: "Receive notifications via email",
                                color: .green,
                                isOn: $emailNotifications
                            )
                            
                            NotificationToggleRow(
                                icon: "chart.bar.circle.fill",
                                title: "Weekly Progress Reports",
                                subtitle: "Get weekly summaries of your progress",
                                color: .purple,
                                isOn: $weeklyReports,
                                isEnabled: emailNotifications
                            )
                            
                            NotificationToggleRow(
                                icon: "megaphone.circle.fill",
                                title: "Marketing Updates",
                                subtitle: "Receive news about new features and tips",
                                color: .pink,
                                isOn: $marketingEmails,
                                isEnabled: emailNotifications
                            )
                        }
                    }
                    
                    // System Notifications Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("System Notifications")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            NotificationToggleRow(
                                icon: "gear.circle.fill",
                                title: "System Updates",
                                subtitle: "Important app updates and maintenance",
                                color: .gray,
                                isOn: $systemUpdates
                            )
                        }
                    }
                    
                    // Notification Schedule Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Schedule")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            NotificationScheduleRow(
                                icon: "moon.circle.fill",
                                title: "Do Not Disturb",
                                subtitle: "22:00 - 08:00",
                                color: .indigo
                            ) {
                                // Configure do not disturb
                            }
                            
                            NotificationScheduleRow(
                                icon: "calendar.circle.fill",
                                title: "Reminder Frequency",
                                subtitle: "Daily",
                                color: .red
                            ) {
                                // Configure reminder frequency
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("Notifications")
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
        }
    }
}

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    var isEnabled: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? color : color.opacity(0.5))
                .frame(width: 44, height: 44)
                .background((isEnabled ? color : color.opacity(0.5)).opacity(0.1))
                .cornerRadius(10)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(!isEnabled)
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
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

struct NotificationScheduleRow: View {
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

#Preview {
    NotificationsView()
}