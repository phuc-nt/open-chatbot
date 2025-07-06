import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("📝 Lịch sử Chat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tab History đã hoạt động!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Các cuộc trò chuyện sẽ xuất hiện ở đây")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Lịch sử")
        }
    }
}

#Preview {
    HistoryView()
} 