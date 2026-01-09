//
//  DuplicateWarningDialog.swift
//  OVEREND
//
//  重複檢測警告對話框
//

import SwiftUI

/// 重複檢測警告對話框
struct DuplicateWarningDialog: View {
    @EnvironmentObject var theme: AppTheme
    
    let result: DuplicateDetectionService.DetectionResult
    let newEntryTitle: String
    var onMergeChoice: (DuplicateDetectionService.MergeStrategy) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 標題
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                Text("發現重複文獻")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            .padding(20)
            .background(theme.tableRowHover)
            
            Divider()
            
            // MARK: - 內容
            VStack(alignment: .leading, spacing: 16) {
                // 匹配資訊
                matchInfoSection
                
                Divider()
                
                // 文獻對比
                comparisonSection
                
                Divider()
                
                // 操作選項
                optionsSection
            }
            .padding(20)
            
            Divider()
            
            // MARK: - 按鈕
            HStack {
                Button("取消匯入") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textMuted)
                
                Spacer()
            }
            .padding(20)
            .background(theme.tableRowHover)
        }
        .frame(width: 500)
        .background(theme.card)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - 匹配資訊區塊
    
    private var matchInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("匹配類型")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                
                matchTypeBadge
            }
            
            if result.matchType == .similarTitle {
                HStack(spacing: 8) {
                    Text("相似度")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                    
                    Text("\(Int(result.similarityScore * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(similarityColor)
                    
                    // 進度條
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(theme.border)
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(similarityColor)
                                .frame(width: geo.size.width * result.similarityScore, height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(width: 100, height: 4)
                }
            }
        }
    }
    
    private var matchTypeBadge: some View {
        Text(result.matchType.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(matchTypeColor.opacity(0.15))
            .foregroundColor(matchTypeColor)
            .cornerRadius(6)
    }
    
    private var matchTypeColor: Color {
        switch result.matchType {
        case .exactDOI: return .red
        case .similarTitle: return .orange
        case .none: return .gray
        }
    }
    
    private var similarityColor: Color {
        if result.similarityScore >= 0.95 {
            return .red
        } else if result.similarityScore >= 0.90 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    // MARK: - 文獻對比區塊
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文獻對比")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textMuted)
            
            HStack(alignment: .top, spacing: 16) {
                // 現有文獻
                entryCard(
                    label: "現有文獻",
                    title: result.existingEntry?.title ?? "未知",
                    author: result.existingEntry?.author ?? "未知",
                    year: result.existingEntry?.year ?? "",
                    color: .blue
                )
                
                // 新文獻
                entryCard(
                    label: "新匯入",
                    title: newEntryTitle,
                    author: "",
                    year: "",
                    color: .green
                )
            }
        }
    }
    
    private func entryCard(
        label: String,
        title: String,
        author: String,
        year: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(3)
                
                if !author.isEmpty {
                    Text(author)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                        .lineLimit(1)
                }
                
                if !year.isEmpty {
                    Text(year)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.tableRowHover)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 操作選項區塊
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("請選擇處理方式")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.textMuted)
            
            VStack(spacing: 8) {
                ForEach(DuplicateDetectionService.MergeOption.options, id: \.title) { option in
                    optionButton(option)
                }
            }
        }
    }
    
    private func optionButton(_ option: DuplicateDetectionService.MergeOption) -> some View {
        Button {
            onMergeChoice(option.strategy)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(option.description)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textTertiary)
            }
            .padding(12)
            .background(theme.tableRowHover)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 批次重複檢測結果視圖

struct BatchDuplicateResultView: View {
    @EnvironmentObject var theme: AppTheme
    
    let results: [DuplicateDetectionService.BatchDetectionResult]
    var onDismiss: () -> Void
    
    private var duplicates: [DuplicateDetectionService.BatchDetectionResult] {
        results.filter { $0.result.isDuplicate }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accent)
                
                Text("重複檢測結果")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(theme.tableRowHover)
            
            Divider()
            
            // 統計摘要
            HStack(spacing: 20) {
                statItem(label: "總數", value: "\(results.count)", color: .blue)
                statItem(label: "重複", value: "\(duplicates.count)", color: .orange)
                statItem(label: "正常", value: "\(results.count - duplicates.count)", color: .green)
            }
            .padding(20)
            
            Divider()
            
            // 重複列表
            if duplicates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("沒有發現重複文獻")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(duplicates.indices, id: \.self) { index in
                            duplicateRow(duplicates[index])
                        }
                    }
                    .padding(20)
                }
            }
            
            Divider()
            
            // 關閉按鈕
            HStack {
                Spacer()
                
                Button("完成") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
            .padding(20)
            .background(theme.tableRowHover)
        }
        .frame(width: 500, height: 500)
        .background(theme.card)
        .cornerRadius(16)
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func duplicateRow(_ item: DuplicateDetectionService.BatchDetectionResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.entry.fields["title"] ?? "未知標題")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(2)
                
                Text(item.result.message)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            Text("\(Int(item.result.similarityScore * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.orange)
        }
        .padding(12)
        .background(theme.tableRowHover)
        .cornerRadius(8)
    }
}

// MARK: - 預覽

#Preview("Warning Dialog") {
    DuplicateWarningDialog(
        result: DuplicateDetectionService.DetectionResult(
            isDuplicate: true,
            matchType: .similarTitle,
            existingEntry: nil,
            similarityScore: 0.92,
            message: "發現相似標題（92% 相似）"
        ),
        newEntryTitle: "A Study on Machine Learning Applications",
        onMergeChoice: { _ in },
        onCancel: {}
    )
    .environmentObject(AppTheme())
    .padding(40)
    .background(Color.gray.opacity(0.3))
}
