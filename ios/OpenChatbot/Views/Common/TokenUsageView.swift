import SwiftUI

struct TokenUsageView: View {
    let tokenUsage: TokenUsage
    let warningLevel: TokenWarningLevel
    let modelName: String
    
    @State private var showDetails = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Token icon with warning color
            Image(systemName: "doc.text.fill")
                .foregroundColor(warningColor)
                .font(.system(size: 14))
            
            // Usage percentage
            Text("\(Int(tokenUsage.usagePercentage))%")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(warningColor)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(warningColor)
                        .frame(width: geometry.size.width * CGFloat(tokenUsage.usagePercentage / 100), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: tokenUsage.usagePercentage)
                }
            }
            .frame(width: 80, height: 6)
            
            // Model name (abbreviated)
            Text(abbreviatedModelName)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 60)
            
            // Info button
            Button(action: { showDetails.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(warningColor.opacity(warningLevel == .critical ? 0.5 : 0), lineWidth: 1)
        )
        .sheet(isPresented: $showDetails) {
            TokenUsageDetailView(
                tokenUsage: tokenUsage,
                warningLevel: warningLevel,
                modelName: modelName
            )
        }
    }
    
    private var warningColor: Color {
        switch warningLevel {
        case .normal:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
    
    private var abbreviatedModelName: String {
        // Abbreviate common model names
        if modelName.contains("gpt-4o") {
            return "GPT-4o"
        } else if modelName.contains("gpt-4") {
            return "GPT-4"
        } else if modelName.contains("gpt-3.5") {
            return "GPT-3.5"
        } else if modelName.contains("claude") {
            return "Claude"
        } else if modelName.contains("llama") {
            return "Llama"
        } else {
            // Take first word or first 8 characters
            let words = modelName.split(separator: " ")
            if let firstWord = words.first {
                return String(firstWord.prefix(8))
            }
            return String(modelName.prefix(8))
        }
    }
}

struct TokenUsageDetailView: View {
    let tokenUsage: TokenUsage
    let warningLevel: TokenWarningLevel
    let modelName: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(warningColor)
                    
                    Text("Token Usage")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(modelName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Usage Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(tokenUsage.usagePercentage / 100))
                        .stroke(warningColor, lineWidth: 20)
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: tokenUsage.usagePercentage)
                    
                    VStack {
                        Text("\(Int(tokenUsage.usagePercentage))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(warningColor)
                        
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Details
                VStack(spacing: 16) {
                    DetailRow(
                        icon: "arrow.up.circle",
                        label: "Current Tokens",
                        value: "\(tokenUsage.current.formatted())",
                        color: .primary
                    )
                    
                    DetailRow(
                        icon: "checkmark.circle",
                        label: "Available Tokens",
                        value: "\(tokenUsage.available.formatted())",
                        color: .green
                    )
                    
                    DetailRow(
                        icon: "lock.circle",
                        label: "Reserved for Response",
                        value: "\(tokenUsage.reserved.formatted())",
                        color: .orange
                    )
                    
                    DetailRow(
                        icon: "chart.bar.circle",
                        label: "Maximum Tokens",
                        value: "\(tokenUsage.maximum.formatted())",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Warning message
                if warningLevel != .normal {
                    HStack {
                        Image(systemName: warningIcon)
                            .foregroundColor(warningColor)
                        
                        Text(warningMessage)
                            .font(.caption)
                            .foregroundColor(warningColor)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(warningColor.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var warningColor: Color {
        switch warningLevel {
        case .normal:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
    
    private var warningIcon: String {
        switch warningLevel {
        case .normal:
            return "checkmark.circle"
        case .medium:
            return "exclamationmark.circle"
        case .high:
            return "exclamationmark.triangle"
        case .critical:
            return "xmark.circle"
        }
    }
    
    private var warningMessage: String {
        switch warningLevel {
        case .normal:
            return "Token usage is within normal range"
        case .medium:
            return "Token usage is moderate. Consider summarizing older messages."
        case .high:
            return "Token usage is high. Automatic compression may be applied soon."
        case .critical:
            return "Token limit nearly reached! Messages will be compressed to fit."
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

struct TokenUsageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TokenUsageView(
                tokenUsage: TokenUsage(
                    current: 2500,
                    maximum: 4096,
                    reserved: 1000,
                    available: 596
                ),
                warningLevel: .medium,
                modelName: "gpt-3.5-turbo"
            )
            
            TokenUsageView(
                tokenUsage: TokenUsage(
                    current: 3900,
                    maximum: 4096,
                    reserved: 1000,
                    available: 196
                ),
                warningLevel: .critical,
                modelName: "claude-3-sonnet"
            )
            
            TokenUsageView(
                tokenUsage: TokenUsage(
                    current: 1000,
                    maximum: 128000,
                    reserved: 1000,
                    available: 126000
                ),
                warningLevel: .normal,
                modelName: "gpt-4o"
            )
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
} 