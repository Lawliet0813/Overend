//
//  WriterAIAssistantView.swift
//  OVEREND
//
//  編輯器 AI 寫作助手 - 提供即時寫作輔助
//

import SwiftUI

/// 編輯器 AI 助手面板
struct WriterAIAssistantView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AppleAIService.shared
    
    @Binding var selectedText: String
    var onInsertText: (String) -> Void
    
    @State private var selectedAction: WriterAIAction = .improve
    @State private var result: String = ""
    @State private var customPrompt: String = ""
    
    enum WriterAIAction: String, CaseIterable {
        case improve = "潤飾"
        case expand = "擴寫"
        case summarize = "精簡"
        case proofread = "校對"
        case translate = "翻譯"
        case custom = "自訂"
        
        var icon: String {
            switch self {
            case .improve: return "wand.and.stars"
            case .expand: return "text.badge.plus"
            case .summarize: return "text.badge.minus"
            case .proofread: return "checkmark.circle"
            case .translate: return "globe"
            case .custom: return "text.bubble"
            }
        }
        
        var prompt: String {
            switch self {
            case .improve: 
                return "請潤飾以下學術寫作，提升表達的流暢度和學術性，保持原意不變，使用繁體中文："
            case .expand:
                return "請擴寫以下內容，增加更多細節和論述，保持學術風格，使用繁體中文："
            case .summarize:
                return "請精簡以下內容，保留核心論點，使其更加簡潔，使用繁體中文："
            case .proofread:
                return "請校對以下文字，指出語法錯誤、標點符號問題和建議修正，使用繁體中文："
            case .translate:
                return "請將以下內容翻譯成繁體中文，保持學術風格和原意："
            case .custom:
                return ""
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent)
                    
                    Text("AI 寫作助手")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                // 可用性指示
                if aiService.isAvailable {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("已就緒")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                    }
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                        .padding(4)
                        .background(Circle().fill(theme.itemHover))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(theme.toolbar)
            
            Divider()
            
            // 功能選擇
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WriterAIAction.allCases, id: \.self) { action in
                        Button(action: { selectedAction = action }) {
                            VStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 16))
                                Text(action.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedAction == action ? .white : theme.textPrimary)
                            .frame(width: 60, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedAction == action ? theme.accent : theme.itemHover)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            
            Divider()
            
            // 內容區
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 原文
                    VStack(alignment: .leading, spacing: 8) {
                        Text("選取的文字")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.textMuted)
                        
                        if selectedText.isEmpty {
                            Text("請先在編輯器中選取要處理的文字")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textMuted)
                                .italic()
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme.itemHover)
                                )
                        } else {
                            Text(selectedText)
                                .font(.system(size: 14))
                                .foregroundColor(theme.textPrimary)
                                .lineSpacing(4)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(theme.border, lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    // 自訂提示（僅自訂模式顯示）
                    if selectedAction == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自訂指令")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(theme.textMuted)
                            
                            TextField("例如：改寫成更正式的語氣", text: $customPrompt)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 14))
                        }
                    }
                    
                    // 執行按鈕
                    Button(action: processText) {
                        HStack {
                            if aiService.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("處理中...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("AI \(selectedAction.rawValue)")
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedText.isEmpty || !aiService.isAvailable ? Color.gray : theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedText.isEmpty || !aiService.isAvailable || aiService.isProcessing)
                    
                    // 結果
                    if !result.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("AI 結果")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(theme.textMuted)
                                
                                Spacer()
                                
                                Button(action: copyResult) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 15))
                                        .foregroundColor(theme.accent)
                                }
                                .buttonStyle(.plain)
                                .help("複製")
                            }
                            
                            Text(result)
                                .font(.system(size: 14))
                                .foregroundColor(theme.textPrimary)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme.accentLight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            // 操作按鈕
                            HStack(spacing: 12) {
                                Button(action: insertResult) {
                                    HStack {
                                        Image(systemName: "arrow.turn.down.left")
                                        Text("取代原文")
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(theme.accent)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: regenerate) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("重新生成")
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(theme.itemHover)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 360, height: 600)
        .background(theme.sidebar)
    }
    
    // MARK: - 方法
    
    private func processText() {
        Task {
            do {
                let session = LanguageModelSession()
                let prompt: String
                
                if selectedAction == .custom {
                    prompt = "\(customPrompt)\n\n\(selectedText)"
                } else {
                    prompt = "\(selectedAction.prompt)\n\n\(selectedText)"
                }
                
                let response = try await session.respond(to: prompt)
                result = response.content
            } catch {
                result = "錯誤：\(error.localizedDescription)"
            }
        }
    }
    
    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        ToastManager.shared.showSuccess("已複製")
    }
    
    private func insertResult() {
        onInsertText(result)
        dismiss()
    }
    
    private func regenerate() {
        result = ""
        processText()
    }
}

// 需要導入 FoundationModels
import FoundationModels

#Preview {
    WriterAIAssistantView(
        selectedText: .constant("這是一段測試文字，用來測試 AI 寫作助手的功能。"),
        onInsertText: { _ in }
    )
    .environmentObject(AppTheme())
}
