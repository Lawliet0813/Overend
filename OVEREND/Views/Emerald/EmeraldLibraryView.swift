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

struct LibrarySidebar: View {
    let libraries: [Library]
    @Binding var selectedLibrary: Library?
    @Binding var searchText: String
    @Binding var smartGroupFilter: EmeraldLibraryView.SmartGroupType
    var onNewLibrary: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 搜尋框
            HStack {
                MaterialIcon(name: "search", size: 18, color: EmeraldTheme.textMuted)
                TextField("搜尋文獻庫...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(EmeraldTheme.surfaceDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(EmeraldTheme.border, lineWidth: 1)
            )
            .padding()
            
            // Smart Groups
            VStack(alignment: .leading, spacing: 4) {
                Text("智慧群組")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                SmartGroupButton(
                    icon: "library_books",
                    title: "所有文獻",
                    count: totalEntryCount,
                    isSelected: smartGroupFilter == .all
                ) { smartGroupFilter = .all }
                
                SmartGroupButton(
                    icon: "schedule",
                    title: "最近新增",
                    count: recentCount,
                    isSelected: smartGroupFilter == .recent
                ) { smartGroupFilter = .recent }
                
                SmartGroupButton(
                    icon: "star",
                    title: "收藏",
                    count: favoritesCount,
                    isSelected: smartGroupFilter == .favorites
                ) { smartGroupFilter = .favorites }
                
                SmartGroupButton(
                    icon: "warning",
                    title: "缺少 DOI",
                    count: missingDOICount,
                    isSelected: smartGroupFilter == .missingDOI
                ) { smartGroupFilter = .missingDOI }
            }
            .padding(.top, 8)
            
            // 文獻庫列表
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("我的文獻庫")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Spacer()
                    
                    Button(action: onNewLibrary) {
                        MaterialIcon(name: "add", size: 14, color: EmeraldTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("新增文獻庫")
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                ForEach(libraries) { library in
                    LibraryRowButton(
                        library: library,
                        isSelected: selectedLibrary?.id == library.id
                    ) {
                        selectedLibrary = library
                    }
                }
            }
            
            Spacer()
            
            // AI 助理區塊
            if #available(macOS 26.0, *) {
                AgentSidebarSection(libraries: libraries)
            }
            
            // 同步狀態
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    MaterialIcon(name: "cloud_sync", size: 18, color: EmeraldTheme.primary)
                    Text("同步狀態")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(EmeraldTheme.primary)
                        .textCase(.uppercase)
                }
                
                Text("最後同步於 2 分鐘前。所有變更已儲存。")
                    .font(.system(size: 11))
                    .foregroundColor(EmeraldTheme.textSecondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [EmeraldTheme.elevated, EmeraldTheme.backgroundDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding()
        }
        .emeraldGlassBackground()
        .emeraldRightBorder()
    }
    
    private var totalEntryCount: Int {
        libraries.reduce(0) { $0 + ($1.entries?.count ?? 0) }
    }
    
    private var recentCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return libraries.flatMap { ($0.entries as? Set<Entry>) ?? [] }
            .filter { $0.createdAt >= weekAgo }
            .count
    }
    
    private var favoritesCount: Int {
        // Entry 目前沒有 isFavorite 屬性，暫時返回 0
        return 0
    }
    
    private var missingDOICount: Int {
        libraries.flatMap { ($0.entries as? Set<Entry>) ?? [] }
            .filter { $0.fields["doi"]?.isEmpty ?? true }
            .count
    }
}

// MARK: - Smart Group 按鈕

struct SmartGroupButton: View {
    let icon: String
    let title: String
    let count: Int
    let isSelected: Bool
    var action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MaterialIcon(
                    name: icon,
                    size: 18,
                    color: isSelected ? EmeraldTheme.primary : EmeraldTheme.textSecondary
                )
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : EmeraldTheme.textSecondary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? EmeraldTheme.primary : EmeraldTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? EmeraldTheme.primary.opacity(0.1) : (isHovered ? Color.white.opacity(0.05) : .clear))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 文獻庫行按鈕

