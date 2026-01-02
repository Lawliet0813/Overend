//
//  EditorSidebarView.swift
//  OVEREND
//
//  編輯器專用側邊欄 - 專案管理、參考文獻、AI 助手
//

import SwiftUI
import CoreData

/// 編輯器側邊欄區塊類型
enum EditorSidebarSection: String, CaseIterable {
    case projects = "專案"
    case recent = "最近編輯"
    case aiAssistant = "AI 助手"
    
    var icon: String {
        switch self {
        case .projects: return "folder.fill"
        case .recent: return "clock.fill"
        case .aiAssistant: return "apple.intelligence"
        }
    }
}

/// 編輯器側邊欄視圖
struct EditorSidebarView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 文稿查詢
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>
    
    // 文獻查詢
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.citationKey, ascending: true)],
        animation: .default
    )
    private var entries: FetchedResults<Entry>
    
    // 側邊欄狀態
    @State private var expandedSections: Set<EditorSidebarSection> = [.projects]
    @State private var searchText = ""
    
    // 回調
    var onSelectDocument: ((Document) -> Void)?
    var onInsertCitation: ((Entry) -> Void)?
    var onExitEditor: (() -> Void)?  // 退出編輯器
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            headerView
            
            Divider()
            
            // 側邊欄內容
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(EditorSidebarSection.allCases, id: \.self) { section in
                        sectionView(for: section)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 200, idealWidth: 240, maxWidth: 280)
        .background(theme.sidebar)
    }
    
    // MARK: - 標題區
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // 首頁按鈕 - 精緻設計
            Button(action: { onExitEditor?() }) {
                HStack(spacing: 12) {
                    // 漸層圖示背景
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accent, theme.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("返回寫作中心")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("退出編輯器")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.accent.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.card)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 12)
            
            Divider()
            
            // 標題
            HStack(spacing: 8) {
                Text("OVEREND")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(theme.sidebar)
    }
    
    // MARK: - 區塊視圖
    
    @ViewBuilder
    private func sectionView(for section: EditorSidebarSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 區塊標題
            Button(action: { toggleSection(section) }) {
                HStack(spacing: 8) {
                    Image(systemName: expandedSections.contains(section) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                        .frame(width: 12)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 12))
                        .foregroundColor(theme.accent)
                    
                    Text(section.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 區塊內容
            if expandedSections.contains(section) {
                sectionContent(for: section)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    @ViewBuilder
    private func sectionContent(for section: EditorSidebarSection) -> some View {
        switch section {
        case .projects:
            projectsContent
        case .recent:
            recentContent
        case .aiAssistant:
            aiAssistantContent
        }
    }
    
    // MARK: - Projects 區塊
    
    private var projectsContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(documents.prefix(10), id: \.id) { document in
                documentRow(document)
            }
            
            if documents.isEmpty {
                emptyStateRow(text: "尚無專案", icon: "plus.circle")
            }
        }
        .padding(.leading, 32)
        .padding(.trailing, 12)
        .padding(.bottom, 8)
    }
    
    private func documentRow(_ document: Document) -> some View {
        Button(action: { onSelectDocument?(document) }) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                
                Text(document.title)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            // 可在此添加 hover 效果
        }
    }
    
    // MARK: - Recent 區塊
    
    private var recentContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            let recentDocs = documents.filter { doc in
                Date().timeIntervalSince(doc.updatedAt) < 7 * 24 * 3600 // 7 天內
            }.prefix(5)
            
            ForEach(Array(recentDocs), id: \.id) { document in
                documentRow(document)
            }
            
            if recentDocs.isEmpty {
                emptyStateRow(text: "無最近編輯", icon: "clock")
            }
        }
        .padding(.leading, 32)
        .padding(.trailing, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Bibliography 區塊
    
    private var bibliographyContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 搜尋欄
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMuted)
                
                TextField("搜尋文獻...", text: $searchText)
                    .font(.system(size: 12))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.itemHover)
            )
            .padding(.bottom, 6)
            
            // 文獻列表
            let filteredEntries = filterEntries()
            ForEach(filteredEntries.prefix(15), id: \.id) { entry in
                entryRow(entry)
            }
            
            if filteredEntries.isEmpty {
                emptyStateRow(text: "尚無參考文獻", icon: "book")
            }
        }
        .padding(.leading, 32)
        .padding(.trailing, 12)
        .padding(.bottom, 8)
    }
    
    private func entryRow(_ entry: Entry) -> some View {
        Button(action: { onInsertCitation?(entry) }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fields["title"] ?? "無標題")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                
                Text(formatAuthor(entry.fields["author"] ?? "未知"))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func filterEntries() -> [Entry] {
        if searchText.isEmpty {
            return Array(entries)
        }
        let lowercased = searchText.lowercased()
        return entries.filter { entry in
            entry.citationKey.lowercased().contains(lowercased) ||
            (entry.fields["title"] ?? "").lowercased().contains(lowercased) ||
            (entry.fields["author"] ?? "").lowercased().contains(lowercased)
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
    
    // MARK: - AI Assistant 區塊
    
    private var aiAssistantContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // AI 功能按鈕
            aiActionButton(title: "智慧排版", icon: "doc.text.fill", color: .blue)
            aiActionButton(title: "語法校對", icon: "checkmark.circle.fill", color: .green)
            aiActionButton(title: "摘要生成", icon: "text.alignleft", color: .purple)
            aiActionButton(title: "翻譯潤飾", icon: "globe", color: .orange)
        }
        .padding(.leading, 32)
        .padding(.trailing, 12)
        .padding(.bottom, 8)
    }
    
    private func aiActionButton(title: String, icon: String, color: Color) -> some View {
        Button(action: {
            // TODO: 觸發 AI 功能
            NotificationCenter.default.post(name: NSNotification.Name("ShowAICommandPalette"), object: nil)
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 輔助視圖
    
    private func emptyStateRow(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(theme.textMuted)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
    
    // MARK: - 輔助方法
    
    private func toggleSection(_ section: EditorSidebarSection) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let theme = AppTheme()
    
    return EditorSidebarView(
        onSelectDocument: { doc in print("Selected: \(doc.title)") },
        onInsertCitation: { entry in print("Insert: \(entry.citationKey)") }
    )
    .environmentObject(theme)
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .frame(height: 600)
}
