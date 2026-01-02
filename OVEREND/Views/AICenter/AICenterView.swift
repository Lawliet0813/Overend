//
//  AICenterView.swift
//  OVEREND
//
//  AI 智慧中心主視圖
//

import SwiftUI
import CoreData

/// AI 智慧中心主視圖
struct AICenterView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    
    // 功能狀態
    @State private var selectedFeature: AIFeature?
    
    var body: some View {
        ZStack {
            // 背景
            theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 標題區域
                headerView
                
                Divider()
                
                // 主內容
                if let feature = selectedFeature {
                    // 顯示選中的功能視圖
                    featureDetailView(for: feature)
                } else {
                    // 顯示功能卡片網格
                    featureGridView
                }
            }
        }
    }
    
    // MARK: - 子視圖
    
    /// 標題區域
    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 返回按鈕（如果有選中的功能）
            if selectedFeature != nil {
                Button(action: { 
                    withAnimation(AnimationSystem.Easing.spring) {
                        selectedFeature = nil
                    }
                }) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: DesignTokens.IconSize.small))
                        Text("返回")
                            .font(.system(size: DesignTokens.Typography.body))
                    }
                    .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            // AI 圖標
            Image(systemName: "apple.intelligence")
                .font(.system(size: DesignTokens.IconSize.large))
                .foregroundColor(theme.accent)
            
            // 標題
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedFeature?.title ?? "AI 智慧中心")
                    .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(selectedFeature?.description ?? "利用 AI 提升您的學術寫作與研究效率")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(theme.toolbar)
    }
    
    /// 功能卡片網格
    private var featureGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignTokens.Spacing.lg),
                    GridItem(.flexible(), spacing: DesignTokens.Spacing.lg)
                ],
                spacing: DesignTokens.Spacing.lg
            ) {
                ForEach(AIFeature.allCases) { feature in
                    AIFeatureCard(feature: feature) {
                        withAnimation(AnimationSystem.Easing.spring) {
                            selectedFeature = feature
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.xl)
        }
    }
    
    /// 功能詳情視圖
    @ViewBuilder
    private func featureDetailView(for feature: AIFeature) -> some View {
        switch feature {
        case .recommendations:
            CitationRecommendationView()
                .environmentObject(theme)
                .environmentObject(viewState)
            
        case .citationCheck:
            Text("引用檢查功能（開發中）")
                .foregroundColor(theme.textMuted)
            
        case .structureAnalysis:
            Text("結構分析功能（開發中）")
                .foregroundColor(theme.textMuted)
            
        case .literatureQA:
            Text("文獻問答功能（即將推出）")
                .foregroundColor(theme.textMuted)
        }
    }
}

// MARK: - AI 功能枚舉

/// AI 功能類型
enum AIFeature: String, CaseIterable, Identifiable {
    case recommendations = "智慧推薦"
    case citationCheck = "引用檢查"
    case structureAnalysis = "結構分析"
    case literatureQA = "文獻問答"
    
    var id: String { rawValue }
    
    var title: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .recommendations:
            return "sparkles"
        case .citationCheck:
            return "checkmark.seal"
        case .structureAnalysis:
            return "chart.bar.doc.horizontal"
        case .literatureQA:
            return "message.badge.filled.fill"
        }
    }
    
    var description: String {
        switch self {
        case .recommendations:
            return "根據您的寫作內容，智慧推薦相關文獻"
        case .citationCheck:
            return "檢查引用品質與相關性，提供改進建議"
        case .structureAnalysis:
            return "分析論文結構，提供章節優化建議"
        case .literatureQA:
            return "與文獻對話，快速提取關鍵資訊"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .recommendations:
            return true  // P0 功能
        case .citationCheck, .structureAnalysis:
            return false // 開發中
        case .literatureQA:
            return false // 即將推出
        }
    }
    
    var statusBadge: String {
        switch self {
        case .recommendations:
            return "可用"
        case .citationCheck, .structureAnalysis:
            return "開發中"
        case .literatureQA:
            return "即將推出"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .recommendations:
            return .green
        case .citationCheck, .structureAnalysis:
            return .orange
        case .literatureQA:
            return .gray
        }
    }
}

// MARK: - AI 功能卡片

/// AI 功能卡片
struct AIFeatureCard: View {
    @EnvironmentObject var theme: AppTheme
    
    let feature: AIFeature
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if feature.isAvailable {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // 圖標與狀態標籤
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(feature.isAvailable ? theme.accentLight : theme.itemHover)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: feature.icon)
                            .font(.system(size: DesignTokens.IconSize.large))
                            .foregroundColor(feature.isAvailable ? theme.accent : theme.textMuted)
                    }
                    
                    Spacer()
                    
                    // 狀態標籤
                    Text(feature.statusBadge)
                        .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(feature.badgeColor)
                        )
                }
                
                // 標題
                Text(feature.title)
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 描述
                Text(feature.description)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // 操作指示
                if feature.isAvailable {
                    HStack {
                        Text("點擊使用")
                            .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                            .foregroundColor(theme.accent)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: DesignTokens.Typography.caption))
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                    .fill(theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                            .stroke(
                                isHovered && feature.isAvailable ? theme.accent : theme.border,
                                lineWidth: isHovered && feature.isAvailable ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isHovered && feature.isAvailable ? theme.accent.opacity(0.2) : .clear,
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!feature.isAvailable)
        .onHover { hovering in
            withAnimation(AnimationSystem.Easing.quick) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    
    return AICenterView()
        .environmentObject(theme)
        .environmentObject(viewState)
        .frame(width: 1000, height: 700)
}
