//
//  WritingStatsView.swift
//  OVEREND
//
//  字數統計儀表板 - 即時顯示寫作統計資訊
//

import SwiftUI

/// 寫作統計視圖
struct WritingStatsView: View {
    @EnvironmentObject var theme: AppTheme
    
    // MARK: - 統計數據
    let wordCount: Int
    let characterCount: Int
    let paragraphCount: Int
    let citationCount: Int
    let estimatedPages: Int
    
    // MARK: - 狀態
    @State private var showDetails = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            withAnimation(AnimationSystem.Panel.slideIn) {
                showDetails.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // 主要統計
                statItem(
                    icon: "textformat.abc",
                    value: "\(formattedCount(wordCount))",
                    label: "字"
                )
                
                if showDetails {
                    Divider()
                        .frame(height: 14)
                    
                    statItem(
                        icon: "character",
                        value: "\(formattedCount(characterCount))",
                        label: "字元"
                    )
                    
                    Divider()
                        .frame(height: 14)
                    
                    statItem(
                        icon: "paragraph",
                        value: "\(paragraphCount)",
                        label: "段"
                    )
                    
                    Divider()
                        .frame(height: 14)
                    
                    statItem(
                        icon: "quote.bubble",
                        value: "\(citationCount)",
                        label: "引用"
                    )
                    
                    Divider()
                        .frame(height: 14)
                    
                    statItem(
                        icon: "doc.plaintext",
                        value: "~\(estimatedPages)",
                        label: "頁"
                    )
                }
                
                // 展開指示器
                Image(systemName: showDetails ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(isHovered ? theme.itemHover : Color.clear)
            )
            .scaleEffect(isHovered ? AnimationSystem.Button.hoverScale : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AnimationSystem.Button.hover) {
                isHovered = hovering
            }
        }
        .help("點擊顯示詳細統計")
        .popover(isPresented: $showDetails, arrowEdge: .top) {
            detailedStatsPopover
        }
    }
    
    // MARK: - 子視圖
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
            
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(theme.textPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
        }
    }
    
    private var detailedStatsPopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.accent)
                
                Text("寫作統計")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            
            Divider()
            
            // 統計網格
            VStack(spacing: 12) {
                statsRow(icon: "textformat.abc", title: "字數", value: "\(formattedCount(wordCount))")
                statsRow(icon: "character", title: "字元數", value: "\(formattedCount(characterCount))")
                statsRow(icon: "character.textbox", title: "字元（不含空格）", value: "\(formattedCount(characterCount - wordCount))")
                
                Divider()
                
                statsRow(icon: "paragraph", title: "段落數", value: "\(paragraphCount)")
                statsRow(icon: "quote.bubble", title: "引用數", value: "\(citationCount)")
                
                Divider()
                
                statsRow(icon: "doc.plaintext", title: "預估頁數", value: "約 \(estimatedPages) 頁")
                statsRow(icon: "clock", title: "預估閱讀時間", value: "\(max(1, wordCount / 200)) 分鐘")
            }
            
            // 進度提示
            if wordCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: progressIcon)
                        .font(.system(size: 14))
                        .foregroundColor(progressColor)
                    
                    Text(progressMessage)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(theme.card)
    }
    
    private func statsRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.textMuted)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(theme.textPrimary)
        }
    }
    
    // MARK: - 輔助方法
    
    private func formattedCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
    }
    
    private var progressIcon: String {
        switch wordCount {
        case 0..<500: return "leaf"
        case 500..<2000: return "flame"
        case 2000..<5000: return "star"
        default: return "trophy"
        }
    }
    
    private var progressColor: Color {
        switch wordCount {
        case 0..<500: return .green
        case 500..<2000: return .orange
        case 2000..<5000: return .blue
        default: return .yellow
        }
    }
    
    private var progressMessage: String {
        switch wordCount {
        case 0..<500: return "剛開始寫作，繼續加油！"
        case 500..<2000: return "進展順利，保持專注！"
        case 2000..<5000: return "寫作進度良好！"
        default: return "太棒了！已完成大量寫作！"
        }
    }
}

// MARK: - 預覽

#Preview {
    WritingStatsView(
        wordCount: 2345,
        characterCount: 5678,
        paragraphCount: 24,
        citationCount: 12,
        estimatedPages: 8
    )
    .environmentObject(AppTheme())
    .padding()
    .background(Color.gray.opacity(0.1))
}
