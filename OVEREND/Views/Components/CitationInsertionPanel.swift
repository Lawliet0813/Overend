//
//  CitationInsertionPanel.swift
//  OVEREND
//
//  引用插入面板 - 快速搜尋並插入引用
//

import SwiftUI
import CoreData

/// 引用插入面板
struct CitationInsertionPanel: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var isPresented: Bool
    var onInsertCitation: (String, [Entry]) -> Void
    
    @State private var searchQuery = ""
    @State private var selectedEntries: [Entry] = []
    @State private var pageNumber = ""
    @State private var citationFormat: CitationService.CitationFormat = .apa7
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)],
        animation: .default
    )
    private var allEntries: FetchedResults<Entry>
    
    private var filteredEntries: [Entry] {
        if searchQuery.isEmpty {
            return Array(allEntries.prefix(20))
        }
        
        return allEntries.filter { entry in
            let title = entry.title.lowercased()
            let author = entry.author.lowercased()
            let query = searchQuery.lowercased()
            return title.contains(query) || author.contains(query)
        }
    }
    
    private var citationPreview: String {
        guard !selectedEntries.isEmpty else { return "" }
        
        let inline = CitationService.shared.generateInlineCitation(
            entries: selectedEntries,
            pageNumber: pageNumber.isEmpty ? nil : pageNumber
        )
        return inline.text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 標題列
            HStack {
                Text("插入引用")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("⌘⇧C")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(theme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.tableRowHover)
                    .cornerRadius(4)
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(theme.tableRowHover)
            
            Divider()
            
            // MARK: - 搜尋列
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.textMuted)
                
                TextField("搜尋標題或作者...", text: $searchQuery)
                    .textFieldStyle(.plain)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(theme.card)
            
            Divider()
            
            // MARK: - 已選擇的引用
            if !selectedEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("已選擇 \(selectedEntries.count) 篇")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.accent)
                        
                        Spacer()
                        
                        Button("清除") {
                            selectedEntries.removeAll()
                        }
                        .font(.system(size: 11))
                        .foregroundColor(theme.destructive)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedEntries, id: \.id) { entry in
                                selectedEntryChip(entry)
                            }
                        }
                    }
                    
                    // 頁碼輸入
                    HStack {
                        Text("頁碼")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textMuted)
                        
                        TextField("例如：23-25", text: $pageNumber)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                }
                .padding(12)
                .background(theme.accentLight)
                
                Divider()
            }
            
            // MARK: - 引用預覽
            if !selectedEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("預覽")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                    
                    Text(citationPreview)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.tableRowHover)
                        .cornerRadius(8)
                }
                .padding(12)
                
                Divider()
            }
            
            // MARK: - 文獻列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEntries, id: \.id) { entry in
                        entryRow(entry)
                    }
                    
                    if filteredEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(theme.textTertiary)
                            
                            Text("沒有找到符合的文獻")
                                .font(.system(size: 13))
                                .foregroundColor(theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    }
                }
                .padding(12)
            }
            
            Divider()
            
            // MARK: - 操作按鈕
            HStack {
                // 格式選擇
                Picker("格式", selection: $citationFormat) {
                    ForEach(CitationService.CitationFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Spacer()
                
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textMuted)
                
                Button("插入引用") {
                    insertCitation()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .disabled(selectedEntries.isEmpty)
            }
            .padding(16)
            .background(theme.tableRowHover)
        }
        .frame(width: 400, height: 550)
        .background(theme.card)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - 子視圖
    
    private func entryRow(_ entry: Entry) -> some View {
        let isSelected = selectedEntries.contains(where: { $0.id == entry.id })
        
        return Button {
            toggleSelection(entry)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(entry.author)
                            .lineLimit(1)
                        
                        Text("·")
                        
                        Text(entry.year)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMuted)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.accent)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(12)
            .background(isSelected ? theme.accentLight : theme.tableRowHover)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func selectedEntryChip(_ entry: Entry) -> some View {
        HStack(spacing: 6) {
            Text(entry.author.components(separatedBy: " ").last ?? entry.author)
                .font(.system(size: 11, weight: .medium))
            
            Text(entry.year)
                .font(.system(size: 10))
                .foregroundColor(theme.textMuted)
            
            Button {
                selectedEntries.removeAll { $0.id == entry.id }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.card)
        .cornerRadius(8)
    }
    
    // MARK: - 操作
    
    private func toggleSelection(_ entry: Entry) {
        if let index = selectedEntries.firstIndex(where: { $0.id == entry.id }) {
            selectedEntries.remove(at: index)
        } else {
            selectedEntries.append(entry)
        }
    }
    
    private func insertCitation() {
        let inline = CitationService.shared.generateInlineCitation(
            entries: selectedEntries,
            pageNumber: pageNumber.isEmpty ? nil : pageNumber
        )
        
        onInsertCitation(inline.text, selectedEntries)
        isPresented = false
    }
}

// MARK: - 快速引用按鈕（用於編輯器側邊欄）

struct QuickCitationButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let entry: Entry
    var onInsert: (String) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                
                Text("\(entry.author), \(entry.year)")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                let citation = CitationService.shared.generateInlineCitation(
                    entries: [entry],
                    pageNumber: nil
                )
                onInsert(citation.text)
            } label: {
                Text("插入")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.accent)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(theme.tableRowHover)
        .cornerRadius(8)
    }
}

// MARK: - 預覽

#Preview {
    CitationInsertionPanel(
        isPresented: .constant(true),
        onInsertCitation: { _, _ in }
    )
    .environmentObject(AppTheme())
    .padding(40)
    .background(Color.gray.opacity(0.3))
}
