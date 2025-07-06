# Sprint 1 Plan - Nền Tảng Phát Triển

**Thời gian**: 2 tuần (Week 1-2)  
**Mục tiêu**: Thiết lập nền tảng vững chắc cho phát triển iOS Chatbot  
**Milestone**: M1 - Development Environment Ready

---

## 🎯 **Sprint Goals**

### **Mục tiêu chính**
1. **Hoàn thiện môi trường phát triển** - Xcode + Cursor setup
2. **Tạo cấu trúc project iOS chuẩn** - SwiftUI + MVVM architecture
3. **Thiết lập Core Data foundation** - Basic models và persistence
4. **Tạo UI shell cơ bản** - Navigation và layout structure
5. **Thiết lập CI/CD cơ bản** - GitHub Actions cho build/test

### **Success Criteria**
- [x] Có thể build và run app trên simulator
- [x] Cấu trúc project theo MVVM pattern
- [x] Core Data hoạt động với basic model
- [x] Navigation giữa các màn hình chính
- [x] Code được push lên GitHub với proper commit messages

---

## 📋 **Task Breakdown**

### **Week 1: Foundation Setup**

#### **Task 1.1: Development Environment** 
**Ước tính**: 4 giờ  
**Ưu tiên**: P0 (Critical)

**Checklist**:
- [ ] Cài đặt Xcode (latest stable version)
- [ ] Cấu hình Cursor với Swift/SwiftUI extensions
- [ ] Thiết lập iOS Simulator (iPhone 15, iPad)
- [ ] Test build một project SwiftUI đơn giản
- [ ] Cấu hình Git hooks cho commit message format

**Deliverables**:
- Development environment hoạt động
- Screenshot simulator chạy thành công
- Git hooks setup document

#### **Task 1.2: iOS Project Structure**
**Ước tính**: 6 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 1.1

**Checklist**:
- [ ] Tạo new SwiftUI project: "OpenChatbot"
- [ ] Thiết lập folder structure:
  ```
  OpenChatbot/
  ├── App/
  │   ├── OpenChatbotApp.swift
  │   └── ContentView.swift
  ├── Views/
  │   ├── Chat/
  │   ├── Settings/
  │   └── Common/
  ├── ViewModels/
  ├── Models/
  ├── Services/
  │   ├── APIService/
  │   ├── DataService/
  │   └── KeychainService/
  ├── Resources/
  └── Utils/
  ```
- [ ] Tạo README.md cho từng folder
- [ ] Thiết lập .gitignore cho iOS
- [ ] Cấu hình project settings (Bundle ID, version, etc.)

**Deliverables**:
- Structured Xcode project
- Documentation cho folder structure
- Project builds successfully

#### **Task 1.3: Core Data Setup**
**Ước tính**: 6 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 1.2

**Checklist**:
- [ ] Thêm Core Data framework
- [ ] Tạo .xcdatamodeld file
- [ ] Thiết kế basic entities:
  - `Conversation` (id, title, createdAt, updatedAt)
  - `Message` (id, content, role, timestamp, conversationId)
  - `APIKey` (id, name, provider, createdAt)
- [ ] Tạo Core Data stack (PersistenceController)
- [ ] Thiết lập DataService với basic CRUD operations
- [ ] Viết unit tests cho Core Data operations

**Deliverables**:
- Core Data models hoạt động
- DataService với CRUD methods
- Unit tests pass

---

### **Week 2: Basic UI & Navigation**

#### **Task 2.1: Navigation Structure**
**Ước tính**: 5 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 1.3

**Checklist**:
- [ ] Thiết lập TabView với 3 tabs:
  - Chat (chính)
  - History (lịch sử)
  - Settings (cài đặt)
- [ ] Tạo NavigationView cho từng tab
- [ ] Implement basic routing system
- [ ] Thiết lập app state management với @StateObject
- [ ] Test navigation trên iPhone và iPad

**Deliverables**:
- Working tab navigation
- Responsive design for iPhone/iPad
- Navigation flows documented

#### **Task 2.2: Chat Interface Shell**
**Ước tính**: 8 giờ  
**Ưu tiên**: P0 (Critical)  
**Dependencies**: Task 2.1

**Checklist**:
- [ ] Tạo ChatView với basic layout:
  - Message list area
  - Input field
  - Send button
- [ ] Implement message bubble UI components
- [ ] Thiết lập ChatViewModel với @ObservableObject
- [ ] Mock data cho testing UI
- [ ] Implement basic scroll to bottom functionality
- [ ] Test với different message lengths

**Deliverables**:
- Chat interface layout
- Message bubble components
- ChatViewModel structure
- UI responsive trên nhiều screen sizes

#### **Task 2.3: Settings Screen**
**Ước tính**: 4 giờ  
**Ưu tiên**: P1 (Important)  
**Dependencies**: Task 2.1

