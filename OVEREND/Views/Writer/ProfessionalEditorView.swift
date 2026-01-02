//
//  ProfessionalEditorView.swift
//  OVEREND
//
//  專業編輯器視圖 - 整合 Physical Canvas Engine
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 專業編輯器視圖
struct ProfessionalEditorView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var document: Document

    // Physical Canvas ViewModel
    @StateObject private var canvasViewModel = PhysicalDocumentViewModel()
    @StateObject private var aiExecutor = AICommandExecutor()

    // 編輯器模式與狀態
    @State private var editorMode: EditorMode = .physicalCanvas
    @State private var showEditorSidebar = true  // 左側邊欄
    @State private var showCitationPanel = true  // 右側參考文獻面板
    @State private var showAICommandPalette = false
    @State private var showFormatTemplateSheet = false
    @State private var showExportMenu = false
    @State private var selectedTemplate: FormatTemplate = .nccu
    @State private var wordCount: Int = 0
    @State private var isSaving: Bool = false
    @State private var lastSaved: Date?
    @State private var autoSaveTimer: Timer?

    init(document: Document) {
        self.document = document
    }

    enum EditorMode {
        case physicalCanvas  // Physical Canvas 模式（預設）
        case richText        // 傳統富文本模式
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側邊欄
            if showEditorSidebar {
                EditorSidebarView(
                    onSelectDocument: { doc in
                        // TODO: 切換文稿
                    },
                    onInsertCitation: { entry in
                        insertCitation(from: entry)
                    },
                    onExitEditor: {
                        // 返回寫作中心
                        viewState.mode = .editorList
                    }
                )
                .transition(.move(edge: .leading))
            }
            
            // 主編輯區域
            VStack(spacing: 0) {
                // 增強型格式工具列
                enhancedToolbar

                // 編輯器（根據模式切換）
                editorContent

                // 底部狀態列
                statusBar
            }
            
            // 右側參考文獻面板
            if showCitationPanel {
                Divider()
                
                VStack(spacing: 0) {
                    // 面板標題
                    HStack {
                        Text("參考文獻")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textPrimary)

                        Spacer()

                        Button(action: {
                            withAnimation(AnimationSystem.Easing.quick) {
                                showCitationPanel = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(theme.toolbar)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(theme.border)
                            .frame(height: 1)
                    }

                    // 引用面板
                    CitationInspector { entry in
                        insertCitation(from: entry)
                    }
                }
                .frame(width: 280)
                .transition(.move(edge: .trailing))
            }
        }
        .background(theme.background)
        .onAppear {
            loadDocumentContent()
            updateWordCount()
        }
        .onDisappear {
            saveDocument()
            autoSaveTimer?.invalidate()
        }
        .sheet(isPresented: $showAICommandPalette) {
            // TODO: 整合實際的 NSTextView 和 ThesisMetadata
            // 目前使用臨時實作
            Text("AI 指令面板（整合中）")
                .font(.system(size: 16))
                .foregroundColor(theme.textMuted)
                .frame(width: 600, height: 400)
                .background(theme.card)
        }
        .sheet(isPresented: $showFormatTemplateSheet) {
            formatTemplateSheet
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAICommandPalette"))) { _ in
            showAICommandPalette = true
        }
    }
    
    // MARK: - 子視圖

    /// 編輯器內容（根據模式切換）
    private var editorContent: some View {
        SwiftUI.Group {
            switch editorMode {
            case .physicalCanvas:
                // Physical Canvas 多頁編輯器
                MultiPageDocumentView()
                    .environmentObject(canvasViewModel)
                    .environmentObject(theme)

            case .richText:
                // 傳統富文本編輯器
                legacyEditorCanvas
            }
        }
    }

    /// 增強型工具列
    private var enhancedToolbar: some View {
        HStack(spacing: 12) {
            // 模式切換
            Picker("", selection: $editorMode) {
                Label("物理畫布", systemImage: "doc.on.doc")
                    .tag(EditorMode.physicalCanvas)
                Label("富文本", systemImage: "doc.richtext")
                    .tag(EditorMode.richText)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Divider()
                .frame(height: 16)

            // 格式模板選擇器
            Menu {
                Button(action: {
                    selectedTemplate = .nccu
                    applyTemplate(.nccu)
                }) {
                    HStack {
                        Text("政大論文格式")
                        if selectedTemplate.name == FormatTemplate.nccu.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button(action: {
                    selectedTemplate = .apa
                    applyTemplate(.apa)
                }) {
                    HStack {
                        Text("APA 格式")
                        if selectedTemplate.name == FormatTemplate.apa.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                Button(action: { showFormatTemplateSheet = true }) {
                    Label("自訂格式...", systemImage: "gearshape")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 14))
                    Text(selectedTemplate.name)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
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

            // AI 指令按鈕
            Button(action: {
                showAICommandPalette = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 14))
                    Text("AI 助手")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.accentLight)
                )
            }
            .buttonStyle(.plain)
            .help("快捷鍵：⌘K")

            Divider()
                .frame(height: 16)

            // 字體選擇器
            Menu {
                Button("新細明體") { /* TODO */ }
                Button("標楷體") { /* TODO */ }
                Button("Times New Roman") { /* TODO */ }
                Button("Arial") { /* TODO */ }
            } label: {
                HStack(spacing: 4) {
                    Text("新細明體")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical  , 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.itemHover)
                )
            }
            .buttonStyle(.plain)
            .frame(width: 100)

            // 字體大小
            Menu {
                ForEach([10, 11, 12, 14, 16, 18, 20, 24], id: \.self) { size in
                    Button("\(size)") { /* TODO */ }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("12")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.itemHover)
                )
            }
            .buttonStyle(.plain)
            .frame(width: 60)

            Divider()
                .frame(height: 16)

            // 格式按鈕組
            HStack(spacing: 6) {
                FormatButton(icon: "bold", tooltip: "粗體 (⌘B)") {
                    // TODO: 套用粗體
                }
                .environmentObject(theme)

                FormatButton(icon: "italic", tooltip: "斜體 (⌘I)") {
                    // TODO: 套用斜體
                }
                .environmentObject(theme)

                FormatButton(icon: "underline", tooltip: "底線 (⌘U)") {
                    // TODO: 套用底線
                }
                .environmentObject(theme)
            }

            Divider()
                .frame(height: 16)

            // 對齊按鈕組
            HStack(spacing: 6) {
                FormatButton(icon: "text.alignleft", tooltip: "靠左對齊") {
                    // TODO: 靠左對齊
                }
                .environmentObject(theme)

                FormatButton(icon: "text.aligncenter", tooltip: "置中對齊") {
                    // TODO: 置中對齊
                }
                .environmentObject(theme)

                FormatButton(icon: "text.alignright", tooltip: "靠右對齊") {
                    // TODO: 靠右對齊
                }
                .environmentObject(theme)

                FormatButton(icon: "text.justify", tooltip: "左右對齊") {
                    // TODO: 左右對齊
                }
                .environmentObject(theme)
            }

            Divider()
                .frame(height: 16)

            // 行距選擇器
            Menu {
                Button("單行間距") { /* TODO */ }
                Button("1.15 倍行距") { /* TODO */ }
                Button("1.5 倍行距") { /* TODO */ }
                Button("2 倍行距") { /* TODO */ }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "text.line.spacing")
                        .font(.system(size: 13))
                    Text("2.0")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.itemHover)
                )
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 16)

            // 項目符號與編號
            HStack(spacing: 6) {
                FormatButton(icon: "list.bullet", tooltip: "項目符號") {
                    // TODO: 項目符號
                }
                .environmentObject(theme)

                FormatButton(icon: "list.number", tooltip: "編號列表") {
                    // TODO: 編號列表
                }
                .environmentObject(theme)
            }

            Divider()
                .frame(height: 16)
            
            // Compile 匯出按鈕
            Menu {
                Button(action: { exportDocument(format: .pdf) }) {
                    Label("匯出 PDF", systemImage: "doc.fill")
                }
                Button(action: { exportDocument(format: .docx) }) {
                    Label("匯出 DOCX", systemImage: "doc.richtext")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 14))
                    Text("Compile")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.accent)
                )
            }
            .buttonStyle(.plain)
            .help("匯出文稿")

            // 字數統計
            HStack(spacing: 4) {
                Image(systemName: "textformat.characters")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                Text("\(wordCount) 字")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }

            // 頁數（Physical Canvas 模式）
            if editorMode == .physicalCanvas {
                HStack(spacing: 4) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                    Text("\(canvasViewModel.totalPages) 頁")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            }

            Spacer()

            // 側邊欄切換
            Button(action: {
                withAnimation(AnimationSystem.Easing.quick) {
                    showEditorSidebar.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showEditorSidebar ? "sidebar.left" : "sidebar.leading")
                        .font(.system(size: 14))
                }
                .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
            .help(showEditorSidebar ? "隱藏側邊欄" : "顯示側邊欄")

            // 儲存狀態
            if isSaving {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("儲存中...")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            } else if let saved = lastSaved {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("已儲存於 \(formatTime(saved))")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }

    /// 底部狀態列
    private var statusBar: some View {
        HStack(spacing: 16) {
            // 文稿名稱
            Text(document.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textPrimary)

            Spacer()

            // 編輯模式指示
            Text(editorMode == .physicalCanvas ? "物理畫布模式" : "富文本模式")
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)

            // 自動儲存狀態
            HStack(spacing: 4) {
                Circle()
                    .fill(isSaving ? .orange : .green)
                    .frame(width: 6, height: 6)
                Text("自動儲存")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(theme.toolbar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }

    // MARK: - 傳統編輯器（富文本模式）

    private var legacyEditorCanvas: some View {
        Text("傳統富文本編輯器（開發中）")
            .font(.system(size: 16))
            .foregroundColor(theme.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
    }

    // MARK: - 格式模板表單

    private var formatTemplateSheet: some View {
        VStack(spacing: 24) {
            // 標題
            HStack {
                Text("格式模板")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Button(action: { showFormatTemplateSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // 預設模板列表
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    templateCard(
                        template: .nccu,
                        icon: "graduationcap",
                        description: "國立政治大學行政管理碩士學程論文格式規範"
                    )

                    templateCard(
                        template: .apa,
                        icon: "doc.text",
                        description: "美國心理學會 (APA) 第七版格式規範"
                    )
                }
                .padding(.vertical, 8)
            }

            Spacer()

            // 按鈕
            Button("關閉") {
                showFormatTemplateSheet = false
            }
            .keyboardShortcut(.escape)
            .font(.system(size: 15))
            .foregroundColor(theme.textMuted)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.itemHover)
            )
        }
        .padding(24)
        .frame(width: 600, height: 500)
        .background(theme.card)
    }

    private func templateCard(template: FormatTemplate, icon: String, description: String) -> some View {
        Button(action: {
            selectedTemplate = template
            applyTemplate(template)
            showFormatTemplateSheet = false
        }) {
            HStack(spacing: 16) {
                // 圖標
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accentLight)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(theme.accent)
                }

                // 內容
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textPrimary)

                        if selectedTemplate.name == template.name {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accent)
                        }
                    }

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textMuted)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedTemplate.name == template.name ? theme.accentLight.opacity(0.3) : theme.itemHover)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedTemplate.name == template.name ? theme.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 方法

    /// 載入文稿內容
    private func loadDocumentContent() {
        // TODO: 從 document.rtfData 載入到 canvasViewModel
        // 目前先使用空白文稿
        canvasViewModel.documentTitle = document.title
    }

    /// 套用格式模板
    private func applyTemplate(_ template: FormatTemplate) {
        // TODO: 將格式模板套用到 canvasViewModel
        // 包含：頁面設定、邊距、字體、行距等
        ToastManager.shared.showSuccess("已套用「\(template.name)」格式")
        scheduleAutoSave()
    }

    /// 更新字數統計
    private func updateWordCount() {
        wordCount = canvasViewModel.totalWordCount()
    }

    /// 格式化時間
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// 插入引用
    private func insertCitation(from entry: Entry) {
        // TODO: 整合到 Physical Canvas
        let author = formatAuthorShort(entry.fields["author"] ?? "Unknown")
        let year = entry.fields["year"] ?? "n.d."
        let citation = "(\(author), \(year))"

        ToastManager.shared.showInfo("引用功能整合中：\(citation)")
        scheduleAutoSave()
    }

    /// 格式化作者名稱
    private func formatAuthorShort(_ author: String) -> String {
        let parts = author.components(separatedBy: " and ")
        guard let firstAuthor = parts.first else { return author }

        if firstAuthor.range(of: "\\p{Han}", options: .regularExpression) != nil {
            return String(firstAuthor.prefix(1))
        }

        let nameParts = firstAuthor.components(separatedBy: ", ")
        return nameParts.first ?? firstAuthor
    }

    /// 排程自動儲存
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            saveDocument()
        }
    }

    /// 儲存文稿
    private func saveDocument() {
        isSaving = true

        // TODO: 從 canvasViewModel 取得內容並儲存到 document.rtfData
        document.updatedAt = Date()

        do {
            try viewContext.save()
            lastSaved = Date()
            updateWordCount()
        } catch {
            print("❌ 儲存失敗：\(error.localizedDescription)")
            ToastManager.shared.showError("儲存失敗")
        }

        isSaving = false
    }
    
    // MARK: - 匯出功能
    
    /// 匯出格式
    enum ExportFormat {
        case pdf
        case docx
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .docx: return "docx"
            }
        }
        
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .docx: return "Word 文件"
            }
        }
    }
    
    /// 匯出文稿
    private func exportDocument(format: ExportFormat) {
        let panel = NSSavePanel()
        panel.title = "匯出\(format.displayName)"
        panel.nameFieldStringValue = "\(document.title).\(format.fileExtension)"
        panel.canCreateDirectories = true
        
        switch format {
        case .pdf:
            panel.allowedContentTypes = [.pdf]
        case .docx:
            panel.allowedContentTypes = [UTType(filenameExtension: "docx") ?? .data]
        }
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            Task {
                do {
                    switch format {
                    case .pdf:
                        try await exportToPDF(url: url)
                    case .docx:
                        try await exportToDOCX(url: url)
                    }
                    
                    await MainActor.run {
                        ToastManager.shared.showSuccess("已成功匯出 \(format.displayName)")
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                } catch {
                    await MainActor.run {
                        ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// 匯出為 PDF
    private func exportToPDF(url: URL) async throws {
        // 使用 DocumentFormatter 的 HTML 生成功能
        let attributedString = document.attributedString
        let html = DocumentFormatter.toHTML(attributedString, template: selectedTemplate)
        
        // 將 HTML 寫入暫存檔案，並用 WebView 渲染成 PDF
        let tempHTMLURL = FileManager.default.temporaryDirectory.appendingPathComponent("export_temp.html")
        try html.write(to: tempHTMLURL, atomically: true, encoding: .utf8)
        
        // 使用 NSPrintOperation 產生 PDF
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                // 建立 NSTextView 來渲染 HTML
                let textStorage = NSTextStorage()
                let layoutManager = NSLayoutManager()
                let textContainer = NSTextContainer(size: NSSize(width: 595, height: CGFloat.greatestFiniteMagnitude))
                
                textStorage.addLayoutManager(layoutManager)
                layoutManager.addTextContainer(textContainer)
                textStorage.setAttributedString(attributedString)
                
                let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
                textView.textStorage?.setAttributedString(attributedString)
                
                // 設定列印選項
                let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
                printInfo.paperSize = NSSize(width: 595, height: 842) // A4
                printInfo.topMargin = 72
                printInfo.bottomMargin = 72
                printInfo.leftMargin = 72
                printInfo.rightMargin = 72
                printInfo.horizontalPagination = .fit
                printInfo.verticalPagination = .automatic
                printInfo.jobDisposition = .save
                printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
                
                let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
                printOperation.showsPrintPanel = false
                printOperation.showsProgressPanel = false
                
                if printOperation.run() {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "ExportError", code: 2, userInfo: [NSLocalizedDescriptionKey: "PDF 匯出失敗"]))
                }
            }
        }
    }
    
    /// 匯出為 DOCX
    private func exportToDOCX(url: URL) async throws {
        // 使用 RTF 資料匯出（DOCX 基本相容）
        let attributedString = document.attributedString
        
        // 生成 RTF 資料
        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            throw NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法生成 RTF 資料"])
        }
        
        // 暫時以 RTF 格式儲存（Word 可開啟）
        let rtfURL = url.deletingPathExtension().appendingPathExtension("rtf")
        try rtfData.write(to: rtfURL)
        
        // 提示使用者
        await MainActor.run {
            ToastManager.shared.showInfo("已匯出為 RTF 格式（Word 可開啟）")
        }
    }
}

/// 格式按鈕
struct FormatButton: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    var tooltip: String = ""
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isHovered ? theme.accent : theme.textMuted)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? theme.accentLight.opacity(0.3) : .clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context, title: "測試文稿")
    
    return ProfessionalEditorView(document: doc)
        .environmentObject(theme)
        .environmentObject(viewState)
        .environment(\.managedObjectContext, context)
        .frame(width: 1200, height: 800)
}
