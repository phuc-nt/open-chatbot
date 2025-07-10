<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# tôi muốn làm một chatbot ios, sử dụng được llm api key của nhiều bên, đặc biệt là của openrouter.ai

Dựa trên thông tin tìm kiếm, tôi thấy bạn muốn phát triển một chatbot iOS có khả năng tích hợp nhiều LLM API, đặc biệt là OpenRouter.ai. Đây là một ý tưởng rất hay vì **OpenRouter.ai cung cấp unified API để truy cập hàng trăm AI model thông qua một endpoint duy nhất**[^1_1][^1_2].

Để có thể hỗ trợ bạn tốt nhất trong việc đặc tả yêu cầu cho dự án này, tôi cần hiểu rõ hơn về mục tiêu và ngữ cảnh cụ thể:

**1. Về phạm vi và mục tiêu:**

- Đây là dự án cá nhân hay thương mại? Bạn dự định phát triển cho nội bộ sử dụng hay phân phối trên App Store?
- Ai sẽ là người dùng chính của chatbot này (developer, end-user, doanh nghiệp)?

**2. Về tính năng và khả năng:**

- Bạn muốn hỗ trợ những LLM provider nào cụ thể ngoài OpenRouter? (OpenAI, Claude/Anthropic, Groq, Grok/xAI, DeepSeek...)[^1_3]
- Có cần tính năng nào đặc biệt như tạo custom assistant, lưu trữ conversation, knowledge base hay role-play bot không?

**3. Về yêu cầu kỹ thuật:**

- Bạn có kinh nghiệm phát triển iOS với Swift không? Có muốn sử dụng các Swift package có sẵn[^1_4] hay tự xây dựng từ đầu?
- Có yêu cầu gì về bảo mật API key và dữ liệu người dùng?

Bạn có thể chia sẻ thêm về những điểm này để tôi có thể đưa ra hướng dẫn và đặc tả yêu cầu phù hợp nhất không?

<div style="text-align: center">⁂</div>

[^1_1]: https://openrouter.ai/docs/quickstart

[^1_2]: https://openrouter.ai

[^1_3]: https://www.llmconnect.co/api-keys

[^1_4]: https://github.com/FiveSheepCo/OpenAI-OpenRouter

[^1_5]: https://www.reddit.com/r/ClaudeAI/comments/1geklu0/llmconnect_a_native_ios_app_to_chat_with_gpt/

[^1_6]: https://llmconnect.co

[^1_7]: https://openrouter.ai/docs/api-reference/overview

[^1_8]: https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints/openrouter

[^1_9]: https://openrouter.ai/docs/api-reference/authentication

[^1_10]: https://www.llmconnect.co/providers/openrouter

[^1_11]: https://openrouter.ai/docs/api-reference/parameters

[^1_12]: https://www.postman.com/ai-engineer/generative-ai-apis/documentation/ef6c9qg/openrouter-api?entity=request-7643177-580b5cf9-ceb1-4fd5-97f5-11e0346e7630

[^1_13]: https://blog.streamlit.io/how-to-create-an-ai-chatbot-llm-api-replicate-streamlit/

[^1_14]: https://www.youtube.com/watch?v=9DjbQpbQVFo

[^1_15]: https://www.youtube.com/watch?v=KyQKTJhSIak

[^1_16]: https://getstream.io/blog/ios-assistant/

[^1_17]: https://developers.redhat.com/articles/2025/05/13/how-integrate-vllm-inference-your-macos-and-ios-apps

[^1_18]: https://apps.apple.com/app/llm-shortcut-toolkit/id6747269378

[^1_19]: https://techifysolutions.com/blog/building-a-multi-agent-chatbot-with-langgraph/

[^1_20]: https://getstream.io/chat/solutions/ai-integration/

[^1_21]: https://www.union.ai/docs/serverless/tutorials/serving/llama_edge_deployment/

[^1_22]: https://henryadu.hashnode.dev/building-a-multi-modal-flutter-chatbot-with-langchaindart-gpt-4o-and-dash-chat-2

[^1_23]: https://apps.apple.com/us/app/private-llm-local-ai-chat/id6448106860

[^1_24]: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/ios

[^1_25]: https://geekyants.com/blog/how-to-build-ai-chatbots-using-chatgpt-api-with-live-demo-video

[^1_26]: https://github.com/chatboxai/chatbox

