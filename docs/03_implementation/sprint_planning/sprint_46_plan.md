# Sprint 4.6 Plan: Dual Chat Mode - Document Intelligence Enhancement

**Sprint Duration**: 2 weeks  
**Sprint Goal**: Implement dual chat modes for document interaction với intelligent context management  
**Business Value**: Enhanced user experience với flexible document chat options  
**Parent Epic**: Document Intelligence & Vector Operations  

## 🎯 **Sprint Objectives**

### **Primary Goal**: Dual Document Chat Modes
Enable users to choose between two distinct chat approaches when interacting with documents:
1. **RAG Mode** (existing): Search-based contextual information retrieval
2. **Full Context Mode** (new): Complete document content inclusion with intelligent limits

### **Success Criteria**
- ✅ Users can select between RAG và Full Context modes
- ✅ Full Context Mode respects intelligent token limits
- ✅ Clear UI indicators for document size và mode recommendations
- ✅ Seamless integration với existing document selection workflow
- ✅ Performance optimized for both modes

## 📋 **Feature Requirements**

### **FR-4.6.1: Chat Mode Selection UI**
**Description**: Users can choose chat mode when selecting documents for conversation

**Acceptance Criteria**:
- Toggle/selector UI in DocumentPickerView và DocumentDetailView
- Clear visual distinction between RAG và Full Context modes
- Mode preference persists during chat session
- Default mode based on document size và user history

### **FR-4.6.2: Full Context Mode Implementation**  
**Description**: Include complete document content in chat context với intelligent limits

**Acceptance Criteria**:
- Support full document content inclusion up to context thresholds
- Automatic fallback to RAG mode when document exceeds limits
- Performance optimization for large document processing
- Token usage transparency for users

### **FR-4.6.3: Context Size Management**
**Description**: Intelligent context length management với model-specific limits

**Acceptance Criteria**:
- Model-specific context thresholds (GPT-4: 120k chars, Claude: 180k chars, etc.)
- Visual indicators: Green/Yellow/Red for document size status
- Warning system for large documents
- Graceful degradation when approaching limits

### **FR-4.6.4: Enhanced Document Selection Experience**
**Description**: Improved document picker với context size awareness

**Acceptance Criteria**:
- Document size indicators in selection list
- Mode recommendations based on document characteristics
- Batch selection với combined size calculation
- Clear mode switching during document selection

## 🏗️ **Technical Architecture**

### **New Components**

#### **1. ChatModeSelector**
```swift
enum ChatMode: String, CaseIterable {
    case rag = "rag"
    case fullContext = "full_context"
    
    var displayName: String
    var description: String
    var icon: String
}

struct ChatModeSelector: View {
    @Binding var selectedMode: ChatMode
    let documentSize: Int
    let recommendedMode: ChatMode
}
```

#### **2. DocumentContextManager**
```swift
class DocumentContextManager: ObservableObject {
    func calculateContextSize(for documents: [ProcessedDocument]) -> Int
    func getRecommendedMode(for documents: [ProcessedDocument], model: LLMModel) -> ChatMode
    func canUseFullContext(for documents: [ProcessedDocument], model: LLMModel) -> Bool
    func getContextSizeStatus(for documents: [ProcessedDocument]) -> ContextSizeStatus
}
```

#### **3. ContextSizeCalculator**
```swift
struct ContextThresholds {
    static let gpt4: Int = 120_000  // characters
    static let claude: Int = 180_000
    static let llama: Int = 60_000
    static let defaultLimit: Int = 80_000
}

enum ContextSizeStatus {
    case optimal    // < 50% threshold - Green
    case large      // 50-80% threshold - Yellow  
    case excessive  // > 80% threshold - Red
}
```

### **Enhanced Existing Components**

#### **ChatViewModel Extensions**
- Add `chatMode` property
- Implement `processFullContextMessage()`
- Enhanced `addDocumentToContext()` với mode awareness
- Context size monitoring và warnings

#### **DocumentPickerView Enhancements**
- Add context size indicators
- Integrate ChatModeSelector
- Show recommended modes per document
- Batch selection với combined size calculation

#### **DocumentDetailView Updates**
- Add mode selector trong Actions section
- Show document context size status
- Mode-specific action buttons

## 📅 **Sprint Breakdown**

### **Week 1: Core Implementation**

#### **Task 4.6.1: Context Size Calculator & Thresholds (8h)** ✅ **COMPLETED**
- ✅ Implement ContextSizeCalculator với model-specific limits 
- ✅ Create ContextThresholds configuration
- ✅ Add character counting utilities
- ✅ Unit tests for size calculations (21/21 tests passed)

**Implementation Status**: ✅ **PRODUCTION READY**
- **Files Created**: `ContextSizeCalculator.swift`, `ContextSizeCalculatorTests.swift`
- **Test Coverage**: 100% (21 comprehensive test cases)
- **Performance**: <100ms calculation time, 2.1s for 100 iterations
- **Features**: Model-specific thresholds, visual indicators, smart character counting

#### **Task 4.6.2: DocumentContextManager Service (12h)**
- Create DocumentContextManager class
- Implement context size analysis methods
- Add mode recommendation logic
- Integration với existing ChatViewModel

