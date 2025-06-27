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
            
            if session.user != nil {
                await fetchUserProfile(userId: session.user.id.uuidString)
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
            let response = try await supabase
                .from("profiles")
                .select("id, email, full_name, created_at, updated_at")
                .eq("id", value: userId)
                .single()
                .execute()
            
            print("Profile fetch response: \(response)")
            
            // Parse the response data
            if let data = response.data,
               let profileDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let profile = UserProfile(
                    id: profileDict["id"] as? String ?? userId,
                    email: profileDict["email"] as? String ?? currentUser?.email ?? "",
                    fullName: profileDict["full_name"] as? String ?? "",
                    createdAt: parseDate(from: profileDict["created_at"]) ?? Date(),
                    updatedAt: parseDate(from: profileDict["updated_at"])
                )
                
                print("Parsed profile: \(profile)")
                self.userProfile = profile
            }
        } catch {
            print("Error fetching user profile: \(error)")
            
            // If profile doesn't exist or there's an error, try to create one
            if let user = currentUser {
                print("Creating fallback profile for user: \(user.email ?? "unknown")")
                let fallbackName = extractNameFromEmail(user.email ?? "")
                await createUserProfile(userId: user.id.uuidString, email: user.email ?? "", fullName: fallbackName)
            }
        }
    }
    
    private func parseDate(from value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.date(from: dateString) ?? {
            // Fallback to basic ISO8601 format
            let basicFormatter = ISO8601DateFormatter()
            return basicFormatter.date(from: dateString)
        }()
    }
    
    private func createUserProfile(userId: String, email: String, fullName: String) async {
        do {
            let profileData: [String: Any] = [
                "id": userId,
                "email": email,
                "full_name": fullName
            ]
            
            print("Creating profile with data: \(profileData)")
            
            let response = try await supabase
                .from("profiles")
                .insert(profileData)
                .execute()
            
            print("Profile creation response: \(response)")
            
            // Create the profile object locally
            let profile = UserProfile(
                id: userId,
                email: email,
                fullName: fullName,
                createdAt: Date(),
                updatedAt: nil
            )
            
            self.userProfile = profile
            print("Profile created successfully: \(profile)")
        } catch {
            print("Error creating user profile: \(error)")
            
            // Create a local profile even if database insert fails
            let profile = UserProfile(
                id: userId,
                email: email,
                fullName: fullName,
                createdAt: Date(),
                updatedAt: nil
            )
            self.userProfile = profile
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
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("Starting sign up for: \(email) with name: \(fullName)")
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            print("Sign up response - User: \(response.user?.id.uuidString ?? "nil"), Session: \(response.session != nil)")
            
            // Check if user needs email confirmation
            if response.user != nil && response.session == nil {
                // User created but needs email confirmation
                self.errorMessage = "Please check your email and confirm your account before signing in."
            } else if response.user != nil && response.session != nil {
                // User is automatically signed in, create profile
                print("User signed up successfully, creating profile...")
                await createUserProfile(userId: response.user.id.uuidString, email: email, fullName: fullName)
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
            
            if response.user != nil {
                await fetchUserProfile(userId: response.user.id.uuidString)
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
        guard let profile = userProfile else {
            // Fallback to extracting name from email if profile is not loaded
            if let email = currentUser?.email {
                return extractNameFromEmail(email)
            }
            return nil
        }
        
        return profile.fullName.isEmpty ? extractNameFromEmail(profile.email) : profile.fullName
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
    
    // MARK: - Profile Update Methods
    
    func updateProfile(fullName: String) async {
        guard let userId = userId else { return }
        
        isLoading = true
        
        do {
            let updateData: [String: Any] = [
                "full_name": fullName
            ]
            
            try await supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
            
            // Update local profile
            if var profile = userProfile {
                profile = UserProfile(
                    id: profile.id,
                    email: profile.email,
                    fullName: fullName,
                    createdAt: profile.createdAt,
                    updatedAt: Date()
                )
                self.userProfile = profile
            }
        } catch {
            print("Error updating profile: \(error)")
            self.errorMessage = "Failed to update profile"
        }
        
        isLoading = false
    }
}

// MARK: - UserProfile Model

struct UserProfile: Codable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}