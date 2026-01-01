//
//  WriterView.swift
//  OVEREND
//
//  文章寫作主視圖 - 整合編輯器、工具列、引用功能
//

import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers

/// 文章寫作視圖
struct WriterView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 編輯的文檔
    @ObservedObject var document: Document
    
    // 編輯器狀態
    @State private var attributedString: NSAttributedString
    @State private var textView: NSTextView?
    @State private var totalPages: Int = 1
    @State private var wordCount: Int = 0
    @State private var isSaving: Bool = false
    @State private var lastSaved: Date?
    
    // AI 助手狀態
    @State private var selectedText: String = ""
    @State private var showAIAssistant: Bool = true
    
    // 彈出視窗狀態
    @State private var showCitationPicker: Bool = false
    @State private var showExportOptions: Bool = false
    @State private var showReferenceGenerator: Bool = false
    
    // 自動儲存計時器
    @State private var autoSaveTimer: Timer?
    
    init(document: Document) {
        self.document = document
        _attributedString = State(initialValue: document.attributedString)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 主要內容
            VStack(spacing: 0) {
                // 編輯器
                RichTextEditor(
                    attributedString: Binding(
                        get: { attributedString },
                        set: { newValue in
                            attributedString = newValue
                            updateWordCount(newValue)
                            scheduleAutoSave()
                        }
                    ),
                    onTextChange: { newValue in
                        attributedString = newValue
                        updateWordCount(newValue)
                        scheduleAutoSave()
                    },
                    onSelectionChange: { range, attributes in
                        // 更新選取的文字給 AI 助手
                        if range.length > 0 {
                            let string = attributedString.string
                            let start = string.index(string.startIndex, offsetBy: range.location)
                            let end = string.index(start, offsetBy: min(range.length, string.count - range.location))
                            selectedText = String(string[start..<end])
                        } else {
                            selectedText = ""
                        }
                    }
                )
                .frame(minHeight: 400)
                
                Divider()
                
                // 狀態列
                statusBar
            }
            
            // AI 浮動助手面板（右下角）
            if showAIAssistant {
                FloatingAIAssistant(
                    textView: $textView,
                    selectedText: $selectedText,
                    onReplaceText: { newText in
                        replaceSelectedText(with: newText)
                    },
                    onInsertReferences: { references in
                        insertReferences(references)
                    }
                )
                .padding(16)
            }
        }
        .navigationTitle(document.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAIAssistant.toggle() }) {
                    Label(
                        showAIAssistant ? "隱藏 AI" : "顯示 AI",
                        systemImage: "apple.intelligence"
                    )
                }
                .help("切換 AI 助手面板")
            }
        }
        .sheet(isPresented: $showCitationPicker) {
            CitationPicker { citation in
                insertCitation(citation)
            }
        }
        .sheet(isPresented: $showReferenceGenerator) {
            ReferenceGeneratorView(document: document)
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(document: document, attributedString: attributedString)
        }
        .onAppear {
            updateWordCount(attributedString)
        }
        .onDisappear {
            saveDocument()
            autoSaveTimer?.invalidate()
        }
    }
    
    // MARK: - 狀態列
    
    private var statusBar: some View {
        HStack {
            // 左側：字數和引用統計
            HStack(spacing: 12) {
                Label("\(wordCount) 字", systemImage: "character.cursor.ibeam")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                    .frame(height: 12)
                
                let citationCount = document.citationArray.count
                Label("\(citationCount) 筆引用", systemImage: "quote.bubble")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 中間：功能按鈕
            HStack(spacing: 8) {
                Button(action: { showCitationPicker = true }) {
                    Label("插入引用", systemImage: "book.pages")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: { showReferenceGenerator = true }) {
                    Label("參考文獻", systemImage: "list.bullet.rectangle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: { showExportOptions = true }) {
                    Label("匯出", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            // 右側：儲存狀態
            if isSaving {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("儲存中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let saved = lastSaved {
                Label("已儲存於 \(saved.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - AI 輔助方法
    
    private func replaceSelectedText(with newText: String) {
        guard let tv = textView else { return }
        
        let range = tv.selectedRange()
        if range.length > 0 {
            tv.textStorage?.replaceCharacters(in: range, with: newText)
            attributedString = tv.attributedString()
            scheduleAutoSave()
        }
    }
    
    private func insertReferences(_ references: String) {
        guard let tv = textView else { return }
        
        // 在文末插入參考文獻
        let refAttr = NSAttributedString(string: "\n\n" + references)
        tv.textStorage?.append(refAttr)
        attributedString = tv.attributedString()
        scheduleAutoSave()
    }
    
    // MARK: - 輔助方法
    
    private func updateWordCount(_ text: NSAttributedString) {
        // 計算中文和英文字數
        let string = text.string
        var count = 0
        
        string.enumerateSubstrings(in: string.startIndex..., options: .byWords) { _, _, _, _ in
            count += 1
        }
        
        // 加上中文字符數（每個漢字算一個字）
        let chineseCharCount = string.unicodeScalars.filter { 
            CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}").contains($0) 
        }.count
        
        wordCount = count + chineseCharCount
    }
    
    private func insertCitation(_ citation: String) {
        // 創建引用屬性字符串
        let citationAttr = NSMutableAttributedString(string: "[\(citation)]")
        citationAttr.addAttributes([
            .foregroundColor: NSColor.systemBlue,
            .link: "citation://\(citation)"
        ], range: NSRange(location: 0, length: citationAttr.length))
        
        // 將引用插入到當前位置
        let mutableText = NSMutableAttributedString(attributedString: attributedString)
        // 簡單地附加到末尾（實際使用時可以改進為插入到游標位置）
        mutableText.append(citationAttr)
        
        attributedString = mutableText
        scheduleAutoSave()
    }
    
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            saveDocument()
        }
    }
    
    private func saveDocument() {
        isSaving = true
        
        document.attributedString = attributedString
        document.updatedAt = Date()
        
        do {
            try viewContext.save()
            lastSaved = Date()
        } catch {
            print("儲存失敗：\(error.localizedDescription)")
        }
        
        isSaving = false
    }
}

// MARK: - 參考文獻生成器

struct ReferenceGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var document: Document
    
    var body: some View {
        VStack(spacing: 16) {
            Text("生成參考文獻")
                .font(.headline)
            
            if document.citationArray.isEmpty {
                Text("尚未插入任何引用")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(document.citationArray, id: \.id) { entry in
                            Text(CitationService.generateAPA(entry: entry))
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 300)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
            }
            
            HStack {
                Button("複製全部") {
                    let references = document.citationArray
                        .map { CitationService.generateAPA(entry: $0) }
                        .joined(separator: "\n\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(references, forType: .string)
                }
                .disabled(document.citationArray.isEmpty)
                
                Spacer()
                
                Button("關閉") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
        }
        .padding()
        .frame(width: 500)
    }
}

// MARK: - 匯出選項視圖

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var document: Document
    let attributedString: NSAttributedString
    
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var includeReferences: Bool = true
    @State private var isExporting: Bool = false
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case rtf = "RTF"
        // case docx = "Word (.docx)"  // 第二階段
        // case latex = "LaTeX"        // 第二階段
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("匯出文件")
                .font(.headline)
            
            // 格式選擇
            VStack(alignment: .leading, spacing: 8) {
                Text("匯出格式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            // 選項
            Toggle("包含參考文獻列表", isOn: $includeReferences)
            
            Divider()
            
            // 按鈕
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("匯出") {
                    exportDocument()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
            }
        }
        .padding()
        .frame(width: 350)
    }
    
    private func exportDocument() {
        isExporting = true
        
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = document.title
        
        switch selectedFormat {
        case .pdf:
            panel.allowedContentTypes = [.pdf]
        case .rtf:
            panel.allowedContentTypes = [.rtf]
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    switch selectedFormat {
                    case .pdf:
                        try exportToPDF(url: url)
                    case .rtf:
                        try exportToRTF(url: url)
                    }
                    dismiss()
                } catch {
                    print("匯出失敗：\(error.localizedDescription)")
                }
            }
            isExporting = false
        }
    }
    
    private func exportToPDF(url: URL) throws {
        // 建立用於列印的 TextView
        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 468, height: 648))
        textView.textStorage?.setAttributedString(attributedString)
        
        // 如果包含參考文獻
        if includeReferences && !document.citationArray.isEmpty {
            let refHeader = NSAttributedString(string: "\n\n參考文獻\n\n", attributes: [
                .font: NSFont.boldSystemFont(ofSize: 16)
            ])
            textView.textStorage?.append(refHeader)
            
            for entry in document.citationArray {
                let ref = NSAttributedString(string: CitationService.generateAPA(entry: entry) + "\n\n")
                textView.textStorage?.append(ref)
            }
        }
        
        // 生成 PDF
        let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        
        let pdfData = textView.dataWithPDF(inside: textView.bounds)
        try pdfData.write(to: url)
    }
    
    private func exportToRTF(url: URL) throws {
        var fullText = NSMutableAttributedString(attributedString: attributedString)
        
        // 如果包含參考文獻
        if includeReferences && !document.citationArray.isEmpty {
            let refHeader = NSAttributedString(string: "\n\n參考文獻\n\n", attributes: [
                .font: NSFont.boldSystemFont(ofSize: 16)
            ])
            fullText.append(refHeader)
            
            for entry in document.citationArray {
                let ref = NSAttributedString(string: CitationService.generateAPA(entry: entry) + "\n\n")
                fullText.append(ref)
            }
        }
        
        let rtfData = try fullText.data(
            from: NSRange(location: 0, length: fullText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        try rtfData.write(to: url)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context, title: "測試文件")
    
    return WriterView(document: doc)
        .environment(\.managedObjectContext, context)
        .frame(width: 800, height: 600)
}