**Checklist**:
- [ ] Tạo SettingsView với sections:
  - API Keys management
  - App preferences
  - About section
- [ ] Implement form components (TextField, Toggle, Picker)
- [ ] Thiết lập SettingsViewModel
- [ ] Add placeholder cho API key management
- [ ] Implement dark mode toggle

**Deliverables**:
- Settings screen layout
- Form components
- Dark mode support

#### **Task 2.4: History Screen**
**Ước tính**: 4 giờ  
**Ưu tiên**: P1 (Important)  
**Dependencies**: Task 1.3, Task 2.1

**Checklist**:
- [ ] Tạo HistoryView với conversation list
- [ ] Implement conversation cell component
- [ ] Thiết lập HistoryViewModel với Core Data fetch
- [ ] Add search functionality placeholder
- [ ] Implement swipe to delete
- [ ] Test với mock conversation data

**Deliverables**:
- History screen với conversation list
- Search placeholder
- Swipe actions working

---

## 🔧 **Technical Setup Tasks**

### **Task 3.1: GitHub Actions Setup**
**Ước tính**: 3 giờ  
**Ưu tiên**: P1 (Important)

**Checklist**:
- [ ] Tạo .github/workflows/ios.yml
- [ ] Cấu hình build workflow:
  - Build for iOS simulator
  - Run unit tests
  - Code coverage report
- [ ] Thiết lập branch protection rules
- [ ] Test workflow với sample commit

**Deliverables**:
- Working GitHub Actions workflow
- Automated build/test on PR

### **Task 3.2: Code Quality Setup**
**Ước tính**: 2 giờ  
**Ưu tiên**: P2 (Nice to have)

**Checklist**:
- [ ] Cấu hình SwiftLint
- [ ] Thiết lập code formatting rules
- [ ] Thêm pre-commit hooks
- [ ] Document coding standards

**Deliverables**:
- SwiftLint configuration
- Code quality checks automated

---

## 📊 **Sprint Metrics**

### **Effort Distribution**
- **Foundation**: 16 giờ (50%)
- **UI Development**: 21 giờ (40%)
- **DevOps**: 5 giờ (10%)
- **Total**: ~42 giờ (2 tuần)

### **Risk Assessment**
- **High Risk**: Core Data setup (chưa có kinh nghiệm)
- **Medium Risk**: UI responsive design
- **Low Risk**: Project structure, navigation

### **Dependencies**
- Xcode installation và setup
- GitHub repository access
- Apple Developer account (cho testing)

---

## 🎯 **Definition of Done**

### **Cho mỗi task**:
- [ ] Code được review và approved
- [ ] Unit tests pass (nếu có)
- [ ] UI tested trên iPhone và iPad simulator
- [ ] Code follows SwiftUI best practices
- [ ] Documentation updated
- [ ] Committed với proper message format

### **Cho toàn Sprint**:
- [ ] App builds và runs successfully
- [ ] All navigation flows working
- [ ] Core Data operations working
- [ ] GitHub Actions workflow passing
- [ ] Sprint retrospective completed
- [ ] Next sprint planning done

---

## 📝 **Daily Standups**

### **Format**: 15 phút mỗi ngày
**Questions**:
1. Hôm qua đã làm gì?
2. Hôm nay sẽ làm gì?
3. Có blocker nào không?

### **Schedule**:
- **Thứ 2**: Sprint planning review
- **Thứ 3-6**: Daily progress check
- **Thứ 7**: Sprint review & demo
- **Chủ nhật**: Sprint retrospective

---

## 🔄 **Sprint Review & Retrospective**

### **Review Questions**:
- Đã đạt được sprint goals chưa?
- Chất lượng code thế nào?
- UI/UX có đáp ứng yêu cầu không?
- Performance có vấn đề gì không?

### **Retrospective Questions**:
- Cái gì đã làm tốt?
- Cái gì cần cải thiện?
- Học được gì từ sprint này?
- Action items cho sprint tiếp theo?

---

## 📋 **Checklist Tổng Thể Sprint 1**

### **Pre-Sprint**
- [x] Sprint planning completed
- [x] Tasks estimated và assigned
- [x] Dependencies identified
- [x] Development environment ready

### **During Sprint**
- [ ] Daily standups conducted
- [ ] Progress tracked daily
- [ ] Blockers resolved quickly
- [ ] Code quality maintained

### **Post-Sprint**
- [ ] Sprint review completed
- [ ] Demo recorded
- [ ] Retrospective done
- [ ] Next sprint planned
- [ ] Lessons learned documented

---

*Sprint 1 Plan - Created: [Date]*  
*Next Review: End of Week 1*  
*Sprint End: [Date + 2 weeks]* 