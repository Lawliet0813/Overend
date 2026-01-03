//
//  ModernEntryListView.swift
//  OVEREND
//
//  現代化文獻列表 - 表格式呈現 + 詳情面板
//

import SwiftUI
import CoreData

/// 排序欄位
enum SortField: String, CaseIterable {
    case title = "標題"
    case author = "作者"
    case year = "年份"
    case type = "類型"
    case createdAt = "建立時間"
}

/// 現代化文獻列表視圖
struct ModernEntryListView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var library: Library
    @State private var selectedEntry: Entry?
    
    // 排序狀態
    @State private var sortField: SortField = .createdAt
    @State private var sortAscending: Bool = false
    
    // 篩選狀態
    @State private var showFilterPopover = false
    @State private var filterYear: String = ""
    @State private var filterType: String = ""
    
    // 懸停預覽狀態
    @State private var hoveredEntry: Entry?
    @State private var showHoverPreview = false
    @State private var hoverTimer: Timer?
    
    // 批次選取狀態
    @State private var isSelectionMode: Bool = false
    @State private var selectedEntryIDs: Set<UUID> = []
    @State private var showBatchDeleteConfirm: Bool = false
    
    @FetchRequest private var entries: FetchedResults<Entry>
    
    init(library: Library) {
        self.library = library
        _entries = FetchRequest<Entry>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
            predicate: NSPredicate(format: "library == %@", library),
            animation: .default
        )
    }
    
    /// 根據當前排序設定排序結果
    private var sortedEntries: [Entry] {
        let filtered = filterEntries(Array(entries))
        return filtered.sorted { e1, e2 in
            let result: Bool
            switch sortField {
            case .title:
                result = (e1.title).localizedCaseInsensitiveCompare(e2.title) == .orderedAscending
            case .author:
                let a1 = e1.fields["author"] ?? ""
                let a2 = e2.fields["author"] ?? ""
                result = a1.localizedCaseInsensitiveCompare(a2) == .orderedAscending
            case .year:
                let y1 = e1.fields["year"] ?? "0"
                let y2 = e2.fields["year"] ?? "0"
                result = y1 < y2
            case .type:
                result = e1.entryType.localizedCaseInsensitiveCompare(e2.entryType) == .orderedAscending
            case .createdAt:
                result = (e1.createdAt ?? Date()) < (e2.createdAt ?? Date())
            }
            return sortAscending ? result : !result
        }
    }
    
    /// 篩選文獻
    private func filterEntries(_ entries: [Entry]) -> [Entry] {
        var result = entries
        
        if !filterYear.isEmpty {
            result = result.filter { $0.fields["year"]?.contains(filterYear) == true }
        }
        
        if !filterType.isEmpty {
            result = result.filter { $0.entryType.lowercased().contains(filterType.lowercased()) }
        }
        
        return result
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側：文獻列表
            ScrollView {
                if entries.isEmpty {
                    emptyState
                } else {
                    // 批次操作工具列
                    batchOperationToolbar
                    
                    // 表格
                    VStack(spacing: 0) {
                        // 表頭
                        tableHeader

                        // 資料列 - 添加交錯動畫
                        LazyVStack(spacing: 0) {
                            ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                                EntryTableRow(
                                    entry: entry,
                                    isSelected: selectedEntry?.id == entry.id,
                                    isSelectionMode: isSelectionMode,
                                    isChecked: selectedEntryIDs.contains(entry.id),
                                    onTap: {
                                        if isSelectionMode {
                                            toggleSelection(entry)
                                        } else {
                                            print("📌 點擊文獻：\(entry.title)")
                                            withAnimation(AnimationSystem.Easing.quick) {
                                                selectedEntry = entry
                                                print("✅ selectedEntry 已更新：\(selectedEntry?.title ?? "nil")")
                                            }
                                        }
                                    },
                                    onToggleSelection: {
                                        toggleSelection(entry)
                                    },
                                    onDelete: {
                                        deleteEntry(entry)
                                    },
                                    onHover: { isHovering in
                                        handleEntryHover(entry: entry, isHovering: isHovering)
                                    }
                                )
                                .environmentObject(theme)
                                .popover(isPresented: Binding(
                                    get: { showHoverPreview && hoveredEntry?.id == entry.id },
                                    set: { if !$0 { showHoverPreview = false } }
                                )) {
                                    EntryPreviewCard(entry: entry)
                                        .environmentObject(theme)
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                                .animation(
                                    AnimationSystem.Easing.spring.delay(Double(min(index, 20)) * 0.03),
                                    value: sortedEntries.count
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

                if #available(macOS 26.0, *) {
                    ModernEntryDetailView(entry: entry, onClose: {
                        withAnimation(AnimationSystem.Easing.quick) {
                            print("❌ 關閉詳情面板")
                            selectedEntry = nil
                        }
                    })
                        .environmentObject(theme)
                        .environment(\.managedObjectContext, viewContext)
                        .frame(width: 360)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .onAppear {
                            print("🎉 詳情面板顯示：\(entry.title)")
                        }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        Text("詳情視圖需要 macOS 26.0 或以上版本")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        Button("關閉") {
                            withAnimation {
                                selectedEntry = nil
                            }
                        }
                    }
                    .frame(width: 360)
                    .background(theme.sidebar)
                }
            } else {
                // 沒有選中時的佔位
                EmptyView()
                    .onAppear {
                        print("⚪️ 沒有選中的文獻")
                    }
            }
        }
        .animation(AnimationSystem.Easing.spring, value: selectedEntry?.id)
    }
    
    // MARK: - 批次操作工具列
    
    private var batchOperationToolbar: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            if isSelectionMode {
                // 全選/取消全選按鈕 - 遵循 44pt 最小觸控區域
                Button(action: toggleSelectAll) {
                    HStack(spacing: 8) {
                        Image(systemName: selectedEntryIDs.count == sortedEntries.count ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .medium))
                        Text(selectedEntryIDs.count == sortedEntries.count ? "取消全選" : "全選")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accentLight)
                    )
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                
                // 已選取數量標籤
                Text("已選取 \(selectedEntryIDs.count) 項")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.tableRowHover)
                    )
                
                Spacer()
                
                // 刪除按鈕 - 遵循 44pt 最小觸控區域
                if !selectedEntryIDs.isEmpty {
                    Button(action: { showBatchDeleteConfirm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                            Text("刪除選取項目")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.destructive)
                        )
                        .shadow(color: theme.destructive.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
                
                // 完成按鈕 - 遵循 44pt 最小觸控區域
                Button(action: exitSelectionMode) {
                    Text("完成")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.accent, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            } else {
                Spacer()
                
                // 進入選取模式按鈕 - 遵循 44pt 最小觸控區域
                Button(action: { isSelectionMode = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18, weight: .medium))
                        Text("選取")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accentLight)
                    )
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(theme.card)
        .alert("確定刪除 \(selectedEntryIDs.count) 篇文獻？", isPresented: $showBatchDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                batchDeleteEntries()
            }
        } message: {
            Text("此操作將刪除所有選取的文獻及其附件，無法還原。")
        }
    }
    
    // MARK: - 批次操作方法
    
    private func toggleSelection(_ entry: Entry) {
        if selectedEntryIDs.contains(entry.id) {
            selectedEntryIDs.remove(entry.id)
        } else {
            selectedEntryIDs.insert(entry.id)
        }
    }
    
    private func toggleSelectAll() {
        if selectedEntryIDs.count == sortedEntries.count {
            selectedEntryIDs.removeAll()
        } else {
            selectedEntryIDs = Set(sortedEntries.map { $0.id })
        }
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedEntryIDs.removeAll()
    }
    
    private func batchDeleteEntries() {
        let deleteCount = selectedEntryIDs.count
        
        // 先收集要刪除的文獻，避免在迭代過程中修改集合
        let entriesToDelete = entries.filter { selectedEntryIDs.contains($0.id) }
        
        // 使用 performAndWait 確保在主執行緒上同步執行
        viewContext.performAndWait {
            for entry in entriesToDelete {
                // 刪除附件文件
                for attachment in entry.attachmentArray {
                    try? PDFService.deleteAttachment(attachment, context: viewContext)
                }
                // 刪除 Entry
                viewContext.delete(entry)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("批次刪除失敗：\(error)")
                viewContext.rollback()
            }
        }
        
        // 在主執行緒上更新 UI
        DispatchQueue.main.async {
            ToastManager.shared.showSuccess("已刪除 \(deleteCount) 篇文獻")
            self.exitSelectionMode()
        }
    }
    
    // MARK: - 表頭
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // 標題欄位（可排序）
            sortableHeaderButton(field: .title)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 作者/年份欄位（可排序）
            sortableHeaderButton(field: .author, displayName: "作者 / 年份")
                .frame(width: 150, alignment: .leading)

            Text("附件")
                .font(.system(size: DesignTokens.Typography.body, weight: .bold))
                .foregroundColor(theme.textMuted)
                .frame(width: 50, alignment: .center)

            // 類型欄位（可排序）
            sortableHeaderButton(field: .type, displayName: "類型")
                .frame(width: 70, alignment: .center)

            // 篩選按鈕
            Button(action: { showFilterPopover.toggle() }) {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14))
                    .foregroundColor(hasActiveFilters ? theme.accent : theme.textMuted)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showFilterPopover) {
                filterPopoverContent
            }
            .frame(width: 40)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(theme.tableRowHover)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
    
    /// 可排序表頭按鈕
    private func sortableHeaderButton(field: SortField, displayName: String? = nil) -> some View {
        Button(action: {
            withAnimation(AnimationSystem.Easing.quick) {
                if sortField == field {
                    sortAscending.toggle()
                } else {
                    sortField = field
                    sortAscending = true
                }
            }
        }) {
            HStack(spacing: 4) {
                Text(displayName ?? field.rawValue)
                    .font(.system(size: DesignTokens.Typography.body, weight: .bold))
                
                if sortField == field {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(theme.accent)
                }
            }
            .foregroundColor(sortField == field ? theme.accent : theme.textMuted)
        }
        .buttonStyle(.plain)
    }
    
    /// 是否有啟用的篩選
    private var hasActiveFilters: Bool {
        !filterYear.isEmpty || !filterType.isEmpty
    }
    
    /// 篩選面板內容
    private var filterPopoverContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("篩選條件")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("年份")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                TextField("如：2024", text: $filterYear)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("類型")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                TextField("如：article", text: $filterType)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
            }
            
            HStack {
                Button("清除篩選") {
                    filterYear = ""
                    filterType = ""
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(theme.destructive)
                .disabled(!hasActiveFilters)
                
                Spacer()
                
                Button("完成") {
                    showFilterPopover = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.accent)
            }
        }
        .padding(16)
        .frame(width: 200)
    }
    
    /// 處理文獻懸停
    private func handleEntryHover(entry: Entry, isHovering: Bool) {
        hoverTimer?.invalidate()
        
        if isHovering {
            hoveredEntry = entry
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                DispatchQueue.main.async {
                    showHoverPreview = true
                }
            }
        } else {
            showHoverPreview = false
            hoveredEntry = nil
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
    var isSelectionMode: Bool = false
    var isChecked: Bool = false
    let onTap: () -> Void
    var onToggleSelection: (() -> Void)? = nil
    let onDelete: () -> Void
    var onHover: ((Bool) -> Void)? = nil
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false

    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 選擇模式下顯示複選框
                if isSelectionMode {
                    Button(action: { onToggleSelection?() }) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(isChecked ? theme.accent : theme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 36)
                } else {
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
                }
                
                // 原有的 HStack 內容
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

                    // Tags
                    if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(tags).sorted(by: { $0.name < $1.name })) { tag in
                                Text(tag.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(tag.color)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.trailing, 8)
                    }

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

                    // 刪除按鈕（非選擇模式下顯示）
                    if !isSelectionMode {
                        Button(action: { showDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: DesignTokens.IconSize.small))
                                .foregroundColor(isHovered ? theme.destructive : theme.textMuted.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 40)
                        .opacity(isHovered ? 1 : 0)
                    } else {
                        Color.clear.frame(width: 40)
                    }
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
            onHover?(hovering)
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

