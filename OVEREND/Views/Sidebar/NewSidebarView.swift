//
//  NewSidebarView.swift
//  OVEREND
//
//  現代化側邊欄 - 採用 macOS 新式設計風格
//

import SwiftUI

/// 側邊欄導航項目
enum SidebarItemType: String, CaseIterable, Identifiable {
    case allEntries = "全部文獻"
    case recent = "最近閱讀"
    case favorites = "我的最愛"
    case pdf = "PDF 文獻"
    case toRead = "待閱讀"
    case trash = "垃圾桶"
    
    case drafts = "寫作草稿"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .allEntries: return "books.vertical.fill"
        case .recent: return "clock.fill"
        case .pdf: return "doc.text.fill"
        case .toRead: return "eyeglasses"
        case .favorites: return "star.fill"
        case .trash: return "trash.fill"
        case .drafts: return "pencil.and.outline"
        }
    }
}

/// 現代化側邊欄視圖
struct NewSidebarView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    
    // 選擇狀態
    @Binding var selection: SidebarItemType?
    
    // 智慧分類展開狀態
    @State private var isSmartGroupExpanded = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacingMD) {
                // MARK: - 標題區域
                HStack {
                    Text("文獻庫")
                        .font(theme.fontSidebarItem)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.top, theme.spacingMD)
                
                // MARK: - 主要導航
                VStack(spacing: 2) {
                    SidebarRow(
                        title: SidebarItemType.allEntries.rawValue,
                        icon: SidebarItemType.allEntries.icon,
                        isSelected: selection == .allEntries,
                        action: { selection = .allEntries }
                    )
                    
                    SidebarRow(
                        title: SidebarItemType.drafts.rawValue,
                        icon: SidebarItemType.drafts.icon,
                        isSelected: selection == .drafts,
                        action: { selection = .drafts }
                    )
                    
                    SidebarRow(
                        title: SidebarItemType.recent.rawValue,
                        icon: SidebarItemType.recent.icon,
                        isSelected: selection == .recent,
                        action: { selection = .recent }
                    )
                    
                    SidebarRow(
                        title: SidebarItemType.favorites.rawValue,
                        icon: SidebarItemType.favorites.icon,
                        isSelected: selection == .favorites,
                        action: { selection = .favorites }
                    )
                    
                    SidebarRow(
                        title: SidebarItemType.trash.rawValue,
                        icon: SidebarItemType.trash.icon,
                        isSelected: selection == .trash,
                        action: { selection = .trash }
                    )
                }
                
                Divider()
                    .background(theme.divider)
                    .padding(.horizontal, theme.spacingMD)
                
                // MARK: - 智慧分類
                VStack(spacing: 2) {
                    Button(action: { withAnimation { isSmartGroupExpanded.toggle() } }) {
                        HStack {
                            Text("智慧分類")
                                .font(theme.fontSidebarItem)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(theme.textTertiary)
                                .rotationEffect(.degrees(isSmartGroupExpanded ? 90 : 0))
                        }
                        .padding(.horizontal, theme.spacingMD)
                        .padding(.vertical, theme.spacingXS)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if isSmartGroupExpanded {
                        SidebarRow(
                            title: SidebarItemType.pdf.rawValue,
                            icon: SidebarItemType.pdf.icon,
                            isSelected: selection == .pdf,
                            action: { selection = .pdf }
                        )
                        SidebarRow(
                            title: SidebarItemType.toRead.rawValue,
                            icon: SidebarItemType.toRead.icon,
                            isSelected: selection == .toRead,
                            action: { selection = .toRead }
                        )
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.sidebarGlass) // 使用玻璃效果背景
    }
}

/// 側邊欄列元件
struct SidebarRow: View {
    @EnvironmentObject var theme: AppTheme
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacingMD) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20, alignment: .center)
                    .foregroundColor(isSelected ? .white : (isHovering ? theme.textPrimary : theme.textSecondary))
                
                Text(title)
                    .font(theme.fontSidebarItem)
                    .foregroundColor(isSelected ? .white : (isHovering ? theme.textPrimary : theme.textSecondary))
                
                Spacer()
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSM)
                    .fill(isSelected ? theme.accent : (isHovering ? theme.itemHover : Color.clear))
            )
            .padding(.horizontal, theme.spacingSM)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    NewSidebarView(selection: .constant(.allEntries))
        .environmentObject(AppTheme())
        .environmentObject(MainViewState())
        .frame(width: 250, height: 600)
}