[^1_27]: https://www.reddit.com/r/iosapps/comments/1gej114/built_my_first_ios_app_in_swiftui_a_multiapi_llm/

[^1_28]: https://expandmapping.substack.com/p/making-minimalist-chatbot-ios-app

[^1_29]: https://privatellm.app/en

[^1_30]: https://www.youtube.com/watch?v=b5iirrDh-2k

[^1_31]: https://openrouter.ai/docs/api-reference/list-available-models

[^1_32]: https://www.reddit.com/r/LocalLLaMA/comments/1cca8ts/native_ios_app_to_chat_with_groq_openrouter/

[^1_33]: https://openrouter.ai/docs/features/provisioning-api-keys

[^1_34]: https://openrouter.ai/docs/api-reference/get-a-generation

[^1_35]: https://support.elephas.app/features-walkthrough/wdkRih4NAYRnhae7GV2P66/how-to-use-openrouter-with-elephas-ai/pbfAWQ7FaZg9kRhLDHMmFo

[^1_36]: https://openrouter.ai/docs/api-reference/chat-completion

[^1_37]: https://www.youtube.com/watch?v=Uu2C5VpEKNg

[^1_38]: https://openrouter.ai/docs/api-reference/list-endpoints-for-a-model

[^1_39]: https://openrouter.ai/docs/features/images-and-pdfs

[^1_40]: https://x.com/OpenRouterAI/status/1871330984597258582?lang=en


---

# - phân phối trên App Store

- người dùng chính của chatbot này: end-user
- hỗ trợ những LLM provider nào cụ thể ngoài OpenRouter?: OpenAI, Claude/Anthropic, Groq, Grok/xAI... Nhưng trước mắt ưu tiên OpenRouter đã
- có lưu trữ conversation, knowledge base và role-play bot (custom instruction)
- không có kinh nghiệm với Swift, hãy dùng các Swift package có sẵn

Cám ơn bạn đã cung cấp thông tin chi tiết! Tôi hiểu rõ hơn về dự án chatbot iOS của bạn. Với mục tiêu phân phối trên App Store và phục vụ end-user, đây sẽ là một ứng dụng cần có **UX tốt, hiệu suất ổn định và tuân thủ các quy định của Apple**.

Để tiếp tục khai thác yêu cầu, tôi cần hiểu rõ hơn về một số khía cạnh quan trọng:

**1. Về mô hình kinh doanh và pricing:**

- Bạn dự định thu phí như thế nào? (freemium, subscription, one-time purchase, hay hoàn toàn miễn phí?)
- Ai sẽ chi trả chi phí API calls? Người dùng tự cung cấp API key hay app sẽ có API key chung và tính phí dựa trên usage?

**2. Về tính năng cốt lõi:**

- Với tính năng "knowledge base", bạn có muốn người dùng upload file PDF/document để chat không? Hay chỉ là lưu trữ thông tin từ các cuộc hội thoại?
- Tính năng "role-play bot" bạn hình dung như thế nào? Người dùng có thể tạo nhiều character khác nhau với personality riêng?

**3. Về platform và deployment:**

- Bạn có muốn hỗ trợ cả iPhone và iPad không? Có cần sync data giữa các thiết bị?
- Có dự định làm version macOS sau này không, hay chỉ tập trung iOS?

---

# - app miễn phí, mã nguồn mở

- người dùng tự chịu phí api key cá nhân
- Với tính năng "knowledge base", cho phép upload file pdf
- Người dùng có thể tạo nhiều character khác nhau với personality riêng
- hỗ trợ cả iPhone và iPad, có sync data giữa các thiết bị

Tuyệt vời! Bạn đã có một **vision rõ ràng** cho một chatbot iOS mã nguồn mở với tính năng phong phú. Việc để người dùng tự quản lý API key sẽ **giảm thiểu chi phí vận hành** và đảm bảo tính minh bạch.

Tôi cần làm rõ thêm một số yêu cầu quan trọng để có thể tạo tài liệu đặc tả đầy đủ:

**1. Về bảo mật và lưu trữ dữ liệu:**

- API keys của người dùng sẽ được lưu trữ như thế nào? (local trên device, encrypted keychain, hay cloud với encryption?)
- Dữ liệu sync giữa các thiết bị bạn dự định sử dụng iCloud hay self-hosted solution?

**2. Về khả năng xử lý file PDF:**

- Có giới hạn kích thước file PDF không? Và bạn có muốn hỗ trợ thêm các format khác như DOCX, TXT không?
- PDF sẽ được xử lý như thế nào - extract text để gửi cùng prompt, hay chunking và embedding cho RAG?

