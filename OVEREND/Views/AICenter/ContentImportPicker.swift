//
//  ContentImportPicker.swift
//  OVEREND
//
//  內容導入選擇器 - 從文獻庫或寫作中心導入內容
//

import SwiftUI
import CoreData

// MARK: - 導入內容類型

/// 文獻導入內容選項
enum LibraryImportContentType: String, CaseIterable, Identifiable {
    case abstract = "摘要"
    case notes = "筆記"
    case bibtex = "BibTeX"
    
    var id: String { rawValue }
}

// MARK: - 文獻選擇器

/// 文獻選擇器視圖
struct LibraryEntryPicker: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)],
        animation: .default
    )
    private var allEntries: FetchedResults<Entry>
    
    @State private var searchText: String = ""
    @State private var selectedContentType: LibraryImportContentType = .abstract
    @State private var selectedLibrary: Library?
    
    let onSelect: (String) -> Void
    
    private var filteredEntries: [Entry] {
        var entries = Array(allEntries)
        
        // 按文獻庫篩選
        if let selectedLibrary = selectedLibrary {
            entries = entries.filter { $0.library?.id == selectedLibrary.id }
        }
        
        // 按搜尋文字篩選
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter { entry in
                entry.title.lowercased().contains(query) ||
                entry.author.lowercased().contains(query) ||
                entry.citationKey.lowercased().contains(query)
            }
        }
        
        return entries
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            headerView
            
            Divider()
            
            // 文獻庫選擇
            if libraries.count > 1 {
                librarySelector
                Divider()
            }
            
            // 內容類型選擇
            contentTypeSelector
            
            Divider()
            
            // 搜尋欄
            searchBar
            
            Divider()
            
            // 文獻列表
            if filteredEntries.isEmpty {
                emptyStateView
            } else {
                entryList
            }
        }
        .frame(width: 500, height: 600)
        .background(theme.card)
        .onAppear {
            // 預設選擇第一個文獻庫（通常是預設庫）
            if selectedLibrary == nil, let firstLibrary = libraries.first {
                selectedLibrary = firstLibrary
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("從文獻庫導入")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                if libraries.count > 1 {
                    Text("選擇文獻庫和要導入的內容")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                } else {
                    Text("選擇要導入的文獻內容")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.lg)
    }
    
    private var librarySelector: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "books.vertical")
                .foregroundColor(theme.accent)
                .font(.system(size: DesignTokens.IconSize.small))
            
            Text("文獻庫")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
            
            Picker("選擇文獻庫", selection: $selectedLibrary) {
                Text("全部文獻庫").tag(nil as Library?)
                ForEach(Array(libraries), id: \.id) { library in
                    HStack {
                        Text(library.name)
                        Text("(\(library.entryCount))")
                            .foregroundColor(theme.textMuted)
                    }
                    .tag(library as Library?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(theme.background)
    }
    
    private var contentTypeSelector: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text("導入內容")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
            
            Picker("內容類型", selection: $selectedContentType) {
                ForEach(LibraryImportContentType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 250)
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(theme.background)
    }
    
    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textMuted)
            
            TextField("搜尋文獻...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.Typography.body))
        }
        .padding(DesignTokens.Spacing.md)
        .background(theme.background)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            
            if allEntries.isEmpty {
                Text("文獻庫為空")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
                
                Text("請先從主介面匯入文獻")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
            } else if selectedLibrary != nil && filteredEntries.isEmpty && searchText.isEmpty {
                Text("此文獻庫中尚無文獻")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
                
                Text("請選擇其他文獻庫或匯入文獻")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
            } else {
                Text("找不到符合的文獻")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
                
                Text("請嘗試其他搜尋關鍵字")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(filteredEntries) { entry in
                    entryRow(entry)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
    
    private func entryRow(_ entry: Entry) -> some View {
        Button(action: { selectEntry(entry) }) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // 圖標
                Image(systemName: "doc.text")
                    .font(.system(size: DesignTokens.IconSize.medium))
                    .foregroundColor(theme.accent)
                    .frame(width: 32)
                
                // 文獻資訊
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(entry.title)
                            .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // 文獻庫標籤（當顯示全部文獻庫時）
                        if selectedLibrary == nil, let library = entry.library {
                            Text(library.name)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.accentLight)
                                .foregroundColor(theme.accent)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(entry.author)
                            .lineLimit(1)
                        
                        if !entry.year.isEmpty {
                            Text("•")
                            Text(entry.year)
                        }
                    }
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
                    
                    // 內容預覽
                    let content = getContent(for: entry)
                    if !content.isEmpty {
                        Text(content)
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                            .padding(.top, 4)
                    } else {
                        Text("（無\(selectedContentType.rawValue)內容）")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                            .italic()
                            .padding(.top, 4)
                    }
                }
                
                // 導入按鈕
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: DesignTokens.IconSize.medium))
                    .foregroundColor(theme.accent)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(theme.background)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getContent(for entry: Entry) -> String {
        switch selectedContentType {
        case .abstract:
            return entry.fields["abstract"] ?? ""
        case .notes:
            return entry.userNotes ?? ""
        case .bibtex:
            return entry.bibtexRaw ?? ""
        }
    }
    
    private func selectEntry(_ entry: Entry) {
        let content = getContent(for: entry)
        if !content.isEmpty {
            onSelect(content)
            dismiss()
        }
    }
}

// MARK: - 文稿選擇器

/// 文稿選擇器視圖
struct DocumentPicker: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>
    
    @State private var searchText: String = ""
    
    let onSelect: (Document, String) -> Void
    
    private var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return Array(documents)
        }
        let query = searchText.lowercased()
        return documents.filter { doc in
            doc.title.lowercased().contains(query)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            headerView
            
            Divider()
            
            // 搜尋欄
            searchBar
            
            Divider()
            
            // 文稿列表
            if filteredDocuments.isEmpty {
                emptyStateView
            } else {
                documentList
            }
        }
        .frame(width: 500, height: 550)
        .background(theme.card)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("從寫作中心導入")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("選擇要導入的文稿")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.lg)
    }
    
    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textMuted)
            
            TextField("搜尋文稿...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.Typography.body))
        }
        .padding(DesignTokens.Spacing.md)
        .background(theme.background)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.textMuted)
            
            Text(searchText.isEmpty ? "尚無文稿" : "找不到符合的文稿")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var documentList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(filteredDocuments) { document in
                    documentRow(document)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
    
    private func documentRow(_ document: Document) -> some View {
        Button(action: { selectDocument(document) }) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // 圖標
                Image(systemName: "doc.richtext")
                    .font(.system(size: DesignTokens.IconSize.medium))
                    .foregroundColor(theme.accent)
                    .frame(width: 32)
                
                // 文稿資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text("更新於 \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                    
                    // 內容預覽
                    let plainText = getPlainText(from: document)
                    if !plainText.isEmpty {
                        Text(plainText)
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                            .padding(.top, 4)
                    } else {
                        Text("（空白文稿）")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                            .italic()
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // 導入按鈕
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: DesignTokens.IconSize.medium))
                    .foregroundColor(theme.accent)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(theme.background)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getPlainText(from document: Document) -> String {
        #if canImport(AppKit)
        return document.attributedString.string
        #else
        return ""
        #endif
    }
    
    private func selectDocument(_ document: Document) {
        let plainText = getPlainText(from: document)
        onSelect(document, plainText)
        dismiss()
    }
}