#### **Task 4.6.3: ChatModeSelector UI Component (8h)**
- Design và implement ChatModeSelector view
- Add visual indicators for mode selection
- Implement mode switching animations
- Responsive design for different screen sizes

### **Week 2: Integration & Polish**

#### **Task 4.6.4: Enhanced DocumentPickerView (10h)**
- Add context size indicators to document list
- Integrate ChatModeSelector
- Implement batch selection với size calculation
- Visual improvements và performance optimization

#### **Task 4.6.5: Full Context Mode in ChatViewModel (12h)**
- Implement `processFullContextMessage()` method
- Enhanced document context building
- Mode-aware message processing
- Error handling và fallback mechanisms

#### **Task 4.6.6: DocumentDetailView Integration (6h)**
- Add mode selector to Actions section
- Show context size status
- Update Chat button behavior
- UI polish và accessibility improvements

#### **Task 4.6.7: Testing & Documentation (8h)**
- Comprehensive unit tests
- Integration testing với different document sizes
- Update documentation
- Performance testing với large documents

## 🎨 **UI/UX Design Specifications**

### **ChatModeSelector Component**
```
┌─────────────────────────────────────┐
│ 📄 Chat Mode Selection             │
├─────────────────────────────────────┤
│ ○ RAG Mode (Recommended)            │
│   Search relevant information       │
│                                     │
│ ● Full Context                      │
│   Include complete document         │
│   ⚠️ Large document - may be slower  │
└─────────────────────────────────────┘
```

### **Document Size Indicators**
- 🟢 **Optimal**: < 20k chars - "Perfect for Full Context"
- 🟡 **Large**: 20k-60k chars - "Consider RAG for speed"
- 🔴 **Excessive**: > 80k chars - "RAG Mode recommended"

### **Enhanced DocumentPickerView**
```
┌─────────────────────────────────────┐
│ Select Documents for Chat           │
├─────────────────────────────────────┤
│ ✓ Report.pdf        🟢 15k chars    │
│ ✓ Manual.pdf        🟡 45k chars    │
│   Presentation.pdf  🔴 120k chars   │
├─────────────────────────────────────┤
│ Combined: 60k chars 🟡              │
│                                     │
│ 📄 Chat Mode:                       │
│ ○ RAG Mode    ● Full Context        │
└─────────────────────────────────────┘
```

## 🧪 **Testing Strategy**

### **Unit Tests**
- ContextSizeCalculator accuracy
- DocumentContextManager logic
- ChatModeSelector component behavior
- Context threshold validations

### **Integration Tests**
- Full Context mode với different document sizes
- Mode switching during active conversations
- Performance với large documents
- Error handling và fallback scenarios

### **User Acceptance Tests**
- **UAT-4.6.1**: Mode selection workflow
- **UAT-4.6.2**: Full Context chat functionality  
- **UAT-4.6.3**: Context size warnings và recommendations
- **UAT-4.6.4**: Performance với mixed document sizes

## 📊 **Performance Targets**

### **Response Times**
- Mode selection: < 100ms
- Context size calculation: < 200ms
- Full Context message processing: < 3s (vs < 1s for RAG)
- Document size analysis: < 50ms per document

### **Memory Usage**
- Full Context mode: < 50MB additional memory
- Context size caching for performance
- Efficient document content loading

### **Token Efficiency**
- Full Context mode: Transparent token usage display
- Automatic truncation when approaching model limits
- Smart content prioritization for large documents

## 🚀 **Success Metrics**

### **User Experience**
- Mode selection completion rate: > 95%
- User satisfaction với dual modes: > 4.5/5
- Task completion time improvement: > 20%

### **Technical Performance**  
- Full Context mode success rate: > 90%
- Context size calculation accuracy: > 99%
- Performance degradation: < 10% for Full Context

### **Business Impact**
- Document interaction frequency: + 30%
- User session duration: + 25%
- Feature adoption rate: > 70% within first month

## 🔄 **Future Enhancements**

### **Phase 2 Considerations**
- **Smart Context Compression**: Intelligent document summarization
- **Hybrid Mode**: Combine RAG với selective full context
- **Context Streaming**: Progressive context loading for huge documents
- **Multi-Document Full Context**: Advanced context management for multiple files

### **Advanced Features**
- **Context Bookmarking**: Save optimal context configurations
- **AI-Powered Mode Selection**: ML-based mode recommendations
- **Custom Thresholds**: User-configurable context limits
- **Context Analytics**: Usage patterns và optimization insights

## 📋 **Definition of Done**

- [ ] All acceptance criteria met for FR-4.6.1 through FR-4.6.4
- [ ] Unit test coverage > 85% for new components
- [ ] Integration tests pass for all scenarios
- [ ] Performance targets achieved
- [ ] UI/UX approved by stakeholders
- [ ] Documentation updated
- [ ] Code review completed
- [ ] User acceptance testing passed
- [ ] Feature toggle implemented for safe rollout

---

**Sprint 4.6 represents a significant enhancement to our Document Intelligence system, providing users với flexible và intelligent ways to interact với their documents while maintaining optimal performance và user experience.**