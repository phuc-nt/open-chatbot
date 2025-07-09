# Acceptance Test Cases - Sprint 2

**Mục tiêu**: Xác thực toàn bộ chức năng được phát triển trong Sprint 2, bao gồm API Integration, Keychain Service, UI Quản lý Key, Real-time Streaming Chat, Model Persistence, và Real-time State Synchronization.

**Hướng dẫn**: Thực hiện từng test case dưới đây trên simulator hoặc thiết bị thật. Điền vào cột "Actual Result" và đánh dấu "Pass" hoặc "Fail" vào cột "Status".

---

## 🧪 Bảng Test Cases

| ID        | Feature                      | Test Case Description                                               | Steps to Reproduce                                                                                                                                                                 | Expected Result                                                                                                                                                             | Actual Result | Status (Pass/Fail) |
|-----------|------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|--------------------|
| **AT-S2-01** | **API Key Management**       | Thêm một API key hợp lệ của OpenRouter.                                | 1. Mở app, vào Settings -> API Keys. <br> 2. Chọn "OpenRouter". <br> 3. Nhấn "Add API Key". <br> 4. Dán một API key **hợp lệ** và lưu lại.                                           | - Key mới được thêm vào danh sách. <br> - Key hiển thị dưới dạng masked (ví dụ: `sk-or-v1-••••-123`). <br> - Trạng thái của key là "Not Verified".                          |               |                    |
| **AT-S2-02** | **API Key Management**       | Kiểm tra kết nối thành công với key hợp lệ.                           | 1. Thực hiện các bước của AT-S2-01. <br> 2. Nhấn vào nút "Test Connection" bên cạnh key vừa thêm.                                                                                  | - Thông báo "Connection Successful!" hiển thị. <br> - Trạng thái của key chuyển thành "Valid". <br> - Nút "Test Connection" biến mất.                                          |               |                    |
| **AT-S2-03** | **API Key Management**       | Thêm một API key không hợp lệ và kiểm tra lỗi.                       | 1. Vào Settings -> API Keys -> OpenRouter. <br> 2. Thêm một API key **không hợp lệ** (ví dụ: "123"). <br> 3. Nhấn "Test Connection".                                                | - Thông báo lỗi "Invalid API Key" hoặc tương tự hiển thị. <br> - Trạng thái của key vẫn là "Invalid".                                                                        |               |                    |
| **AT-S2-04** | **API Key Management**       | Xóa một API key.                                                    | 1. Vào Settings -> API Keys -> OpenRouter. <br> 2. Vuốt sang trái trên một key đã thêm. <br> 3. Nhấn nút "Delete".                                                                   | - Key bị xóa khỏi danh sách.                                                                                                                                                |               |                    |
| **AT-S2-05** | **Streaming Chat**           | Gửi một tin nhắn và nhận phản hồi streaming thành công.               | 1. Quay lại màn hình Chat. <br> 2. Đảm bảo đã có API key hợp lệ và đã chọn một model (ví dụ: GPT-4o Mini). <br> 3. Gõ "Hello, how are you?" và gửi.                             | - Tin nhắn của người dùng hiển thị ngay lập tức. <br> - Typing indicator của assistant xuất hiện. <br> - Phản hồi của assistant hiển thị dần dần từng chữ/từ một cách mượt mà.      |               |                    |
| **AT-S2-06** | **Streaming Chat**           | Dừng một yêu cầu streaming đang diễn ra.                             | 1. Gửi một câu hỏi dài để đảm bảo có thời gian streaming (ví dụ: "Hãy kể một câu chuyện ngắn về một con tàu vũ trụ"). <br> 2. Trong khi assistant đang trả lời, nhấn nút "Stop". | - Quá trình streaming dừng lại ngay lập tức. <br> - Typing indicator biến mất. <br> - Nút "Stop" chuyển lại thành nút "Send".                                                      |               |                    |
| **AT-S2-07** | **Streaming Chat**           | Xử lý lỗi khi không có API key hợp lệ.                                | 1. Xóa tất cả API key hợp lệ trong Settings. <br> 2. Quay lại màn hình Chat. <br> 3. Gửi một tin nhắn.                                                                           | - Một banner lỗi hiển thị ở đầu màn hình với thông báo "API Key not found or invalid." hoặc tương tự. <br> - Tin nhắn không được gửi đi.                                     |               |                    |
| **AT-S2-08** | **Model Selection**          | Chuyển đổi model trong khi chat.                                     | 1. Mở menu (dấu ba chấm ở góc trên bên phải). <br> 2. Chọn "Chọn Model". <br> 3. Chọn một model khác với model hiện tại. <br> 4. Gửi một tin nhắn mới.                          | - Tên model mới được hiển thị trên header của màn hình Chat. <br> - Phản hồi được trả về từ model mới đã chọn (có thể kiểm tra bằng cách hỏi "Bạn là model nào?").            |               |                    |
| **AT-S2-09** | **Error Handling**           | Xử lý lỗi khi không có kết nối mạng.                                  | 1. Tắt Wi-Fi và Dữ liệu di động trên thiết bị/simulator. <br> 2. Gửi một tin nhắn trong Chat.                                                                               | - Banner lỗi hiển thị với thông báo về sự cố mạng (ví dụ: "The Internet connection appears to be offline.").                                                               |               |                    |
| **AT-S2-10** | **UI/UX**                    | Kiểm tra hiển thị và cuộn trong danh sách tin nhắn.                 | 1. Gửi nhiều tin nhắn qua lại để danh sách dài hơn màn hình. <br> 2. Quan sát và cuộn danh sách.                                                                           | - Danh sách tin nhắn cuộn mượt mà. <br> - Tin nhắn mới nhất luôn được tự động cuộn xuống để xem. <br> - Message bubble của user và assistant có màu và vị trí khác nhau.       |               |                    |

