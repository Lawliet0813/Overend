//
//  PDFLayoutAnalysisView.swift
//  OVEREND
//
//  PDF 版面分析視圖
//
//  功能：
//  - 視覺化顯示 XY-Cut 分析結果
//  - 標記偵測到的欄位區塊
//  - 顯示閱讀順序
//  - 依閱讀順序提取文字
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// PDF 版面分析視圖
@available(macOS 26.0, *)
struct PDFLayoutAnalysisView: View {
    @EnvironmentObject var theme: AppTheme
    
    // 狀態
    @State private var pdfDocument: PDFDocument?
    @State private var currentPageIndex: Int = 0
    @State private var analysisResult: LayoutAnalysisResult?
    @State private var isAnalyzing: Bool = false
    @State private var extractedText: String = ""
    @State private var showExtractedText: Bool = false
    @State private var isDragging: Bool = false
    @State private var showCopiedToast: Bool = false
    
    var body: some View {
        HSplitView {
            // 左側：PDF 預覽與控制
            leftPanel
                .frame(minWidth: 400)
            
            // 右側：分析結果
            rightPanel
                .frame(minWidth: 350)
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showCopiedToast)
    }
    
    // MARK: - 左側面板
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "doc.viewfinder")
                    .foregroundColor(theme.accent)
                Text("PDF 版面分析")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                
                Spacer()
                
                if let doc = pdfDocument {
                    Text("第 \(currentPageIndex + 1) / \(doc.pageCount) 頁")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding()
            
            Divider()
            
            if pdfDocument != nil {
                // PDF 預覽區
                pdfPreviewArea
                
                Divider()
                
                // 頁面控制
                pageControls
            } else {
                // 拖放區
                dropZone
            }
        }
        .background(theme.background)
    }
    
    private var dropZone: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(isDragging ? theme.accent : theme.textMuted)
            
            Text("拖放 PDF 檔案至此處")
                .font(.system(size: DesignTokens.Typography.title3, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            Text("或點擊下方按鈕選擇檔案")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
            
            Button {
                selectPDFFile()
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("選擇 PDF 檔案")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .stroke(isDragging ? theme.accent : theme.border, style: StrokeStyle(lineWidth: 2, dash: [10]))
                .padding()
        )
        .onDrop(of: [.pdf], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private var pdfPreviewArea: some View {
        GeometryReader { geometry in
            ZStack {
                // PDF 頁面
                if let doc = pdfDocument, let page = doc.page(at: currentPageIndex) {
                    PDFPagePreview(page: page, analysisResult: analysisResult)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 分析中遮罩
                if isAnalyzing {
                    Color.black.opacity(0.3)
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("分析版面中...")
                            .font(.system(size: DesignTokens.Typography.body))
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
            }
        }
    }
    
    private var pageControls: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 上一頁
            Button {
                if currentPageIndex > 0 {
                    currentPageIndex -= 1
                    analysisResult = nil
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(currentPageIndex == 0)
            
            // 下一頁
            Button {
                if let doc = pdfDocument, currentPageIndex < doc.pageCount - 1 {
                    currentPageIndex += 1
                    analysisResult = nil
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(pdfDocument == nil || currentPageIndex >= (pdfDocument?.pageCount ?? 1) - 1)
            
            Spacer()
            
            // 分析按鈕
            Button {
                performAnalysis()
            } label: {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text("分析版面")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(pdfDocument == nil || isAnalyzing)
            
            // 更換檔案
            Button {
                pdfDocument = nil
                analysisResult = nil
                extractedText = ""
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(theme.toolbar)
    }
    
    // MARK: - 右側面板
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(theme.accent)
                Text("分析結果")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .semibold))
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            if let result = analysisResult {
                // 分析統計
                analysisStats(result)
                
                Divider()
                
                // 區塊列表
                blocksList(result)
                
                Divider()
                
                // 提取控制
                extractControls
            } else {
                // 空狀態
                emptyState
            }
        }
        .background(theme.background)
        .sheet(isPresented: $showExtractedText) {
            extractedTextSheet
        }
    }
    
    private func analysisStats(_ result: LayoutAnalysisResult) -> some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            statBadge(
                title: "區塊數",
                value: "\(result.blocks.count)",
                icon: "square.grid.2x2",
                color: .blue
            )
            
            statBadge(
                title: "欄數",
                value: "\(result.columnCount)",
                icon: "text.alignleft",
                color: result.isMultiColumn ? .orange : .green
            )
            
            statBadge(
                title: "處理時間",
                value: String(format: "%.1f ms", result.processingTime * 1000),
                icon: "clock",
                color: .purple
            )
        }
        .padding()
        .background(theme.card)
    }
    
    private func statBadge(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }
            
            Text(title)
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func blocksList(_ result: LayoutAnalysisResult) -> some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(result.blocksInReadingOrder) { block in
                    blockRow(block)
                }
            }
            .padding()
        }
    }
    
    private func blockRow(_ block: LayoutBlock) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 閱讀順序
            Text("\(block.readingOrder + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(theme.accent))
            
            // 區塊資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(block.blockType.displayName)
                    .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                
                Text("位置: (\(Int(block.bounds.minX)), \(Int(block.bounds.minY))) 尺寸: \(Int(block.bounds.width))×\(Int(block.bounds.height))")
                    .font(.system(size: DesignTokens.Typography.caption, design: .monospaced))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            // 區塊類型標籤
            Text(block.blockType.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(colorForBlockType(block.blockType))
                )
        }
        .padding(DesignTokens.Spacing.sm)
        .background(theme.card)
        .cornerRadius(DesignTokens.CornerRadius.medium)
    }
    
    private func colorForBlockType(_ type: LayoutBlockType) -> Color {
        switch type {
        case .paragraph: return .blue
        case .title: return .purple
        case .figure: return .green
        case .table: return .orange
        case .caption: return .cyan
        case .header: return .gray
        case .footer: return .gray
        case .column: return .indigo
        case .unknown: return .secondary
        }
    }
    
    private var extractControls: some View {
        HStack {
            Button {
                extractTextInReadingOrder()
            } label: {
                HStack {
                    Image(systemName: "text.quote")
                    Text("依閱讀順序提取文字")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .disabled(analysisResult == nil)
        }
        .padding()
        .background(theme.toolbar)
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            
            Text("載入 PDF 並點擊「分析版面」")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textSecondary)
            
            Text("系統將使用 XY-Cut 演算法\n分析多欄版面結構")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 提取文字 Sheet
    
    private var extractedTextSheet: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Text("提取的文字")
                    .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                
                Spacer()
                
                Button {
                    copyToClipboard(extractedText)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("複製全部")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                
                Button {
                    showExtractedText = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // 文字內容
            ScrollView {
                Text(extractedText)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
                    .padding()
            }
        }
        .frame(width: 600, height: 500)
        .background(theme.background)
    }
    
    // MARK: - Toast
    
    private var copiedToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("已複製到剪貼簿")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            Capsule()
                .fill(theme.card)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    // MARK: - 動作
    
    private func selectPDFFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            loadPDF(from: url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, error in
            guard let url = url else { return }
            
            // 需要複製到臨時位置，因為拖放的檔案只在回調中有效
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.copyItem(at: url, to: tempURL)
            
            DispatchQueue.main.async {
                loadPDF(from: tempURL)
            }
        }
    }
    
    private func loadPDF(from url: URL) {
        if let doc = PDFDocument(url: url) {
            pdfDocument = doc
            currentPageIndex = 0
            analysisResult = nil
            extractedText = ""
        }
    }
    
    private func performAnalysis() {
        guard let doc = pdfDocument, let page = doc.page(at: currentPageIndex) else { return }
        
        isAnalyzing = true
        
        Task {
            // 在背景執行分析
            let result = await Task.detached {
                XYCutLayoutAnalyzer.analyze(page: page)
            }.value
            
            await MainActor.run {
                analysisResult = result
                isAnalyzing = false
            }
        }
    }
    
    private func extractTextInReadingOrder() {
        guard let doc = pdfDocument, 
              let page = doc.page(at: currentPageIndex),
              let result = analysisResult else { return }
        
        extractedText = XYCutLayoutAnalyzer.extractTextInReadingOrder(from: page, blocks: result.blocksInReadingOrder)
        showExtractedText = true
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedToast = false
        }
    }
}

// MARK: - PDF 頁面預覽

@available(macOS 26.0, *)
struct PDFPagePreview: NSViewRepresentable {
    let page: PDFPage
    let analysisResult: LayoutAnalysisResult?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displaysPageBreaks = false
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        // 創建一個只包含當前頁面的臨時文檔
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        pdfView.document = doc
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    PDFLayoutAnalysisView()
        .environmentObject(AppTheme())
        .frame(width: 900, height: 600)
}
