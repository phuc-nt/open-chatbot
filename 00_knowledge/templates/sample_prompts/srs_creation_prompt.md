# Hướng Dẫn Tạo SRS Bằng Phương Pháp Trò Chuyện với AI

<!-- 
📝 HƯỚNG DẪN SỬ DỤNG:
- Phương pháp này hiệu quả hơn nhiều so với việc điền vào một template dài.
- Nó biến việc tạo SRS thành một cuộc phỏng vấn tự nhiên với một "Chuyên gia AI".
- Hãy làm theo 2 bước đơn giản dưới đây.
-->

## Tại Sao Dùng Phương Pháp Này?

Việc bắt AI điền vào một template dài thường không hiệu quả. Thay vào đó, chúng ta sẽ "dạy" cho AI cách trở thành một chuyên gia phân tích nghiệp vụ, sau đó trò chuyện với nó. AI sẽ chủ động đặt câu hỏi để khai thác thông tin từ bạn, giúp tài liệu SRS được tạo ra một cách tự nhiên, đầy đủ và chính xác hơn.

---

## **Bước 1: Cung Cấp "Bộ Não" Cho AI (Định Danh Chuyên Gia)**

Trước khi bắt đầu, bạn cần "cài đặt" cho AI vai trò và kỹ năng của một chuyên gia khai thác yêu cầu.

1.  **Mở file**: `01_ai_documentation_system/templates/sample_prompts/srs_assistant_instruction_prompt.md`
2.  **Copy toàn bộ nội dung** của file đó.
3.  **Dán vào cửa sổ chat** với AI của bạn (ví dụ: Claude, Gemini, ChatGPT) như lời nhắn **đầu tiên** trong một phiên hội thoại mới.

Thao tác này sẽ "biến" AI của bạn thành một chuyên gia phân tích nghiệp vụ, sẵn sàng để phỏng vấn bạn.

---

## **Bước 2: Bắt Đầu Cuộc Phỏng Vấn**

Nhiệm vụ của bạn bây giờ rất đơn giản:

1.  **Trình bày ý tưởng ban đầu** của mình một cách ngắn gọn và tự nhiên. Ví dụ:
    > "tôi muốn làm một chatbot ios, sử dụng được llm api key của nhiều bên, đặc biệt là của openrouter.ai"

2.  **Chờ AI đặt câu hỏi**. AI sẽ bắt đầu phỏng vấn bạn, mỗi lần hỏi khoảng 2-3 câu để làm rõ ý tưởng.

3.  **Kiên nhẫn trả lời** các câu hỏi của AI. Quá trình này có thể lặp lại nhiều lần. AI sẽ tự động dẫn dắt bạn đi qua các khía cạnh cần thiết của dự án.

4.  **Chờ AI tổng hợp**. Khi cảm thấy đã có đủ thông tin, AI sẽ hỏi bạn có muốn tạo tài liệu SRS hay không.

5.  **Review và tinh chỉnh**. Sau khi AI tạo ra bản SRS đầu tiên, bạn có thể yêu cầu nó chỉnh sửa hoặc bổ sung nếu cần.

### **Ví Dụ Thực Tế**

Để xem một ví dụ hoàn chỉnh về cuộc hội thoại từ đầu đến cuối và kết quả SRS được tạo ra, bạn có thể tham khảo file:
➡️ `01_ai_documentation_system/actual_sample/requirement_chat_history.md`

File này ghi lại chính xác quá trình một người dùng đã trò chuyện với AI theo phương pháp này để tạo ra một tài liệu yêu cầu chi tiết.