//
//  FloatingAIAssistant.swift
//  OVEREND
//
//  浮動 AI 助手 - 右下角固定面板
//

import SwiftUI
import FoundationModels

/// 浮動 AI 助手面板（右下角）
struct FloatingAIAssistant: View {
    @EnvironmentObject var theme: AppTheme
    @StateObject private var aiService = AppleAIService.shared

    // 編輯器綁定
    @Binding var textView: NSTextView?
    @Binding var selectedText: String
    var onReplaceText: ((String) -> Void)?
    var onInsertReferences: ((String) -> Void)?

    // Core Data
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default)
    private var libraries: FetchedResults<Library>

    // 面板狀態
    @State private var isExpanded: Bool = false
    @State private var isMinimized: Bool = true

    // AI 對話
    @State private var userInput: String = ""
    @State private var messages: [AIMessage] = []
    @State private var currentEditingText: String = ""
    @State private var aiResult: String = ""
    @State private var suggestedActions: [SuggestedAction] = [
        SuggestedAction(title: "智慧排版（APA 格式）", icon: "doc.text.fill", color: .blue),
        SuggestedAction(title: "修正引用格式", icon: "checkmark.circle.fill", color: .green),
        SuggestedAction(title: "潤飾選取的文字", icon: "wand.and.stars", color: .purple),
        SuggestedAction(title: "生成參考文獻列表", icon: "list.bullet.rectangle", color: .orange),
        SuggestedAction(title: "生成目錄", icon: "list.number", color: .teal),
        SuggestedAction(title: "調整段落間距", icon: "text.alignleft", color: .indigo)
    ]

    // 參考文獻生成
    @State private var showLibrarySelector: Bool = false
    @State private var selectedLibrary: Library?
    @State private var selectedGroup: Group?
    @State private var selectedCitationFormat: String = "APA"

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !isMinimized {
                // 展開狀態 - 完整面板
                expandedView
            } else {
                // 最小化狀態 - 小圖示
                minimizedView
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isMinimized)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .sheet(isPresented: $showLibrarySelector) {
            LibrarySelectorSheet(
                libraries: Array(libraries),
                selectedLibrary: $selectedLibrary,
                selectedGroup: $selectedGroup,
                selectedFormat: $selectedCitationFormat,
                onGenerate: {
                    generateReferenceList()
                },
                onCancel: {
                    showLibrarySelector = false
                }
            )
            .environmentObject(theme)
        }
    }

    // MARK: - 展開視圖

    private var expandedView: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack(spacing: 8) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accent)

                Text("AI 助理助手")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                // 狀態指示
                if aiService.isAvailable {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }

                // 最小化按鈕
                Button(action: { isMinimized = true }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(theme.toolbar)

            Divider()

            // 建議操作區（僅在沒有對話時顯示）
            if messages.isEmpty {
                suggestionsView
            } else {
                // 對話區
                VStack(spacing: 0) {
                    // 返回主選單按鈕
                    HStack {
                        Button(action: {
                            withAnimation {
                                messages.removeAll()
                                aiResult = ""
                                currentEditingText = ""
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14))
                                Text("返回主選單")
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(theme.accent)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                        Spacer()
                    }
                    .background(theme.itemHover)

                    Divider()

                    messagesView
                }
            }

            Divider()

            // 輸入區
            inputArea
        }
        .frame(width: 320, height: isExpanded ? 480 : 280)
        .background(theme.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: - 最小化視圖

    private var minimizedView: some View {
        Button(action: { isMinimized = false }) {
            HStack(spacing: 6) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Text("AI 助理助手")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.accent,
                        theme.accent.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 建議視圖

    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 選取文字顯示
                if !selectedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.cursor")
                                .font(.system(size: 14))
                                .foregroundColor(theme.accent)

                            Text("選取的文字")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textMuted)

                            Spacer()

                            Text("\(selectedText.count) 字")
                                .font(.system(size: 9))
                                .foregroundColor(theme.textMuted)
                        }

                        Text(selectedText)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(3)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(theme.border, lineWidth: 0.5)
                                    )
                            )

                        // 快速編輯按鈕
                        HStack(spacing: 6) {
                            QuickActionButton(title: "潤飾", icon: "wand.and.stars", color: .purple) {
                                performQuickEdit(action: .improve)
                            }
                            QuickActionButton(title: "擴寫", icon: "text.badge.plus", color: .blue) {
                                performQuickEdit(action: .expand)
                            }
                            QuickActionButton(title: "精簡", icon: "text.badge.minus", color: .orange) {
                                performQuickEdit(action: .summarize)
                            }
                            QuickActionButton(title: "校對", icon: "checkmark.circle", color: .green) {
                                performQuickEdit(action: .proofread)
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.accentLight)
                    )
                }

                // AI 處理結果
                if !aiResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(theme.accent)

                            Text("AI 建議")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textMuted)

                            Spacer()

                            Button(action: { aiResult = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(aiResult)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textPrimary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .textSelection(.enabled)

                        // 操作按鈕
                        HStack(spacing: 8) {
                            Button(action: replaceWithAIResult) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 9))
                                    Text("取代")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.accent)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: copyAIResult) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 9))
                                    Text("複製")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.itemHover)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: { performQuickEdit(action: .improve) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 9))
                                    Text("重新生成")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.itemHover)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.card)
                    )
                }

                // 歡迎訊息（當沒有選取文字時）
                if selectedText.isEmpty && aiResult.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(theme.accent)

                            Text("我可以協助您")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.textMuted)
                        }

                        Text("選取編輯器中的文字，我可以幫您潤飾、擴寫、精簡或校對。")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.accentLight)
                    )
                }

                // 建議操作
                VStack(spacing: 8) {
                    ForEach(suggestedActions) { action in
                        SuggestionButton(action: action) {
                            handleSuggestion(action)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: - 對話視圖

    private var messagesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                }
            }
            .padding(12)
        }
    }

    // MARK: - 輸入區

    private var inputArea: some View {
        HStack(spacing: 8) {
            // 輸入框
            TextField("問我任何問題...", text: $userInput)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(theme.itemHover)
                .cornerRadius(16)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }

            // 發送按鈕
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(userInput.isEmpty ? theme.textMuted : theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(userInput.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.toolbar)
    }

    // MARK: - 方法

    // AI 編輯操作類型
    enum AIEditAction {
        case improve, expand, summarize, proofread

        var prompt: String {
            switch self {
            case .improve:
                return "請潤飾以下學術寫作，提升表達的流暢度和學術性，保持原意不變，使用繁體中文："
            case .expand:
                return "請擴寫以下內容，增加更多細節和論述，保持學術風格，使用繁體中文："
            case .summarize:
                return "請精簡以下內容，保留核心論點，使其更加簡潔，使用繁體中文："
            case .proofread:
                return "請校對以下文字，修正語法錯誤、標點符號問題，並提供改進建議，使用繁體中文："
            }
        }
    }

    private func performQuickEdit(action: AIEditAction) {
        guard !selectedText.isEmpty, aiService.isAvailable else { return }

        currentEditingText = selectedText
        aiResult = "" // 清空之前的結果

        Task {
            do {
                let session = LanguageModelSession()
                let prompt = "\(action.prompt)\n\n\(selectedText)"

                let response = try await session.respond(to: prompt)

                await MainActor.run {
                    aiResult = response.content
                }
            } catch {
                await MainActor.run {
                    aiResult = "處理失敗：\(error.localizedDescription)"
                }
            }
        }
    }

    private func replaceWithAIResult() {
        guard !aiResult.isEmpty else { return }
        onReplaceText?(aiResult)
        aiResult = ""
        ToastManager.shared.showSuccess("已取代文字")
    }

    private func copyAIResult() {
        guard !aiResult.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(aiResult, forType: .string)
        ToastManager.shared.showSuccess("已複製")
    }

    private func handleSuggestion(_ action: SuggestedAction) {
        // 根據不同建議執行不同操作
        if action.title.contains("參考文獻") {
            // 顯示文獻庫選擇器
            showLibrarySelector = true
        } else if action.title.contains("智慧排版") {
            // 智慧排版（APA 格式）
            performSmartFormatting()
        } else if action.title.contains("修正引用格式") {
            // 修正引用格式
            fixCitationFormat()
        } else if action.title.contains("生成目錄") {
            // 生成目錄
            generateTableOfContents()
        } else if action.title.contains("調整段落間距") {
            // 調整段落間距
            adjustParagraphSpacing()
        } else {
            let userMessage = AIMessage(role: .user, content: action.title)
            messages.append(userMessage)

            // 模擬 AI 回應
            Task {
                await generateAIResponse(for: action.title)
            }
        }
    }

    /// 智慧排版（APA 格式）
    private func performSmartFormatting() {
        guard let tv = textView else { return }

        let currentText = tv.attributedString()

        Task {
            do {
                let result = try await AILayoutFormatter.format(
                    text: currentText,
                    type: .academic
                )

                await MainActor.run {
                    // 應用格式化結果
                    tv.textStorage?.setAttributedString(result.formattedText)

                    // 顯示改動訊息
                    let message = AIMessage(
                        role: .assistant,
                        content: "✅ 已完成智慧排版\n\n改動：\n" + result.changes.map { "• \($0)" }.joined(separator: "\n")
                    )
                    messages.append(message)

                    ToastManager.shared.showSuccess("已套用 APA 格式排版")
                }
            } catch {
                await MainActor.run {
                    let errorMessage = AIMessage(
                        role: .assistant,
                        content: "❌ 排版失敗：\(error.localizedDescription)"
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }

    /// 修正引用格式
    private func fixCitationFormat() {
        guard let tv = textView else { return }

        let currentText = tv.attributedString()

        Task {
            do {
                let fixed = try await AILayoutFormatter.fixCitations(in: currentText)

                await MainActor.run {
                    tv.textStorage?.setAttributedString(fixed)

                    let message = AIMessage(
                        role: .assistant,
                        content: "✅ 已將引用格式修正為 APA 第 7 版"
                    )
                    messages.append(message)

                    ToastManager.shared.showSuccess("引用格式已修正")
                }
            } catch {
                await MainActor.run {
                    let errorMessage = AIMessage(
                        role: .assistant,
                        content: "❌ 修正失敗：\(error.localizedDescription)"
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }

    /// 生成目錄
    private func generateTableOfContents() {
        guard let tv = textView else { return }

        let currentText = tv.attributedString()
        let toc = AILayoutFormatter.generateTableOfContents(from: currentText)

        // 在文件開頭插入目錄
        tv.textStorage?.insert(toc, at: 0)

        let message = AIMessage(
            role: .assistant,
            content: "✅ 已在文件開頭插入目錄"
        )
        messages.append(message)

        ToastManager.shared.showSuccess("目錄已生成")
    }

    /// 調整段落間距
    private func adjustParagraphSpacing() {
        guard let tv = textView else { return }

        let currentText = tv.attributedString()
        let adjusted = AILayoutFormatter.adjustParagraphSpacing(
            in: currentText,
            style: .academic
        )

        tv.textStorage?.setAttributedString(adjusted)

        let message = AIMessage(
            role: .assistant,
            content: "✅ 已調整段落間距為學術論文格式\n\n• 左右對齊\n• 1.5 倍行距\n• 首行縮排 2 字元"
        )
        messages.append(message)

        ToastManager.shared.showSuccess("段落間距已調整")
    }

    private func generateReferenceList() {
        guard let library = selectedLibrary else { return }

        var entries: [Entry] = []

        if let group = selectedGroup {
            // 使用選取的分組
            entries = Array(group.entries ?? [])
        } else {
            // 使用整個文獻庫
            entries = Array(library.entries ?? [])
        }

        // 根據選擇的格式生成參考文獻列表
        let references = entries
            .sorted { $0.citationKey < $1.citationKey }
            .map { entry in
                switch selectedCitationFormat {
                case "APA":
                    return CitationService.generateAPA(entry: entry)
                case "MLA":
                    return CitationService.generateMLA(entry: entry)
                case "Chicago":
                    // Chicago 格式暫時使用 APA 格式
                    return CitationService.generateAPA(entry: entry)
                case "BibTeX":
                    // BibTeX 格式：使用原始 BibTeX 資料
                    return entry.bibtexRaw
                default:
                    return CitationService.generateAPA(entry: entry)
                }
            }
            .joined(separator: "\n\n")

        let referenceSection = """
        參考文獻

        \(references)
        """

        onInsertReferences?(referenceSection)
        showLibrarySelector = false
        ToastManager.shared.showSuccess("已插入 \(entries.count) 筆 \(selectedCitationFormat) 格式參考文獻")
    }

    private func sendMessage() {
        guard !userInput.isEmpty else { return }

        let userMessage = AIMessage(role: .user, content: userInput)
        messages.append(userMessage)

        let query = userInput
        userInput = ""

        Task {
            await generateAIResponse(for: query)
        }
    }

    private func generateAIResponse(for query: String) async {
        guard aiService.isAvailable else {
            let errorMessage = AIMessage(
                role: .assistant,
                content: "抱歉，AI 助手目前不可用。請確認您的裝置支援 Apple Intelligence。"
            )
            await MainActor.run {
                messages.append(errorMessage)
            }
            return
        }

        do {
            let session = LanguageModelSession()

            // 根據查詢類型提供不同的系統提示
            let systemContext = """
            你是 OVEREND 學術寫作助手，專門協助用戶：
            - 管理和引用學術文獻
            - 生成 APA 格式引用
            - 提供寫作建議和潤飾
            - 回答學術寫作相關問題

            請用繁體中文簡潔回答，提供實用建議。
            """

            let fullPrompt = "\(systemContext)\n\n用戶問題：\(query)"

            let response = try await session.respond(to: fullPrompt)

            await MainActor.run {
                let aiMessage = AIMessage(role: .assistant, content: response.content)
                messages.append(aiMessage)
            }
        } catch {
            await MainActor.run {
                let errorMessage = AIMessage(
                    role: .assistant,
                    content: "抱歉，處理您的請求時發生錯誤：\(error.localizedDescription)"
                )
                messages.append(errorMessage)
            }
        }
    }
}

// MARK: - 建議操作模型

struct SuggestedAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

// MARK: - AI 訊息模型

struct AIMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()

    enum MessageRole {
        case user
        case assistant
    }
}

// MARK: - 快速操作按鈕

struct QuickActionButton: View {
    @EnvironmentObject var theme: AppTheme
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isHovered ? .white : color)

                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isHovered ? .white : theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? color : theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 建議按鈕

struct SuggestionButton: View {
    @EnvironmentObject var theme: AppTheme
    let action: SuggestedAction
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.system(size: 14))
                    .foregroundColor(action.color)
                    .frame(width: 20)

                Text(action.title)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.itemHover : theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? action.color.opacity(0.3) : theme.border, lineWidth: isHovered ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 訊息氣泡

struct MessageBubble: View {
    @EnvironmentObject var theme: AppTheme
    let message: AIMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(message.role == .user ? .white : theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user ? theme.accent : theme.card)
                    )
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(theme.textMuted)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - 文獻庫選擇器

struct LibrarySelectorSheet: View {
    @EnvironmentObject var theme: AppTheme
    let libraries: [Library]
    @Binding var selectedLibrary: Library?
    @Binding var selectedGroup: Group?
    @Binding var selectedFormat: String
    let onGenerate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text("選擇文獻庫")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.toolbar)

            Divider()

            // 內容
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 格式選擇器
                    VStack(alignment: .leading, spacing: 8) {
                        Text("引用格式")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.textMuted)

                        HStack(spacing: 8) {
                            ForEach(["APA", "MLA", "Chicago"], id: \.self) { format in
                                Button(action: {
                                    selectedFormat = format
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 14))

                                        Text(format)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(selectedFormat == format ? .white : theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedFormat == format ? theme.accent : theme.card)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedFormat == format ? theme.accent : theme.border, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    Text("請選擇要生成參考文獻的文獻庫或分組")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)

                    // 文獻庫列表
                    VStack(spacing: 8) {
                        ForEach(libraries) { library in
                            ReferencesLibraryRow(
                                library: library,
                                isSelected: selectedLibrary?.id == library.id,
                                selectedGroup: $selectedGroup,
                                onSelect: {
                                    selectedLibrary = library
                                    selectedGroup = nil
                                }
                            )
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 底部按鈕
            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape)

                Spacer()

                if let library = selectedLibrary {
                    let count = selectedGroup?.entryCount ?? library.entryCount
                    Text("\(count) 筆文獻")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }

                Button("生成參考文獻") {
                    onGenerate()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .disabled(selectedLibrary == nil)
            }
            .padding()
        }
        .frame(width: 480, height: 500)
        .background(theme.background)
    }
}

// MARK: - 文獻庫行

struct ReferencesLibraryRow: View {
    @EnvironmentObject var theme: AppTheme
    let library: Library
    let isSelected: Bool
    @Binding var selectedGroup: Group?
    let onSelect: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 文獻庫行
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                        .onTapGesture {
                            isExpanded.toggle()
                        }

                    Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)

                    Text(library.name)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Text("\(library.entryCount)")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)

                    if isSelected && selectedGroup == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accent)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected && selectedGroup == nil ? theme.accentLight : theme.card)
                )
            }
            .buttonStyle(.plain)

            // 分組列表（展開時顯示）
            if isExpanded, let groups = library.groups {
                VStack(spacing: 4) {
                    ForEach(Array(groups).filter { $0.parent == nil }.sorted { $0.orderIndex < $1.orderIndex }) { group in
                        ReferencesGroupRow(
                            group: group,
                            isSelected: selectedGroup?.id == group.id,
                            onSelect: {
                                onSelect()
                                selectedGroup = group
                            }
                        )
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }
}

// MARK: - 分組行

struct ReferencesGroupRow: View {
    @EnvironmentObject var theme: AppTheme
    let group: Group
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)

                Text(group.name)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Text("\(group.entryCount)")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? theme.accentLight : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FloatingAIAssistant(
        textView: .constant(nil),
        selectedText: .constant("這是一段測試文字，用來測試 AI 編輯功能。"),
        onReplaceText: { _ in }
    )
    .environmentObject(AppTheme())
    .padding()
    .frame(width: 400, height: 600)
}
