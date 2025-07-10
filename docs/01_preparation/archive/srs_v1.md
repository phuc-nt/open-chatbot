# Tài Liệu Yêu Cầu Phần Mềm (SRS)
## Chatbot iOS với Tích Hợp Đa LLM API

## 1. TỔNG QUAN DỰ ÁN

### 1.1 Mục Tiêu Dự Án
Phát triển một **chatbot iOS native** mã nguồn mở, hỗ trợ đa LLM API provider, đặc biệt tối ưu cho **OpenRouter.ai**, nhằm cung cấp cho end-user một trải nghiệm AI chat toàn diện với khả năng tùy chỉnh cao.

### 1.2 Phạm Vi Dự Án
- **Platform**: iOS (iPhone + iPad) với Universal App
- **Phân phối**: App Store + mã nguồn mở
- **Mô hình kinh doanh**: Miễn phí, người dùng tự quản lý API key
- **Ngôn ngữ**: Swift với SwiftUI framework
- **Deployment**: iCloud sync để đồng bộ dữ liệu giữa thiết bị

### 1.3 Đối Tượng Người Dùng
- **Primary**: End-user cá nhân sử dụng AI chatbot
- **Secondary**: Developer muốn tùy chỉnh và đóng góp vào dự án mã nguồn mở

## 2. YÊU CẦU CHỨC NĂNG

### 2.1 Quản Lý API Key và Provider
**FR-001: Quản lý đa API Key**
- Cho phép nhập và lưu trữ nhiều API key từ các provider khác nhau
- Hỗ trợ provider: OpenRouter.ai (ưu tiên), OpenAI, Anthropic/Claude, Groq, Grok/xAI
- **Bảo mật**: Lưu trữ API key trong iOS Keychain với mã hóa AES-256[1][2]
- Label và phân loại API key theo provider và mục đích sử dụng

**FR-002: Chuyển đổi Model**
- Chuyển đổi nhanh giữa các model khác nhau trong cùng một conversation
- Hiển thị danh sách model có sẵn từ mỗi provider
- **Lưu trữ model đã chọn**: Tự động lưu và khôi phục model được sử dụng cho từng cuộc hội thoại.
- **Cost tracking**: Theo dõi chi phí theo từng model và conversation[3][4]

### 2.2 Giao Diện Chat và Tương Tác
**FR-003: Streaming Response**
- Hiển thị phản hồi AI theo thời gian thực với **WebSocket connection**[5][6]
- Progressive text generation với typing indicator
- Khả năng dừng generation khi cần thiết

**FR-004: Giao Diện Chat**
- UI/UX tối ưu cho iPhone và iPad
- Hỗ trợ **markdown rendering** và **syntax highlighting**[7][8]
- Copy code blocks, share conversations
- Dark mode và light mode support

### 2.3 Quản Lý Hội Thoại
**FR-005: Tổ chức Conversation**
- Lưu trữ và tổ chức hội thoại bằng **folder system**
- **Ghim hội thoại** quan trọng lên đầu danh sách
- Rename và archive conversations
- **Tìm kiếm** trong lịch sử chat với full-text search

**FR-006: Lưu Trữ Dữ Liệu**
- **Lưu trữ cục bộ** trên thiết bị với mã hóa[9][10]
- **iCloud sync** để đồng bộ giữa iPhone và iPad
- Backup và restore conversations
- **Auto-save** conversations real-time

### 2.4 Custom Assistant và Knowledge Base
**FR-007: Custom Assistant**
- Tạo assistant tùy chỉnh với **system prompt** riêng[11][12]
- **Role-play characters** với personality khác nhau
- Template prompt có sẵn cho các use case phổ biến
- **Cài đặt model mặc định**: Cho phép người dùng chọn một model mặc định cho tất cả các cuộc hội thoại mới.
- **Model parameters**: temperature, max tokens, top-p, frequency penalty

**FR-008: Knowledge Base**
- Upload file: **PDF, DOCX, TXT, Markdown** (giới hạn **50MB** per file)[13]
- **OCR integration**: Nhận diện văn bản trong ảnh[14][15][16]
- **Text extraction** từ document để gửi cùng prompt
- **Giai đoạn 2**: Nâng cấp thành RAG system[17][3]

### 2.5 Xử Lý Multimedia
**FR-009: Image Processing**
- **Đính kèm ảnh** vào prompt với preview
- **OCR**: Trích xuất text từ ảnh sử dụng **Vision API** (iOS native)[15][16]
- **Image analysis**: Phân tích nội dung hình ảnh với vision models[18]
- Hỗ trợ multiple image attachments

**FR-010: Web Integration**
- **Web Analyzer**: Tìm kiếm thông tin cập nhật từ internet
- **YouTube content analysis**: Phân tích transcript video
- **Article summarization**: Tóm tắt bài viết web
- **Real-time search**: Tích hợp search engine results

### 2.6 Export và Sharing
**FR-011: Export Conversations**
- Export format: **PDF, TXT, Markdown**
- Preserve formatting và code syntax highlighting
- **Share conversations** qua iOS Share Sheet
- **Print support** cho conversations

### 2.7 Cost Management
**FR-012: Cost Tracking**
- **Theo dõi chi phí** theo từng conversation[3][4]
- **Token usage monitoring** real-time
- **Cost breakdown** theo model và provider
- **Budget alerts** khi đạt ngưỡng chi phí

## 3. YÊU CẦU PHI CHỨC NĂNG

