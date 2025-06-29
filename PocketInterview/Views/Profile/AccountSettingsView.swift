//
//  AccountSettingsView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAccountSheet = false
    @State private var showingEditNameSheet = false
    @State private var showingChangePasswordSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            AccountInfoRow(
                                icon: "person.circle",
                                title: "Full Name",
                                value: authManager.userName ?? "User",
                                color: .blue
                            ) {
                                showingEditNameSheet = true
                            }
                            
                            AccountInfoRow(
                                icon: "envelope.circle",
                                title: "Email",
                                value: authManager.userEmail ?? "",
                                color: .green,
                                isEditable: false
                            )
                            
                            AccountInfoRow(
                                icon: "lock.circle",
                                title: "Password",
                                value: "••••••••",
                                color: .orange
                            ) {
                                showingChangePasswordSheet = true
                            }
                        }
                    }
                    
                    // Privacy & Security Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy & Security")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            SettingsToggleRow(
                                icon: "eye.circle",
                                title: "Data Analytics",
                                subtitle: "Help improve the app with usage analytics",
                                color: .purple,
                                isOn: .constant(true)
                            )
                            
                            SettingsToggleRow(
                                icon: "shield.circle",
                                title: "Enhanced Security",
                                subtitle: "Additional security measures for your account",
                                color: .red,
                                isOn: .constant(false)
                            )
                        }
                    }
                    
                    // Data Management Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            SettingsActionRow(
                                icon: "arrow.down.circle",
                                title: "Export Data",
                                subtitle: "Download your interview data",
                                color: .cyan
                            ) {
                                // Export data action
                            }
                            
                            SettingsActionRow(
                                icon: "trash.circle",
                                title: "Clear Interview History",
                                subtitle: "Remove all interview sessions",
                                color: .orange
                            ) {
                                // Clear history action
                            }
                        }
                    }
                    
                    // Danger Zone Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Danger Zone")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Button(action: {
                            showingDeleteAccountSheet = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Delete Account")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Permanently delete your account and all data")
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(
                                color: Color.black.opacity(0.05),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("Account Settings")
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
            .sheet(isPresented: $showingDeleteAccountSheet) {
                DeleteAccountView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingEditNameSheet) {
                EditNameView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingChangePasswordSheet) {
                ChangePasswordView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct AccountInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var isEditable: Bool = true
    let action: (() -> Void)?
    
    init(icon: String, title: String, value: String, color: Color, isEditable: Bool = true, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.isEditable = isEditable
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEditable {
                action?()
            }
        }) {
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
                
                if isEditable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
        .disabled(!isEditable)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    
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
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
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

struct SettingsActionRow: View {
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
    AccountSettingsView()
        .environmentObject(AuthenticationManager())
}