**3. Về timeline và phạm vi MVP:**

- Bạn có mong muốn về timeline phát triển không? Và trong phase đầu tiên, bạn muốn ưu tiên tính năng nào (basic chat, character creation, hay PDF upload)?

Sau khi có thêm thông tin này, tôi sẽ có thể tạo một tài liệu yêu cầu chi tiết và roadmap phát triển cho dự án của bạn.

---

# - API keys của người dùng sẽ được lưu local trên device

- có giới hạn kích thước file pdf, cụ thể hãy tham khảo các app phổ biến.  hỗ trợ thêm các format khác như DOCX, TXT, markdown (AI friendly format)
- PDF sẽ được xử lý như thế nào: extract text để gửi cùng prompt. giai đoạn 2 sẽ nâng cấp thành RAG
- phạm vi MVP: ưu tiên chat được với api key của OpenRouter, upload được ảnh, pdf

Hoàn hảo! Tôi đã thu thập được **tất cả thông tin cần thiết** để tạo tài liệu yêu cầu chi tiết cho dự án chatbot iOS của bạn.

Dựa trên thông tin search results, tôi thấy các giới hạn file phổ biến trong thị trường:

- **ChatGPT web**: 50MB và 150 pages[^4_1]
- **ChatGPT app**: 100MB[^4_1]
- **OpenAI GPT uploads**: 512MB per file[^4_2]
- **ChatPDF free**: 10MB, 120 pages[^4_3]
- **Các app khác**: từ 10MB đến 50MB[^4_4]

Với **MVP tập trung vào OpenRouter API + upload ảnh/PDF**, và **roadmap rõ ràng** (giai đoạn 1: extract text, giai đoạn 2: nâng cấp RAG), tôi có thể tạo một tài liệu đặc tả đầy đủ bao gồm:

✅ **Tổng quan dự án và mục tiêu**
✅ **Yêu cầu chức năng chi tiết**
✅ **Yêu cầu phi chức năng** (hiệu suất, bảo mật, UI/UX)
✅ **Kiến trúc kỹ thuật và Swift packages**
✅ **Roadmap phát triển theo giai đoạn**
✅ **Tiêu chí chấp nhận và test cases**

**Tôi đã thu thập được các thông tin cần thiết. Bạn có muốn tôi tạo tài liệu yêu cầu ngay bây giờ không?**

<div style="text-align: center">⁂</div>

[^4_1]: https://www.pdfgear.com/how-to/chatgpt-read-pdf.htm

[^4_2]: https://help.openai.com/en/articles/8983719-what-are-the-file-upload-size-restrictions

[^4_3]: https://www.xda-developers.com/ai-tools-chat-large-pdf-files/

[^4_4]: https://fliphtml5.com/learning-center/top-10-ai-pdf-chatbot/

[^4_5]: https://www.reddit.com/r/ChatGPTPro/comments/17r5atz/gpts_can_take_very_long_pdfs_over_900_pages/

[^4_6]: https://github.com/AkshayAcharyaN/Text_Summarizer_ChatBot

[^4_7]: https://www.helicone.ai/blog/pdf-chatbot-tutorial

[^4_8]: https://www.pageon.ai/blog/chat-with-pdf-locally

[^4_9]: https://apps.apple.com/us/app/chatbox-ai-chatbot-assistant/id6447763703

[^4_10]: https://dev.to/web_dev-usman/here-how-to-build-a-chatbot-for-free-using-openrouter-and-deepseek-apis-492e

[^4_11]: https://www.docsumo.com/blog/pdf-reading-with-gpt4

[^4_12]: https://www.wired.com/story/chatgpt-plus-image-feature-openai/

[^4_13]: https://www.reddit.com/r/ArtificialInteligence/comments/1gejp5o/i_built_a_native_ios_client_that_connects_all/

[^4_14]: https://www.youtube.com/watch?v=bqI6jP_yFOU

[^4_15]: https://www.zdnet.com/article/my-3-favorite-ai-chatbot-apps-for-ios-and-what-you-can-do-with-them/

[^4_16]: https://appsumo.com/products/chatmaxima/questions/limit-on-documents-for-training-the-chat-1351530/

[^4_17]: https://chatdoc.com

[^4_18]: https://docs.chatbotbuilder.ai/support/solutions/articles/150000193974-media-format-and-file-size-guide

