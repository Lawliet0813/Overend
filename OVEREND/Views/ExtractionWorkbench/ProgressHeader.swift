//
//  ProgressHeader.swift
//  OVEREND
//
//  批次處理進度指示器
//

import SwiftUI

/// 批次處理進度頭部
struct ProgressHeader: View {
    let current: Int
    let total: Int
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            // 進度文字
            HStack(spacing: 8) {
                Text("處理進度")
                    .font(.system(size: DesignTokens.Typography.subheadline))
                    .foregroundColor(theme.textMuted)
                
                Text("\(current + 1) / \(total)")
                    .font(.system(size: DesignTokens.Typography.headline, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }
            
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.border)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accent)
                        .frame(width: geometry.size.width * progressRatio)
                        .animation(AnimationSystem.Easing.spring, value: progressRatio)
                }
            }
            .frame(height: 8)
            .frame(maxWidth: 200)
            
            // 百分比
            Text("\(Int(progressRatio * 100))%")
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(theme.accent)
                .frame(width: 44, alignment: .trailing)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.card)
    }
    
    private var progressRatio: Double {
        guard total > 0 else { return 0 }
        return Double(current + 1) / Double(total)
    }
}

/// 簡化版進度指示器
struct CompactProgressIndicator: View {
    let current: Int
    let total: Int
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 8) {
            // 圓點進度
            HStack(spacing: 4) {
                ForEach(0..<min(total, 10), id: \.self) { index in
                    Circle()
                        .fill(index <= current ? theme.accent : theme.border)
                        .frame(width: 8, height: 8)
                }
                
                if total > 10 {
                    Text("...")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMuted)
                }
            }
            
            Text("\(current + 1)/\(total)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressHeader(current: 2, total: 5)
        ProgressHeader(current: 0, total: 1)
        ProgressHeader(current: 9, total: 10)
        
        Divider()
        
        CompactProgressIndicator(current: 3, total: 8)
        CompactProgressIndicator(current: 0, total: 15)
    }
    .environmentObject(AppTheme())
}
