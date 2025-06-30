import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingSignOutAlert = false
    @State private var showingAccountSettings = false
    @State private var showingHelpSupport = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // User Info
                        VStack(spacing: 6) {
                            BoltBadgeImageView(height: 60, scaleEffect: 0.95)
                            
                            Text(authManager.userName ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(authManager.userEmail ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Options
                    VStack(spacing: 16) {
                        ProfileOptionCard(
                            icon: "person.circle",
                            title: "Account Settings",
                            subtitle: "Manage your account preferences",
                            color: .blue
                        ) {
                            showingAccountSettings = true
                        }
                        
                        ProfileOptionCard(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            subtitle: "Get help and contact support",
                            color: .green
                        ) {
                            showingHelpSupport = true
                        }
                        
                        ProfileOptionCard(
                            icon: "info.circle",
                            title: "About",
                            subtitle: "App version and information",
                            color: .purple
                        ) {
                            showingAbout = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Account Actions Section
                    VStack(spacing: 12) {
                        // Sign Out Button
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.square")
                                    .font(.title3)
                                
                                Text("Sign Out")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingHelpSupport) {
                HelpSupportView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
        // 🔥 NEW: Monitor auth state and auto-dismiss sheets when user is logged out
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                // Close all sheets when user is signed out
                showingAccountSettings = false
                showingHelpSupport = false
                showingAbout = false
                showingSignOutAlert = false
            }
        }
    }
}

struct ProfileOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
