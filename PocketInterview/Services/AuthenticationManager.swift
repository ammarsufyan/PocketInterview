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
            self.isAuthenticated = true
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
            
            print("Sign up response - User: \(response.user.id.uuidString), Session: \(response.session != nil)")
            
            // Check if user needs email confirmation
            if response.session == nil {
                // User created but needs email confirmation
                self.errorMessage = "Please check your email and confirm your account before signing in."
            } else {
                // User is automatically signed in
                print("User signed up successfully with display name: \(fullName)")
                self.currentUser = response.user
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
    
    // MARK: - 🔥 FIXED: Complete Account Deletion using Admin Client
    
    func deleteAccountSimple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user info before deletion
            guard let currentUser = currentUser else {
                throw AuthError.userNotFound
            }
            
            let userId = currentUser.id
            
            print("🗑️ Starting complete account deletion for user: \(userId)")
            
            // Step 1: Delete user data from custom tables
            print("🗑️ Deleting user data...")
            try await deleteUserData(userId: userId)
            
            // Step 2: Delete the user from Supabase Auth using admin client
            print("🗑️ Deleting user from Supabase Auth...")
            try await deleteUserFromAuthAdmin(userId: userId)
            
            print("✅ Account deletion completed successfully")
            
            // Step 3: Clear local state
            self.currentUser = nil
            self.isAuthenticated = false
            
        } catch {
            print("❌ Account deletion error: \(error)")
            self.errorMessage = handleDeleteAccountError(error)
            
            // If deletion fails, at least sign out the user
            if self.isAuthenticated {
                await signOut()
            }
        }
        
        isLoading = false
    }
    
    private func deleteUserData(userId: UUID) async throws {
        print("🗑️ Deleting user data for: \(userId)")
        
        // Delete interview sessions (this will cascade to transcripts and score details)
        try await supabase
            .from("interview_sessions")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        print("✅ User data deleted successfully")
    }
    
    private func deleteUserFromAuthAdmin(userId: UUID) async throws {
        print("🗑️ Attempting to delete user from Supabase Auth using admin client...")
        
        // Get service role key from environment
        guard let serviceRoleKey = EnvironmentConfig.shared.supabaseServiceRoleKey,
              !serviceRoleKey.isEmpty else {
            print("⚠️ Service role key not found, falling back to sign out")
            try await supabase.auth.signOut()
            return
        }
        
        guard let supabaseUrl = EnvironmentConfig.shared.supabaseURL,
              !supabaseUrl.isEmpty else {
            print("⚠️ Supabase URL not found, falling back to sign out")
            try await supabase.auth.signOut()
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
        
        // Use admin client to delete the user
        try await adminClient.auth.admin.deleteUser(id: userId)
        
        print("✅ User successfully deleted from Supabase Auth using admin client")
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
            // Use the correct method for updating user metadata in Supabase Swift SDK
            let updatedUser = try await supabase.auth.update(
                user: UserAttributes(
                    data: [
                        "display_name": .string(displayName)
                    ]
                )
            )
            
            // Update the current user with the updated user directly
            self.currentUser = updatedUser
            
            print("Display name updated successfully to: \(displayName)")
        } catch {
            print("Error updating display name: \(error)")
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
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .deletionFailed:
            return "Failed to delete account"
        case .unauthorized:
            return "Unauthorized operation"
        case .invalidPassword:
            return "invalidPassword"
        }
    }
}