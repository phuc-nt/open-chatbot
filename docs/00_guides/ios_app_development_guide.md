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

## Cấu trúc thư mục cuối cùng

```
MyApp/
├── .cursorrules
├── buildServer.json
├── MyApp.xcodeproj/
│   └── project.pbxproj
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

## Tips và Best Practices

1. **Sử dụng SwiftUI Preview** để xem giao diện real-time
2. **Tận dụng AI của Cursor** để học các pattern mới
3. **Tuân thủ iOS Human Interface Guidelines**
4. **Sử dụng proper state management** (@State, @Binding, @ObservedObject)
5. **Code clean và có comment** để AI hiểu context tốt hơn
6. **Test trên nhiều device sizes** sử dụng different simulators

## Tài liệu tham khảo

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SweetPad Extension](https://marketplace.visualstudio.com/items?itemName=sweetpad.sweetpad) 