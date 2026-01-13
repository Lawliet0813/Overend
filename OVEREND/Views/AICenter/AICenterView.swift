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
    @Environment(\.managedObjectContext) private var viewContext
    
    // 功能狀態
    @State private var selectedFeature: AIFeature?
    
    // 目標文獻庫（用於 Zotero 匯入）
    var targetLibrary: Library?
    
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
    
    @ViewBuilder
    private func featureDetailView(for feature: AIFeature) -> some View {
        switch feature {
        case .academicTranslation:
            if #available(macOS 26.0, *) {
                AcademicTranslationView()
                    .environmentObject(theme)
            } else {
                Text("此功能需要 macOS 26.0 或更新版本")
                    .foregroundColor(theme.textMuted)
            }
            
        case .standardsCheck:
            if #available(macOS 26.0, *) {
                AcademicStandardsCheckView()
                    .environmentObject(theme)
            } else {
                Text("此功能需要 macOS 26.0 或更新版本")
                    .foregroundColor(theme.textMuted)
            }
            
        case .phrasebank:
            if #available(macOS 26.0, *) {
                AcademicPhrasebankView()
                    .environmentObject(theme)
            } else {
                Text("此功能需要 macOS 26.0 或更新版本")
                    .foregroundColor(theme.textMuted)
            }
            
        case .terminologyCheck:
            if #available(macOS 26.0, *) {
                TerminologyCheckView()
                    .environmentObject(theme)
            } else {
                Text("此功能需要 macOS 26.0 或更新版本")
                    .foregroundColor(theme.textMuted)
            }
            
        case .zoteroConnect:
            if #available(macOS 26.0, *) {
                ZoteroBridgeView(targetLibrary: targetLibrary)
                    .environmentObject(theme)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("此功能需要 macOS 26.0 或更新版本")
                    .foregroundColor(theme.textMuted)
            }
            
        case .pdfAnalysis:
            if #available(macOS 26.0, *) {
                PDFLayoutAnalysisView()
                    .environmentObject(theme)
            } else {
                Text("此功能需要 macOS 26.0 或更新版本")
                    .foregroundColor(theme.textMuted)
            }
        }
    }
}

// MARK: - AI 功能枚舉

/// AI 功能類型
enum AIFeature: String, CaseIterable, Identifiable {
    case academicTranslation = "學術翻譯"
    case standardsCheck = "規範檢查"
    case phrasebank = "學術語料庫"
    case terminologyCheck = "術語檢查"
    case zoteroConnect = "Zotero 連接"
    case pdfAnalysis = "PDF 智慧分析"
    
    var id: String { rawValue }
    
    var title: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .academicTranslation:
            return "character.book.closed"
        case .standardsCheck:
            return "checkmark.seal"
        case .phrasebank:
            return "text.book.closed"
        case .terminologyCheck:
            return "character.textbox"
        case .zoteroConnect:
            return "link.circle"
        case .pdfAnalysis:
            return "doc.viewfinder"
        }
    }
    
    var description: String {
        switch self {
        case .academicTranslation:
            return "中英文學術表達轉換，保持學術嚴謹性"
        case .standardsCheck:
            return "檢查台灣學術規範，包含用語與格式"
        case .phrasebank:
            return "學術寫作句型庫，提供標準學術表達"
        case .terminologyCheck:
            return "繁簡術語校正，確保符合台灣用語規範"
        case .zoteroConnect:
            return "連接 Zotero 文獻庫，快速匯入書目"
        case .pdfAnalysis:
            return "智慧分析 PDF 版面，精準提取多欄文字"
        }
    }
    
    var isAvailable: Bool {
        return true
    }
    
    var statusBadge: String {
        switch self {
        case .phrasebank, .terminologyCheck:
            return "新功能"
        case .zoteroConnect, .pdfAnalysis:
            return "新功能"
        default:
            return "可用"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .phrasebank, .terminologyCheck:
            return .purple
        case .zoteroConnect:
            return .blue
        case .pdfAnalysis:
            return .orange
        default:
            return .green
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
