//
//  iPadContentView.swift
//  OVEREND iPad
//
//  iPad 版本的主要內容視圖 - 使用 NavigationSplitView 三欄佈局
//

#if os(iOS)
import SwiftUI
import CoreData

struct iPadContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // 導航狀態
    @State private var selectedLibrary: Library?
    @State private var selectedEntry: Entry?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // UI 狀態
    @State private var searchText = ""
    @State private var showingNewLibrarySheet = false
    @State private var showingImportSheet = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第一欄：文獻庫列表
            iPadLibrarySidebar(
                selectedLibrary: $selectedLibrary,
                showingNewLibrarySheet: $showingNewLibrarySheet
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
        } content: {
            // 第二欄：書目列表
            if let library = selectedLibrary {
                iPadEntryListView(
                    library: library,
                    selectedEntry: $selectedEntry,
                    searchText: $searchText
                )
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
            } else {
                ContentUnavailableView(
                    "選擇文獻庫",
                    systemImage: "folder",
                    description: Text("從左側選擇一個文獻庫來瀏覽書目")
                )
            }
        } detail: {
            // 第三欄：書目詳情
            if let entry = selectedEntry {
                iPadEntryDetailView(entry: entry)
            } else {
                ContentUnavailableView(
                    "選擇書目",
                    systemImage: "doc.text",
                    description: Text("選擇一個書目來查看詳細資訊")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewLibrarySheet) {
            iPadNewLibrarySheet(isPresented: $showingNewLibrarySheet)
        }
    }
}

// MARK: - Library Sidebar

struct iPadLibrarySidebar: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>
    
    @Binding var selectedLibrary: Library?
    @Binding var showingNewLibrarySheet: Bool
    
    var body: some View {
        List(selection: $selectedLibrary) {
            Section {
                ForEach(libraries) { library in
                    NavigationLink(value: library) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(library.name ?? "未命名")
                                    .font(.headline)
                                
                                Text("\(library.entries?.count ?? 0) 個書目")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteLibraries)
            } header: {
                Text("文獻庫")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("OVEREND")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewLibrarySheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if libraries.isEmpty {
                ContentUnavailableView {
                    Label("沒有文獻庫", systemImage: "folder.badge.plus")
                } description: {
                    Text("點擊右上角的 + 創建新的文獻庫")
                } actions: {
                    Button("創建文獻庫") {
                        showingNewLibrarySheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func deleteLibraries(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(libraries[index])
        }
        
        do {
            try viewContext.save()
        } catch {
            print("刪除失敗: \(error)")
        }
    }
}

// MARK: - Entry List View

struct iPadEntryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let library: Library
    @Binding var selectedEntry: Entry?
    @Binding var searchText: String
    
    @FetchRequest private var entries: FetchedResults<Entry>
    
    init(library: Library, selectedEntry: Binding<Entry?>, searchText: Binding<String>) {
        self.library = library
        self._selectedEntry = selectedEntry
        self._searchText = searchText
        
        self._entries = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Entry.title, ascending: true)],
            predicate: NSPredicate(format: "library == %@", library),
            animation: .default
        )
    }
    
    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return Array(entries)
        }
        return entries.filter { entry in
            entry.title?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.authors?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    var body: some View {
        List(selection: $selectedEntry) {
            ForEach(filteredEntries) { entry in
                NavigationLink(value: entry) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title ?? "未命名")
                            .font(.headline)
                            .lineLimit(2)
                        
                        if let authors = entry.authors, !authors.isEmpty {
                            Text(authors)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 8) {
                            if let year = entry.year {
                                Label(year, systemImage: "calendar")
                                    .font(.caption)
                            }
                            
                            if let journal = entry.journal, !journal.isEmpty {
                                Label(journal, systemImage: "book")
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteEntries)
        }
        .listStyle(.plain)
        .navigationTitle(library.name ?? "書目")
        .searchable(text: $searchText, prompt: "搜尋書目...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        // TODO: 新增書目
                    } label: {
                        Label("新增書目", systemImage: "plus")
                    }
                    
                    Button {
                        // TODO: 匯入 PDF
                    } label: {
                        Label("匯入 PDF", systemImage: "doc.badge.plus")
                    }
                    
                    Button {
                        // TODO: 匯入 BibTeX
                    } label: {
                        Label("匯入 BibTeX", systemImage: "text.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if filteredEntries.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label("沒有書目", systemImage: "doc.text")
                    } description: {
                        Text("點擊右上角的 + 新增書目或匯入文獻")
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        for entry in entriesToDelete {
            viewContext.delete(entry)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("刪除失敗: \(error)")
        }
    }
}

// MARK: - Entry Detail View

struct iPadEntryDetailView: View {
    @ObservedObject var entry: Entry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 標題區域
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title ?? "未命名")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let authors = entry.authors, !authors.isEmpty {
                        Text(authors)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // 元資料網格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MetadataItem(label: "年份", value: entry.year)
                    MetadataItem(label: "期刊", value: entry.journal)
                    MetadataItem(label: "DOI", value: entry.doi)
                    MetadataItem(label: "類型", value: entry.entryType)
                }
                
                // 摘要
                if let abstract = entry.abstract, !abstract.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("摘要")
                            .font(.headline)
                        
                        Text(abstract)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("書目詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        // TODO: 編輯
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    
                    if entry.pdfData != nil {
                        Button {
                            // TODO: 開啟 PDF
                        } label: {
                            Label("開啟 PDF", systemImage: "doc.fill")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        // TODO: 刪除
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct MetadataItem: View {
    let label: String
    let value: String?
    
    var body: some View {
        if let value = value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - New Library Sheet

struct iPadNewLibrarySheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var libraryName = ""
    @State private var libraryDescription = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("文獻庫名稱", text: $libraryName)
                    TextField("描述（選填）", text: $libraryDescription)
                }
            }
            .navigationTitle("新增文獻庫")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("創建") {
                        createLibrary()
                    }
                    .disabled(libraryName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func createLibrary() {
        let library = Library(context: viewContext)
        library.id = UUID()
        library.name = libraryName
        library.createdAt = Date()
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("創建失敗: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    iPadContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#endif
