//
//  CitationRecommendationView.swift
//  OVEREND
//
//  智慧文獻推薦視圖
//

import SwiftUI
import CoreData

/// 智慧文獻推薦視圖
struct CitationRecommendationView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText: String = ""
    @State private var recommendations: [RecommendedEntry] = []
    @State private var isAnalyzing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜尋/輸入區域
            inputSection
            
            Divider()
            
            // 推薦結果
            if isAnalyzing {
                loadingView
            } else if recommendations.isEmpty {
                emptyStateView
            } else {
                recommendationListView
            }
        }
    }
    
    // MARK: - 子視圖
    
    /// 輸入區域
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("輸入文字或段落，AI 將推薦相關文獻")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(theme.textMuted)
            
            // 文字輸入框
            TextEditor(text: $searchText)
                .font(.system(size: DesignTokens.Typography.body))
                .frame(height: 120)
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(theme.itemHover)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .stroke(theme.border, lineWidth: 1)
                        )
                )
            
            // 操作按鈕
            HStack {
                Spacer()
                
                SecondaryButton("清除", size: .small) {
                    searchText = ""
                    recommendations = []
                }
                .environmentObject(theme)
                .disabled(searchText.isEmpty)
                
                PrimaryButton("分析並推薦", icon: "sparkles", size: .medium) {
                    analyzeAndRecommend()
                }
                .environmentObject(theme)
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(theme.toolbar)
    }
    
    /// 載入視圖
    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            SpinnerLoadingIndicator(size: 48, lineWidth: 4)
                .environmentObject(theme)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("正在分析...")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("AI 正在尋找相關文獻")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(theme.accent)
            }
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("開始分析")
                    .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("輸入文字後點擊「分析並推薦」")
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 推薦列表視圖
    private var recommendationListView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // 標題
            HStack {
                Text("找到 \(recommendations.count) 篇相關文獻")
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("按相關度排序")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.lg)
            
            // 推薦列表
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                            .environmentObject(theme)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
    }
    
    // MARK: - 方法
    
    /// 分析並推薦
    private func analyzeAndRecommend() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isAnalyzing = true
        recommendations = []
        
        Task {
            do {
                // TODO: 實現真正的 AI 推薦邏輯
                // 暫時使用模擬數據
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 秒
                
                await MainActor.run {
                    // 模擬推薦結果
                    recommendations = [
                        RecommendedEntry(
                            title: "AI in Education: A Review",
                            authors: "Smith, J., & Jones, A.",
                            year: "2023",
                            relevanceScore: 0.95,
                            reason: "討論 AI 技術在教育領域的應用，與您的內容高度相關"
                        ),
                        RecommendedEntry(
                            title: "Machine Learning for Academic Writing",
                            authors: "Chen, L.",
                            year: "2022",
                            relevanceScore: 0.87,
                            reason: "探討機器學習在學術寫作中的輔助角色"
                        ),
                        RecommendedEntry(
                            title: "The Future of Digital Learning",
                            authors: "Brown, K., et al.",
                            year: "2024",
                            relevanceScore: 0.76,
                            reason: "分析數位學習的未來趨勢與挑戰"
                        )
                    ]
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    ToastManager.shared.showError("分析失敗")
                }
            }
        }
    }
}

// MARK: - 推薦的文獻模型

/// 推薦的文獻
struct RecommendedEntry: Identifiable {
    let id = UUID()
    let title: String
    let authors: String
    let year: String
    let relevanceScore: Double
    let reason: String
}

// MARK: - 推薦卡片

/// 推薦卡片
struct RecommendationCard: View {
    @EnvironmentObject var theme: AppTheme
    
    let recommendation: RecommendedEntry
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 標題與相關度
            HStack(alignment: .top) {
                Text(recommendation.title)
                    .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                // 相關度指示器
                relevanceIndicator
            }
            
            // 作者與年份
            Text("\(recommendation.authors) (\(recommendation.year))")
                .font(.system(size: DesignTokens.Typography.caption))
                .foregroundColor(theme.textMuted)
            
            // 推薦原因
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accent)
                
                Text(recommendation.reason)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(theme.accentLight)
            )
            
            // 操作按鈕
            HStack(spacing: DesignTokens.Spacing.sm) {
                Spacer()
                
                Button(action: {
                    // TODO: 跳轉到文獻詳情
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                        Text("查看詳情")
                            .font(.system(size: DesignTokens.Typography.caption))
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.itemHover)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    // TODO: 插入引用到編輯器
                    ToastManager.shared.showSuccess("已插入引用")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 12))
                        Text("插入引用")
                            .font(.system(size: DesignTokens.Typography.caption))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.accent)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(AnimationSystem.Easing.quick) {
                isHovered = hovering
            }
        }
    }
    
    /// 相關度指示器
    private var relevanceIndicator: some View {
        VStack(spacing: 2) {
            Text("\(Int(recommendation.relevanceScore * 100))%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(relevanceColor)
            
            Text("相關度")
                .font(.system(size: 10))
                .foregroundColor(theme.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(relevanceColor.opacity(0.1))
        )
    }
    
    /// 相關度顏色
    private var relevanceColor: Color {
        if recommendation.relevanceScore >= 0.9 {
            return .green
        } else if recommendation.relevanceScore >= 0.7 {
            return .orange
        } else {
            return .gray
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    
    return CitationRecommendationView()
        .environmentObject(theme)
        .environmentObject(viewState)
        .frame(width: 900, height: 700)
}
