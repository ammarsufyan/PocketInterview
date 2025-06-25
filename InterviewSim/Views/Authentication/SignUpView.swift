//
//  SignUpView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var authManager: MockAuthenticationManager
    @Binding var showingSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isEmailValid = true
    @State private var isPasswordValid = true
    @State private var isConfirmPasswordValid = true
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 24) {
                        Spacer(minLength: 40)
                        
                        // Logo
                        InterviewSimLogo()
                            .scaleEffect(0.7)
                        
                        // Welcome Text
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Join InterviewSim to start practicing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(minHeight: geometry.size.height * 0.3)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        // Email Field
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
                                .onChange(of: email) { _ in
                                    validateEmail()
                                    authManager.clearError()
                                }
                            
                            if !isEmailValid {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Create a password", text: $password)
                                .textFieldStyle(AuthTextFieldStyle(isValid: isPasswordValid))
                                .textContentType(.newPassword)
                                .onChange(of: password) { _ in
                                    validatePassword()
                                    validateConfirmPassword()
                                    authManager.clearError()
                                }
                            
                            if !isPasswordValid {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(AuthTextFieldStyle(isValid: isConfirmPasswordValid))
                                .textContentType(.newPassword)
                                .onChange(of: confirmPassword) { _ in
                                    validateConfirmPassword()
                                    authManager.clearError()
                                }
                            
                            if !isConfirmPasswordValid {
                                Text("Passwords do not match")
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
                                .padding(.horizontal)
                        }
                        
                        // Sign Up Button
                        Button(action: signUp) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.plus.fill")
                                        .font(.title3)
                                }
                                
                                Text(authManager.isLoading ? "Creating Account..." : "Create Account")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(
                                color: .purple.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .disabled(authManager.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        
                        // Sign In Link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Sign In") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSignUp = false
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Validation
    
    private func validateEmail() {
        isEmailValid = email.isEmpty || (email.contains("@") && email.contains("."))
    }
    
    private func validatePassword() {
        isPasswordValid = password.isEmpty || password.count >= 6
    }
    
    private func validateConfirmPassword() {
        isConfirmPasswordValid = confirmPassword.isEmpty || password == confirmPassword
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && 
               !password.isEmpty && 
               !confirmPassword.isEmpty &&
               isEmailValid && 
               isPasswordValid && 
               isConfirmPasswordValid
    }
    
    // MARK: - Actions
    
    private func signUp() {
        Task {
            await authManager.signUp(email: email, password: password)
        }
    }
}

#Preview {
    SignUpView(
        authManager: MockAuthenticationManager(),
        showingSignUp: .constant(true)
    )
}