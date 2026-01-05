//
//  AcademicEditorView.swift
//  OVEREND
//
//  學術編輯器 - 整合 AI 助理與專注模式
//

import SwiftUI
import CoreData

// MARK: - 學術編輯器主視圖

struct AcademicEditorView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var document: Document
    
    // 文獻庫 FetchRequest
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>
    
    // 編輯器狀態
    @State private var text: String = ""
    @State private var isTypewriterMode = false
    @State private var showInspector = true
    @State private var fontSize: CGFloat = 18
    @State private var inspectorMode: InspectorMode = .aiTools
    @State private var citationSearch: String = ""
    
    // AI 狀態
    @State private var isAiLoading = false
    @State private var aiResponse: String?
    @State private var showAiSheet = false
    
    // 面板模式
    enum InspectorMode: String, CaseIterable {
        case aiTools = "AI 工具"
        case citations = "引用插入"
    }
    var body: some View {
        HStack(spacing: 0) {
            // --- 左側編輯主體 ---
            VStack(spacing: 0) {
                // 頂部工具列
                editorToolbar
                
                // 寫作內容區
                ZStack {
                    theme.background.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            // 文章分類標籤
                            Text("THESIS DRAFT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(theme.accent.opacity(0.6))
                                .tracking(4)
                                .padding(.top, 60)
                            
                            // 標題
                            Text(document.title)
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(theme.textPrimary)
                                .padding(.bottom, 20)
                            
                            // 編輯器主體
                            TextEditor(text: $text)
                                .font(.system(size: fontSize, weight: .light, design: .serif))
                                .lineSpacing(12)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 800)
                                .accentColor(theme.accent)
                        }
                        .padding(.horizontal, 60)
                        .frame(maxWidth: 800) // 黃金寬度限制
                    }
                    
                    // 打字機模式遮罩
                    if isTypewriterMode {
                        typewriterOverlay
                    }
                }
                
                // 底部狀態列
                statusBar
            }
            
            // --- 右側檢查器 (Inspector) ---
            if showInspector {
                inspectorPanel
                    .transition(.move(edge: .trailing))
            }
        }
        .onAppear {
            text = document.attributedString.string
        }
        .onChange(of: text) {
            document.attributedString = NSAttributedString(string: text)
        }
        .overlay {
            if isAiLoading {
                AiLoadingOverlay(theme: theme)
            }
        }
        .sheet(isPresented: $showAiSheet) {
            if let response = aiResponse {
                AiResponseSheet(content: response, theme: theme)
            }
        }
    }
    
    // MARK: - 工具列
    
    private var editorToolbar: some View {
        HStack {
            // 文件資訊
            HStack(spacing: 15) {
                Image(systemName: "doc.text")
                    .foregroundColor(theme.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("最後同步於 \(formatDate(document.updatedAt))")
                        .font(.system(size: 9))
                        .foregroundColor(theme.textTertiary)
                }
            }
            
            Spacer()
            
            // 字體大小控制
            HStack(spacing: 2) {
                Button(action: { fontSize = max(12, fontSize - 1) }) {
                    Image(systemName: "textformat.size.smaller")
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textSecondary)
                
                Text("\(Int(fontSize))")
                    .font(theme.monoFont(size: 11))
                    .frame(width: 25)
                    .foregroundColor(theme.textSecondary)
                
                Button(action: { fontSize = min(32, fontSize + 1) }) {
                    Image(systemName: "textformat.size.larger")
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            
            Divider().frame(height: 20).padding(.horizontal, 10)
            
            // 專注模式
            Button(action: { isTypewriterMode.toggle() }) {
                Image(systemName: "scope")
                    .foregroundColor(isTypewriterMode ? theme.accent : theme.textTertiary)
            }
            .buttonStyle(.plain)
            .help("打字機專注模式")
            
            // Inspector 切換
            Button(action: { withAnimation(.spring(response: 0.3)) { showInspector.toggle() } }) {
                Image(systemName: "sidebar.right")
                    .foregroundColor(showInspector ? theme.accent : theme.textTertiary)
            }
            .buttonStyle(.plain)
            .help("切換學術助理")
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - 打字機遮罩
    
    private var typewriterOverlay: some View {
        VStack {
            LinearGradient(
                colors: [theme.background, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 250)
            
            Spacer()
            
            LinearGradient(
                colors: [.clear, theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 250)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - 狀態列
    
    private var statusBar: some View {
        HStack {
            HStack(spacing: 20) {
                Label("\(text.count) 字元", systemImage: "character.cursor.ibeam")
                Label("\(wordCount) 單詞", systemImage: "text.alignleft")
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Text("模式: \(isTypewriterMode ? "專注" : "標準")")
                    .foregroundColor(theme.accent)
                
                Circle()
                    .fill(theme.success)
                    .frame(width: 6, height: 6)
                
                Text("已儲存")
            }
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundColor(theme.textTertiary)
        .padding(.horizontal, 20)
        .frame(height: 32)
        .background(Color.white.opacity(0.02))
    }
    
    // MARK: - 檢查器面板
    
    private var inspectorPanel: some View {
        VStack(spacing: 0) {
            // 模式選擇器
            Picker("", selection: $inspectorMode) {
                ForEach(InspectorMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch inspectorMode {
                    case .aiTools:
                        aiToolsContent
                    case .citations:
                        citationInsertContent
                    }
                }
                .padding(20)
            }
            
            // 底部統計
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                
                HStack {
                    Text("總字數")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                    Spacer()
                    Text("\(text.count)")
                        .font(theme.monoFont(size: 12))
                        .foregroundColor(theme.accent)
                }
                
                HStack {
                    Text("預估閱讀")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                    Spacer()
                    Text("\(max(1, text.count / 500)) 分鐘")
                        .font(theme.monoFont(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
        .frame(width: 280)
        .background(theme.elevated)
    }
    
    // MARK: - AI 工具內容
    
    private var aiToolsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("學術助理")
                .font(.headline)
                .foregroundColor(theme.accent)
            
            // AI 工具組
            VStack(spacing: 12) {
                AiActionButton(
                    title: "學術潤色",
                    icon: "sparkles",
                    theme: theme
                ) {
                    callAI(prompt: "請潤色以下學術文字，保持專業語調並改善表達：\n\n\(text)")
                }
                
                AiActionButton(
                    title: "邏輯檢查",
                    icon: "brain.head.profile",
                    theme: theme
                ) {
                    callAI(prompt: "檢查以下論述的邏輯結構並指出潛在缺陷：\n\n\(text)")
                }
                
                AiActionButton(
                    title: "擴展論點",
                    icon: "arrow.up.left.and.arrow.down.right",
                    theme: theme
                ) {
                    callAI(prompt: "請為以下觀點提供更深入的分析和支持論據：\n\n\(text)")
                }
                
                AiActionButton(
                    title: "生成摘要",
                    icon: "doc.text.magnifyingglass",
                    theme: theme
                ) {
                    callAI(prompt: "請為以下內容生成學術摘要（100-150字）：\n\n\(text)")
                }
            }
            
            Divider().padding(.vertical, 10)
            
            // 關聯文獻
            Text("關聯文獻")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textSecondary)
            
            VStack(alignment: .leading, spacing: 15) {
                ForEach(document.citationArray.prefix(5)) { entry in
                    CitationItem(entry: entry, theme: theme)
                }
                
                if document.citationArray.isEmpty {
                    Text("尚無關聯文獻")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                        .padding(.vertical, 10)
                }
            }
        }
    }
    
    // MARK: - 引用插入內容
    
    private var citationInsertContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("文獻插入面板")
                .font(.headline)
                .foregroundColor(theme.accent)
            
            // 搜尋欄
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.textTertiary)
                
                TextField("搜尋文獻庫...", text: $citationSearch)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            
            // 篩選後的文獻列表
            let filteredEntries = citationSearch.isEmpty ? Array(entries.prefix(10)) : entries.filter {
                $0.title.localizedCaseInsensitiveContains(citationSearch) ||
                $0.author.localizedCaseInsensitiveContains(citationSearch)
            }
            
            if filteredEntries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "text.book.closed")
                        .font(.title2)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("無符合的文獻")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        CitationInsertCard(
                            entry: entry,
                            theme: theme,
                            onInsert: { style in
                                insertCitation(entry: entry, style: style)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 引用插入
    
    private func insertCitation(entry: Entry, style: CitationStyle) {
        let citation = entry.inTextCitation(style: style)
        text += " \(citation)"
        ToastManager.shared.showSuccess("已插入引用")
    }
    
    // MARK: - AI 呼叫
    
    private func callAI(prompt: String) {
        isAiLoading = true
        
        Task {
            do {
                // 根據 prompt 內容選擇適當的 AI 操作
                var response = ""
                
                if #available(macOS 26.0, *) {
                    let ai = UnifiedAIService.shared
                    
                    if prompt.contains("潤色") {
                        response = try await ai.writing.rewrite(text: text, style: .academic)
                    } else if prompt.contains("邏輯") {
                        let suggestions = try await ai.writing.getSuggestions(for: text)
                        response = formatSuggestions(suggestions)
                    } else if prompt.contains("擴展") {
                        response = try await ai.writing.rewrite(text: text, style: .elaborate)
                    } else if prompt.contains("摘要") {
                        response = try await ai.writing.condense(text: text, targetRatio: 0.3)
                    } else {
                        // 默認使用寫作分析
                        let suggestions = try await ai.writing.getSuggestions(for: text)
                        response = formatSuggestions(suggestions)
                    }
                } else {
                    response = "AI 功能需要 macOS 26.0 或更新版本。"
                }
                
                await MainActor.run {
                    aiResponse = response
                    isAiLoading = false
                    showAiSheet = true
                }
            } catch {
                await MainActor.run {
                    aiResponse = "AI 服務暫時無法使用：\(error.localizedDescription)"
                    isAiLoading = false
                    showAiSheet = true
                }
            }
        }
    }
    
    private func formatSuggestions(_ suggestions: WritingSuggestions) -> String {
        var result = "## 寫作分析結果\n\n"
        
        if !suggestions.overallFeedback.isEmpty {
            result += "### 整體評價\n\(suggestions.overallFeedback)\n\n"
        }
        
        if !suggestions.grammarIssues.isEmpty {
            result += "### 語法建議 (\(suggestions.grammarIssues.count))\n"
            for issue in suggestions.grammarIssues {
                result += "- 「\(issue.original)」→「\(issue.suggestion)」\n  *\(issue.explanation)*\n"
            }
            result += "\n"
        }
        
        if !suggestions.styleIssues.isEmpty {
            result += "### 風格建議 (\(suggestions.styleIssues.count))\n"
            for issue in suggestions.styleIssues {
                result += "- 「\(issue.original)」→「\(issue.suggestion)」\n  *\(issue.reason)*\n"
            }
            result += "\n"
        }
        
        if !suggestions.logicIssues.isEmpty {
            result += "### 邏輯建議 (\(suggestions.logicIssues.count))\n"
            for issue in suggestions.logicIssues {
                result += "- \(issue.description)\n  *建議：\(issue.suggestion)*\n"
            }
        }
        
        if !suggestions.hasIssues {
            result += "✅ 寫作內容表達清晰，無明顯問題。"
        }
        
        return result
    }
    
    // MARK: - 輔助計算
    
    private var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - AI 動作按鈕

struct AiActionButton: View {
    let title: String
    let icon: String
    let theme: AppTheme
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(theme.accent)
                
                Text(title)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(theme.textTertiary)
                    .opacity(0.5)
            }
            .padding()
            .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - 引用項目

struct CitationItem: View {
    let entry: Entry
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.citationKey)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.accent)
            
            Text(entry.title)
                .font(.system(size: 10))
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
        }
        .padding(.leading, 10)
        .overlay(
            Rectangle()
                .fill(theme.accent.opacity(0.3))
                .frame(width: 2),
            alignment: .leading
        )
    }
}

// MARK: - AI 載入遮罩

struct AiLoadingOverlay: View {
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(theme.accent)
                
                Text("AI 正在分析...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

// MARK: - AI 回應 Sheet

struct AiResponseSheet: View {
    let content: String
    let theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("AI 學術建議", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                Button("關閉") { dismiss() }
            }
            
            Divider()
            
            ScrollView {
                Text(content)
                    .lineSpacing(8)
                    .textSelection(.enabled)
            }
            
            HStack {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    ToastManager.shared.showSuccess("已複製到剪貼簿")
                }) {
                    Label("複製", systemImage: "doc.on.doc")
                }
                
                Spacer()
                
                Button("套用建議") {
                    // TODO: 套用 AI 建議到編輯器
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
        }
        .padding(40)
        .frame(width: 600, height: 500)
    }
}

// MARK: - 引用插入卡片

struct CitationInsertCard: View {
    let entry: Entry
    let theme: AppTheme
    var onInsert: (CitationStyle) -> Void
    
    @State private var isHovered = false
    @State private var showStyles = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
            
            HStack {
                Text(entry.author.components(separatedBy: ",").first ?? "Unknown")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                
                if !entry.year.isEmpty {
                    Text("(\(entry.year))")
                        .font(.caption2)
                        .foregroundColor(theme.textTertiary)
                }
            }
            
            // 插入按鈕
            HStack(spacing: 8) {
                Button(action: { onInsert(.apa7) }) {
                    Label("插入引用", systemImage: "plus.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.accent)
                
                Spacer()
                
                // 更多格式選擇
                Menu {
                    ForEach(CitationStyle.allCases) { style in
                        Button(style.rawValue) {
                            onInsert(style)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding()
        .background(isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
        .cornerRadius(12)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - 預覽

#Preview {
    AcademicEditorView(document: {
        let context = PersistenceController.preview.container.viewContext
        let doc = Document(context: context, title: "AI 在學術寫作中的應用研究")
        return doc
    }())
    .environmentObject(AppTheme())
}
