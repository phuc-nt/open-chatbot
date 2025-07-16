# Sprint 4 Test Case Business Guide

## 📋 **Mục đích tài liệu**

Tài liệu này giải thích từng test case trong Sprint 4 từ **góc độ nghiệp vụ của user**, giúp hiểu:
- **Tính năng nào** đang được test
- **Tại sao** phải test tính năng đó  
- **Giá trị** mang lại cho user experience
- **Rủi ro** nếu tính năng không hoạt động đúng

---

## 🎯 **Sprint 4: Document Intelligence System**

### **User Story**: 
*"Là một user, tôi muốn upload documents (PDF, images) và chatbot có thể hiểu nội dung để trả lời câu hỏi dựa trên documents đó."*

---

## 📚 **DOC-001: Document Upload & Processing**

### **User Experience**: Upload và xử lý documents

#### **DocumentTypesTests (12/12 PASSED ✅)**

**Nghiệp vụ**: User cần upload nhiều loại file khác nhau và hệ thống phải xử lý đúng.

##### **1. Document Type Detection Tests**

**Test Cases**:
- `testPDFDocumentType()` 
- `testImageDocumentTypes()`
- `testUnsupportedDocumentType()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: User sẽ upload PDF reports, ảnh chụp tài liệu, screenshots
- **Giá trị**: Hệ thống tự động detect loại file, áp dụng processing phù hợp
- **Rủi ro nếu fail**: User upload PDF nhưng hệ thống xử lý như image → extract text sai

**User Scenario**:
```
User: "Tôi có báo cáo PDF về doanh số và ảnh chụp hóa đơn"
System: ✅ Detect PDF → dùng PDFKit extract text
         ✅ Detect image → dùng Vision OCR
```

##### **2. Processing Status Management**

**Test Cases**:
- `testProcessingStatusTransitions()`
- `testProcessingTaskManagement()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: User cần biết document đang được xử lý hay đã xong
- **Giá trị**: UI hiển thị progress, user không phải đoán
- **Rủi ro nếu fail**: User không biết document có ready để chat chưa

**User Scenario**:
```
User uploads 20MB PDF:
Step 1: "Processing..." (status: .processing) 
Step 2: "Extracting text..." (status: .extracting)
Step 3: "Ready" (status: .completed) → User có thể chat
```

##### **3. Error Handling Tests**

**Test Cases**:
- `testCorruptedFileHandling()`
- `testProcessingErrorRecovery()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: User có thể upload file lỗi, corrupted, hoặc quá lớn
- **Giá trị**: Error message rõ ràng, suggest cách fix
- **Rủi ro nếu fail**: App crash hoặc user không hiểu tại sao upload fail

**User Scenario**:
```
User uploads corrupted PDF:
❌ Bad: App crashes
✅ Good: "File damaged. Please try another PDF or contact support."
```

---

## 🧠 **DOC-002: Multilingual Embedding Strategy**

### **User Experience**: Chatbot hiểu được nội dung documents bằng tiếng Việt và tiếng Anh

#### **EmbeddingServiceTests (13/23 PASSED ⚠️)**

**Nghiệp vụ**: Chatbot phải "hiểu" semantic meaning của text để trả lời đúng context.

##### **✅ PASSED Tests - Core Functionality**

##### **1. Service Initialization (3/3 tests)**

**Test Cases**:
- `testEmbeddingServiceInitialization()`
- `testEmbeddingServiceInitializationWithOnDeviceStrategy()`  
- `testEmbeddingServiceInitializationWithAPIStrategy()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: Đảm bảo service khởi tạo đúng với các strategies khác nhau
- **Giá trị**: User có thể dùng app offline (on-device) hoặc online (API)
- **Rủi ro nếu fail**: App không start được, user không thể chat với documents

**User Scenario**:
```
Scenario 1: User ở vùng có internet tốt
→ Dùng API strategy: Fast, accurate embeddings

Scenario 2: User ở vùng ít internet  
→ Dùng on-device strategy: Slower nhưng vẫn work offline

Scenario 3: User muốn balance
→ Dùng hybrid strategy: On-device first, fallback to API
```

##### **2. Language Detection (4/4 tests)**

**Test Cases**:
- `testLanguageDetectionEnglish()`
- `testLanguageDetectionVietnamese()`
- `testLanguageDetectionEmptyText()`
- `testLanguageDetectionShortText()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: Documents có thể là tiếng Việt, tiếng Anh, hoặc mixed
- **Giá trị**: Hệ thống chọn đúng model embedding cho từng ngôn ngữ
- **Rủi ro nếu fail**: Chatbot hiểu sai nội dung → trả lời không đúng

**User Scenario**:
```
User uploads:
- "Báo cáo tài chính Q4" → Detect Vietnamese → Dùng Vietnamese embedding model
- "Financial Report Q4" → Detect English → Dùng English embedding model  
- Mixed document → Detect dominant language hoặc split processing
```

##### **3. Strategy Selection (3/3 tests)**

**Test Cases**:
- `testOnDeviceStrategy()`
- `testAPIStrategy()`
- `testHybridStrategy()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: User cần flexibility based on connectivity/privacy needs
- **Giá trị**: App adapt theo tình huống thực tế của user
- **Rủi ro nếu fail**: App chỉ work trong điều kiện lý tưởng

**User Scenario**:
```
Corporate User (Privacy-sensitive):
→ Chọn on-device strategy: Data không leave device

Personal User (Speed priority):  
→ Chọn API strategy: Fastest, most accurate results

General User:
→ Chọn hybrid: Best of both worlds
```

