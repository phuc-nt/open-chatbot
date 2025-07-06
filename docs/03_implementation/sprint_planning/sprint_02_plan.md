# Sprint 2 Plan - API Integration & Real-time Chat

**Thời gian**: 3 tuần (Week 3-5)  
**Mục tiêu**: Tích hợp API thật và implement real-time chat functionality  
**Milestone**: M2 - Working Chatbot with Real AI Models  
**Status**: **PLANNING** 🔄 (2025-01-06)

---

## 🎯 **Sprint Goals**

### **Mục tiêu chính**
1. **OpenRouter API Integration** - Multi-LLM support với secure authentication ✅
2. **API Key Management** - Secure storage trong iOS Keychain với UI ✅  
3. **Real-time Streaming** - WebSocket/SSE cho progressive responses ✅
4. **Message Persistence** - Kết nối UI với Core Data storage ✅
5. **File Upload Foundation** - PDF và image processing basics ✅

### **Success Criteria**
- [ ] User có thể add/edit API keys an toàn trong Settings
- [ ] Chat với real AI models từ OpenRouter (GPT-4, Claude, etc.)
- [ ] Streaming responses hiển thị real-time
- [ ] Messages được save/load từ Core Data
- [ ] Basic file upload (PDF/images) working
- [ ] Error handling và loading states professional

---

## 📋 **Task Breakdown**

### **Week 1: Core Infrastructure**

#### **Task 2.1: API Service Architecture** 
**Ước tính**: 8 giờ  
**Ưu tiên**: P0 (Critical)

**Checklist**:
- [ ] Tạo protocol `LLMAPIService` cho abstraction layer
- [ ] Implement `OpenRouterAPIService` concrete class
- [ ] Support multiple models: GPT-4, Claude-3, Llama-2
- [ ] Error handling và rate limiting
- [ ] Network monitoring và retry logic
- [ ] Unit tests cho API service layer

**Deliverables**:
- [ ] Working OpenRouter integration
- [ ] Model selection functionality
- [ ] Comprehensive error handling

#### **Task 2.2: Keychain Service Implementation**
**Ước tính**: 6 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: -

**Checklist**:
- [ ] Implement `KeychainService` với AES-256 encryption
- [ ] CRUD operations cho API keys:
  - Create: Add new API key với validation
  - Read: Retrieve keys cho authentication
  - Update: Edit existing keys
  - Delete: Secure removal với confirmation
- [ ] Biometric authentication option (Face ID/Touch ID)
- [ ] Key validation và connection testing
- [ ] Security best practices implementation

**Deliverables**:
- [ ] Secure API key storage working
- [ ] Biometric protection optional
- [ ] Connection validation system

#### **Task 2.3: API Key Management UI**
**Ước tính**: 6 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 2.2

**Checklist**:
- [ ] Enhance SettingsView với API key section:
  - List existing keys với provider icons
  - Add new key form với validation
  - Edit/delete existing keys
  - Test connection button
- [ ] Form validation và user feedback
- [ ] Loading states và error messages
- [ ] iOS design guidelines compliance
- [ ] Accessibility support (VoiceOver, Dynamic Type)

**Deliverables**:
- [ ] Complete API key management UI
- [ ] Professional error handling
- [ ] Accessibility compliant

---

## 📅 **Week 2: Real-time Features**

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