---

## 🆕 **Enhanced Features Test Cases**

| ID        | Feature                      | Test Case Description                                               | Steps to Reproduce                                                                                                                                                                 | Expected Result                                                                                                                                                             | Actual Result | Status (Pass/Fail) |
|-----------|------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|--------------------|
| **AT-S2-11** | **Default Model Settings**   | Cài đặt model mặc định cho các cuộc hội thoại mới.                | 1. Vào Settings -> Default AI Model. <br> 2. Chọn một model từ danh sách (ví dụ: Claude-3.5 Sonnet). <br> 3. Quay lại Settings.                                           | - Tên model đã chọn hiển thị ngay lập tức trong phần "Default AI Model" của Settings. <br> - Model được đánh dấu ở đầu danh sách khi mở lại Default Model setting.        |               |                    |
| **AT-S2-12** | **Real-time State Sync**     | Kiểm tra đồng bộ hóa real-time giữa các tab.                      | 1. Đang ở tab Chat, chú ý model hiện tại. <br> 2. Chuyển sang Settings -> Default AI Model. <br> 3. Chọn model khác. <br> 4. Chuyển lại tab Chat.                        | - Model trong Chat tab được cập nhật ngay lập tức thành model mới (nếu đang ở cuộc hội thoại trống). <br> - Không cần restart app hay reload.                            |               |                    |
| **AT-S2-13** | **Model Persistence**        | Lưu model cho từng cuộc hội thoại riêng biệt.                     | 1. Tạo cuộc hội thoại với Model A, gửi 1-2 tin nhắn. <br> 2. Tạo cuộc hội thoại mới với Model B. <br> 3. Quay lại cuộc hội thoại đầu thông qua History.                  | - Khi quay lại cuộc hội thoại đầu, model tự động chuyển về Model A. <br> - Mỗi cuộc hội thoại ghi nhớ model đã sử dụng.                                                   |               |                    |
| **AT-S2-14** | **Smart App Startup**        | App tự động mở cuộc hội thoại gần nhất khi khởi động.             | 1. Có ít nhất 1 cuộc hội thoại trong History. <br> 2. Tắt app hoàn toàn. <br> 3. Mở lại app.                                                                              | - App tự động load cuộc hội thoại gần nhất thay vì tạo chat mới. <br> - Model được khôi phục theo cuộc hội thoại đó.                                                       |               |                    |
| **AT-S2-15** | **Model Search & Filter**    | Tìm kiếm model trong danh sách model picker.                      | 1. Mở Model Picker (trong Chat hoặc Settings). <br> 2. Gõ tên model vào search bar (ví dụ: "claude"). <br> 3. Kiểm tra kết quả lọc.                                      | - Chỉ hiển thị các model phù hợp với từ khóa tìm kiếm. <br> - Search hoạt động real-time khi gõ. <br> - Có thể tìm theo tên model hoặc provider.                          |               |                    |
| **AT-S2-16** | **History Tab Enhancement**   | Kiểm tra UI cải tiến của History tab.                             | 1. Vào History tab. <br> 2. Tạo vài cuộc hội thoại với tên khác nhau. <br> 3. Kiểm tra layout và tìm kiếm.                                                              | - Layout nhất quán với Settings tab (Form-based). <br> - Không có overlap với navigation bar. <br> - Search functionality hoạt động trong History.                       |               |                    |
| **AT-S2-17** | **Navigation Improvements**  | Chuyển đổi mượt mà giữa History và Chat.                          | 1. Ở History tab, tap vào một cuộc hội thoại. <br> 2. Kiểm tra việc chuyển tab và load conversation.                                                                       | - Tự động chuyển sang Chat tab. <br> - Cuộc hội thoại được load với đúng messages và model. <br> - Transition mượt mà không có lag.                                       |               |                    |
| **AT-S2-18** | **New Chat Button**          | Tạo cuộc hội thoại mới từ Chat tab.                               | 1. Ở Chat tab, nhấn nút "New Chat" (top-left). <br> 2. Kiểm tra reset state.                                                                                              | - Messages được clear. <br> - Model chuyển về default model. <br> - Sẵn sàng cho cuộc hội thoại mới.                                                                      |               |                    |

---

## 📊 **Test Execution Summary**

**Total Test Cases**: 18  
**Core Features**: 10 test cases  
**Enhanced Features**: 8 test cases  

**Pass**: ___/18  
**Fail**: ___/18  
**Coverage**: API Management, Streaming Chat, Model Management, State Synchronization, Persistence, UI/UX  

---

## 📝 **Notes & Issues**

**Tester**: ___________________  
**Date**: ___________________  
**Device/Simulator**: ___________________  
**iOS Version**: ___________________  

**Issues Found**:
1. ________________________________
2. ________________________________
3. ________________________________

**Recommendations**:
1. ________________________________
2. ________________________________
3. ________________________________ 