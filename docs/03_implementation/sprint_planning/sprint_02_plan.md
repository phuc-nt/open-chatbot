# Sprint 2 Plan - API Integration & Real-time Chat

**Thời gian**: 3 tuần (Week 3-5)  
**Mục tiêu**: Tích hợp API thật và implement real-time chat functionality  
**Milestone**: M2 - Working Chatbot with Real AI Models  
**Status**: **TASK 2.3 COMPLETED** ✅ (2025-01-06)

---

## 🎯 **Sprint Goals**

### **Mục tiêu chính**
1. **OpenRouter API Integration** - Multi-LLM support với secure authentication ✅
2. **API Key Management** - Secure storage trong iOS Keychain với UI ✅  
3. **Real-time Streaming** - WebSocket/SSE cho progressive responses 🔄
4. **Message Persistence** - Kết nối UI với Core Data storage 📋
5. **File Upload Foundation** - PDF và image processing basics 📋

### **Success Criteria**
- ✅ User có thể add/edit API keys an toàn trong Settings
- 🔄 Chat với real AI models từ OpenRouter (GPT-4, Claude, etc.)
- [ ] Streaming responses hiển thị real-time
- [ ] Messages được save/load từ Core Data
- [ ] Basic file upload (PDF/images) working
- [ ] Error handling và loading states professional

---

## 📋 **Task Breakdown**

### **Week 1: Core Infrastructure - COMPLETED ✅**

#### **Task 2.1: API Service Architecture** ✅ **COMPLETED**
**Ước tính**: 8 giờ / **Thực tế**: 4 giờ (**200% efficiency**)  
**Ưu tiên**: P0 (Critical)  
**Completed**: 2025-01-06

**Checklist**:
- ✅ Tạo protocol `LLMAPIService` cho abstraction layer
- ✅ Implement `OpenRouterAPIService` concrete class
- ✅ Support multiple models: GPT-4o, Claude-3.7 Sonnet, và others
- ✅ Error handling và comprehensive `LLMAPIError` types
- ✅ AsyncStream support cho streaming responses
- ✅ Server-Sent Events (SSE) parsing implementation

**Deliverables**:
- ✅ Working OpenRouter integration với 6 providers
- ✅ Model selection functionality với pricing info
- ✅ Comprehensive error handling với recovery suggestions

#### **Task 2.2: Keychain Service Implementation** ✅ **COMPLETED**
**Ước tính**: 6 giờ / **Thực tế**: Included in 2.1 (**Ahead of schedule**)  
**Ưu tiên**: P0 (Critical)  
**Completed**: 2025-01-06

**Checklist**:
- ✅ Implement `KeychainService` với AES-256 encryption
- ✅ CRUD operations cho API keys (Create, Read, Update, Delete)
- ✅ Biometric authentication option (Face ID/Touch ID)
- ✅ Key validation và connection testing methods
- ✅ Security best practices implementation
- ✅ Multi-provider key management

**Deliverables**:
- ✅ Secure API key storage working
- ✅ Biometric protection implemented
- ✅ Connection validation system functional

#### **Task 2.3: API Key Management UI** ✅ **COMPLETED**
**Ước tính**: 6 giờ / **Thực tế**: 6 giờ (**100% efficiency**)  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 2.2  
**Completed**: 2025-01-06

**Checklist**:
- ✅ Enhanced SettingsView với comprehensive API key management
- ✅ Professional UI components (APIKeyRow, AddAPIKeyView)
- ✅ Real-time validation với live status indicators
- ✅ Masked API key display (sk-••••••••abc123)
- ✅ Test connection functionality với detailed feedback
- ✅ iOS design guidelines compliance
- ✅ Accessibility support (VoiceOver, Dynamic Type)
- ✅ **Build Success**: SweetPad + Simulator running perfectly

**Deliverables**:
- ✅ Complete API key management UI
- ✅ Professional error handling và user feedback
- ✅ Multi-provider support (6 providers)
- ✅ Advanced security features restored

