# OpenChatbot iOS

iOS SwiftUI application cho multi-LLM chatbot với OpenRouter integration.

## 🎯 **Project Overview**

> 📖 **Detailed documentation**: [Project Overview](../docs/00_context/project_overview.md)

**Architecture**: MVVM pattern với SwiftUI  
**Persistence**: Core Data + CloudKit sync  
**Development**: Cursor + SweetPad workflow  
**Target**: iOS 17.0+, Xcode 16.4+

## 🚀 **Quick Start**

### **Prerequisites**
- macOS 15.5+, Xcode 16.4+
- Cursor IDE với SweetPad extension
- SwiftLint và SwiftFormat: `brew install swiftlint swiftformat`

### **Build & Run**
```bash
# Using SweetPad in Cursor
# 1. Open project in Cursor
# 2. Cmd+Shift+P → "SweetPad: Run"
# 3. Select iPhone 16 simulator

# Or command line
cd ios
xcodebuild -scheme OpenChatbot -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 📁 **Project Structure**

```
ios/OpenChatbot/
├── App/                    # Entry point (OpenChatbotApp.swift, ContentView.swift)
├── Views/                  # SwiftUI views (Chat, History, Settings, Common)
├── ViewModels/             # MVVM business logic
├── Models/                 # Data models (Message, Conversation, APIKey)
├── Services/               # Core services (Data, Persistence)
├── Resources/              # Core Data models, assets
└── Tests/                  # Unit tests
```

## 🔧 **Development Workflow**

### **Code Quality**
```bash
# Run all quality checks
./scripts/format.sh

# Individual tools
./scripts/format.sh format  # SwiftFormat only
./scripts/format.sh lint    # SwiftLint only
./scripts/format.sh fix     # Auto-fix issues
```

### **Configuration Files**
- `.swiftlint.yml` - Linting rules
- `.swiftformat` - Code formatting
- `buildServer.json` - SweetPad configuration
- `.gitignore` - Git ignore patterns

## 📚 **Documentation**

> 📖 **Complete setup guide**: [iOS App Development Guide](../docs/00_guides/ios_app_development_guide.md)  
> 📖 **Development environment**: [Dev Environment Guide](../docs/02_development/dev_env_guide.md)  
> 📖 **Sprint progress**: [Sprint 1 Plan](../docs/03_implementation/sprint_planning/sprint_01_plan.md)

### **Key Features Implemented**
- ✅ MVVM architecture với SwiftUI
- ✅ Core Data persistence với CloudKit sync
- ✅ TabView navigation (Chat, History, Settings)
- ✅ Professional UI following iOS guidelines
- ✅ Comprehensive unit tests (15 tests)
- ✅ Code quality tools và standards

## 🧪 **Testing**

```bash
# Run unit tests
xcodebuild test -scheme OpenChatbot -destination 'platform=iOS Simulator,name=iPhone 16'

# Test coverage: Models 100%, ViewModels 80%+, Services 90%+
```

## 📊 **Project Status**

**Sprint 1: COMPLETED** ✅  
- **Time**: 16h / 42h estimated (62% under budget)
- **Quality**: All standards met
- **Architecture**: Production-ready MVVM foundation

**Ready for Sprint 2**: OpenRouter API integration, real-time chat, advanced features

---

**🚀 Production-ready iOS foundation với comprehensive testing và documentation!** 