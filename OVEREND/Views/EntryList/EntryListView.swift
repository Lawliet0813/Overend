//
//  EntryListView.swift
//  OVEREND
//
//  中間欄 - 書目列表視圖
//

import SwiftUI
import UniformTypeIdentifiers

struct EntryListView: View {
    let library: Library
    @Binding var selectedEntry: Entry?
    @Binding var selectedEntries: Set<Entry.ID>
    @StateObject private var viewModel = EntryViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    // UI 狀態
    @State private var showingCreateSheet = false
    @State private var editingEntry: Entry?
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingOnlineSearch = false

    var body: some View {
        VStack(spacing: 0) {
            // 搜尋欄
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("搜尋書目...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)

                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.overendSearchBackground)

            Divider()

            // 書目列表
            List(viewModel.filteredEntries, selection: $selectedEntries) { entry in
                EntryRow(entry: entry)
                    .tag(entry.id)
                    .contextMenu {
                        // 引用操作
                        Button(action: { copyCitation(entry, format: "APA") }) {
                            Label("複製 APA 引用", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: { copyCitation(entry, format: "MLA") }) {
                            Label("複製 MLA 引用", systemImage: "doc.on.doc")
                        }
                        
                        Divider()
                        
                        // PDF 操作
                        if entry.hasPDF {
                            Button(action: { openPDF(entry) }) {
                                Label("開啟附件 PDF", systemImage: "doc.richtext")
                            }
                            
                            Button(action: { revealInFinder(entry) }) {
                                Label("在 Finder 中顯示", systemImage: "folder")
                            }
                            
                            Divider()
                        }
                        
                        // 編輯操作
                        Button(action: { editingEntry = entry }) {
                            Label("編輯書目", systemImage: "pencil")
                        }
                        
                        Button(action: { exportEntry(entry) }) {
                            Label("導出 BibTeX", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        // AI 功能
                        Button(action: { generateAIBibliography(entry) }) {
                            Label("✨ AI 生成摘要", systemImage: "apple.intelligence")
                        }
                        
                        Divider()
                        
                        // 刪除
                        Button(role: .destructive, action: { deleteEntry(entry) }) {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                    .onTapGesture {
                        // 單擊更新 selectedEntry 以顯示詳情
                        selectedEntry = entry
                    }
            }
            .listStyle(.inset)
            .onChange(of: selectedEntries) { newSelection in
                // 當多選時，更新 selectedEntry 為第一個選中項
                if let firstID = newSelection.first,
                   let firstEntry = viewModel.filteredEntries.first(where: { $0.id == firstID }) {
                    selectedEntry = firstEntry
                } else {
                    selectedEntry = nil
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingOnlineSearch = true }) {
                    Label("線上搜尋", systemImage: "globe")
                }
                .help("線上搜尋")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Label("新建", systemImage: "plus")
                }
                .help("新增書目")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: importBibTeX) {
                        Label("匯入 BibTeX", systemImage: "doc.text")
                    }
                    Button(action: importPDF) {
                        Label("匯入 PDF", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Label("匯入", systemImage: "square.and.arrow.down")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingDeleteConfirmation = true }) {
                    Label("刪除", systemImage: "trash")
                }
                .disabled(selectedEntries.isEmpty)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack {
                EntryEditorView(library: library)
            }
        }
        .sheet(isPresented: $showingOnlineSearch) {
            NavigationStack {
                OnlineSearchView()
                    .environmentObject(viewModel)
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                EntryEditorView(library: library, entry: entry)
            }
        }
        .alert("匯入錯誤", isPresented: $showingImportError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteSelectedEntries()
            }
        } message: {
            Text("確定要刪除 \(selectedEntries.count) 筆書目嗎？此操作無法復原。")
        }
        .onAppear {
            viewModel.library = library
        }
        .onChange(of: library) { newLibrary in
            viewModel.library = newLibrary
        }
    }
    
    // MARK: - 右鍵選單 Actions
    
    private func copyCitation(_ entry: Entry, format: String) {
        let citation: String
        switch format {
        case "APA":
            citation = CitationService.generateAPA(entry: entry)
        case "MLA":
            citation = CitationService.generateMLA(entry: entry)
        default:
            citation = CitationService.generateAPA(entry: entry)
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(citation, forType: .string)
        ToastManager.shared.showSuccess("已複製\(format)引用")
    }
    
    private func openPDF(_ entry: Entry) {
        guard let attachment = entry.attachments?.first else { return }
        let url = URL(fileURLWithPath: attachment.filePath)
        NSWorkspace.shared.open(url)
    }
    
    private func revealInFinder(_ entry: Entry) {
        guard let attachment = entry.attachments?.first else { return }
        let url = URL(fileURLWithPath: attachment.filePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    // MARK: - AI 生成書目
    
    private func generateAIBibliography(_ entry: Entry) {
        Task {
            do {
                let aiService = AppleAIService.shared
                let summary = try await aiService.generateSummary(
                    title: entry.title,
                    abstract: entry.fields["abstract"] ?? "",
                    content: entry.fields["note"] ?? ""
                )
                
                await MainActor.run {
                    entry.fields["ai_summary"] = summary
                    try? viewContext.save()
                    ToastManager.shared.showSuccess("AI 摘要已生成")
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("AI 生成失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 刪除 Actions
    
    private func deleteEntry(_ entry: Entry) {
        // 先保存資訊用於日誌（避免存取已刪除物件）
        let citationKey = entry.citationKey
        let attachmentPaths = entry.attachments?.map { $0.filePath } ?? []
        let entryObjectID = entry.objectID
        
        // 先清除選擇
        if selectedEntry == entry {
            selectedEntry = nil
        }
        
        // 使用延遲確保 UI 先更新
        Task { @MainActor in
            // 小延遲讓 SwiftUI 完成更新
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            
            // 刪除附件檔案
            for path in attachmentPaths {
                let fileURL = URL(fileURLWithPath: path)
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            // 從 objectID 獲取物件並刪除
            if let entryToDelete = try? viewContext.existingObject(with: entryObjectID) {
                viewContext.delete(entryToDelete)
                
                do {
                    try viewContext.save()
                    print("成功刪除書目: \(citationKey)")
                } catch {
                    print("刪除失敗: \(error)")
                    viewContext.rollback()
                }
            }
        }
    }
    
    private func deleteSelectedEntries() {
        // 收集要刪除的條目
        let entriesToDelete = viewModel.filteredEntries.filter { selectedEntries.contains($0.id) }
        
        guard !entriesToDelete.isEmpty else { return }
        
        // 清除選擇
        selectedEntry = nil
        selectedEntries.removeAll()
        
        Task { @MainActor in
            // 小延遲讓 UI 完成更新
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            for entry in entriesToDelete {
                // 刪除附件檔案
                if let attachments = entry.attachments {
                    for attachment in attachments {
                        let fileURL = URL(fileURLWithPath: attachment.filePath)
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
                
                // 刪除書目
                viewContext.delete(entry)
            }
            
            do {
                try viewContext.save()
                print("成功刪除 \(entriesToDelete.count) 筆書目")
            } catch {
                print("批次刪除失敗: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    private func importBibTeX() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.bibtex, .text] // 支援 .bib 和純文字
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                importFile(at: url)
            }
        }
    }
    
    private func importFile(at url: URL) {
        do {
            let entries = try BibTeXParser.parseFile(at: url)
            let count = try BibTeXParser.importEntries(entries, into: library, context: viewContext)
            print("成功匯入 \(count) 筆書目")
        } catch {
            importErrorMessage = "匯入失敗: \(error.localizedDescription)"
            showingImportError = true
        }
    }
    
    private func importPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "匯入 PDF"
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    importSinglePDF(url: url)
                }
            }
        }
    }
    
    private func importSinglePDF(url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileName = url.deletingPathExtension().lastPathComponent
        
        // 嘗試從 PDF 提取 DOI
        if let doi = DOIService.extractDOI(from: url) {
            print("找到 DOI: \(doi)")
            
            Task {
                do {
                    // ⭐ 使用 CrossRefService 查詢（優先）
                    let metadata = try await CrossRefService.fetchMetadata(doi: doi)
                    print("✅ CrossRef 查詢成功: \(metadata.title?.first ?? "Unknown")")
                    
                    await MainActor.run {
                        createEntryFromCrossRef(metadata, pdfURL: url, doi: doi)
                    }
                } catch {
                    print("⚠️ CrossRef 查詢失敗: \(error), 嘗試 DOIService")
                    
                    // 回退到 DOIService
                    do {
                        let metadata = try await DOIService.fetchMetadata(for: doi)
                        print("✅ DOIService 查詢成功: \(metadata.title)")
                        
                        await MainActor.run {
                            createEntryWithMetadata(metadata, pdfURL: url)
                        }
                    } catch {
                        print("⚠️ DOIService 也失敗: \(error.localizedDescription)")
                        print("回退到基本匯入模式，但保留 DOI")
                        await MainActor.run {
                            createBasicEntry(fileName: fileName, pdfURL: url, doi: doi)
                        }
                    }
                }
            }
        } else {
            createBasicEntry(fileName: fileName, pdfURL: url, doi: nil)
        }
    }
    
    private func createEntryWithMetadata(_ metadata: DOIService.Metadata, pdfURL: URL) {
        viewContext.perform {
            let entry = Entry(
                context: viewContext,
                citationKey: metadata.citationKey,
                entryType: metadata.entryType,
                fields: metadata.fields,
                library: library
            )
            
            do {
                try PDFService.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
                print("成功匯入: \(metadata.title)")
            } catch {
                print("PDF 附加失敗: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    /// 從 CrossRef 元數據創建 Entry
    private func createEntryFromCrossRef(_ metadata: CrossRefMetadata, pdfURL: URL, doi: String) {
        // 提取資訊
        let title = metadata.title?.first ?? "Unknown"
        let authors = metadata.author?.map { $0.chineseName }.joined(separator: "、") ?? "Unknown"
        let year = metadata.published?.year ?? ""
        let journal = metadata.containerTitle?.first
        let volume = metadata.volume
        let issue = metadata.issue
        let pages = metadata.page
        
        // 生成引用鍵
        let authorLastName = authors.components(separatedBy: "、").first ?? "unknown"
        let citationKey = year.isEmpty ? authorLastName : "\(authorLastName)\(year)"
        
        // 建立 fields
        var fields: [String: String] = [
            "title": title,
            "author": authors,
            "doi": doi
        ]
        
        if !year.isEmpty { fields["year"] = year }
        if let journal = journal { fields["journal"] = journal }
        if let volume = volume { fields["volume"] = volume }
        if let issue = issue { fields["issue"] = issue }
        if let pages = pages { fields["pages"] = pages }
        
        // 創建 Entry
        viewContext.perform {
            let entry = Entry(
                context: viewContext,
                citationKey: citationKey,
                entryType: "article",
                fields: fields,
                library: library
            )
            
            do {
                try PDFService.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
                
                // 詳細日誌
                var logMessage = "✅ 成功從 CrossRef 匯入:\n"
                logMessage += "  標題: \(title)\n"
                logMessage += "  作者: \(authors)\n"
                if !year.isEmpty { logMessage += "  年份: \(year)\n" }
                if let journal = journal { logMessage += "  期刊: \(journal)\n" }
                if let volume = volume { logMessage += "  卷: \(volume)\n" }
                if let issue = issue { logMessage += "  期: \(issue)\n" }
                if let pages = pages { logMessage += "  頁碼: \(pages)\n" }
                logMessage += "  DOI: \(doi)"
                
                print(logMessage)
            } catch {
                print("❌ PDF 附加失敗: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    private func createBasicEntry(fileName: String, pdfURL: URL, doi: String?) {
        // 使用增強版 PDF 元數據提取
        let (title, author, year, type) = DOIService.extractEnhancedMetadata(from: pdfURL, fileName: fileName)
        
        // 生成引用鍵
        let authorLastName = author.components(separatedBy: " ").last?.lowercased() ?? "unknown"
        let citationKey = year.isEmpty ? authorLastName : "\(authorLastName)\(year)"
        
        var fields: [String: String] = ["title": title]
        if author != "Unknown" {
            fields["author"] = author
        }
        if !year.isEmpty {
            fields["year"] = year
        }
        // 如果有 DOI，也保存起來（即使 CrossRef 查不到）
        if let doi = doi {
            fields["doi"] = doi
        }
        
        viewContext.perform {
            let entry = Entry(
                context: viewContext,
                citationKey: citationKey,
                entryType: type,
                fields: fields,
                library: library
            )
            
            do {
                try PDFService.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
                let doiInfo = doi != nil ? ", DOI: \(doi!)" : ""
                print("成功匯入 PDF: \(title) (作者: \(author), 年份: \(year.isEmpty ? "未知" : year)\(doiInfo))")
            } catch {
                print("PDF 匯入失敗: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    private func exportEntry(_ entry: Entry) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = "\(entry.citationKey).bib"
        panel.prompt = "導出"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try BibTeXGenerator.export([entry], to: url)
                } catch {
                    print("導出失敗: \(error)")
                }
            }
        }
    }
}

struct EntryRow: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 標題
            Text(entry.title)
                .font(.title3)
                .lineLimit(2)

            // 作者與年份
            HStack {
                Text(entry.author)
                    .font(.body)
                    .foregroundColor(.secondary)

                if !entry.year.isEmpty {
                    Text("(\(entry.year))")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            // 引用鍵與類型
            HStack {
                Text(entry.citationKey)
                    .font(.callout)
                    .foregroundColor(.overendAccent)

                Text("•")
                    .foregroundColor(.secondary)

                Text(entry.entryType)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if entry.hasPDF {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
