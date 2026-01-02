//
//  NewSidebarView.swift
//  OVEREND
//
//  新版側邊欄 - 現代化 macOS 風格
//

import SwiftUI

/// 新版側邊欄
struct NewSidebarView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @ObservedObject var libraryVM: LibraryViewModel
    
    @State private var showNewLibrarySheet = false
    
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
                    .fill(theme.glassBorder.opacity(0.5))
                    .frame(height: 0.5)
            }
            
            // 側邊欄內容
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    // 資源管理區塊
                    sectionHeader("資源管理")

                    SidebarButton(
                        icon: "books.vertical",
                        title: "全部文獻",
                        isSelected: viewState.activeSidebarItem == .allEntries
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
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.top, DesignTokens.Spacing.md)
            }
            
            Spacer()
        }
        .frame(minWidth: 220, maxWidth: 220)
        .background(.regularMaterial)
        .sheet(isPresented: $showNewLibrarySheet) {
            NewLibrarySheet(libraryVM: libraryVM)
                .environmentObject(theme)
        }
    }
    
    // MARK: - 子視圖
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
            .foregroundColor(theme.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xxs)
    }
    
    private func sectionHeaderWithButton(_ title: String, onAdd: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
                .foregroundColor(theme.textMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            
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
                .foregroundColor(isSelected ? .white : theme.textPrimary)
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
    let libraryVM = LibraryViewModel(context: context)
    
    return NewSidebarView(libraryVM: libraryVM)
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
        libraryVM.createLibrary(name: trimmed)
        dismiss()
    }
}
