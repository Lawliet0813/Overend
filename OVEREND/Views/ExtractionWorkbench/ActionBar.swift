//
//  ActionBar.swift
//  OVEREND
//
//  工作台底部操作列
//

import SwiftUI

/// 工作台底部操作按鈕列
struct ActionBar: View {
    let hasPrevious: Bool
    let hasNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onConfirm: () -> Void
    let onSkip: () -> Void
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側：導航按鈕
            HStack(spacing: 8) {
                Button(action: onPrevious) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("上一個")
                    }
                    .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(hasPrevious ? theme.textSecondary : theme.textMuted.opacity(0.5))
                .disabled(!hasPrevious)
                
                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text("下一個")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(hasNext ? theme.textSecondary : theme.textMuted.opacity(0.5))
                .disabled(!hasNext)
            }
            
            Spacer()
            
            // 右側：主要操作按鈕
            HStack(spacing: 12) {
                // 跳過按鈕
                Button(action: onSkip) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward")
                        Text("跳過")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                            .fill(theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                // 確認建立按鈕
                Button(action: onConfirm) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("確認建立")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(theme.card)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
        )
    }
}

/// 簡化版操作列（用於單一 PDF）
struct SimpleActionBar: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            
            SecondaryButton("取消") {
                onCancel()
            }
            .keyboardShortcut(.escape)
            
            PrimaryButton("確認建立", icon: "checkmark.circle.fill") {
                onConfirm()
            }
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(theme.card)
    }
}

#Preview {
    VStack(spacing: 0) {
        Spacer()
        
        ActionBar(
            hasPrevious: true,
            hasNext: true,
            onPrevious: { print("Previous") },
            onNext: { print("Next") },
            onConfirm: { print("Confirm") },
            onSkip: { print("Skip") }
        )
        
        Divider()
        
        SimpleActionBar(
            onConfirm: { print("Confirm") },
            onCancel: { print("Cancel") }
        )
    }
    .environmentObject(AppTheme())
}
