# Project Context - iOS Chatbot

## 🎯 **What We're Building**
Open-source iOS chatbot app supporting multiple LLM API providers (OpenRouter, OpenAI, Claude, etc.)

**Target Users**: End-users who want a powerful AI chat app with their own API keys  
**Platform**: iOS Universal App (iPhone + iPad)  
**Distribution**: App Store + open source

## 🏗️ **Technical Stack**
- **Frontend**: SwiftUI + Combine
- **Data**: Core Data + CloudKit (for sync)
- **Security**: iOS Keychain (API keys)
- **Architecture**: MVVM + Clean Architecture
- **AI Integration**: REST APIs with streaming support

## 📋 **Core Features (MVP)**
1. **API Key Management** - Secure storage in Keychain
2. **Chat Interface** - SwiftUI with streaming responses  
3. **File Processing** - PDF upload + OCR for images
4. **Conversation Storage** - Core Data with search
5. **Export** - PDF/text export functionality
6. **Multi-provider** - OpenRouter (priority), OpenAI, Claude

> 📖 **Complete feature list**: [Feature Backlog](../01_preparation/feature_backlog.md)

## 🎯 **Key Decisions Made**
- **IDE**: Cursor (AI-first) + Xcode (when needed)
- **Primary API**: OpenRouter.ai (unified access to multiple models)
- **Architecture**: MVVM for testability and separation of concerns
- **Storage**: Local-first with optional iCloud sync

> 📖 **Full requirements**: [SRS Document](../01_preparation/srs_v1.md)

## 📅 **Timeline & Milestones**
- **Phase 1**: MVP (8 weeks) - Basic functional chatbot
- **Phase 2**: V2.0 (6 weeks) - Advanced features (RAG, web integration)
- **Phase 3**: V3.0 (4 weeks) - Enterprise features

> 📖 **Detailed timeline**: [Project Roadmap](../01_preparation/project_roadmap.md)

## 🚀 **Development Approach**
Following ["Trust the Process"](https://phucnt.substack.com/p/ai-coding-tu-vibe-coding-en-chuyen) methodology:
- **AI as Teammate**: Structured collaboration with AI
- **Process-centric**: Clear phases and documentation
- **Quality-first**: Testing, security, maintainability

> 📖 **Best practices learned**: [Best Practice Guide](../01_preparation/best_practice.md)

## 📊 **Success Metrics**
- **MVP**: Functional chat app by Week 8
- **Quality**: >80% test coverage, <5 bugs
- **Performance**: <2s app launch, smooth scrolling
- **User**: App Store approval, positive feedback

---
*For AI: This project uses SwiftUI, Core Data, and multiple LLM APIs. Focus on iOS best practices, security, and clean architecture.* 