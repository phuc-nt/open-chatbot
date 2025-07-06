# Hướng dẫn phát triển iOS App với Cursor và SweetPad

## Tổng quan
Guideline này hướng dẫn cách tạo và phát triển một ứng dụng iOS đơn giản sử dụng SwiftUI với Cursor và SweetPad.

## Yêu cầu
- Xcode đã được cài đặt
- Cursor với các extensions: Swift, SweetPad, CodeLLDB, SwiftLint
- Homebrew tools: xcode-build-server, xcbeautify, swiftformat, swiftlint

## Bước 1: Tạo cấu trúc project

### 1.1 Tạo thư mục project và các file cần thiết

```bash
# Tạo thư mục project
mkdir MyApp
cd MyApp

# Tạo thư mục con cho source code
mkdir MyApp

# Tạo thư mục cho assets
mkdir MyApp/Assets.xcassets
```

### 1.2 Tạo file .cursorrules

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

## Bước 2: Tạo các file Swift

### 2.1 MyAppApp.swift - Entry point của ứng dụng

```swift
import SwiftUI

@main
struct MyAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2.2 ContentView.swift - Giao diện chính

```swift
import SwiftUI

struct ContentView: View {
    @State private var name: String = ""
    @State private var greeting: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("My First App")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            TextField("Nhập tên của bạn", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                if !name.isEmpty {
                    greeting = "Xin chào, \(name)!"
                } else {
                    greeting = "Vui lòng nhập tên của bạn"
                }
            }) {
                Text("Say Hello")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            if !greeting.isEmpty {
                Text(greeting)
                    .font(.title2)
                    .padding(.top)
            }
            
            Spacer()
        }
        .padding()
    }
}
```

### 2.3 Preview.swift - File xem trước

```swift
import SwiftUI

#Preview {
    ContentView()
}
```

## Bước 3: Tạo Xcode project

### 3.1 Tạo file project.pbxproj

Tạo file `MyApp.xcodeproj/project.pbxproj` với nội dung cơ bản của Xcode project. File này chứa cấu hình build settings, targets, và references đến các file source.

### 3.2 Tạo Assets.xcassets

```json
// MyApp/Assets.xcassets/Contents.json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

## Bước 4: Cấu hình SweetPad

### 4.1 Tạo file buildServer.json ban đầu

```json
{
  "kind": "xcode",
  "projectPath": "./MyApp.xcodeproj",
  "schemeName": "MyApp",
  "buildSettings": {
    "PLATFORM_NAME": "iphonesimulator",
    "SDKROOT": "iphonesimulator",
    "SWIFT_VERSION": "5.0"
  }
}
```

### 4.2 Generate build server config

```bash
xcode-build-server config -project MyApp.xcodeproj -scheme MyApp
```

Lệnh này sẽ tự động cập nhật file `buildServer.json` với cấu hình chính xác.

## Bước 5: Build và Run

### 5.1 Kiểm tra build từ command line

```bash
# Kiểm tra danh sách simulators có sẵn
xcodebuild -project MyApp.xcodeproj -scheme MyApp -showdestinations

# Build project
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build
```

### 5.2 Sử dụng SweetPad trong Cursor

1. **Restart Cursor** để load lại cấu hình
2. Mở Command Palette (Cmd+Shift+P)
3. Chọn "SweetPad: Run"
4. Chọn simulator (iPhone 16, iPad, etc.)

## Bước 6: Phát triển với AI

### 6.1 Sử dụng Cursor AI

- **Cmd+L**: Chat với AI để hỏi về code
- **Cmd+I**: Composer để tạo code từ mô tả
- **Cmd+K**: Edit code inline
- **Tab**: Accept AI suggestions

### 6.2 Ví dụ prompts hữu ích

```
"Thêm một counter button vào giao diện"
"Tạo một navigation view với multiple screens"
"Thêm animation cho button khi được tap"
"Tạo một list view với sample data"
```

## Bước 7: Code Quality & Standards

### 7.1 Cài đặt Code Quality Tools

```bash
# Install SwiftLint và SwiftFormat
brew install swiftlint swiftformat
```

### 7.2 Tạo file cấu hình SwiftLint (.swiftlint.yml)

```yaml
# SwiftLint Configuration
included:
  - MyApp/

excluded:
  - .build/
  - DerivedData/

# Rule Configuration
line_length:
  warning: 120
  error: 150

function_body_length:
  warning: 50
  error: 100

type_body_length:
  warning: 200
  error: 300

# Naming Rules
type_name:
  min_length: 3
  max_length: 40

identifier_name:
  min_length: 2
  max_length: 40
  excluded:
    - id
    - url
    - api

# Custom Reporter
reporter: "xcode"
```

### 7.3 Tạo file cấu hình SwiftFormat (.swiftformat)

```bash
# SwiftFormat Configuration
--exclude .build,DerivedData
--indent 4
--trimwhitespace always
--wraparguments before-first
--wrapparameters before-first
--shortoptionals always
--semicolons inline
--commas inline
--redundantself remove
--redundantget remove
--redundantinit remove
```

