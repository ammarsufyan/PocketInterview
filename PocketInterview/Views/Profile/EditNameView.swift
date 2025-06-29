//
//  EditNameView.swift
//  PocketInterview
//
//  Created by Ammar Sufyan on 29/06/25.
//

import SwiftUI

struct EditNameView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @State private var isNameValid = true
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text("Edit Your Name")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Update your display name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Full Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter your full name", text: $newName)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isNameValid ? Color.blue.opacity(0.5) : Color.red.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                        .focused($isTextFieldFocused)
                        .onChange(of: newName) { _, _ in
                            validateName()
                        }
                    
                    if !isNameValid {
                        Text("Name must be at least 2 characters")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 32)
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button(action: updateName) {
                    HStack(spacing: 12) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        
                        Text(authManager.isLoading ? "Updating..." : "Update Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isFormValid ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        isFormValid ? Color.blue : Color(.systemGray4)
                    )
                    .cornerRadius(12)
                    .shadow(
                        color: isFormValid ? Color.blue.opacity(0.3) : Color.clear,
                        radius: isFormValid ? 8 : 0,
                        x: 0,
                        y: 4
                    )
                }
                .disabled(!isFormValid || authManager.isLoading)
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .disabled(authManager.isLoading)
                }
            }
            .onAppear {
                newName = authManager.userName ?? ""
                validateName()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func validateName() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        isNameValid = trimmedName.count >= 2
    }
    
    private var isFormValid: Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return isNameValid && !trimmedName.isEmpty && trimmedName != authManager.userName
    }
    
    private func updateName() {
        guard isFormValid else { return }
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await authManager.updateDisplayName(trimmedName)
            
            if authManager.errorMessage == nil {
                dismiss()
            }
        }
    }
}

#Preview {
    EditNameView()
        .environmentObject(AuthenticationManager())
}