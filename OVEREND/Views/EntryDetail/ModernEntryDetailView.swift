//
//  ModernEntryDetailView.swift
//  OVEREND
//
//  現代化書目詳情面板 - 右側顯示詳細資訊
//

import SwiftUI
import PDFKit
import Vision
import CoreData

/// 現代化書目詳情視圖
@available(macOS 26.0, *)
struct ModernEntryDetailView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: Entry
    var onClose: (() -> Void)?
    
    @State private var showPDFViewer = false
    @State private var selectedAttachment: Attachment?
    
    // AI 功能狀態
    @StateObject private var aiService = UnifiedAIService.shared
    @State private var aiSummary: String = ""
    @State private var aiKeywords: [String] = []
    @State private var isGeneratingSummary = false
    @State private var isExtractingKeywords = false
    
    // 編輯模式狀態
    @State private var isEditMode: Bool = false
    @State private var editedFields: [String: String] = [:]
    @State private var editedTitle: String = ""
    @State private var editedEntryType: String = ""
    @State private var hasUnsavedChanges: Bool = false
    @State private var showUnsavedAlert: Bool = false
    @State private var isExtractingMetadata: Bool = false
    
    // AI 標籤建議
    @State private var showSmartTagSuggestion = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            HStack {
                Text(isEditMode ? "編輯書目" : "書目詳情")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if isEditMode {
                    // 編輯模式：AI 提取、取消和儲存按鈕
                    // 編輯模式：AI 提取、取消和儲存按鈕
                    Button(action: { performAIExtraction() }) {
                        if isExtractingMetadata {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Label("AI 提取", systemImage: "sparkles")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isExtractingMetadata)
                    
                    Button("取消") {
                        cancelEdit()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(theme.textMuted)
                    
                    Button("儲存") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!hasUnsavedChanges)
                } else {
                    // 查看模式：編輯按鈕
                    Button(action: { enterEditMode() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("編輯")
                        }
                        .font(.system(size: 14))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: { onClose?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textMuted)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(theme.itemHover)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(theme.toolbar)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }
            
            // 內容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 標題區
                    headerSection
                    
                    Divider()
                    
                    // AI 智慧分析（新增）
                    // AI 智慧分析（新增）
                    aiSection
                    
                    Divider()

                    // 標籤管理（新增）
                    tagsSection

                    Divider()
                    
                    // 書目資訊
                    metadataSection
                    
                    Divider()
                    
                    // 引用格式
                    citationSection
                    
                    Divider()
                    
                    // PDF 附件（含預覽）
                    attachmentSection
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        .background(theme.sidebar)
        .sheet(isPresented: $showPDFViewer) {
            if let attachment = selectedAttachment {
                PDFViewerSheet(attachment: attachment)
                    .environmentObject(theme)
            }
        }
        .onAppear {
            // 載入已儲存的摘要
            if let saved = entry.fields["ai_summary"] {
                aiSummary = saved
            }
            if let keywordsStr = entry.fields["ai_keywords"] {
                aiKeywords = keywordsStr.components(separatedBy: ", ")
            }
            
            // 初始化編輯欄位
            editedTitle = entry.title
            editedFields = entry.fields
        }
        .alert("未儲存的變更", isPresented: $showUnsavedAlert) {
            Button("繼續編輯", role: .cancel) { }
            Button("放棄變更", role: .destructive) {
                isEditMode = false
                hasUnsavedChanges = false
                // 重置編輯欄位
                editedTitle = entry.title
                editedFields = entry.fields
            }
        } message: {
            Text("您有尚未儲存的變更，確定要放棄嗎？")
        }
    }
    
    // MARK: - AI 智慧分析區
    
    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "AI 智慧分析", icon: "apple.intelligence")
                
                Spacer()
                

            }
            
            // AI 摘要
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("摘要")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    Button(action: generateSummary) {
                        if isGeneratingSummary {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Label("生成", systemImage: "sparkles")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(isGeneratingSummary)
                }
                
                if aiSummary.isEmpty {
                    Text("點擊「生成」讓 AI 自動摘要此文獻")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                        .italic()
                } else {
                    Text(aiSummary)
                        .font(.system(size: 15))
                        .foregroundColor(theme.textPrimary)
                        .textSelection(.enabled)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accentLight.opacity(0.5))
            )
            
            // AI 關鍵詞
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("關鍵詞")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    Button(action: extractKeywords) {
                        if isExtractingKeywords {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Label("提取", systemImage: "tag")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(isExtractingKeywords)
                }
                
                if aiKeywords.isEmpty {
                    Text("點擊「提取」讓 AI 自動識別關鍵詞")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                        .italic()
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(aiKeywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.system(size: 14))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.accent.opacity(0.2))
                                )
                                .foregroundColor(theme.accent)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accentLight.opacity(0.5))
            )
        }
    }

    // MARK: - 標籤管理區

    @State private var isAddingTag = false
    @State private var newTagSearchText = ""

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "標籤", icon: "tag")
                
                Spacer()
                
                Button(action: { showSmartTagSuggestion = true }) {
                    Label("AI 建議", systemImage: "sparkles")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.purple)
                .popover(isPresented: $showSmartTagSuggestion) {
                    SmartTagSuggestionView(
                        entryTitle: entry.title,
                        onAccept: { tags in
                            addSuggestedTags(tags)
                            showSmartTagSuggestion = false
                        },
                        onCancel: {
                            showSmartTagSuggestion = false
                        }
                    )
                }
                
                Button(action: { isAddingTag = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .popover(isPresented: $isAddingTag) {
                    VStack(spacing: 12) {
                        TextField("搜尋或建立標籤", text: $newTagSearchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                // 顯示現有標籤（過濾後）
                                let allTags = (entry.library?.tags as? Set<Tag> ?? [])
                                    .sorted { $0.name < $1.name }
                                    .filter { tag in
                                        newTagSearchText.isEmpty || tag.name.localizedCaseInsensitiveContains(newTagSearchText)
                                    }
                                
                                ForEach(allTags) { tag in
                                    Button(action: {
                                        toggleTag(tag)
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(tag.color)
                                                .frame(width: 8, height: 8)
                                            Text(tag.name)
                                            Spacer()
                                            if (entry.tags as? Set<Tag>)?.contains(tag) == true {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // 如果搜尋文字不為空且沒有完全匹配的標籤，顯示建立選項
                                if !newTagSearchText.isEmpty && !allTags.contains(where: { $0.name.caseInsensitiveCompare(newTagSearchText) == .orderedSame }) {
                                    Divider()
                                    Button(action: {
                                        createNewTag(name: newTagSearchText)
                                    }) {
                                        Label("建立 \"\(newTagSearchText)\"", systemImage: "plus.circle")
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding()
                }
            }
            
            if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(tags).sorted(by: { $0.name < $1.name })) { tag in
                        HStack(spacing: 4) {
                            Text(tag.name)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tag.color)
                        .cornerRadius(4)
                    }
                }
            } else {
                Text("尚無標籤")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                    .italic()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.sidebar.opacity(0.5)) // Slightly different background
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private func toggleTag(_ tag: Tag) {
        var currentTags = entry.tags as? Set<Tag> ?? []
        if currentTags.contains(tag) {
            currentTags.remove(tag)
        } else {
            currentTags.insert(tag)
        }
        entry.tags = currentTags
        try? viewContext.save()
    }

    private func removeTag(_ tag: Tag) {
        var currentTags = entry.tags as? Set<Tag> ?? []
        currentTags.remove(tag)
        entry.tags = currentTags
        try? viewContext.save()
    }

    private func addSuggestedTags(_ tagNames: [String]) {
        guard let library = entry.library else { return }
        var currentTags = entry.tags as? Set<Tag> ?? []
        var updated = false
        
        for name in tagNames {
            // Check if tag exists in library
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@ AND library == %@", name, library)
            
            if let existingTag = try? viewContext.fetch(request).first {
                if !currentTags.contains(existingTag) {
                    currentTags.insert(existingTag)
                    updated = true
                }
            } else {
                // Create new tag
                let newTag = Tag(context: viewContext, name: name, library: library)
                let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55"]
                newTag.colorHex = colors.randomElement() ?? "#007AFF"
                currentTags.insert(newTag)
                updated = true
            }
        }
        
        if updated {
            entry.tags = currentTags
            try? viewContext.save()
            ToastManager.shared.showSuccess("已加入 \(tagNames.count) 個標籤")
        }
    }

    private func createNewTag(name: String) {
        guard let library = entry.library else { return }
        let newTag = Tag(context: viewContext, name: name, library: library)
        // Random color
        let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55"]
        newTag.colorHex = colors.randomElement() ?? "#007AFF"
        
        var currentTags = entry.tags as? Set<Tag> ?? []
        currentTags.insert(newTag)
        entry.tags = currentTags
        
        try? viewContext.save()
        
        // 觸發學習
        LearningService.shared.learnTagging(title: entry.title, tags: [newTag.name])
        
        newTagSearchText = ""
    }
    
    private func generateSummary() {
        isGeneratingSummary = true
        
        Task {
            do {
                let abstract = entry.fields["abstract"] ?? ""
                let content = entry.fields["note"] ?? ""
                
                let summary = try await aiService.document.generateSummary(
                    title: entry.title,
                    abstract: abstract,
                    content: content
                )
                
                await MainActor.run {
                    aiSummary = summary
                    // 儲存到 entry
                    entry.fields["ai_summary"] = summary
                    try? viewContext.save()
                    isGeneratingSummary = false
                    ToastManager.shared.showSuccess("摘要生成完成")
                }
            } catch {
                await MainActor.run {
                    isGeneratingSummary = false
                    ToastManager.shared.showError("生成失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func extractKeywords() {
        isExtractingKeywords = true
        
        Task {
            do {
                let abstract = entry.fields["abstract"] ?? entry.title
                
                let keywords = try await aiService.document.extractKeywords(
                    title: entry.title,
                    abstract: abstract
                )
                
                await MainActor.run {
                    aiKeywords = keywords
                    // 儲存到 entry
                    entry.fields["ai_keywords"] = keywords.joined(separator: ", ")
                    try? viewContext.save()
                    isExtractingKeywords = false
                    ToastManager.shared.showSuccess("已提取 \(keywords.count) 個關鍵詞")
                }
            } catch {
                await MainActor.run {
                    isExtractingKeywords = false
                    ToastManager.shared.showError("提取失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 編輯模式方法
    
    /// 進入編輯模式
    private func enterEditMode() {
        isEditMode = true
        // 複製當前資料到編輯欄位
        editedTitle = entry.title
        editedFields = entry.fields
        hasUnsavedChanges = false
    }
    
    /// 儲存變更
    private func saveChanges() {
        // 1. 驗證必填欄位
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ToastManager.shared.showError("標題為必填欄位")
            return
        }
        
        // 2. 更新 Entry - title 存入 fields
        editedFields["title"] = editedTitle
        entry.fields = editedFields
        entry.updatedAt = Date()
        
        // 3. 重新生成 BibTeX
        entry.bibtexRaw = generateBibTeX()
        
        // 4. Core Data 儲存
        do {
            try viewContext.save()
            
            // 5. 退出編輯模式
            isEditMode = false
            hasUnsavedChanges = false
            
            ToastManager.shared.showSuccess("已儲存變更")
        } catch {
            ToastManager.shared.showError("儲存失敗：\(error.localizedDescription)")
        }
    }
    
    /// 取消編輯
    private func cancelEdit() {
        if hasUnsavedChanges {
            showUnsavedAlert = true
        } else {
            isEditMode = false
            // 重置編輯欄位
            editedTitle = entry.title
            editedFields = entry.fields
        }
    }
    
    /// 生成 BibTeX
    private func generateBibTeX() -> String {
        var bibtex = "@\(entry.entryType){\(entry.citationKey),\n"
        
        // 標題
        bibtex += "  title = {\(editedTitle)},\n"
        
        // 其他欄位
        let fieldOrder = ["author", "year", "journal", "volume", "pages", "doi", "abstract"]
        for field in fieldOrder {
            if let value = editedFields[field], !value.isEmpty {
                bibtex += "  \(field) = {\(value)},\n"
            }
        }
        
        bibtex += "}"
        return bibtex
    }
    
    // MARK: - AI 智慧提取
    
    /// 從 PDF 附件提取元數據並填入編輯欄位
    private func performAIExtraction() {
        // 取得 PDF 附件
        guard let pdfAttachment = entry.attachmentArray.first(where: { $0.mimeType == "application/pdf" }) else {
            // 如果沒有 PDF，嘗試從現有資料提取
            performAIExtractionFromText()
            return
        }
        
        isExtractingMetadata = true
        
        Task {
            do {
                // 從 PDF 提取文字
                let pdfURL = URL(fileURLWithPath: pdfAttachment.filePath)
                guard let pdfDocument = PDFDocument(url: pdfURL) else {
                    await MainActor.run {
                        isExtractingMetadata = false
                        ToastManager.shared.showError("無法讀取 PDF 文件")
                    }
                    return
                }
                
                // 提取前 5 頁的文字（通常包含標題、作者等資訊）
                var pdfText = ""
                let pageCount = min(pdfDocument.pageCount, 5)
                for i in 0..<pageCount {
                    if let page = pdfDocument.page(at: i), let pageContent = page.string {
                        pdfText += pageContent + "\n"
                    }
                }
                
                // 如果直接提取失敗，嘗試 OCR
                if pdfText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        ToastManager.shared.showInfo("正在進行 OCR 識別...")
                    }
                    pdfText = try await performOCR(on: pdfDocument, pageCount: pageCount)
                }
                
                guard !pdfText.isEmpty else {
                    await MainActor.run {
                        isExtractingMetadata = false
                        ToastManager.shared.showError("PDF 無法提取文字（即使 OCR 後）")
                    }
                    return
                }
                
                // 使用 AI 提取元數據
                let metadata = try await aiService.document.extractMetadata(from: pdfText)
                
                await MainActor.run {
                    applyExtractedMetadata(metadata)
                    isExtractingMetadata = false
                }
            } catch {
                await MainActor.run {
                    isExtractingMetadata = false
                    ToastManager.shared.showError("AI 提取失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 使用 Vision framework 進行 OCR
    private func performOCR(on pdfDocument: PDFDocument, pageCount: Int) async throws -> String {
        var ocrText = ""
        
        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            
            // 將 PDF 頁面渲染為圖片
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0 // 提高解析度以獲得更好的 OCR 結果
            let imageSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let image = NSImage(size: imageSize)
            image.lockFocus()
            
            if let context = NSGraphicsContext.current?.cgContext {
                context.setFillColor(NSColor.white.cgColor)
                context.fill(CGRect(origin: .zero, size: imageSize))
                context.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: context)
            }
            
            image.unlockFocus()
            
            // 進行 OCR
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            
            let pageText = try await recognizeText(in: cgImage)
            if !pageText.isEmpty {
                ocrText += pageText + "\n\n"
            }
        }
        
        return ocrText
    }
    
    /// 使用 Vision framework 識別圖片中的文字
    private func recognizeText(in image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            // 配置 OCR 請求
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en-US"] // 支援繁簡中文和英文
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 從現有文字資料提取（當沒有 PDF 時）
    private func performAIExtractionFromText() {
        let abstract = editedFields["abstract"] ?? entry.fields["abstract"] ?? ""
        let title = editedTitle.isEmpty ? entry.title : editedTitle
        
        guard !abstract.isEmpty || !title.isEmpty else {
            ToastManager.shared.showError("沒有 PDF 附件或文字資料可供分析")
            return
        }
        
        isExtractingMetadata = true
        
        Task {
            do {
                let textToAnalyze = "標題: \(title)\n\n摘要: \(abstract)"
                let metadata = try await aiService.document.extractMetadata(from: textToAnalyze)
                
                await MainActor.run {
                    applyExtractedMetadata(metadata)
                    isExtractingMetadata = false
                }
            } catch {
                await MainActor.run {
                    isExtractingMetadata = false
                    ToastManager.shared.showError("AI 提取失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 將提取的元數據應用到編輯欄位
    private func applyExtractedMetadata(_ metadata: ExtractedDocumentMetadata) {
        var fieldsUpdated = 0
        
        if let title = metadata.title, !title.isEmpty, editedTitle.isEmpty {
            editedTitle = title
            fieldsUpdated += 1
        }
        
        if !metadata.authors.isEmpty {
            let authorField = editedFields["author"] ?? ""
            if authorField.isEmpty {
                editedFields["author"] = metadata.authorsBibTeX
                fieldsUpdated += 1
            }
        }
        
        if let year = metadata.year {
            let yearField = editedFields["year"] ?? ""
            if yearField.isEmpty {
                editedFields["year"] = year
                fieldsUpdated += 1
            }
        }
        
        if let journal = metadata.journal {
            let journalField = editedFields["journal"] ?? ""
            if journalField.isEmpty {
                editedFields["journal"] = journal
                fieldsUpdated += 1
            }
        }
        
        if let doi = metadata.doi {
            let doiField = editedFields["doi"] ?? ""
            if doiField.isEmpty {
                editedFields["doi"] = doi
                fieldsUpdated += 1
            }
        }
        
        if let entryType = metadata.entryType {
            editedEntryType = entryType
            fieldsUpdated += 1
        }
        
        if fieldsUpdated > 0 {
            hasUnsavedChanges = true
            ToastManager.shared.showSuccess("已提取 \(fieldsUpdated) 個欄位")
        } else {
            ToastManager.shared.showInfo("未發現新資訊可填入")
        }
    }
    
    
    // MARK: - 標題區
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 類型標籤
            Text(entry.entryType.uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentLight)
                )
            
            // 標題
            if isEditMode {
                EditableMetadataRow(
                    label: "標題",
                    value: $editedTitle,
                    isRequired: true,
                    placeholder: "請輸入標題"
                )
                .environmentObject(theme)
            } else {
                Text(entry.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 作者
            if isEditMode {
                EditableMetadataRow(
                    label: "作者",
                    value: Binding(
                        get: { editedFields["author"] ?? "" },
                        set: { editedFields["author"] = $0; hasUnsavedChanges = true }
                    ),
                    placeholder: "請輸入作者",
                    hint: "建議格式：Last, F. & Last, F."
                )
                .environmentObject(theme)
            } else if let author = entry.fields["author"], !author.isEmpty {
                Text(author)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
        }
    }
    
    // MARK: - 書目資訊
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailSectionHeader(title: "書目資訊", icon: "info.circle")
            
            if isEditMode {
                VStack(spacing: 16) {
                    EditableMetadataRow(
                        label: "年份",
                        value: Binding(
                            get: { editedFields["year"] ?? "" },
                            set: { editedFields["year"] = $0; hasUnsavedChanges = true }
                        ),
                        isRequired: false,
                        placeholder: "YYYY",
                        validator: { value in
                            if value.isEmpty { return (true, nil) }
                            if let year = Int(value), year >= 1900 && year <= 2100 {
                                return (true, nil)
                            }
                            return (false, "請輸入有效年份（1900-2100）")
                        }
                    )
                    .environmentObject(theme)
                    
                    EditableMetadataRow(
                        label: "期刊",
                        value: Binding(
                            get: { editedFields["journal"] ?? "" },
                            set: { editedFields["journal"] = $0; hasUnsavedChanges = true }
                        ),
                        placeholder: "請輸入期刊名稱"
                    )
                    .environmentObject(theme)
                    
                    EditableMetadataRow(
                        label: "卷期",
                        value: Binding(
                            get: { editedFields["volume"] ?? "" },
                            set: { editedFields["volume"] = $0; hasUnsavedChanges = true }
                        ),
                        placeholder: "如：Vol. 12, No. 3"
                    )
                    .environmentObject(theme)
                    
                    EditableMetadataRow(
                        label: "頁碼",
                        value: Binding(
                            get: { editedFields["pages"] ?? "" },
                            set: { editedFields["pages"] = $0; hasUnsavedChanges = true }
                        ),
                        placeholder: "如：123-145"
                    )
                    .environmentObject(theme)
                    
                    EditableMetadataRow(
                        label: "DOI",
                        value: Binding(
                            get: { editedFields["doi"] ?? "" },
                            set: { editedFields["doi"] = $0; hasUnsavedChanges = true }
                        ),
                        placeholder: "如：10.1234/example"
                    )
                    .environmentObject(theme)
                    
                    EditableMetadataRow(
                        label: "摘要",
                        value: Binding(
                            get: { editedFields["abstract"] ?? "" },
                            set: { editedFields["abstract"] = $0; hasUnsavedChanges = true }
                        ),
                        isMultiline: true,
                        placeholder: "請輸入摘要"
                    )
                    .environmentObject(theme)
                }
            } else {
                VStack(spacing: 12) {
                    if let year = entry.fields["year"], !year.isEmpty {
                        DetailMetadataRow(label: "年份", value: year)
                    }
                    
                    if let journal = entry.fields["journal"], !journal.isEmpty {
                        DetailMetadataRow(label: "期刊", value: journal)
                    }
                    
                    if let volume = entry.fields["volume"], !volume.isEmpty {
                        DetailMetadataRow(label: "卷期", value: volume)
                    }
                    
                    if let pages = entry.fields["pages"], !pages.isEmpty {
                        DetailMetadataRow(label: "頁碼", value: pages)
                    }
                    
                    if let doi = entry.fields["doi"], !doi.isEmpty {
                        DetailMetadataRow(label: "DOI", value: doi, isLink: true)
                    }
                    
                    DetailMetadataRow(label: "引用鍵", value: entry.citationKey)
                }
            }
        }
    }
    
    // MARK: - 引用格式
    
    private var citationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "引用格式", icon: "quote.bubble")
                
                if isEditMode {
                    Text("（預覽）")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
            }
            
            VStack(spacing: 12) {
                if isEditMode {
                    // 編輯模式：使用 editedFields 生成預覽
                    DetailCitationCard(
                        format: "APA 7th",
                        citation: generateAPAPreview()
                    )
                    
                    DetailCitationCard(
                        format: "MLA 9th",
                        citation: generateMLAPreview()
                    )
                } else {
                    // 查看模式：使用 entry 資料
                    DetailCitationCard(
                        format: "APA 7th",
                        citation: CitationService.generateAPA(entry: entry)
                    )
                    
                    DetailCitationCard(
                        format: "MLA 9th",
                        citation: CitationService.generateMLA(entry: entry)
                    )
                }
            }
        }
    }
    
    /// 編輯模式下生成 APA 預覽
    private func generateAPAPreview() -> String {
        let author = editedFields["author"] ?? ""
        let year = editedFields["year"] ?? ""
        let title = editedTitle
        let journal = editedFields["journal"] ?? ""
        let volume = editedFields["volume"] ?? ""
        let pages = editedFields["pages"] ?? ""
        let doi = editedFields["doi"] ?? ""
        
        var citation = ""
        
        // 作者
        if !author.isEmpty {
            citation += author
        } else {
            citation += "作者未知"
        }
        
        // 年份
        citation += " (\(year.isEmpty ? "n.d." : year)). "
        
        // 標題
        citation += title.isEmpty ? "無標題" : title
        citation += ". "
        
        // 期刊
        if !journal.isEmpty {
            citation += "*\(journal)*"
            if !volume.isEmpty {
                citation += ", \(volume)"
            }
            if !pages.isEmpty {
                citation += ", \(pages)"
            }
            citation += ". "
        }
        
        // DOI
        if !doi.isEmpty {
            citation += "https://doi.org/\(doi)"
        }
        
        return citation
    }
    
    /// 編輯模式下生成 MLA 預覽
    private func generateMLAPreview() -> String {
        let author = editedFields["author"] ?? ""
        let title = editedTitle
        let journal = editedFields["journal"] ?? ""
        let volume = editedFields["volume"] ?? ""
        let year = editedFields["year"] ?? ""
        let pages = editedFields["pages"] ?? ""
        
        var citation = ""
        
        // 作者
        if !author.isEmpty {
            citation += author
        } else {
            citation += "作者未知"
        }
        citation += ". "
        
        // 標題
        citation += "\"" + (title.isEmpty ? "無標題" : title) + ".\" "
        
        // 期刊
        if !journal.isEmpty {
            citation += "*\(journal)*"
            if !volume.isEmpty {
                citation += ", vol. \(volume)"
            }
            if !year.isEmpty {
                citation += ", \(year)"
            }
            if !pages.isEmpty {
                citation += ", pp. \(pages)"
            }
            citation += "."
        }
        
        return citation
    }
    
    // MARK: - 附件區
    
    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "附件", icon: "paperclip")
                
                Spacer()
                
                Button(action: importPDF) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            if entry.attachmentArray.isEmpty {
                Text("尚未添加附件")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.attachmentArray, id: \.id) { attachment in
                        DetailAttachmentCard(attachment: attachment) {
                            selectedAttachment = attachment
                            showPDFViewer = true
                        }
                        .environmentObject(theme)
                    }
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func importPDF() {
        PDFService.selectPDFFile { url in
            guard let url = url else { return }
            
            do {
                try PDFService.addPDFAttachment(from: url, to: entry, context: viewContext)
            } catch {
                print("添加 PDF 失敗：\(error)")
            }
        }
    }
}

// MARK: - 子元件

struct DetailSectionHeader: View {
    @EnvironmentObject var theme: AppTheme
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(theme.textMuted)
    }
}

struct DetailMetadataRow: View {
    @EnvironmentObject var theme: AppTheme
    let label: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textMuted)
                .frame(width: 60, alignment: .leading)
            
            if isLink {
                Link(value, destination: URL(string: "https://doi.org/\(value)") ?? URL(string: "https://doi.org")!)
                    .font(.system(size: 14))
                    .foregroundColor(theme.accent)
            } else {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
        }
    }
}

struct DetailCitationCard: View {
    @EnvironmentObject var theme: AppTheme
    let format: String
    let citation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(format)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(citation, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
                .help("複製引用")
            }
            
            Text(citation)
                .font(.system(size: 15))
                .foregroundColor(theme.textPrimary)
                .lineLimit(4)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
        )
    }
}

struct DetailAttachmentCard: View {
    @EnvironmentObject var theme: AppTheme
    let attachment: Attachment
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // PDF 圖標
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "doc.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                
                // 資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.fileName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(attachment.pageCount) 頁")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                        
                        Text(formatFileSize(attachment.fileSize))
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                    }
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.accentLight : theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let kb = Double(size) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            return String(format: "%.1f MB", kb / 1024)
        }
    }
}

// MARK: - PDF 檢視器

struct PDFViewerSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    let attachment: Attachment
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text(attachment.fileName)
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Button("關閉") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(theme.toolbar)
            
            // PDF 內容
            PDFKitView(url: URL(fileURLWithPath: attachment.filePath))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 800, height: 600)
    }
}

/// PDF 縮圖視圖
struct PDFThumbnailView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.white.cgColor
        
        if let document = PDFDocument(url: url),
           let page = document.page(at: 0) {
            let thumbnail = page.thumbnail(of: CGSize(width: 320, height: 400), for: .artBox)
            let imageView = NSImageView()
            imageView.image = thumbnail
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // 更新縮圖
    }
}

struct PDFKitView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}

#Preview {
    let theme = AppTheme()
    let context = PersistenceController.preview.container.viewContext
    
    let library = Library(context: context)
    library.id = UUID()
    library.name = "Test"
    
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.citationKey = "test2024"
    entry.entryType = "article"
    entry.fields = [
        "title": "測試論文標題",
        "author": "張三 and 李四",
        "year": "2024",
        "journal": "測試期刊"
    ]
    entry.bibtexRaw = "@article{test2024}"
    entry.library = library
    
    if #available(macOS 26.0, *) {
        return ModernEntryDetailView(entry: entry)
            .environmentObject(theme)
            .environment(\.managedObjectContext, context)
            .frame(width: 320, height: 600)
    } else {
        // Fallback on earlier versions
    }
}
