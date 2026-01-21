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
    @State private var showExportOptions: Bool = false
    @State private var showTagPicker: Bool = false
    
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
    
    /// 選取的文獻陣列
    private var selectedEntriesArray: [Entry] {
        sortedEntries.filter { selectedEntryIDs.contains($0.id) }
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
                
                // 批次操作按鈕區
                if !selectedEntryIDs.isEmpty {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        // 匯出按鈕
                        Button(action: { showExportOptions = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("匯出")
                                    .font(theme.fontButton)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                    .fill(theme.accentLight)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                            .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .shadow(color: theme.accent.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showExportOptions, arrowEdge: .bottom) {
                            BatchExportOptionsView(
                                selectedEntries: selectedEntriesArray,
                                onDismiss: { showExportOptions = false }
                            )
                            .environmentObject(theme)
                            .environment(\.managedObjectContext, viewContext)
                        }
                        
                        // 加標籤按鈕
                        Button(action: { showTagPicker = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "tag")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("加標籤")
                                    .font(theme.fontButton)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                    .fill(theme.accentLight)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                                            .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .shadow(color: theme.accent.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showTagPicker, arrowEdge: .bottom) {
                            BatchTagPickerView(
                                selectedEntries: selectedEntriesArray,
                                onDismiss: { showTagPicker = false }
                            )
                            .environmentObject(theme)
                            .environment(\.managedObjectContext, viewContext)
                        }
                    }
                }
                
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.fields["title"] ?? "無標題")
                            .font(theme.fontBodyLarge)  // 17pt，更大更清晰
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                            .lineLimit(2)  // 允許兩行顯示
                            .fixedSize(horizontal: false, vertical: true)

                        // 期刊/來源
                        if let journal = entry.fields["journal"], !journal.isEmpty {
                            Text(journal)
                                .font(theme.fontBodySmall)  // 13pt
                                .foregroundColor(theme.textSecondary)
                                .italic()
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, theme.spacingMD)

                    // Tags - 優化樣式
                    if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(Array(tags).sorted(by: { $0.name < $1.name }).prefix(3)) { tag in
                                Text(tag.name)
                                    .font(theme.fontLabel)  // 12pt
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(tag.color.opacity(0.9))
                                    )
                                    .shadow(color: tag.color.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            if tags.count > 3 {
                                Text("+\(tags.count - 3)")
                                    .font(theme.fontLabel)
                                    .foregroundColor(theme.textTertiary)
                            }
                        }
                        .padding(.trailing, theme.spacingMD)
                    }

                    // 作者 / 年份 - 放大字體
                    Text(authorYearText)
                        .font(theme.fontBodyMedium)  // 15pt
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                        .frame(width: 180, alignment: .leading)

                    // 附件數量 - 更清晰的視覺
                    HStack(spacing: 4) {
                        if !entry.attachmentArray.isEmpty {
                            Image(systemName: "paperclip")
                                .font(.system(size: 14, weight: .medium))
                            Text("\(entry.attachmentArray.count)")
                                .font(theme.fontBodyMedium)
                        }
                    }
                    .foregroundColor(entry.attachmentArray.isEmpty ? theme.textTertiary : theme.accent)
                    .frame(width: 60)

                    // 類型標籤 - 更精緻
                    Text(entry.entryType)
                        .font(theme.fontLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadiusSM)
                                .fill(theme.accentLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.cornerRadiusSM)
                                        .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .frame(width: 80)

                    // 刪除按鈕（非選擇模式下顯示）- 優化交互
                    if !isSelectionMode {
                        Button(action: { showDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(isHovered ? theme.destructive : .clear)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isHovered ? theme.destructive.opacity(0.1) : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44)  // 觸控區域
                        .opacity(isHovered ? 1 : 0)
                    } else {
                        Color.clear.frame(width: 44)
                    }
                }
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, theme.spacingMD)  // 增加內間距
            }
            .background(backgroundColor)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered && !isSelected ? 1.01 : 1.0)  // 微妙的縮放
        .shadow(
            color: isSelected ? theme.accent.opacity(0.1) : (isHovered ? .black.opacity(0.08) : .clear),
            radius: isHovered || isSelected ? 6 : 0,
            x: 0,
            y: isHovered || isSelected ? 3 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            withAnimation(AnimationSystem.Easing.quick) {
                isHovered = hovering
            }
            onHover?(hovering)
        }
        // 🎯 新增：右鍵選單
        .contextMenu {
            // 編輯書目
            Button(action: {
                // TODO: 觸發編輯模式
                print("編輯書目：\(entry.title)")
            }) {
                Label("編輯書目", systemImage: "pencil")
            }
            
            Divider()
            
            // 複製引用
            Button(action: {
                let citation = CitationService.generateAPA(entry: entry)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(citation, forType: .string)
            }) {
                Label("複製 APA 引用", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                let citation = CitationService.generateMLA(entry: entry)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(citation, forType: .string)
            }) {
                Label("複製 MLA 引用", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.citationKey, forType: .string)
            }) {
                Label("複製 Citation Key", systemImage: "key")
            }
            
            Divider()
            
            // 開啟 PDF
            if !entry.attachmentArray.isEmpty {
                Button(action: {
                    if let firstPDF = entry.attachmentArray.first {
                        NSWorkspace.shared.open(URL(fileURLWithPath: firstPDF.filePath))
                    }
                }) {
                    Label("開啟 PDF", systemImage: "doc.fill")
                }
            }
            
            Divider()
            
            // 刪除
            Button(role: .destructive, action: { showDeleteConfirm = true }) {
                Label("刪除", systemImage: "trash")
            }
        }
        .contextMenu {
            // MARK: - 開啟操作
            if !entry.attachmentArray.isEmpty {
                Button(action: {
                    if let firstAttachment = entry.attachmentArray.first {
                        NSWorkspace.shared.open(firstAttachment.fileURL)
                    }
                }) {
                    Label("開啟 PDF", systemImage: "doc.text")
                }
            }
            
            if let doi = entry.fields["doi"], !doi.isEmpty {
                Button(action: {
                    let doiURL = doi.hasPrefix("http") ? doi : "https://doi.org/\(doi)"
                    if let url = URL(string: doiURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("開啟 DOI 連結", systemImage: "link")
                }
            }
            
            Divider()
            
            // MARK: - 複製引用
            Menu("複製引用") {
                Button("APA 7th") {
                    let citation = entry.generateAPACitation()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(citation, forType: .string)
                    ToastManager.shared.showSuccess("已複製 APA 引用")
                }
                
                Button("MLA 9th") {
                    let citation = entry.generateMLACitation()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(citation, forType: .string)
                    ToastManager.shared.showSuccess("已複製 MLA 引用")
                }
                
                Divider()
                
                Button("BibTeX") {
                    let bibtex = entry.generateBibTeX()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(bibtex, forType: .string)
                    ToastManager.shared.showSuccess("已複製 BibTeX")
                }
                
                Button("引用鍵") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.citationKey, forType: .string)
                    ToastManager.shared.showSuccess("已複製引用鍵")
                }
            }
            
            Divider()
            
            // MARK: - 組織操作
            Button(action: {
                entry.isStarred.toggle()
                try? entry.managedObjectContext?.save()
                ToastManager.shared.showSuccess(entry.isStarred ? "已加入星號標記" : "已移除星號標記")
            }) {
                Label(entry.isStarred ? "取消星號標記" : "加入星號標記", 
                      systemImage: entry.isStarred ? "star.fill" : "star")
            }
            
            // 開啟多個附件
            if entry.attachmentArray.count > 1 {
                Menu("開啟附件") {
                    ForEach(Array(entry.attachmentArray.enumerated()), id: \.element.id) { index, attachment in
                        Button(action: {
                            NSWorkspace.shared.open(attachment.fileURL)
                        }) {
                            Label(attachment.fileName, systemImage: "doc.fill")
                        }
                    }
                }
            }
            
            Divider()
            
            // MARK: - 編輯與刪除
            Button(action: {
                // TODO: 開啟編輯面板
                ToastManager.shared.showInfo("編輯功能開發中")
            }) {
                Label("編輯書目", systemImage: "pencil")
            }
            
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

// MARK: - Batch Export Options View

/// 批次匯出選項 Popover
struct BatchExportOptionsView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    let selectedEntries: [Entry]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("匯出選項")
                .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                .foregroundColor(theme.textPrimary)
                .padding(.bottom, DesignTokens.Spacing.xs)
            
            // BibTeX 匯出
            Button(action: exportBibTeX) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 18))
                        .foregroundColor(theme.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匯出為 BibTeX")
                            .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        Text("\(selectedEntries.count) 篇文獻")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textTertiary)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(theme.itemHover)
                )
            }
            .buttonStyle(.plain)
            
            // RIS 匯出
            Button(action: exportRIS) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(theme.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匯出為 RIS")
                            .font(.system(size: DesignTokens.Typography.body, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        Text("通用引用格式")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.textMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textTertiary)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(theme.itemHover)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(theme.elevated)
        .cornerRadius(DesignTokens.CornerRadius.large)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    private func exportBibTeX() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "bib")!]
        savePanel.nameFieldStringValue = "export_\(selectedEntries.count)_entries.bib"
        savePanel.title = "匯出 BibTeX"
        savePanel.message = "選擇匯出位置"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let result = try BatchOperationService.batchExportBibTeX(entries: selectedEntries, to: url)
                    ToastManager.shared.showSuccess(result.message)
                    onDismiss()
                } catch {
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func exportRIS() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "ris")!]
        savePanel.nameFieldStringValue = "export_\(selectedEntries.count)_entries.ris"
        savePanel.title = "匯出 RIS"
        savePanel.message = "選擇匯出位置"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let result = try BatchOperationService.batchExportRIS(entries: selectedEntries, to: url)
                    ToastManager.shared.showSuccess(result.message)
                    onDismiss()
                } catch {
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Batch Tag Picker View

/// 批次標籤選擇器 Popover
struct BatchTagPickerView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default
    ) private var allTags: FetchedResults<Tag>
    
    let selectedEntries: [Entry]
    let onDismiss: () -> Void
    
    @State private var selectedTags: Set<Tag> = []
    @State private var newTagName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // 標題
            Text("為選取的文獻加標籤")
                .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            Text("已選取 \(selectedEntries.count) 篇文獻")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textMuted)
            
            Divider()
            
            // 標籤列表
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(allTags, id: \.id) { tag in
                        TagToggleRow(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            onToggle: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        )
                        .environmentObject(theme)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Divider()
            
            // 新增標籤
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(theme.accent)
                
                TextField("建立新標籤", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(createNewTag)
                
                if !newTagName.isEmpty {
                    Button(action: createNewTag) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // 動作按鈕
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("取消") {
                    onDismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("套用標籤 (\(selectedTags.count))") {
                    applyTags()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTags.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(width: 400)
        .background(theme.elevated)
        .cornerRadius(DesignTokens.CornerRadius.large)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    private func createNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let newTag = Tag(context: viewContext)
        newTag.id = UUID()
        newTag.name = trimmed
        newTag.createdAt = Date()
        
        do {
            try viewContext.save()
            selectedTags.insert(newTag)
            newTagName = ""
            ToastManager.shared.showSuccess("已建立標籤：\(trimmed)")
        } catch {
            ToastManager.shared.showError("建立標籤失敗：\(error.localizedDescription)")
        }
    }
    
    private func applyTags() {
        do {
            let result = try BatchOperationService.batchAddTags(
                entries: selectedEntries,
                tags: Array(selectedTags),
                context: viewContext
            )
            ToastManager.shared.showSuccess(result.message)
            onDismiss()
        } catch {
            ToastManager.shared.showError("套用標籤失敗：\(error.localizedDescription)")
        }
    }
}

/// 標籤切換行
struct TagToggleRow: View {
    @EnvironmentObject var theme: AppTheme
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? theme.accent : theme.textTertiary)
                    .font(.system(size: 18))
                
                Text(tag.name)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(isSelected ? theme.accentLight : Color.clear)
            )
        }
        .buttonStyle(.plain)
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

