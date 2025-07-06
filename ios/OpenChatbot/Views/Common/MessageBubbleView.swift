import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(isUser ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        MessageBubbleView(message: Message(content: "Hello! This is a user message.", role: .user, conversationId: UUID()))
        MessageBubbleView(message: Message(content: "This is an assistant response with a longer message to test the bubble layout.", role: .assistant, conversationId: UUID()))
    }
    .padding()
} 