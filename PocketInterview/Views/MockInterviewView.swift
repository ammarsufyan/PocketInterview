import SwiftUI
import UniformTypeIdentifiers

struct MockInterviewView: View {
    @State private var selectedCategory = "Technical"
    @State private var showingCVPicker = false
    @State private var cvUploaded = false
    @State private var showingSessionSetup = false
    @State private var showingExtractionResults = false
    @State private var showingTavusInterview = false
    @StateObject private var cvExtractor = CVExtractor()
    
    @StateObject private var sessionData = SessionData()
    
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
                                
                                Text("Choose your interview type and meet your AI interviewer")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Interview Categories with Personas
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 16) {
                            // Technical Category - Steve
                            CategoryCard(
                                title: "Technical",
                                description: "Practice with Steve",
                                icon: "laptopcomputer",
                                color: .blue,
                                interviewerName: "Steve",
                                isSelected: selectedCategory == "Technical"
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = "Technical"
                                    resetSessionData()
                                }
                            }
                            
                            // Behavioral Category - Lucy
                            CategoryCard(
                                title: "Behavioral",
                                description: "Practice with Lucy",
                                icon: "person.2.fill",
                                color: .purple,
                                interviewerName: "Lucy",
                                isSelected: selectedCategory == "Behavioral"
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = "Behavioral"
                                    resetSessionData()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // CV Upload Section
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
                            cvExtractor: cvExtractor,
                            onUpload: {
                                showingCVPicker = true
                            },
                            onViewResults: {
                                showingExtractionResults = true
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    // Start Interview Button
                    VStack(spacing: 12) {
                        StartInterviewButton(
                            category: selectedCategory,
                            interviewerName: TavusConfig.getInterviewerName(for: selectedCategory),
                            isEnabled: cvUploaded
                        ) {
                            sessionData.category = selectedCategory
                            showingSessionSetup = true
                        }
                        .padding(.horizontal, 20)
                        
                        if !cvUploaded {
                            Text("Upload your CV to get personalized questions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Next: Set session name and duration")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Built by Bolt.new Badge
                    BoltBadgeImageView()
                        .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Mock Interview")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCVPicker) {
                CVPickerView(
                    category: selectedCategory,
                    cvExtractor: cvExtractor,
                    onUpload: { success in
                        if success {
                            withAnimation(.spring()) {
                                cvUploaded = true
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSessionSetup) {
                SessionSetupView(
                    sessionData: sessionData,
                    onSessionStart: {
                        showingSessionSetup = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingTavusInterview = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showingExtractionResults) {
                CVExtractionResultView(cvExtractor: cvExtractor, category: selectedCategory)
            }
            .fullScreenCover(isPresented: $showingTavusInterview) {
                TavusInterviewView(
                    sessionData: sessionData,
                    cvContext: cvExtractor.extractedText.isEmpty ? nil : cvExtractor.extractedText,
                    onBackToSetup: {
                        showingTavusInterview = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSessionSetup = true
                        }
                    }
                )
                .environmentObject(InterviewHistoryManager())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetSessionData() {
        cvUploaded = false
        cvExtractor.resetAnalysis()
        sessionData.reset()
    }
}

// MARK: - SessionData ObservableObject

class SessionData: ObservableObject {
    @Published var category: String = ""
    @Published var sessionName: String = ""
    @Published var duration: Int = 30
    
    func reset() {
        category = ""
        sessionName = ""
        duration = 30
    }
    
    func updateSession(name: String, duration: Int) {
        self.sessionName = name
        self.duration = duration
    }
    
    var isValid: Bool {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !category.isEmpty && !trimmedName.isEmpty && trimmedName.count >= 3
    }
}

// MARK: - Supporting Views

struct CategoryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let interviewerName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
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
    @ObservedObject var cvExtractor: CVExtractor
    let onUpload: () -> Void
    let onViewResults: () -> Void
    
    private var uploadDescription: String {
        let interviewerName = TavusConfig.getInterviewerName(for: category)
        
        switch category {
        case "Technical":
            return isUploaded ? 
                "\(interviewerName) will create personalized technical questions based on your skills and experience" :
                "\(interviewerName) will analyze your technical background"
        case "Behavioral":
            return isUploaded ?
                "\(interviewerName) will create personalized behavioral questions based on your work experience and achievements" :
                "\(interviewerName) will analyze your background"
        default:
            return "Your AI interviewer will analyze your background"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            if isUploaded && cvExtractor.cvAnalysis != nil {
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analysis Complete")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            if let analysis = cvExtractor.cvAnalysis {
                                Text(analysis.summary)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: onViewResults) {
                            Text("View Details")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(category == "Technical" ? .blue : .purple)
                        }
                    }
                }
            }
            
            if cvExtractor.isExtracting {
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Analyzing your CV...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
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
    let interviewerName: String
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
                
                Text("Start Interview with \(interviewerName)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isEnabled ? .white : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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

struct SessionSetupView: View {
    @ObservedObject var sessionData: SessionData
    let onSessionStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var localSessionName = ""
    @State private var localSelectedDuration = 30
    @FocusState private var isTextFieldFocused: Bool
    
    private let durations = [15, 30, 45, 60]
    
    private var categoryColor: Color {
        sessionData.category == "Technical" ? .blue : .purple
    }
    
    private var interviewerName: String {
        TavusConfig.getInterviewerName(for: sessionData.category)
    }
    
    private var placeholderText: String {
        switch sessionData.category {
        case "Technical":
            return "e.g., iOS Development Practice, Data Structures Deep Dive"
        case "Behavioral":
            return "e.g., Leadership Experience, Communication Skills"
        default:
            return "e.g., Interview Practice Session"
        }
    }
    
    private var trimmedSessionName: String {
        localSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isSessionNameValid: Bool {
        !trimmedSessionName.isEmpty && trimmedSessionName.count >= 3
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: sessionData.category == "Technical" ? "laptopcomputer" : "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(categoryColor)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("Setup Your Session")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(sessionData.category) Interview with \(interviewerName)")
                                .font(.headline)
                                .foregroundColor(categoryColor)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 24) {
                        // Session Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Session Name")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("*")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Enter session name...", text: $localSessionName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isSessionNameValid ? categoryColor.opacity(0.5) : 
                                                (localSessionName.isEmpty ? Color.clear : Color.red.opacity(0.5)),
                                                lineWidth: 1
                                            )
                                    )
                                    .focused($isTextFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        if !isSessionNameValid {
                                            isTextFieldFocused = true
                                        }
                                    }
                                    .onChange(of: localSessionName) { _, _ in
                                        // Validation happens automatically through computed property
                                    }
                                
                                Text(placeholderText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                                
                                if !localSessionName.isEmpty && !isSessionNameValid {
                                    Text("Session name must be at least 3 characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Text("This name will appear in your interview history")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Duration Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Duration")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(durations, id: \.self) { duration in
                                    DurationCard(
                                        duration: duration,
                                        isSelected: localSelectedDuration == duration,
                                        categoryColor: categoryColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            localSelectedDuration = duration
                                        }
                                    }
                                }
                            }
                            
                            Text("How long do you want to practice with \(interviewerName)?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Start Button
                    Button(action: {
                        startTavusInterview()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.wave.2.fill")
                                .font(.title2)
                            
                            Text("Start Interview with \(interviewerName)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isSessionNameValid ? .white : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Group {
                                if isSessionNameValid {
                                    LinearGradient(
                                        gradient: Gradient(colors: [categoryColor, categoryColor.opacity(0.8)]),
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
                            color: isSessionNameValid ? categoryColor.opacity(0.3) : Color.clear,
                            radius: isSessionNameValid ? 8 : 0,
                            x: 0,
                            y: 4
                        )
                        .scaleEffect(isSessionNameValid ? 1.0 : 0.98)
                    }
                    .disabled(!isSessionNameValid)
                    .animation(.easeInOut(duration: 0.2), value: isSessionNameValid)
                    .padding(.horizontal, 20)
                    
                    if !isSessionNameValid {
                        if localSessionName.isEmpty {
                            Text("Please enter a session name to continue")
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Session name must be at least 3 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("Ready to start your personalized interview with \(interviewerName)!")
                            .font(.caption)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .fontWeight(.medium)
                    }
                    
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
            .onAppear {
                localSessionName = sessionData.sessionName
                localSelectedDuration = sessionData.duration
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func startTavusInterview() {
        guard isSessionNameValid else { 
            return 
        }
        
        sessionData.updateSession(name: trimmedSessionName, duration: localSelectedDuration)
        
        onSessionStart()
        dismiss()
    }
}

struct DurationCard: View {
    let duration: Int
    let isSelected: Bool
    let categoryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(duration)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : categoryColor)
                
                Text("minutes")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [categoryColor, categoryColor.opacity(0.8)]),
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
                        isSelected ? Color.clear : categoryColor.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? categoryColor.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct CVPickerView: View {
    let category: String
    @ObservedObject var cvExtractor: CVExtractor
    let onUpload: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    @State private var hasAnalysis = false
    
    private var categoryColor: Color {
        category == "Technical" ? .blue : .purple
    }
    
    private var interviewerName: String {
        TavusConfig.getInterviewerName(for: category)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: cvExtractor.isExtracting ? "doc.text.magnifyingglass" : "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(cvExtractor.isExtracting ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cvExtractor.isExtracting)
                    
                    VStack(spacing: 12) {
                        Text(cvExtractor.isExtracting ? "Analyzing CV..." : "Upload Your CV")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("For \(category) Interview with \(interviewerName)")
                            .font(.headline)
                            .foregroundColor(categoryColor)
                            .fontWeight(.semibold)
                    }
                }
                
                if cvExtractor.isExtracting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Extracting text and analyzing your background...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 16) {
                        Button(action: {
                            showingDocumentPicker = true
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
                }
                
                if let error = cvExtractor.extractionError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
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
                    .disabled(cvExtractor.isExtracting)
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf, .plainText, UTType(filenameExtension: "doc")!, UTType(filenameExtension: "docx")!],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }
            .onReceive(cvExtractor.$cvAnalysis) { analysis in
                let newHasAnalysis = analysis != nil
                if newHasAnalysis != hasAnalysis {
                    hasAnalysis = newHasAnalysis
                    if hasAnalysis && !cvExtractor.isExtracting {
                        onUpload(true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { 
                cvExtractor.extractionError = "No file selected"
                return 
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                cvExtractor.extractionError = "Cannot access the selected file. Please try selecting the file again."
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw NSError(domain: "FileError", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
                }
                
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
                guard fileSize <= maxSize else {
                    throw NSError(domain: "FileError", code: 413, userInfo: [NSLocalizedDescriptionKey: "File is too large. Maximum size is 10MB."])
                }
                
                let data = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                
                DispatchQueue.main.async {
                    self.cvExtractor.extractionError = nil
                }
                
                cvExtractor.extractTextFromDocument(data: data, fileName: fileName)
                
            } catch {
                let errorMessage: String
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case NSFileReadNoPermissionError:
                        errorMessage = "Permission denied. Please ensure the file is accessible and try again."
                    case NSFileReadNoSuchFileError:
                        errorMessage = "File not found. Please select a valid file."
                    case 413:
                        errorMessage = nsError.localizedDescription
                    default:
                        errorMessage = "Failed to read file: \(nsError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Failed to read file: \(error.localizedDescription)"
                }
                
                DispatchQueue.main.async {
                    self.cvExtractor.extractionError = errorMessage
                }
            }
            
        case .failure(let error):
            cvExtractor.extractionError = "Failed to select file: \(error.localizedDescription)"
        }
    }
}

#Preview {
    MockInterviewView()
}