# 🤖 Digital Doppelgänger - AI-Powered Personal Assistant

> **✨ STABLE VERSION**  
> A sophisticated Flutter application that serves as an intelligent personal assistant with advanced AI capabilities, voice interaction, and comprehensive fact management. Built with modern Flutter architecture and integrated with Google's cutting-edge Gemini AI technologies.

## 🌟 What This App Does

Digital Doppelgänger is a comprehensive personal AI assistant that combines multiple advanced technologies to create a truly intelligent companion. The app learns from user interactions, stores personal facts and knowledge, and provides contextual assistance through both text and voice interfaces.

### 🧠 Core Philosophy
This application bridges the gap between traditional note-taking apps and modern AI assistants by creating a persistent, searchable knowledge base that grows with the user. Unlike generic AI assistants, Digital Doppelgänger becomes increasingly personalized and context-aware over time.

## 🎯 Key Features

### 🗣️ **Advanced Voice Interaction**
- **Gemini 2.5 Flash Preview TTS**: Premium voice synthesis using Google's latest AI model
- **Intelligent Speech Recognition**: Natural language processing with context awareness
- **Voice-to-Fact Processing**: Speak facts naturally and have them automatically categorized
- **Multi-Layer Fallback System**: Gemini TTS → Device TTS for reliability
- **Smart Timeout Protection**: Auto-stop mechanisms to prevent stuck states

### 🧠 **Intelligent Fact Management**
- **Categorized Knowledge Storage**: Organize facts into Personal, Professional, Health, Learning, Goals, and Ideas
- **Smart Search & Filtering**: Advanced search capabilities with real-time filtering
- **Importance Ranking**: Prioritize facts with importance levels (Low, Medium, High, Critical)
- **Voice Integration**: Add facts via voice commands with automatic AI categorization
- **Rich Metadata**: Automatic timestamps, category assignment, and relationship tracking

### 💬 **AI-Powered Chat**
- **Context-Aware Responses**: Chat responses informed by stored facts and user history
- **Fact-Integrated Intelligence**: AI references your personal knowledge base in conversations
- **Natural Language Processing**: Understands intent and provides relevant information
- **Real-time Processing**: Instant responses with visual feedback

### 📊 **Analytics & Insights**
- **Usage Pattern Analysis**: Track interaction frequencies and trends
- **Knowledge Growth Metrics**: Monitor fact database expansion over time
- **Learning Progress Tracking**: Visualize educational and personal development
- **Engagement Statistics**: Detailed analytics on app usage patterns

### 🎨 **Modern User Experience**
- **Dark Theme Design**: Elegant dark mode with gradient accents and glassmorphism
- **Smooth Animations**: Fluid transitions using animate_do package
- **Responsive Layout**: Optimized for various screen sizes and orientations
- **Intuitive Navigation**: Clean, modern navigation with quick action cards

## 🛠️ Technical Architecture

### Core Technologies
- **Framework**: Flutter 3.x with Dart
- **AI Integration**: Google Generative AI (Gemini 2.5 Flash models)
- **Voice Technology**: 
  - Speech Recognition: speech_to_text package
  - Text-to-Speech: Gemini 2.5 Flash Preview TTS + flutter_tts fallback
  - Audio Playback: audioplayers package
- **Database**: SQLite with sqflite for local storage
- **State Management**: Native Flutter StatefulWidget patterns
- **UI Animations**: animate_do package for smooth transitions

### Architecture Patterns
- **Service Layer Architecture**: Separated business logic with dedicated service classes
- **Repository Pattern**: Database operations abstracted through helper classes
- **Factory Pattern**: AI service instantiation and configuration
- **Graceful Fallback Systems**: Multiple backup mechanisms for reliability

### Key Dependencies
```yaml
dependencies:
  flutter: sdk
  google_generative_ai: ^0.4.0
  speech_to_text: ^7.0.0
  flutter_tts: ^3.8.5
  audioplayers: ^6.0.0
  sqflite: ^2.3.3
  location: ^6.0.2
  shared_preferences: ^2.2.3
  animate_do: ^3.3.4
  flutter_dotenv: ^5.1.0
  path_provider: ^2.1.1
```

