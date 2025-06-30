//
//  ChangePasswordView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isCurrentPasswordValid = true
    @State private var isNewPasswordValid = true
    @State private var isConfirmPasswordValid = true
    @State private var successMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case currentPassword, newPassword, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    
                    VStack(spacing: 20) {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("Change Password")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Enter your current password and choose a new one")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    VStack(spacing: 20) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter current password", text: $currentPassword)
                                .textFieldStyle(PasswordFieldStyle(isValid: isCurrentPasswordValid))
                                .focused($focusedField, equals: .currentPassword)
                                .onChange(of: currentPassword) { _, _ in
                                    validateCurrentPassword()
                                    clearMessages()
                                }
                            
                            if !isCurrentPasswordValid {
                                Text("Current password is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter new password", text: $newPassword)
                                .textFieldStyle(PasswordFieldStyle(isValid: isNewPasswordValid))
                                .focused($focusedField, equals: .newPassword)
                                .onChange(of: newPassword) { _, _ in
                                    validateNewPassword()
                                    validateConfirmPassword()
                                    clearMessages()
                                }
                            
                            if !isNewPasswordValid {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(PasswordFieldStyle(isValid: isConfirmPasswordValid))
                                .focused($focusedField, equals: .confirmPassword)
                                .onChange(of: confirmPassword) { _, _ in
                                    validateConfirmPassword()
                                    clearMessages()
                                }
                            
                            if !isConfirmPasswordValid {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Error/Success Messages
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Change Password Button
                    Button(action: changePassword) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "lock.rotation")
                                    .font(.title3)
                            }
                            
                            Text(authManager.isLoading ? "Changing Password..." : "Change Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isFormValid ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            isFormValid ? Color.orange : Color(.systemGray4)
                        )
                        .cornerRadius(12)
                        .shadow(
                            color: isFormValid ? Color.orange.opacity(0.3) : Color.clear,
                            radius: isFormValid ? 8 : 0,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(authManager.isLoading)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .currentPassword
                }
            }
        }
    }
    
    private func validateCurrentPassword() {
        isCurrentPasswordValid = currentPassword.isEmpty || currentPassword.count >= 1
    }
    
    private func validateNewPassword() {
        isNewPasswordValid = newPassword.isEmpty || newPassword.count >= 6
    }
    
    private func validateConfirmPassword() {
        isConfirmPasswordValid = confirmPassword.isEmpty || newPassword == confirmPassword
    }
    
    private var isFormValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               isCurrentPasswordValid &&
               isNewPasswordValid &&
               isConfirmPasswordValid
    }
    
    private func clearMessages() {
        authManager.clearError()
        successMessage = nil
    }
    
    private func changePassword() {
        guard isFormValid else { return }
        
        Task {
            await authManager.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            if authManager.errorMessage == nil {
                successMessage = "Password changed successfully!"
                
                // Clear form fields
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                
                // Dismiss after showing success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

struct PasswordFieldStyle: TextFieldStyle {
    let isValid: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isValid ? Color.clear : Color.red.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isValid)
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(AuthenticationManager())
}
