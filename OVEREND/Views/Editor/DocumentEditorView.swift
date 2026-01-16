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
    @Environment(\.managedObjectContext) var viewContext
    
    @State var attributedText: NSAttributedString
    @State private var showExportMenu = false
    @State private var showImportSheet = false
    @State var isExporting = false
    @State private var isPandocAvailable = PandocService.isAvailable
    @State var textViewRef: NSTextView?
    @State private var showCitationSidebar = true
    @State private var isAIProcessing = false
    
    // AI 寫作助手（預設關閉）
    @State private var showWritingAssistant = false
    @State private var cursorPosition: Int = 0
    @State private var canUndo = false
    @State private var canRedo = false
    @State var currentFont: String = "Helvetica"
    
    // 封面輸入
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
                canUndo: $canUndo,
                canRedo: $canRedo,
                currentFont: $currentFont,
                showCitationSidebar: $showCitationSidebar
            )
            .environmentObject(theme)
            
            // 主編輯區域 + 引用側邊欄 + AI 助手
            HSplitView {
                // 編輯區域
                ZStack(alignment: .bottomTrailing) {
                    RichTextEditorView(
                        attributedText: $attributedText,
                        textViewRef: $textViewRef,
                        onTextChange: {
                            saveDocument()
                            updateCursorPosition()
                        }
                    )
                    .environmentObject(theme)
                    
                    // AI 助手浮動按鈕（預設關閉）
                    if #available(macOS 26.0, *) {
                        aiToggleButton
                    }
                }
                .frame(minWidth: 400)
                
                // AI 寫作助手側邊欄（使用者手動開啟）
                if #available(macOS 26.0, *) {
                    if showWritingAssistant {
                        WritingAssistantView(
                            documentText: attributedText.string,
                            cursorPosition: $cursorPosition,
                            isPresented: $showWritingAssistant,
                            selectedLibrary: selectedLibrary
                        )
                        .environmentObject(theme)
                    }
                }
                
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
        .onAppear {
            // 不預設選擇文獻庫，由使用者手動選擇
            
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
    
    // MARK: - AI 助手開關按鈕
    
    @available(macOS 26.0, *)
    private var aiToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showWritingAssistant.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showWritingAssistant ? "sparkles" : "sparkles")
                    .font(.body)
                if !showWritingAssistant {
                    Text("AI 助手")
                        .font(.caption)
                }
            }
            .foregroundStyle(showWritingAssistant ? .white : theme.textPrimary)
            .padding(.horizontal, showWritingAssistant ? 10 : 12)
            .padding(.vertical, 8)
            .background(
                showWritingAssistant ? theme.accent : theme.elevated,
                in: Capsule()
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .padding()
        .help(showWritingAssistant ? "關閉 AI 助手" : "開啟 AI 助手（預設關閉）")
    }
    
    /// 更新游標位置
    private func updateCursorPosition() {
        guard let textView = textViewRef else { return }
        cursorPosition = textView.selectedRange().location
    }
    
    // MARK: - Formatting Types
    

    
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

    func updateUndoRedoState() {
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


    

    

    
    // MARK: - Citation Methods
    

    

    

    

    

    
    // MARK: - Methods
    

    

    

}

// MARK: - 編輯器工具列



// MARK: - 格式化按鈕



// MARK: - AI 格式調整面板



// MARK: - Preview

#Preview {
    DocumentEditorView(document: {
        let doc = Document(context: PersistenceController.preview.container.viewContext, title: "測試文件")
        return doc
    }())
    .environmentObject(AppTheme())
    .frame(width: 900, height: 700)
}

