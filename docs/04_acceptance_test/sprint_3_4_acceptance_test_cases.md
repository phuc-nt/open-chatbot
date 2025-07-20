# 📋 **Acceptance Test Cases - Sprint 3 & 4**
*Real Device Testing Guide cho Production Readiness*

**Scope**: Smart Memory System (Sprint 3) + Document Intelligence (Sprint 4-4.5)  
**Environment**: iPhone/iPad running iOS 17+  
**Testing Type**: End-to-end user scenarios on actual devices  
**Duration**: Each test case ~5-15 minutes  

---

## 🧠 **Sprint 3: Smart Memory System - Acceptance Tests**

### **AT-3.1: Conversation Memory Persistence**
**Purpose**: Verify AI remembers conversation context across app sessions  
**Technology**: Core Data + Custom memory algorithms  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **Setup**: Fresh app install on iPhone
2. **Start Conversation**:
   - Open app, ensure clean state
   - Send message: "Hi, I'm working on a machine learning project about image classification"
   - Verify AI responds acknowledging ML topic
3. **Continue Discussion**:
   - Send 3-4 more messages about ML specifics
   - Verify AI maintains context in responses
4. **Force App Restart**:
   - Close app completely (swipe up from home indicator)
   - Wait 30 seconds
   - Reopen app
5. **Test Memory Recall**:
   - Send message: "What were we discussing before?"
   - **Expected**: AI recalls machine learning and image classification topic

#### **Expected Results:**
- ✅ AI remembers previous conversation topic
- ✅ Response shows context understanding
- ✅ No memory loss after app restart
- ✅ Context relevance maintained

#### **Failure Criteria:**
- ❌ AI says "I don't recall previous conversation"
- ❌ App crashes during memory retrieval
- ❌ Response time >5 seconds

---

### **AT-3.2: Long Conversation Summarization**
**Purpose**: Verify AI handles long conversations without memory overflow  
**Technology**: ConversationSummaryMemory-inspired algorithms  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **Setup**: Open app, start new conversation
2. **Build Long Conversation**:
   - Send 50+ messages about a complex project
   - Mix topics: technical details, timelines, team members
   - Ensure messages span >30 minutes
3. **Test Summarization Trigger**:
   - Continue conversation until context limit approached
   - Send message: "Summarize our entire discussion"
4. **Verify Summary Quality**:
   - Check if summary includes key points
   - Verify important details preserved
   - Confirm irrelevant details compressed

#### **Expected Results:**
- ✅ App handles 50+ message conversation
- ✅ Summary includes key topics and details
- ✅ Response time <10 seconds for summary
- ✅ Memory consumption stays reasonable

#### **Failure Criteria:**
- ❌ App crashes with long conversation
- ❌ Summary misses critical information
- ❌ Memory usage exceeds 200MB

---

### **AT-3.3: Context Relevance Filtering**
**Purpose**: Verify AI prioritizes relevant context for queries  
**Technology**: Smart context relevance algorithms  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Setup Multiple Contexts**:
   - Discuss Topic A (work project) for 10 messages
   - Switch to Topic B (vacation planning) for 10 messages  
   - Switch to Topic C (technical learning) for 10 messages
2. **Test Relevance Filtering**:
   - Ask specific question about Topic A: "What was the deadline for the work project?"
   - Verify AI focuses on work project context
3. **Cross-Check Other Topics**:
   - Ask about Topic B: "Where did we decide to travel?"
   - Ask about Topic C: "What programming language were we discussing?"

#### **Expected Results:**
- ✅ AI retrieves correct context for each topic
- ✅ Responses focus on relevant information
- ✅ No mixing of unrelated contexts
- ✅ Context switching works smoothly

---

### **AT-3.4: Performance & Memory Optimization**
**Purpose**: Verify memory system performance on real device  
**Technology**: Core Data with performance optimizations  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Performance Baseline**:
   - Measure app launch time (cold start)
   - Record memory usage at startup
2. **Load Test**:
   - Create 5 different conversations
   - Each with 20+ messages
   - Switch between conversations rapidly
3. **Memory Retrieval Speed**:
   - Time context loading for each conversation
   - Measure response generation time
4. **Background/Foreground Test**:
   - Send app to background for 10 minutes
   - Return to foreground
   - Test immediate memory access

#### **Expected Results:**
- ✅ Memory retrieval <500ms per conversation
- ✅ App launch time <3 seconds
- ✅ Memory usage <100MB for 5 conversations
- ✅ No performance degradation after background

---

## 📄 **Sprint 4: Document Intelligence - Acceptance Tests**

### **AT-4.1: Multi-Format Document Upload**
**Purpose**: Verify app handles PDF, images, and text files correctly  
**Technology**: PDFKit + Vision framework + Core Data  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **PDF Upload Test**:
   - Use Files app to select a 5-10 page PDF
   - Upload through document picker
   - Verify text extraction and processing
2. **Image OCR Test**:
   - Take photo of printed Vietnamese text
   - Upload through camera/photo library
   - Verify OCR extraction accuracy
3. **Text File Test**:
   - Upload .txt file with mixed Vietnamese/English
   - Verify content processing and language detection
4. **Bulk Upload Test**:
   - Select multiple files (2 PDFs + 3 images)
   - Upload simultaneously
   - Verify all files processed correctly

#### **Expected Results:**
- ✅ All file types upload successfully
- ✅ Text extraction >95% accuracy for clear documents
- ✅ Vietnamese OCR works correctly
- ✅ Processing completes within 30 seconds per document
- ✅ Document metadata saved correctly

#### **Failure Criteria:**
- ❌ App crashes during upload
- ❌ Text extraction fails or produces gibberish
- ❌ Processing takes >60 seconds per document

