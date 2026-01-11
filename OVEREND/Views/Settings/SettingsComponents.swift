//
//  SettingsComponents.swift
//  OVEREND
//
//  共用設定頁面元件
//

import SwiftUI

// MARK: - 區塊標題組件

struct SectionHeader: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.accent)
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
