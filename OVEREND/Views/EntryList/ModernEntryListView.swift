//
//  ModernEntryListView.swift
//  OVEREND
//
//  現代化文獻列表 - 表格式呈現 + 詳情面板
//

import SwiftUI
import CoreData

/// 現代化文獻列表視圖
struct ModernEntryListView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var library: Library
    @State private var selectedEntry: Entry?
    
    @FetchRequest private var entries: FetchedResults<Entry>
    
    init(library: Library) {
        self.library = library
        _entries = FetchRequest<Entry>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
            predicate: NSPredicate(format: "library == %@", library),
            animation: .default
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側：文獻列表
            ScrollView {
                if entries.isEmpty {
                    emptyState
                } else {
                    // 表格
                    VStack(spacing: 0) {
                        // 表頭
                        tableHeader
                        
                        // 資料列
                        LazyVStack(spacing: 0) {
                            ForEach(entries) { entry in
                                EntryTableRow(
                                    entry: entry,
                                    isSelected: selectedEntry?.id == entry.id,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedEntry = entry
                                        }
                                    },
                                    onDelete: {
                                        deleteEntry(entry)
                                    }
                                )
                                .environmentObject(theme)
                            }
                        }
                    }
                    .background(theme.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 右側：詳情面板
            if let entry = selectedEntry {
                Divider()
                
                ModernEntryDetailView(entry: entry, onClose: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedEntry = nil
                    }
                })
                    .environmentObject(theme)
                    .frame(width: 360)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedEntry?.id)
    }
    
    // MARK: - 表頭
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("標題")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("作者 / 年份")
                .frame(width: 150, alignment: .leading)
            
            Text("附件")
                .frame(width: 50, alignment: .center)
            
            Text("類型")
                .frame(width: 70, alignment: .center)
            
            Text("")
                .frame(width: 40)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(theme.textMuted)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.tableRowHover)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
    
    // MARK: - 删除文獨
    
    private func deleteEntry(_ entry: Entry) {
        // 如果正在選中，先取消選中
        if selectedEntry?.id == entry.id {
            selectedEntry = nil
        }
        
        // 删除附件文件
        for attachment in entry.attachmentArray {
            try? PDFService.deleteAttachment(attachment, context: viewContext)
        }
        
        // 删除 Entry
        viewContext.delete(entry)
        
        do {
            try viewContext.save()
        } catch {
            print("删除文獨失敗：\(error)")
        }
    }
    
    // MARK: - 空狀態
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 32))
                    .foregroundColor(theme.accent)
            }
            
            VStack(spacing: 8) {
                Text("尚無文獻")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("匯入 PDF 或 BibTeX 開始管理您的文獻")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

/// 文獻表格列
struct EntryTableRow: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var entry: Entry
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 標題
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.fields["title"] ?? "無標題")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                        .lineLimit(1)
                    
                    // 期刊/來源
                    if let journal = entry.fields["journal"], !journal.isEmpty {
                        Text(journal)
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 作者 / 年份
                Text(authorYearText)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
                    .frame(width: 150, alignment: .leading)
                
                // 附件數量
                HStack(spacing: 4) {
                    if !entry.attachmentArray.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 11))
                        Text("\(entry.attachmentArray.count)")
                            .font(.system(size: 11))
                    }
                }
                .foregroundColor(theme.textMuted)
                .frame(width: 50)
                
                // 類型標籤
                Text(entry.entryType)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.accentLight)
                    )
                    .frame(width: 70)
                
                // 刪除按鈕
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(isHovered ? .red : theme.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
                .frame(width: 40)
                .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? theme.accentLight :
                (isHovered ? theme.tableRowHover : Color.clear)
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(theme.accent)
                        .frame(width: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .alert("確定刪除？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("此操作將刪除「\(entry.title)」及其所有附件，無法還原。")
        }
    }
    
    private var authorYearText: String {
        let author = entry.fields["author"] ?? "未知作者"
        let year = entry.fields["year"] ?? ""
        let shortAuthor = author.components(separatedBy: " and ").first ?? author
        return year.isEmpty ? shortAuthor : "\(shortAuthor) (\(year))"
    }
}

/// 進度條
struct ProgressBar: View {
    @EnvironmentObject var theme: AppTheme
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.itemHover)
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.accent)
                    .frame(width: geometry.size.width * CGFloat(progress), height: 4)
            }
        }
        .frame(height: 4)
    }
}

/// 影響力標籤
struct ImpactBadge: View {
    @EnvironmentObject var theme: AppTheme
    let impact: String
    
    var body: some View {
        Text(impact)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.accentLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    let context = PersistenceController.preview.container.viewContext
    
    let library = Library(context: context)
    library.id = UUID()
    library.name = "測試庫"
    library.createdAt = Date()
    library.updatedAt = Date()
    
    return ModernEntryListView(library: library)
        .environmentObject(theme)
        .environmentObject(viewState)
        .environment(\.managedObjectContext, context)
        .frame(width: 1000, height: 600)
}

