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

    // Core Data 環境
    @Environment(\.managedObjectContext) private var viewContext

    // 選擇狀態
    @Binding var selection: SidebarItemType?

    // 智慧分類展開狀態
    @State private var isSmartGroupExpanded = true

    // MARK: - 數量查詢

    /// 全部文獻數量
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)],
        animation: .default
    )
    private var allEntries: FetchedResults<Entry>

    /// 最近閱讀數量（最近 7 天更新的）
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.updatedAt, ascending: false)],
        predicate: NSPredicate(format: "updatedAt >= %@", Calendar.current.date(byAdding: .day, value: -7, to: Date())! as CVarArg),
        animation: .default
    )
    private var recentEntries: FetchedResults<Entry>

    /// 草稿數量
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var drafts: FetchedResults<Document>

    // MARK: - 數量計算

    private func getCount(for itemType: SidebarItemType) -> Int? {
        switch itemType {
        case .allEntries:
            return allEntries.count
        case .recent:
            return recentEntries.count
        case .drafts:
            return drafts.count
        // 暫時返回 nil，等待功能實現
        case .favorites, .pdf, .toRead, .trash:
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacingMD) {
                // MARK: - 標題區域
                HStack {
                    Text("文獻庫")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, theme.spacingLG)
                .padding(.top, theme.spacingLG)
                .padding(.bottom, theme.spacingSM)
                
                // MARK: - 主要導航
                VStack(spacing: 4) {
                    SidebarRow(
                        title: SidebarItemType.allEntries.rawValue,
                        icon: SidebarItemType.allEntries.icon,
                        isSelected: selection == .allEntries,
                        action: { selection = .allEntries },
                        count: getCount(for: .allEntries)
                    )

                    SidebarRow(
                        title: SidebarItemType.drafts.rawValue,
                        icon: SidebarItemType.drafts.icon,
                        isSelected: selection == .drafts,
                        action: { selection = .drafts },
                        count: getCount(for: .drafts)
                    )

                    SidebarRow(
                        title: SidebarItemType.recent.rawValue,
                        icon: SidebarItemType.recent.icon,
                        isSelected: selection == .recent,
                        action: { selection = .recent },
                        count: getCount(for: .recent)
                    )

                    SidebarRow(
                        title: SidebarItemType.favorites.rawValue,
                        icon: SidebarItemType.favorites.icon,
                        isSelected: selection == .favorites,
                        action: { selection = .favorites },
                        count: getCount(for: .favorites)
                    )

                    SidebarRow(
                        title: SidebarItemType.trash.rawValue,
                        icon: SidebarItemType.trash.icon,
                        isSelected: selection == .trash,
                        action: { selection = .trash },
                        count: getCount(for: .trash)
                    )
                }
                
                Divider()
                    .background(theme.divider)
                    .padding(.horizontal, theme.spacingMD)
                
                // MARK: - 智慧分類
                VStack(spacing: 4) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isSmartGroupExpanded.toggle() } }) {
                        HStack {
                            Text("智慧分類")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.textTertiary)
                                .textCase(.uppercase)
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
                            action: { selection = .pdf },
                            count: getCount(for: .pdf),
                            isSubItem: true
                        )
                        SidebarRow(
                            title: SidebarItemType.toRead.rawValue,
                            icon: SidebarItemType.toRead.icon,
                            isSelected: selection == .toRead,
                            action: { selection = .toRead },
                            count: getCount(for: .toRead),
                            isSubItem: true
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
    let count: Int? // 新增：數量徽章
    let isSubItem: Bool // 新增：是否為子項目（縮排用）

    @State private var isHovering = false

    init(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        count: Int? = nil,
        isSubItem: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
        self.count = count
        self.isSubItem = isSubItem
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacingMD) {
                Image(systemName: icon)
                    .font(.system(size: isSubItem ? 13 : 15)) // 子項目圖標較小
                    .frame(width: 20, alignment: .center)
                    .foregroundColor(isSelected ? .white : (isHovering ? theme.textPrimary : theme.textSecondary))

                Text(title)
                    .font(isSubItem ? .system(size: 13) : theme.fontSidebarItem) // 子項目字體較小
                    .foregroundColor(isSelected ? .white : (isHovering ? theme.textPrimary : theme.textSecondary))

                Spacer()

                // 數量徽章
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : theme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : theme.elevated)
                        )
                }
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.leading, isSubItem ? theme.spacingLG : 0) // 子項目增加左側縮排
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
        .contextMenu {
            // 右鍵快速操作菜單
            contextMenuContent
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button(action: {}) {
            Label("在新視窗開啟", systemImage: "plus.rectangle.on.rectangle")
        }

        Divider()

        Button(action: {}) {
            Label("重新整理", systemImage: "arrow.clockwise")
        }

        Button(action: {}) {
            Label("清空此分類", systemImage: "trash")
        }
        .disabled(count == nil || count == 0)
    }
}

#Preview {
    NewSidebarView(selection: .constant(.allEntries))
        .environmentObject(AppTheme())
        .environmentObject(MainViewState())
        .frame(width: 250, height: 600)
}
