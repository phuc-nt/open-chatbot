# Acceptance Test Cases - Sprint 3 (Smart Memory System)

**Mục tiêu**: Xác thực toàn bộ chức năng Memory System được phát triển trong Sprint 3, bao gồm ConversationBufferMemory, ConversationSummaryMemory, Context-Aware Responses, Memory Persistence và Token Window Management.

**Hướng dẫn**: Thực hiện từng test case dưới đây trên simulator hoặc thiết bị thật. Điền vào cột "Actual Result" và đánh dấu "Pass" hoặc "Fail" vào cột "Status".

---

## 🧪 Core Memory Features Test Cases

| ID        | Feature                      | Test Case Description                                               | Steps to Reproduce                                                                                                                                                                 | Expected Result                                                                                                                                                             | Actual Result | Status (Pass/Fail) |
|-----------|------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|--------------------|
| **AT-S3-01** | **ConversationBufferMemory** | Kiểm tra khả năng ghi nhớ context trong một cuộc trò chuyện.        | 1. Bắt đầu một cuộc trò chuyện mới. <br> 2. Hỏi "What is your name?". <br> 3. AI trả lời với tên của nó. <br> 4. Hỏi "What did I just ask you?".                                  | - AI nhớ được câu hỏi trước đó. <br> - Trả lời chính xác rằng user đã hỏi về tên. <br> - Không có dấu hiệu mất context.                                                      |               |                    |
| **AT-S3-02** | **ConversationBufferMemory** | Kiểm tra khả năng theo dõi chủ đề phức tạp.                         | 1. Bắt đầu một cuộc trò chuyện về một chủ đề (ví dụ: "Let's talk about space"). <br> 2. Hỏi 3-4 câu liên quan, sử dụng đại từ "it". <br> 3. Kiểm tra câu trả lời.                | - AI hiểu được "it" đang đề cập đến gì. <br> - Duy trì được mạch trò chuyện. <br> - Trả lời phù hợp với context.                                                             |               |                    |
| **AT-S3-03** | **Memory Persistence**       | Kiểm tra khả năng lưu trữ context qua các phiên.                    | 1. Tạo một cuộc trò chuyện và chat vài tin nhắn. <br> 2. Tắt app hoàn toàn. <br> 3. Mở lại app và vào lại cuộc trò chuyện đó. <br> 4. Hỏi về nội dung đã nói trước đó.           | - Context được khôi phục đầy đủ. <br> - AI nhớ được nội dung trò chuyện trước. <br> - Không có dấu hiệu mất dữ liệu.                                                         |               |                    |
| **AT-S3-04** | **Context-Aware Response**   | Kiểm tra độ chính xác của context trong câu trả lời.                | 1. Hỏi một câu phức tạp. <br> 2. Hỏi thêm "Can you explain that simpler?". <br> 3. Tiếp tục với "Give me an example.".                                                            | - AI hiểu được "that" đề cập đến gì. <br> - Giải thích đơn giản hơn về cùng chủ đề. <br> - Đưa ra ví dụ liên quan đến chủ đề ban đầu.                                       |               |                    |
| **AT-S3-05** | **Memory Performance**       | Kiểm tra thời gian phản hồi với context dài.                        | 1. Tạo một cuộc trò chuyện với ít nhất 20 tin nhắn qua lại. <br> 2. Gửi một tin nhắn mới. <br> 3. Đo thời gian từ lúc gửi đến khi nhận phản hồi.                                | - Thời gian phản hồi < 500ms. <br> - Không có lag trong UI. <br> - Context được duy trì chính xác.                                                                           |               |                    |

## 🧪 Advanced Memory Features Test Cases

