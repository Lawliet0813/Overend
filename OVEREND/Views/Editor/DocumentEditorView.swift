//
//  DocumentEditorView.swift
//  OVEREND
//
//  DOCX 編輯器 - 支援 DOCX/PDF 匯入匯出
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 主編輯器視圖

struct DocumentEditorView: View {
    @ObservedObject var document: Document
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var attributedText: NSAttributedString
    @State private var showExportMenu = false
    @State private var showImportSheet = false
    @State private var isExporting = false
    @State private var isPandocAvailable = PandocService.isAvailable
    @State private var textViewRef: NSTextView?
    @State private var showCitationSidebar = true
    @State private var showAIPanel = false
    @State private var isAIProcessing = false
    
    // 文獻庫
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>
    
    @State private var selectedLibrary: Library?
    
    init(document: Document) {
        self.document = document
        _attributedText = State(initialValue: document.attributedString)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            EditorToolbar(
                document: document,
                onImport: { showImportSheet = true },
                onExport: { showExportMenu = true },
                isPandocAvailable: isPandocAvailable,
                onBold: { applyFormat(.bold) },
                onItalic: { applyFormat(.italic) },
                onUnderline: { applyFormat(.underline) },
                onAlignLeft: { applyAlignment(.left) },
                onAlignCenter: { applyAlignment(.center) },
                onAlignRight: { applyAlignment(.right) },
                onIncreaseFontSize: { adjustFontSize(by: 2) },
                onDecreaseFontSize: { adjustFontSize(by: -2) },
                onLineSpacing: { spacing in applyLineSpacing(spacing) },
                onTextColor: { color in applyTextColor(color) },
                onAI: { showAIPanel = true },
                showCitationSidebar: $showCitationSidebar
            )
            .environmentObject(theme)
            
            // 主編輯區域 + 引用側邊欄
            HSplitView {
                // 編輯區域
                RichTextEditorView(
                    attributedText: $attributedText,
                    textViewRef: $textViewRef,
                    onTextChange: saveDocument
                )
                .environmentObject(theme)
                .frame(minWidth: 400)
                
                // 引用側邊欄
                if showCitationSidebar {
                    CitationSidebarView(
                        libraries: Array(libraries),
                        selectedLibrary: $selectedLibrary,
                        onInsertCitation: insertCitation
                    )
                    .environmentObject(theme)
                    .frame(width: 320)
                }
            }
            
            Divider()
            
            // 狀態列
            EditorStatusBar(
                wordCount: wordCount,
                characterCount: attributedText.length,
                isPandocAvailable: isPandocAvailable
            )
            .environmentObject(theme)
        }
        .background(theme.background)
        .sheet(isPresented: $showImportSheet) {
            ImportDocumentSheet(onImport: handleImport)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showAIPanel) {
            AIFormattingPanel(
                text: attributedText.string,
                onApplyRewrite: { newText in applyAIRewrite(newText) },
                onClose: { showAIPanel = false }
            )
            .environmentObject(theme)
            .frame(minWidth: 500, minHeight: 400)
        }
        .confirmationDialog("匯出格式", isPresented: $showExportMenu) {
            Button("匯出 DOCX") { exportDocument(format: .docx) }
            Button("匯出 PDF") { exportDocument(format: .pdf) }
            Button("取消", role: .cancel) { }
        }
        .overlay {
            if isExporting || isAIProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(isAIProcessing ? "AI 處理中..." : "正在匯出...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
        .onAppear {
            // 預設選擇第一個文獻庫
            if selectedLibrary == nil {
                selectedLibrary = libraries.first
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var wordCount: Int {
        let text = attributedText.string
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    // MARK: - Formatting Types
    
    enum FormatStyle {
        case bold, italic, underline
    }
    
    // MARK: - Formatting Methods
    
    private func applyFormat(_ style: FormatStyle) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            guard let currentFont = value as? NSFont else { return }
            
            var newFont: NSFont
            let traits = currentFont.fontDescriptor.symbolicTraits
            
            switch style {
            case .bold:
                if traits.contains(.bold) {
                    // 移除粗體
                    newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
                }
            case .italic:
                if traits.contains(.italic) {
                    newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
                }
            case .underline:
                // 底線使用不同的屬性
                let hasUnderline = textStorage.attribute(.underlineStyle, at: attrRange.location, effectiveRange: nil) != nil
                if hasUnderline {
                    textStorage.removeAttribute(.underlineStyle, range: attrRange)
                } else {
                    textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: attrRange)
                }
                return
            }
            
            textStorage.addAttribute(.font, value: newFont, range: attrRange)
        }
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    private func applyAlignment(_ alignment: NSTextAlignment) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        textStorage.beginEditing()
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    private func adjustFontSize(by delta: CGFloat) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            guard let currentFont = value as? NSFont else { return }
            let newSize = max(8, currentFont.pointSize + delta)
            let newFont = NSFont(descriptor: currentFont.fontDescriptor, size: newSize) ?? currentFont
            textStorage.addAttribute(.font, value: newFont, range: attrRange)
        }
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    private func applyLineSpacing(_ spacing: CGFloat) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = spacing
        
        textStorage.beginEditing()
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("行距已設為 \(spacing) 倍")
    }
    
    private func applyAIRewrite(_ newText: String) {
        guard let textView = textViewRef else { return }
        
        // 如果有選取文字，替換選取部分；否則替換全文
        let range = textView.selectedRange()
        let replaceRange = range.length > 0 ? range : NSRange(location: 0, length: textView.string.count)
        
        guard let textStorage = textView.textStorage else { return }
        
        // 保持原有格式，只替換文字內容
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        let newAttributed = NSAttributedString(string: newText, attributes: attributes)
        
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: replaceRange, with: newAttributed)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("AI 調整完成")
    }
    
