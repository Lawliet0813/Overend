//
//  EmeraldAIAssistantView.swift
//  OVEREND
//
//  Emerald AI Assistant - AI 助手對話面板
//

import SwiftUI

// MARK: - 主視圖

struct EmeraldAIAssistantView: View {
    @EnvironmentObject var theme: AppTheme
    
    @State private var messages: [EmeraldChatMessage] = EmeraldChatMessage.sampleMessages
    @State private var inputText = ""
    @State private var isTyping = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HeaderBar()
            
            // 對話區域
            ChatArea(messages: messages, isTyping: isTyping)
            
            // 快速操作
            QuickActions()
            
            // 輸入區域
            InputBar(text: $inputText, onSend: sendMessage)
        }
        .background(EmeraldTheme.backgroundDark)
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newMessage = EmeraldChatMessage(
            id: UUID(),
            content: inputText,
            isUser: true,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3)) {
            messages.append(newMessage)
        }
        
        inputText = ""
        isTyping = true
        
        // 模擬 AI 回應
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = EmeraldChatMessage(
                id: UUID(),
                content: "我理解你的問題。讓我為你分析這個段落的學術風格，並提供改進建議...",
                isUser: false,
                timestamp: Date(),
                suggestions: ["改善段落結構", "增加文獻引用", "調整語氣"]
            )
            
            withAnimation(.spring(response: 0.3)) {
                isTyping = false
                messages.append(response)
            }
        }
    }
}

// MARK: - 訊息模型

struct EmeraldChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var codeBlock: String? = nil
    var suggestions: [String]? = nil
    
    static let sampleMessages: [EmeraldChatMessage] = [
        EmeraldChatMessage(
            id: UUID(),
            content: "如何改善這段學術寫作的風格？",
            isUser: true,
            timestamp: Date().addingTimeInterval(-120)
        ),
        EmeraldChatMessage(
            id: UUID(),
            content: "我可以幫你分析並改善學術寫作風格。以下是一些建議：\n\n1. **使用主動語態** - 讓句子更清晰有力\n2. **避免贅字** - 精簡表達\n3. **增加文獻支持** - 加強論點可信度",
            isUser: false,
            timestamp: Date().addingTimeInterval(-60)
        ),
        EmeraldChatMessage(
            id: UUID(),
            content: "可以給我一個程式碼範例嗎？",
            isUser: true,
            timestamp: Date().addingTimeInterval(-30)
        ),
        EmeraldChatMessage(
            id: UUID(),
            content: "當然！這裡是一個引用格式處理的範例：",
            isUser: false,
            timestamp: Date(),
            codeBlock: """
            func formatCitation(author: String, year: Int) -> String {
                let citation = "(\\(author), \\(year))"
                return citation
            }
            """,
            suggestions: ["複製程式碼", "解釋程式碼", "查找相關文獻"]
        )
    ]
}

// MARK: - 標題列

struct HeaderBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(EmeraldTheme.primary.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(EmeraldTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACADEMIC AI ASSISTANT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text("Powered by GPT-4 Turbo")
                        .font(.system(size: 10))
                        .foregroundColor(EmeraldTheme.textMuted)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(EmeraldTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(EmeraldTheme.surfaceDark)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(EmeraldTheme.surfaceDark)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(EmeraldTheme.surfaceDark.opacity(0.5))
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - 對話區域

struct ChatArea: View {
    let messages: [EmeraldChatMessage]
    let isTyping: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                    
                    if isTyping {
                        TypingBubble()
                    }
                }
                .padding(20)
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - 訊息氣泡

struct MessageBubble: View {
    let message: EmeraldChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
                // AI 頭像
                ZStack {
                    Circle()
                        .fill(EmeraldTheme.surfaceDark)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(EmeraldTheme.primary)
                }
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // 訊息內容
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey(message.content))
                        .font(.system(size: 14))
                        .foregroundColor(message.isUser ? .white : EmeraldTheme.textSecondary)
                        .lineSpacing(4)
                    
                    // 程式碼區塊
                    if let codeBlock = message.codeBlock {
                        CodeBlockView(code: codeBlock)
                    }
                    
                    // 建議按鈕
                    if let suggestions = message.suggestions {
                        SuggestionChips(suggestions: suggestions)
                    }
                }
                .padding(16)
                .background(
                    message.isUser ?
                    EmeraldTheme.primary.opacity(0.15) :
                    EmeraldTheme.surfaceDark.opacity(0.8)
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            message.isUser ? EmeraldTheme.borderAccent : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
            }
            .frame(maxWidth: 500, alignment: message.isUser ? .trailing : .leading)
            
            if message.isUser {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - 程式碼區塊

struct CodeBlockView: View {
    let code: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("swift")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(EmeraldTheme.textMuted)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(EmeraldTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(EmeraldTheme.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(EmeraldTheme.backgroundDark)
                .cornerRadius(8)
        }
    }
}

// MARK: - 建議按鈕

struct SuggestionChips: View {
    let suggestions: [String]
    
    var body: some View {
        EmeraldFlowLayout(spacing: 8) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {}) {
                    Text(suggestion)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(EmeraldTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(EmeraldTheme.backgroundDark)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .scaleOnHover(1.05)
            }
        }
    }
}

// MARK: - Flow Layout

struct EmeraldFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - 打字中氣泡

struct TypingBubble: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(EmeraldTheme.surfaceDark)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(EmeraldTheme.primary)
            }
            
            HStack(spacing: 8) {
                TypingIndicator()
            }
            .padding(16)
            .background(EmeraldTheme.surfaceDark.opacity(0.8))
            .cornerRadius(16)
            
            Spacer()
        }
    }
}

// MARK: - 快速操作

struct QuickActions: View {
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "doc.text", title: "Summarize")
            QuickActionButton(icon: "globe", title: "Translate")
            QuickActionButton(icon: "checkmark.circle", title: "Proofread")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(EmeraldTheme.surfaceDark.opacity(0.3))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? EmeraldTheme.primary : EmeraldTheme.textSecondary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isHovered ? EmeraldTheme.primary : EmeraldTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovered ? EmeraldTheme.primary.opacity(0.1) : EmeraldTheme.surfaceDark)
            .cornerRadius(999)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(isHovered ? EmeraldTheme.borderAccent : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 輸入區域

struct InputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 附件按鈕
            Button(action: {}) {
                Image(systemName: "paperclip")
                    .font(.system(size: 18))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            
            // 輸入框
            TextField("輸入你的問題...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(EmeraldTheme.surfaceDark)
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .onSubmit(onSend)
            
            // 發送按鈕
            Button(action: onSend) {
                Text("Send")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(text.isEmpty ? EmeraldTheme.textMuted : EmeraldTheme.backgroundDark)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(text.isEmpty ? EmeraldTheme.surfaceDark : EmeraldTheme.primary)
                    .cornerRadius(999)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(EmeraldTheme.surfaceDark.opacity(0.5))
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Preview

#Preview {
    EmeraldAIAssistantView()
        .environmentObject(AppTheme())
        .frame(width: 600, height: 800)
}
