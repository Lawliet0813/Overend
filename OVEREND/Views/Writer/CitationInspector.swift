//
//  CitationInspector.swift
//  OVEREND
//
//  引用快速面板 - 右側引用文獻列表
//

import SwiftUI
import CoreData

/// 引用快速面板
struct CitationInspector: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.citationKey, ascending: true)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>
    
    @State private var searchText = ""
    var onInsertCitation: (Entry) -> Void
    
    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return Array(entries.prefix(20))
        }
        let lowercased = searchText.lowercased()
        return entries.filter { entry in
            entry.citationKey.lowercased().contains(lowercased) ||
            (entry.fields["title"] ?? "").lowercased().contains(lowercased) ||
            (entry.fields["author"] ?? "").lowercased().contains(lowercased)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 標題
            Text("文獻庫快速引用")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // 搜尋欄
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                
                TextField("搜尋文獻...", text: $searchText)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.itemHover)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            // 文獻列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEntries, id: \.id) { entry in
                        CitationCard(entry: entry) {
                            onInsertCitation(entry)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // AI 助手提示
            aiAssistantTip
        }
        .frame(width: 260)
        .background(theme.sidebar)
    }
    
    // MARK: - AI 助手提示
    
    private var aiAssistantTip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("💡")
                Text("AI 排版助手")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.accent)
            }
            
            Text("已偵測到引用標記，是否自動生成 APA 參考文獻清單？")
                .font(.system(size: 9))
                .foregroundColor(theme.textMuted)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.accentLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(12)
    }
}

/// 引用卡片
struct CitationCard: View {
    @EnvironmentObject var theme: AppTheme
    let entry: Entry
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.fields["title"] ?? "無標題")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(formatAuthor(entry.fields["author"] ?? "未知"))
                        .font(.system(size: 9))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    if isHovered {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.border, lineWidth: 1)
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.accentLight : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatAuthor(_ author: String) -> String {
        let parts = author.components(separatedBy: " and ")
        guard let first = parts.first else { return author }
        if parts.count > 1 {
            return "\(first) 等"
        }
        return first
    }
}

#Preview {
    let theme = AppTheme()
    
    return CitationInspector { entry in
        print("Insert: \(entry.citationKey)")
    }
    .environmentObject(theme)
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .frame(height: 500)
}