### 3.1 Hiệu Suất (Performance)
**NFR-001: Response Time**
- Streaming response latency < 200ms
- App launch time < 2 seconds
- Smooth scrolling trong long conversations

**NFR-002: File Processing**
- PDF processing < 5 seconds cho file 10MB
- OCR processing < 3 seconds cho standard image
- Batch file upload support

### 3.2 Bảo Mật (Security)
**NFR-003: Data Protection**
- API key encryption sử dụng **iOS Keychain**[1][2]
- Local data encryption với **FileProtectionComplete**[10]
- No API key transmission to external servers
- **Biometric authentication** option (Face ID/Touch ID)

### 3.3 Khả Năng Sử Dụng (Usability)
**NFR-004: User Experience**
- **iOS Human Interface Guidelines** compliance
- **Accessibility support** (VoiceOver, Dynamic Type)
- **Haptic feedback** cho user interactions
- **Error handling** với user-friendly messages
- **Khởi động thông minh**: Tự động mở lại cuộc hội thoại gần nhất khi khởi động ứng dụng để đảm bảo tính liên tục.
- **Đồng bộ hóa trạng thái real-time**: Trạng thái ứng dụng (ví dụ: model đã chọn) được đồng bộ hóa ngay lập tức trên tất cả các tab, mang lại trải nghiệm liền mạch.

### 3.4 Tương Thích (Compatibility)
**NFR-005: Platform Support**
- **iOS 15.0+** minimum requirement
- **Universal App**: iPhone và iPad optimization
- **iCloud sync** cross-device compatibility
- **App Store** submission compliance

## 4. KIẾN TRÚC KỸ THUẬT

### 4.1 Technology Stack
**Frontend**: SwiftUI + Combine
**Data Layer**: Core Data + CloudKit
**Security**: iOS Keychain Services
**Networking**: URLSession + WebSocket
**File Processing**: PDFKit + Vision Framework

### 4.2 Swift Packages Dependencies
```swift
// Networking & API
.package(url: "https://github.com/Alamofire/Alamofire")

// Markdown Rendering
.package(url: "https://github.com/gonzalezreal/swift-markdown-ui")

// Syntax Highlighting
.package(url: "https://github.com/raspu/Highlightr")

// PDF Processing
.package(url: "https://github.com/PSPDFKit/PSPDFKit-iOS")

// OCR Enhancement
.package(url: "https://github.com/tesseract-ocr/tesseract")

// Cost Monitoring
.package(url: "https://github.com/realm/realm-swift")
```

### 4.3 Kiến Trúc Ứng Dụng
```
├── Core/
│   ├── APIManager (Multi-provider support)
│   ├── DataManager (Core Data + CloudKit)
│   ├── SecurityManager (Keychain + Encryption)
│   └── CostTracker (Usage monitoring)
├── Features/
│   ├── Chat/ (Conversation UI)
│   ├── Assistant/ (Custom bot creation)
│   ├── Documents/ (File processing)
│   ├── Settings/ (Configuration)
│   └── Export/ (Share & Export)
├── Utils/
│   ├── Extensions/
│   ├── Helpers/
│   └── Constants/
└── Resources/
```

## 5. ROADMAP PHÁT TRIỂN

### 5.1 MVP (Giai Đoạn 1) - 8 tuần
**Tuần 1-2: Core Infrastructure**
- Project setup + Swift package integration
- API key management với Keychain
- Basic OpenRouter API integration

**Tuần 3-4: Chat Interface**
- SwiftUI chat UI với streaming support
- Basic conversation management
- Markdown rendering + syntax highlighting

**Tuần 5-6: File Processing**
- PDF/image upload và OCR
- Text extraction và prompt integration
- Cost tracking basic implementation

**Tuần 7-8: Polish & Testing**
- UI/UX refinement
- Error handling và edge cases
- App Store submission preparation

### 5.2 V2.0 (Giai Đoạn 2) - 6 tuần
**Advanced Features**
- RAG system implementation
- Web integration (search, YouTube, articles)
- Advanced custom assistant features
- Enhanced export options

### 5.3 V3.0 (Giai Đoạn 3) - 4 tuần
**Enterprise Features**
- Advanced cost analytics
- Team sharing capabilities
- API provider expansion
- Performance optimizations

## 6. TIÊU CHÍ CHẤP NHẬN

### 6.1 MVP Acceptance Criteria
✅ **Core Chat**: Successful chat với OpenRouter API, streaming response
✅ **File Upload**: PDF (≤50MB) và image upload với OCR
✅ **Security**: API key stored securely trong Keychain
✅ **UI/UX**: Responsive design cho iPhone/iPad
✅ **Cost Tracking**: Basic token usage monitoring
✅ **Export**: Export conversation as PDF/text

### 6.2 Quality Assurance
- **Unit tests** coverage ≥80%
- **UI tests** cho critical user flows
- **Performance testing** với large conversations
- **Security audit** cho API key handling
- **App Store review** compliance check

## 7. RỦIRO VÀ GIẢI PHÁP

### 7.1 Technical Risks
**API Rate Limiting**: Implement exponential backoff và user notifications
**Large File Processing**: Chunk processing và progress indicators
**Memory Management**: Optimize for large conversations và file uploads

### 7.2 Business Risks
**App Store Approval**: Ensure compliance với Apple guidelines
**User Privacy**: Clear privacy policy về data handling
**Cost Management**: Educate users về API usage costs