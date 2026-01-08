//
//  SimpleContentView.swift
//  OVEREND
//
//  簡潔版主視圖 - Academic Green 設計風格
//  整合完整功能 + 改良側邊欄結構
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - 主要視圖控制

struct SimpleContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var theme = AppTheme()
    @StateObject private var libraryVM = LibraryViewModel()
    
    // 導航狀態
    @State private var selection: String? = "dashboard"
    @State private var selectedDocument: Document?
    
    // 匯入相關狀態
    @State private var showImportOptions = false
    @State private var isExtractingMetadata = false
    @State private var showExtractionWorkbench = false
    @State private var extractionWorkbenchVM: ExtractionWorkbenchViewModel?
    @State private var currentPDFURL: URL?
    @State private var extractedMetadata: PDFMetadata?
    @State private var currentExtractionLogs: String = ""
    @State private var processingStartTime: Date?
    
    // 設定相關
    @State private var showThemeSettings = false
    @State private var showNewLibrarySheet = false
    
    // 資料
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>
    
    var body: some View {
        NavigationSplitView {
            // --- 側邊欄佈局 ---
            List(selection: $selection) {
                
                // 核心導航
                Section("研究中心") {
                    NavigationLink(value: "dashboard") {
                        Label("寫作首頁", systemImage: "house.fill")
                    }
                    NavigationLink(value: "library") {
                        HStack {
                            Label("文獻庫", systemImage: "books.vertical.fill")
                            Spacer()
                            if entries.count > 0 {
                                Text("\(entries.count)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(theme.accent.opacity(0.2)))
                                    .foregroundColor(theme.accent)
                            }
                        }
                    }
                    NavigationLink(value: "aiCenter") {
                        Label("AI 智慧中心", systemImage: "apple.intelligence")
                    }
                }
                
                // 專案管理
                Section("當前專案") {
                    ForEach(documents.prefix(5)) { doc in
                        NavigationLink(value: "doc_\(doc.id.uuidString)") {
                            Label(doc.title, systemImage: "doc.text.fill")
                        }
                    }
                    
                    if documents.isEmpty {
                        Label("尚無專案", systemImage: "plus.circle.dashed")
                            .foregroundColor(theme.textTertiary)
                    }
                }
                
                // 輔助工具
                Section("工具") {
                    Button(action: { showThemeSettings = true }) {
                        HStack {
                            Label("主題設定", systemImage: "paintbrush")
                            Spacer()
                            Circle()
                                .fill(theme.accent)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("OVEREND")
            
        } detail: {
            // --- 內容區佈局 ---
            SwiftUI.Group {
                switch selection {
                case "dashboard":
                    SimpleDashboardView(
                        documents: Array(documents),
                        onProjectTap: { doc in
                            selectedDocument = doc
                            selection = "doc_\(doc.id.uuidString)"
                        },
                        onNewProject: createNewDocument
                    )
                    .environmentObject(theme)
                    
                case "library":
                    AcademicLibraryView(
                        entries: Array(entries),
                        onImportPDF: { showImportOptions = true }
                    )
                    .environmentObject(theme)
                    
                case "aiCenter":
                    AICenterView()
                        .environmentObject(theme)
                    
                case let docSelection where docSelection?.hasPrefix("doc_") == true:
                    if let docId = docSelection?.replacingOccurrences(of: "doc_", with: ""),
                       let uuid = UUID(uuidString: docId),
                       let doc = documents.first(where: { $0.id == uuid }) {
                        DocumentEditorView(document: doc)
                            .environmentObject(theme)
                    } else if let doc = selectedDocument {
                        DocumentEditorView(document: doc)
                            .environmentObject(theme)
                    }
                    
                default:
                    WelcomeEmptyState(theme: theme)
                }
            }
            .background(theme.background)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .preferredColorScheme(.dark)
        .withToast()
        // PDF 拖曳匯入
        .onDrop(of: [.pdf, .fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        // AI 處理中的遮罩層
        .overlay {
            if isExtractingMetadata {
                AIProcessingOverlay(theme: theme)
            }
        }
        // Sheets
        .sheet(isPresented: $showImportOptions) {
            ImportOptionsSheet(
                onImportBibTeX: importBibTeX,
                onImportPDF: importPDF
            )
            .environmentObject(theme)
        }
        .sheet(isPresented: $showThemeSettings) {
            ThemeSettingsView()
                .environmentObject(theme)
        }
        .sheet(isPresented: $showNewLibrarySheet) {
            NewLibrarySheet(libraryVM: libraryVM)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showExtractionWorkbench) {
            if let vm = extractionWorkbenchVM {
                ExtractionWorkbenchView(viewModel: vm)
                    .environmentObject(theme)
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear {
                        extractionWorkbenchVM = nil
                    }
            }
        }
    }
    
    // MARK: - 方法
    
    private func createNewDocument() {
        let doc = Document(context: viewContext, title: "新文稿")
        try? viewContext.save()
        selectedDocument = doc
        selection = "doc_\(doc.id.uuidString)"
        ToastManager.shared.showSuccess("已建立新文稿")
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let library = libraryVM.libraries.first else {
            ToastManager.shared.showError("請先建立文獻庫")
            return false
        }
        
        var importedCount = 0
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    defer { group.leave() }
                    guard let url = url, url.pathExtension.lowercased() == "pdf" else { return }
                    
                    DispatchQueue.main.async {
                        self.extractAndShowMetadata(from: url, library: library)
                        importedCount += 1
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if importedCount > 0 {
                ToastManager.shared.showInfo("正在處理 \(importedCount) 個 PDF...")
            }
        }
        
        return true
    }
    
    private func importBibTeX() {
        guard let library = libraryVM.libraries.first else {
            ToastManager.shared.showError("請先建立文獻庫")
            return
        }
        
        let panel = NSOpenPanel()
        panel.title = "匯入 BibTeX 檔案"
        panel.message = "選擇 .bib 檔案匯入書目資料"
        panel.allowedContentTypes = [.text, UTType(filenameExtension: "bib")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let entries = try BibTeXParser.parseFile(at: url)
                    let count = try BibTeXParser.importEntries(entries, into: library, context: viewContext)
                    ToastManager.shared.showSuccess("成功匯入 \(count) 筆書目")
                } catch {
                    ToastManager.shared.showError("匯入失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func importPDF() {
        guard let library = libraryVM.libraries.first else {
            ToastManager.shared.showError("請先建立文獻庫")
            return
        }
        
        let panel = NSOpenPanel()
        panel.title = "匯入 PDF 檔案"
        panel.message = "選擇 PDF 檔案，AI 將自動提取書目信息"
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK {
                let urls = panel.urls
                if urls.count == 1 {
                    self.extractAndShowMetadata(from: urls[0], library: library)
                } else if urls.count > 1 {
                    self.batchImportPDFs(urls: urls, into: library)
                }
            }
        }
    }
    
    private func extractAndShowMetadata(from url: URL, library: Library) {
        currentPDFURL = url
        isExtractingMetadata = true
        processingStartTime = Date()
        
        Task {
            let (metadata, logs) = await PDFMetadataExtractor.extractMetadata(from: url)
            
            var pdfText: String? = nil
            if let (_, extractedText) = try? PDFService.extractPDFMetadata(from: url) {
                pdfText = extractedText
            }
            
            await MainActor.run {
                let vm = ExtractionWorkbenchViewModel(context: viewContext, library: library)
                vm.addPendingExtraction(
                    metadata: metadata,
                    pdfURL: url,
                    pdfText: pdfText,
                    logs: logs
                )
                
                extractionWorkbenchVM = vm
                isExtractingMetadata = false
                showExtractionWorkbench = true
                extractedMetadata = metadata
                currentExtractionLogs = logs
            }
        }
    }
    
    private func batchImportPDFs(urls: [URL], into library: Library) {
        let totalCount = urls.count
        var successCount = 0
        var failedCount = 0
        
        ToastManager.shared.showInfo("正在處理 \(totalCount) 個 PDF 文件...")
        
        Task {
            for url in urls {
                let startTime = Date()
                let (metadata, logs) = await PDFMetadataExtractor.extractMetadata(from: url)
                
                await MainActor.run {
                    do {
                        try self.savePDFEntry(metadata: metadata, pdfURL: url, library: library)
                        successCount += 1
                        
                        // Notion 同步 - 僅開發版本
                        #if DEBUG
                        if NotionConfig.isAutoCreateEnabled {
                            let duration = Date().timeIntervalSince(startTime)
                            Task {
                                try? await NotionService.shared.createRecord(
                                    metadata: metadata,
                                    fileURL: url,
                                    processingTime: duration,
                                    logs: logs
                                )
                            }
                        }
                        #endif
                    } catch {
                        failedCount += 1
                    }
                }
            }
            
            await MainActor.run {
                if failedCount == 0 {
                    ToastManager.shared.showSuccess("成功匯入 \(successCount) 個 PDF")
                } else {
                    ToastManager.shared.showWarning("成功 \(successCount) 個，失敗 \(failedCount) 個")
                }
            }
        }
    }
    
    private func savePDFEntry(metadata: PDFMetadata, pdfURL: URL, library: Library) throws {
        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.entryType = metadata.entryType
        entry.citationKey = generateCitationKey(from: metadata)
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
        entry.bibtexRaw = PDFMetadataExtractor.generateBibTeX(from: metadata, citationKey: entry.citationKey)
        try PDFService.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
    }
    
    private func generateCitationKey(from metadata: PDFMetadata) -> String {
        var key = ""
        if let firstAuthor = metadata.authors.first {
            let lastName = firstAuthor.components(separatedBy: " ").last ?? firstAuthor
            key = lastName.lowercased()
        }
        if let year = metadata.year { key += year }
        let titleWords = metadata.title.components(separatedBy: .whitespaces).prefix(2).map { $0.lowercased() }.joined()
        key += titleWords
        key = key.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        if key.count < 5 { key += "\(Int(Date().timeIntervalSince1970) % 10000)" }
        return key.isEmpty ? "entry\(Int(Date().timeIntervalSince1970))" : key
    }
}

// MARK: - Dashboard 視圖

struct SimpleDashboardView: View {
    @EnvironmentObject var theme: AppTheme
    
    let documents: [Document]
    var onProjectTap: (Document) -> Void
    var onNewProject: () -> Void
    
    let momentumData: [Double] = [0.2, 0.5, 0.1, 0.8, 0.4, 0.3, 0.9, 0.6, 0.7, 0.2, 0.4, 0.5, 0.8, 1.0]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 35) {
                // Banner
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: theme.radiusBanner)
                        .fill(theme.elevated)
                        .overlay(
                            Circle()
                                .fill(theme.accent.opacity(0.08))
                                .frame(width: 400)
                                .blur(radius: 100)
                                .offset(x: 250, y: -50)
                        )
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日研究摘要")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.accent)
                                .tracking(2)
                            
                            Text(greeting)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                            
                            HStack(spacing: 20) {
                                Label("14 天後提交", systemImage: "calendar")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                
                                Label("進度 \(overallProgress)%", systemImage: "target")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Button(action: onNewProject) {
                                Label("新建文稿", systemImage: "plus")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.accent)
                            .foregroundColor(.black)
                            .padding(.top, 10)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 12) {
                            Text("研究動能")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(theme.textTertiary)
                            
                            HStack(spacing: 6) {
                                ForEach(0..<momentumData.count, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(theme.accent.opacity(momentumData[i]))
                                        .frame(width: 14, height: 14)
                                }
                            }
                            
                            HStack(spacing: 25) {
                                VStack(alignment: .trailing) {
                                    Text(totalWords)
                                        .font(theme.monoFont(size: 20))
                                        .foregroundColor(theme.textPrimary)
                                    Text("總字數")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(theme.textTertiary)
                                }
                                VStack(alignment: .trailing) {
                                    Text("\(documents.count)")
                                        .font(theme.monoFont(size: 20))
                                        .foregroundColor(theme.textPrimary)
                                    Text("專案數")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(theme.textTertiary)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(45)
                }
                .frame(height: 280)
                
                // 專案列表
                HStack {
                    Text("最近的寫作專案")
                        .font(.title2)
                        .bold()
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: onNewProject) {
                        Label("新建專案", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(theme.accent)
                }
                
                if documents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textTertiary)
                        
                        Text("尚無寫作專案")
                            .font(.title3)
                            .foregroundColor(theme.textSecondary)
                        
                        Button("建立第一個專案", action: onNewProject)
                            .buttonStyle(.borderedProminent)
                            .tint(theme.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 25)], spacing: 25) {
                        ForEach(documents.prefix(6)) { document in
                            EnhancedProjectCard(document: document, theme: theme)
                                .onTapGesture { onProjectTap(document) }
                        }
                    }
                }
            }
            .padding(45)
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "夜深了，學術路上的旅人" }
        else if hour < 12 { return "早安，學術路上的旅人" }
        else if hour < 18 { return "午安，學術路上的旅人" }
        else { return "晚安，學術路上的旅人" }
    }
    
    private var totalWords: String {
        let count = documents.reduce(0) { $0 + $1.attributedString.string.count }
        if count > 1000 { return String(format: "%.1fk", Double(count) / 1000) }
        return "\(count)"
    }
    
    private var overallProgress: Int {
        guard !documents.isEmpty else { return 0 }
        let avgWords = documents.reduce(0) { $0 + $1.attributedString.string.count } / documents.count
        return min(Int(Double(avgWords) / 50.0), 100)
    }
}

// MARK: - 整合版文獻庫

struct IntegratedLibraryView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    let entries: [Entry]
    var onImportPDF: () -> Void
    
    @State private var searchText = ""
    @State private var selectedEntry: Entry?
    
    var filteredEntries: [Entry] {
        if searchText.isEmpty { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            HStack {
                Text("學術文獻庫")
                    .font(.title)
                    .bold()
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                TextField("搜尋文獻...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Button(action: onImportPDF) {
                    Label("匯入", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
            .padding(30)
            
            if entries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 64))
                        .foregroundColor(theme.textTertiary)
                    
                    Text("尚無文獻")
                        .font(.title2)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("拖曳 PDF 到此處，或點擊「匯入」開始")
                        .font(.subheadline)
                        .foregroundColor(theme.textTertiary)
                    
                    Button(action: onImportPDF) {
                        Label("匯入 PDF", systemImage: "doc.badge.plus")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEntries, selection: $selectedEntry) { entry in
                    HStack(spacing: 16) {
                        // 文獻圖標
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.accent.opacity(0.1))
                                .frame(width: 50, height: 65)
                            
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(2)
                            
                            Text("\(entry.author) · \(entry.year ?? "")")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                            
                            if !entry.publication.isEmpty {
                                Text(entry.publication)
                                    .font(.caption)
                                    .foregroundColor(theme.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // 操作按鈕
                        HStack(spacing: 12) {
                            if !entry.attachmentArray.isEmpty {
                                Button(action: { openPDF(for: entry) }) {
                                    Image(systemName: "doc.viewfinder")
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(theme.accent)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "sparkles")
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(theme.accent)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(theme.background)
    }
    
    private func openPDF(for entry: Entry) {
        guard let attachment = entry.attachmentArray.first else { return }
        let path = attachment.filePath
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}

// MARK: - 輔助視圖

struct WelcomeEmptyState: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.cursor")
                .font(.system(size: 48))
                .foregroundColor(theme.textTertiary)
            
            Text("請選擇一個項目開始研究")
                .font(.title3)
                .foregroundColor(theme.textSecondary)
        }
    }
}

struct AIProcessingOverlay: View {
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(theme.accent)
                
                Text("AI 正在分析 PDF...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

struct EnhancedProjectCard: View {
    @ObservedObject var document: Document
    let theme: AppTheme
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "doc.text.fill")
                .foregroundColor(theme.accent)
                .font(.title2)
            
            Text(document.title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("最後編輯：\(formatDate(document.updatedAt))")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                
                ProgressView(value: Double(progress) / 100.0)
                    .tint(theme.accent)
            }
        }
        .padding(25)
        .frame(minHeight: 180)
        .background(theme.elevated)
        .cornerRadius(theme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusCard)
                .stroke(isHovered ? theme.accent.opacity(0.3) : theme.border, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
    
    private var progress: Int {
        min(Int(Double(document.attributedString.string.count) / 50.0), 100)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 編輯器佔位視圖

struct EditorPlaceholderView: View {
    let document: Document
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(theme.textTertiary)
            
            Text("編輯器開發中...")
                .font(.title2)
                .foregroundColor(theme.textSecondary)
            
            Text(document.title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}


#Preview {
    SimpleContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
