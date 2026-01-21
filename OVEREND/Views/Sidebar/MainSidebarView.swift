//
//  MainSidebarView.swift
//  OVEREND
//
//  新版側邊欄 - 現代化 macOS 風格
//

import SwiftUI

/// 新版側邊欄
struct MainSidebarView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @ObservedObject var libraryVM: LibraryViewModel
    
    @State private var showNewLibrarySheet = false
    @State private var showThemeSettings = false
    @State private var showRenameSheet = false
    @State private var libraryToRename: Library?
    @State private var showDeleteConfirm = false
    @State private var libraryToDelete: Library?
    
    var body: some View {
        VStack(spacing: 0) {
            // 品牌 Header
            HStack {
                Text("OVEREND")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.accent)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(height: 52) // 與 DynamicToolbar 對齊
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }
            
            // 側邊欄內容
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    // 資源管理區塊
                    sectionHeader("資源管理")

                    SidebarButton(
                        icon: "books.vertical",
                        title: "全部文獻",
                        isSelected: viewState.activeSidebarItem == .allEntries,
                        badge: libraryVM.totalEntryCount > 0 ? libraryVM.totalEntryCount : nil
                    ) {
                        viewState.showLibrary()
                    }

                    SidebarButton(
                        icon: "pencil.line",
                        title: "寫作中心",
                        isSelected: viewState.activeSidebarItem == .writingCenter
                    ) {
                        viewState.showWritingCenter()
                    }

                    SidebarButton(
                        icon: "apple.intelligence",
                        title: "AI 智慧中心",
                        isSelected: viewState.activeSidebarItem == .aiCenter
                    ) {
                        viewState.showAICenter()
                    }


                    // 智能過濾區塊
                    sectionHeader("智能過濾")
                        .padding(.top, DesignTokens.Spacing.md)

                    SidebarButton(
                        icon: "clock",
                        title: "最近閱覽",
                        isSelected: viewState.activeSidebarItem == .recentlyViewed
                    ) {
                        viewState.activeSidebarItem = .recentlyViewed
                    }

                    SidebarButton(
                        icon: "bookmark.fill",
                        title: "待讀標註",
                        isSelected: viewState.activeSidebarItem == .bookmarked
                    ) {
                        viewState.activeSidebarItem = .bookmarked
                    }

                    // 文獻庫區塊
                    sectionHeaderWithButton("文獻庫") {
                        showNewLibrarySheet = true
                    }
                    .padding(.top, DesignTokens.Spacing.md)

                    ForEach(libraryVM.libraries) { library in
                        SidebarButton(
                            icon: library.isDefault ? "star.fill" : "folder",
                            title: library.name,
                            isSelected: viewState.selectedLibrary?.id == library.id,
                            badge: library.entryCount
                        ) {
                            viewState.selectedLibrary = library
                            viewState.showLibrary()
                        }
                        .contextMenu {
                            libraryContextMenu(for: library)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.top, DesignTokens.Spacing.md)
            }
            
            Spacer()
            
            // 底部設定區域
            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal, DesignTokens.Spacing.md)
                
                // 主題色設定按鈕
                Button(action: { showThemeSettings = true }) {
                    HStack(spacing: 8) {
                        // 主題色預覽圓點
                        if theme.isPrideMode {
                            Circle()
                                .fill(theme.prideGradient)
                                .frame(width: 14, height: 14)
                        } else {
                            Circle()
                                .fill(theme.accent)
                                .frame(width: 14, height: 14)
                        }
                        
                        Text("主題色設定")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, DesignTokens.Spacing.sm)
        }
        .frame(minWidth: 220, maxWidth: 220)
        .background(
            ZStack {
                // 提升層背景 (Elevated Layer)
                theme.elevated
                // 頂層玻璃效果
                theme.cardGlass
            }
        )
        .sheet(isPresented: $showThemeSettings) {
            ThemeSettingsView()
                .environmentObject(theme)
        }
        .sheet(isPresented: $showNewLibrarySheet) {
            NewLibrarySheet(libraryVM: libraryVM)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showRenameSheet) {
            if let library = libraryToRename {
                RenameLibrarySheet(library: library, libraryVM: libraryVM)
                    .environmentObject(theme)
            }
        }
        .alert("確定刪除文獻庫？", isPresented: $showDeleteConfirm, presenting: libraryToDelete) { library in
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteLibrary(library)
            }
        } message: { library in
            Text("文獻庫「\(library.name)」及其中的 \(library.entryCount) 篇文獻將被永久刪除。")
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func libraryContextMenu(for library: Library) -> some View {
        Button(action: {
            libraryToRename = library
            showRenameSheet = true
        }) {
            Label("重新命名", systemImage: "pencil")
        }
        
        Button(action: {
            copyLibrary(library)
        }) {
            Label("複製文獻庫", systemImage: "doc.on.doc")
        }
        
        Menu {
            Button(action: {
                exportLibraryBibTeX(library)
            }) {
                Label("匯出 BibTeX", systemImage: "doc.text")
            }
            
            Button(action: {
                exportLibraryRIS(library)
            }) {
                Label("匯出 RIS", systemImage: "doc.badge.gearshape")
            }
        } label: {
            Label("匯出", systemImage: "square.and.arrow.up")
        }
        
        if !library.isDefault {
            Divider()
            
            Button(role: .destructive, action: {
                libraryToDelete = library
                showDeleteConfirm = true
            }) {
                Label("刪除", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Library Actions
    
    private func copyLibrary(_ library: Library) {
        Task {
            await libraryVM.duplicateLibrary(library)
            ToastManager.shared.showSuccess("已複製文獻庫「\(library.name)」")
        }
    }
    
    private func exportLibraryBibTeX(_ library: Library) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "bib")!]
        savePanel.nameFieldStringValue = "\(library.name).bib"
        savePanel.title = "匯出文獻庫為 BibTeX"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let context = libraryVM.context
                    let entries = Entry.fetchAll(in: library, context: context)
                    let result = try BatchOperationService.batchExportBibTeX(entries: entries, to: url)
                    ToastManager.shared.showSuccess(result.message)
                } catch {
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func exportLibraryRIS(_ library: Library) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "ris")!]
        savePanel.nameFieldStringValue = "\(library.name).ris"
        savePanel.title = "匯出文獻庫為 RIS"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let context = libraryVM.context
                    let entries = Entry.fetchAll(in: library, context: context)
                    let result = try BatchOperationService.batchExportRIS(entries: entries, to: url)
                    ToastManager.shared.showSuccess(result.message)
                } catch {
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteLibrary(_ library: Library) {
        Task {
            await libraryVM.deleteLibrary(library)
            ToastManager.shared.showSuccess("已刪除文獻庫「\(library.name)」")
        }
    }
    
    // MARK: - 子視圖
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
            .foregroundColor(theme.textTertiary)
            .textCase(.uppercase)
            .tracking(1.5)  // 增加字距 (academic style)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xxs)
    }
    
    private func sectionHeaderWithButton(_ title: String, onAdd: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
                .foregroundColor(theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.5)  // 增加字距 (academic style)
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xxs)
    }
}