[^4_19]: https://python.plainenglish.io/building-a-free-local-llm-chatbot-for-pdfs-docx-txt-files-and-text-input-8f24becdc0c3

[^4_20]: https://community.zapier.com/troubleshooting-99/chatbot-2mb-file-limit-workarounds-for-pdfs-45973

[^4_21]: https://hackernoon.com/lets-build-a-customer-support-chatbot-using-rag-and-your-companys-documentation-in-openwebui

[^4_22]: https://chatbotapp.ai

[^4_23]: https://3mw.albert-rapp.de/p/streaming-and-rendering-markdown

[^4_24]: https://community.openai.com/t/creating-a-bot-using-100-pdfs-as-the-knowledge-base/597237

[^4_25]: https://fastbots.ai

[^4_26]: https://www.reddit.com/r/selfhosted/comments/1gm68a1/need_help_setting_up_a_selfhosted_ai_chatbot_for/

[^4_27]: https://askyourpdf.com

[^4_28]: https://lacviet.vn/en/chatbot-ai/

[^4_29]: https://github.com/umbertogriffo/rag-chatbot

[^4_30]: https://chatboxai.app/en

[^4_31]: https://community.openai.com/t/how-chatbot-can-return-images-and-or-text-from-my-own-data-in-pdfs/308691

[^4_32]: https://www.langchain.ca/blog/custom-chatbot-to-query-pdf-documents-using-openai-and-langchain/

[^4_33]: https://collabnix.com/designing-a-chatbot-for-pdf-based-company-information/

[^4_34]: https://powell-software.com/resources/blog/which-chatbot-is-able-to-read-attached-pdf-files-for-free/

[^4_35]: https://www.diva-portal.org/smash/get/diva2:1892804/FULLTEXT01.pdf

[^4_36]: https://blog.getodin.ai/how-to-use-chatgpt-to-extract-data-from-pdfs/

[^4_37]: https://github.com/Techno-Guild/RAG-PDF-Chatbot

[^4_38]: https://www.agentx.so/post/can-chatbots-read-pdf-uncovering-the-technology-behind

[^4_39]: https://www.confident-ai.com/blog/how-to-build-a-pdf-qa-chatbot-using-openai-and-chromadb

[^4_40]: https://www.bluebash.co/blog/pdf-csv-chatbot-rag-langchain-streamlit/

[^4_41]: https://www.appypieagents.ai/chat-with-pdf-documents

[^4_42]: https://n8n.io/workflows/585-extract-text-from-a-pdf-file/

[^4_43]: https://arxiv.org/abs/2501.16276

[^4_44]: https://www.youtube.com/watch?v=OF6SolDiEwU

[^4_45]: https://www.linkedin.com/pulse/chatbot-using-natural-language-processing-pdf-url-mastery-najit-khan

[^4_46]: https://sider.ai/apps/ios

[^4_47]: https://apps.apple.com/no/app/chatbot-ai-chat-bot-image-scan/id6446196293

[^4_48]: https://pipedream.com/apps/openrouter/integrations/chatbot

[^4_49]: https://community.openai.com/t/i-always-get-an-error-when-upload-an-image-any-image/636578

[^4_50]: https://community.openai.com/t/ios-app-needs-image-support-with-shortcuts-app/1060277

[^4_51]: https://www.youtube.com/watch?v=1ePaytkXV1M

[^4_52]: https://apps.apple.com/vn/app/ai-chatbot-ai-chat-assistant/id6503696206

[^4_53]: https://www.reddit.com/r/ChatGPT/comments/14n09ph/personal_gpt_a_tiny_ai_chatbot_that_runs_fully/

[^4_54]: https://theresanaiforthat.com/s/chatbot+buider+with+image+upload+input/

[^4_55]: https://openrouter.ai

[^4_56]: https://www.reddit.com/r/OpenAI/comments/1fqujb2/chatgpt_4_plus_what_is_the_limit_of_pictures_i/

[^4_57]: https://openrouter.ai/docs/quickstart


---

# thêm các tính năng sau:

