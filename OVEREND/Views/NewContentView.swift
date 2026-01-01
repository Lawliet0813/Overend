//
//  NewContentView.swift
//  OVEREND
//
//  新版主內容視圖 - 整合三視圖系統
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

/// 新版主內容視圖
struct NewContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var theme = AppTheme()
    @StateObject private var viewState = MainViewState()
    @StateObject private var libraryVM: LibraryViewModel
    
    @State private var showNewLibrarySheet = false
    @State private var showNewDocumentSheet = false
    @State private var showImportOptions = false
    @State private var importMessage: String?
    @State private var showImportAlert = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _libraryVM = StateObject(wrappedValue: LibraryViewModel(context: context))
    }
    
    var body: some View {
        NavigationSplitView {
            // 側邊欄 - 使用 Liquid Glass 效果
            NewSidebarView(libraryVM: libraryVM)
                .environmentObject(theme)
                .environmentObject(viewState)
                .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 260)
                .scrollContentBackground(.hidden)
        } detail: {
            // 主內容區域
            VStack(spacing: 0) {
                // 動態工具列
                DynamicToolbar(
                    searchText: $viewState.searchText,
                    onNewItem: handleNewItem
                )
                .environmentObject(theme)
                .environmentObject(viewState)
                
                // 視圖切換
                ZStack {
                    switch viewState.mode {
                    case .library:
                        // 文獻管理視圖
                        if let library = viewState.selectedLibrary ?? libraryVM.libraries.first {
                            ModernEntryListView(library: library)
                                .environmentObject(theme)
                                .environmentObject(viewState)
                        } else {
                            emptyLibraryState
                        }
                        
                    case .editorList:
                        // 文稿列表視圖
                        EditorListView()
                            .environmentObject(theme)
                            .environmentObject(viewState)
                        
                    case .editorFull(let document):
                        // 專業編輯器視圖
                        ProfessionalEditorView(document: document)
                            .environmentObject(theme)
                            .environmentObject(viewState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(theme.background)
        }
        .environmentObject(theme)
        .environmentObject(viewState)
        .onAppear {
            if viewState.selectedLibrary == nil && !libraryVM.libraries.isEmpty {
                viewState.selectedLibrary = libraryVM.libraries.first
            }
        }
        .sheet(isPresented: $showImportOptions) {
            ImportOptionsSheet(
                onImportBibTeX: importBibTeX,
                onImportPDF: importPDF
            )
            .environmentObject(theme)
        }
        .alert("匯入結果", isPresented: $showImportAlert, presenting: importMessage) { _ in
            Button("確定", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
    
    // MARK: - 空狀態
    
    private var emptyLibraryState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "books.vertical")
                    .font(.system(size: 40))
                    .foregroundColor(theme.accent)
            }
            
            VStack(spacing: 8) {
                Text("尚無文獻庫")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("建立您的第一個文獻庫開始使用")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
            
            Button(action: { showNewLibrarySheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("建立文獻庫")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.accent)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 方法
    
    private func handleNewItem() {
        switch viewState.mode {
        case .library:
            // 顯示匯入選項
            showImportOptions = true
        case .editorList, .editorFull:
            // 新建文稿
            showNewDocumentSheet = true
        }
    }
    
    private func importBibTeX() {
        guard let library = viewState.selectedLibrary ?? libraryVM.libraries.first else { return }
        
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
                    importMessage = "成功匯入 \(count) 筆書目"
                    showImportAlert = true
                } catch {
                    importMessage = "匯入失敗：\(error.localizedDescription)"
                    showImportAlert = true
                }
            }
        }
    }
    
    private func importPDF() {
        guard let library = viewState.selectedLibrary ?? libraryVM.libraries.first else { return }
        
        let panel = NSOpenPanel()
        panel.title = "匯入 PDF 檔案"
        panel.message = "選擇 PDF 檔案，將自動建立書目並附加"
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK {
                var successCount = 0
                var failCount = 0
                
                for url in panel.urls {
                    do {
                        // 建立新的 Entry
                        let entry = Entry(context: viewContext)
                        entry.id = UUID()
                        entry.entryType = "misc"
                        let citationKey = generateCitationKey(from: url)
                        entry.citationKey = citationKey
                        entry.createdAt = Date()
                        entry.updatedAt = Date()
                        entry.library = library
                        
                        // 從 PDF 檔名提取標題
                        let title = url.deletingPathExtension().lastPathComponent
                            .replacingOccurrences(of: "_", with: " ")
                            .replacingOccurrences(of: "-", with: " ")
                        entry.fields = ["title": title]
                        
                        // 設置 bibtexRaw（必填欄位）
                        entry.bibtexRaw = """
                        @misc{\(citationKey),
                          title = {\(title)}
                        }
                        """
                        
                        // 附加 PDF
                        try PDFService.addPDFAttachment(from: url, to: entry, context: viewContext)
                        successCount += 1
                    } catch {
                        print("匯入 PDF 失敗：\(error)")
                        failCount += 1
                    }
                }
                
                if failCount == 0 {
                    importMessage = "成功匯入 \(successCount) 個 PDF 檔案"
                } else {
                    importMessage = "匯入完成：\(successCount) 成功，\(failCount) 失敗"
                }
                showImportAlert = true
            }
        }
    }
    
    private func generateCitationKey(from url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        let sanitized = name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let timestamp = Int(Date().timeIntervalSince1970) % 10000
        return "\(sanitized.prefix(20))_\(timestamp)"
    }
}

// MARK: - 匯入選項 Sheet

struct ImportOptionsSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    let onImportBibTeX: () -> Void
    let onImportPDF: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("匯入文獻")
                .font(.system(size: 18, weight: .bold))
            
            HStack(spacing: 20) {
                // BibTeX 匯入
                ImportOptionCard(
                    icon: "doc.text",
                    title: "BibTeX",
                    description: "匯入 .bib 書目檔案"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onImportBibTeX()
                    }
                }
                
                // PDF 匯入
                ImportOptionCard(
                    icon: "doc.richtext",
                    title: "PDF",
                    description: "匯入 PDF 並建立書目"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onImportPDF()
                    }
                }
            }
            
            Button("取消") {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
        .padding(32)
    }
}

struct ImportOptionCard: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHovered ? theme.accent : theme.accentLight)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isHovered ? .white : theme.accent)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(width: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    NewContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 1200, height: 800)
}

