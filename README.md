# PocketInterview 🎯

**Master Your Interview Skills with AI-Powered Practice**

PocketInterview is an innovative iOS application that helps job seekers practice and improve their interview skills through realistic AI-powered mock interviews. Built with SwiftUI and powered by advanced AI technology, it provides personalized interview experiences tailored to your background and career goals.

## 🌟 Features

### 🤖 AI-Powered Interviews
- **Two Specialized AI Interviewers:**
  - **Steve** - Technical Interview Expert
  - **Lucy** - Behavioral Interview Specialist
- Real-time conversation with advanced AI personas
- Natural, human-like interview interactions

### 📄 CV-Based Personalization
- Upload your CV (PDF, DOC, DOCX supported)
- AI analyzes your background, skills, and experience
- Generates personalized questions based on your profile
- Supports multiple file formats up to 10MB

### 📊 Comprehensive Analytics
- **AI-Generated Scoring System:**
  - **Clarity Score** (30% weight) - Communication effectiveness
  - **Grammar Score** (20% weight) - Language proficiency
  - **Substance Score** (50% weight) - Content quality and depth
- Detailed feedback and improvement suggestions
- Progress tracking across multiple sessions

### 📝 Complete Session Management
- **Interview History** - Track all your practice sessions
- **Full Transcripts** - Review every question and answer
- **Session Details** - Duration, scores, and performance metrics
- **Search & Filter** - Find specific sessions or topics

### 🔒 Secure & Private
- **Supabase Authentication** - Secure user accounts
- **Row-Level Security** - Your data stays private
- **GDPR Compliant** - Full control over your data
- **Account Management** - Easy profile and password management

## 🛠 Technology Stack

### Frontend (iOS)
- **SwiftUI** - Modern, declarative UI framework
- **iOS 18.0+** - Latest iOS features and capabilities
- **Combine** - Reactive programming for data flow
- **WebKit** - Embedded web views for AI interviews

### Backend & Services
- **Supabase** - Backend-as-a-Service platform
  - PostgreSQL database with real-time capabilities
  - Authentication and user management
  - Row-Level Security (RLS) policies
- **Tavus AI** - Advanced AI video conversation platform
- **OpenRouter** - LLM-powered scoring and analysis

### AI & Machine Learning
- **Tavus Personas** - Specialized AI interviewers
- **OpenRouter LLM** - Intelligent scoring and feedback
- **CV Analysis** - Automated resume parsing and analysis

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0 or later
- iOS 18.0+ device or simulator
- Apple Developer Account (for device testing)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/pocketinterview.git
   cd pocketinterview
   ```

2. **Open in Xcode:**
   ```bash
   open PocketInterview.xcodeproj
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   TAVUS_API_KEY=your_tavus_api_key
   TAVUS_BASE_URL=https://tavusapi.com/v2
   OPENROUTER_API_KEY=your_openrouter_api_key
   ```

4. **Install Dependencies:**
   Dependencies are managed through Swift Package Manager and will be automatically resolved when you build the project.

5. **Build and Run:**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Database Setup

The application uses Supabase with the following main tables:
- `profiles` - User profile information
- `interview_sessions` - Interview session records
- `interview_transcripts` - Full conversation transcripts
- `score_details` - AI-generated scoring breakdown

Database migrations are located in `supabase/migrations/` and will be automatically applied.

## 📱 App Architecture

### MVVM Pattern
```
Views/
├── Authentication/     # Login, signup, password reset
├── Profile/           # User profile and settings
├── MockInterviewView  # Main interview interface
├── HistoryView        # Session history and analytics
└── TavusInterviewView # Live AI interview interface

Models/
├── InterviewSession   # Session data model
├── InterviewTranscript # Conversation transcripts
├── ScoreDetails       # AI scoring breakdown
└── CVExtractor        # CV analysis and parsing

Services/
├── AuthenticationManager    # User authentication
├── InterviewHistoryManager  # Session management
├── TavusService            # AI interview integration
├── TranscriptManager       # Transcript handling
└── ScoreDetailsManager     # Scoring analytics
```

### Key Components

- **AuthenticationManager** - Handles user login, signup, and session management
- **TavusService** - Manages AI interview sessions and real-time communication
- **CVExtractor** - Processes and analyzes uploaded CV documents
- **InterviewHistoryManager** - Tracks and manages interview session data

## 🔧 Configuration

### Supabase Setup
1. Create a new Supabase project
2. Run the provided migrations in `supabase/migrations/`
3. Configure authentication settings
4. Set up Row-Level Security policies

### Tavus Integration
1. Sign up for Tavus API access
2. Create AI personas for technical and behavioral interviews
3. Configure webhook endpoints for transcript processing

### OpenRouter Setup
1. Get API access for LLM scoring
2. Configure the scoring webhook function
3. Set up environment variables

## 📊 Features in Detail

### Interview Types
- **Technical Interviews** - Coding challenges, system design, technical concepts
- **Behavioral Interviews** - STAR method, leadership scenarios, soft skills

### CV Analysis
- Automatic text extraction from PDF/DOC files
- Skills identification and categorization
- Experience level assessment
- Personalized question generation

### Scoring System
- **Weighted Scoring Algorithm:**
  - Substance (50%) - Content quality and technical accuracy
  - Clarity (30%) - Communication effectiveness
  - Grammar (20%) - Language proficiency
- Real-time feedback and improvement suggestions

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Write comprehensive unit tests
- Document public APIs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Tavus** - AI video conversation platform
- **Supabase** - Backend infrastructure and authentication
- **OpenRouter** - LLM integration for intelligent scoring
- **Bolt.new** - Development platform and tools

## 📞 Support

- **Email:** ammarsfyn@gmail.com
- **Documentation:** [Wiki](https://github.com/yourusername/pocketinterview/wiki)
- **Issues:** [GitHub Issues](https://github.com/yourusername/pocketinterview/issues)

## 🗺 Roadmap

### Version 1.1
- [ ] Video recording of practice sessions
- [ ] Advanced analytics dashboard
- [ ] Custom interview question sets
- [ ] Team collaboration features

### Version 1.2
- [ ] Multi-language support
- [ ] Industry-specific interview templates
- [ ] Integration with job boards
- [ ] AI-powered interview tips

---

**Built with ❤️ using Swift, SwiftUI, and cutting-edge AI technology.**

*PocketInterview - Your personal interview coach, available anytime, anywhere.*