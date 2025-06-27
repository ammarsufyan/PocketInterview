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
    @Published var userProfile: UserProfile?
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
            
            if let user = session.user {
                await fetchUserProfile(userId: user.id.uuidString)
            }
        } catch {
            print("Error checking initial auth state: \(error)")
            self.isAuthenticated = false
            self.currentUser = nil
            self.userProfile = nil
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
            
            if let user = session?.user {
                await fetchUserProfile(userId: user.id.uuidString)
            }
        case .signedOut:
            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false
        case .tokenRefreshed:
            self.currentUser = session?.user
        default:
            break
        }
    }
    
    // MARK: - Profile Management
    
    private func fetchUserProfile(userId: String) async {
        do {
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            self.userProfile = profile
        } catch {
            print("Error fetching user profile: \(error)")
            // If profile doesn't exist, create a default one
            if let user = currentUser {
                let defaultProfile = UserProfile(
                    id: user.id.uuidString,
                    email: user.email ?? "",
                    fullName: extractNameFromEmail(user.email ?? ""),
                    createdAt: Date()
                )
                self.userProfile = defaultProfile
            }
        }
    }
    
    private func createUserProfile(userId: String, email: String, fullName: String) async {
        do {
            let profile = UserProfile(
                id: userId,
                email: email,
                fullName: fullName,
                createdAt: Date()
            )
            
            try await supabase
                .from("profiles")
                .insert(profile)
                .execute()
            
            self.userProfile = profile
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let username = email.components(separatedBy: "@").first ?? email
        return username.replacingOccurrences(of: ".", with: " ").capitalized
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Check if user needs email confirmation
            if response.user != nil && response.session == nil {
                // User created but needs email confirmation
                self.errorMessage = "Please check your email and confirm your account before signing in."
            } else if let user = response.user, response.session != nil {
                // User is automatically signed in, create profile
                await createUserProfile(userId: user.id.uuidString, email: email, fullName: fullName)
                self.currentUser = user
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
            
            if let user = response.user {
                await fetchUserProfile(userId: user.id.uuidString)
            }
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
            self.userProfile = nil
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
        return userProfile?.fullName
    }
    
    var userInitials: String {
        guard let name = userProfile?.fullName, !name.isEmpty else {
            return userEmail?.prefix(2).uppercased() ?? "U"
        }
        
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = String(components[0].prefix(1))
            let lastInitial = String(components[1].prefix(1))
            return (firstInitial + lastInitial).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

// MARK: - UserProfile Model

struct UserProfile: Codable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case createdAt = "created_at"
    }
}