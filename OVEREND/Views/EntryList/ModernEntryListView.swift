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
    var filterMode: SidebarItemType? = nil // 新增：篩選模式
    
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
    
    init(library: Library, filterMode: SidebarItemType? = nil) {
        self.library = library
        self.filterMode = filterMode
        
        // 根據 filterMode 調整預設排序
        let sortDescriptors: [NSSortDescriptor]
        if filterMode == .recent {
            sortDescriptors = [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)]
        } else {
            sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        }
        
        _entries = FetchRequest<Entry>(
            sortDescriptors: sortDescriptors,
            predicate: NSPredicate(format: "library == %@", library),
            animation: .default
        )
    }
    
    /// 根據當前排序設定排序結果
    private var sortedEntries: [Entry] {
        var baseEntries = Array(entries)
        
        // 1. 應用側邊欄模式篩選
        if let mode = filterMode {
            // 先過濾垃圾桶狀態
            if mode == .trash {
                baseEntries = baseEntries.filter { $0.fields["_deleted"] == "true" }
            } else {
                baseEntries = baseEntries.filter { $0.fields["_deleted"] != "true" }
            }
            
            // 再根據模式篩選
            switch mode {
            case .favorites:
                baseEntries = baseEntries.filter { $0.fields["_starred"] == "true" }
            case .recent:
                baseEntries = Array(baseEntries.prefix(50))
            case .pdf:
                baseEntries = baseEntries.filter { entry in
                    entry.attachmentArray.contains { $0.mimeType == "application/pdf" }
                }
            case .toRead:
                baseEntries = baseEntries.filter { $0.fields["_status"] == "unread" || $0.tagsArray.contains { $0.name == "待閱讀" } }
            case .trash:
                break // 已在上面處理
            case .allEntries:
                break
            case .drafts:
                break // 應由 DraftsListView 處理
            }
        } else {
            // 默認排除垃圾桶
            baseEntries = baseEntries.filter { $0.fields["_deleted"] != "true" }
        }
        
        // 2. 應用列表內篩選 (年份/類型)
        let filtered = filterEntries(baseEntries)
        
        // 3. 排序 (如果使用者手動調整了排序，會覆蓋 Sidebar 的預設排序概念)
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
                result = e1.createdAt < e2.createdAt
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
                                    onRestore: {
                                        restoreEntry(entry)
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

                if #available(macOS 14.0, *) {
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
    
    // MARK: - 批次操作工具列（增強版）
    
    private var batchOperationToolbar: some View {
        HStack(spacing: theme.spacingLG) {
            if isSelectionMode {
                // 全選/取消全選按鈕
                Button(action: toggleSelectAll) {
                    HStack(spacing: 10) {
                        Image(systemName: selectedEntryIDs.count == sortedEntries.count ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                        Text(selectedEntryIDs.count == sortedEntries.count ? "取消全選" : "全選")
                            .font(theme.fontButton)
                    }
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                            .fill(theme.accentLight)
                            .shadow(color: theme.accent.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                
                // 已選取數量標籤 - 更顯眼
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.accent)
                    Text("已選取 \(selectedEntryIDs.count) 項")
                        .font(theme.fontBodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                        .fill(theme.accent.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                .stroke(theme.accent.opacity(0.2), lineWidth: 1.5)
                        )
                )
                
                Spacer()
                
                // 刪除按鈕 - 更醒目
                if !selectedEntryIDs.isEmpty {
                    Button(action: { showBatchDeleteConfirm = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("刪除選取項目")
                                .font(theme.fontButton)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [theme.destructive, theme.destructive.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMD))
                        )
                        .shadow(color: theme.destructive.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
                
                // 完成按鈕 - 更清晰
                Button(action: exitSelectionMode) {
                    Text("完成")
                        .font(theme.fontButton)
                        .fontWeight(.bold)
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                .stroke(theme.accent, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            } else {
                Spacer()
                
                // 進入選取模式按鈕 - 更顯眼
                Button(action: { isSelectionMode = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("批次選取")
                            .font(theme.fontButton)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentLight, theme.accentLight.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                    .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: theme.accent.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, theme.spacingXL)
        .padding(.vertical, theme.spacingLG)
        .background(
            theme.card
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(theme.cornerRadiusMD)
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
        // 1. 收集要刪除的 ObjectIDs（比直接持有對象更安全）
        let idsToDelete = selectedEntryIDs
        let objectIDs = entries
            .filter { idsToDelete.contains($0.id) }
            .map { $0.objectID }
        
        let deleteCount = objectIDs.count
        
        guard deleteCount > 0 else {
            exitSelectionMode()
            return
        }
        
        // 2. 先清空選取狀態（防止 UI 持有已刪除對象）
        exitSelectionMode()
        
        // 3. 在背景線程執行刪除
        let container = PersistenceController.shared.container
        
        Task.detached(priority: .userInitiated) {
            let backgroundContext = container.newBackgroundContext()
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var success = true
            
            await backgroundContext.perform {
                for objectID in objectIDs {
                    do {
                        let entry = try backgroundContext.existingObject(with: objectID) as? Entry
                        
                        // 刪除附件文件
                        if let entry = entry {
                            for attachment in entry.attachmentArray {
                                try? FileManager.default.removeItem(atPath: attachment.filePath)
                            }
                        }
                        
                        // 刪除 Entry
                        if let entry = entry {
                            backgroundContext.delete(entry)
                        }
                    } catch {
                        // 對象可能已被刪除,忽略此錯誤
                        continue
                    }
                }
                
                do {
                    try backgroundContext.save()
                } catch {
                    success = false
                    #if DEBUG
                    print("批次刪除失敗：\(error)")
                    #endif
                }
            }
            
            // 4. 回到主線程更新 UI
            await MainActor.run {
                if success {
                    ToastManager.shared.showSuccess("已刪除 \(deleteCount) 篇文獻")
                } else {
                    ToastManager.shared.showError("刪除失敗")
                }
            }
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
    
    // MARK: - 删除文獻
    
    private func deleteEntry(_ entry: Entry) {
        let isAlreadyDeleted = entry.fields["_deleted"] == "true"
        
        // 如果已經在垃圾桶中，則執行永久刪除
        if isAlreadyDeleted {
            permanentDeleteEntry(entry)
        } else {
            // 否則執行軟刪除 (移至垃圾桶)
            softDeleteEntry(entry)
        }
    }
    
    private func softDeleteEntry(_ entry: Entry) {
        entry.fields["_deleted"] = "true"
        entry.updatedAt = Date()
        
        // 如果正在選中，取消選中
        if selectedEntry?.id == entry.id {
            selectedEntry = nil
        }
        
        try? viewContext.save()
        ToastManager.shared.showSuccess("已移至垃圾桶")
    }
    
    private func permanentDeleteEntry(_ entry: Entry) {
        // 先保存所有需要的資料，避免在異步執行時存取已失效的物件
        let entryObjectID = entry.objectID
        let entryTitle = entry.title
        let attachmentPaths = entry.attachmentArray.map { $0.filePath }
        
        // 如果正在選中，先取消選中
        if selectedEntry?.id == entry.id {
            selectedEntry = nil
        }
        
        // 從批次選取中移除
        selectedEntryIDs.remove(entry.id)
        
        // 延遲刪除，讓 UI 先更新
        DispatchQueue.main.async {
            // 刪除附件文件（使用預先提取的路徑）
            for filePath in attachmentPaths {
                try? FileManager.default.removeItem(atPath: filePath)
            }
            
            // 使用 objectID 重新獲取 Entry 並刪除
            do {
                if let entryToRemove = try? viewContext.existingObject(with: entryObjectID) {
                    viewContext.delete(entryToRemove)
                }
                try viewContext.save()
                ToastManager.shared.showSuccess("已永久刪除「\(entryTitle)」")
            } catch {
                ErrorLogger.shared.log(error, context: "ModernEntryListView.deleteEntry")
                ToastManager.shared.showError("刪除失敗")
            }
        }
    }
    
    // 復原邏輯
    private func restoreEntry(_ entry: Entry) {
        entry.fields["_deleted"] = nil
        entry.updatedAt = Date()
        try? viewContext.save()
        ToastManager.shared.showSuccess("已復原文獻")
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

/// 文獻表格列 - 已移至 EntryListComponents.swift
// struct EntryTableRow - 見 EntryListComponents.swift
// struct ProgressBar - 見 EntryListComponents.swift  
// struct ImpactBadge - 見 EntryListComponents.swift

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