- Nhập và quản lý nhiều API key cá nhân
- Chuyển đổi nhanh giữa các model khác nhau
- Streaming response (hiển thị phản hồi theo thời gian thực)
- Lưu trữ và tổ chức hội thoại bằng folder
- Ghim hội thoại quan trọng
- Tìm kiếm trong lịch sử chat
- Lưu trữ dữ liệu cục bộ trên thiết bị
- Giữ lịch sử hội thoại an toàn
- Tạo assistant tùy chỉnh với prompt hệ thống riêng
- Thiết lập knowledge base riêng cho từng assistant
- Cấu hình tham số model (temperature, max tokens, etc.)
- Tạo template prompt có sẵn
- Đính kèm ảnh vào prompt
- Nhận diện văn bản trong ảnh (OCR)
- Phân tích nội dung hình ảnh
- Web Analyzer (tìm kiếm thông tin cập nhật từ internet)
- Phân tích nội dung YouTube
- Tóm tắt bài viết web
- Tìm kiếm thông tin real-time
- Hiển thị markdown đẹp
- Syntax highlighting cho code
- Export hội thoại (PDF, text, markdown)
- Lưu trữ API key cục bộ (không gửi lên server)
- Chỉ trả phí cho API usage thực tế (qua key cá nhân)
- quản lý chi phí gọi llm của từng conversation

Tuyệt vời! Bây giờ tôi có **đầy đủ thông tin** để tạo tài liệu yêu cầu hoàn chỉnh cho dự án chatbot iOS của bạn. Đây sẽ là một ứng dụng rất toàn diện với **hơn 30 tính năng** được phân loại rõ ràng.

# Tài Liệu Yêu Cầu Phần Mềm (SRS)

## Chatbot iOS với Tích Hợp Đa LLM API

## 1. TỔNG QUAN DỰ ÁN

### 1.1 Mục Tiêu Dự Án

Phát triển một **chatbot iOS native** mã nguồn mở, hỗ trợ đa LLM API provider, đặc biệt tối ưu cho **OpenRouter.ai**, nhằm cung cấp cho end-user một trải nghiệm AI chat toàn diện với khả năng tùy chỉnh cao.

### 1.2 Phạm Vi Dự Án

- **Platform**: iOS (iPhone + iPad) với Universal App
- **Phân phối**: App Store + mã nguồn mở
- **Mô hình kinh doanh**: Miễn phí, người dùng tự quản lý API key
- **Ngôn ngữ**: Swift với SwiftUI framework
- **Deployment**: iCloud sync để đồng bộ dữ liệu giữa thiết bị


### 1.3 Đối Tượng Người Dùng

- **Primary**: End-user cá nhân sử dụng AI chatbot
- **Secondary**: Developer muốn tùy chỉnh và đóng góp vào dự án mã nguồn mở


## 2. YÊU CẦU CHỨC NĂNG

### 2.1 Quản Lý API Key và Provider

**FR-001: Quản lý đa API Key**

- Cho phép nhập và lưu trữ nhiều API key từ các provider khác nhau
- Hỗ trợ provider: OpenRouter.ai (ưu tiên), OpenAI, Anthropic/Claude, Groq, Grok/xAI
- **Bảo mật**: Lưu trữ API key trong iOS Keychain với mã hóa AES-256[^5_1][^5_2]
- Label và phân loại API key theo provider và mục đích sử dụng

**FR-002: Chuyển đổi Model**

- Chuyển đổi nhanh giữa các model khác nhau trong cùng một conversation
- Hiển thị danh sách model có sẵn từ mỗi provider
- **Cost tracking**: Theo dõi chi phí theo từng model và conversation[^5_3][^5_4]


### 2.2 Giao Diện Chat và Tương Tác

**FR-003: Streaming Response**

- Hiển thị phản hồi AI theo thời gian thực với **WebSocket connection**[^5_5][^5_6]
- Progressive text generation với typing indicator
- Khả năng dừng generation khi cần thiết

**FR-004: Giao Diện Chat**

- UI/UX tối ưu cho iPhone và iPad
- Hỗ trợ **markdown rendering** và **syntax highlighting**[^5_7][^5_8]
- Copy code blocks, share conversations
- Dark mode và light mode support


### 2.3 Quản Lý Hội Thoại

**FR-005: Tổ chức Conversation**

- Lưu trữ và tổ chức hội thoại bằng **folder system**
- **Ghim hội thoại** quan trọng lên đầu danh sách
- Rename và archive conversations
- **Tìm kiếm** trong lịch sử chat với full-text search

**FR-006: Lưu Trữ Dữ Liệu**

- **Lưu trữ cục bộ** trên thiết bị với mã hóa[^5_9][^5_10]
- **iCloud sync** để đồng bộ giữa iPhone và iPad
- Backup và restore conversations
- **Auto-save** conversations real-time


