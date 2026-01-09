//
//  BatchOperationsToolbar.swift
//  OVEREND
//
//  批次操作工具列
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

/// 批次操作工具列
struct BatchOperationsToolbar: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedEntries: Set<Entry>
    @Binding var isSelectionMode: Bool
    
    // 所有可選書目
    let allEntries: [Entry]
    
    // 可用群組和標籤
    let availableGroups: [Group]
    let availableTags: [Tag]
    
    // 回調
    var onEntriesUpdated: () -> Void
    
    @State private var showDeleteConfirm = false
    @State private var showTypeSelector = false
    @State private var showGroupSelector = false
    @State private var showTagSelector = false
    @State private var showValidationResults = false
    @State private var showExportPanel = false
    
    @State private var selectedNewType: String = "article"
    @State private var selectedGroups: Set<Group> = []
    @State private var selectedTags: Set<Tag> = []
    @State private var validationResults: [BatchOperationService.ValidationResult] = []
    
    var body: some View {
        HStack(spacing: 12) {
            // 選擇狀態
            selectionInfo
            
            Divider()
                .frame(height: 24)
            
            // 快速操作
            quickActions
            
            Divider()
                .frame(height: 24)
            
            // 更多操作
            moreActionsMenu
            
            Spacer()
            
            // 完成按鈕
            Button("完成") {
                isSelectionMode = false
                selectedEntries.removeAll()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.accent.opacity(0.1))
        .overlay(
            Rectangle()
                .fill(theme.accent)
                .frame(height: 2),
            alignment: .top
        )
        // 刪除確認
        .confirmationDialog(
            "確定要刪除選取的 \(selectedEntries.count) 篇文獻？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("刪除", role: .destructive) {
                performBatchDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作無法復原，相關附件也會一併刪除。")
        }
        // 類型選擇器
        .sheet(isPresented: $showTypeSelector) {
            TypeSelectorSheet(
                selectedType: $selectedNewType,
                onConfirm: {
                    performBatchChangeType()
                    showTypeSelector = false
                },
                onCancel: {
                    showTypeSelector = false
                }
            )
            .environmentObject(theme)
        }
        // 群組選擇器
        .sheet(isPresented: $showGroupSelector) {
            GroupSelectorSheet(
                groups: availableGroups,
                selectedGroups: $selectedGroups,
                onConfirm: {
                    performBatchAddToGroup()
                    showGroupSelector = false
                },
                onCancel: {
                    showGroupSelector = false
                }
            )
            .environmentObject(theme)
        }
        // 標籤選擇器
        .sheet(isPresented: $showTagSelector) {
            TagSelectorSheet(
                tags: availableTags,
                selectedTags: $selectedTags,
                onConfirm: {
                    performBatchAddTags()
                    showTagSelector = false
                },
                onCancel: {
                    showTagSelector = false
                }
            )
            .environmentObject(theme)
        }
        // 驗證結果
        .sheet(isPresented: $showValidationResults) {
            ValidationResultsSheet(
                results: validationResults,
                onDismiss: {
                    showValidationResults = false
                }
            )
            .environmentObject(theme)
        }
    }
    
    // MARK: - 選擇資訊
    
    private var selectionInfo: some View {
        HStack(spacing: 8) {
            Text("已選擇 \(selectedEntries.count) 篇")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.accent)
            
            Button("全選") {
                selectedEntries = Set(allEntries)
            }
            .font(.system(size: 12))
            .foregroundColor(theme.textMuted)
            
            Button("取消全選") {
                selectedEntries.removeAll()
            }
            .font(.system(size: 12))
            .foregroundColor(theme.textMuted)
        }
    }
    
    // MARK: - 快速操作
    
    private var quickActions: some View {
        HStack(spacing: 8) {
            // 刪除
            toolbarButton(icon: "trash", label: "刪除", destructive: true) {
                showDeleteConfirm = true
            }
            
            // 標星
            toolbarButton(icon: "star", label: "標星") {
                performBatchToggleStar(setStarred: true)
            }
            
            // 取消標星
            toolbarButton(icon: "star.slash", label: "取消標星") {
                performBatchToggleStar(setStarred: false)
            }
            
            // 匯出
            toolbarButton(icon: "square.and.arrow.up", label: "匯出") {
                performBatchExport()
            }
        }
    }
    
    // MARK: - 更多操作選單
    
    private var moreActionsMenu: some View {
        Menu {
            Button {
                showTypeSelector = true
            } label: {
                Label("修改書目類型", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Button {
                showGroupSelector = true
            } label: {
                Label("加入群組", systemImage: "folder.badge.plus")
            }
            
            Button {
                showTagSelector = true
            } label: {
                Label("新增標籤", systemImage: "tag")
            }
            
            Divider()
            
            Button {
                performBatchValidate()
            } label: {
                Label("驗證完整性", systemImage: "checkmark.shield")
            }
            
            Button {
                copyBibTeXToClipboard()
            } label: {
                Label("複製 BibTeX", systemImage: "doc.on.doc")
            }
        } label: {
            HStack(spacing: 4) {
                Text("更多操作")
                    .font(.system(size: 12))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.card)
            .cornerRadius(8)
        }
        .menuStyle(.borderlessButton)
    }
    
    // MARK: - 輔助視圖
    
    private func toolbarButton(
        icon: String,
        label: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(destructive ? theme.destructive : theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(selectedEntries.isEmpty)
    }
    
    // MARK: - 操作執行
    
    private func performBatchDelete() {
        do {
            let result = try BatchOperationService.batchDelete(
                entries: Array(selectedEntries),
                context: viewContext
            )
            
            if result.isSuccess {
                toastManager.showSuccess(result.message)
            } else {
                toastManager.showWarning(result.message)
            }
            selectedEntries.removeAll()
            onEntriesUpdated()
        } catch {
            toastManager.showError("刪除失敗：\(error.localizedDescription)")
        }
    }
    
    private func performBatchChangeType() {
        do {
            let result = try BatchOperationService.batchChangeType(
                entries: Array(selectedEntries),
                newType: selectedNewType,
                context: viewContext
            )
            
            toastManager.showSuccess(result.message)
            onEntriesUpdated()
        } catch {
            toastManager.showError("修改失敗")
        }
    }
    
    private func performBatchAddToGroup() {
        guard let group = selectedGroups.first else { return }
        
        do {
            let result = try BatchOperationService.batchAddToGroup(
                entries: Array(selectedEntries),
                group: group,
                context: viewContext
            )
            
            toastManager.showSuccess(result.message)
            onEntriesUpdated()
        } catch {
            toastManager.showError("加入群組失敗")
        }
    }
    
    private func performBatchAddTags() {
        do {
            let result = try BatchOperationService.batchAddTags(
                entries: Array(selectedEntries),
                tags: Array(selectedTags),
                context: viewContext
            )
            
            toastManager.showSuccess(result.message)
            onEntriesUpdated()
        } catch {
            toastManager.showError("新增標籤失敗")
        }
    }
    
    private func performBatchToggleStar(setStarred: Bool) {
        do {
            let result = try BatchOperationService.batchToggleStar(
                entries: Array(selectedEntries),
                setStarred: setStarred,
                context: viewContext
            )
            
            toastManager.showSuccess(result.message)
            onEntriesUpdated()
        } catch {
            toastManager.showError("操作失敗")
        }
    }
    
    private func performBatchExport() {
        let panel = NSSavePanel()
        panel.title = "匯出 BibTeX"
        panel.nameFieldStringValue = "export_\(selectedEntries.count)_entries.bib"
        panel.allowedContentTypes = [.init(filenameExtension: "bib")!]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let result = try BatchOperationService.batchExportBibTeX(
                        entries: Array(selectedEntries),
                        to: url
                    )
                    
                    DispatchQueue.main.async {
                        toastManager.showSuccess(result.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        toastManager.showError("匯出失敗：\(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func performBatchValidate() {
        validationResults = BatchOperationService.batchValidateCompleteness(
            entries: Array(selectedEntries)
        )
        showValidationResults = true
    }
    
    private func copyBibTeXToClipboard() {
        let bibtex = BatchOperationService.generateBibTeXString(entries: Array(selectedEntries))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bibtex, forType: .string)
        toastManager.showSuccess("已複製 \(selectedEntries.count) 篇 BibTeX 至剪貼簿")
    }
}

// MARK: - 子視圖

/// 類型選擇器
struct TypeSelectorSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var selectedType: String
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("選擇書目類型")
                .font(.system(size: 16, weight: .bold))
            
            Picker("類型", selection: $selectedType) {
                ForEach(Constants.BibTeX.supportedTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                Button("取消") { onCancel() }
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button("確認") { onConfirm() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 300)
    }
}

/// 群組選擇器
struct GroupSelectorSheet: View {
    @EnvironmentObject var theme: AppTheme
    let groups: [Group]
    @Binding var selectedGroups: Set<Group>
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("選擇群組")
                .font(.system(size: 16, weight: .bold))
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(groups, id: \.id) { group in
                        HStack {
                            Text(group.name)
                            Spacer()
                            if selectedGroups.contains(group) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.accent)
                            }
                        }
                        .padding(10)
                        .background(selectedGroups.contains(group) ? theme.accentLight : theme.tableRowHover)
                        .cornerRadius(8)
                        .onTapGesture {
                            if selectedGroups.contains(group) {
                                selectedGroups.remove(group)
                            } else {
                                selectedGroups.insert(group)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            
            HStack {
                Button("取消") { onCancel() }
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button("確認") { onConfirm() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 300)
    }
}

/// 標籤選擇器
struct TagSelectorSheet: View {
    @EnvironmentObject var theme: AppTheme
    let tags: [Tag]
    @Binding var selectedTags: Set<Tag>
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("選擇標籤")
                .font(.system(size: 16, weight: .bold))
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(tags, id: \.id) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.colorHex) ?? .gray)
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                                .font(.system(size: 12))
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.accent)
                            }
                        }
                        .padding(8)
                        .background(selectedTags.contains(tag) ? theme.accentLight : theme.tableRowHover)
                        .cornerRadius(6)
                        .onTapGesture {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            
            HStack {
                Button("取消") { onCancel() }
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button("確認") { onConfirm() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 350)
    }
}

/// 驗證結果視圖
struct ValidationResultsSheet: View {
    @EnvironmentObject var theme: AppTheme
    let results: [BatchOperationService.ValidationResult]
    var onDismiss: () -> Void
    
    private var incompleteResults: [BatchOperationService.ValidationResult] {
        results.filter { !$0.isComplete }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "checkmark.shield")
                    .foregroundColor(theme.accent)
                Text("驗證結果")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(20)
            .background(theme.tableRowHover)
            
            Divider()
            
            // 統計
            HStack(spacing: 20) {
                VStack {
                    Text("\(results.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("總數")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
                
                VStack {
                    Text("\(results.count - incompleteResults.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("完整")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
                
                VStack {
                    Text("\(incompleteResults.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("缺欄")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding(20)
            
            Divider()
            
            // 列表
            if incompleteResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("所有文獻欄位完整")
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(incompleteResults.indices, id: \.self) { index in
                            let result = incompleteResults[index]
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.entry.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                    
                                    Text("缺少：\(result.missingFields.joined(separator: ", "))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(theme.tableRowHover)
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                }
            }
            
            Divider()
            
            // 關閉
            HStack {
                Spacer()
                Button("完成") { onDismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .frame(width: 400, height: 450)
    }
}

// MARK: - 預覽

#Preview {
    BatchOperationsToolbar(
        selectedEntries: .constant([]),
        isSelectionMode: .constant(true),
        allEntries: [],
        availableGroups: [],
        availableTags: [],
        onEntriesUpdated: {}
    )
    .environmentObject(AppTheme())
    .environmentObject(ToastManager.shared)
}
