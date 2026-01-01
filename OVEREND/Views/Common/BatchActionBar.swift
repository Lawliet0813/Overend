//
//  BatchActionBar.swift
//  OVEREND
//
//  批次操作列 - 多選後顯示的操作工具列
//

import SwiftUI

/// 批次操作列
struct BatchActionBar: View {
    @EnvironmentObject var theme: AppTheme
    
    let selectedCount: Int
    let onDelete: () -> Void
    let onExport: () -> Void
    let onClearSelection: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 選取計數
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.accent)
                Text("已選取 \(selectedCount) 筆")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textPrimary)
            }
            
            Divider()
                .frame(height: 20)
            
            // 操作按鈕
            HStack(spacing: 12) {
                // 刪除按鈕
                BatchActionButton(
                    icon: "trash",
                    label: "刪除",
                    color: .red,
                    action: onDelete
                )
                .environmentObject(theme)
                
                // 匯出按鈕
                BatchActionButton(
                    icon: "square.and.arrow.up",
                    label: "匯出",
                    color: theme.accent,
                    action: onExport
                )
                .environmentObject(theme)
            }
            
            Spacer()
            
            // 取消選取
            Button(action: onClearSelection) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                    Text("取消選取")
                        .font(.system(size: 12))
                }
                .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.tableRowHover)
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.card)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.accent.opacity(0.3))
                .frame(height: 2)
        }
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

/// 批次操作按鈕
struct BatchActionButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isHovered ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    BatchActionBar(
        selectedCount: 5,
        onDelete: {},
        onExport: {},
        onClearSelection: {}
    )
    .environmentObject(AppTheme())
    .frame(width: 600)
    .padding()
}
