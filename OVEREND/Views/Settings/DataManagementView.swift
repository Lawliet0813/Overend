//
//  DataManagementView.swift
//  OVEREND
//
//  資料管理設定頁面
//

import SwiftUI
import CoreData

/// 資料管理設定視圖
struct DataManagementView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var theme: AppTheme
    
    @State private var summary: AnalyticsSummary?
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showExportSuccess = false
    @State private var showAnalyticsSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 標題
                Text("AI 提取資料管理")
                    .font(.system(size: DesignTokens.Typography.title2, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                // 訓練資料統計
                VStack(alignment: .leading, spacing: 16) {
                    Text("訓練資料")
                        .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    HStack(spacing: 20) {
                        StatCard(
                            title: "已收集樣本",
                            value: "\(summary?.totalExtractions ?? 0)",
                            icon: "doc.text.fill",
                            color: theme.accent
                        )
                        
                        StatCard(
                            title: "已評分樣本",
                            value: "\(summary?.ratedExtractions ?? 0)",
                            icon: "star.fill",
                            color: Color(hex: "#FFC107")
                        )
                        
                        StatCard(
                            title: "已修正樣本",
                            value: "\(summary?.correctedExtractions ?? 0)",
                            icon: "pencil.circle.fill",
                            color: Color(hex: "#FF9800")
                        )
                    }
                    
                    // 匯出按鈕
                    HStack {
                        PrimaryButton("匯出 JSON 訓練資料", icon: "square.and.arrow.up") {
                            exportTrainingData()
                        }
                        .disabled(isExporting || (summary?.totalExtractions ?? 0) == 0)
                        
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(theme.card)
                )
                
                // 準確率分析
                if let summary = summary, !summary.methodAccuracies.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("提取方法準確率")
                                .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Button("查看詳細分析") {
                                showAnalyticsSheet = true
                            }
                            .font(.system(size: 13))
                            .foregroundColor(theme.accent)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(summary.methodAccuracies) { accuracy in
                                MethodAccuracyRow(accuracy: accuracy)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.card)
                    )
                }
                
                // Prompt 改進建議
                if let suggestions = summary?.suggestions, !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Prompt 改進建議")
                            .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                        
                        VStack(spacing: 12) {
                            ForEach(suggestions) { suggestion in
                                SuggestionRow(suggestion: suggestion)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.card)
                    )
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(theme.background)
        .onAppear {
            loadAnalytics()
        }
        .alert("匯出成功", isPresented: $showExportSuccess) {
            Button("打開資料夾") {
                if let url = exportURL {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
            }
            Button("確定", role: .cancel) {}
        } message: {
            if let url = exportURL {
                Text("已匯出至：\n\(url.lastPathComponent)")
            }
        }
        .sheet(isPresented: $showAnalyticsSheet) {
            AnalyticsDetailSheet(summary: summary)
                .environmentObject(theme)
        }
    }
    
    private func loadAnalytics() {
        let analytics = ExtractionAnalytics(context: context)
        summary = analytics.calculateSummary()
    }
    
    private func exportTrainingData() {
        isExporting = true
        
        Task {
            let viewModel = ExtractionWorkbenchViewModel(context: context)
            if let url = viewModel.exportTrainingData() {
                await MainActor.run {
                    exportURL = url
                    showExportSuccess = true
                    isExporting = false
                }
            } else {
                await MainActor.run {
                    isExporting = false
                    ToastManager.shared.showError("匯出失敗")
                }
            }
        }
    }
}

// MARK: - 統計卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 準確率行

struct MethodAccuracyRow: View {
    let accuracy: MethodAccuracy
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            Text(accuracy.displayName)
                .font(.system(size: 14))
                .foregroundColor(theme.textPrimary)
                .frame(width: 140, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.border)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accuracyColor)
                        .frame(width: geometry.size.width * accuracy.accuracyPercentage / 100)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(accuracy.accuracyPercentage))%")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accuracyColor)
                .frame(width: 44, alignment: .trailing)
            
            Text("(\(accuracy.totalCount))")
                .font(.system(size: 11))
                .foregroundColor(theme.textMuted)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private var accuracyColor: Color {
        switch accuracy.accuracyPercentage {
        case 80...100: return Color(hex: "#4CAF50")
        case 60..<80: return Color(hex: "#FFC107")
        default: return Color(hex: "#F44336")
        }
    }
}

// MARK: - 建議行

struct SuggestionRow: View {
    let suggestion: PromptSuggestion
    @EnvironmentObject var theme: AppTheme
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 優先級標籤
                Text(suggestion.priority.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: suggestion.priority.color))
                    )
                
                Text(suggestion.issue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("影響 \(suggestion.affectedCount) 筆")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMuted)
                
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text("建議修改：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Text(suggestion.suggestedPrompt)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textPrimary)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.success.opacity(0.1))
                        )
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.background)
        )
    }
}

// MARK: - 詳細分析頁面

struct AnalyticsDetailSheet: View {
    let summary: AnalyticsSummary?
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let summary = summary {
                    VStack(alignment: .leading, spacing: 24) {
                        // 整體統計
                        VStack(alignment: .leading, spacing: 12) {
                            Text("整體統計")
                                .font(.headline)
                            
                            HStack(spacing: 40) {
                                VStack(alignment: .leading) {
                                    Text("整體準確率")
                                        .font(.caption)
                                        .foregroundColor(theme.textMuted)
                                    Text("\(Int(summary.overallAccuracy))%")
                                        .font(.title)
                                        .bold()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("修正率")
                                        .font(.caption)
                                        .foregroundColor(theme.textMuted)
                                    Text("\(Int(summary.correctionRate))%")
                                        .font(.title)
                                        .bold()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("平均評分")
                                        .font(.caption)
                                        .foregroundColor(theme.textMuted)
                                    Text(String(format: "%.1f", summary.averageRating))
                                        .font(.title)
                                        .bold()
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 常見錯誤
                        if !summary.commonErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("常見錯誤")
                                    .font(.headline)
                                
                                ForEach(summary.commonErrors) { error in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("欄位：\(error.field)")
                                            .font(.caption)
                                            .foregroundColor(theme.textMuted)
                                        
                                        HStack {
                                            Text("AI：")
                                                .font(.caption)
                                            Text(error.aiValue)
                                                .strikethrough()
                                                .foregroundColor(.red)
                                        }
                                        
                                        HStack {
                                            Text("正確：")
                                                .font(.caption)
                                            Text(error.correctValue)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(8)
                                    .background(theme.card)
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("詳細分析")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    DataManagementView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppTheme())
        .frame(width: 600, height: 700)
}