---

## 📅 **Week 2: Real-time Features - NEXT**

#### **Task 2.4: Streaming Response Implementation**
**Ước tính**: 10 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 2.1

**Checklist**:
- [ ] Research OpenRouter streaming API endpoints
- [ ] Implement WebSocket/SSE client:
  - URLSessionWebSocketTask cho iOS native
  - Progressive text parsing và display
  - Connection state management
  - Auto-reconnection logic
- [ ] Update ChatViewModel để handle streaming:
  - Real-time message updates
  - Typing indicators
  - Stop generation functionality
- [ ] UI animations cho smooth experience
- [ ] Memory management cho long conversations

**Deliverables**:
- [ ] Real-time streaming working
- [ ] Smooth UI animations
- [ ] Professional typing indicators

#### **Task 2.5: Chat Integration với Real API**
**Ước tính**: 8 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 2.1, Task 2.3, Task 2.4

**Checklist**:
- [ ] Connect ChatView với APIService:
  - Send messages to selected model
  - Handle API responses và errors
  - Display real AI responses
- [ ] Model selection trong chat interface:
  - Dropdown/picker cho available models
  - Model switching mid-conversation
  - Display current model trong UI
- [ ] Enhanced message handling:
  - Message states (sending, sent, failed)
  - Retry failed messages
  - Message metadata (model, timestamp, tokens)
- [ ] Cost tracking foundation:
  - Token counting per message
  - Basic cost calculation
  - Usage statistics display

**Deliverables**:
- [ ] Working chat với real AI
- [ ] Model selection functional
- [ ] Basic cost tracking

#### **Task 2.6: Message Persistence Integration**
**Ước tính**: 6 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 2.5

**Checklist**:
- [ ] Connect ChatViewModel với Core Data:
  - Save messages real-time
  - Load conversation history
  - Update message status
- [ ] Enhance HistoryViewModel:
  - Real conversation loading
  - Search functionality
  - Conversation management (rename, delete)
- [ ] Core Data optimizations:
  - Batch saving cho performance
  - Lazy loading for large conversations
  - Memory management
- [ ] Background sync preparation:
  - CloudKit integration hooks
  - Conflict resolution strategy

**Deliverables**:
- [ ] Messages persist correctly
- [ ] History loads từ database
- [ ] Search functionality working

---

## 🗂️ **Week 3: File Processing & Polish**

#### **Task 2.7: File Upload Foundation**
**Ước tính**: 8 giờ  
**Ưu tiên**: P1 (Important)  
**Dependencies**: Task 2.5

**Checklist**:
- [ ] File picker integration:
  - UIDocumentPickerViewController for PDFs
  - UIImagePickerController for photos
  - File size validation (max 50MB)
  - Supported formats: PDF, TXT, images
- [ ] Basic file processing:
  - PDF text extraction với PDFKit
  - Image OCR với Vision framework
  - Text preprocessing for API
- [ ] UI enhancements:
  - File attachment trong chat
  - File preview thumbnails
  - Upload progress indicators
- [ ] Error handling:
  - Unsupported formats
  - File size limits
  - Processing failures

**Deliverables**:
- [ ] File upload working
- [ ] PDF và OCR processing
- [ ] Professional upload UI

#### **Task 2.8: Performance & Polish**
**Ước tính**: 6 giờ  
**Ưu tiên**: P1 (Important)  
**Dependencies**: All previous tasks

**Checklist**:
- [ ] Performance optimizations:
  - Memory usage profiling
  - Core Data query optimization
  - UI rendering performance
  - Network request optimization
- [ ] Error handling improvements:
  - User-friendly error messages
  - Retry mechanisms
  - Offline handling
  - Network connectivity monitoring
- [ ] UI/UX polish:
  - Loading animations
  - Empty states
  - Pull-to-refresh
  - Haptic feedback