/// 側邊欄按鈕
struct SidebarButton: View {
    @EnvironmentObject var theme: AppTheme

    let icon: String
    let title: String
    let isSelected: Bool
    var badge: Int? = nil
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                // 選中高亮條
                if isSelected {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.accent)
                        .frame(width: 3)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Color.clear
                        .frame(width: 3)
                }

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.IconSize.small))
                        .frame(width: 18)

                    Text(title)
                        .font(.system(size: DesignTokens.Typography.body))
                        .lineLimit(1)

                    Spacer()

                    if let badge = badge {
                        Text("\(badge)")
                            .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignTokens.Spacing.xs - 2)
                            .padding(.vertical, DesignTokens.Spacing.xxs / 2)
                            .background(Capsule().fill(Color.gray.opacity(0.5)))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    ZStack {
                        // 液態玻璃效果背景
                        if isSelected {
                            // 選中：藍色液態玻璃
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.accent.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                                )
                        } else if isHovered {
                            // 懸停：淡色玻璃
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.itemHover)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                        } else {
                            Color.clear
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.85))
                // 懸停時添加陰影
                .shadow(
                    color: isSelected ? theme.accent.opacity(0.4) : (isHovered ? Color.black.opacity(0.1) : .clear),
                    radius: isSelected ? 10 : (isHovered ? 8 : 0),
                    x: 0,
                    y: isSelected ? 4 : (isHovered ? 4 : 0)
                )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        .animation(AnimationSystem.Easing.spring, value: isSelected)
        .animation(AnimationSystem.Easing.quick, value: isHovered)
        .onHover { hovering in
            withAnimation(AnimationSystem.Easing.quick) {
                isHovered = hovering
            }
        }
    }

    // MARK: - 計算屬性

    /// 背景顏色（不再使用，保留相容性）
    private var backgroundColor: Color {
        if isSelected {
            return theme.accent
        } else if isHovered {
            return theme.itemHover
        } else {
            return Color.clear
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    let context = PersistenceController.preview.container.viewContext
    let repository = LibraryRepository(context: context)
    let libraryVM = LibraryViewModel(repository: repository)

    MainSidebarView(libraryVM: libraryVM)
        .environmentObject(theme)
        .environmentObject(viewState)
        .frame(height: 500)
}

// MARK: - New Library Sheet

/// 新增文獻庫 Sheet
struct NewLibrarySheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var libraryVM: LibraryViewModel
    @State private var libraryName = ""
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("新增文獻庫")
                .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            TextField("文獻庫名稱", text: $libraryName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .onSubmit {
                    createLibrary()
                }
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                SecondaryButton("取消") {
                    dismiss()
                }
                .environmentObject(theme)
                .keyboardShortcut(.escape)
                
                PrimaryButton("創建", size: .medium) {
                    createLibrary()
                }
                .environmentObject(theme)
                .disabled(libraryName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
    }
    
    private func createLibrary() {
        let trimmed = libraryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task {
            await libraryVM.createLibrary(name: trimmed)
            dismiss()
        }
    }
}

// MARK: - Rename Library Sheet

/// 重新命名文獻庫 Sheet
struct RenameLibrarySheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var libraryVM: LibraryViewModel
    let library: Library
    
    @State private var newName: String
    
    init(library: Library, libraryVM: LibraryViewModel) {
        self.library = library
        self.libraryVM = libraryVM
        _newName = State(initialValue: library.name)
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("重新命名文獻庫")
                .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            TextField("文獻庫名稱", text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .onSubmit {
                    renameLibrary()
                }
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                SecondaryButton("取消") {
                    dismiss()
                }
                .environmentObject(theme)
                .keyboardShortcut(.escape)
                
                PrimaryButton("確定", size: .medium) {
                    renameLibrary()
                }
                .environmentObject(theme)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || newName == library.name)
                .keyboardShortcut(.return)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
    }
    
    private func renameLibrary() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != library.name else { return }
        
        Task {
            await libraryVM.renameLibrary(library, to: trimmed)
            ToastManager.shared.showSuccess("已重新命名為「\(trimmed)」")
            dismiss()
        }
    }
}
