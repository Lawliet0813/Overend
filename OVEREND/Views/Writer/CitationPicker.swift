//
//  CitationPicker.swift
//  OVEREND
//
//  引用選擇器 - 從文獻庫選擇並插入引用
//

import SwiftUI
import CoreData

/// 引用格式選項
enum CitationInsertStyle: String, CaseIterable {
    case authorYear = "作者年份"      // (Author, Year)
    case fullCitation = "完整引用"    // Full APA citation
    case citeKey = "Citation Key"     // BibTeX key
    
    var description: String {
        switch self {
        case .authorYear: return "例：(Chen, 2024)"
        case .fullCitation: return "完整 APA 格式引用"
        case .citeKey: return "例：chen2024study"
        }
    }
}

/// 引用選擇器視圖
struct CitationPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.citationKey, ascending: true)],
        animation: .default
    )
    private var allEntries: FetchedResults<Entry>
    
    @State private var searchText = ""
    @State private var selectedEntries: Set<Entry.ID> = []
    @State private var insertStyle: CitationInsertStyle = .authorYear
    
    var onInsert: (String) -> Void
    
    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return Array(allEntries)
        }
        
        let lowercased = searchText.lowercased()
        return allEntries.filter { entry in
            entry.citationKey.lowercased().contains(lowercased) ||
            (entry.fields["title"] ?? "").lowercased().contains(lowercased) ||
            (entry.fields["author"] ?? "").lowercased().contains(lowercased)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text("插入引用")
                    .font(.headline)
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // 搜尋欄
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜尋書目...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            // 書目列表
            List(filteredEntries, id: \.id, selection: $selectedEntries) { entry in
                CitationEntryRow(entry: entry, isSelected: selectedEntries.contains(entry.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedEntries.contains(entry.id) {
                            selectedEntries.remove(entry.id)
                        } else {
                            selectedEntries.insert(entry.id)
                        }
                    }
            }
            .listStyle(.inset)
            
            Divider()
            
            // 底部控制區
            VStack(spacing: 12) {
                // 格式選擇
                HStack {
                    Text("引用格式：")
                        .foregroundColor(.secondary)
                    Picker("", selection: $insertStyle) {
                        ForEach(CitationInsertStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }
                
                // 預覽
                if !selectedEntries.isEmpty {
                    Text("預覽：\(generatePreview())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 插入按鈕
                HStack {
                    Text("已選擇 \(selectedEntries.count) 筆")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("插入") {
                        insertSelectedCitations()
                    }
                    .keyboardShortcut(.return)
                    .disabled(selectedEntries.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 500, height: 500)
    }
    
    // MARK: - 輔助方法
    
    private func generatePreview() -> String {
        let entries = allEntries.filter { selectedEntries.contains($0.id) }
        
        switch insertStyle {
        case .authorYear:
            let citations = entries.map { entry -> String in
                let author = formatAuthorShort(entry.fields["author"] ?? "Unknown")
                let year = entry.fields["year"] ?? "n.d."
                return "\(author), \(year)"
            }
            return "(\(citations.joined(separator: "; ")))"
            
        case .fullCitation:
            return entries.map { CitationService.generateAPA(entry: $0) }.joined(separator: "\n")
            
        case .citeKey:
            return entries.map { $0.citationKey }.joined(separator: ", ")
        }
    }
    
    private func formatAuthorShort(_ author: String) -> String {
        // 取第一作者姓氏
        let parts = author.components(separatedBy: " and ")
        guard let firstAuthor = parts.first else { return author }
        
        // 處理中文名字（取姓）
        if firstAuthor.range(of: "\\p{Han}", options: .regularExpression) != nil {
            return String(firstAuthor.prefix(1))
        }
        
        // 處理英文名字（取姓氏）
        let nameParts = firstAuthor.components(separatedBy: ", ")
        return nameParts.first ?? firstAuthor
    }
    
    private func insertSelectedCitations() {
        let citation = generatePreview()
        onInsert(citation)
        dismiss()
    }
}

/// 書目列表項目
struct CitationEntryRow: View {
    let entry: Entry
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 選擇指示器
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                // 標題
                Text(entry.fields["title"] ?? "無標題")
                    .font(.body)
                    .lineLimit(2)
                
                // 作者與年份
                HStack {
                    Text(entry.fields["author"] ?? "未知作者")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let year = entry.fields["year"] {
                        Text("(\(year))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Citation Key
                Text(entry.citationKey)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// Preview temporarily disabled to resolve build conflicts
// #Preview("Citation Picker") {
//     CitationPicker { citation in
//         print("Inserted: \(citation)")
//     }
// }
