//
//  DocumentEditorView.swift
//  OVEREND
//
//  DOCX 編輯器 - 支援 DOCX/PDF 匯入匯出
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FoundationModels

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
    @State private var canUndo = false
    @State private var canRedo = false
    @State private var currentFont: String = "Helvetica"
    
    // 引用插入面板
    @State private var showCitationInsertionPanel = false
    @State private var showCoverInputSheet = false
    
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
                onUndo: { performUndo() },
                onRedo: { performRedo() },
                onFontChange: { fontName in applyFont(fontName) },
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
                onHighlight: { color in applyHighlight(color) },
                onHeading: { level in applyHeading(level) },
                onList: { type in applyList(type) },
                onInsert: { type in insertElement(type) },
                onChineseOptimization: { type in applyChineseOptimization(type) },
                onApplyNCCUFormat: { applyNCCUFormat() },
                onInsertCover: { showCoverInputSheet = true },
                onAI: { showAIPanel = true },
                onInsertCitationShortcut: { showCitationInsertionPanel = true },
                canUndo: $canUndo,
                canRedo: $canRedo,
                currentFont: $currentFont,
                showCitationSidebar: $showCitationSidebar
            )
            .environmentObject(theme)
            
            // 主編輯區域 + 引用側邊欄
            HSplitView {
                // 編輯區域
                RichTextEditorView(
                    attributedText: $attributedText,
                    textViewRef: $textViewRef,
                    canUndo: $canUndo,
                    canRedo: $canRedo,
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
        .background(Color.clear)
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
        .sheet(isPresented: $showCoverInputSheet) {
            NCCUCoverInputSheet(isPresented: $showCoverInputSheet, onInsert: handleInsertCover)
                .environmentObject(theme)
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
        .sheet(isPresented: $showCitationInsertionPanel) {
            CitationInsertionPanel(
                isPresented: $showCitationInsertionPanel,
                onInsertCitation: { citationText, entries in
                    insertMultipleCitations(citationText, entries: entries)
                }
            )
            .environmentObject(theme)
        }
        .onAppear {
            // 預設選擇第一個文獻庫
            if selectedLibrary == nil {
                selectedLibrary = libraries.first
            }

            // 啟動定時器更新 undo/redo 狀態
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                updateUndoRedoState()
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
        case bold, italic, underline, strikethrough
    }
    
    enum HeadingLevel: Int, CaseIterable, Identifiable {
        case normal = 0
        case h1 = 1
        case h2 = 2
        case h3 = 3
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .normal: return "內文"
            case .h1: return "標題 1"
            case .h2: return "標題 2"
            case .h3: return "標題 3"
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .normal: return 12
            case .h1: return 24
            case .h2: return 18
            case .h3: return 14
            }
        }
    }
    
    enum ListType {
        case bullet
        case numbered
    }
    
    enum InsertType {
        case image
        case table
        case footnote
    }
    
    enum ChineseOptimizationType {
        case punctuation
        case spacing
        case toTraditional
        case toSimplified
        case terminology
    }
    
    // MARK: - Undo/Redo Methods

    private func performUndo() {
        guard let textView = textViewRef else { return }
        textView.undoManager?.undo()
        updateUndoRedoState()
    }

    private func performRedo() {
        guard let textView = textViewRef else { return }
        textView.undoManager?.redo()
        updateUndoRedoState()
    }

    private func updateUndoRedoState() {
        guard let undoManager = textViewRef?.undoManager else { return }
        canUndo = undoManager.canUndo
        canRedo = undoManager.canRedo

        // 更新當前字體顯示
        if let textView = textViewRef,
           let font = textView.typingAttributes[.font] as? NSFont {
            currentFont = font.fontName
        }
    }

    // MARK: - Formatting Methods

    private func applyFont(_ fontName: String) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else {
            // 如果沒有選取文字，更新預設字體
            currentFont = fontName
            if let font = NSFont(name: fontName, size: 12) {
                textView.typingAttributes[.font] = font
            }
            return
        }

        guard let textStorage = textView.textStorage else { return }

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            guard let currentFont = value as? NSFont else { return }

            // 保持原有字體大小和特性
            let fontSize = currentFont.pointSize
            let traits = currentFont.fontDescriptor.symbolicTraits

            // 創建新字體
            if let newFont = NSFont(name: fontName, size: fontSize) {
                var finalFont = newFont

                // 保留粗體和斜體特性
                if traits.contains(.bold) {
                    finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .boldFontMask)
                }
                if traits.contains(.italic) {
                    finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .italicFontMask)
                }

                textStorage.addAttribute(.font, value: finalFont, range: attrRange)
            }
        }
        textStorage.endEditing()

        currentFont = fontName
        attributedText = textView.attributedString()
        saveDocument()
    }

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
            case .strikethrough:
                let hasStrikethrough = textStorage.attribute(.strikethroughStyle, at: attrRange.location, effectiveRange: nil) != nil
                if hasStrikethrough {
                    textStorage.removeAttribute(.strikethroughStyle, range: attrRange)
                } else {
                    textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: attrRange)
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
                .foregroundColor: NSColor.black,
                .font: NSFont.systemFont(ofSize: 12)
            ]
        )
        
        textStorage.insert(citationAttributed, at: insertionPoint)
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("已插入引用")
    }
    
    /// 插入多重引用（從 CitationInsertionPanel）
    private func insertMultipleCitations(_ citationText: String, entries: [Entry]) {
        guard let textView = textViewRef else { return }
        
        let insertionPoint = textView.selectedRange().location
        guard let textStorage = textView.textStorage else { return }
        
        let citationAttributed = NSAttributedString(
            string: citationText,
            attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.systemFont(ofSize: 12)
            ]
        )
        
        textStorage.insert(citationAttributed, at: insertionPoint)
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("已插入 \(entries.count) 篇引用")
    }
    
    private func applyHighlight(_ color: NSColor) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        if color == .clear {
            textStorage.removeAttribute(.backgroundColor, range: range)
        } else {
            textStorage.addAttribute(.backgroundColor, value: color, range: range)
        }
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    private func applyHeading(_ level: HeadingLevel) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        // Apply to the paragraph
        let paragraphRange = (textView.string as NSString).paragraphRange(for: range)
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        
        // Set Font
        let font = NSFont.systemFont(ofSize: level.fontSize, weight: level == .normal ? .regular : .bold)
        textStorage.addAttribute(.font, value: font, range: paragraphRange)
        
        // Reset paragraph style if normal, or set specific spacing for headings
        let paragraphStyle = NSMutableParagraphStyle()
        if level != .normal {
            paragraphStyle.paragraphSpacing = 12
            paragraphStyle.paragraphSpacingBefore = 6
        }
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
        
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    private func applyList(_ type: ListType) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        let paragraphRange = (textView.string as NSString).paragraphRange(for: range)
        
        guard let textStorage = textView.textStorage else { return }
        
        let marker = type == .bullet ? "•\t" : "1.\t"
        
        textStorage.beginEditing()
        
        // Check if already has list marker
        let currentText = (textView.string as NSString).substring(with: paragraphRange)
        if currentText.hasPrefix("•\t") || currentText.range(of: #"^\d+\.\t"#, options: .regularExpression) != nil {
            // Remove list (simplified logic: just remove prefix)
            // In a real app, we'd use NSTextList, but for this simplified editor, we toggle prefix
            // This is a placeholder for robust list handling
            // For now, let's just insert the marker if not present
        } else {
            textStorage.insert(NSAttributedString(string: marker), at: paragraphRange.location)
            
            // Set indentation
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20, options: [:])]
            
            // We need to apply this to the new range including the marker
            let newRange = NSRange(location: paragraphRange.location, length: paragraphRange.length + marker.count)
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: newRange)
        }
        
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    private func insertElement(_ type: InsertType) {
        guard let textView = textViewRef else { return }
        
        switch type {
        case .image:
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.begin { response in
                if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    // Resize to fit width if needed (simplified)
                    attachment.bounds = CGRect(x: 0, y: 0, width: 300, height: 300 * (image.size.height / image.size.width))
                    
                    let attrString = NSAttributedString(attachment: attachment)
                    textView.textStorage?.insert(attrString, at: textView.selectedRange().location)
                    self.saveDocument()
                }
            }
        case .table:
            // Simplified table insertion (placeholder)
            let tablePlaceholder = "\n| Column 1 | Column 2 |\n| -------- | -------- |\n| Cell 1   | Cell 2   |\n"
            textView.insertText(tablePlaceholder, replacementRange: textView.selectedRange())
            saveDocument()
        case .footnote:
            // Simplified footnote
            let footnote = " [^1]"
            textView.insertText(footnote, replacementRange: textView.selectedRange())
            saveDocument()
        }
    }
    
    private func applyChineseOptimization(_ type: ChineseOptimizationType) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        let replaceRange = range.length > 0 ? range : NSRange(location: 0, length: textView.string.count)
        
        guard let textStorage = textView.textStorage else { return }
        let currentText = (textView.string as NSString).substring(with: replaceRange)
        var newText = currentText
        
        switch type {
        case .punctuation:
            newText = ChineseOptimizationService.shared.convertToFullWidthPunctuation(currentText)
        case .spacing:
            newText = ChineseOptimizationService.shared.adjustSpacing(currentText)
        case .toTraditional:
            newText = ChineseOptimizationService.shared.convertScript(currentText, to: .traditional)
        case .toSimplified:
            newText = ChineseOptimizationService.shared.convertScript(currentText, to: .simplified)
        case .terminology:
            let suggestions = ChineseOptimizationService.shared.checkTerminology(currentText)
            if suggestions.isEmpty {
                ToastManager.shared.showSuccess("未發現需修正的術語")
                return
            }
            // 簡單實作：自動替換第一個建議（實際應用應顯示列表供選擇）
            for suggestion in suggestions {
                newText = newText.replacingOccurrences(of: suggestion.original, with: suggestion.suggestion)
            }
            ToastManager.shared.showSuccess("已修正 \(suggestions.count) 個術語")
        }
        
        if newText != currentText {
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: replaceRange, with: newText)
            textStorage.endEditing()
            
            attributedText = textView.attributedString()
            saveDocument()
            ToastManager.shared.showSuccess("中文優化完成")
        }
    }
    
    private func applyNCCUFormat() {
        guard let textView = textViewRef, let textStorage = textView.textStorage else { return }
        
        NCCUFormatService.shared.applyFormat(to: textStorage)
        // NCCUFormatService.shared.applyPageSettings(to: textView)
        
        attributedText = textView.attributedString()
        saveDocument()
        ToastManager.shared.showSuccess("已套用政大論文格式")
    }
    
    private func handleInsertCover(_ info: NCCUCoverInfo) {
        guard let textView = textViewRef, let textStorage = textView.textStorage else { return }
        
        let cover = NCCUFormatService.shared.generateCover(info: info)
        
        textStorage.beginEditing()
        textStorage.insert(cover, at: 0)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
        ToastManager.shared.showSuccess("已插入封面")
    }
    

    
    // MARK: - Methods
    
    private func saveDocument() {
        document.attributedString = attributedText
        document.updatedAt = Date()
        try? viewContext.save()
        updateUndoRedoState()
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
                
                // 將所有文字顏色改為黑色（適應白色紙張）
                let mutableImported = NSMutableAttributedString(attributedString: imported)
                mutableImported.addAttribute(
                    .foregroundColor,
                    value: NSColor.black,
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
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onFontChange: ((String) -> Void)?
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
    var onHighlight: ((NSColor) -> Void)?
    var onHeading: ((DocumentEditorView.HeadingLevel) -> Void)?
    var onList: ((DocumentEditorView.ListType) -> Void)?
    var onInsert: ((DocumentEditorView.InsertType) -> Void)?
    var onChineseOptimization: ((DocumentEditorView.ChineseOptimizationType) -> Void)?
    var onApplyNCCUFormat: (() -> Void)?
    var onInsertCover: (() -> Void)?
    var onAI: (() -> Void)?
    var onInsertCitationShortcut: (() -> Void)?

    // Undo/Redo 狀態
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    @Binding var currentFont: String
    
    // 側邊欄控制
    @Binding var showCitationSidebar: Bool
    
    // 狀態
    @State private var showColorPicker = false
    @State private var selectedColor: Color = .black
    @State private var selectedHighlightColor: Color = .clear
    @State private var currentHeading: DocumentEditorView.HeadingLevel = .normal

    // 可用字體列表
    struct FontOption: Hashable {
        let name: String
        let displayName: String
    }

    let availableFonts: [FontOption] = [
        FontOption(name: "PMingLiU", displayName: "新細明體"),
        FontOption(name: "Times New Roman", displayName: "Times New Roman"),
        FontOption(name: "Arial", displayName: "Arial"),
        FontOption(name: "Helvetica", displayName: "Helvetica"),
        FontOption(name: "PingFang TC", displayName: "蘋方-繁"),
        FontOption(name: "Heiti TC", displayName: "黑體-繁"),
        FontOption(name: "Kaiti TC", displayName: "楷體-繁"),
        FontOption(name: "Georgia", displayName: "Georgia"),
        FontOption(name: "Courier New", displayName: "Courier New"),
        FontOption(name: "Verdana", displayName: "Verdana")
    ]

    func getFontDisplayName(_ fontName: String) -> String {
        availableFonts.first { $0.name == fontName }?.displayName ?? fontName
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 1200
            
            VStack(spacing: 0) {
                // 主工具列 - 放大優化
                HStack(spacing: 16) {
                    // 標題 - 放大
                    Text(document.title)
                        .font(theme.fontDisplaySmall)  // 20pt
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    // AI 調整 - 增大
                    Button(action: { onAI?() }) {
                        Label("AI 調整", systemImage: "sparkles")
                            .font(theme.fontButton)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.large)
                    
                    // 引用側邊欄切換 - 增大
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
                .background(theme.toolbarGlass)
                
                Divider()
                
                // 格式化工具列
                HStack(spacing: 8) {
                    // 1. 復原/重作 (Always Visible)
                    SwiftUI.Group {
                        HStack(spacing: 4) {
                            FormatButton(icon: "arrow.uturn.backward", tooltip: "復原 (⌘Z)", action: onUndo, disabled: !canUndo)
                            FormatButton(icon: "arrow.uturn.forward", tooltip: "重作 (⇧⌘Z)", action: onRedo, disabled: !canRedo)
                        }
                        .padding(4)
                        .background(theme.elevated.opacity(0.5))
                        .cornerRadius(6)
                        
                        Divider().frame(height: 20)
                    }
                    
                    // 2. 標題樣式 (Always Visible)
                    Menu {
                        ForEach(DocumentEditorView.HeadingLevel.allCases) { level in
                            Button(action: { 
                                currentHeading = level
                                onHeading?(level) 
                            }) {
                                HStack {
                                    Text(level.displayName)
                                        .font(.system(size: level.fontSize))
                                    if currentHeading == level {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentHeading.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 50, alignment: .leading)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .padding(6)
                        .background(theme.elevated.opacity(0.5))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .help("標題樣式")
                    
                    Divider().frame(height: 20)
                    
                    // 3. 字體與大小 (Compact: Move to More)
                    if !isCompact {
                        fontControls
                        Divider().frame(height: 20)
                    }
                    
                    // 4. 基本格式 (Bold/Italic/Underline) (Always Visible)
                    HStack(spacing: 4) {
                        FormatButton(icon: "bold", tooltip: "粗體 (⌘B)", action: onBold)
                        FormatButton(icon: "italic", tooltip: "斜體 (⌘I)", action: onItalic)
                        FormatButton(icon: "underline", tooltip: "底線 (⌘U)", action: onUnderline)
                    }
                    .padding(4)
                    .background(theme.elevated.opacity(0.5))
                    .cornerRadius(6)
                    
                    Divider().frame(height: 20)
                    
                    // 5. 顏色與螢光筆 (Compact: Simplified)
                    HStack(spacing: 4) {
                        // 文字顏色
                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 24, height: 24)
                            .help("文字顏色")
                            .onChange(of: selectedColor) { newColor in
                                onTextColor?(NSColor(newColor))
                            }
                        
                        // 螢光筆
                        Menu {
                            Button(action: { onHighlight?(.clear) }) {
                                Label("無", systemImage: "slash.circle")
                            }
                            Button(action: { onHighlight?(.yellow) }) {
                                Label("黃色", systemImage: "circle.fill").foregroundColor(.yellow)
                            }
                            Button(action: { onHighlight?(.green) }) {
                                Label("綠色", systemImage: "circle.fill").foregroundColor(.green)
                            }
                            Button(action: { onHighlight?(.cyan) }) {
                                Label("藍色", systemImage: "circle.fill").foregroundColor(.cyan)
                            }
                            Button(action: { onHighlight?(.magenta) }) {
                                Label("粉紅", systemImage: "circle.fill").foregroundColor(.pink)
                            }
                        } label: {
                            Image(systemName: "highlighter")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textPrimary)
                                .frame(width: 24, height: 24)
                        }
                        .menuStyle(.borderlessButton)
                        .help("螢光筆")
                    }
                    .padding(4)
                    .background(theme.elevated.opacity(0.5))
                    .cornerRadius(6)
                    
                    Divider().frame(height: 20)
                    
                    // 6. 清單與對齊 (Compact: Move to More)
                    if !isCompact {
                        listAndAlignControls
                        Divider().frame(height: 20)
                    }
                    
                    // 7. 插入與引用 (Always Visible)
                    HStack(spacing: 4) {
                        // 插入引用快捷鈕
                        Button(action: { onInsertCitationShortcut?() }) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 28, height: 28)
                        .background(theme.elevated.opacity(0.5))
                        .cornerRadius(6)
                        .help("插入引用 (⌘⇧C)")
                        
                        // 插入選單
                        Menu {
                            Button(action: { onInsert?(.image) }) {
                                Label("圖片", systemImage: "photo")
                            }
                            Button(action: { onInsert?(.table) }) {
                                Label("表格", systemImage: "tablecells")
                            }
                            Button(action: { onInsert?(.footnote) }) {
                                Label("腳註", systemImage: "text.alignleft")
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("插入")
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                            }
                            .padding(6)
                            .background(theme.elevated.opacity(0.5))
                            .cornerRadius(6)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    // 8. 中文優化 (Compact: Move to More)
                    if !isCompact {
                        Divider().frame(height: 20)
                        chineseOptimizationMenu
                        
                        Divider().frame(height: 20)
                        nccuTemplateButton
                    }
                    
                    Spacer()
                    
                    // 9. 更多選單 (Compact Only)
                    if isCompact {
                        Menu {
                            // 字體控制
                            Section("字體") {
                                Button("放大字體") { onIncreaseFontSize?() }
                                Button("縮小字體") { onDecreaseFontSize?() }
                                Menu("選擇字體") {
                                    ForEach(availableFonts, id: \.self) { font in
                                        Button(font.displayName) { onFontChange?(font.name) }
                                    }
                                }
                            }
                            
                            // 段落控制
                            Section("段落") {
                                Button("靠左對齊") { onAlignLeft?() }
                                Button("置中對齊") { onAlignCenter?() }
                                Button("靠右對齊") { onAlignRight?() }
                                Button("項目符號") { onList?(.bullet) }
                                Button("編號清單") { onList?(.numbered) }
                            }
                            
                            // 中文優化
                            Section("中文優化") {
                                Button("全形標點轉換") { onChineseOptimization?(.punctuation) }
                                Button("中英文間距") { onChineseOptimization?(.spacing) }
                                Button("轉繁體") { onChineseOptimization?(.toTraditional) }
                                Button("轉簡體") { onChineseOptimization?(.toSimplified) }
                                Button("台灣學術用語檢查") { onChineseOptimization?(.terminology) }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(theme.textPrimary)
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.trailing, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.toolbarGlass)
            }
        }
        .frame(height: 100)
    }
    
    // MARK: - Subviews
    
    private var fontControls: some View {
        HStack(spacing: 8) {
            // 字體選擇器
            Menu {
                ForEach(availableFonts, id: \.self) { font in
                    Button(action: { onFontChange?(font.name) }) {
                        HStack {
                            Text(font.displayName)
                                .font(.custom(font.name, size: 14))
                            if currentFont == font.name {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "textformat")
                        .font(.system(size: 12))
                    Text(getFontDisplayName(currentFont))
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 140)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            .help("字體")

            // 字體大小
            HStack(spacing: 4) {
                FormatButton(icon: "textformat.size.smaller", tooltip: "縮小字體", action: onDecreaseFontSize)
                FormatButton(icon: "textformat.size.larger", tooltip: "放大字體", action: onIncreaseFontSize)
            }
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
        }
    }
    
    private var listAndAlignControls: some View {
        HStack(spacing: 8) {
            // 對齊
            HStack(spacing: 4) {
                FormatButton(icon: "text.alignleft", tooltip: "靠左對齊", action: onAlignLeft)
                FormatButton(icon: "text.aligncenter", tooltip: "置中對齊", action: onAlignCenter)
                FormatButton(icon: "text.alignright", tooltip: "靠右對齊", action: onAlignRight)
            }
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            
            // 清單
            HStack(spacing: 4) {
                FormatButton(icon: "list.bullet", tooltip: "項目符號", action: { onList?(.bullet) })
                FormatButton(icon: "list.number", tooltip: "編號清單", action: { onList?(.numbered) })
            }
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            
            // 行距
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
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            .help("行距")
        }
    }
    
    private var chineseOptimizationMenu: some View {
        Menu {
            Button("全形標點轉換") { 
                onChineseOptimization?(.punctuation)
            }
            Button("中英文間距自動調整") { 
                onChineseOptimization?(.spacing)
            }
            Menu("繁簡轉換") {
                Button("轉繁體") { onChineseOptimization?(.toTraditional) }
                Button("轉簡體") { onChineseOptimization?(.toSimplified) }
            }
            Button("台灣學術用語檢查") { 
                onChineseOptimization?(.terminology)
            }
        } label: {
            Label("中文優化", systemImage: "character.book.closed.zh")
                .font(.system(size: 12))
                .padding(6)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
    }
    
    private var nccuTemplateButton: some View {
        Menu {
            Button("套用格式") { onApplyNCCUFormat?() }
            Button("插入封面") { onInsertCover?() }
        } label: {
            Label("政大模版", systemImage: "doc.text.image")
                .font(.system(size: 12))
                .padding(6)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
        .help("政大論文模版工具")
    }
    


}

// MARK: - 格式化按鈕

struct FormatButton: View {
    let icon: String
    let tooltip: String
    var action: (() -> Void)?
    var disabled: Bool = false

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
        .foregroundColor(disabled ? .gray : .white)
        .help(tooltip)
        .disabled(disabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}


// MARK: - 富文本編輯器（A4 紙張模擬）

struct RichTextEditorView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    @EnvironmentObject var theme: AppTheme
    let onTextChange: () -> Void
    
    // A4 尺寸 (72 DPI: 595 x 842 pt)
    static let a4Width: CGFloat = 595
    static let a4Margin: CGFloat = 72  // 1 inch margin
    static let textViewIdentifier = "mainEditorTextView"
    
    func makeNSView(context: Context) -> NSScrollView {
        // 創建容器 ScrollView
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
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
        textContainer.heightTracksTextView = false
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        let textView = NSTextView(frame: NSRect(
            x: Self.a4Margin,
            y: Self.a4Margin,
            width: Self.a4Width - (Self.a4Margin * 2),
            height: 842 - (Self.a4Margin * 2)
        ), textContainer: textContainer)

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = []
        textView.maxSize = NSSize(width: Self.a4Width - (Self.a4Margin * 2), height: .greatestFiniteMagnitude)
        textView.minSize = NSSize(width: Self.a4Width - (Self.a4Margin * 2), height: 842 - (Self.a4Margin * 2))
        textView.identifier = NSUserInterfaceItemIdentifier(Self.textViewIdentifier)
        
        // 紙張樣式 - 根據主題調整
        if theme.isPrideMode {
            textView.backgroundColor = .clear
            textView.textColor = .white
            textView.insertionPointColor = .white
        } else {
            textView.backgroundColor = .white
            textView.textColor = .black
            textView.insertionPointColor = .black
        }
        textView.font = .systemFont(ofSize: 12)
        
        // 預設輸入屬性
        textView.typingAttributes = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        // 紙張視圖
        let paperView = NSView(frame: NSRect(x: 0, y: 0, width: Self.a4Width, height: 842))
        paperView.wantsLayer = true
        paperView.layer?.backgroundColor = theme.isPrideMode ? NSColor.clear.cgColor : NSColor.white.cgColor
        
        if !theme.isPrideMode {
            paperView.layer?.shadowColor = NSColor.black.cgColor
            paperView.layer?.shadowOffset = CGSize(width: 0, height: -2)
            paperView.layer?.shadowRadius = 8
            paperView.layer?.shadowOpacity = 0.3
        }
        
        paperView.addSubview(textView)
        
        // 設置紙張居中的剪輯視圖
        let clipView = CenteredClipView()
        clipView.documentView = paperView
        clipView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        clipView.drawsBackground = true
        
        scrollView.contentView = clipView
        scrollView.documentView = paperView
        
        // 初始內容
        textView.textStorage?.setAttributedString(attributedText)
        
        // 儲存參考並初始化 undo/redo 狀態
        DispatchQueue.main.async {
            self.textViewRef = textView
        }

        // 設置 undo/redo 觀察者由 Coordinator 管理
        context.coordinator.setupObservers(for: textView)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // 使用緩存的 textView 參考以提升性能
        guard let textView = context.coordinator.cachedTextView ?? {
            guard let paperView = nsView.documentView,
                  let tv = paperView.subviews.first(where: { $0.identifier?.rawValue == Self.textViewIdentifier }) as? NSTextView else { return nil }
            context.coordinator.cachedTextView = tv
            return tv
        }() else { return }

        // 使用改進的 hash 組合方式進行快速比較以提升性能
        let newHash = attributedText.string.hashValue &+ (attributedText.length &* 31)
        if context.coordinator.lastContentHash != newHash {
            context.coordinator.lastContentHash = newHash
            
            let selectedRanges = textView.selectedRanges
            // 使用批次更新來提升性能
            textView.textStorage?.beginEditing()
            textView.textStorage?.setAttributedString(attributedText)
            textView.textStorage?.endEditing()
            textView.selectedRanges = selectedRanges
        }

        // 讓 textView 自動調整大小以適應內容
        if let layoutManager = textView.layoutManager,
           let textContainer = textView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let contentHeight = max(842, usedRect.height + Self.a4Margin * 2)

            // 更新紙張和 textView 的高度
            paperView.frame.size = NSSize(width: Self.a4Width, height: contentHeight)
            textView.frame = NSRect(
                x: Self.a4Margin,
                y: Self.a4Margin,
                width: Self.a4Width - (Self.a4Margin * 2),
                height: contentHeight - Self.a4Margin * 2
            )

            // 通知 scrollView 內容大小已改變
            nsView.documentView?.needsLayout = true
        }
        
        // 更新主題相關樣式
        nsView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        if let clipView = nsView.contentView as? CenteredClipView {
            clipView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        }
        
        if let paperView = nsView.documentView {
            paperView.layer?.backgroundColor = theme.isPrideMode ? NSColor.clear.cgColor : NSColor.white.cgColor
            if theme.isPrideMode {
                paperView.layer?.shadowOpacity = 0.0
            } else {
                paperView.layer?.shadowOpacity = 0.3
            }
        }
        
        if let textView = context.coordinator.cachedTextView {
            textView.backgroundColor = theme.isPrideMode ? .clear : .white
            textView.textColor = theme.isPrideMode ? .white : .black
            textView.insertionPointColor = theme.isPrideMode ? .white : .black
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView
        var observers: [NSObjectProtocol] = []
        var lastContentHash: Int = 0
        weak var cachedTextView: NSTextView?

        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }
        
        deinit {
            // 移除所有觀察者以防止記憶體洩漏
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        func setupObservers(for textView: NSTextView) {
            // 緩存 textView 參考
            cachedTextView = textView
            
            // 監聽 undo manager 通知
            let undoObserver = NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidUndoChange,
                object: textView.undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState(for: textView)
            }
            observers.append(undoObserver)
            
            let redoObserver = NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidRedoChange,
                object: textView.undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState(for: textView)
            }
            observers.append(redoObserver)
        }
        
        func updateUndoRedoState(for textView: NSTextView) {
            guard let undoManager = textView.undoManager else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.canUndo = undoManager.canUndo
                self.parent.canRedo = undoManager.canRedo
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
            parent.onTextChange()
            updateUndoRedoState(for: textView)
        }

        // 監聽 undo/redo 狀態變化
        func undoManagerDidUndo(_ notification: Notification) {
            parent.onTextChange()
        }

        func undoManagerDidRedo(_ notification: Notification) {
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
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(theme.toolbarGlass)
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
                
                Divider()
                
                // 右側：預覽與執行
                VStack {
                    if isProcessing {
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
                    } else if let error = errorMessage {
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
                    } else if let suggestions = suggestions {
                        // 顯示寫作建議
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
                    } else if let result = resultText {
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
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.background)
    }
    
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

// MARK: - Preview

#Preview {
    DocumentEditorView(document: {
        let doc = Document(context: PersistenceController.preview.container.viewContext, title: "測試文件")
        return doc
    }())
    .environmentObject(AppTheme())
    .frame(width: 900, height: 700)
}

