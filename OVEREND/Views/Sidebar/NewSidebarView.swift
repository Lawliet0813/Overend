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
    
    var body: some View {
        VStack(spacing: 0) {
            // 側邊欄內容
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
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
                    
                    // 智能過濾區塊
                    sectionHeader("智能過濾")
                        .padding(.top, 16)
                    
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
                    sectionHeader("文獻庫")
                        .padding(.top, 16)
                    
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
                .padding(.horizontal, 8)
                .padding(.top, 16)
            }
            
            Spacer()
        }
        .frame(minWidth: 220, maxWidth: 220)
        .background(theme.sidebar)
    }
    
    // MARK: - 子視圖
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(theme.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 15))
                    .lineLimit(1)
                
                Spacer()
                
                if let badge = badge {
                    Text("\(badge)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.gray.opacity(0.5)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? theme.accent : (isHovered ? theme.itemHover : Color.clear))
            )
            .foregroundColor(isSelected ? .white : theme.textPrimary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
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
