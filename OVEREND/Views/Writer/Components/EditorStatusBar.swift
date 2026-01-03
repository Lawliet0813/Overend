//
//  EditorStatusBar.swift
//  OVEREND
//
//  編輯器底部狀態列
//

import SwiftUI

/// 編輯器狀態列
struct EditorStatusBar: View {
    @EnvironmentObject var theme: AppTheme

    let documentTitle: String
    let editorMode: String
    let isSaving: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 文稿名稱
            Text(documentTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textPrimary)

            Spacer()

            // 編輯模式指示
            Text(editorMode)
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)

            // 自動儲存狀態
            HStack(spacing: 4) {
                Circle()
                    .fill(isSaving ? .orange : .green)
                    .frame(width: 6, height: 6)
                Text("自動儲存")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(theme.toolbar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
}