## 🚀 Quick Start Guide

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK (included with Flutter)
- Android Studio or VS Code with Flutter extensions
- Physical device recommended for voice features

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd doppelganger_flutter
   ```

2. **Create `.env` file in project root:**
   ```bash
   # Copy the template and fill in your keys
   cp .env.template .env
   ```
   
   Or create manually:
   ```env
   # Gemini AI API Key (for chat functionality and TTS)
   GEMINI_API_KEY=your_gemini_api_key_here
   
   # Weather API Key (for location-based weather integration)
   WEATHER_API_KEY=your_openweather_api_key_here
   
   # Firebase API Key (for future web features - moved from web/index.html)
   FIREBASE_API_KEY=your_firebase_api_key_here
   ```

3. **Install dependencies and run:**
   ```bash
   flutter pub get
   flutter run
   ```

### API Keys Required
- **Google Gemini API**: For AI chat functionality and TTS (Required)
- **OpenWeather API**: For location-based weather integration (Optional)
- **Firebase API**: For future web features (Optional - moved from hardcoded)

### Getting API Keys
1. **Gemini API**: Visit [Google AI Studio](https://makersuite.google.com/app/apikey) to get your free API key
2. **Weather API**: Visit [OpenWeatherMap](https://openweathermap.org/api) for free weather API access

## 📱 User Experience Flow

### First Launch
1. **Onboarding**: Simple setup with location-based weather integration
2. **Name Setup**: Personalize your AI assistant with your name
3. **Permission Requests**: Voice and location permissions for full functionality

### Daily Usage
1. **Voice Interaction**: Tap the microphone to start voice conversations
2. **Fact Recording**: Say "Remember that..." or "Add fact..." to store information
3. **Knowledge Building**: Add facts through voice or forms with auto-categorization
4. **AI Conversations**: Chat with AI that knows your personal facts
5. **Analytics Review**: Track personal growth through detailed insights

## 🔧 Advanced Configuration

### Voice Settings
- **TTS Quality**: Automatically uses Gemini TTS for premium quality
- **Speech Recognition**: Optimized for natural conversation patterns
- **Timeout Protection**: Configurable timeouts to prevent stuck states

### Fact Management
- **Auto-Categorization**: AI suggests categories based on content
- **Bulk Operations**: Import/export facts for backup and sharing
- **Search Optimization**: Full-text search across all stored information

### Privacy & Security
- **Local-First Storage**: Primary data storage on device using SQLite
- **API Key Security**: All API keys moved to .env file (not committed to version control)
- **User-Controlled Data**: Complete control over data export and deletion
- **Transparent Permissions**: Clear communication about required permissions
- **Template Configuration**: .env.template provided for easy setup

## 🐛 Troubleshooting

### Common Issues

#### Build Issues
If you encounter Android build issues:
```bash
flutter clean
flutter pub get
flutter run
```

#### Voice Recognition Stuck
- The app includes automatic timeout protection (30 seconds)
- Tap the stop button if recognition seems stuck
- Check microphone permissions in device settings

#### TTS Not Working
- Ensure GEMINI_API_KEY is set in .env file
- App automatically falls back to device TTS if Gemini unavailable
- Check internet connection for Gemini TTS

#### Facts Not Saving
- Check storage permissions
- Ensure database is initialized (happens automatically)
- Verify voice recognition is working properly

## 🎯 Recently Fixed Issues

### ✅ All Major Issues Resolved
- **Voice Mode Stuck**: Added timeout protection and proper state management
- **Fact Recording**: Enhanced voice-to-fact processing with better error handling
- **UI Overflow**: Removed Quick Chat section that was causing layout issues
- **Hero Tag Conflicts**: Fixed multiple FloatingActionButton conflicts
- **Code Quality**: All Dart analysis errors resolved, deprecated calls updated

### ✅ Enhanced Features
- **User Name Integration**: Dynamic user name updates across all pages
- **Drawer Improvements**: Beautiful avatar with user initials
- **Error Handling**: Comprehensive error handling with user feedback
- **Performance**: Optimized database operations and AI calls

## 🚀 Future Roadmap

### Phase 1: Intelligence Enhancement
- **Cross-Session Memory**: Persistent conversation context
- **Smart Notifications**: Context-aware reminders based on facts
- **Advanced Search**: Natural language search across all data
- **Conversation Analytics**: Track discussion patterns and topics

### Phase 2: Expanded Capabilities
- **Multi-Language Support**: International language support
- **Calendar Integration**: Smart scheduling with preference learning
- **Widget System**: Home screen widgets for quick access
- **Cloud Sync**: Optional cloud synchronization with encryption

### Phase 3: Advanced Features
- **AI Vision**: Image analysis and OCR for visual fact extraction
- **Collaborative Features**: Shared knowledge bases
- **Advanced Analytics**: ML-powered insights and predictions
- **API Development**: RESTful API for integrations

## 🤝 Contributing

This project demonstrates modern Flutter development practices and AI integration patterns. The codebase serves as an excellent reference for:
- AI service integration in mobile applications
- Voice technology implementation with fallback systems
- Local database management with SQLite
- Modern UI/UX patterns in Flutter
- Service-oriented architecture in mobile apps

### Code Standards
- Follow Flutter/Dart style guidelines
- Maintain comprehensive error handling
- Document complex business logic
- Ensure null safety compliance
- Write self-documenting code

## 📄 License

This project is available as open source for educational and development purposes. See individual service provider terms for API usage limitations and requirements.

---

**Digital Doppelgänger** represents the convergence of AI, voice technology, and personal knowledge management in a mobile application. It demonstrates how modern Flutter applications can integrate multiple cutting-edge technologies to create genuinely intelligent and useful personal assistants.

*Built with Flutter 💙 • Powered by Google AI 🤖 • Enhanced with Voice Technology 🎙️*
