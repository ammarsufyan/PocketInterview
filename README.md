# 🎯 InterviewSim

**Master Your Interview Skills with AI-Powered Mock Interviews**

InterviewSim is a cutting-edge iOS application designed to help job seekers practice and perfect their interview skills through personalized mock interviews. Built with SwiftUI and powered by intelligent CV analysis, it provides tailored questions for both technical and behavioral interviews.

## ✨ Features

### 🎤 **Mock Interview Types**
- **Technical Interviews**: Practice coding challenges, system design, and technical problem-solving
- **Behavioral Interviews**: Master the STAR method with experience-based questions

### 📄 **Smart CV Analysis**
- Upload your CV/Resume in PDF, DOC, or DOCX format
- AI-powered analysis creates personalized questions based on your background
- Technical questions tailored to your skills and experience
- Behavioral questions based on your work history and achievements

### 📊 **Performance Tracking**
- Comprehensive interview history with detailed analytics
- Score tracking and performance metrics
- Filter sessions by interview type
- Search through past sessions

### 🎨 **Modern UI/UX**
- Beautiful, intuitive interface built with SwiftUI
- Smooth animations and micro-interactions
- Dark/Light mode support
- Responsive design for all iOS devices

## 🚀 Getting Started

### Prerequisites
- iOS 18.5 or later
- Xcode 16.4 or later
- Swift 5.0

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/InterviewSim.git
   cd InterviewSim
   ```

2. **Open in Xcode**
   ```bash
   open InterviewSim.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## 📱 App Structure

### Core Views
- **SplashScreenView**: Animated app launch screen with branding
- **ContentView**: Main tab-based navigation container
- **MockInterviewView**: Interview setup and configuration
- **HistoryView**: Performance tracking and session history

### Components
- **BoltBadgeView**: Reusable "Built by bolt.new" badge component
- **CategoryCard**: Interview type selection cards
- **CVUploadCard**: CV upload interface
- **HistorySessionCard**: Individual session display cards

## 🏗️ Architecture

### Design Patterns
- **MVVM Architecture**: Clean separation of concerns
- **SwiftUI Declarative UI**: Modern, reactive user interface
- **Component-Based Design**: Reusable UI components
- **Single Responsibility Principle**: Each view has a focused purpose

### File Organization
```
InterviewSim/
├── InterviewSimApp.swift          # App entry point
├── ContentView.swift              # Main tab container
├── Views/
│   ├── SplashScreenView.swift     # Launch screen
│   ├── MockInterviewView.swift    # Interview setup
│   ├── HistoryView.swift          # Performance tracking
│   └── Components/
│       └── BoltBadgeView.swift    # Reusable badge component
└── Assets.xcassets/               # App assets and images
```

## 🎨 Design System

### Color Palette
- **Primary Blue**: Technical interview theme
- **Primary Purple**: Behavioral interview theme
- **Success Green**: Completed actions and high scores
- **Warning Orange**: Medium performance scores
- **Error Red**: Low performance scores

### Typography
- **System Font**: SF Pro (iOS default)
- **Design**: Rounded for friendly, approachable feel
- **Weights**: Regular, Medium, Semibold, Bold

### Spacing System
- **Base Unit**: 8px grid system
- **Consistent Padding**: 16px, 20px, 32px
- **Component Spacing**: 12px, 16px, 20px, 32px

## 🔧 Technical Features

### Performance Optimizations
- **Lazy Loading**: Efficient list rendering with LazyVStack
- **Animation Performance**: Optimized spring animations
- **Memory Management**: Proper state management with @State and @StateObject

### Accessibility
- **VoiceOver Support**: Semantic labels and hints
- **Dynamic Type**: Scalable text for accessibility
- **High Contrast**: Sufficient color contrast ratios
- **Keyboard Navigation**: Full keyboard accessibility

### Data Persistence
- **UserDefaults**: App preferences and settings
- **File System**: CV document storage
- **Core Data Ready**: Prepared for local database integration

## 📊 Analytics & Tracking

### Session Metrics
- **Interview Duration**: Time spent in each session
- **Questions Answered**: Number of questions completed
- **Performance Score**: AI-calculated performance rating
- **Category Breakdown**: Technical vs Behavioral performance

### Historical Data
- **Session History**: Complete record of all interviews
- **Performance Trends**: Score progression over time
- **Category Analysis**: Strengths and improvement areas

## 🛠️ Development

### Code Quality
- **SwiftLint**: Code style enforcement
- **Clean Architecture**: Separation of concerns
- **SOLID Principles**: Maintainable, extensible code
- **Documentation**: Comprehensive inline documentation

### Testing Strategy
- **Unit Tests**: Core business logic testing
- **UI Tests**: User interaction flow testing
- **Performance Tests**: Memory and CPU usage monitoring

## 🚀 Future Enhancements

### Planned Features
- [ ] **Real-time Speech Analysis**: Voice recognition and feedback
- [ ] **Video Recording**: Practice with video playback
- [ ] **AI Interviewer**: Interactive AI-powered interviewer
- [ ] **Company-Specific Prep**: Questions tailored to specific companies
- [ ] **Collaborative Features**: Share sessions with mentors
- [ ] **Advanced Analytics**: Detailed performance insights
- [ ] **Cloud Sync**: Cross-device session synchronization

### Technical Roadmap
- [ ] **Core Data Integration**: Robust local data persistence
- [ ] **CloudKit Sync**: iCloud data synchronization
- [ ] **Machine Learning**: On-device speech analysis
- [ ] **Widget Support**: Home screen interview reminders
- [ ] **Apple Watch**: Quick session stats and reminders

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Development Guidelines
- Follow Swift style guidelines
- Write comprehensive tests
- Update documentation
- Ensure accessibility compliance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **SwiftUI Community**: For excellent resources and examples
- **Apple Developer Documentation**: Comprehensive iOS development guides
- **Design Inspiration**: Modern iOS app design patterns

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/InterviewSim/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/InterviewSim/discussions)
- **Email**: support@interviewsim.app

---

<div align="center">

### Built with ❤️ using SwiftUI

[![Built by bolt.new](https://img.shields.io/badge/Built%20by-bolt.new-000000?style=flat-square&logo=bolt&logoColor=white)](https://bolt.new)

**InterviewSim** - *Master Your Interview Skills*

</div>