    private func applyTextColor(_ color: NSColor) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        textStorage.addAttribute(.foregroundColor, value: color, range: range)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - Citation Methods
    
    private func insertCitation(_ entry: Entry) {
        guard let textView = textViewRef else { return }
        
        // 生成 APA 格式引用
        let citationText = CitationService.generateAPA(entry: entry)
        
        // 在游標位置插入
        let insertionPoint = textView.selectedRange().location
        
        guard let textStorage = textView.textStorage else { return }
        
        let citationAttributed = NSAttributedString(
            string: "(\(entry.author), \(entry.year.isEmpty ? "n.d." : entry.year))",
            attributes: [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 14)
            ]
        )
        
        textStorage.insert(citationAttributed, at: insertionPoint)
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("已插入引用")
    }
    
    // MARK: - Methods
    
    private func saveDocument() {
        document.attributedString = attributedText
        document.updatedAt = Date()
        try? viewContext.save()
    }
    
    private func handleImport(_ url: URL) {
        Task {
            do {
                // 開始存取安全範圍資源
                let canAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let data = try Data(contentsOf: url)
                
                // 嘗試使用 Office Open XML 格式讀取
                let imported: NSAttributedString
                do {
                    imported = try NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.officeOpenXML],
                        documentAttributes: nil
                    )
                } catch {
                    // 回退到 RTF 格式
                    imported = try NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.rtf],
                        documentAttributes: nil
                    )
                }
                
                // 將所有文字顏色改為白色（適應深色主題）
                let mutableImported = NSMutableAttributedString(attributedString: imported)
                mutableImported.addAttribute(
                    .foregroundColor,
                    value: NSColor.white,
                    range: NSRange(location: 0, length: mutableImported.length)
                )
                
                await MainActor.run {
                    attributedText = mutableImported
                    saveDocument()
                    ToastManager.shared.showSuccess("已成功匯入文件（\(imported.length) 字元）")
                }
            } catch {
                await MainActor.run {
                    print("Import error: \(error)")
                    ToastManager.shared.showError("匯入失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func exportDocument(format: PandocService.OutputFormat) {
        Task {
            await MainActor.run { isExporting = true }
            
            do {
                let panel = NSSavePanel()
                panel.title = "匯出\(format == .docx ? " DOCX" : " PDF")"
                panel.nameFieldStringValue = "\(document.title).\(format.ext)"
                panel.allowedContentTypes = [format == .docx ? 
                    (UTType(filenameExtension: "docx") ?? .data) : .pdf]
                
                let response = await panel.beginSheetModal(for: NSApp.keyWindow!)
                
                if response == .OK, let url = panel.url {
                    // 使用原生 API 匯出
                    try await exportWithNativeAPI(to: url, format: format)
                    
                    await MainActor.run {
                        ToastManager.shared.showSuccess("已成功匯出")
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } catch {
                await MainActor.run {
                    print("Export error: \(error)")
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
            
            await MainActor.run { isExporting = false }
        }
    }
    
    private func exportWithNativeAPI(to url: URL, format: PandocService.OutputFormat) async throws {
        switch format {
        case .docx:
            // 使用 Office Open XML
            if let data = try? attributedText.data(
                from: NSRange(location: 0, length: attributedText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.officeOpenXML]
            ) {
                try data.write(to: url)
            } else {
                // 回退到 RTF
                let rtfData = try attributedText.data(
                    from: NSRange(location: 0, length: attributedText.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                let rtfURL = url.deletingPathExtension().appendingPathExtension("rtf")
                try rtfData.write(to: rtfURL)
            }
        case .pdf:
            try await exportPDFNative(to: url)
        default:
            break
        }
    }
    
    private func exportPDFNative(to url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
                textView.textStorage?.setAttributedString(attributedText)
                
                let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
                printInfo.paperSize = NSSize(width: 595, height: 842)
                printInfo.topMargin = 72
                printInfo.bottomMargin = 72
                printInfo.leftMargin = 72
                printInfo.rightMargin = 72
                printInfo.jobDisposition = .save
                printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
                
                let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
                printOp.showsPrintPanel = false
                printOp.showsProgressPanel = false
                
                if printOp.run() {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "PDF", code: -1))
                }
            }
        }
    }
}

// MARK: - 編輯器工具列

struct EditorToolbar: View {
    @ObservedObject var document: Document
    @EnvironmentObject var theme: AppTheme
    
    let onImport: () -> Void
    let onExport: () -> Void
    let isPandocAvailable: Bool
    
    // 格式化回調
    var onBold: (() -> Void)?
    var onItalic: (() -> Void)?
    var onUnderline: (() -> Void)?
    var onAlignLeft: (() -> Void)?
    var onAlignCenter: (() -> Void)?
    var onAlignRight: (() -> Void)?
    var onIncreaseFontSize: (() -> Void)?
    var onDecreaseFontSize: (() -> Void)?
    var onLineSpacing: ((CGFloat) -> Void)?
    var onTextColor: ((NSColor) -> Void)?
    var onAI: (() -> Void)?
    
    // 側邊欄控制
    @Binding var showCitationSidebar: Bool
    
    // 狀態
    @State private var showColorPicker = false
    @State private var selectedColor: Color = .black
    
    var body: some View {
        VStack(spacing: 0) {
            // 主工具列
            HStack(spacing: 16) {
                // 標題
                Text(document.title)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // AI 調整
                Button(action: { onAI?() }) {
                    Label("AI 調整", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                
                // 引用側邊欄切換
                Button(action: { showCitationSidebar.toggle() }) {
                    Label("參考文獻", systemImage: showCitationSidebar ? "sidebar.right" : "sidebar.left")
                }
                .buttonStyle(.bordered)
                
                Divider().frame(height: 20)
                
                // 匯入
                Button(action: onImport) {
                    Label("匯入 DOCX", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                
                // 匯出
                Button(action: onExport) {
                    Label("匯出", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(theme.elevated)
            
            Divider()
            
            // 格式化工具列
            HStack(spacing: 8) {
                // 字體樣式組
                HStack(spacing: 4) {
                    FormatButton(icon: "bold", tooltip: "粗體 ⌘B", action: onBold)
                    FormatButton(icon: "italic", tooltip: "斜體 ⌘I", action: onItalic)
                    FormatButton(icon: "underline", tooltip: "底線 ⌘U", action: onUnderline)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
                
                Divider().frame(height: 20)
                
                // 字體大小
                HStack(spacing: 4) {
                    FormatButton(icon: "textformat.size.smaller", tooltip: "縮小字體", action: onDecreaseFontSize)
                    FormatButton(icon: "textformat.size.larger", tooltip: "放大字體", action: onIncreaseFontSize)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
                
                Divider().frame(height: 20)
                
                // 對齊組
                HStack(spacing: 4) {
                    FormatButton(icon: "text.alignleft", tooltip: "靠左對齊", action: onAlignLeft)
                    FormatButton(icon: "text.aligncenter", tooltip: "置中對齊", action: onAlignCenter)
                    FormatButton(icon: "text.alignright", tooltip: "靠右對齊", action: onAlignRight)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
                
                Divider().frame(height: 20)
                
                // 行距選單
                Menu {
                    Button("單行 (1.0)") { onLineSpacing?(1.0) }
                    Button("1.15 倍") { onLineSpacing?(1.15) }
                    Button("1.5 倍") { onLineSpacing?(1.5) }
                    Button("雙倍 (2.0)") { onLineSpacing?(2.0) }
                } label: {
                    Label("行距", systemImage: "text.line.spacing")
                        .font(.system(size: 14, weight: .medium))
                        .frame(height: 28)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 60)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
                .help("行距")
                
                // 字體顏色
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 28, height: 28)
                    .help("字體顏色")
                    .onChange(of: selectedColor) { newColor in
                        onTextColor?(NSColor(newColor))
                    }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(theme.background)
        }
    }
}

// MARK: - 格式化按鈕

struct FormatButton: View {
    let icon: String
    let tooltip: String
    var action: (() -> Void)?
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: { action?() }) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}


// MARK: - 富文本編輯器（A4 紙張模擬）

struct RichTextEditorView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?
    @EnvironmentObject var theme: AppTheme
    let onTextChange: () -> Void
    
    // A4 尺寸 (72 DPI: 595 x 842 pt)
    static let a4Width: CGFloat = 595
    static let a4Margin: CGFloat = 72  // 1 inch margin
    
    func makeNSView(context: Context) -> NSScrollView {
        // 創建容器 ScrollView
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor.darkGray.withAlphaComponent(0.3)
        scrollView.drawsBackground = true
        
        // 創建 A4 紙張容器
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // 創建 TextView
        let textContainer = NSTextContainer(size: NSSize(
            width: Self.a4Width - (Self.a4Margin * 2),
            height: .greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = false
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        let textView = NSTextView(frame: NSRect(
            x: Self.a4Margin,
            y: Self.a4Margin,
            width: Self.a4Width - (Self.a4Margin * 2),
            height: 600
        ), textContainer: textContainer)
        
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.height]
        
        // 紙張樣式 - 白色背景配深色文字
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.insertionPointColor = .black
        textView.font = .systemFont(ofSize: 12)
        
        // 預設輸入屬性
        textView.typingAttributes = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        // 紙張視圖
        let paperView = NSView(frame: NSRect(x: 0, y: 0, width: Self.a4Width, height: 842))
        paperView.wantsLayer = true
        paperView.layer?.backgroundColor = NSColor.white.cgColor
        paperView.layer?.shadowColor = NSColor.black.cgColor
        paperView.layer?.shadowOffset = CGSize(width: 0, height: -2)
        paperView.layer?.shadowRadius = 8
        paperView.layer?.shadowOpacity = 0.3
        
        paperView.addSubview(textView)
        
        // 設置紙張居中的剪輯視圖
        let clipView = CenteredClipView()
        clipView.documentView = paperView
        clipView.backgroundColor = NSColor.darkGray.withAlphaComponent(0.3)
        clipView.drawsBackground = true
        
        scrollView.contentView = clipView
        scrollView.documentView = paperView
        
        // 初始內容
        textView.textStorage?.setAttributedString(attributedText)
        
        // 儲存參考
        DispatchQueue.main.async {
            self.textViewRef = textView
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let paperView = nsView.documentView,
              let textView = paperView.subviews.first as? NSTextView else { return }
        
        // 只在內容真正改變時更新
        if textView.attributedString() != attributedText {
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(attributedText)
            textView.selectedRanges = selectedRanges
        }
        
        // 更新紙張高度以適應內容
        textView.sizeToFit()
        let contentHeight = max(842, textView.frame.height + Self.a4Margin * 2)
        paperView.frame.size.height = contentHeight
        textView.frame.origin.y = Self.a4Margin
        textView.frame.size.height = contentHeight - Self.a4Margin * 2
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView
        
        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
            parent.onTextChange()
        }
    }
}

// MARK: - 置中 ClipView

class CenteredClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        
        if let documentView = documentView {
            // 水平置中
            if documentView.frame.width < proposedBounds.width {
                rect.origin.x = (documentView.frame.width - proposedBounds.width) / 2
            }
        }
        
        return rect
    }
}

// MARK: - 狀態列

struct EditorStatusBar: View {
    @EnvironmentObject var theme: AppTheme
    let wordCount: Int
    let characterCount: Int
    let isPandocAvailable: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            Label("\(wordCount) 字詞", systemImage: "textformat.abc")
            Label("\(characterCount) 字元", systemImage: "character")
            
            Spacer()
            
            Text("DOCX / PDF 匯出")
                .foregroundColor(theme.textTertiary)
        }
        .font(.caption)
        .foregroundColor(theme.textSecondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(theme.elevated)
    }
}

// MARK: - 匯入表單

struct ImportDocumentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AppTheme
    
    let onImport: (URL) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("匯入 DOCX 文件")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("選擇一個 DOCX 檔案匯入編輯器")
                .foregroundColor(theme.textSecondary)
            
            Button(action: selectFile) {
                Label("選擇檔案", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            
            Button("取消") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(theme.textSecondary)
        }
        .padding(40)
        .frame(width: 400)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "選擇 DOCX 檔案"
        panel.allowedContentTypes = [UTType(filenameExtension: "docx") ?? .data]
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onImport(url)
                dismiss()
            }
        }
    }
}

// MARK: - 匯出中遮罩

struct ExportingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("正在匯出...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

// MARK: - 引用側邊欄

struct CitationSidebarView: View {
    @EnvironmentObject var theme: AppTheme
    
    let libraries: [Library]
    @Binding var selectedLibrary: Library?
    let onInsertCitation: (Entry) -> Void
    
    @State private var searchText = ""
    
    var filteredEntries: [Entry] {
        guard let library = selectedLibrary else { return [] }
        let entries = Array(library.entries ?? [])
        
        if searchText.isEmpty {
            return entries.sorted { $0.title < $1.title }
        }
        
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "quote.bubble")
                    .foregroundColor(theme.accent)
                Text("參考文獻")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }
            .padding()
            .background(theme.elevated)
            
            Divider()
            
            // 文獻庫選擇
            if libraries.count > 1 {
                Picker("文獻庫", selection: $selectedLibrary) {
                    ForEach(libraries, id: \.id) { library in
                        Text(library.name).tag(library as Library?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
            }
            
            // 搜尋
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.textTertiary)
                TextField("搜尋文獻...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(8)
            .padding()
            
            // 文獻列表
            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 32))
                        .foregroundColor(theme.textTertiary)
                    Text(selectedLibrary == nil ? "請選擇文獻庫" : "無符合的文獻")
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEntries, id: \.id) { entry in
                            CitationEntryRow(entry: entry, onInsert: onInsertCitation)
                                .environmentObject(theme)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(theme.background)
    }
}

// MARK: - 引用條目列

struct CitationEntryRow: View {
    @EnvironmentObject var theme: AppTheme
    let entry: Entry
    let onInsert: (Entry) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
            
            HStack {
                Text(entry.author)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
                
                if !entry.year.isEmpty {
                    Text("(\(entry.year))")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                
                Spacer()
                
                Button(action: { onInsert(entry) }) {
                    Label("插入", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(isHovered ? theme.elevated : theme.background)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - AI 格式調整面板

struct AIFormattingPanel: View {
    @EnvironmentObject var theme: AppTheme
    let text: String
    let onApplyRewrite: (String) -> Void
    let onClose: () -> Void
    
    @State private var selectedMode: AIMode = .autoLayout
    @State private var isProcessing = false
    @State private var resultText: String?
    @State private var errorMessage: String?
    
    enum AIMode: String, CaseIterable, Identifiable {
        case autoLayout = "自動排版"
        case academic = "學術格式化"
        case rewrite = "重寫優化"
        case proofread = "潤飾文字"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .autoLayout: return "text.alignleft"
            case .academic: return "graduationcap"
            case .rewrite: return "pencil.and.outline"
            case .proofread: return "checkmark.circle"
            }
        }
        
        var description: String {
            switch self {
            case .autoLayout: return "自動調整標題層級、段落縮排"
            case .academic: return "符合 APA/MLA 論文格式規範"
            case .rewrite: return "改寫選取的文字，使其更流暢"
            case .proofread: return "修正文法、拼寫、標點"
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
                VStack(spacing: 8) {
                    ForEach(AIMode.allCases) { mode in
                        Button(action: { selectedMode = mode; resultText = nil }) {
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
                                        .lineLimit(1)
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
                    Spacer()
                }
                .padding()
                .frame(width: 250)
                .background(theme.elevated.opacity(0.3))
                
                Divider()
                
                // 右側：預覽與執行
                VStack {
                    if isProcessing {
                        ProgressView("AI 正在思考中...")
                            .scaleEffect(1.2)
                    } else if let result = resultText {
                        VStack(alignment: .leading) {
                            Text("建議修改結果：")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            ScrollView {
                                Text(result)
                                    .font(.system(size: 14))
                                    .padding()
                                    .background(theme.background)
                                    .cornerRadius(8)
                            }
                            
                            HStack {
                                Button("取消") { resultText = nil }
                                    .keyboardShortcut(.cancelAction)
                                Spacer()
                                Button("套用修改") {
                                    onApplyRewrite(result)
                                    onClose()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(theme.accent)
                                .keyboardShortcut(.defaultAction)
                            }
                            .padding(.top)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: selectedMode.icon)
                                .font(.system(size: 48))
                                .foregroundColor(theme.accent)
                            
                            Text("準備執行 \(selectedMode.rawValue)")
                                .font(.title3)
                            
                            Text(selectedMode.description)
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Button("開始分析") {
                                runAIAnalysis()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.purple)
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.background)
    }
    
    private func runAIAnalysis() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            // 模擬 AI 處理延遲
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                // 這裡應該呼叫真實的 AI 服務
                // 暫時使用模擬回應
                switch selectedMode {
                case .autoLayout:
                    resultText = text // 實際應回傳排版後的文字
                case .academic:
                    resultText = "根據學術規範，建議調整以下格式..."
                case .rewrite:
                    resultText = "這是經過 AI 優化後的文字內容，語氣更加流暢..."
                case .proofread:
                    resultText = "未發現明顯的文法錯誤。"
                }
                isProcessing = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentEditorView(document: {
        let doc = Document(context: PersistenceController.preview.container.viewContext, title: "測試文件")
        return doc
    }())
    .environmentObject(AppTheme())
    .frame(width: 900, height: 700)
}

