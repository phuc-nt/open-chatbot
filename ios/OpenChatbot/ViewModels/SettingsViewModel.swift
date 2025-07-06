import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var apiKeys: [APIKey] = []
    @Published var isDarkMode = false
    @Published var notificationsEnabled = true
    @Published var showAddAPIKey = false
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        apiKeys = [
            APIKey(name: "OpenRouter Key", provider: .openRouter),
            APIKey(name: "OpenAI Key", provider: .openAI)
        ]
    }
} 