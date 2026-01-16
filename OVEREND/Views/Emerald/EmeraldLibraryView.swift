//
//  EmeraldLibraryView.swift
//  OVEREND
//
//  Emerald Library - 文獻庫管理介面
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

// MARK: - 主視圖

struct EmeraldLibraryView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>
    
    @State private var selectedLibrary: Library?
    @State private var selectedEntry: Entry?
    @State private var selectedEntries: Set<UUID> = []  // 多選
    @State private var searchText = ""
    @State private var showAddReference = false
    
    // 新增狀態
    @State private var showNewLibrarySheet = false
    @State private var showImportPDFPanel = false
    @State private var showImportBibTeXPanel = false
    @State private var showDeleteConfirm = false
    @State private var entryToDelete: Entry?
    @State private var showEditEntry = false
    @State private var smartGroupFilter: SmartGroupType = .all
    
    enum SmartGroupType {
        case all, recent, favorites, missingDOI
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側邊欄
            LibrarySidebar(
                libraries: Array(libraries),
                selectedLibrary: $selectedLibrary,
                searchText: $searchText,
                smartGroupFilter: $smartGroupFilter,
                onNewLibrary: { showNewLibrarySheet = true }
            )
            .frame(width: 280)
            
            // 中間主內容
            LibraryMainContent(
                selectedLibrary: selectedLibrary,
                allLibraries: Array(libraries),
                selectedEntry: $selectedEntry,
                selectedEntries: $selectedEntries,
                searchText: searchText,
                smartGroupFilter: smartGroupFilter,
                onAddReference: { showImportPDFPanel = true },
                onImportBibTeX: { showImportBibTeXPanel = true }
            )
            
            // 右側 Inspector
            if let entry = selectedEntry {
                LibraryInspector(
                    entry: entry,
                    onEdit: { showEditEntry = true },
                    onDelete: {
                        entryToDelete = entry
                        showDeleteConfirm = true
                    },
                    onOpenPDF: { openPDF(for: entry) },
                    onOpenDOI: { openDOI(for: entry) }
                )
                .frame(width: 380)
            }
        }
        .background(EmeraldTheme.backgroundDark)
        .onAppear {
            if selectedLibrary == nil {
                selectedLibrary = libraries.first
            }
        }
        // 新增文獻庫 Sheet
        .sheet(isPresented: $showNewLibrarySheet) {
            NewLibrarySheet(libraryVM: LibraryViewModel())
                .environmentObject(theme)
        }
        // 匯入 PDF Panel
        .fileImporter(
            isPresented: $showImportPDFPanel,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handlePDFImport(result)
        }
        // 匯入 BibTeX Panel
        .fileImporter(
            isPresented: $showImportBibTeXPanel,
            allowedContentTypes: [.text, .init(filenameExtension: "bib")!],
            allowsMultipleSelection: false
        ) { result in
            handleBibTeXImport(result)
        }
        // 刪除確認
        .alert("確定刪除這篇文獻？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                }
            }
        } message: {
            Text("刪除後無法復原。")
        }
    }
    
    // MARK: - 功能方法
    
    private func openPDF(for entry: Entry) {
        guard let attachment = entry.attachments?.first else {
            ToastManager.shared.showError("找不到 PDF 附件")
            return
        }
        
        // 使用 filePath 開啟 PDF
        let fileURL = URL(fileURLWithPath: attachment.filePath)
        if FileManager.default.fileExists(atPath: attachment.filePath) {
            NSWorkspace.shared.open(fileURL)
        } else {
            ToastManager.shared.showError("PDF 文件不存在")
        }
    }
    
    private func openDOI(for entry: Entry) {
        guard let doi = entry.fields["doi"], !doi.isEmpty else {
            ToastManager.shared.showError("此文獻沒有 DOI")
            return
        }
        
        let cleanDOI = doi.replacingOccurrences(of: "https://doi.org/", with: "")
        if let url = URL(string: "https://doi.org/\(cleanDOI)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func deleteEntry(_ entry: Entry) {
        // 先清除選擇，避免 UI 引用已刪除的物件
        let entryToRemove = entry
        selectedEntry = nil
        entryToDelete = nil
        
        // 延遲刪除，讓 UI 先更新
        DispatchQueue.main.async {
            viewContext.delete(entryToRemove)
            do {
                try viewContext.save()
                ToastManager.shared.showSuccess("已刪除文獻")
            } catch {
                ToastManager.shared.showError("刪除失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func handlePDFImport(_ result: Result<[URL], Error>) {
        guard let library = selectedLibrary else {
            ToastManager.shared.showError("請先選擇文獻庫")
            return
        }
        
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // 使用 SimpleContentView 的 PDF 匯入邏輯
                Task {
                    if #available(macOS 26.0, *) {
                        do {
                            let agent = LiteratureAgent.shared
                            let metadata = try await agent.extractPDFMetadata(from: url)
                            
                            await MainActor.run {
                                createEntry(from: metadata, pdfURL: url, library: library)
                            }
                        } catch {
                            await MainActor.run {
                                ToastManager.shared.showError("匯入失敗: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        let (metadata, _) = await PDFMetadataExtractor.extractMetadata(from: url, useGemini: false)
                        await MainActor.run {
                            createEntryFromPDFMetadata(metadata, pdfURL: url, library: library)
                        }
                    }
                }
            }
            ToastManager.shared.showInfo("正在處理 \(urls.count) 個 PDF...")
            
        case .failure(let error):
            ToastManager.shared.showError("匯入失敗: \(error.localizedDescription)")
        }
    }
    
    @available(macOS 26.0, *)
    private func createEntry(from result: LiteratureAgent.PDFExtractionResult, pdfURL: URL, library: Library) {
        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.entryType = result.entryType
        entry.citationKey = generateCitationKey(title: result.title, author: result.authors.first, year: result.year)
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.library = library
        entry.fields = result.fields
        
        // 附加 PDF（使用 PDFService）
        try? PDFService.shared.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
        
        try? viewContext.save()
        ToastManager.shared.showSuccess("已匯入: \(result.title)")
    }
    
    private func createEntryFromPDFMetadata(_ metadata: PDFMetadata, pdfURL: URL, library: Library) {
        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.entryType = metadata.entryType
        entry.citationKey = generateCitationKey(title: metadata.title, author: metadata.authors.first, year: metadata.year)
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.library = library
        
        var fields: [String: String] = ["title": metadata.title]
        if !metadata.authors.isEmpty { fields["author"] = metadata.authors.joined(separator: " and ") }
        if let year = metadata.year { fields["year"] = year }
        if let doi = metadata.doi { fields["doi"] = doi }
        if let journal = metadata.journal { fields["journal"] = journal }
        if let abstract = metadata.abstract { fields["abstract"] = abstract }
        entry.fields = fields
        
        // 附加 PDF（使用 PDFService）
        try? PDFService.shared.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
        
        try? viewContext.save()
        ToastManager.shared.showSuccess("已匯入: \(metadata.title)")
    }
    
    private func handleBibTeXImport(_ result: Result<[URL], Error>) {
        guard let library = selectedLibrary else {
            ToastManager.shared.showError("請先選擇文獻庫")
            return
        }
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let entries = try BibTeXParser.parseFile(at: url)
                let count = try BibTeXParser.importEntries(entries, into: library, context: viewContext)
                ToastManager.shared.showSuccess("成功匯入 \(count) 筆書目")
            } catch {
                ToastManager.shared.showError("匯入失敗: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            ToastManager.shared.showError("匯入失敗: \(error.localizedDescription)")
        }
    }
    
    private func generateCitationKey(title: String, author: String?, year: String?) -> String {
        var key = ""
        if let author = author {
            let lastName = author.components(separatedBy: " ").last ?? author
            key = lastName.lowercased()
        }
        if let year = year { key += year }
        let titleWords = title.components(separatedBy: .whitespaces).prefix(2).map { $0.lowercased() }.joined()
        key += titleWords
        key = key.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        if key.isEmpty { key = "entry\(Int(Date().timeIntervalSince1970))" }
        return key
    }
}

// MARK: - 側邊欄





// MARK: - Preview

#Preview {
    EmeraldLibraryView()
        .environmentObject(AppTheme())
        .frame(width: 1400, height: 900)
}
