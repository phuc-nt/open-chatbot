import SwiftUI

// MARK: - App State for Tab Navigation
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedConversationID: String?
    
    func switchToChatTab(withConversation conversationID: String? = nil) {
        selectedConversationID = conversationID
        selectedTab = 0  // Switch to Chat tab
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
                .tag(0)
                .environmentObject(appState)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
                .tag(1)
                .environmentObject(appState)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
} 