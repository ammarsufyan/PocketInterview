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
    @Published var successMessage: String? // 🔥 NEW: For success messages
    
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
            self.isAuthenticated = true
        } catch {
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
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "display_name": .string(fullName)
                ]
            )
            // Check if user needs email confirmation
            if response.session == nil {
                // User created but needs email confirmation
                self.errorMessage = "Please check your email and confirm your account before signing in."
            } else {
                // User is automatically signed in
                self.currentUser = response.user
                self.isAuthenticated = true
            }
        } catch {
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
    
    // MARK: - 🔥 UPDATED: Supabase Password Reset System
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "https://pocketinterview.netlify.app/auth/reset-password")
            )
            
            // Set simple success message
            self.successMessage = "Reset link sent to your email"
            
        } catch {
            self.errorMessage = handlePasswordResetError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Change Password Method
    
    func changePassword(currentPassword: String, newPassword: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First, verify the current password by attempting to sign in
            guard let userEmail = currentUser?.email else {
                throw AuthError.userNotFound
            }
            
            // Verify current password by attempting to sign in
            do {
                _ = try await supabase.auth.signIn(
                    email: userEmail,
                    password: currentPassword
                )
            } catch {
                throw AuthError.invalidPassword
            }
            
            // 🔥 FIXED: Use the correct API for authenticated user password change
            let updatedUser = try await supabase.auth.update(
                user: UserAttributes(
                    password: newPassword
                )
            )
            
            // Update the current user
            self.currentUser = updatedUser
            
        } catch let error as AuthError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - 🔥 CLEANED: Account Deletion with Auto Sign Out
    
    func deleteAccountSimple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user info before deletion
            guard let currentUser = currentUser else {
                throw AuthError.userNotFound
            }
            
            let userId = currentUser.id
            
            // Step 1: Delete user data from custom tables using regular client
            try await deleteUserData(userId: userId)
            
            // Step 2: Delete the user from Supabase Auth using admin client
            try await deleteUserFromAuthAdmin(userId: userId)
            
            // Step 3: Auto sign out after successful deletion
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
                self.errorMessage = nil
            }
            
        } catch {
            self.errorMessage = handleDeleteAccountError(error)
            
            // If deletion fails, at least sign out the user
            if self.isAuthenticated {
                await signOut()
            }
        }
        
        isLoading = false
    }
    
    private func deleteUserData(userId: UUID) async throws {
        // Delete interview sessions (this will cascade to transcripts and score details)
        try await supabase
            .from("interview_sessions")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        // Also try to delete profile if it exists
        do {
            try await supabase
                .from("profiles")
                .delete()
                .eq("id", value: userId)
                .execute()
        } catch {
            // Continue even if profile deletion fails
        }
    }
    
    private func deleteUserFromAuthAdmin(userId: UUID) async throws {
        // Get service role key from environment
        guard let serviceRoleKey = EnvironmentConfig.shared.supabaseServiceRoleKey,
              !serviceRoleKey.isEmpty else {
            return
        }
        
        guard let supabaseUrl = EnvironmentConfig.shared.supabaseURL,
              !supabaseUrl.isEmpty else {
            return
        }
        
        // Create admin client with service role key
        guard let url = URL(string: supabaseUrl) else {
            throw AuthError.deletionFailed
        }
        
        let adminClient = SupabaseClient(
            supabaseURL: url,
            supabaseKey: serviceRoleKey
        )
        
        // 🔥 FIXED: Use the correct admin API method
        try await adminClient.auth.admin.deleteUser(id: userId)
    }
    
    private func handleDeleteAccountError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .userNotFound:
                return "Account not found. You may already be signed out."
            case .deletionFailed:
                return "Failed to delete account. Please try again."
            case .unauthorized:
                return "Unable to delete account. Please contact support."
            case .invalidPassword:
                return "Authentication error occurred."
            case .invalidConfiguration:
                return "Configuration error. Please contact support."
            }
        }
        
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("user not found") {
            return "Account not found. You may already be signed out."
        } else if errorDescription.contains("unauthorized") || 
                  errorDescription.contains("permission") ||
                  errorDescription.contains("not_admin") {
            return "Unable to delete account. Please contact support for assistance."
        } else if errorDescription.contains("network") || errorDescription.contains("connection") {
            return "Network error. Please check your connection and try again."
        } else if errorDescription.contains("rate limit") {
            return "Too many requests. Please try again later."
        }
        
        return "Failed to delete account. Please try again or contact support."
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
    
    // MARK: - 🔥 NEW: Password Reset Error Handling
    
    private func handlePasswordResetError(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("user not found") {
            return "No account found with this email address"
        } else if errorDescription.contains("rate limit") {
            return "Too many password reset requests. Please try again later."
        } else if errorDescription.contains("network") || 
                  errorDescription.contains("connection") {
            return "Network error. Please check your connection and try again."
        } else if errorDescription.contains("invalid") {
            return "Invalid email address. Please check and try again."
        }
        
        return "Failed to send password reset email. Please try again."
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - 🔥 NEW: Clear Success Message
    
    func clearSuccess() {
        successMessage = nil
    }
    
    // MARK: - 🔥 NEW: Clear All Messages
    
    func clearAllMessages() {
        errorMessage = nil
        successMessage = nil
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
            // 🔥 FIXED: Use the correct method for updating user metadata
            let updatedUser = try await supabase.auth.update(
                user: UserAttributes(
                    data: [
                        "display_name": .string(displayName)
                    ]
                )
            )
            
            // Update the current user with the updated user directly
            self.currentUser = updatedUser
        } catch {
            self.errorMessage = "Failed to update display name"
        }
        
        isLoading = false
    }
}

// MARK: - Custom Auth Errors

enum AuthError: Error, LocalizedError {
    case userNotFound
    case deletionFailed
    case unauthorized
    case invalidPassword
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .deletionFailed:
            return "Failed to delete account"
        case .unauthorized:
            return "Unauthorized operation"
        case .invalidPassword:
            return "Current password is incorrect"
        case .invalidConfiguration:
            return "Configuration error"
        }
    }
}