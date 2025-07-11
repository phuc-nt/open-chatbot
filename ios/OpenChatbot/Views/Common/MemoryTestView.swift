import SwiftUI

struct MemoryTestView: View {
    @StateObject private var memoryService = MemoryService()
    @State private var testResults: [String] = []
    @State private var isRunning = false
    @State private var currentTest = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Memory System Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Kiểm tra ConversationBufferMemory")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Test Status
                if isRunning {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Đang chạy: \(currentTest)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Control Buttons
                HStack(spacing: 16) {
                    Button("Chạy Test Cơ bản") {
                        Task {
                            await runBasicTests()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)
                    
                    Button("Test Memory Full") {
                        Task {
                            await runFullMemoryTest()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunning)
                    
                    Button("Xóa Log") {
                        testResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunning)
                }
                .padding(.horizontal)
                
                // Memory Service Status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(memoryService.isMemoryEnabled ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text("Memory Service: \(memoryService.isMemoryEnabled ? "Enabled" : "Disabled")")
                            .font(.caption)
                    }
                    
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text("Status: \(statusText)")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Test Results
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(testResults, id: \.self) { result in
                            HStack {
                                if result.contains("✅") {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                } else if result.contains("❌") {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                } else if result.contains("🧠") {
                                    Image(systemName: "brain")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                } else {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                
                                Text(result)
                                    .font(.system(.caption, design: .monospaced))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Memory Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var statusColor: Color {
        switch memoryService.memoryStatus {
        case .idle: return .gray
        case .loading: return .orange
        case .ready: return .green
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch memoryService.memoryStatus {
        case .idle: return "Idle"
        case .loading: return "Loading"
        case .ready: return "Ready"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    // MARK: - Test Functions
    
    private func addTestResult(_ message: String) {
        DispatchQueue.main.async {
            testResults.append(message)
        }
    }
    
    private func runBasicTests() async {
        isRunning = true
        testResults.removeAll()
        
        currentTest = "Kiểm tra cơ bản"
        addTestResult("🧠 Bắt đầu test Memory System...")
        
        // Test 1: Service Initialization
        addTestResult("Test 1: Khởi tạo MemoryService")
        if memoryService.isMemoryEnabled {
            addTestResult("✅ MemoryService được khởi tạo thành công")
        } else {
            addTestResult("❌ MemoryService không được enable")
            isRunning = false
            return
        }
        
        // Test 2: Conversation Memory Creation
        currentTest = "Tạo Conversation Memory"
        addTestResult("Test 2: Tạo Conversation Memory")
        
        let conversationId = UUID()
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        if memory.conversationId == conversationId {
            addTestResult("✅ Conversation Memory được tạo với ID đúng")
        } else {
            addTestResult("❌ Conversation Memory có ID sai")
        }
        
        if memory.messageCount == 0 {
            addTestResult("✅ Memory mới không có message nào")
        } else {
            addTestResult("❌ Memory mới đã có \(memory.messageCount) messages")
        }
        
        // Test 3: Add Message
        currentTest = "Thêm message vào memory"
        addTestResult("Test 3: Thêm message vào memory")
        
        let testMessage = Message(
            content: "Xin chào! Đây là test message cho memory system.",
            role: .user,
            conversationId: conversationId
        )
        
        await memoryService.addMessageToMemory(testMessage, conversationId: conversationId)
        
        let updatedMemory = await memoryService.getMemoryForConversation(conversationId)
        if updatedMemory.messageCount == 1 {
            addTestResult("✅ Message được thêm thành công")
        } else {
            addTestResult("❌ Message không được thêm. Count: \(updatedMemory.messageCount)")
        }
        
        if let firstMessage = updatedMemory.messages.first,
           firstMessage.content == testMessage.content {
            addTestResult("✅ Nội dung message chính xác")
        } else {
            addTestResult("❌ Nội dung message không đúng")
        }
        
        // Test 4: Memory Stats
        currentTest = "Kiểm tra Memory Stats"
        addTestResult("Test 4: Memory Statistics")
        
        let stats = await memoryService.getMemoryStats(for: conversationId)
        addTestResult("📊 Message count: \(stats.messageCount)")
        addTestResult("📊 Estimated tokens: \(stats.estimatedTokens)")
        addTestResult("📊 Cache status: \(stats.cacheStatus)")
        
        if stats.messageCount > 0 {
            addTestResult("✅ Memory stats hoạt động đúng")
        } else {
            addTestResult("❌ Memory stats không chính xác")
        }
        
        currentTest = "Hoàn thành"
        addTestResult("🎉 Test cơ bản hoàn thành!")
        isRunning = false
    }
    
    private func runFullMemoryTest() async {
        isRunning = true
        testResults.removeAll()
        
        addTestResult("🧠 Bắt đầu Full Memory Test...")
        
        let conversationId = UUID()
        
        // Test nhiều messages
        currentTest = "Thêm nhiều messages"
        addTestResult("Test: Thêm 10 messages để test token limit")
        
        for i in 1...10 {
            let message = Message(
                content: "Đây là message số \(i). Nội dung này được tạo để test khả năng quản lý token và memory của hệ thống. Message này có độ dài trung bình để mô phỏng cuộc trò chuyện thực tế.",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
            addTestResult("➕ Đã thêm message \(i)")
        }
        
        // Test Token Limit
        currentTest = "Test token limits"
        addTestResult("Test: Token limit management")
        
        let limits = [50, 100, 500, 1000, 4000]
        for limit in limits {
            let context = await memoryService.getContextForAPICall(
                conversationId: conversationId,
                maxTokens: limit
            )
            addTestResult("🎯 Token limit \(limit): \(context.count) messages")
        }
        
        // Test Memory Clear
        currentTest = "Test memory clear"
        addTestResult("Test: Clear memory cache")
        
        memoryService.clearMemory(for: conversationId)
        addTestResult("🗑️ Memory cache cleared")
        
        // Reload memory
        let reloadedMemory = await memoryService.getMemoryForConversation(conversationId)
        addTestResult("🔄 Memory reloaded: \(reloadedMemory.messageCount) messages")
        
        currentTest = "Hoàn thành"
        addTestResult("🎉 Full Memory Test hoàn thành!")
        isRunning = false
    }
}

// MARK: - Preview
struct MemoryTestView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryTestView()
    }
} 