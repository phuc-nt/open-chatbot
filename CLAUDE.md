# CLAUDE.md - OpenChatbot iOS Development Rules

## Quy tắc cơ bản
- **Luôn sử dụng tiếng Việt để trả lời** trừ khi user yêu cầu tiếng Anh cụ thể
- Đọc `docs/START_POINT.md` trước khi bắt đầu bất kỳ task nào
- Check `docs/00_context/current_status.md` để hiểu tình hình hiện tại
- Tuân thủ workflow trong `docs/00_process/task_management_guide.md`

## Tool Usage Priority
- **Luôn ưu tiên Serena MCP tools** cho tất cả tác vụ liên quan đến source code
- Kiểm tra Serena availability bằng `mcp__serena__get_current_config` trước khi bắt đầu
- Sử dụng Serena tools cho:
  - Code search: `mcp__serena__search_for_pattern`, `mcp__serena__find_symbol`
  - Code navigation: `mcp__serena__get_symbols_overview`, `mcp__serena__find_referencing_symbols`
  - Code editing: `mcp__serena__replace_symbol_body`, `mcp__serena__insert_after_symbol`
  - Project exploration: `mcp__serena__list_dir`, `mcp__serena__find_file`
- Chỉ fallback sang standard tools (Read, Grep, Glob) khi Serena không available

## Kiến trúc và code style

### iOS Swift Development
- Tuân thủ Swift naming conventions (camelCase cho variables/functions, PascalCase cho types)
- Ưu tiên `let` hơn `var` khi có thể
- SwiftUI: sử dụng `@State` cho local state, `@StateObject` cho view-owned objects
- Theo pattern MVVM với ViewModels
- Sử dụng dependency injection cho services
- Core Data cho local storage

### Project Structure
- `/ios/` - Main iOS project code
- `/docs/` - All documentation (theo structured hierarchy)
- Không được modify `.cursorrules` trừ khi có lý do rất cụ thể

## Quy trình phát triển

### Build và Test
- Sử dụng commands đã verified trong `docs/02_development/verified_build_commands.md`
- Build for real device: `xcodebuild -project OpenChatbot.xcodeproj -scheme OpenChatbot -destination 'generic/platform=iOS' build`
- Run tests: `xcodebuild test -project OpenChatbot.xcodeproj -scheme OpenChatbot -destination 'platform=iOS Simulator,name=iPhone 16'`
- Luôn test trên real device cho acceptance testing

### Documentation Updates
- Cập nhật `docs/00_context/current_status.md` sau mỗi major milestone
- Và cập nhật các document khác theo `docs/00_process/documentation_maintenance_guide.md`

### Git Commit Guidelines
- **Không sử dụng emoji** trong commit messages
- **Không thêm thông tin về Claude Code** hoặc AI tools trong commit message
- Sử dụng conventional commit format: `type: description`
- Ví dụ: `feat: add user authentication`, `fix: resolve memory leak in chat view`