- [ ] Code quality:
  - SwiftLint compliance
  - Unit test coverage >85%
  - Documentation updates

**Deliverables**:
- [ ] Smooth performance
- [ ] Professional error handling
- [ ] Polished user experience

#### **Task 2.9: Documentation & Testing**
**Ước tính**: 4 giờ  
**Ưu tiên**: P2 (Nice to have)  
**Dependencies**: Task 2.8

**Checklist**:
- [ ] Update documentation:
  - API integration guide
  - User manual updates
  - Developer setup instructions
- [ ] Comprehensive testing:
  - API service tests
  - UI integration tests
  - Core Data tests update
  - Performance tests
- [ ] Sprint retrospective:
  - What went well
  - Improvements for Sprint 3
  - Updated velocity metrics

**Deliverables**:
- [ ] Complete documentation
- [ ] Test coverage >85%
- [ ] Sprint 2 retrospective

---

## 🔧 **Technical Specifications**

### **API Integration Architecture**
```swift
protocol LLMAPIService {
    func sendMessage(_ message: String, model: LLMModel) async throws -> AsyncStream<String>
    func getAvailableModels() async throws -> [LLMModel]
    func validateAPIKey(_ key: String) async throws -> Bool
}

class OpenRouterAPIService: LLMAPIService {
    private let baseURL = "https://openrouter.ai/api/v1"
    private let keychain: KeychainService
    // Implementation...
}
```

### **Streaming Response Flow**
1. User sends message
2. ChatViewModel calls APIService
3. WebSocket connection established
4. Progressive response chunks received
5. UI updates real-time
6. Final message saved to Core Data

### **Security Considerations**
- API keys never logged or transmitted unencrypted
- Keychain access protected by biometrics
- Network requests use SSL pinning
- Core Data encrypted at rest

---

## 🎯 **Definition of Done**

### **For Each Task**
- [ ] Code implemented và tested
- [ ] SwiftLint/SwiftFormat compliance
- [ ] Unit tests written với >80% coverage
- [ ] Documentation updated
- [ ] Manual testing completed
- [ ] Performance verified

### **For Sprint 2**
- [ ] All P0 tasks completed
- [ ] App builds và runs without errors
- [ ] Real chat với AI models working
- [ ] API keys managed securely
- [ ] Basic file upload functional
- [ ] User testing feedback positive

---

## 📊 **Risk Management**

### **High Risk Items**
1. **OpenRouter API complexity** - Mitigation: Start với simple calls, iterate
2. **WebSocket stability** - Mitigation: Implement robust reconnection logic
3. **Core Data concurrency** - Mitigation: Use proper queue management
4. **iOS Keychain quirks** - Mitigation: Extensive testing on device

### **Dependencies**
- OpenRouter API availability và stability
- iOS Simulator limitations for Keychain testing
- Network connectivity for real API testing

---

## 📚 **Lessons Learned - Week 1**

### **🔧 Build Error Resolution - Critical Learning**

#### **Problem: "Cannot find type 'StoredAPIKey' in scope"**
**Root Cause**: Files existed trên filesystem nhưng không được include trong Xcode project build target

**Build Evidence**:
```bash
# Files ĐƯỢC compile:
/OpenChatbot/App/ContentView.swift ✅
/OpenChatbot/Views/Settings/SettingsView.swift ✅  
/OpenChatbot/ViewModels/SettingsViewModel.swift ✅

# Files BỊ THIẾU từ build:
/OpenChatbot/Models/LLMModel.swift ❌
/OpenChatbot/Services/KeychainService/KeychainService.swift ❌  
/OpenChatbot/Services/APIService/OpenRouterAPIService.swift ❌
```

#### **Solution Process**:
1. **Initial Approach**: Simplified implementation để fix immediate build
   - Created basic SettingsView without advanced types
   - Temporary workaround để continue development
   
2. **Root Cause Analysis**: Discovered Xcode project.pbxproj missing file references
   - Files physically existed nhưng not in build target
   - Missing PBXBuildFile và PBXFileReference entries
   
