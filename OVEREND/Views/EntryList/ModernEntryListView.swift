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

                        // 資料列 - 添加交錯動畫
                        LazyVStack(spacing: 0) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                EntryTableRow(
                                    entry: entry,
                                    isSelected: selectedEntry?.id == entry.id,
                                    onTap: {
                                        withAnimation(AnimationSystem.Easing.quick) {
                                            selectedEntry = entry
                                        }
                                    },
                                    onDelete: {
                                        deleteEntry(entry)
                                    }
                                )
                                .environmentObject(theme)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                                .animation(
                                    AnimationSystem.Easing.spring.delay(Double(min(index, 20)) * 0.03),
                                    value: entries.count
                                )
                            }
                        }
                    }
                    .background(
                        ZStack {
                            // 基礎卡片背景
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .fill(theme.card)
                            
                            // 添加微妙漸變光澤
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(theme.isDarkMode ? 0.03 : 0.2),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                    .cornerRadius(DesignTokens.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.border,
                                        theme.border.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    // 增強陰影效果
                    .shadow(
                        color: Color.black.opacity(theme.isDarkMode ? 0.2 : 0.12),
                        radius: 15,
                        x: 0,
                        y: 6
                    )
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .frame(maxWidth: .infinity)

            // 右側：詳情面板
            if let entry = selectedEntry {
                Divider()

                ModernEntryDetailView(entry: entry, onClose: {
                    withAnimation(AnimationSystem.Easing.quick) {
                        selectedEntry = nil
                    }
                })
                    .environmentObject(theme)
                    .frame(width: 360)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(AnimationSystem.Easing.spring, value: selectedEntry?.id)
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
        .font(.system(size: DesignTokens.Typography.body, weight: .bold))
        .foregroundColor(theme.textMuted)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
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
        VStack(spacing: DesignTokens.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.text")
                    .font(.system(size: DesignTokens.IconSize.xLarge))
                    .foregroundColor(theme.accent)
            }
            .scaleEffect(1.0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("尚無文獻")
                    .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Text("匯入 PDF 或 BibTeX 開始管理您的文獻")
                    .font(.system(size: DesignTokens.Typography.body))
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
                // 選中高亮條
                if isSelected {
                    Rectangle()
                        .fill(theme.accent)
                        .frame(width: 3)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Color.clear
                        .frame(width: 3)
                }

                HStack(spacing: 0) {
                    // 標題
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text(entry.fields["title"] ?? "無標題")
                            .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                            .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                            .lineLimit(1)

                        // 期刊/來源
                        if let journal = entry.fields["journal"], !journal.isEmpty {
                            Text(journal)
                                .font(.system(size: DesignTokens.Typography.caption))
                                .foregroundColor(theme.textMuted)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 作者 / 年份
                    Text(authorYearText)
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textMuted)
                        .lineLimit(1)
                        .frame(width: 150, alignment: .leading)

                    // 附件數量
                    HStack(spacing: DesignTokens.Spacing.xxs) {
                        if !entry.attachmentArray.isEmpty {
                            Image(systemName: "paperclip")
                                .font(.system(size: DesignTokens.IconSize.small))
                            Text("\(entry.attachmentArray.count)")
                                .font(.system(size: DesignTokens.Typography.body))
                        }
                    }
                    .foregroundColor(theme.textMuted)
                    .frame(width: 50)

                    // 類型標籤
                    Text(entry.entryType)
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.accentLight)
                        )
                        .frame(width: 70)

                    // 刪除按鈕
                    Button(action: { showDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: DesignTokens.IconSize.small))
                            .foregroundColor(isHovered ? theme.destructive : theme.textMuted.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 40)
                    .opacity(isHovered ? 1 : 0)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
            .background(backgroundColor)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered && !isSelected ? 1.005 : 1.0)
        .shadow(
            color: isHovered && !isSelected ? .black.opacity(0.05) : .clear,
            radius: isHovered ? 4 : 0,
            x: 0,
            y: isHovered ? 2 : 0
        )
        .animation(AnimationSystem.Easing.spring, value: isSelected)
        .animation(AnimationSystem.Easing.quick, value: isHovered)
        .onHover { hovering in
            withAnimation(AnimationSystem.Easing.quick) {
                isHovered = hovering
            }
        }
        .contextMenu {
            // 複製引用鍵
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.citationKey, forType: .string)
                ToastManager.shared.showSuccess("已複製引用鍵")
            }) {
                Label("複製引用鍵", systemImage: "doc.on.doc")
            }

            // 複製 BibTeX
            Button(action: {
                let bibtex = entry.generateBibTeX()
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(bibtex, forType: .string)
                ToastManager.shared.showSuccess("已複製 BibTeX")
            }) {
                Label("複製 BibTeX", systemImage: "doc.text")
            }

            Divider()

            // 開啟附件
            if !entry.attachmentArray.isEmpty {
                Menu("開啟附件") {
                    ForEach(Array(entry.attachmentArray.enumerated()), id: \.element.id) { index, attachment in
                        Button(action: {
                            NSWorkspace.shared.open(attachment.fileURL)
                        }) {
                            Text(attachment.fileName)
                        }
                    }
                }

                Divider()
            }

            // 編輯
            Button(action: {
                // TODO: 開啟編輯面板
                ToastManager.shared.showInfo("編輯功能開發中")
            }) {
                Label("編輯", systemImage: "pencil")
            }

            // 刪除
            Button(role: .destructive, action: {
                showDeleteConfirm = true
            }) {
                Label("刪除", systemImage: "trash")
            }
        }
        .alert("確定刪除？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                withAnimation(AnimationSystem.Easing.spring) {
                    onDelete()
                }
            }
        } message: {
            Text("此操作將刪除「\(entry.title)」及其所有附件，無法還原。")
        }
    }

    // MARK: - 計算屬性

    /// 背景顏色
    private var backgroundColor: Color {
        if isSelected {
            return theme.accentLight
        } else if isHovered {
            return theme.tableRowHover
        } else {
            return Color.clear
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
                    .animation(AnimationSystem.Easing.spring, value: progress)
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
            .font(.system(size: DesignTokens.Typography.body, weight: .bold))
            .foregroundColor(theme.accent)
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(theme.accentLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
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

