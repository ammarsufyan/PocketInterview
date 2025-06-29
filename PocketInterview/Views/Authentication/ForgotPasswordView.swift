//
//  ForgotPasswordView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isEmailValid = true
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // 🔥 UPDATED: New description for temporary password system
                            Text("Enter your email address and we'll generate a temporary password for you")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(AuthTextFieldStyle(isValid: isEmailValid))
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) {
                                    validateEmail()
                                    authManager.clearAllMessages() // 🔥 UPDATED: Clear all messages
                                }
                            
                            if !isEmailValid {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // 🔥 NEW: Success Message with Temporary Password
                        if let successMessage = authManager.successMessage {
                            VStack(spacing: 12) {
                                Text("Temporary Password Generated!")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                
                                Text(successMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding(16)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Generate Temporary Password Button
                        Button(action: generateTempPassword) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "key.radiowaves.forward.fill")
                                        .font(.title3)
                                }
                                
                                // 🔥 UPDATED: New button text
                                Text(authManager.isLoading ? "Generating..." : "Generate Temporary Password")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(
                                color: .blue.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .disabled(authManager.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        
                        // 🔥 NEW: Security Notice
                        if authManager.successMessage == nil {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "shield.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text("Security Notice")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("The temporary password will expire in 24 hours. Please change it immediately after signing in.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            // 🔥 NEW: Auto dismiss after successful temp password generation
            .onChange(of: authManager.successMessage) { _, successMessage in
                if successMessage != nil {
                    // Auto dismiss after 10 seconds to give user time to copy password
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        if authManager.successMessage != nil {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateEmail() {
        isEmailValid = email.isEmpty || (email.contains("@") && email.contains("."))
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && isEmailValid
    }
    
    // MARK: - Actions
    
    // 🔥 UPDATED: Use new temporary password system
    private func generateTempPassword() {
        Task {
            await authManager.resetPasswordWithTempPassword(email: email)
        }
    }
}

#Preview {
    ForgotPasswordView(authManager: AuthenticationManager())
}