//
//  AIFormattingPanel.swift
//  OVEREND
//
//  AI 格式調整面板 - 從 DocumentEditorView 拆分
//

import SwiftUI

// MARK: - AI 格式調整面板

struct AIFormattingPanel: View {
    @EnvironmentObject var theme: AppTheme
    let text: String
    let onApplyRewrite: (String) -> Void
    let onClose: () -> Void

    @State private var selectedMode: AIMode = .rewrite
    @State private var selectedRewriteStyle: RewriteStyle = .academic
    @State private var isProcessing = false
    @State private var resultText: String?
    @State private var errorMessage: String?
    @State private var suggestions: WritingSuggestions?

    enum AIMode: String, CaseIterable, Identifiable {
        case rewrite = "改寫優化"
        case proofread = "寫作建議"
        case academicStyle = "學術風格檢查"
        case condense = "精簡文字"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .rewrite: return "pencil.and.outline"
            case .proofread: return "checkmark.circle"
            case .academicStyle: return "graduationcap"
            case .condense: return "text.alignleft"
            }
        }

        var description: String {
            switch self {
            case .rewrite: return "改寫選取的文字，多種風格可選"
            case .proofread: return "檢查語法、風格、邏輯問題"
            case .academicStyle: return "檢查學術寫作規範"
            case .condense: return "精簡冗長的文字內容"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI 格式調整")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.elevated)
            
            Divider()
            
            HStack(spacing: 0) {
                // 左側：模式選擇
                modeSelectionPanel
                
                Divider()
                
                // 右側：預覽與執行
                resultPanel
            }
        }
        .background(theme.background)
    }
    
    // MARK: - 模式選擇面板
    
    private var modeSelectionPanel: some View {
        VStack(spacing: 8) {
            ForEach(AIMode.allCases) { mode in
                Button(action: {
                    selectedMode = mode
                    resultText = nil
                    suggestions = nil
                    errorMessage = nil
                }) {
                    HStack {
                        Image(systemName: mode.icon)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text(mode.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(selectedMode == mode ? theme.accent.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedMode == mode ? theme.accent : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.vertical, 8)

            // 改寫風格選擇（僅在改寫模式下顯示）
            if selectedMode == .rewrite {
                VStack(alignment: .leading, spacing: 8) {
                    Text("改寫風格")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)

                    ForEach(RewriteStyle.allCases, id: \.self) { style in
                        Button(action: { selectedRewriteStyle = style }) {
                            HStack {
                                Image(systemName: selectedRewriteStyle == style ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedRewriteStyle == style ? theme.accent : theme.textSecondary)
                                Text(style.displayName)
                                    .font(.caption)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(theme.background.opacity(0.5))
                .cornerRadius(6)
            }

            Spacer()
        }
        .padding()
        .frame(width: 280)
        .background(theme.elevated.opacity(0.3))
    }
    
    // MARK: - 結果面板
    
    private var resultPanel: some View {
        VStack {
            if isProcessing {
                processingView
            } else if let error = errorMessage {
                errorView(error: error)
            } else if let suggestions = suggestions {
                suggestionsView(suggestions: suggestions)
            } else if let result = resultText {
                resultView(result: result)
            } else {
                readyView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("AI 正在處理中...")
                .font(.headline)
            Text("使用 Apple Intelligence")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            Button("檢查 AI 狀態") {
                checkAIStatus()
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("處理失敗")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            Button("重試") {
                errorMessage = nil
                runAIAnalysis()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private func suggestionsView(suggestions: WritingSuggestions) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI 建議")
                    .font(.headline)

                if !suggestions.grammarIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("語法問題 (\(suggestions.grammarIssues.count))", systemImage: "exclamationmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        ForEach(suggestions.grammarIssues) { issue in
                            AISuggestionRow(
                                original: issue.original,
                                suggestion: issue.suggestion,
                                explanation: issue.explanation,
                                color: .red
                            )
                        }
                    }
                }

                if !suggestions.styleIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("風格問題 (\(suggestions.styleIssues.count))", systemImage: "paintbrush")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        ForEach(suggestions.styleIssues) { issue in
                            AISuggestionRow(
                                original: issue.original,
                                suggestion: issue.suggestion,
                                explanation: issue.reason,
                                color: .orange
                            )
                        }
                    }
                }

                if !suggestions.logicIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("邏輯問題 (\(suggestions.logicIssues.count))", systemImage: "arrow.triangle.branch")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        ForEach(suggestions.logicIssues) { issue in
                            AISuggestionRow(
                                original: issue.description,
                                suggestion: issue.suggestion,
                                explanation: "",
                                color: .blue
                            )
                        }
                    }
                }

                if !suggestions.overallFeedback.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("整體評價")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(suggestions.overallFeedback)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .background(theme.elevated.opacity(0.5))
                    .cornerRadius(8)
                }

                Button("返回") {
                    self.suggestions = nil
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    private func resultView(result: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 結果")
                .font(.headline)
                .padding(.bottom, 8)

            ScrollView {
                Text(result)
                    .font(.system(size: 14))
                    .padding()
                    .background(theme.background)
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }

            HStack {
                Button("取消") {
                    resultText = nil
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("套用到文件") {
                    onApplyRewrite(result)
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
    
    private var readyView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedMode.icon)
                .font(.system(size: 48))
                .foregroundColor(theme.accent)

            Text("準備執行 \(selectedMode.rawValue)")
                .font(.title3)

            Text(selectedMode.description)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 文字長度顯示
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(theme.textSecondary)
                    Text("\(text.count) 字符")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                // 長度警告
                let maxLength = getMaxLength(for: selectedMode)
                if text.count > maxLength {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("文字過長，將自動截取前 \(maxLength) 字符")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            if selectedMode == .rewrite {
                Text("風格：\(selectedRewriteStyle.displayName)")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.accent.opacity(0.2))
                    .cornerRadius(12)
            }

            VStack(spacing: 12) {
                Button("開始分析") {
                    runAIAnalysis()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.purple)
                .disabled(text.isEmpty)

                Button("測試 AI 連線") {
                    checkAIStatus()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - AI 分析
    
    private func runAIAnalysis() {
        guard !text.isEmpty else {
            errorMessage = "請輸入或選擇文字"
            return
        }

        isProcessing = true
        errorMessage = nil
        resultText = nil
        suggestions = nil

        Task {
            do {
                // 檢查 macOS 版本
                if #available(macOS 26.0, *) {
                    print("🔍 開始 AI 處理，模式：\(selectedMode.rawValue)")

                    let aiService = UnifiedAIService.shared

                    // 檢查服務可用性
                    if !aiService.isAvailable {
                        print("⚠️ Apple Intelligence 不可用")
                        throw AIServiceError.notAvailable
                    }

                    switch selectedMode {
                    case .rewrite:
                        print("📝 開始改寫，風格：\(selectedRewriteStyle.displayName)")
                        let result = try await aiService.writing.rewrite(text: text, style: selectedRewriteStyle)
                        print("✅ 改寫完成，長度：\(result.count)")
                        await MainActor.run {
                            resultText = result
                            isProcessing = false
                        }

                    case .proofread:
                        print("✍️ 開始寫作建議分析")
                        let options = WritingOptions()
                        let result = try await aiService.writing.getSuggestions(for: text, options: options)
                        print("✅ 分析完成，問題數：\(result.totalIssueCount)")
                        await MainActor.run {
                            suggestions = result
                            isProcessing = false
                        }

                    case .academicStyle:
                        print("🎓 開始學術風格檢查")
                        let styleIssues = try await aiService.writing.checkAcademicStyle(text: text)
                        print("✅ 檢查完成，問題數：\(styleIssues.count)")
                        await MainActor.run {
                            suggestions = WritingSuggestions(
                                grammarIssues: [],
                                styleIssues: styleIssues,
                                logicIssues: [],
                                overallFeedback: styleIssues.isEmpty ? "✅ 未發現學術風格問題" : "發現 \(styleIssues.count) 個學術風格問題"
                            )
                            isProcessing = false
                        }

                    case .condense:
                        print("✂️ 開始精簡文字")
                        let result = try await aiService.writing.condense(text: text, targetRatio: 0.7)
                        print("✅ 精簡完成，原長度：\(text.count)，新長度：\(result.count)")
                        await MainActor.run {
                            resultText = result
                            isProcessing = false
                        }
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "需要 macOS 26.0 或更新版本才能使用 Apple Intelligence"
                        isProcessing = false
                    }
                }
            } catch let error as AIServiceError {
                await MainActor.run {
                    errorMessage = "AI 服務錯誤：\(error.localizedDescription ?? "未知錯誤")\n\n建議：請確認您的裝置支援 Apple Intelligence"
                    isProcessing = false
                    print("❌ AI 處理失敗 (AIServiceError): \(error)")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "處理失敗：\(error.localizedDescription)\n\n技術細節：\(error)"
                    isProcessing = false
                    print("❌ AI 處理失敗 (未知錯誤): \(error)")
                }
            }
        }
    }

    // MARK: - 輔助方法

    private func getMaxLength(for mode: AIMode) -> Int {
        switch mode {
        case .rewrite: return 800
        case .proofread: return 1000
        case .academicStyle: return 1200
        case .condense: return 1000
        }
    }

    // MARK: - AI 狀態檢查

    private func checkAIStatus() {
        isProcessing = true
        errorMessage = nil

        Task {
            if #available(macOS 26.0, *) {
                let (available, message) = await AppleAITest.testAvailability()
                await MainActor.run {
                    if available {
                        resultText = message
                    } else {
                        errorMessage = message
                    }
                    isProcessing = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "需要 macOS 26.0 或更新版本"
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - AI 建議行視圖

struct AISuggestionRow: View {
    let original: String
    let suggestion: String
    let explanation: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Image(systemName: "arrow.right")
                    .foregroundColor(color)
                    .font(.caption)
                VStack(alignment: .leading, spacing: 4) {
                    Text("原文：\(original)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("建議：\(suggestion)")
                        .font(.caption)
                        .fontWeight(.medium)
                    if !explanation.isEmpty {
                        Text(explanation)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
}
