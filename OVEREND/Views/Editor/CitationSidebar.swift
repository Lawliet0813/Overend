//
//  CitationSidebar.swift
//  OVEREND
//
//  引用側邊欄元件 - 從 DocumentEditorView 拆分
//

import SwiftUI

// MARK: - 引用側邊欄

struct CitationSidebarView: View {
    @EnvironmentObject var theme: AppTheme
    
    let libraries: [Library]
    @Binding var selectedLibrary: Library?
    let onInsertCitation: (Entry) -> Void
    
    @State private var searchText = ""
    
    var filteredEntries: [Entry] {
        guard let library = selectedLibrary else { return [] }
        let entries = Array(library.entries ?? [])
        
        if searchText.isEmpty {
            return entries.sorted { $0.title < $1.title }
        }
        
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "quote.bubble")
                    .foregroundColor(theme.accent)
                Text("參考文獻")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }
            .padding()
            .background(theme.elevated)
            
            Divider()
            
            // 文獻庫選擇（必須選擇）
            Picker("選擇文獻庫", selection: $selectedLibrary) {
                Text("選擇文獻庫...").tag(nil as Library?)
                ForEach(libraries, id: \.id) { library in
                    Text(library.name).tag(library as Library?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // 搜尋（只有選擇文獻庫後才顯示）
            if selectedLibrary != nil {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    TextField("搜尋文獻...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(8)
                .padding()
            }
            
            // 文獻列表或空狀態
            if selectedLibrary == nil {
                // 空狀態：未選擇文獻庫
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textTertiary)
                    Text("請選擇文獻庫")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    Text("從上方選單選擇要使用的文獻庫")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else if filteredEntries.isEmpty {
                // 空狀態：無文獻
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(theme.textTertiary)
                    Text("無符合的文獻")
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                // 文獻列表
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEntries, id: \.id) { entry in
                            CitationEntryRow(entry: entry, onInsert: onInsertCitation)
                                .environmentObject(theme)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(theme.background)
    }
}

// MARK: - 引用條目列

struct CitationEntryRow: View {
    @EnvironmentObject var theme: AppTheme
    let entry: Entry
    let onInsert: (Entry) -> Void
    
    @State private var isHovered = false
    @State private var selectedFormat: CitationFormat = .apa
    
    enum CitationFormat: String, CaseIterable, Identifiable {
        case apa = "APA 7th"
        case mla = "MLA 9th"
        case chicago = "Chicago"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標題
            Text(entry.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
            
            // 作者和年份
            HStack {
                Text(entry.author)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
                
                if !entry.year.isEmpty {
                    Text("(\(entry.year))")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                
                Spacer()
            }
            
            // 格式選擇 + 插入按鈕
            HStack(spacing: 8) {
                Picker("格式", selection: $selectedFormat) {
                    ForEach(CitationFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                
                Button(action: { 
                    // TODO: 根據 selectedFormat 生成對應格式的引用
                    onInsert(entry) 
                }) {
                    Label("插入", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(theme.accent)
            }
        }
        .padding(12)
        .background(isHovered ? theme.elevated : theme.background)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
