## **Bước 1: Cài đặt các công cụ cần thiết**

### Cài đặt Xcode
Mặc dù muốn ưu tiên Cursor, bạn vẫn cần Xcode làm foundation:
- Mở Mac App Store và tìm "Xcode"
- Tải và cài đặt (khoảng 10-15GB, mất 30-60 phút)
- Mở Xcode một lần để hoàn tất setup ban đầu

### Cài đặt Cursor
- Truy cập cursor.com và tải về
- Cài đặt như một ứng dụng bình thường
- Đăng ký tài khoản (free tier đủ để bắt đầu)

### Cài đặt Command Line Tools
Mở Terminal và chạy các lệnh sau:

```bash
# Xcode Build Server - cho phép Cursor hiểu Swift projects
brew install xcode-build-server

# XCBeautify - làm đẹp output khi build
brew install xcbeautify

# SwiftFormat - format code Swift tự động
brew install swiftformat

# SwiftLint - kiểm tra code style
brew install swiftlint
```

## **Bước 2: Thiết lập Cursor cho Swift**

### Cài đặt Extensions trong Cursor
1. Mở Cursor
2. Nhấn `Cmd+Shift+X` để mở Extensions
3. Cài đặt các extension sau:
   - **Swift** (syntax highlighting, code completion)
   - **SweetPad** (tích hợp với Xcode build system)
   - **CodeLLDB** (debugging Swift code)
   - **SwiftLint** (code style checking)

### Cấu hình SweetPad
SweetPad là chìa khóa để build/run app trực tiếp từ Cursor:
1. Sau khi cài SweetPad, restart Cursor
2. Mở Command Palette (`Cmd+Shift+P`)
3. Tìm "SweetPad: Generate Build Server Config"

## **Bước 3: Tạo project đầu tiên**

### Tạo project trong Xcode (chỉ làm 1 lần)
1. Mở Xcode
2. Chọn "Create a new Xcode project"
3. Chọn **iOS** → **App**
4. Điền thông tin:
   - **Product Name**: "MyFirstApp"
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Organization Identifier**: com.yourname.myfirstapp
5. Chọn vị trí lưu và tạo project
6. **Đóng Xcode ngay sau khi tạo xong**

### Mở project trong Cursor
1. Mở Cursor
2. Chọn "Open Folder"
3. Chọn folder chứa project vừa tạo (có file .xcodeproj)
4. Cursor sẽ tự động detect đây là Swift project

### Cấu hình Build Server
1. Trong Cursor, mở Command Palette (`Cmd+Shift+P`)
2. Chạy "SweetPad: Generate Build Server Config"
3. File `buildServer.json` sẽ được tạo tự động

## **Bước 4: Workflow phát triển với Cursor**

### Cấu trúc project cơ bản
Sau khi mở project, bạn sẽ thấy:
```
MyFirstApp/
├── MyFirstApp/
│   ├── ContentView.swift    # UI chính
│   ├── MyFirstAppApp.swift  # Entry point
│   └── Assets.xcassets      # Hình ảnh, icons
├── MyFirstApp.xcodeproj     # Project file
└── buildServer.json         # Build config
```

### Sử dụng AI trong Cursor
1. **Chat với AI**: Nhấn `Cmd+L` để mở chat
2. **Composer**: Nhấn `Cmd+I` để tạo code từ mô tả
3. **Inline editing**: Highlight code và nhấn `Cmd+K`

### Ví dụ tạo app đầu tiên với AI
1. Mở file `ContentView.swift`
2. Nhấn `Cmd+L` để chat với AI
3. Gõ prompt:
```
"Tạo một app iOS đơn giản với SwiftUI có:
- Tiêu đề 'My First App'
- Một text field để nhập tên
- Một button 'Say Hello'
- Khi nhấn button, hiển thị 'Hello [tên]' bên dưới"
```

4. AI sẽ generate code, copy và paste vào ContentView.swift

### Build và Run từ Cursor
1. Nhấn `F5` hoặc mở Command Palette
2. Chọn "SweetPad: Run"
3. Chọn simulator (iPhone 15, iPad, etc.)
4. App sẽ build và chạy trực tiếp

## **Bước 5: Tối ưu hóa workflow**

### Tạo .cursorrules file
Tạo file `.cursorrules` trong root project với nội dung:

```
You are an expert iOS developer using SwiftUI and Swift.

When writing code:
- Use SwiftUI for all UI components
- Follow Swift naming conventions
- Use proper state management with @State, @Binding, @ObservedObject
- Write clean, readable code with comments
- Suggest modern SwiftUI patterns and best practices
- Always explain what the code does

For UI:
- Use native SwiftUI components
- Follow iOS Human Interface Guidelines
- Make responsive layouts that work on different screen sizes
- Use proper spacing and padding

When I ask for help:
- Provide complete, working code examples
- Explain the concepts being used
- Suggest improvements or alternatives
```

### Keyboard Shortcuts hữu ích
- `Cmd+L`: Chat với AI
- `Cmd+I`: Composer (tạo code từ mô tả)
- `Cmd+K`: Edit code inline
- `F5`: Build và run
- `Cmd+Shift+P`: Command Palette
- `Cmd+/`: Comment/uncomment code

### Hot Reloading với Inject (tùy chọn)
Để thay đổi code hiển thị ngay lập tức:
1. Thêm Inject vào project:
```bash
# Trong terminal, tại folder project
swift package add https://github.com/krzysztofzablocki/Inject.git
```

2. Thêm vào ContentView:
```swift
import Inject

struct ContentView: View {
    var body: some View {
        // Your UI code here
    }
    .enableInjection()
}
```

## **Bước 6: Workflow hàng ngày**

### Quy trình làm việc
1. **Mở Cursor** (không cần mở Xcode)
2. **Chat với AI** để brainstorm tính năng
3. **Dùng Composer** để tạo code mới
4. **Edit inline** để tinh chỉnh
5. **Build/Run** trực tiếp từ Cursor
6. **Chỉ mở Xcode** khi cần:
   - Cấu hình build settings phức tạp
   - Sử dụng Interface Builder
   - Submit app lên App Store

### Khi nào cần Xcode
- **Cấu hình certificates** cho device testing
- **App Store submission**
- **Advanced debugging** với breakpoints
- **Performance profiling**
- **Interface Builder** cho Storyboard (hiếm khi dùng với SwiftUI)

Với setup này, bạn có thể làm 90% công việc trong Cursor và chỉ cần Xcode cho các tác vụ đặc biệt. AI sẽ giúp bạn học Swift và SwiftUI nhanh chóng mà không cần kinh nghiệm trước đó.