3. **Proper Fix**: Updated project.pbxproj file với proper structure:
   ```xml
   // Added PBXBuildFile entries
   A1000300D000000001D0000 = {isa = PBXBuildFile; fileRef = A1000301D000000001D0000; };
   
   // Added PBXFileReference entries
   A1000301D000000001D0000 = {isa = PBXFileReference; path = "LLMModel.swift"; };
   
   // Created proper group structure
   Services/APIService/ và Services/KeychainService/
   
   // Added to PBXSourcesBuildPhase
   ```

#### **Technical Issues Resolved**:
1. **AsyncStream closure signature**: Fixed `@Sendable` annotation
2. **Optional data binding**: Fixed non-optional data from `session.data(for:)`
3. **parseErrorResponse parameter**: Changed từ `Data?` to `Data`
4. **Duplicate extensions**: Removed redundant KeychainService extension

#### **Key Insights**:
- **File System ≠ Xcode Project**: Files can exist but not be compiled
- **Build Output Analysis**: Critical for identifying missing files
- **Xcode Project File**: Understanding project.pbxproj structure essential
- **Incremental Fixes**: Sometimes temporary solutions needed để unblock development

### **🏗️ Architecture Decisions**

#### **Protocol-Oriented Design Success**
**Decision**: Use protocols for API abstraction (`LLMAPIService`)
**Benefit**: 
- Easy to add new providers (đã support 6 providers)
- Testable design với mock implementations
- Clear separation of concerns

#### **Security-First Approach**
**Decision**: iOS Keychain + Biometric authentication từ đầu
**Benefit**:
- Production-ready security
- User trust và confidence
- Apple guidelines compliance

#### **Modern Swift Patterns**
**Decision**: async/await throughout, MainActor for UI
**Benefit**:
- Clean concurrency code
- UI safety guaranteed
- Performance optimization built-in

### **🚀 Development Velocity Insights**

#### **High Efficiency Factors**:
1. **Clear Task Breakdown**: Detailed checklists prevented scope creep
2. **Protocol Design**: Enabled parallel development of components
3. **Mock Data Strategy**: UI development không blocked by API complexity
4. **Quality Tools**: SwiftLint/SwiftFormat caught issues early

#### **Process Improvements**:
1. **Build Validation**: Always verify files in Xcode project after adding
2. **Incremental Testing**: Test each component as it's built
3. **Documentation Sync**: Update docs immediately after implementation
4. **Error Analysis**: Build output analysis is critical skill

### **🎯 Week 2 Preparation**

#### **Technical Readiness**:
- ✅ API architecture solid và extensible
- ✅ Security foundation complete
- ✅ UI components professional và consistent
- ✅ Build process stable và reliable

#### **Next Focus Areas**:
1. **Streaming Implementation**: WebSocket/SSE complexity management
2. **Core Data Integration**: Concurrency và performance considerations
3. **Error Handling**: User-friendly messaging cho network issues
4. **Performance**: Memory management với long conversations

---

## 📈 **Success Metrics**

### **Technical Metrics**
- **API Response Time**: <2s for first token
- **Streaming Latency**: <200ms between chunks
- **App Launch Time**: <3s cold start
- **Memory Usage**: <100MB for typical conversations
- **Battery Impact**: Minimal background processing

### **User Experience Metrics**
- **API Key Setup**: <2 minutes for new user
- **Chat Response**: Immediate feedback với streaming
- **File Upload**: <5s for 10MB PDF processing
- **Error Recovery**: Clear messaging và retry options

---

## 🚀 **Next Sprint Preview**

**Sprint 3 Preview**: Advanced Features
- RAG system implementation
- Web search integration
- Advanced export formats
- Performance optimizations
- User onboarding flow

---

**📝 Sprint 2 kicked off! Let's build the core functionality!** 🚀

---
*Created: 2025-01-06*  
*Next update: End of Week 1* 