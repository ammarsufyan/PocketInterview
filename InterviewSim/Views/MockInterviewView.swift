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
    @State private var showingSessionSetup = false
    
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
                                    cvUploaded = false // Reset CV status when switching
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
                                    cvUploaded = false // Reset CV status when switching
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // CV Upload Section (for both Technical and Behavioral)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Personalize Your Interview")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        CVUploadCard(
                            category: selectedCategory,
                            isUploaded: cvUploaded,
                            onUpload: {
                                showingCVPicker = true
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    // Start Interview Button
                    VStack(spacing: 12) {
                        StartInterviewButton(
                            category: selectedCategory,
                            isEnabled: cvUploaded
                        ) {
                            showingSessionSetup = true
                        }
                        .padding(.horizontal, 20)
                        
                        if !cvUploaded {
                            Text("Upload your CV to get personalized questions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Built by Bolt.new Badge - Using Asset Image
                    BoltBadgeImageView()
                        .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Mock Interview")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCVPicker) {
                CVPickerView(category: selectedCategory, onUpload: { success in
                    if success {
                        withAnimation(.spring()) {
                            cvUploaded = true
                        }
                    }
                })
            }
            .sheet(isPresented: $showingSessionSetup) {
                SessionSetupView(category: selectedCategory)
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
    let category: String
    let isUploaded: Bool
    let onUpload: () -> Void
    
    private var uploadDescription: String {
        switch category {
        case "Technical":
            return isUploaded ? 
                "We'll create personalized technical questions based on your skills and experience" :
                "We'll analyze your technical background and tailor coding/problem-solving questions accordingly"
        case "Behavioral":
            return isUploaded ?
                "We'll create personalized behavioral questions based on your work experience and achievements" :
                "We'll analyze your work history and create STAR-method questions based on your background"
        default:
            return "We'll analyze your background and tailor questions accordingly"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isUploaded ? "checkmark.circle.fill" : "doc.text.fill")
                .font(.title2)
                .foregroundColor(isUploaded ? .green : (category == "Technical" ? .blue : .purple))
                .frame(width: 44, height: 44)
                .background(
                    (isUploaded ? Color.green : (category == "Technical" ? Color.blue : Color.purple)).opacity(0.1)
                )
                .cornerRadius(10)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(isUploaded ? "CV Uploaded Successfully" : "Upload Your CV")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUploaded ? .green : .primary)
                
                Text(uploadDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
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
                        .background(category == "Technical" ? Color.blue : Color.purple)
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
    let category: String
    let onUpload: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    private var analysisDescription: String {
        switch category {
        case "Technical":
            return "We'll analyze your technical skills, programming languages, frameworks, and project experience to create relevant coding challenges and technical questions."
        case "Behavioral":
            return "We'll analyze your work experience, achievements, and career progression to create personalized STAR-method behavioral questions."
        default:
            return "We'll analyze your background to create personalized questions."
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 12) {
                        Text("Upload Your CV")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("For \(category) Interview")
                            .font(.headline)
                            .foregroundColor(categoryColor)
                            .fontWeight(.semibold)
                        
                        Text(analysisDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .lineLimit(4)
                    }
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        // Simulate upload success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onUpload(true)
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.headline)
                            Text("Choose File")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [categoryColor, categoryColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(
                            color: categoryColor.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    
                    VStack(spacing: 4) {
                        Text("Supported formats: PDF, DOC, DOCX")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Max file size: 10MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                    .foregroundColor(categoryColor)
                }
            }
        }
    }
}

// MARK: - Session Setup View
struct SessionSetupView: View {
    let category: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionName = ""
    @State private var selectedDuration = 30
    
    private let durations = [15, 30, 45, 60]
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: category == "Technical" ? "laptopcomputer" : "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(categoryColor)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("Setup Your Session")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(category) Interview")
                                .font(.headline)
                                .foregroundColor(categoryColor)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 24) {
                        // Session Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Name")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField(
                                category == "Technical" ? 
                                "e.g., iOS Interview Prep" : 
                                "e.g., Leadership Experience",
                                text: $sessionName
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                            
                            Text("Give your session a memorable name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Duration Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 12) {
                                ForEach(durations, id: \.self) { duration in
                                    Button(action: {
                                        selectedDuration = duration
                                    }) {
                                        Text("\(duration) min")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedDuration == duration ? .white : categoryColor)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedDuration == duration ? 
                                                categoryColor : categoryColor.opacity(0.1)
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            Text("How long do you want to practice?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Start Button
                    Button(action: {
                        startInterview()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            
                            Text("Start Interview")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [categoryColor, categoryColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: categoryColor.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(sessionName.isEmpty)
                    .opacity(sessionName.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Session Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(categoryColor)
                }
            }
        }
    }
    
    private func startInterview() {
        // Here you would start the actual interview with:
        // - sessionName: User's custom session name
        // - selectedDuration: Interview duration
        // - category: Technical or Behavioral
        
        print("Starting \(category) interview:")
        print("Session Name: \(sessionName)")
        print("Duration: \(selectedDuration) minutes")
        
        // For now, just dismiss
        dismiss()
    }
}

#Preview {
    MockInterviewView()
}
