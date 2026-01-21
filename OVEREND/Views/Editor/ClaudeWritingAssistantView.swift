//
//  ClaudeWritingAssistantView.swift
//  OVEREND
//
//  Claude Writing Assistant - 富文本編輯器與 AI 寫作助手
//  提供格式化工具、實時文本分析和改進建議
//

import SwiftUI
import AppKit
import CoreData

// MARK: - Main View

struct ClaudeWritingAssistantView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext

    // 支持 Document 模型
    @ObservedObject var document: Document

    @StateObject var viewModel = WritingAssistantViewModel()
    @State private var showColorPicker = false
    @State private var showLinkDialog = false
    @State private var linkUrl = ""
    @State private var selectedText: NSRange = NSRange(location: 0, length: 0)

    // 自動保存計時器
    @State private var autoSaveTimer: Timer?

    // 右側面板模式
    @State private var rightPanelMode: RightPanelMode = .suggestions
    @State private var isRightPanelCollapsed = false

    // 標題編輯狀態
    @State private var isEditingTitle = false
    @State private var editingTitle = ""

    // 引用側邊欄狀態
    @State private var selectedLibrary: Library?

    // 匯出狀態
    @State var isExporting = false

    // 文獻庫列表查詢
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>

    enum RightPanelMode: String, CaseIterable {
        case suggestions = "建議"
        case citations = "引用"

        var icon: String {
            switch self {
            case .suggestions: return "sparkles"
            case .citations: return "quote.bubble"
            }
        }
    }

    init(document: Document) {
        self.document = document
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左側：編輯器面板
                editorPanel
                    .frame(width: isRightPanelCollapsed ? geometry.size.width : geometry.size.width * 0.7)

                Divider()

                // 右側：建議/引用面板（可切換、可折疊）
                if !isRightPanelCollapsed {
                    rightPanel
                        .frame(width: geometry.size.width * 0.3)
                        .transition(.move(edge: .trailing))
                }

                // 折疊狀態的浮動按鈕
                if isRightPanelCollapsed {
                    VStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isRightPanelCollapsed = false
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "sidebar.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.accent)
                                Text("面板")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding(8)
                            .background(theme.card)
                            .cornerRadius(theme.cornerRadiusMD)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("展開側邊面板")
                        .padding(.trailing, 8)
                        .padding(.top, 8)

                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
        }
        .background(theme.background)
        .overlay(linkDialogOverlay)
        .onAppear {
            // 從 Document 加載內容
            loadDocumentContent()

            // 監聽文本變化，自動保存
            setupAutoSave()
        }
        .onDisappear {
            // 停止自動保存計時器
            autoSaveTimer?.invalidate()

            // 最後一次保存
            saveDocumentContent()
        }
        .onChange(of: viewModel.attributedText) { _ in
            // 文本變化時觸發自動保存（延遲 2 秒）
            resetAutoSaveTimer()
        }
    }

    // MARK: - Link Dialog Overlay

    @ViewBuilder
    private var linkDialogOverlay: some View {
        if showLinkDialog {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showLinkDialog = false
                        linkUrl = ""
                    }

                VStack(spacing: 16) {
                    Text("插入連結")
                        .font(theme.fontDisplaySmall)
                        .foregroundColor(theme.textPrimary)

                    TextField("輸入 URL", text: $linkUrl)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)

                    HStack(spacing: 12) {
                        Button("取消") {
                            showLinkDialog = false
                            linkUrl = ""
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("插入") {
                            insertLink()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(linkUrl.isEmpty)
                    }
                }
                .padding(24)
                .background(theme.card)
                .cornerRadius(theme.cornerRadiusMD)
                .shadow(radius: 20)
            }
        }
    }

    // MARK: - Editor Panel

    private var editorPanel: some View {
        VStack(spacing: 0) {
            // 標題列
            editorHeader

            Divider()

            // 格式化工具列
            FormattingToolbarView(
                viewModel: viewModel,
                showColorPicker: $showColorPicker,
                showLinkDialog: $showLinkDialog
            )
            .environmentObject(theme)

            Divider()

            // 富文本編輯器
            RichTextEditorWrapper(
                attributedText: $viewModel.attributedText,
                selectedRange: $selectedText,
                highlights: viewModel.highlights
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.elevated)

            // 底部狀態列
            editorFooter
        }
        .background(theme.card)
    }

    private var editorHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundColor(theme.accent)
                    .font(.title2)

                // 可編輯標題
                if isEditingTitle {
                    TextField("文稿標題", text: $editingTitle, onCommit: {
                        saveTitle()
                    })
                    .textFieldStyle(.plain)
                    .font(theme.fontDisplaySmall)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: 300)
                } else {
                    Text(document.title)
                        .font(theme.fontDisplaySmall)
                        .foregroundColor(theme.textPrimary)
                        .onTapGesture {
                            isEditingTitle = true
                            editingTitle = document.title
                        }
                        .help("點擊編輯標題")
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // 中文優化選單
                Menu {
                    Button(action: fullChineseOptimization) {
                        Label("完整優化", systemImage: "wand.and.stars")
                    }
                    Divider()
                    Button(action: optimizePunctuation) {
                        Label("標點全形化", systemImage: "textformat")
                    }
                    Button(action: optimizeSpacing) {
                        Label("間距調整", systemImage: "arrow.left.and.right")
                    }
                    Button(action: checkTerminology) {
                        Label("術語檢查", systemImage: "checkmark.circle")
                    }
                    Divider()
                    Button(action: convertToTraditional) {
                        Label("轉繁體", systemImage: "character.book.closed.zh")
                    }
                    Button(action: convertToSimplified) {
                        Label("轉簡體", systemImage: "character.book.closed")
                    }
                } label: {
                    Image(systemName: "textformat")
                        .foregroundColor(theme.accent)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 32)
                .help("中文優化")

                // NCCU 格式
                Button(action: applyNCCUFormat) {
                    Image(systemName: "doc.badge.gearshape")
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 28)
                .help("套用政大論文格式")

                // 插入選單
                Menu {
                    Button(action: insertImage) {
                        Label("圖片", systemImage: "photo")
                    }
                    Button(action: insertTable) {
                        Label("表格", systemImage: "tablecells")
                    }
                    Button(action: insertFootnote) {
                        Label("註腳", systemImage: "text.badge.plus")
                    }
                    Divider()
                    Button(action: insertDivider) {
                        Label("分隔線", systemImage: "minus")
                    }
                    Button(action: insertCurrentDate) {
                        Label("目前日期", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "plus.square")
                        .foregroundColor(theme.accent)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 32)
                .help("插入元素")

                // 匯出選單
                Menu {
                    Button(action: exportDocx) {
                        Label("匯出 Word (.docx)", systemImage: "doc.text")
                    }
                    Button(action: exportPDF) {
                        Label("匯出 PDF", systemImage: "doc.richtext")
                    }
                } label: {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(theme.accent)
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 32)
                .disabled(isExporting)
                .help("匯出文件")

                Button(action: viewModel.loadSampleText) {
                    Label("範例", systemImage: "doc.text")
                        .font(theme.fontBodySmall)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: viewModel.copyText) {
                    Label("複製", systemImage: "doc.on.doc")
                        .font(theme.fontBodySmall)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
    }

    private var editorFooter: some View {
        HStack {
            Text("\(viewModel.characterCount) 字元")
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)

            Spacer()

            Button(action: {
                Task {
                    await viewModel.analyzeText()
                }
            }) {
                HStack(spacing: 6) {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(.circular)
                        Text("分析中...")
                    } else {
                        Image(systemName: "sparkles")
                        Text("分析文本")
                    }
                }
                .font(theme.fontButton)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isAnalyzing || viewModel.text.isEmpty)
        }
        .padding()
    }

    // MARK: - Right Panel (Suggestions / Citations)

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // 標題與模式切換
            HStack {
                // 模式切換按鈕
                ForEach(RightPanelMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            rightPanelMode = mode
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                        }
                        .font(theme.fontBodySmall)
                        .foregroundColor(rightPanelMode == mode ? .white : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadiusSM)
                                .fill(rightPanelMode == mode ? theme.accent : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // 右側統計資訊
                if rightPanelMode == .suggestions && !viewModel.suggestions.isEmpty {
                    Text("\(viewModel.suggestions.count) 項")
                        .font(theme.fontBodySmall)
                        .foregroundColor(theme.textSecondary)
                }

                // 折疊按鈕
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isRightPanelCollapsed = true
                    }
                }) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("收起側邊面板")
            }
            .padding()

            Divider()

            // 根據模式顯示不同內容
            if rightPanelMode == .suggestions {
                suggestionsPanel
            } else {
                citationPanel
            }
        }
        .background(theme.card)
    }

    // MARK: - Suggestions Panel

    private var suggestionsPanel: some View {
        VStack(spacing: 0) {
            // 分類篩選
            categoryFilter

            Divider()

            // 建議列表
            if viewModel.isAnalyzing {
                analyzingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if viewModel.suggestions.isEmpty {
                emptyView
            } else {
                suggestionsList
            }
        }
    }

    // MARK: - Citation Panel

    private var citationPanel: some View {
        CitationSidebarView(
            libraries: Array(libraries),
            selectedLibrary: $selectedLibrary,
            onInsertCitation: insertCitation
        )
        .environmentObject(theme)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WritingSuggestionCategory.allCases, id: \.self) { category in
                    WritingCategoryButton(
                        category: category,
                        count: viewModel.getSuggestionCount(for: category),
                        isActive: viewModel.activeCategory == category,
                        action: { viewModel.activeCategory = category }
                    )
                    .environmentObject(theme)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredSuggestions) { suggestion in
                        WritingSuggestionCard(
                            suggestion: suggestion,
                            onApply: { viewModel.applySuggestion(suggestion) },
                            onDismiss: { viewModel.dismissSuggestion(suggestion) }
                        )
                        .environmentObject(theme)
                    }
                }
                .padding()
            }

            // 應用所有建議按鈕
            if !viewModel.suggestions.isEmpty {
                Divider()

                Button(action: {
                    viewModel.applyAllSuggestions()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("應用所有建議")
                    }
                    .font(theme.fontButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(theme.cornerRadiusSM)
                .padding()
            }
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(.circular)

            Text("正在分析文本...")
                .font(theme.fontBodyMedium)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(theme.accent)

            Text("沒有建議")
                .font(theme.fontDisplaySmall)
                .foregroundColor(theme.textPrimary)

            Text("您的文本看起來很好！\n點擊「分析文本」按鈕重新分析。")
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("分析失敗")
                .font(theme.fontDisplaySmall)
                .foregroundColor(theme.textPrimary)

            Text(message)
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            Button("重試") {
                Task {
                    await viewModel.analyzeText()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Methods

    private func insertLink() {
        guard !linkUrl.isEmpty else { return }

        // 創建帶有連結的屬性字串
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .link: linkUrl,
            .foregroundColor: NSColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        // 如果有選中的文字，將其轉為連結
        if selectedText.length > 0 {
            viewModel.attributedText.addAttributes(linkAttributes, range: selectedText)
        } else {
            // 否則插入 URL 文字作為連結
            let linkString = NSAttributedString(string: linkUrl, attributes: linkAttributes)
            viewModel.attributedText.insert(linkString, at: selectedText.location)
        }

        // 更新文本
        viewModel.text = viewModel.attributedText.string

        // 關閉對話框
        showLinkDialog = false
        linkUrl = ""
    }

    // MARK: - Document Integration

    private func loadDocumentContent() {
        // 從 Document 加載 NSAttributedString
        viewModel.attributedText = NSMutableAttributedString(attributedString: document.attributedString)
        viewModel.text = viewModel.attributedText.string
    }

    private func saveDocumentContent() {
        // 保存到 Document
        document.attributedString = viewModel.attributedText
        document.updatedAt = Date()

        // 保存 Core Data
        do {
            try viewContext.save()
        } catch {
            print("保存 Document 失敗: \(error.localizedDescription)")
        }
    }

    private func setupAutoSave() {
        // 不需要手動計時器，使用 onChange 監聽即可
    }

    private func resetAutoSaveTimer() {
        // 取消之前的計時器
        autoSaveTimer?.invalidate()

        // 創建新的計時器（2 秒後自動保存）
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            saveDocumentContent()
        }
    }

    // MARK: - Title Editing

    private func saveTitle() {
        guard !editingTitle.isEmpty else {
            editingTitle = document.title
            isEditingTitle = false
            return
        }

        document.title = editingTitle
        document.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            print("保存標題失敗: \(error.localizedDescription)")
        }

        isEditingTitle = false
    }

    // MARK: - Citation Insertion

    private func insertCitation(_ entry: Entry) {
        // 生成 APA 格式引用（簡化版本）
        let author = entry.author.isEmpty ? "Unknown" : entry.author
        let year = entry.year.isEmpty ? "n.d." : entry.year
        let citationText = "(\(author), \(year))"

        // 創建引用的屬性字串
        let citationAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let citationString = NSAttributedString(string: citationText, attributes: citationAttributes)

        // 在當前光標位置插入引用
        viewModel.attributedText.insert(citationString, at: selectedText.location)

        // 更新文本
        viewModel.text = viewModel.attributedText.string

        // 自動保存
        resetAutoSaveTimer()
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: AppTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [theme.accent, theme.accent.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(theme.cornerRadiusSM)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: AppTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.elevated)
            .cornerRadius(theme.cornerRadiusSM)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    document.id = UUID()
    document.title = "預覽文稿"
    document.createdAt = Date()
    document.updatedAt = Date()
    document.attributedString = NSAttributedString(string: "這是預覽文字內容。\n\n請開始編輯...")

    return ClaudeWritingAssistantView(document: document)
        .environmentObject(AppTheme())
        .environment(\.managedObjectContext, context)
        .frame(width: 1200, height: 800)
}