struct LibraryRowButton: View {
    let library: Library
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MaterialIcon(
                    name: "folder",
                    size: 18,
                    color: isSelected ? .white : EmeraldTheme.textSecondary
                )
                
                Text(library.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : EmeraldTheme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovered ? Color.white.opacity(0.05) : .clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 主內容區

struct LibraryMainContent: View {
    let selectedLibrary: Library?
    let allLibraries: [Library]  // 新增：所有文獻庫
    @Binding var selectedEntry: Entry?
    @Binding var selectedEntries: Set<UUID>  // 多選
    let searchText: String
    let smartGroupFilter: EmeraldLibraryView.SmartGroupType
    let onAddReference: () -> Void
    let onImportBibTeX: () -> Void
    
    private var isAllSelected: Bool {
        !entries.isEmpty && entries.allSatisfy { selectedEntries.contains($0.id) }
    }
    
    private var entries: [Entry] {
        var result: Set<Entry> = []
        
        // 根據智慧群組決定來源
        switch smartGroupFilter {
        case .all:
            // 顯示所有文獻庫的所有文獻
            for library in allLibraries {
                if let entrySet = library.entries as? Set<Entry> {
                    result.formUnion(entrySet)
                }
            }
        case .recent:
            // 最近 7 天新增的
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            for library in allLibraries {
                if let entrySet = library.entries as? Set<Entry> {
                    result.formUnion(entrySet.filter { $0.createdAt >= weekAgo })
                }
            }
        case .favorites:
            // Entry 目前沒有 isFavorite 屬性，暫時返回空
            break
        case .missingDOI:
            // 缺少 DOI 的文獻
            for library in allLibraries {
                if let entrySet = library.entries as? Set<Entry> {
                    result.formUnion(entrySet.filter { $0.fields["doi"]?.isEmpty ?? true })
                }
            }
        }
        
        // 安全過濾：排除已刪除或無效的物件
        result = result.filter { entry in
            !entry.isDeleted && entry.managedObjectContext != nil
        }
        
        // 搜尋過濾
        if !searchText.isEmpty {
            result = result.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return Array(result).sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            HStack {
                HStack(spacing: 8) {
                    // 匯入 BibTeX 按鈕
                    Button(action: onImportBibTeX) {
                        MaterialIcon(name: "article", size: 22, color: EmeraldTheme.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("匯入 BibTeX")
                    
                    Divider()
                        .frame(height: 20)
                        .background(Color.white.opacity(0.1))
                    
                    // 顯示數量提示
                    Text("\(entries.count) 篇文獻")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(EmeraldTheme.textMuted)
                }
                
                Spacer()
                
                Button(action: onAddReference) {
                    HStack(spacing: 8) {
                        MaterialIcon(name: "add", size: 18, color: EmeraldTheme.backgroundDark)
                        Text("匯入 PDF")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(EmeraldTheme.primary)
                    .foregroundColor(EmeraldTheme.backgroundDark)
                    .cornerRadius(8)
                    .shadow(color: EmeraldTheme.primary.opacity(0.3), radius: 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(EmeraldTheme.backgroundDark)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // 表格
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 表頭
                    HStack {
                        // 全選按鈕
                        Button {
                            if isAllSelected {
                                selectedEntries.removeAll()
                            } else {
                                selectedEntries = Set(entries.map { $0.id })
                            }
                        } label: {
                            CheckboxView(isChecked: isAllSelected)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 40)
                        
                        Text("標題")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("作者")
                            .frame(width: 150, alignment: .leading)
                        
                        Text("年份")
                            .frame(width: 80, alignment: .leading)
                        
                        Text("期刊")
                            .frame(width: 150, alignment: .leading)
                        
                        Spacer()
                            .frame(width: 40)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(EmeraldTheme.surfaceDark)
                    
                    // 資料行
                    ForEach(entries) { entry in
                        LibraryEntryTableRow(
                            entry: entry,
                            isSelected: selectedEntry?.id == entry.id
                        ) {
                            selectedEntry = entry
                        }
                    }
                }
                .background(EmeraldTheme.surfaceDark.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(24)
            }
        }
        .background(EmeraldTheme.backgroundDark)
    }
}

// MARK: - 工具列按鈕

struct ToolbarButton: View {
    let icon: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            MaterialIcon(name: icon, size: 22, color: isHovered ? .white : EmeraldTheme.textSecondary)
                .frame(width: 40, height: 40)
                .background(isHovered ? EmeraldTheme.surfaceDark : .clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.white.opacity(0.1) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Checkbox

struct CheckboxView: View {
    let isChecked: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isChecked ? EmeraldTheme.primary : EmeraldTheme.backgroundDark)
            .frame(width: 16, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isChecked ? EmeraldTheme.primary : Color.white.opacity(0.2), lineWidth: 1)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.backgroundDark)
                    .opacity(isChecked ? 1 : 0)
            )
    }
}

// MARK: - 表格行

struct LibraryEntryTableRow: View {
    let entry: Entry
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var rowBackground: Color {
        if isSelected {
            return EmeraldTheme.primary.opacity(0.1)
        } else if isHovered {
            return EmeraldTheme.surfaceDark.opacity(0.8)
        }
        return .clear
    }
    
    private var pdfIconName: String {
        entry.hasPDF ? "picture_as_pdf" : "article"
    }
    
    private var pdfIconColor: Color {
        entry.hasPDF ? EmeraldTheme.primary : EmeraldTheme.textMuted
    }
    
    var body: some View {
        Button(action: action) {
            rowContent
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var rowContent: some View {
        HStack {
            CheckboxView(isChecked: isSelected)
                .frame(width: 40)
            
            Text(entry.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(entry.author)
                .font(.system(size: 13))
                .foregroundColor(EmeraldTheme.textSecondary)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            Text(entry.year)
                .font(.system(size: 13))
                .foregroundColor(EmeraldTheme.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            publicationBadge
            
            MaterialIcon(name: pdfIconName, size: 18, color: pdfIconColor)
                .frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(rowBackground)
    }
    
    @ViewBuilder
    private var publicationBadge: some View {
        if !entry.publication.isEmpty {
            Text(entry.publication)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(EmeraldTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(EmeraldTheme.backgroundDark)
                .cornerRadius(4)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
        } else {
            Spacer()
                .frame(width: 150)
        }
    }
}

// MARK: - Inspector 面板

struct LibraryInspector: View {
    let entry: Entry
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onOpenPDF: () -> Void
    var onOpenDOI: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inspectorHeader
            inspectorTabs
            inspectorContent
        }
        .background(EmeraldTheme.surfaceDark.opacity(0.3))
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1),
            alignment: .leading
        )
    }
    
    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EmeraldTheme.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    MaterialIcon(name: "article", size: 22, color: EmeraldTheme.primary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        MaterialIcon(name: "edit", size: 20, color: EmeraldTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("編輯文獻")
                    
                    Button(action: onDelete) {
                        MaterialIcon(name: "delete", size: 20, color: .red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("刪除文獻")
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                Text("\(entry.author), \(entry.year) • \(entry.publication)")
                    .font(.system(size: 13))
                    .foregroundColor(EmeraldTheme.textSecondary)
            }
        }
        .padding(24)
    }
    
    private var inspectorTabs: some View {
        HStack(spacing: 24) {
            InspectorTab(title: "資訊", isSelected: true)
            InspectorTab(title: "筆記", isSelected: false)
            InspectorTab(title: "標籤", isSelected: false)
        }
        .padding(.horizontal, 24)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var inspectorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pdfAttachmentView
                abstractView
                doiView
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private var pdfAttachmentView: some View {
        if entry.hasPDF {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    MaterialIcon(name: "picture_as_pdf", size: 20, color: .red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.citationKey).pdf")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("PDF 文件")
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: onOpenPDF) {
                    MaterialIcon(name: "launch", size: 18, color: EmeraldTheme.primary)
                }
                .buttonStyle(.plain)
                .help("開啟 PDF")
            }
            .padding(12)
            .background(EmeraldTheme.backgroundDark)
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var abstractView: some View {
        let abstractText = entry.fields["abstract"] ?? ""
        if !abstractText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("摘要")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                
                Text(abstractText)
                    .font(.system(size: 13))
                    .foregroundColor(EmeraldTheme.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
    
    @ViewBuilder
    private var doiView: some View {
        let doiText = entry.fields["doi"] ?? ""
        if !doiText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("DOI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                
                HStack {
                    Text(doiText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: onOpenDOI) {
                        MaterialIcon(name: "launch", size: 18, color: EmeraldTheme.primary)
                    }
                    .buttonStyle(.plain)
                    .help("在瀏覽器中開啟 DOI")
                }
                .padding(12)
                .background(EmeraldTheme.surfaceDark)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Inspector Tab

struct InspectorTab: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? EmeraldTheme.primary : EmeraldTheme.textSecondary)
                .padding(.bottom, 12)
            
            Rectangle()
                .fill(isSelected ? EmeraldTheme.primary : .clear)
                .frame(height: 2)
        }
    }
}

// MARK: - AI 助理側邊欄區塊

@available(macOS 26.0, *)
struct AgentSidebarSection: View {
    let libraries: [Library]
    
    @ObservedObject private var agent = LiteratureAgent.shared
    @State private var isExpanded = false
    
    private var currentLibrary: Library? {
        libraries.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標題按鈕
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(EmeraldTheme.primary.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "cpu")
                            .font(.system(size: 14))
                            .foregroundColor(EmeraldTheme.primary)
                    }
                    
                    Text("AI 助理")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(EmeraldTheme.primary)
                    
                    Spacer()
                    
                    // 狀態指示燈
                    if agent.state.isExecuting {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(EmeraldTheme.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // 展開的內容
            if isExpanded {
                VStack(spacing: 8) {
                    AgentQuickButton(
                        icon: "folder.badge.gearshape",
                        title: "智慧分類",
                        isLoading: agent.state == .classifying
                    ) {
                        if let library = currentLibrary {
                            Task {
                                try? await agent.execute(task: .organizeByTopic(library))
                            }
                        }
                    }
                    
                    AgentQuickButton(
                        icon: "tag.fill",
                        title: "自動標籤",
                        isLoading: agent.state == .tagging
                    ) {
                        if let library = currentLibrary {
                            let context = PersistenceController.shared.container.viewContext
                            let entries = Entry.fetchAll(in: library, context: context)
                            Task {
                                try? await agent.execute(task: .autoTagEntries(entries))
                            }
                        }
                    }
                    
                    AgentQuickButton(
                        icon: "doc.on.doc",
                        title: "尋找重複",
                        isLoading: agent.state == .analyzing
                    ) {
                        if let library = currentLibrary {
                            Task {
                                try? await agent.execute(task: .findDuplicates(library))
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // 待確認建議提示
            if !agent.pendingSuggestions.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("\(agent.pendingSuggestions.count) 個建議待確認")
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [EmeraldTheme.primary.opacity(0.05), EmeraldTheme.elevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(EmeraldTheme.primary.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Agent 快速按鈕

@available(macOS 26.0, *)
struct AgentQuickButton: View {
    let icon: String
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(EmeraldTheme.textSecondary)
                        .frame(width: 18)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isHovered ? .white : EmeraldTheme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isHovered ? EmeraldTheme.primary.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    EmeraldLibraryView()
        .environmentObject(AppTheme())
        .frame(width: 1400, height: 900)
}