| ID        | Feature                      | Test Case Description                                               | Steps to Reproduce                                                                                                                                                                 | Expected Result                                                                                                                                                             | Actual Result | Status (Pass/Fail) |
|-----------|------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|--------------------|
| **AT-S3-06** | **ConversationSummaryMemory** | Kiểm tra khả năng tóm tắt cuộc trò chuyện dài.                     | 1. Tạo một cuộc trò chuyện với >30 tin nhắn. <br> 2. Đợi cho ConversationSummaryMemory trigger. <br> 3. Kiểm tra token usage trước và sau.                                        | - Token usage giảm >70%. <br> - Context quan trọng vẫn được giữ lại. <br> - AI vẫn nhớ các thông tin chính.                                                                  |               |                    |
| **AT-S3-07** | **ConversationSummaryMemory** | Kiểm tra chất lượng của summary được tạo.                           | 1. Tạo cuộc trò chuyện về một chủ đề cụ thể. <br> 2. Đợi summary được tạo. <br> 3. Hỏi AI tóm tắt những gì đã nói.                                                                | - Summary chứa các điểm chính của cuộc trò chuyện. <br> - Không bỏ sót thông tin quan trọng. <br> - Ngữ cảnh được bảo toàn.                                                 |               |                    |
| **AT-S3-08** | **Token Window Management**   | Kiểm tra xử lý khi vượt quá giới hạn token.                         | 1. Chọn model với giới hạn token thấp (ví dụ: 4k). <br> 2. Tạo cuộc trò chuyện dài. <br> 3. Theo dõi cách hệ thống quản lý context.                                               | - Tự động nén context khi cần. <br> - Không vượt quá giới hạn token của model. <br> - Giữ lại tin nhắn gần nhất.                                                            |               |                    |
| **AT-S3-09** | **Progressive Compression**   | Kiểm tra khả năng nén tiến tiến.                                    | 1. Tạo cuộc trò chuyện dài. <br> 2. Quan sát các lần nén. <br> 3. Kiểm tra chất lượng context sau mỗi lần nén.                                                                    | - Mỗi lần nén đều giảm token usage. <br> - Context quality được duy trì. <br> - Không có thông tin quan trọng bị mất.                                                       |               |                    |
| **AT-S3-10** | **Error Recovery**           | Kiểm tra khả năng phục hồi khi gặp lỗi summarization.               | 1. Tạo điều kiện lỗi (ví dụ: mất kết nối khi đang summarize). <br> 2. Đợi hệ thống recovery. <br> 3. Kiểm tra tính toàn vẹn của dữ liệu.                                         | - Không mất dữ liệu gốc. <br> - Tự động thử summarize lại. <br> - UI thông báo lỗi phù hợp.                                                                                 |               |                    |

## 🧪 Integration Test Cases

| ID        | Feature                      | Test Case Description                                               | Steps to Reproduce                                                                                                                                                                 | Expected Result                                                                                                                                                             | Actual Result | Status (Pass/Fail) |
|-----------|------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|--------------------|
| **AT-S3-11** | **Memory-CoreData Bridge**   | Kiểm tra đồng bộ giữa memory và persistent storage.                 | 1. Tạo và lưu nhiều cuộc trò chuyện. <br> 2. Kiểm tra CoreData storage. <br> 3. Verify data integrity.                                                                             | - Dữ liệu trong CoreData khớp với memory. <br> - Không có memory leak. <br> - Load/save operations không block UI.                                                          |               |                    |
| **AT-S3-12** | **Memory-UI Integration**    | Kiểm tra hiển thị trạng thái memory trên UI.                       | 1. Theo dõi UI indicators trong quá trình chat. <br> 2. Kiểm tra khi memory đang được summarize. <br> 3. Verify progress indicators.                                                | - UI hiển thị memory status rõ ràng. <br> - Progress được update real-time. <br> - Không có UI glitches.                                                                    |               |                    |
| **AT-S3-13** | **Multi-Model Support**      | Kiểm tra memory với các model khác nhau.                           | 1. Tạo các cuộc trò chuyện với different models. <br> 2. Switch giữa các models. <br> 3. Verify memory behavior.                                                                    | - Memory system works với mọi model. <br> - Token limits được respect. <br> - Summarization phù hợp với từng model.                                                         |               |                    |

---

## 📊 **Test Execution Summary**

**Total Test Cases**: 13  
**Core Features**: 5 test cases  
**Advanced Features**: 5 test cases  
**Integration**: 3 test cases  

**Pass**: _____/13  
**Fail**: _____/13  
**Blocked**: _____/13  
**Coverage**: Memory Management, Context Awareness, Persistence, Summarization, Token Management  

---

## 📝 **Notes & Issues**

**Tester**: ___________________  
**Date**: ___________________  
**Device**: ___________________  
**iOS Version**: ___________________  

**Issues Found**:
1. ________________________________
2. ________________________________
3. ________________________________

**Fixed Issues**:
1. ________________________________
2. ________________________________
3. ________________________________

**Recommendations**:
1. ________________________________
2. ________________________________
3. ________________________________ 