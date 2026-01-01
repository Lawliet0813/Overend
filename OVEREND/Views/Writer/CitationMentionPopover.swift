//
//  CitationMentionPopover.swift
//  OVEREND
//
//  @ 觸發的文獻搜尋彈窗 - 快速引用插入
//

import SwiftUI
import CoreData

/// @ 觸發的文獻搜尋彈窗
struct CitationMentionPopover: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.citationKey, ascending: true)],
        animation: .default
    )
    private var allEntries: FetchedResults<Entry>
    
    @Binding var searchText: String
    @Binding var selectedIndex: Int
    let onSelect: (Entry) -> Void
    let onDismiss: () -> Void
    
    // 過濾後的文獻列表
    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return Array(allEntries.prefix(8))
        }
        let lowercased = searchText.lowercased()
        return allEntries.filter { entry in
            entry.citationKey.lowercased().contains(lowercased) ||
            (entry.fields["title"] ?? "").lowercased().contains(lowercased) ||
            (entry.fields["author"] ?? "").lowercased().contains(lowercased) ||
            (entry.fields["year"] ?? "").contains(lowercased)
        }.prefix(8).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 標題列
            HStack {
                Image(systemName: "at")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accent)
                
                Text("快速引用")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textMuted)
                
                Spacer()
                
                Text("↑↓ 選擇  ↵ 插入  esc 取消")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textMuted.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.tableRowHover)
            
            Divider()
            
            // 搜尋結果列表
            if filteredEntries.isEmpty {
                // 無結果狀態
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textMuted.opacity(0.5))
                    
                    Text("找不到符合的文獻")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                                MentionEntryRow(
                                    entry: entry,
                                    isSelected: index == selectedIndex
                                ) {
                                    onSelect(entry)
                                }
                                .id(index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 240)
                    .onChange(of: selectedIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 320)
        .background(theme.card)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.border, lineWidth: 1)
        )
    }
    
    // MARK: - 鍵盤處理
    
    /// 處理向上鍵
    func moveUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        } else {
            selectedIndex = max(0, filteredEntries.count - 1)
        }
    }
    
    /// 處理向下鍵
    func moveDown() {
        if selectedIndex < filteredEntries.count - 1 {
            selectedIndex += 1
        } else {
            selectedIndex = 0
        }
    }
    
    /// 確認選擇
    func confirmSelection() {
        guard selectedIndex < filteredEntries.count else { return }
        onSelect(filteredEntries[selectedIndex])
    }
}

/// 單一文獻列表項
struct MentionEntryRow: View {
    @EnvironmentObject var theme: AppTheme
    
    let entry: Entry
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // 圖示
                Image(systemName: entryIcon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : theme.accent)
                    .frame(width: 20)
                
                // 文獻資訊
                VStack(alignment: .leading, spacing: 2) {
                    // 標題
                    Text(entry.fields["title"] ?? "無標題")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white : theme.textPrimary)
                        .lineLimit(1)
                    
                    // 作者與年份
                    HStack(spacing: 4) {
                        Text(formatAuthor(entry.fields["author"] ?? ""))
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : theme.textMuted)
                        
                        if let year = entry.fields["year"], !year.isEmpty {
                            Text("(\(year))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isSelected ? .white.opacity(0.9) : theme.accent)
                        }
                    }
                }
                
                Spacer()
                
                // 引用鍵
                Text(entry.citationKey)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : theme.textMuted.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.2) : theme.tableRowHover)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? theme.accent : (isHovered ? theme.itemHover : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - 輔助方法
    
    private var entryIcon: String {
        switch entry.entryType.lowercased() {
        case "article": return "newspaper"
        case "book": return "book"
        case "inproceedings", "conference": return "person.3"
        case "phdthesis", "mastersthesis": return "graduationcap"
        case "techreport": return "doc.text"
        case "misc": return "doc"
        default: return "doc.text"
        }
    }
    
    private func formatAuthor(_ author: String) -> String {
        let parts = author.components(separatedBy: " and ")
        guard let first = parts.first, !first.isEmpty else { return "未知作者" }
        
        // 取第一個作者的姓氏
        let nameParts = first.components(separatedBy: ",")
        let lastName = nameParts.first?.trimmingCharacters(in: .whitespaces) ?? first
        
        if parts.count > 1 {
            return "\(lastName) 等"
        }
        return lastName
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @State var selectedIndex = 0
    
    return CitationMentionPopover(
        searchText: $searchText,
        selectedIndex: $selectedIndex,
        onSelect: { entry in
            print("Selected: \(entry.citationKey)")
        },
        onDismiss: {}
    )
    .environmentObject(AppTheme())
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .padding()
    .background(Color.gray.opacity(0.2))
}
