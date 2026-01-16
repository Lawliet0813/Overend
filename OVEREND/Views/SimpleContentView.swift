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
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var theme = AppTheme()
    @StateObject var libraryVM = LibraryViewModel()
    
    // 導航狀態
    @State private var selection: String? = "dashboard"
    @State private var selectedDocument: Document?
    
    // 匯入相關狀態
    @State private var showImportOptions = false
    @State var isExtractingMetadata = false
    @State var showExtractionWorkbench = false
    @State var extractionWorkbenchVM: ExtractionWorkbenchViewModel?
    @State var currentPDFURL: URL?
    @State var extractedMetadata: PDFMetadata?
    @State var currentExtractionLogs: String = ""
    @State var processingStartTime: Date?

    // 金句輪播
    @State private var currentQuoteIndex = 0
    @State private var quoteTimer: Timer?
    
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
                Section {
                    NavigationLink(value: "dashboard") {
                        HStack(spacing: theme.spacingMD) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selection == "dashboard" ? theme.accent : theme.textSecondary)
                                .frame(width: 24)
                            
                            Text("寫作首頁")
                                .font(theme.fontSidebarItem)  // 14pt
                                .foregroundColor(selection == "dashboard" ? theme.textPrimary : theme.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    NavigationLink(value: "library") {
                        HStack(spacing: theme.spacingMD) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selection == "library" ? theme.accent : theme.textSecondary)
                                .frame(width: 24)
                            
                            Text("文獻庫")
                                .font(theme.fontSidebarItem)
                                .foregroundColor(selection == "library" ? theme.textPrimary : theme.textSecondary)
                            
                            Spacer()
                            
                            if entries.count > 0 {
                                Text("\(entries.count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(theme.accent)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(theme.accent.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    NavigationLink(value: "aiCenter") {
                        HStack(spacing: theme.spacingMD) {
                            Image(systemName: "apple.intelligence")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selection == "aiCenter" ? theme.accent : theme.textSecondary)
                                .frame(width: 24)
                            
                            Text("AI 智慧中心")
                                .font(theme.fontSidebarItem)
                                .foregroundColor(selection == "aiCenter" ? theme.textPrimary : theme.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("研究中心")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textTertiary)
                        .textCase(.uppercase)
                        .padding(.top, theme.spacingSM)
                }
                
                // 專案管理
                Section {
                    ForEach(documents.filter { $0.type == .general }.prefix(5)) { doc in
                        NavigationLink(value: "doc_\(doc.id.uuidString)") {
                            HStack(spacing: theme.spacingMD) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .frame(width: 24)
                                
                                Text(doc.title)
                                    .font(theme.fontBodySmall)  // 13pt
                                    .foregroundColor(theme.textPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 1)
                        }
                    }
                    
                    if documents.filter({ $0.type == .general }).isEmpty {
                        Button(action: { createNewDocument(type: .general) }) {
                            HStack(spacing: theme.spacingMD) {
                                Image(systemName: "plus.circle.dashed")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(theme.textTertiary)
                                    .frame(width: 24)
                                
                                Text("建立文稿")
                                    .font(theme.fontBodySmall)
                                    .foregroundColor(theme.textTertiary)
                            }
                            .padding(.vertical, 1)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("一般文稿")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textTertiary)
                        .textCase(.uppercase)
                        .padding(.top, theme.spacingMD)
                }
                
                Section("筆記摘要") {
                    ForEach(documents.filter { $0.type == .note }.prefix(5)) { doc in
                        NavigationLink(value: "doc_\(doc.id.uuidString)") {
                            Label(doc.title, systemImage: "note.text")
                        }
                    }
                    
                    if documents.filter({ $0.type == .note }).isEmpty {
                        Label("尚無筆記", systemImage: "plus.circle.dashed")
                            .foregroundColor(theme.textTertiary)
                            .onTapGesture {
                                createNewDocument(type: .note)
                            }
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
            .scrollContentBackground(.hidden)
            .background(theme.sidebarGlass)
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
                        onNewProject: { createNewDocument(type: .general) }
                    )
                    .environmentObject(theme)
                    
                case "library":
                    EmeraldLibraryView()
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
            .background(Color.clear) // Clear background for detail view to let window background show
        }
        .background(
            ZStack {
                theme.background
                theme.liquidGradient.ignoresSafeArea()
            }
        )
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
    
    private func createNewDocument(type: Document.DocumentType = .general) {
        let title = type == .general ? "新文稿" : "新筆記"
        let doc = Document(context: viewContext, title: title)
        doc.type = type
        try? viewContext.save()
        selectedDocument = doc
        selection = "doc_\(doc.id.uuidString)"
        ToastManager.shared.showSuccess("已建立\(type.displayName)")
    }
    
    private func createNote(for entry: Entry?) {
        let title = entry != nil ? "筆記：\(entry!.title)" : "新筆記"
        let doc = Document(context: viewContext, title: title)
        doc.type = .note
        
        if let entry = entry {
            var currentCitations = doc.citations ?? []
            currentCitations.insert(entry)
            doc.citations = currentCitations
        }
        
        try? viewContext.save()
        selectedDocument = doc
        selection = "doc_\(doc.id.uuidString)"
        ToastManager.shared.showSuccess("已建立筆記")
    }
    
}

// MARK: - Dashboard 視圖

struct SimpleDashboardView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext

    let documents: [Document]
    var onProjectTap: (Document) -> Void
    var onNewProject: () -> Void

    let momentumData: [Double] = [0.2, 0.5, 0.1, 0.8, 0.4, 0.3, 0.9, 0.6, 0.7, 0.2, 0.4, 0.5, 0.8, 1.0]

    // 金句輪播狀態
    @State private var currentQuoteIndex = 0
    @State private var quoteTimer: Timer?
    
    // 選取模式狀態
    @State private var isSelectionMode: Bool = false
    @State private var selectedDocumentIDs: Set<UUID> = []
    @State private var showBatchDeleteConfirm: Bool = false
    
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

                            // 金句卡片
                            dailyQuoteCard
                                .padding(.vertical, 8)

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
                    
                    if !documents.isEmpty {
                        // 選取模式按鈕
                        Button(action: { 
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedDocumentIDs.removeAll()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.system(size: 16, weight: .medium))
                                Text(isSelectionMode ? "取消選取" : "選取")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.accentLight)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: onNewProject) {
                        Label("新建專案", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(theme.accent)
                }
                
                // 批次操作工具列
                if isSelectionMode && !selectedDocumentIDs.isEmpty {
                    HStack(spacing: 16) {
                        Text("已選取 \(selectedDocumentIDs.count) 個專案")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textMuted)
                        
                        Spacer()
                        
                        Button(action: { 
                            if selectedDocumentIDs.count == documents.count {
                                selectedDocumentIDs.removeAll()
                            } else {
                                selectedDocumentIDs = Set(documents.map { $0.id })
                            }
                        }) {
                            Text(selectedDocumentIDs.count == documents.count ? "取消全選" : "全選")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.accent)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { showBatchDeleteConfirm = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                Text("刪除")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.border, lineWidth: 1)
                    )
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
                        ForEach(documents.filter { !$0.isDeleted && $0.managedObjectContext != nil }.prefix(6)) { document in
                            EnhancedProjectCard(
                                document: document, 
                                theme: theme,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedDocumentIDs.contains(document.id)
                            )
                            .onTapGesture { 
                                if isSelectionMode {
                                    toggleSelection(document.id)
                                } else {
                                    onProjectTap(document)
                                }
                            }
                        }
                    }
                }
            }
            .padding(45)
        }
        .alert("確定刪除 \(selectedDocumentIDs.count) 個專案？", isPresented: $showBatchDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                batchDeleteDocuments()
            }
        } message: {
            Text("此操作將刪除所有選取的文稿，無法還原。")
        }
    }
    
    // MARK: - 批次操作方法
    
    private func toggleSelection(_ documentID: UUID) {
        if selectedDocumentIDs.contains(documentID) {
            selectedDocumentIDs.remove(documentID)
        } else {
            selectedDocumentIDs.insert(documentID)
        }
    }
    
    private func batchDeleteDocuments() {
        // 1. 先收集要刪除的 ObjectIDs（比直接持有對象更安全）
        let idsToDelete = selectedDocumentIDs
        let objectIDs = documents
            .filter { idsToDelete.contains($0.id) }
            .map { $0.objectID }
        
        let deleteCount = objectIDs.count
        
        guard deleteCount > 0 else {
            selectedDocumentIDs.removeAll()
            isSelectionMode = false
            return
        }
        
        // 2. 清空選取狀態（防止 UI 持有已刪除對象）
        selectedDocumentIDs.removeAll()
        isSelectionMode = false
        
        // 3. 在背景線程執行刪除
        let container = PersistenceController.shared.container
        
        Task.detached(priority: .userInitiated) {
            let backgroundContext = container.newBackgroundContext()
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var success = true
            
            await backgroundContext.perform {
                for objectID in objectIDs {
                    do {
                        let document = try backgroundContext.existingObject(with: objectID)
                        backgroundContext.delete(document)
                    } catch {
                        // 對象可能已被刪除,忽略此錯誤
                        continue
                    }
                }
                
                do {
                    try backgroundContext.save()
                } catch {
                    success = false
                    #if DEBUG
                    print("批次刪除失敗：\(error)")
                    #endif
                }
            }
            
            // 4. 回到主線程更新 UI
            await MainActor.run {
                if success {
                    ToastManager.shared.showSuccess("已刪除 \(deleteCount) 個專案")
                } else {
                    ToastManager.shared.showError("刪除失敗")
                }
            }
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

    // MARK: - 金句庫存

    private let inspirationalQuotes: [(text: String, author: String)] = [
        ("研究的目的不在於證明自己是對的，而在於發現真理。", "卡爾·波普爾"),
        ("在科學研究中，問對問題比找到答案更重要。", "愛因斯坦"),
        ("學術寫作是思想的建築，每一句話都是支撐論點的磚石。", "溫貝托·艾可"),
        ("優秀的論文不是一次完成的，而是反覆打磨的結果。", "海明威"),
        ("研究者的使命是站在前人的肩膀上，看得更遠。", "牛頓"),
        ("批判性思考是學術研究的靈魂。", "約翰·杜威"),
        ("文獻回顧不是堆砌資料，而是建構對話。", "韋恩·布斯"),
        ("寫作是思考的過程，而非思考的記錄。", "E.M.佛斯特"),
        ("每一個偉大的研究都始於一個小小的好奇。", "瑪麗·居里"),
        ("論文的價值在於其對知識體系的貢獻，而非篇幅。", "威廉·斯特倫克"),
        ("學術誠信是研究者最寶貴的資產。", "羅伯特·默頓"),
        ("數據不會說話，但研究者必須讓數據說出有意義的故事。", "愛德華·塔夫特"),
        ("研究方法是通往真理的地圖，選對方法才能到達目的地。", "查爾斯·達爾文"),
        ("引用不僅是致敬，更是將個人研究置於學術傳統之中。", "米歇爾·傅柯"),
        ("寫論文如同登山，每一步都要踏實，最終才能登頂。", "艾德蒙·希拉里"),
        ("好的研究問題值得用一生去探索。", "漢娜·鄂蘭"),
        ("學術寫作需要清晰、精確、優雅三者兼具。", "史蒂芬·平克"),
        ("研究的過程比結果更能塑造一個學者。", "托馬斯·庫恩"),
        ("每一份文獻都是前人智慧的結晶，值得尊重與學習。", "本傑明·富蘭克林"),
        ("論文的邏輯如同音樂的旋律，必須和諧流暢。", "路德維希·維根斯坦"),
        ("學術研究是一場馬拉松，而非短跑。", "村上春樹"),
        ("資料分析如同偵探辦案，細節中藏著真相。", "夏洛克·福爾摩斯"),
        ("寫作的第一步是克服空白頁的恐懼。", "安妮·拉莫特"),
        ("創新來自於對既有知識的質疑與重組。", "史蒂夫·賈伯斯"),
        ("研究倫理不是限制，而是保護研究價值的盾牌。", "艾莉絲·沃克")
    ]

    // MARK: - 金句卡片視圖

    private var dailyQuoteCard: some View {
        let quote = inspirationalQuotes[currentQuoteIndex]

        return HStack(spacing: 12) {
            // 左側引號裝飾
            VStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accent.opacity(0.4))
                Spacer()
            }

            // 金句內容
            VStack(alignment: .leading, spacing: 6) {
                Text(quote.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineSpacing(3)
                    .transition(.opacity)
                    .id("quote-\(currentQuoteIndex)")

                Text("— \(quote.author)")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
                    .italic()
            }

            Spacer()

            // 右側切換按鈕
            VStack(spacing: 6) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        previousQuote()
                    }
                }) {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("上一句")

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        nextQuote()
                    }
                }) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("下一句")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.accent.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            startQuoteRotation()
        }
        .onDisappear {
            stopQuoteRotation()
        }
    }

    // MARK: - 金句控制方法

    private func startQuoteRotation() {
        // 隨機選擇初始金句
        currentQuoteIndex = Int.random(in: 0..<inspirationalQuotes.count)

        // 每45秒自動切換金句
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                nextQuote()
            }
        }
    }

    private func stopQuoteRotation() {
        quoteTimer?.invalidate()
        quoteTimer = nil
    }

    private func nextQuote() {
        currentQuoteIndex = (currentQuoteIndex + 1) % inspirationalQuotes.count
    }

    private func previousQuote() {
        currentQuoteIndex = (currentQuoteIndex - 1 + inspirationalQuotes.count) % inspirationalQuotes.count
    }
}

// MARK: - 原始變數保留位置
// 以下變數移至 SimpleDashboardView 內

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
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        // Guard against deleted Core Data objects
        if document.isDeleted || document.managedObjectContext == nil {
            EmptyView()
        } else {
            ZStack(alignment: .topTrailing) {
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
                        .stroke(
                            isSelected ? theme.accent : (isHovered ? theme.accent.opacity(0.3) : theme.border), 
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: isHovered)
                .onHover { hovering in isHovered = hovering }
                
                // 選取指示器
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? theme.accent : theme.textMuted)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(theme.card)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .padding(8)
                }
            }
        }
    }
    
    private var progress: Int {
        // Guard against deleted Core Data objects
        guard !document.isDeleted, document.managedObjectContext != nil else {
            return 0
        }
        return min(Int(Double(document.attributedString.string.count) / 50.0), 100)
    }
    
    private func formatDate(_ date: Date) -> String {
        // Guard against deleted Core Data objects
        guard !document.isDeleted, document.managedObjectContext != nil else {
            return ""
        }
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