### 2.4 Custom Assistant và Knowledge Base

**FR-007: Custom Assistant**

- Tạo assistant tùy chỉnh với **system prompt** riêng[^5_11][^5_12]
- **Role-play characters** với personality khác nhau
- Template prompt có sẵn cho các use case phổ biến
- **Model parameters**: temperature, max tokens, top-p, frequency penalty

**FR-008: Knowledge Base**

- Upload file: **PDF, DOCX, TXT, Markdown** (giới hạn **50MB** per file)[^5_13]
- **OCR integration**: Nhận diện văn bản trong ảnh[^5_14][^5_15][^5_16]
- **Text extraction** từ document để gửi cùng prompt
- **Giai đoạn 2**: Nâng cấp thành RAG system[^5_17][^5_3]


### 2.5 Xử Lý Multimedia

**FR-009: Image Processing**

- **Đính kèm ảnh** vào prompt với preview
- **OCR**: Trích xuất text từ ảnh sử dụng **Vision API** (iOS native)[^5_15][^5_16]
- **Image analysis**: Phân tích nội dung hình ảnh với vision models[^5_18]
- Hỗ trợ multiple image attachments

**FR-010: Web Integration**

- **Web Analyzer**: Tìm kiếm thông tin cập nhật từ internet
- **YouTube content analysis**: Phân tích transcript video
- **Article summarization**: Tóm tắt bài viết web
- **Real-time search**: Tích hợp search engine results


### 2.6 Export và Sharing

**FR-011: Export Conversations**

- Export format: **PDF, TXT, Markdown**
- Preserve formatting và code syntax highlighting
- **Share conversations** qua iOS Share Sheet
- **Print support** cho conversations


### 2.7 Cost Management

**FR-012: Cost Tracking**

- **Theo dõi chi phí** theo từng conversation[^5_3][^5_4]
- **Token usage monitoring** real-time
- **Cost breakdown** theo model và provider
- **Budget alerts** khi đạt ngưỡng chi phí


## 3. YÊU CẦU PHI CHỨC NĂNG

### 3.1 Hiệu Suất (Performance)

**NFR-001: Response Time**

- Streaming response latency < 200ms
- App launch time < 2 seconds
- Smooth scrolling trong long conversations

**NFR-002: File Processing**

- PDF processing < 5 seconds cho file 10MB
- OCR processing < 3 seconds cho standard image
- Batch file upload support


### 3.2 Bảo Mật (Security)

**NFR-003: Data Protection**

- API key encryption sử dụng **iOS Keychain**[^5_1][^5_2]
- Local data encryption với **FileProtectionComplete**[^5_10]
- No API key transmission to external servers
- **Biometric authentication** option (Face ID/Touch ID)


### 3.3 Khả Năng Sử Dụng (Usability)

**NFR-004: User Experience**

- **iOS Human Interface Guidelines** compliance
- **Accessibility support** (VoiceOver, Dynamic Type)
- **Haptic feedback** cho user interactions
- **Error handling** với user-friendly messages


### 3.4 Tương Thích (Compatibility)

**NFR-005: Platform Support**

- **iOS 15.0+** minimum requirement
- **Universal App**: iPhone và iPad optimization
- **iCloud sync** cross-device compatibility
- **App Store** submission compliance


## 4. KIẾN TRÚC KỸ THUẬT

### 4.1 Technology Stack

**Frontend**: SwiftUI + Combine
**Data Layer**: Core Data + CloudKit
**Security**: iOS Keychain Services
**Networking**: URLSession + WebSocket
**File Processing**: PDFKit + Vision Framework

### 4.2 Swift Packages Dependencies

```swift
// Networking & API
.package(url: "https://github.com/Alamofire/Alamofire")

// Markdown Rendering
.package(url: "https://github.com/gonzalezreal/swift-markdown-ui")

// Syntax Highlighting
.package(url: "https://github.com/raspu/Highlightr")

// PDF Processing
.package(url: "https://github.com/PSPDFKit/PSPDFKit-iOS")

// OCR Enhancement
.package(url: "https://github.com/tesseract-ocr/tesseract")

// Cost Monitoring
.package(url: "https://github.com/realm/realm-swift")
```


### 4.3 Kiến Trúc Ứng Dụng

