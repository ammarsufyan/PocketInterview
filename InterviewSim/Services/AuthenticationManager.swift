//
//  AuthenticationManager.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
// Temporarily comment out Supabase import until package is properly linked
// import Supabase
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: MockUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Temporarily use mock implementation until Supabase package is fixed
    // private let supabase = SupabaseConfig.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Temporarily comment out Supabase setup
        // setupAuthStateListener()
        checkInitialAuthState()
    }
    
    // MARK: - Auth State Management (Mock Implementation)
    
    private func checkInitialAuthState() {
        // Check if user was previously logged in (mock implementation)
        if let email = UserDefaults.standard.string(forKey: "mock_user_email") {
            self.currentUser = MockUser(id: UUID().uuidString, email: email)
            self.isAuthenticated = true
        }
    }
    
    /*
    // Supabase implementation - commented out until package is fixed
    private func setupAuthStateListener() {
        supabase.auth.onAuthStateChange { [weak self] event, session in
            Task { @MainActor in
                self?.handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
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
    */
    
    // MARK: - Authentication Methods (Mock Implementation)
    
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
        
        /*
        // Real Supabase implementation - commented out until package is fixed
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Auto sign in after successful sign up
            if response.user != nil {
                await signIn(email: email, password: password)
            }
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        */
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
        
        /*
        // Real Supabase implementation - commented out until package is fixed
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
        */
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
        
        /*
        // Real Supabase implementation - commented out until package is fixed
        do {
            try await supabase.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        */
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
        
        /*
        // Real Supabase implementation - commented out until package is fixed
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            // Success - user will receive email
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        */
    }
    
    // MARK: - Error Handling
    
    /*
    // Supabase error handling - commented out until package is fixed
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .invalidCredentials:
                return "Invalid email or password"
            case .emailNotConfirmed:
                return "Please check your email and confirm your account"
            case .userNotFound:
                return "No account found with this email"
            case .weakPassword:
                return "Password should be at least 6 characters"
            case .emailAlreadyRegistered:
                return "An account with this email already exists"
            default:
                return authError.localizedDescription
            }
        }
        return error.localizedDescription
    }
    */
    
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

// Mock User struct for temporary implementation
struct MockUser {
    let id: String
    let email: String
}