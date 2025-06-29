//
//  SignInView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct SignInView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var showingSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    @State private var isEmailValid = true
    @State private var isPasswordValid = true
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section - MOVED HIGHER
                    VStack(spacing: 24) {
                        Spacer(minLength: 40) // REDUCED from 60
                        
                        // Logo
                        InterviewSimLogo()
                            .scaleEffect(0.8)
                        
                        // Welcome Text
                        VStack(spacing: 8) {
                            Text("PocketInterview")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(minHeight: geometry.size.height * 0.35) // REDUCED from 0.4
                    
                    // ADDED: Extra spacing between title and form
                    Spacer()
                        .frame(height: 32)
                    
                    // Form Section
                    VStack(spacing: 24) {
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
                                .onChange(of: email) {
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
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(AuthTextFieldStyle(isValid: isPasswordValid))
                                .textContentType(.password)
                                .onChange(of: password) {
                                    validatePassword()
                                    authManager.clearError()
                                }
                            
                            if !isPasswordValid {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Sign In Button
                        Button(action: signIn) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3)
                                }
                                
                                Text(authManager.isLoading ? "Signing In..." : "Sign In")
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
                        
                        // Sign Up Link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Sign Up") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSignUp = true
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
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(authManager: authManager)
        }
    }
    
    // MARK: - Validation
    
    private func validateEmail() {
        isEmailValid = email.isEmpty || email.contains("@") && email.contains(".")
    }
    
    private func validatePassword() {
        isPasswordValid = password.isEmpty || password.count >= 6
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && 
               !password.isEmpty && 
               isEmailValid && 
               isPasswordValid
    }
    
    // MARK: - Actions
    
    private func signIn() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

#Preview {
    SignInView(
        authManager: AuthenticationManager(),
        showingSignUp: .constant(false)
    )
}