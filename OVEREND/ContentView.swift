//
//  ContentView.swift
//  OVEREND
//
//  主視圖 - 三欄布局
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var libraryVM: LibraryViewModel
    @State private var selectedLibrary: Library?
    @State private var selectedEntry: Entry?
    @State private var selectedEntries: Set<Entry.ID> = []
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    // Menu command states
    @State private var showNewLibrarySheet = false
    @State private var showNewEntrySheet = false
    @State private var newLibraryName = ""

    init() {
        // 使用共享的 PersistenceController context
        let context = PersistenceController.shared.container.viewContext
        _libraryVM = StateObject(wrappedValue: LibraryViewModel(context: context))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 左側邊欄 - 文獻庫與資料夾
            LibrarySidebarView(
                selectedLibrary: $selectedLibrary,
                viewModel: libraryVM
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // 中間欄 - 書目列表
            if let library = selectedLibrary {
                EntryListView(
                    library: library,
                    selectedEntry: $selectedEntry,
                    selectedEntries: $selectedEntries
                )
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
            } else {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "請選擇文獻庫",
                        systemImage: "book.closed",
                        description: Text("從左側選擇或創建一個文獻庫開始使用")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("請選擇文獻庫")
                            .font(.title2)
                        Text("從左側選擇或創建一個文獻庫開始使用")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        } detail: {
            // 右側詳情 - 文獻詳情或論文編輯器
            if let entry = selectedEntry {
                EntryDetailView(entry: entry)
            } else {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "未選擇書目",
                        systemImage: "doc.text",
                        description: Text("從列表中選擇一筆書目查看詳情")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("未選擇書目")
                            .font(.title2)
                        Text("從列表中選擇一筆書目查看詳情")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("OVEREND")
        // Focused values for menu commands
        .focusedSceneValue(\.selectedLibrary, selectedLibrary)
        .focusedSceneValue(\.showNewLibrary, $showNewLibrarySheet)
        .focusedSceneValue(\.showNewEntry, $showNewEntrySheet)
        .focusedSceneValue(\.importBibTeXAction, importBibTeX)
        .focusedSceneValue(\.importPDFAction, importPDF)
        // New Library Sheet
        .sheet(isPresented: $showNewLibrarySheet) {
            NewLibraryPopoverView(
                libraryName: $newLibraryName,
                isPresented: $showNewLibrarySheet,
                onCreate: { name in
                    libraryVM.createLibrary(name: name)
                }
            )
        }
        // New Entry Sheet
        .sheet(isPresented: $showNewEntrySheet) {
            if let library = selectedLibrary {
                NavigationStack {
                    EntryEditorView(library: library)
                }
            }
        }
        .onAppear {
            // 自動選擇第一個庫（如果有的話）
            if selectedLibrary == nil && !libraryVM.libraries.isEmpty {
                selectedLibrary = libraryVM.libraries.first
            }
        }
        .onChange(of: libraryVM.libraries) { newLibraries in
            // 當庫列表更新時，如果當前沒有選擇，自動選擇第一個
            if selectedLibrary == nil && !newLibraries.isEmpty {
                selectedLibrary = newLibraries.first
            }
        }
    }
    
    // MARK: - Import Actions
    
    private func importBibTeX() {
        guard let library = selectedLibrary else { return }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.bibtex, .text]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let entries = try BibTeXParser.parseFile(at: url)
                    let count = try BibTeXParser.importEntries(entries, into: library, context: viewContext)
                    print("成功匯入 \(count) 篇文獻")
                } catch {
                    print("匯入失敗: \(error)")
                }
            }
        }
    }
    
    private func importPDF() {
        guard let library = selectedLibrary else { return }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "匯入 PDF"
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    importSinglePDF(url: url, into: library)
                }
            }
        }
    }
    
    private func importSinglePDF(url: URL, into library: Library) {
        // 開始存取安全範圍資源
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
            
            // 使用 async 查詢元數據
            Task {
                do {
                    let metadata = try await DOIService.fetchMetadata(for: doi)
                    print("成功獲取元數據: \(metadata.title)")
                    
                    // 在主線程創建條目
                    await MainActor.run {
                        createEntryWithMetadata(metadata, pdfURL: url, library: library)
                    }
                } catch {
                    print("獲取元數據失敗: \(error.localizedDescription)")
                    // 回退到基本匯入
                    await MainActor.run {
                        createBasicEntry(fileName: fileName, pdfURL: url, library: library)
                    }
                }
            }
        } else {
            // 沒有找到 DOI，使用基本匯入
            createBasicEntry(fileName: fileName, pdfURL: url, library: library)
        }
    }
    
    private func createEntryWithMetadata(_ metadata: DOIService.Metadata, pdfURL: URL, library: Library) {
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
                print("成功匯入書目: \(metadata.title)")
            } catch {
                print("PDF 附件新增失敗: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    private func createBasicEntry(fileName: String, pdfURL: URL, library: Library) {
        // 使用增強版元數據提取
        let (title, author, year, type) = DOIService.extractEnhancedMetadata(from: pdfURL, fileName: fileName)
        
        let citationKey = fileName.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
        
        viewContext.perform {
            var fields: [String: String] = ["title": title]
            if author != "Unknown" { fields["author"] = author }
            if !year.isEmpty { fields["year"] = year }
            
            let entry = Entry(
                context: viewContext,
                citationKey: citationKey,
                entryType: type,
                fields: fields,
                library: library
            )
            
            do {
                try PDFService.addPDFAttachment(from: pdfURL, to: entry, context: viewContext)
                print("成功匯入 PDF 作為書目: \(title)")
            } catch {
                print("匯入書目失敗: \(error)")
                viewContext.rollback()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 1400, height: 900)
}
