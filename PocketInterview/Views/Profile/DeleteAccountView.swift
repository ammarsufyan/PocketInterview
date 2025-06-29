//
//  DeleteAccountView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Warning Icon
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                                .symbolRenderingMode(.hierarchical)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Delete Account")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("This action is permanent and cannot be undone")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Account Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account to be deleted:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(authManager.userEmail ?? "")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // What will be deleted section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What will be deleted:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        VStack(spacing: 12) {
                            DeletedItemRow(
                                icon: "clock.fill",
                                text: "All interview sessions and history"
                            )
                            
                            DeletedItemRow(
                                icon: "text.bubble.fill",
                                text: "All transcripts and recordings"
                            )
                            
                            DeletedItemRow(
                                icon: "brain.head.profile",
                                text: "All AI scores and feedback"
                            )
                            
                            DeletedItemRow(
                                icon: "gearshape.fill",
                                text: "Account settings and preferences"
                            )
                            
                            DeletedItemRow(
                                icon: "person.fill",
                                text: "All personal data"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Delete Button
                    Button(action: {
                        Task {
                            await authManager.deleteAccountSimple()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.title3)
                            }
                            
                            Text(authManager.isLoading ? "Deleting Account..." : "Delete My Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red)
                        .cornerRadius(16)
                        .shadow(
                            color: Color.red.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(authManager.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
            .navigationBarHidden(true)
            .overlay(
                // Custom Navigation Bar
                VStack {
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .disabled(authManager.isLoading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                },
                alignment: .top
            )
        }
        // 🔥 ENHANCED: Monitor auth state and auto-dismiss when user is logged out
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                // Force dismiss all sheets and navigate to auth
                dismiss()
            }
        }
        // 🔥 NEW: Also monitor currentUser for immediate response
        .onChange(of: authManager.currentUser) { _, currentUser in
            if currentUser == nil {
                dismiss()
            }
        }
    }
}

struct DeletedItemRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
                .symbolRenderingMode(.hierarchical)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    DeleteAccountView()
        .environmentObject(AuthenticationManager())
}