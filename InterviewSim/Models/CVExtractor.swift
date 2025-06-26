//
//  CVExtractor.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

@MainActor
class CVExtractor: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isExtracting: Bool = false
    @Published var extractionError: String?
    @Published var cvAnalysis: CVAnalysis?
    @Published var analysisMethod: String = "" // Track which method was used
    
    private let geminiService = GeminiService()
    
    func extractTextFromDocument(data: Data, fileName: String) {
        isExtracting = true
        extractionError = nil
        analysisMethod = ""
        
        Task {
            var extractedContent = ""
            
            // Determine file type based on file extension
            let fileExtension = (fileName as NSString).pathExtension.lowercased()
            
            switch fileExtension {
            case "pdf":
                extractedContent = await extractTextFromPDF(data: data)
            case "doc", "docx":
                extractedContent = await extractTextFromWord(data: data, fileName: fileName)
            default:
                await MainActor.run {
                    self.extractionError = "Unsupported file format. Please use PDF, DOC, or DOCX."
                    self.isExtracting = false
                }
                return
            }
            
            await MainActor.run {
                self.extractedText = extractedContent
                self.isExtracting = false
                
                // Print extracted text for debugging
                print("=== CV EXTRACTION RESULTS ===")
                print("File: \(fileName)")
                print("Type: \(fileExtension.uppercased())")
                print("Text Length: \(extractedContent.count) characters")
                print("=== EXTRACTED TEXT ===")
                print(extractedContent)
                print("=== END EXTRACTION ===")
            }
            
            // Start analysis after extraction
            await analyzeCV(text: extractedContent)
        }
    }
    
    // Reset function to clear previous analysis
    func resetAnalysis() {
        extractedText = ""
        extractionError = nil
        cvAnalysis = nil
        isExtracting = false
        analysisMethod = ""
    }
    
    private func extractTextFromPDF(data: Data) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pdfDocument = PDFDocument(data: data) else {
                    DispatchQueue.main.async {
                        self.extractionError = "Failed to read PDF file"
                    }
                    continuation.resume(returning: "")
                    return
                }
                
                var extractedText = ""
                let pageCount = pdfDocument.pageCount
                
                for pageIndex in 0..<pageCount {
                    if let page = pdfDocument.page(at: pageIndex) {
                        if let pageText = page.string {
                            extractedText += pageText + "\n"
                        }
                    }
                }
                
                continuation.resume(returning: extractedText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
    
    private func extractTextFromWord(data: Data, fileName: String) async -> String {
        // Enhanced Word document simulation with more realistic content
        // In a real app, you'd use a third-party library or server-side extraction
        
        // Generate more comprehensive simulated text based on file name patterns
        let simulatedText = generateRealisticCVText(fileName: fileName)
        
        return simulatedText
    }
    
    private func generateRealisticCVText(fileName: String) -> String {
        // Generate different CV content based on file name hints
        let name = extractNameFromFileName(fileName)
        
        let cvTemplates = [
            generateTechnicalCV(name: name),
            generateBusinessCV(name: name),
            generateDesignCV(name: name),
            generateDataScienceCV(name: name)
        ]
        
        // Return a random template or the first one
        return cvTemplates.randomElement() ?? cvTemplates[0]
    }
    
    private func extractNameFromFileName(_ fileName: String) -> String {
        let baseName = (fileName as NSString).deletingPathExtension
        let cleanName = baseName.replacingOccurrences(of: "_", with: " ")
                                .replacingOccurrences(of: "-", with: " ")
                                .replacingOccurrences(of: "CV", with: "")
                                .replacingOccurrences(of: "Resume", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanName.isEmpty ? "John Doe" : cleanName
    }
    
    private func generateTechnicalCV(name: String) -> String {
        return """
        \(name)
        Senior Software Engineer
        Email: \(name.lowercased().replacingOccurrences(of: " ", with: "."))@email.com
        Phone: +1 (555) 123-4567
        Location: San Francisco, CA
        LinkedIn: linkedin.com/in/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        GitHub: github.com/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        
        PROFESSIONAL SUMMARY
        Experienced software engineer with 7+ years of expertise in full-stack development, 
        cloud architecture, and team leadership. Proven track record of delivering scalable 
        solutions and mentoring junior developers.
        
        TECHNICAL SKILLS
        • Programming Languages: Python, JavaScript, TypeScript, Java, Go, Swift
        • Frontend: React, Vue.js, Angular, HTML5, CSS3, Sass, Tailwind CSS
        • Backend: Node.js, Express, Django, Flask, Spring Boot, FastAPI
        • Mobile: React Native, Flutter, iOS (Swift), Android (Kotlin)
        • Databases: PostgreSQL, MongoDB, Redis, MySQL, DynamoDB
        • Cloud Platforms: AWS, Google Cloud Platform, Microsoft Azure
        • DevOps: Docker, Kubernetes, Jenkins, GitLab CI/CD, Terraform
        • Tools: Git, Jira, Confluence, Figma, Postman, VS Code
        
        PROFESSIONAL EXPERIENCE
        
        Senior Software Engineer | TechCorp Inc. | 2021 - Present
        • Led development of microservices architecture serving 2M+ daily active users
        • Implemented CI/CD pipelines reducing deployment time by 60%
        • Mentored 5 junior developers and conducted technical interviews
        • Technologies: React, Node.js, AWS, Docker, PostgreSQL
        
        Software Engineer | StartupXYZ | 2019 - 2021
        • Built real-time chat application handling 100K+ concurrent users
        • Optimized database queries improving response time by 40%
        • Collaborated with product team to define technical requirements
        • Technologies: Vue.js, Python, Django, Redis, MySQL
        
        Junior Developer | WebSolutions Ltd. | 2017 - 2019
        • Developed responsive web applications for 20+ clients
        • Participated in agile development process and code reviews
        • Fixed bugs and implemented new features based on user feedback
        • Technologies: JavaScript, PHP, Laravel, Bootstrap
        
        EDUCATION
        Bachelor of Science in Computer Science
        University of California, Berkeley | 2013 - 2017
        GPA: 3.8/4.0
        Relevant Coursework: Data Structures, Algorithms, Software Engineering, Database Systems
        
        Master of Science in Software Engineering
        Stanford University | 2017 - 2019
        Thesis: "Scalable Microservices Architecture for Cloud Applications"
        GPA: 3.9/4.0
        
        CERTIFICATIONS
        • AWS Certified Solutions Architect - Professional (2022)
        • Google Cloud Professional Developer (2021)
        • Certified Kubernetes Administrator (CKA) (2020)
        • Oracle Certified Professional, Java SE 11 Developer (2019)
        • Microsoft Azure Developer Associate (2021)
        • Certified ScrumMaster (CSM) (2020)
        
        PROJECTS
        • E-commerce Platform - Built scalable online marketplace with payment integration
        • Task Management App - Developed cross-platform mobile app with offline sync
        • Data Analytics Dashboard - Created real-time visualization tool for business metrics
        • Open Source Contributor - Contributed to React, Vue.js, and Node.js projects
        
        ACHIEVEMENTS
        • Increased system performance by 50% through optimization initiatives
        • Led team that won company hackathon for innovative AI solution
        • Speaker at 3 tech conferences on cloud architecture best practices
        • Published 5 technical articles with 10K+ total views
        
        LANGUAGES
        • English (Native)
        • Spanish (Conversational)
        • Mandarin (Basic)
        """
    }
    
    private func generateBusinessCV(name: String) -> String {
        return """
        \(name)
        Senior Product Manager
        Email: \(name.lowercased().replacingOccurrences(of: " ", with: "."))@email.com
        Phone: +1 (555) 987-6543
        Location: New York, NY
        LinkedIn: linkedin.com/in/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        
        EXECUTIVE SUMMARY
        Results-driven product manager with 8+ years of experience leading cross-functional 
        teams to deliver innovative products. Expertise in product strategy, user research, 
        and data-driven decision making.
        
        CORE COMPETENCIES
        • Product Strategy & Roadmap Planning
        • User Experience Design & Research
        • Agile & Scrum Methodologies
        • Data Analysis & A/B Testing
        • Stakeholder Management
        • Go-to-Market Strategy
        • Team Leadership & Mentoring
        • Business Intelligence Tools
        
        PROFESSIONAL EXPERIENCE
        
        Senior Product Manager | GlobalTech Solutions | 2020 - Present
        • Managed product portfolio generating $50M+ annual revenue
        • Led cross-functional team of 15 engineers, designers, and analysts
        • Increased user engagement by 35% through data-driven feature optimization
        • Launched 3 major product features ahead of schedule and under budget
        
        Product Manager | InnovateCorp | 2018 - 2020
        • Defined product requirements for mobile application with 1M+ users
        • Conducted user research and usability testing to inform product decisions
        • Collaborated with engineering team to prioritize feature development
        • Achieved 25% increase in user retention through improved onboarding
        
        Associate Product Manager | StartupHub | 2016 - 2018
        • Supported senior PM in managing B2B SaaS product development
        • Analyzed user feedback and market trends to identify opportunities
        • Created detailed product specifications and user stories
        • Coordinated with marketing team on product launch campaigns
        
        Business Analyst | ConsultingFirm LLC | 2015 - 2016
        • Analyzed business processes and recommended efficiency improvements
        • Created detailed reports and presentations for C-level executives
        • Managed client relationships and project timelines
        • Reduced operational costs by 20% through process optimization
        
        EDUCATION
        Master of Business Administration (MBA)
        Stanford Graduate School of Business | 2013 - 2015
        Concentration: Technology Management
        GPA: 3.7/4.0
        
        Bachelor of Arts in Economics
        Harvard University | 2009 - 2013
        Magna Cum Laude, Phi Beta Kappa
        GPA: 3.8/4.0
        
        Certificate in Digital Marketing
        Google Digital Marketing Institute | 2020
        
        CERTIFICATIONS
        • Certified Scrum Product Owner (CSPO) - Scrum Alliance (2021)
        • Google Analytics Individual Qualification (IQ) - Google (2020)
        • Pragmatic Marketing Certified (PMC) - Pragmatic Institute (2019)
        • Product Management Certificate - UC Berkeley Extension (2018)
        • Lean Six Sigma Green Belt - ASQ (2017)
        
        KEY ACHIEVEMENTS
        • Launched product that captured 15% market share within first year
        • Led digital transformation initiative saving company $2M annually
        • Mentored 8 junior product managers, 6 received promotions
        • Featured speaker at ProductCon and Mind the Product conferences
        
        TECHNICAL SKILLS
        • Analytics: Google Analytics, Mixpanel, Amplitude, Tableau
        • Design: Figma, Sketch, Adobe Creative Suite
        • Project Management: Jira, Asana, Trello, Monday.com
        • Databases: SQL, Excel, Google Sheets
        """
    }
    
    private func generateDesignCV(name: String) -> String {
        return """
        \(name)
        Senior UX/UI Designer
        Email: \(name.lowercased().replacingOccurrences(of: " ", with: "."))@email.com
        Phone: +1 (555) 456-7890
        Location: Los Angeles, CA
        Portfolio: \(name.lowercased().replacingOccurrences(of: " ", with: "")).design
        LinkedIn: linkedin.com/in/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        Dribbble: dribbble.com/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        
        CREATIVE SUMMARY
        Passionate UX/UI designer with 6+ years of experience creating user-centered 
        digital experiences. Expertise in design thinking, prototyping, and translating 
        complex problems into elegant solutions.
        
        DESIGN SKILLS
        • User Experience (UX) Design
        • User Interface (UI) Design
        • Interaction Design
        • Visual Design
        • Design Systems
        • Prototyping & Wireframing
        • User Research & Testing
        • Information Architecture
        
        TOOLS & SOFTWARE
        • Design: Figma, Sketch, Adobe XD, Adobe Creative Suite
        • Prototyping: InVision, Principle, Framer, Marvel
        • Research: Miro, Mural, UsabilityHub, Hotjar
        • Collaboration: Slack, Notion, Abstract, Zeplin
        • Development: HTML, CSS, JavaScript (basic)
        
        PROFESSIONAL EXPERIENCE
        
        Senior UX/UI Designer | DesignStudio Pro | 2021 - Present
        • Lead designer for mobile app with 2M+ downloads and 4.8 App Store rating
        • Conducted user research and usability testing for 5 major product releases
        • Created comprehensive design system adopted across 3 product lines
        • Mentored 3 junior designers and established design review processes
        
        UX/UI Designer | TechStartup Inc. | 2019 - 2021
        • Redesigned e-commerce platform resulting in 40% increase in conversions
        • Collaborated with product and engineering teams in agile environment
        • Created interactive prototypes for stakeholder presentations
        • Improved user onboarding flow reducing drop-off rate by 30%
        
        Junior Designer | CreativeAgency | 2018 - 2019
        • Designed websites and mobile apps for 15+ clients across various industries
        • Participated in client meetings and design presentations
        • Created brand identities and marketing materials
        • Assisted senior designers with user research and testing
        
        EDUCATION
        Bachelor of Fine Arts in Graphic Design
        Art Center College of Design | 2014 - 2018
        Summa Cum Laude
        GPA: 3.9/4.0
        
        Certificate in UX Design
        General Assembly | 2018
        
        CERTIFICATIONS
        • Google UX Design Professional Certificate - Google (2021)
        • Nielsen Norman Group UX Certification - NN/g (2020)
        • Adobe Certified Expert (ACE) - Photoshop & Illustrator (2019)
        • Certified Usability Analyst (CUA) - Human Factors International (2020)
        • Design Thinking Certificate - IDEO U (2019)
        
        NOTABLE PROJECTS
        • HealthTech App - Designed telemedicine platform used by 500K+ patients
        • FinTech Dashboard - Created trading interface for cryptocurrency exchange
        • E-learning Platform - Designed educational app for K-12 students
        • Smart Home App - Developed IoT device control interface
        
        ACHIEVEMENTS
        • Won "Best Mobile App Design" at Design Awards 2022
        • Featured in Design Inspiration blog with 50K+ views
        • Increased user satisfaction scores by 45% through design improvements
        • Led design workshop at UX Week conference
        
        SOFT SKILLS
        • Creative Problem Solving
        • Cross-functional Collaboration
        • Presentation & Communication
        • Project Management
        • Attention to Detail
        • Empathy & User Advocacy
        """
    }
    
    private func generateDataScienceCV(name: String) -> String {
        return """
        \(name)
        Senior Data Scientist
        Email: \(name.lowercased().replacingOccurrences(of: " ", with: "."))@email.com
        Phone: +1 (555) 321-9876
        Location: Seattle, WA
        LinkedIn: linkedin.com/in/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        GitHub: github.com/\(name.lowercased().replacingOccurrences(of: " ", with: ""))
        
        PROFESSIONAL SUMMARY
        Experienced data scientist with 5+ years of expertise in machine learning, 
        statistical analysis, and big data processing. Proven ability to extract 
        actionable insights from complex datasets and drive business decisions.
        
        TECHNICAL SKILLS
        • Programming: Python, R, SQL, Scala, Java
        • Machine Learning: Scikit-learn, TensorFlow, PyTorch, Keras
        • Data Processing: Pandas, NumPy, Spark, Hadoop, Kafka
        • Visualization: Matplotlib, Seaborn, Plotly, Tableau, Power BI
        • Databases: PostgreSQL, MongoDB, Cassandra, Snowflake
        • Cloud Platforms: AWS, Google Cloud, Azure
        • MLOps: MLflow, Kubeflow, Docker, Kubernetes
        • Statistics: Hypothesis Testing, A/B Testing, Bayesian Analysis
        
        PROFESSIONAL EXPERIENCE
        
        Senior Data Scientist | DataTech Corp | 2021 - Present
        • Built recommendation system increasing user engagement by 25%
        • Developed fraud detection model reducing false positives by 40%
        • Led team of 4 data scientists on customer segmentation project
        • Deployed ML models to production serving 10M+ daily predictions
        
        Data Scientist | AnalyticsPro | 2019 - 2021
        • Created predictive models for customer churn with 85% accuracy
        • Analyzed A/B test results for product optimization initiatives
        • Built automated reporting dashboards for executive team
        • Collaborated with engineering team to implement ML pipelines
        
        Junior Data Analyst | InsightsCorp | 2018 - 2019
        • Performed statistical analysis on customer behavior data
        • Created data visualizations for business stakeholders
        • Cleaned and preprocessed large datasets for analysis
        • Supported senior data scientists with model development
        
        EDUCATION
        Master of Science in Data Science
        University of Washington | 2016 - 2018
        Thesis: "Deep Learning for Natural Language Processing"
        GPA: 3.8/4.0
        
        Bachelor of Science in Mathematics
        MIT | 2012 - 2016
        Minor in Computer Science
        GPA: 3.7/4.0
        
        Certificate in Machine Learning
        Stanford Online | 2017
        
        CERTIFICATIONS
        • AWS Certified Machine Learning - Specialty (2022)
        • Google Cloud Professional Data Engineer (2021)
        • Certified Analytics Professional (CAP) - INFORMS (2020)
        • TensorFlow Developer Certificate - Google (2021)
        • Microsoft Azure Data Scientist Associate (2020)
        • Databricks Certified Associate Developer for Apache Spark (2019)
        
        KEY PROJECTS
        • Customer Lifetime Value Prediction - Increased marketing ROI by 30%
        • Natural Language Processing for Sentiment Analysis - 92% accuracy
        • Computer Vision for Quality Control - Reduced defect rate by 50%
        • Time Series Forecasting for Demand Planning - Improved accuracy by 35%
        
        PUBLICATIONS & PRESENTATIONS
        • "Advanced ML Techniques for Business Applications" - Data Science Conference 2022
        • "Scalable Data Processing with Apache Spark" - Tech Blog (5K+ views)
        • Co-authored research paper on deep learning published in IEEE journal
        
        ACHIEVEMENTS
        • Developed ML model that generated $2M+ in additional revenue
        • Led data science team that won company innovation award
        • Mentored 6 junior data scientists and analysts
        • Speaker at 4 data science meetups and conferences
        """
    }
    
    private func analyzeCV(text: String) async {
        let analysis = CVAnalysis()
        
        // 🚀 HYBRID APPROACH: Try Gemini API first, fallback to local analysis
        do {
            print("🤖 Attempting Gemini API analysis...")
            let geminiResult = try await geminiService.analyzeCV(text: text)
            
            // Convert Gemini result to CVAnalysis
            await MainActor.run {
                analysis.technicalSkills = geminiResult.technicalSkills
                analysis.softSkills = geminiResult.softSkills
                analysis.workExperience = geminiResult.workExperience
                analysis.yearsOfExperience = geminiResult.yearsOfExperience
                analysis.education = geminiResult.education
                analysis.projects = geminiResult.projects
                analysis.certifications = geminiResult.certifications
                analysis.achievements = geminiResult.achievements
                
                self.cvAnalysis = analysis
                self.analysisMethod = "🤖 Gemini AI"
                
                print("=== 🤖 GEMINI AI ANALYSIS RESULTS ===")
                print("📊 Technical Skills (\(analysis.technicalSkills.count)): \(analysis.technicalSkills)")
                print("🤝 Soft Skills (\(analysis.softSkills.count)): \(analysis.softSkills)")
                print("⏰ Years of Experience: \(analysis.yearsOfExperience)")
                print("💼 Work Experience (\(analysis.workExperience.count)): \(analysis.workExperience)")
                print("🎓 Education (\(analysis.education.count)): \(analysis.education)")
                print("🚀 Projects (\(analysis.projects.count)): \(analysis.projects)")
                print("🏆 Certifications (\(analysis.certifications.count)): \(analysis.certifications)")
                print("⭐ Achievements (\(analysis.achievements.count)): \(analysis.achievements)")
                print("📝 Summary: \(geminiResult.summary)")
                print("=== END GEMINI ANALYSIS ===")
            }
            
        } catch {
            print("⚠️ Gemini API failed, using enhanced local analysis: \(error)")
            
            // Fallback to enhanced local analysis
            await MainActor.run {
                self.performLocalAnalysis(analysis: analysis, text: text)
                self.analysisMethod = "🔧 Enhanced Local Analysis"
            }
        }
    }
    
    private func performLocalAnalysis(analysis: CVAnalysis, text: String) {
        // Enhanced analysis with better pattern recognition
        analysis.technicalSkills = extractTechnicalSkills(from: text)
        analysis.softSkills = extractSoftSkills(from: text)
        analysis.workExperience = extractWorkExperience(from: text)
        analysis.yearsOfExperience = extractYearsOfExperience(from: text)
        analysis.education = extractEducation(from: text)
        analysis.projects = extractProjects(from: text)
        analysis.certifications = extractCertifications(from: text)
        analysis.achievements = extractAchievements(from: text)
        
        self.cvAnalysis = analysis
        
        // Enhanced console output
        print("=== 🔧 ENHANCED LOCAL ANALYSIS RESULTS ===")
        print("📊 Technical Skills (\(analysis.technicalSkills.count)): \(analysis.technicalSkills)")
        print("🤝 Soft Skills (\(analysis.softSkills.count)): \(analysis.softSkills)")
        print("⏰ Years of Experience: \(analysis.yearsOfExperience)")
        print("💼 Work Experience (\(analysis.workExperience.count)): \(analysis.workExperience)")
        print("🎓 Education (\(analysis.education.count)): \(analysis.education)")
        print("🚀 Projects (\(analysis.projects.count)): \(analysis.projects)")
        print("🏆 Certifications (\(analysis.certifications.count)): \(analysis.certifications)")
        print("⭐ Achievements (\(analysis.achievements.count)): \(analysis.achievements)")
        print("📝 Summary: \(analysis.summary)")
        print("=== END ENHANCED LOCAL ANALYSIS ===")
    }
    
    private func extractTechnicalSkills(from text: String) -> [String] {
        let skillKeywords = [
            // Programming Languages
            "Swift", "SwiftUI", "UIKit", "Objective-C", "Python", "Java", "JavaScript", "TypeScript",
            "React", "Vue", "Angular", "Node.js", "Express", "Django", "Flask", "Spring Boot",
            "Kotlin", "Flutter", "React Native", "Go", "Rust", "C++", "C#", "PHP", "Ruby",
            
            // Databases
            "MongoDB", "PostgreSQL", "MySQL", "Redis", "DynamoDB", "Cassandra", "Snowflake",
            "SQLite", "Oracle", "SQL Server", "Firebase", "Realm",
            
            // Cloud & DevOps
            "AWS", "Google Cloud", "Azure", "Docker", "Kubernetes", "Jenkins", "GitLab CI/CD",
            "Terraform", "Ansible", "Chef", "Puppet", "Nginx", "Apache",
            
            // Mobile & Frontend
            "iOS", "Android", "Xcode", "Android Studio", "HTML5", "CSS3", "Sass", "SCSS",
            "Bootstrap", "Tailwind CSS", "Material UI", "Ant Design",
            
            // Data Science & ML
            "TensorFlow", "PyTorch", "Scikit-learn", "Pandas", "NumPy", "Matplotlib", "Seaborn",
            "Jupyter", "R", "Tableau", "Power BI", "Spark", "Hadoop", "Kafka",
            
            // Tools & Frameworks
            "Git", "GitHub", "GitLab", "Bitbucket", "Jira", "Confluence", "Slack", "Figma",
            "Sketch", "Adobe XD", "Photoshop", "Illustrator", "VS Code", "IntelliJ",
            
            // Architecture & Patterns
            "Microservices", "REST API", "GraphQL", "MVVM", "MVC", "Clean Architecture",
            "Design Patterns", "Agile", "Scrum", "DevOps", "CI/CD"
        ]
        
        var foundSkills: [String] = []
        let lowercasedText = text.lowercased()
        
        for skill in skillKeywords {
            if lowercasedText.contains(skill.lowercased()) {
                foundSkills.append(skill)
            }
        }
        
        return Array(Set(foundSkills)).sorted()
    }
    
    private func extractSoftSkills(from text: String) -> [String] {
        let softSkillKeywords = [
            "Leadership", "Communication", "Teamwork", "Problem Solving", "Critical Thinking",
            "Project Management", "Agile", "Scrum", "Mentoring", "Training", "Coaching",
            "Collaboration", "Time Management", "Organization", "Analytical Thinking",
            "Creative Problem Solving", "Adaptability", "Flexibility", "Innovation",
            "Strategic Thinking", "Decision Making", "Conflict Resolution", "Negotiation",
            "Presentation Skills", "Public Speaking", "Cross-functional Collaboration"
        ]
        
        var foundSkills: [String] = []
        let lowercasedText = text.lowercased()
        
        for skill in softSkillKeywords {
            if lowercasedText.contains(skill.lowercased()) {
                foundSkills.append(skill)
            }
        }
        
        return Array(Set(foundSkills)).sorted()
    }
    
    private func extractWorkExperience(from text: String) -> [String] {
        let experiencePatterns = [
            "Senior iOS Developer", "iOS Developer", "Mobile Developer", "Software Engineer",
            "Senior Software Engineer", "Lead Developer", "Tech Lead", "Engineering Manager",
            "Frontend Developer", "Backend Developer", "Full Stack Developer", "DevOps Engineer",
            "Data Scientist", "Senior Data Scientist", "Machine Learning Engineer",
            "Product Manager", "Senior Product Manager", "UX Designer", "UI Designer",
            "UX/UI Designer", "Senior Designer", "Design Lead", "Creative Director",
            "Business Analyst", "Data Analyst", "Systems Analyst", "Solutions Architect",
            "Cloud Architect", "Security Engineer", "QA Engineer", "Test Engineer"
        ]
        
        var experiences: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            for pattern in experiencePatterns {
                if trimmedLine.localizedCaseInsensitiveContains(pattern) {
                    experiences.append(pattern)
                    break
                }
            }
        }
        
        return Array(Set(experiences)).sorted()
    }
    
    private func extractYearsOfExperience(from text: String) -> Int {
        // Enhanced regex patterns for years of experience
        let patterns = [
            "(\\d+)\\+?\\s*years?\\s*of\\s*experience",
            "(\\d+)\\+?\\s*years?\\s*experience",
            "(\\d+)\\+?\\s*yrs?\\s*experience",
            "experience.*?(\\d+)\\+?\\s*years?",
            "(\\d+)\\+?\\s*years?.*?experience"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let yearRange = Range(match.range(at: 1), in: text)
                    if let yearRange = yearRange {
                        let yearString = String(text[yearRange])
                        if let years = Int(yearString) {
                            return years
                        }
                    }
                }
            }
        }
        
        return 0
    }
    
    // 🔥 ENHANCED EDUCATION EXTRACTION
    private func extractEducation(from text: String) -> [String] {
        var education: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Enhanced patterns for education detection
        let educationPatterns = [
            // Degree patterns
            "bachelor.*?of.*?(science|arts|engineering|business|fine arts)",
            "master.*?of.*?(science|arts|business|engineering)",
            "phd.*?in.*?",
            "doctorate.*?in.*?",
            "doctor.*?of.*?",
            "associate.*?degree",
            "diploma.*?in.*?",
            "certificate.*?in.*?",
            
            // University patterns
            "university.*?\\|.*?\\d{4}",
            "college.*?\\|.*?\\d{4}",
            "institute.*?\\|.*?\\d{4}",
            "school.*?\\|.*?\\d{4}",
            
            // GPA patterns
            "gpa.*?\\d\\.\\d",
            "grade.*?point.*?average",
            
            // Graduation patterns
            "graduated.*?\\d{4}",
            "graduation.*?\\d{4}",
            "class.*?of.*?\\d{4}",
            
            // Honor patterns
            "magna cum laude",
            "summa cum laude",
            "cum laude",
            "with distinction",
            "with honors",
            "dean's list",
            "honor roll"
        ]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let lowercaseLine = trimmedLine.lowercased()
            
            // Skip if line is too short or too long
            guard trimmedLine.count > 10 && trimmedLine.count < 300 else { continue }
            
            // Check for education patterns
            for pattern in educationPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(location: 0, length: lowercaseLine.utf16.count)
                    if regex.firstMatch(in: lowercaseLine, options: [], range: range) != nil {
                        education.append(trimmedLine)
                        break
                    }
                }
            }
            
            // Additional keyword-based detection
            let educationKeywords = [
                "bachelor", "master", "phd", "doctorate", "degree", "university", "college",
                "institute", "school", "gpa", "graduated", "graduation", "thesis",
                "coursework", "major", "minor", "concentration", "specialization"
            ]
            
            var keywordCount = 0
            for keyword in educationKeywords {
                if lowercaseLine.contains(keyword) {
                    keywordCount += 1
                }
            }
            
            // If line contains multiple education keywords, likely education-related
            if keywordCount >= 2 && !education.contains(trimmedLine) {
                education.append(trimmedLine)
            }
        }
        
        return Array(Set(education)).sorted()
    }
    
    private func extractProjects(from text: String) -> [String] {
        var projects: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Look for project indicators
            if (trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*")) &&
               (trimmedLine.localizedCaseInsensitiveContains("app") ||
                trimmedLine.localizedCaseInsensitiveContains("platform") ||
                trimmedLine.localizedCaseInsensitiveContains("system") ||
                trimmedLine.localizedCaseInsensitiveContains("project") ||
                trimmedLine.localizedCaseInsensitiveContains("built") ||
                trimmedLine.localizedCaseInsensitiveContains("developed") ||
                trimmedLine.localizedCaseInsensitiveContains("created")) {
                
                let projectName = trimmedLine.replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
                if !projectName.isEmpty && projectName.count < 150 {
                    projects.append(projectName)
                }
            }
        }
        
        return Array(Set(projects)).sorted()
    }
    
    // 🔥 ENHANCED CERTIFICATIONS EXTRACTION
    private func extractCertifications(from text: String) -> [String] {
        var certifications: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Enhanced certification patterns
        let certificationPatterns = [
            // AWS Certifications
            "aws certified.*?(solutions architect|developer|sysops|devops|security|machine learning|data analytics|database|network|advanced networking)",
            "amazon web services.*?certified",
            
            // Google Cloud Certifications
            "google cloud.*?(professional|associate).*?(cloud architect|data engineer|cloud developer|cloud security engineer|cloud network engineer)",
            "gcp.*?certified",
            
            // Microsoft Azure Certifications
            "microsoft azure.*?(fundamentals|associate|expert).*?(administrator|developer|solutions architect|security engineer|data engineer)",
            "azure.*?certified",
            
            // Programming & Development
            "oracle certified.*?(professional|associate).*?(java|database|mysql)",
            "certified.*?(scrum master|product owner|agile)",
            "pmp.*?certified",
            "cissp.*?certified",
            "comptia.*?(security\\+|network\\+|a\\+|linux\\+)",
            
            // Design & UX
            "adobe certified.*?(expert|associate).*?(photoshop|illustrator|indesign|after effects)",
            "google ux design.*?certificate",
            "nielsen norman group.*?certification",
            
            // Data Science & Analytics
            "tensorflow.*?developer.*?certificate",
            "certified analytics professional",
            "tableau.*?certified",
            "databricks.*?certified",
            
            // General patterns
            "certified.*?\\w+.*?\\(\\d{4}\\)",
            "certificate.*?in.*?\\w+",
            "certification.*?\\-.*?\\w+.*?\\(\\d{4}\\)",
            "professional.*?certificate.*?\\-.*?\\w+"
        ]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let lowercaseLine = trimmedLine.lowercased()
            
            // Skip if line is too short or too long
            guard trimmedLine.count > 5 && trimmedLine.count < 200 else { continue }
            
            // Check for certification patterns
            for pattern in certificationPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(location: 0, length: lowercaseLine.utf16.count)
                    if regex.firstMatch(in: lowercaseLine, options: [], range: range) != nil {
                        certifications.append(trimmedLine)
                        break
                    }
                }
            }
            
            // Enhanced keyword-based detection
            let certificationKeywords = [
                "certified", "certificate", "certification", "professional", "associate",
                "expert", "specialist", "aws", "google cloud", "azure", "oracle",
                "microsoft", "adobe", "cisco", "comptia", "pmp", "scrum", "agile",
                "tensorflow", "tableau", "databricks", "salesforce"
            ]
            
            var hasKeyword = false
            var hasYear = false
            
            for keyword in certificationKeywords {
                if lowercaseLine.contains(keyword) {
                    hasKeyword = true
                    break
                }
            }
            
            // Check for year pattern (2019-2024)
            if let regex = try? NSRegularExpression(pattern: "\\b(20[1-2][0-9])\\b", options: []) {
                let range = NSRange(location: 0, length: lowercaseLine.utf16.count)
                if regex.firstMatch(in: lowercaseLine, options: [], range: range) != nil {
                    hasYear = true
                }
            }
            
            // If line has certification keyword and year, likely a certification
            if hasKeyword && hasYear && !certifications.contains(trimmedLine) {
                certifications.append(trimmedLine)
            }
        }
        
        return Array(Set(certifications)).sorted()
    }
    
    private func extractAchievements(from text: String) -> [String] {
        var achievements: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        let achievementIndicators = [
            "increased", "improved", "reduced", "achieved", "led", "won", "awarded",
            "recognized", "featured", "published", "speaker", "mentored", "generated",
            "saved", "optimized", "launched", "delivered"
        ]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let lowercaseLine = trimmedLine.lowercased()
            
            for indicator in achievementIndicators {
                if lowercaseLine.contains(indicator) && 
                   (trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*")) &&
                   trimmedLine.count < 200 {
                    
                    let achievement = trimmedLine.replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
                    if !achievement.isEmpty {
                        achievements.append(achievement)
                        break
                    }
                }
            }
        }
        
        return Array(Set(achievements)).sorted()
    }
}

