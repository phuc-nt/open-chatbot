# OpenChatbot iOS

iOS SwiftUI application cho multi-LLM chatbot với OpenRouter integration.

## 🏗️ **Project Structure**

```
ios/OpenChatbot/
├── App/                     # App entry point và main configuration
│   ├── OpenChatbotApp.swift # Main app struct với @main
│   └── ContentView.swift    # Root view với TabView navigation
├── Views/                   # SwiftUI views theo feature
│   ├── Chat/               # Chat-related views
│   │   ├── ChatView.swift  # Main chat interface
│   │   └── HistoryView.swift # Conversation history
│   ├── Settings/           # Settings views
│   │   └── SettingsView.swift # App settings và API key management
│   └── Common/             # Reusable UI components
│       └── MessageBubbleView.swift # Message bubble component
├── ViewModels/             # MVVM ViewModels
│   ├── ChatViewModel.swift # Chat logic và state management
│   ├── HistoryViewModel.swift # History logic
│   └── SettingsViewModel.swift # Settings logic
├── Models/                 # Data models
│   ├── Message.swift       # Message model với MessageRole enum
│   ├── Conversation.swift  # Conversation model
│   └── APIKey.swift        # API key model với APIProvider enum
├── Services/               # Business logic services
│   ├── APIService/         # API communication
│   ├── DataService/        # Core Data operations
│   └── KeychainService/    # Secure API key storage
├── Resources/              # Assets, localizations, etc.
├── Utils/                  # Utility functions và extensions
└── Tests/                  # Unit tests
```

## 🎯 **Architecture: MVVM Pattern**

### **Views (SwiftUI)**
- Declarative UI components
- Bind to ViewModels via @StateObject/@ObservedObject
- Handle user interactions và navigation

### **ViewModels (ObservableObject)**
- Business logic và state management
- Communicate với Services
- Publish changes to Views via @Published

### **Models (Codable Structs)**
- Data structures
- Immutable when possible
- Conform to Identifiable, Codable

### **Services (Classes)**
- API communication (APIService)
- Data persistence (DataService)
- Security operations (KeychainService)

## 🚀 **Development Setup**

### **Prerequisites**
- macOS 15.5+
- Xcode 16.4+
- iOS 17.0+ deployment target
- Cursor IDE (primary development)
- SweetPad (for building/running)

### **Building & Running**
1. Open project trong Cursor IDE
2. Use SweetPad để build và run trên simulator
3. Hoặc dùng command line: `swift build` (nếu có Package.swift)

### **Key Features Implemented**
- ✅ TabView navigation (Chat, History, Settings)
- ✅ Basic chat interface với message bubbles
- ✅ Conversation history với search
- ✅ Settings screen với API key management
- ✅ Mock data cho UI testing
- ✅ MVVM architecture setup

### **Next Steps (Task 1.3)**
- [ ] Core Data integration
- [ ] PersistenceController setup
- [ ] Real data persistence
- [ ] API service implementation

## 📝 **Notes**
- Tất cả linter errors hiện tại là do missing dependencies (sẽ được resolve khi build toàn bộ project)
- Mock data được sử dụng để test UI components
- Project structure tuân theo iOS best practices
- Ready cho SweetPad integration 