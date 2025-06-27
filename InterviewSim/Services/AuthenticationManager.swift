//
//  AuthenticationManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
        Task {
            await checkInitialAuthState()
        }
    }
    
    // MARK: - Auth State Management
    
    private func checkInitialAuthState() async {
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = session.user != nil
        } catch {
            print("Error checking initial auth state: \(error)")
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    private func setupAuthStateListener() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            self.currentUser = session?.user
            self.isAuthenticated = true
            self.errorMessage = nil
        case .signedOut:
            self.currentUser = nil
            self.isAuthenticated = false
        case .tokenRefreshed:
            self.currentUser = session?.user
        default:
            break
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("Starting sign up for: \(email) with name: \(fullName)")
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "display_name": .string(fullName)
                ]
            )
            
            print("Sign up response - User: \(response.user?.id.uuidString ?? "nil"), Session: \(response.session != nil)")
            
            // Check if user needs email confirmation
            if let user = response.user, response.session == nil {
                // User created but needs email confirmation
                self.errorMessage = "Please check your email and confirm your account before signing in."
            } else if let user = response.user, response.session != nil {
                // User is automatically signed in
                print("User signed up successfully with display name: \(fullName)")
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            print("Sign up error: \(error)")
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            // Success - user will receive email
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    
    private func handleAuthError(_ error: Error) -> String {
        // Handle Supabase-specific errors
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid login credentials") || 
           errorDescription.contains("invalid email or password") {
            return "Invalid email or password"
        } else if errorDescription.contains("email not confirmed") {
            return "Please check your email and confirm your account"
        } else if errorDescription.contains("user not found") {
            return "No account found with this email"
        } else if errorDescription.contains("password") && errorDescription.contains("weak") {
            return "Password should be at least 6 characters"
        } else if errorDescription.contains("already registered") || 
                  errorDescription.contains("already exists") {
            return "An account with this email already exists"
        } else if errorDescription.contains("rate limit") {
            return "Too many attempts. Please try again later"
        } else if errorDescription.contains("network") || 
                  errorDescription.contains("connection") {
            return "Network error. Please check your connection"
        }
        
        return error.localizedDescription
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    var userId: String? {
        return currentUser?.id.uuidString
    }
    
    var userName: String? {
        // First try to get display_name from user metadata
        if let userMetadata = currentUser?.userMetadata,
           let displayName = userMetadata["display_name"]?.stringValue,
           !displayName.isEmpty {
            return displayName
        }
        
        // Fallback to extracting name from email
        if let email = currentUser?.email {
            return extractNameFromEmail(email)
        }
        
        return nil
    }
    
    var userInitials: String {
        guard let name = userName, !name.isEmpty else {
            return userEmail?.prefix(2).uppercased() ?? "U"
        }
        
        let components = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if components.count >= 2 {
            let firstInitial = String(components[0].prefix(1))
            let lastInitial = String(components[1].prefix(1))
            return (firstInitial + lastInitial).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let username = email.components(separatedBy: "@").first ?? email
        let cleanedUsername = username.replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        
        // Remove numbers and capitalize
        let nameComponents = cleanedUsername.components(separatedBy: CharacterSet.decimalDigits.union(.whitespaces))
            .filter { !$0.isEmpty }
            .map { $0.capitalized }
        
        return nameComponents.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Profile Update Methods
    
    func updateDisplayName(_ displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userAttributes = UserAttributes(
                data: [
                    "display_name": .string(displayName)
                ]
            )
            
            let updatedUser = try await supabase.auth.updateUser(attributes: userAttributes)
            
            // Update the current user with the response
            self.currentUser = updatedUser.user
            
            print("Display name updated successfully to: \(displayName)")
        } catch {
            print("Error updating display name: \(error)")
            self.errorMessage = "Failed to update display name"
        }
        
        isLoading = false
    }
}