```
├── Core/
│   ├── APIManager (Multi-provider support)
│   ├── DataManager (Core Data + CloudKit)
│   ├── SecurityManager (Keychain + Encryption)
│   └── CostTracker (Usage monitoring)
├── Features/
│   ├── Chat/ (Conversation UI)
│   ├── Assistant/ (Custom bot creation)
│   ├── Documents/ (File processing)
│   ├── Settings/ (Configuration)
│   └── Export/ (Share & Export)
├── Utils/
│   ├── Extensions/
│   ├── Helpers/
│   └── Constants/
└── Resources/
```


## 5. ROADMAP PHÁT TRIỂN

### 5.1 MVP (Giai Đoạn 1) - 8 tuần

**Tuần 1-2: Core Infrastructure**

- Project setup + Swift package integration
- API key management với Keychain
- Basic OpenRouter API integration

**Tuần 3-4: Chat Interface**

- SwiftUI chat UI với streaming support
- Basic conversation management
- Markdown rendering + syntax highlighting

**Tuần 5-6: File Processing**

- PDF/image upload và OCR
- Text extraction và prompt integration
- Cost tracking basic implementation

**Tuần 7-8: Polish \& Testing**

- UI/UX refinement
- Error handling và edge cases
- App Store submission preparation


### 5.2 V2.0 (Giai Đoạn 2) - 6 tuần

**Advanced Features**

- RAG system implementation
- Web integration (search, YouTube, articles)
- Advanced custom assistant features
- Enhanced export options


### 5.3 V3.0 (Giai Đoạn 3) - 4 tuần

**Enterprise Features**

- Advanced cost analytics
- Team sharing capabilities
- API provider expansion
- Performance optimizations


## 6. TIÊU CHÍ CHẤP NHẬN

### 6.1 MVP Acceptance Criteria

✅ **Core Chat**: Successful chat với OpenRouter API, streaming response
✅ **File Upload**: PDF (≤50MB) và image upload với OCR
✅ **Security**: API key stored securely trong Keychain
✅ **UI/UX**: Responsive design cho iPhone/iPad
✅ **Cost Tracking**: Basic token usage monitoring
✅ **Export**: Export conversation as PDF/text

### 6.2 Quality Assurance

- **Unit tests** coverage ≥80%
- **UI tests** cho critical user flows
- **Performance testing** với large conversations
- **Security audit** cho API key handling
- **App Store review** compliance check


## 7. RỦIRO VÀ GIẢI PHÁP

### 7.1 Technical Risks

**API Rate Limiting**: Implement exponential backoff và user notifications
**Large File Processing**: Chunk processing và progress indicators
**Memory Management**: Optimize for large conversations và file uploads

### 7.2 Business Risks

**App Store Approval**: Ensure compliance với Apple guidelines
**User Privacy**: Clear privacy policy về data handling
**Cost Management**: Educate users về API usage costs

**Bạn có muốn tôi đặt thêm câu hỏi để làm rõ hoặc bổ sung thông tin nào không?**

<div style="text-align: center">⁂</div>

[^5_1]: https://capgo.app/blog/api-key-security-for-app-store-compliance/

[^5_2]: https://dev.to/msiatrak/securing-api-keys-in-swiftui-a-practical-guide-intro-3f91

[^5_3]: https://www.helicone.ai/blog/monitor-and-optimize-llm-costs

[^5_4]: https://www.reddit.com/r/node/comments/1eawb2i/how_to_track_api_usage_and_costs_for_individual/

[^5_5]: https://docs.aws.amazon.com/solutions/latest/qnabot-on-aws/llm-streaming-responses.html

[^5_6]: https://dev.to/pranshu_kabra_fe98a73547a/streaming-responses-in-ai-how-ai-outputs-are-generated-in-real-time-18kb

[^5_7]: https://www.youtube.com/watch?v=DYD6_3JD7jk

[^5_8]: https://alfianlosari.com/posts/add-markdown-and-code-syntax-higlighting-chatgpt-swiftui-ios-app

[^5_9]: https://www.newsoftwares.net/blog/is-local-data-on-iphone-secure/

[^5_10]: https://mas.owasp.org/MASTG/0x06d-Testing-Data-Storage/

[^5_11]: https://theonetechnologies.com/blog/post/top-features-to-include-in-a-chatbot-app

[^5_12]: https://customgpt.ai/ai-knowledge-base-chatbots/

[^5_13]: https://www.proprofschat.com/blog/chatbot-features/

[^5_14]: https://docs.scanbot.io/document-scanner-sdk/ios/features/optical-character-recognition/

