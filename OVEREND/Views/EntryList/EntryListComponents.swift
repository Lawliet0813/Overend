//
//  EntryListComponents.swift
//  OVEREND
//
//  文獻列表元件 - 從 ModernEntryListView 拆分
//

import SwiftUI
import AppKit

// MARK: - 文獻表格列

struct EntryTableRow: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var entry: Entry
    let isSelected: Bool
    var isSelectionMode: Bool = false
    var isChecked: Bool = false
    let onTap: () -> Void
    var onToggleSelection: (() -> Void)? = nil
    let onDelete: () -> Void
    var onRestore: (() -> Void)? = nil
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
                            .font(theme.fontBodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        // 期刊/來源
                        if let journal = entry.fields["journal"], !journal.isEmpty {
                            Text(journal)
                                .font(theme.fontBodySmall)
                                .foregroundColor(theme.textSecondary)
                                .italic()
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, theme.spacingMD)

                    // Tags
                    if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(Array(tags).sorted(by: { $0.name < $1.name }).prefix(3)) { tag in
                                Text(tag.name)
                                    .font(theme.fontLabel)
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

                    // 作者 / 年份
                    Text(authorYearText)
                        .font(theme.fontBodyMedium)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                        .frame(width: 180, alignment: .leading)

                    // 附件數量
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

                    // 類型標籤
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

                    // 刪除按鈕
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
                        .frame(width: 44)
                        .opacity(isHovered ? 1 : 0)
                    } else {
                        Color.clear.frame(width: 44)
                    }
                }
                .padding(.horizontal, theme.spacingLG)
                .padding(.vertical, theme.spacingMD)
            }
            .background(backgroundColor)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered && !isSelected ? 1.01 : 1.0)
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
        .contextMenu {
            if let onRestore = onRestore {
                Button("復原") { onRestore() }
                Divider()
            }
            Button("編輯") { ToastManager.shared.showInfo("編輯功能開發中") }
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Text("刪除")
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
            Text("此操作將刪除「\(entryTitle)」及其所有附件，無法還原。")
        }
    }

    // MARK: - 計算屬性
    
    /// 安全的標題（預先提取，避免刪除時物件失效）
    private var entryTitle: String {
        entry.fields["title"] ?? "無標題"
    }

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

// MARK: - 進度條

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

// MARK: - 影響力標籤

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
