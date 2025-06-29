import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(authManager.userInitials)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                            .shadow(
                                color: .blue.opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                        
                        // User Info
                        VStack(spacing: 4) {
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
                            // Account settings action
                        }
                        
                        ProfileOptionCard(
                            icon: "bell.circle",
                            title: "Notifications",
                            subtitle: "Configure notification preferences",
                            color: .orange
                        ) {
                            // Notifications action
                        }
                        
                        ProfileOptionCard(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            subtitle: "Get help and contact support",
                            color: .green
                        ) {
                            // Help action
                        }
                        
                        ProfileOptionCard(
                            icon: "info.circle",
                            title: "About",
                            subtitle: "App version and information",
                            color: .purple
                        ) {
                            // About action
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
                        
                        // Delete Account Button
                        Button(action: {
                            showingDeleteAccountAlert = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.circle")
                                    .font(.title3)
                                
                                Text("Delete Account")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Built by Bolt.new Badge
                    BoltBadgeImageView()
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
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } message: {
                Text("This action cannot be undone. All your interview history and data will be permanently deleted.")
            }
            .sheet(isPresented: $showingDeleteConfirmation) {
                DeleteAccountConfirmationView(
                    userEmail: authManager.userEmail ?? "",
                    confirmationText: $deleteConfirmationText,
                    onConfirm: {
                        Task {
                            await authManager.deleteAccount()
                        }
                        showingDeleteConfirmation = false
                    },
                    onCancel: {
                        showingDeleteConfirmation = false
                        deleteConfirmationText = ""
                    }
                )
            }
        }
    }
}

struct DeleteAccountConfirmationView: View {
    let userEmail: String
    @Binding var confirmationText: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject private var authManager: AuthenticationManager
    
    private var isConfirmationValid: Bool {
        confirmationText.lowercased() == "delete my account"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Warning Icon
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 12) {
                        Text("Delete Account")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("This action is permanent and cannot be undone")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Account Info
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account to be deleted:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(userEmail)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // What will be deleted
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What will be deleted:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            DeletedItemRow(text: "All interview sessions and history")
                            DeletedItemRow(text: "All transcripts and recordings")
                            DeletedItemRow(text: "All AI scores and feedback")
                            DeletedItemRow(text: "Account settings and preferences")
                            DeletedItemRow(text: "All personal data")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                // Confirmation Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Type \"delete my account\" to confirm:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("delete my account", text: $confirmationText)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isConfirmationValid ? Color.red : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.title3)
                            }
                            
                            Text(authManager.isLoading ? "Deleting Account..." : "Delete My Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            isConfirmationValid && !authManager.isLoading ? 
                                Color.red : 
                                Color.gray
                        )
                        .cornerRadius(12)
                        .shadow(
                            color: isConfirmationValid ? Color.red.opacity(0.3) : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(!isConfirmationValid || authManager.isLoading)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .disabled(authManager.isLoading)
                }
                .padding(.horizontal, 20)
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.blue)
                    .disabled(authManager.isLoading)
                }
            }
        }
    }
}

struct DeletedItemRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
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