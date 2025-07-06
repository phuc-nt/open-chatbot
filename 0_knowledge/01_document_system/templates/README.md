# Documentation Templates

Bộ template này được thiết kế để giúp bạn triển khai hệ thống tài liệu "AI-friendly" được mô tả trong bài blog **"AI Không Đọc Được Suy Nghĩ Của Bạn"**.

## 🎯 Cách Sử Dụng

### **Bước 1: Copy Toàn Bộ Cấu Trúc**
```bash
# Copy toàn bộ thư mục templates vào dự án mới
cp -r templates/docs_structure/ your-new-project/docs/
```

### **Bước 2: Thay Thế Placeholders**
Mỗi template chứa các placeholder dạng `{{PLACEHOLDER}}` mà bạn cần thay thế:
- `{{PROJECT_NAME}}` - Tên dự án của bạn
- `{{TECH_STACK}}` - Công nghệ sử dụng (ví dụ: "React + Node.js")
- `{{MAIN_GOAL}}` - Mục tiêu chính của dự án
- `{{CURRENT_WEEK}}` - Tuần hiện tại trong roadmap
- `{{NEXT_MILESTONE}}` - Cột mốc tiếp theo

### **Bước 3: Tạo SRS Bằng Phương Pháp Phỏng Vấn AI**
Thay vì điền vào một template dài, hãy sử dụng phương pháp tương tác:
1. **Định danh AI**: Sử dụng `sample_prompts/srs_assistant_instruction_prompt.md` để "dạy" AI trở thành chuyên gia phân tích nghiệp vụ
2. **Bắt đầu cuộc trò chuyện**: Trình bày ý tưởng ban đầu và để AI dẫn dắt qua các câu hỏi
3. **Tham khảo**: Xem ví dụ thực tế trong `actual_sample/requirement_chat_history.md`
4. **Hướng dẫn chi tiết**: Trong `sample_prompts/srs_creation_prompt.md`

### **Bước 4: Onboard AI Nhanh Chóng**
Sử dụng prompt tinh gọn trong `sample_prompts/ai_onboarding_prompt.md`:
1. **Copy prompt gốc** và chọn biến thể phù hợp (onboarding, new task, review, debug)
2. **Điền thông tin** dự án cụ thể
3. **Test với AI** để đảm bảo hoạt động tốt

## 📁 Cấu Trúc Templates

```
templates/
├── README.md                    # File này
├── docs_structure/              # Cấu trúc thư mục docs/ hoàn chỉnh
│   ├── README.md               # Template cho file README chính
│   ├── 00_context/
│   │   ├── project_overview.md
│   │   └── current_status.md
│   ├── 00_guides/
│   │   ├── task_management_guide.md
│   │   ├── checklist_system_guide.md
│   │   └── documentation_maintenance_guide.md
│   ├── 01_preparation/
│   ├── 02_development/
│   ├── 03_implementation/
│   └── 04_troubleshooting/
├── sample_prompts/              # Prompts để làm việc với AI
│   ├── ai_onboarding_prompt.md  # Prompt ngắn gọn với biến thể
│   ├── srs_creation_prompt.md   # Hướng dẫn phương pháp phỏng vấn
│   └── srs_assistant_instruction_prompt.md  # "Định danh" AI chuyên gia
└── actual_sample/               # Ví dụ thực tế
    └── requirement_chat_history.md  # Cuộc trò chuyện tạo SRS hoàn chỉnh
```

## 🚀 Quick Start

1. **Tạo dự án mới**: Copy cấu trúc `docs_structure/` vào dự án
2. **Thay thế placeholders**: Tìm và thay thế tất cả `{{...}}`
3. **Tạo SRS bằng phỏng vấn AI**: Dùng instruction prompt + trò chuyện tự nhiên
4. **Setup môi trường**: Dùng AI tạo `dev_env_guide.md` từ tech stack
5. **Onboard AI**: Dùng prompt ngắn gọn với biến thể phù hợp

## 💡 Tips

- **Luôn bắt đầu với file `docs/START_POINT.md`** - đây là điểm vào duy nhất
- **Cập nhật `current_status.md` hàng ngày** - chỉ mất 2 phút
- **Tuân thủ `task_management_guide.md`** - đảm bảo quy trình nhất quán
- **Sử dụng phương pháp phỏng vấn cho SRS** - hiệu quả hơn nhiều so với template tĩnh
- **Tận dụng AI onboarding prompt** - tiết kiệm thời gian setup mỗi phiên làm việc

## 🔗 Tài Liệu Tham Khảo

- **Blog gốc**: Đọc bài viết đầy đủ về hệ thống này
- **GitHub Repository**: [https://github.com/phuc-nt/knowledge/tree/master/01_ai_documentation_system](https://github.com/phuc-nt/knowledge/tree/master/01_ai_documentation_system)
- **Template Index**: Xem `TEMPLATE_INDEX.md` để biết chi tiết về từng template

---
*Templates được tạo ra từ kinh nghiệm thực tế trong dự án iOS Chatbot.* 