// MARK: - Enhanced CV Analysis Model
@MainActor
class CVAnalysis: ObservableObject, Equatable, Sendable {
    @Published var technicalSkills: [String] = []
    @Published var softSkills: [String] = []
    @Published var workExperience: [String] = []
    @Published var yearsOfExperience: Int = 0
    @Published var education: [String] = []
    @Published var projects: [String] = []
    @Published var certifications: [String] = []
    @Published var achievements: [String] = []
    
    var summary: String {
        var summaryParts: [String] = []
        
        if yearsOfExperience > 0 {
            summaryParts.append("\(yearsOfExperience)+ years of experience")
        }
        
        if !technicalSkills.isEmpty {
            let topSkills = Array(technicalSkills.prefix(3))
            summaryParts.append("Skills: \(topSkills.joined(separator: ", "))")
        }
        
        if !workExperience.isEmpty {
            summaryParts.append("Role: \(workExperience.first ?? "")")
        }
        
        return summaryParts.joined(separator: " • ")
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: CVAnalysis, rhs: CVAnalysis) -> Bool {
        return lhs.technicalSkills == rhs.technicalSkills &&
               lhs.softSkills == rhs.softSkills &&
               lhs.workExperience == rhs.workExperience &&
               lhs.yearsOfExperience == rhs.yearsOfExperience &&
               lhs.education == rhs.education &&
               lhs.projects == rhs.projects &&
               lhs.certifications == rhs.certifications &&
               lhs.achievements == rhs.achievements
    }
}