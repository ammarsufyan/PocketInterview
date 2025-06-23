//
//  MockInterviewView.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct MockInterviewView: View {
    @State private var selectedCategory = "Technical"
    @State private var showingCVPicker = false
    @State private var cvUploaded = false
    
    let categories = ["Technical", "Behavioral"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ready to Practice?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Choose your interview type and start practicing")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Interview Categories
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Interview Types")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            // Technical Category
                            CategoryCard(
                                title: "Technical",
                                subtitle: "Technical & Problem Solving",
                                description: "Practice technical skills and problem-solving abilities",
                                icon: "laptopcomputer",
                                color: .blue,
                                isSelected: selectedCategory == "Technical"
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = "Technical"
                                }
                            }
                            
                            // Behavioral Category
                            CategoryCard(
                                title: "Behavioral",
                                subtitle: "Soft Skills & Experience",
                                description: "Master STAR method and showcase your experience",
                                icon: "person.2.fill",
                                color: .purple,
                                isSelected: selectedCategory == "Behavioral"
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = "Behavioral"
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // CV Upload Section (for Technical interviews)
                    if selectedCategory == "Technical" {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Personalize Your Interview")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            CVUploadCard(
                                isUploaded: cvUploaded,
                                onUpload: {
                                    showingCVPicker = true
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Start Interview Button
                    VStack(spacing: 12) {
                        StartInterviewButton(
                            category: selectedCategory,
                            isEnabled: selectedCategory != "Technical" || cvUploaded
                        ) {
                            // Start interview action
                            print("Starting \(selectedCategory) interview")
                        }
                        .padding(.horizontal, 20)
                        
                        if selectedCategory == "Technical" && !cvUploaded {
                            Text("Upload your CV to get personalized questions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Mock Interview")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCVPicker) {
                CVPickerView(onUpload: { success in
                    if success {
                        withAnimation(.spring()) {
                            cvUploaded = true
                        }
                    }
                })
            }
        }
    }
}

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 52, height: 52)
                    .background(
                        isSelected ? color : color.opacity(0.1)
                    )
                    .cornerRadius(12)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(20)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemBackground)
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.clear : Color(.systemGray4),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct CVUploadCard: View {
    let isUploaded: Bool
    let onUpload: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isUploaded ? "checkmark.circle.fill" : "doc.text.fill")
                .font(.title2)
                .foregroundColor(isUploaded ? .green : .blue)
                .frame(width: 44, height: 44)
                .background(
                    (isUploaded ? Color.green : Color.blue).opacity(0.1)
                )
                .cornerRadius(10)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(isUploaded ? "CV Uploaded Successfully" : "Upload Your CV")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUploaded ? .green : .primary)
                
                Text(isUploaded ? 
                     "We'll create personalized questions based on your background" :
                     "We'll analyze your background and tailor questions accordingly"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            }
            
            Spacer()
            
            if !isUploaded {
                Button(action: onUpload) {
                    Text("Upload")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            } else {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isUploaded ? Color.green.opacity(0.3) : Color(.systemGray4),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

struct StartInterviewButton: View {
    let category: String
    let isEnabled: Bool
    let action: () -> Void
    
    private var gradientColors: [Color] {
        switch category {
        case "Technical":
            return [.blue, .cyan]
        case "Behavioral":
            return [.purple, .pink]
        default:
            return [.blue, .cyan]
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Start \(category) Interview")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isEnabled ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(.systemGray4)
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: isEnabled ? gradientColors[0].opacity(0.3) : Color.clear,
                radius: isEnabled ? 8 : 0,
                x: 0,
                y: 4
            )
            .scaleEffect(isEnabled ? 1.0 : 0.98)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct CVPickerView: View {
    let onUpload: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text("Upload Your CV")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("We'll analyze your background to create personalized interview questions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        // Simulate upload success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            onUpload(true)
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Choose File")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Text("Supported formats: PDF, DOC, DOCX")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Upload CV")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MockInterviewView()
}