### 7.4 Tạo script format (scripts/format.sh)

```bash
#!/bin/bash

# Code Quality Script
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$PROJECT_DIR/MyApp"

echo "🔧 Running Code Quality Checks"

# SwiftFormat
if command -v swiftformat &> /dev/null; then
    echo "🎨 Running SwiftFormat..."
    swiftformat --config .swiftformat "$SOURCE_DIR"
    echo "✅ SwiftFormat completed"
else
    echo "❌ SwiftFormat not installed. Run: brew install swiftformat"
fi

# SwiftLint
if command -v swiftlint &> /dev/null; then
    echo "🔍 Running SwiftLint..."
    swiftlint lint --config .swiftlint.yml
    echo "✅ SwiftLint completed"
else
    echo "❌ SwiftLint not installed. Run: brew install swiftlint"
fi
```

```bash
# Cấp quyền thực thi
chmod +x scripts/format.sh
```

## Bước 8: Coding Standards

### 8.1 Architecture Guidelines - MVVM Pattern

```swift
// ✅ Good: Clear separation of concerns
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private let dataService: DataService
    
    func sendMessage(_ content: String) {
        // Business logic here
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        // UI code only
    }
}
```

### 8.2 Naming Conventions

```swift
// ✅ Good: Descriptive camelCase
let userMessage = "Hello"
let isLoadingMessages = false
func sendMessageToServer(_ message: String) { }

// ❌ Bad: Unclear names
let msg = "Hello"
let loading = false
func send(_ m: String) { }
```

### 8.3 SwiftUI Best Practices

```swift
// ✅ Good: Small, focused views
struct ChatView: View {
    var body: some View {
        VStack {
            MessageListView()
            MessageInputView()
        }
    }
}

// ✅ Good: Proper state management
struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
}
```

### 8.4 Error Handling

```swift
// ✅ Good: Safe optional handling
if let message = viewModel.selectedMessage {
    presentMessageDetail(message)
}

guard let user = currentUser else {
    showLoginScreen()
    return
}

// ❌ Bad: Force unwrapping
let message = viewModel.selectedMessage! // Dangerous
```

### 8.5 Code Quality Checklist

#### Before Committing
- [ ] Code follows MVVM pattern
- [ ] SwiftLint warnings resolved
- [ ] SwiftFormat applied
- [ ] No force unwrapping (`!`) or `try!`
- [ ] Proper error handling
- [ ] Accessibility labels added
- [ ] Documentation comments for public APIs

#### Code Review
- [ ] Code is readable and maintainable
- [ ] Architecture patterns followed
- [ ] Edge cases handled
- [ ] Performance implications considered
- [ ] Memory management (weak references)

### 8.6 Running Quality Checks

```bash
# Run all quality checks
./scripts/format.sh

# Or run individually
swiftformat --config .swiftformat MyApp/
swiftlint lint --config .swiftlint.yml
```

## Cấu trúc thư mục cuối cùng

```
MyApp/
├── .cursorrules
├── .swiftlint.yml
├── .swiftformat
├── .gitignore
├── buildServer.json
├── MyApp.xcodeproj/
│   └── project.pbxproj
├── scripts/
│   └── format.sh
└── MyApp/
    ├── Assets.xcassets/
    │   └── Contents.json
    ├── MyAppApp.swift
    ├── ContentView.swift
    └── Preview.swift
```

## Troubleshooting

### Lỗi "No xcode workspaces found"
- Chạy lại: `xcode-build-server config -project MyApp.xcodeproj -scheme MyApp`
- Restart Cursor
- Đảm bảo file buildServer.json có field "kind": "xcode"

### Build errors
- Kiểm tra syntax Swift
- Đảm bảo tất cả imports đúng
- Verify project structure

### SweetPad không hiển thị simulators
- Mở Xcode một lần để khởi tạo simulators
- Restart Cursor
- Kiểm tra Xcode command line tools: `xcode-select --install`

### SwiftLint/SwiftFormat Issues
- Verify tools installed: `brew list | grep swift`
- Check config file paths
- Run with verbose flag: `swiftlint lint --verbose`

## Tips và Best Practices

1. **Sử dụng SwiftUI Preview** để xem giao diện real-time
2. **Tận dụng AI của Cursor** để học các pattern mới
3. **Tuân thủ iOS Human Interface Guidelines**
4. **Sử dụng proper state management** (@State, @Binding, @ObservedObject)
5. **Code clean và có comment** để AI hiểu context tốt hơn
6. **Test trên nhiều device sizes** sử dụng different simulators
7. **Run quality checks thường xuyên** để maintain code standards
8. **Use descriptive names** thay vì abbreviations
9. **Keep functions small** (max 50 lines)
10. **Document public APIs** với Swift DocC format

## Tài liệu tham khảo

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SweetPad Extension](https://marketplace.visualstudio.com/items?itemName=sweetpad.sweetpad)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [SwiftFormat Options](https://github.com/nicklockwood/SwiftFormat#options) 