---

### **AT-4.2: Document Q&A with RAG**
**Purpose**: Verify semantic search and intelligent answers work on real documents  
**Technology**: Core Data Vector + Custom RAG implementation  
**Priority**: P0 (Critical)

#### **Pre-setup:**
- Upload 3 different documents:
  - Technical manual (PDF)
  - Research paper (PDF) 
  - Meeting notes (image/text)

#### **Test Steps:**
1. **Simple Q&A Test**:
   - Ask: "What is the main topic of the technical manual?"
   - Verify AI provides accurate answer with source citation
2. **Cross-Document Search**:
   - Ask: "What common themes appear across all documents?"
   - Verify AI analyzes multiple documents
3. **Specific Information Retrieval**:
   - Ask detailed question about specific content
   - Verify AI finds and cites exact information
4. **Vietnamese Content Test**:
   - Upload Vietnamese document
   - Ask questions in Vietnamese
   - Verify multilingual RAG works

#### **Expected Results:**
- ✅ Answers are relevant and accurate
- ✅ Source citations include document name and section
- ✅ Cross-document analysis works
- ✅ Response time <5 seconds per query
- ✅ Vietnamese Q&A functions correctly

---

### **AT-4.3: Document Management UI**
**Purpose**: Verify complete document organization experience  
**Technology**: SwiftUI + Core Data + iOS FileManager  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Document Browser Test**:
   - Navigate to Documents tab
   - Verify all uploaded documents appear
   - Test search functionality with keywords
   - Test filter by document type
2. **Document Organization**:
   - Create new folder structure
   - Move documents between folders
   - Add tags to documents
   - Test sorting options (date, name, size)
3. **Document Detail View**:
   - Tap on document to view details
   - Test preview functionality
   - Edit document metadata (title, tags)
   - Test sharing functionality
4. **Document Management Actions**:
   - Test swipe-to-delete
   - Test swipe-to-archive
   - Test bulk selection and actions
   - Test document duplication detection

#### **Expected Results:**
- ✅ All UI interactions work smoothly
- ✅ Search finds relevant documents
- ✅ Organization features function correctly
- ✅ Preview shows document content properly
- ✅ Metadata changes persist across app restarts

---

### **AT-4.4: Integration: Memory + Documents**
**Purpose**: Verify AI remembers document discussions across sessions  
**Technology**: Integrated memory + RAG systems  
**Priority**: P1 (Important)

#### **Test Steps:**
1. **Initial Document Discussion**:
   - Upload business plan document
   - Discuss key strategies with AI (10+ messages)
   - AI should reference document content in responses
2. **App Restart Test**:
   - Close and reopen app
   - Return to same conversation
   - Ask: "What did we conclude about the marketing strategy?"
3. **Document Context Persistence**:
   - Verify AI remembers both:
     - Previous conversation about document
     - Document content for new queries
4. **Multi-Document Memory**:
   - Upload second related document
   - Discuss differences between documents
   - Test if AI maintains context about both

#### **Expected Results:**
- ✅ AI remembers document discussions after restart
- ✅ Can reference both conversation history and document content
- ✅ Context switching between documents works
- ✅ Memory system handles complex document+conversation context

---

## 🔒 **Cross-Cutting: Security Acceptance Tests**

### **AT-S.1: Keychain Security Integration**
**Purpose**: Verify enterprise-level API key security  
**Technology**: iOS Keychain + LocalAuthentication + Secure Enclave  
**Priority**: P0 (Critical)

#### **Test Steps:**
1. **API Key Setup**:
   - Navigate to Settings
   - Add OpenRouter API key
   - Verify Face ID/Touch ID prompt appears
   - Complete biometric authentication
2. **Key Storage Verification**:
   - Verify key appears masked in UI (sk-o••••••••cdef)
   - Test app functionality with stored key
   - Verify AI responses work with stored credentials
3. **Security Boundary Test**:
   - Try to access settings without biometric auth
   - Verify key remains protected
   - Test app restart - key should persist securely
4. **Multi-Provider Test**:
   - Add second API key (OpenAI)
   - Verify keys stored separately
   - Test switching between providers

#### **Expected Results:**
- ✅ Biometric authentication required for key access
- ✅ Keys stored securely in hardware keychain
- ✅ UI properly masks sensitive information
- ✅ Multi-provider isolation works correctly
- ✅ Keys persist across app restarts

---

## 📊 **Test Execution Guidelines**

### **Pre-Test Setup:**
1. **Device Requirements**:
   - iPhone/iPad with iOS 17+
   - Face ID or Touch ID enabled
   - Sufficient storage (>1GB free)
   - Stable internet connection

2. **Test Data Preparation**:
   - Valid OpenRouter API key
   - Sample documents (PDF, images, text files)
   - Vietnamese text samples for multilingual testing

### **Test Environment:**
- **Fresh App Install**: For baseline testing
- **Production Build**: Use TestFlight or App Store build
- **Real Network**: Test with actual API calls
- **Multiple Sessions**: Test across different usage patterns

### **Success Criteria:**
- **Functionality**: All test cases pass expected results
- **Performance**: Response times within specified limits
- **Stability**: No crashes during extended testing
- **User Experience**: Smooth, intuitive interactions

### **Reporting:**
Each test case should document:
- ✅ **Pass/Fail status**
- ⏱️ **Performance measurements**
- 📝 **Detailed observations**
- 🐛 **Issues found (if any)**
- 📱 **Device/iOS version tested**

---

**These acceptance tests ensure Sprint 3 & 4 features are production-ready và deliver the expected user experience on real iOS devices. Each test case maps directly to user stories và business requirements defined trong SRS v2.0.** 🚀 