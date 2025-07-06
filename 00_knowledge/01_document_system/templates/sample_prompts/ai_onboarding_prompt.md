# AI Onboarding Prompt

<!-- 
📝 HƯỚNG DẪN SỬ DỤNG:
1. Copy phần "🚀 Prompt Gốc".
2. Chọn một "ACTION_REQUIRED" từ các biến thể bên dưới và thay thế vào prompt chính.
3. Điền các placeholder còn lại (ví dụ: `{{PROJECT_NAME}}`, `{{SESSION_GOAL}}`).
4. Paste vào cửa sổ chat với AI.
-->

## 🚀 Prompt Gốc (Core Onboarding Prompt)

```
Chào bạn. Bạn là một **{{AI_ROLE | ví dụ: "Senior Developer Assistant"}}** cho dự án **{{PROJECT_NAME}}**.

Nhiệm vụ đầu tiên của bạn là hãy đọc file `docs/README.md` và làm theo hướng dẫn dành cho vai trò 'AI Assistant'.

Sau khi đọc xong, hãy **{{ACTION_REQUIRED}}**.

**Mục tiêu cho phiên làm việc này là:**
- {{SESSION_GOAL_1}}
- {{SESSION_GOAL_2}}
```

---

## 🎭 Biến Thể Prompt (Chọn 1 `ACTION_REQUIRED` phù hợp)

### **1. Onboarding Lần Đầu (Mặc Định)**
**Mục đích**: Nắm bắt tổng quan dự án.  
**ACTION_REQUIRED**: `tóm tắt cho tôi về dự án, tình trạng hiện tại, và đề xuất các bước tiếp theo để đạt được mục tiêu của phiên làm việc này.`

### **2. Bắt Đầu Một Task Mới**
**Mục đích**: Tập trung vào một nhiệm vụ cụ thể từ backlog.  
**ACTION_REQUIRED**: `xác nhận rằng bạn đã hiểu task {{TASK_ID}} trong 'docs/03_implementation/tasks/'. Hãy nêu kế hoạch thực hiện các bước trong checklist của task đó.`

### **3. Review Code hoặc Tài Liệu**
**Mục đích**: Đóng vai trò kiểm tra chất lượng.  
**ACTION_REQUIRED**: `review file/folder tại '{{PATH_TO_REVIEW}}'. Sau đó, cung cấp các nhận xét và đề xuất cải thiện dựa trên các quy chuẩn trong 'docs/00_guides/'.`

### **4. Gỡ Lỗi (Debugging)**
**Mục đích**: Tìm và sửa một lỗi cụ thể.  
**ACTION_REQUIRED**: `phân tích vấn đề được mô tả tại '{{ISSUE_LINK_OR_DESCRIPTION}}'. Sau đó, đề xuất các nguyên nhân có thể và một kế hoạch chi tiết để debug.`

## 🎯 **AI Onboarding Prompt**

```