[^5_15]: https://scanbot.io/developer/ios-data-capture/ocr-library/

[^5_16]: https://www.designveloper.com/blog/mobile-ocr-libraries/

[^5_17]: https://slite.com/en/learn/knowledge-base-chatbot

[^5_18]: https://www.appcoda.com/swiftui-image-recognition/

[^5_19]: https://www.edenai.co/advanced-features/multi-api-key-management

[^5_20]: https://github.com/discord/discord-api-docs/discussions/6310

[^5_21]: https://www.reddit.com/r/swift/comments/15zre75/how_should_i_store_an_api_key/

[^5_22]: https://softblues.io/blog/llm-api-for-ai-chatbots/

[^5_23]: https://www.chatbot.com/features/

[^5_24]: https://www.tidio.com/blog/chatbot-features/

[^5_25]: https://sendbird.com/docs/chat/uikit/v3/ios-uikit/features/ai-chatbot

[^5_26]: https://www.linkedin.com/pulse/what-makes-chatbot-advanced-key-features-beyond-systems-mishra-uu1af

[^5_27]: https://fpt.ai/blogs/dialog-management/

[^5_28]: https://python.langchain.com/docs/tutorials/chatbot/

[^5_29]: https://vasundhara.io/blogs/ai-chatbot-integration-into-ios-apps

[^5_30]: https://chatbotapp.ai

[^5_31]: https://community.openai.com/t/how-can-i-use-one-api-key-to-establish-conversations-with-multiple-people-without-mixing/571982

[^5_32]: https://masterofcode.com/blog/chatbot-features

[^5_33]: https://www.nngroup.com/articles/prompt-controls-genai/

[^5_34]: https://helpcrunch.com/blog/chatbot-features/

[^5_35]: https://www.socialintents.com/blog/ai-chatbot-features/

[^5_36]: https://www.freecodecamp.org/news/build-a-conversational-ai-chatbot-with-stream-chat-and-react/

[^5_37]: https://python.langchain.com/docs/how_to/chat_streaming/

[^5_38]: https://getstream.io/blog/ios-assistant/

[^5_39]: https://docs.streamlit.io/develop/tutorials/chat-and-llm-apps/build-conversational-apps

[^5_40]: https://www.vendasta.com/blog/ai-chatbot-for-website/

[^5_41]: https://www.yeschat.ai/gpts-9t557fXbj1w-Video-Chatbot

[^5_42]: https://docs.ray.io/en/latest/serve/tutorials/streaming.html

[^5_43]: https://apps.apple.com/vn/app/chatbot-ai-open-assistant/id6472981037

[^5_44]: https://livechatai.com/blog/chatbot-features

[^5_45]: https://n8n.io/workflows/2956-ultimate-ai-powered-chatbot-for-youtube-summarization-and-analysis/

[^5_46]: https://ai-sdk.dev/cookbook/next/markdown-chatbot-with-memoization

[^5_47]: https://www.reddit.com/r/ChatGPT/comments/1h3bh0o/heres_syntax_highlighting_fix_for_web_chatgpt/

[^5_48]: https://sendbird.com/docs/ai-chatbot/platform-api/v3/managing-bot-messages/send-streaming-message

[^5_49]: https://codecrew.codewithchris.com/t/how-to-secure-api-keys/25110

[^5_50]: https://stackoverflow.com/questions/36188627/storing-api-keys-in-the-cloud-for-an-ios-app

[^5_51]: https://axiashift.com/mastering-llm-api-cost-estimation-a-comprehensive-guide-for-businesses

[^5_52]: https://symflower.com/en/company/blog/2024/managing-llm-costs/

[^5_53]: https://www.toolify.ai/compare/api-usage-vs-ai-powered-chatbot-for-websites

[^5_54]: https://support.apple.com/en-vn/108353

[^5_55]: https://www.reddit.com/r/llmops/comments/18cd2rw/how_to_monitor_llm_api_usage_and_cost_management/

[^5_56]: https://blog.encoded.life/safely-distributing-api-keys-in-your-mobile-app

[^5_57]: https://mongoosemedia.us/cost-to-connect-api-with-ai-chatbot/

[^5_58]: https://support.apple.com/en-vn/guide/security/sece3bee0835/web

[^5_59]: https://www.usageguard.com/resources/articles/how-to-optimize-costs-for-llm-api-usage

[^5_60]: https://developer.apple.com/documentation/security/storing-keys-in-the-keychain

