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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Enter your email address and we'll send you a link to reset your password")
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
                                    authManager.clearAllMessages()
                                }
                            
                            if !isEmailValid {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Send Reset Link Button
                        Button(action: sendResetLink) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "envelope.arrow.triangle.branch")
                                        .font(.title3)
                                }
                                
                                Text(authManager.isLoading ? "Sending..." : "Send Reset Link")
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
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Simple Success Message
                        if let successMessage = authManager.successMessage {
                            Text(successMessage)
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Instructions (only show when no success message)
                        if authManager.successMessage == nil {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text("How it works")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("1. Enter your email address")
                                    Text("2. Check your email for a reset link")
                                    Text("3. Click the link to set a new password")
                                    Text("4. Sign in with your new password")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
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
            // Auto dismiss after successful email send
            .onChange(of: authManager.successMessage) { _, successMessage in
                if successMessage != nil {
                    // Auto dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
    
    private func sendResetLink() {
        Task {
            await authManager.resetPassword(email: email)
        }
    }
}

#Preview {
    ForgotPasswordView(authManager: AuthenticationManager())
}
