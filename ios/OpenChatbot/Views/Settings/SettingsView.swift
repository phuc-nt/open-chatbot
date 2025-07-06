import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("⚙️ Cài đặt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tab Settings đã hoạt động!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Các tùy chọn cài đặt sẽ xuất hiện ở đây")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Cài đặt")
        }
    }
}

#Preview {
    SettingsView()
} 