##### **4. Caching & Performance (2/2 tests)**

**Test Cases**:
- `testEmbeddingCaching()`
- `testEmbeddingErrorDescriptions()`

**Giải thích nghiệp vụ**:
- **Tại sao test**: Prevent re-processing same content, improve speed
- **Giá trị**: User chat nhiều lần với same document → responses faster
- **Rủi ro nếu fail**: Slow performance, waste resources

**User Scenario**:
```
User uploads "Company Policy.pdf" (100 pages):
First time: 30 seconds processing
Next chat sessions: Instant (cached embeddings)
```

##### **❌ HANGING Tests - Integration Issues**

##### **5. Real Embedding Generation (6/6 hanging)**

**Test Cases**:
- `testEmbeddingGenerationErrorHandling()`
- `testEmbeddingGenerationWithSpecificLanguage()`
- `testBatchEmbeddingGeneration()`
- `testVietnameseTextHandling()`
- `testEmbeddingPerformanceBenchmark()`
- `testEmbeddingServiceWithRealText()`

**Tại sao tests hang**:
- **Technical**: Tests call real Apple ML APIs, download assets từ internet
- **Impact**: Không thể validate core business functionality

**Nghiệp vụ bị ảnh hưởng**:
```
🚨 CRITICAL: Chưa validate được:
- Vietnamese text processing quality
- Embedding accuracy cho business documents  
- Performance với large documents
- Error handling trong real-world scenarios
```

**Required Actions**:
1. **Mock tests** để validate logic
2. **Manual device testing** với real documents
3. **Integration testing** với actual user workflows

##### **6. API Integration (4/4 hanging)**

**Test Cases**:
- `testAPIEmbeddingServiceInitialization()`
- `testModelSelectionForVietnamese()`
- `testEmbeddingRequestStructure()`  
- `testEmbeddingResponseStructure()`

**Nghiệp vụ bị ảnh hưởng**:
```
🚨 CRITICAL: Chưa validate được:
- API fallback khi on-device fails
- Cost optimization (model selection)
- Network error handling  
- Rate limiting protection
```

---

## 📊 **Test Coverage vs User Needs**

### **✅ Validated User Needs**

1. **Multi-format Document Support** ✅
   - PDF, images, various formats
   - Error handling cho corrupted files

2. **Language Flexibility** ✅  
   - Vietnamese + English detection
   - Appropriate model selection

3. **Connectivity Adaptation** ✅
   - On-device, API, hybrid strategies
   - Basic initialization working

4. **Performance Optimization** ✅
   - Caching mechanisms
   - Strategy switching

### **❌ Critical User Needs Not Validated**

1. **Actual Document Understanding** ❌
   - Real embedding quality chưa test
   - Vietnamese text processing chưa validate

2. **Production Reliability** ❌
   - API error scenarios chưa test
   - Large document performance unknown

3. **User Experience Flow** ❌
   - End-to-end document chat workflow chưa test
   - Error recovery scenarios chưa validate

---

## 🎯 **Business Impact Assessment**

### **Current Risk Level: MEDIUM-HIGH ⚠️**

**✅ Safe to proceed với basic features**:
- Document upload/processing
- Basic embedding service functionality
- Multi-language detection

**🚨 Requires immediate attention**:
- Real embedding quality validation
- API integration testing
- Performance benchmarking

### **User Experience Implications**

**What Works Now**:
```
✅ User can upload documents
✅ System detects file types correctly  
✅ Basic language detection works
✅ Service initializes properly
```

**What's At Risk**:
```
❌ Embedding quality unknown → May give wrong answers
❌ API fallback untested → May fail when needed
❌ Performance unknown → May be too slow for real use
❌ Error handling incomplete → Poor user experience when things go wrong
```

---

## 📋 **Recommendations for Next Steps**

### **Priority 1: Critical Business Validation**

1. **Manual Testing Protocol**:
   - Test Vietnamese business documents (contracts, reports)
   - Test English technical documents  
   - Validate embedding quality manually

2. **Mock Testing Implementation**:
   - Create comprehensive mocks cho async tests
   - Validate business logic without external dependencies

### **Priority 2: User Acceptance Testing**

1. **Real User Scenarios**:
   - Upload real business documents
   - Ask practical questions
   - Measure response accuracy

2. **Performance Testing**:
   - Test với documents of various sizes
   - Measure processing times
   - Validate caching effectiveness

### **Priority 3: Production Readiness**

1. **Error Scenario Testing**:
   - Network failures
   - API rate limits
   - Large file handling

2. **Integration Testing**:
   - Full document-to-chat workflow
   - Multi-document scenarios
   - Cross-language document handling

---

## 📚 **Appendix: Test-to-Feature Mapping**

| Test Category | Business Feature | User Value | Risk if Failed |
|---------------|------------------|------------|----------------|
| Document Type Detection | Multi-format support | Can upload any business document | Wrong processing → bad results |
| Language Detection | Multilingual support | Works with Vietnamese + English docs | Wrong language → poor understanding |
| Strategy Selection | Connectivity adaptation | Works online/offline | Single point of failure |
| Caching | Performance | Fast repeated interactions | Slow user experience |
| Embedding Generation | Document understanding | Accurate answers from docs | Completely wrong responses |
| API Integration | Reliability & scale | Works under load | Service unavailable |

---

*Tài liệu này sẽ được update theo progress của Sprint 4 testing.* 