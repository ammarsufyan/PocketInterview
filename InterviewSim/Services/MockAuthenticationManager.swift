//
//  MockAuthenticationManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import Combine

@MainActor
class MockAuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: MockUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Check if user was previously logged in
        checkStoredAuthState()
    }
    
    private func checkStoredAuthState() {
        if let email = UserDefaults.standard.string(forKey: "mock_user_email") {
            self.currentUser = MockUser(id: UUID().uuidString, email: email)
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Mock validation
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Simulate successful sign up
        let user = MockUser(id: UUID().uuidString, email: email)
        self.currentUser = user
        self.isAuthenticated = true
        
        // Store in UserDefaults for persistence
        UserDefaults.standard.set(email, forKey: "mock_user_email")
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Mock validation
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Mock authentication (accept any valid email/password combo)
        let user = MockUser(id: UUID().uuidString, email: email)
        self.currentUser = user
        self.isAuthenticated = true
        
        // Store in UserDefaults for persistence
        UserDefaults.standard.set(email, forKey: "mock_user_email")
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        self.currentUser = nil
        self.isAuthenticated = false
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: "mock_user_email")
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        // Mock success - in real app, this would send an email
        isLoading = false
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    var userId: String? {
        return currentUser?.id
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        return email.contains("@") && email.contains(".")
    }
}

struct MockUser {
    let id: String
    let email: String
}