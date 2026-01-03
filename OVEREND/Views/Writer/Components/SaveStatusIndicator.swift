//
//  SaveStatusIndicator.swift
//  OVEREND
//
//  文檔儲存狀態指示器
//

import SwiftUI

/// 儲存狀態指示器
struct SaveStatusIndicator: View {
    @EnvironmentObject var theme: AppTheme

    let isSaving: Bool
    let lastSaved: Date?

    var body: some View {
        HStack(spacing: 6) {
            if isSaving {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)

                Text("儲存中...")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            } else if let lastSaved = lastSaved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)

                Text("已儲存 \(formatTime(lastSaved))")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)

                Text("未儲存")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.toolbar)
        )
    }

    /// 格式化時間（相對時間）
    private func formatTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "剛剛"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) 分鐘前"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours) 小時前"
        }
    }
}
