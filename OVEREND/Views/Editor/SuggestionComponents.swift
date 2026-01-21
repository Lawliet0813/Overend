//
//  SuggestionComponents.swift
//  OVEREND
//
//  建議面板組件 - 分類按鈕和建議卡片
//

import SwiftUI

// MARK: - Category Button

struct WritingCategoryButton: View {
    @EnvironmentObject var theme: AppTheme
    let category: WritingSuggestionCategory
    let count: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(theme.fontBodySmall)

                if count > 0 {
                    Text("(\(count))")
                        .font(theme.fontBodySmall)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? category.color : theme.elevated)
            .foregroundColor(isActive ? .white : theme.textPrimary)
            .cornerRadius(theme.cornerRadiusLG)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Suggestion Card

struct WritingSuggestionCard: View {
    @EnvironmentObject var theme: AppTheme
    let suggestion: WritingSuggestion
    let onApply: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            HStack {
                // 分類標籤
                HStack(spacing: 4) {
                    Image(systemName: suggestion.category.icon)
                        .font(.caption2)

                    Text(suggestion.category.rawValue)
                        .font(theme.fontLabel)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(suggestion.category.color)
                .foregroundColor(.white)
                .cornerRadius(theme.cornerRadiusSM)

                // 顏色指示器
                Circle()
                    .fill(suggestion.category.color.opacity(0.5))
                    .frame(width: 12, height: 12)

                Spacer()

                // 操作按鈕
                HStack(spacing: 4) {
                    Button(action: onApply) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .help("接受建議")

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("忽略建議")
                }
            }

            // 修改建議
            HStack(spacing: 8) {
                // 原文（劃線）
                Text(suggestion.issue)
                    .font(theme.fontBodySmall)
                    .foregroundColor(.red)
                    .strikethrough()

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)

                // 建議文字
                Text(suggestion.suggestion)
                    .font(theme.fontBodySmall)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }

            // 說明
            Text(suggestion.explanation)
                .font(theme.fontBodySmall)
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(theme.elevated)
        .cornerRadius(theme.cornerRadiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMD)
                .stroke(suggestion.category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Category Button") {
    HStack {
        WritingCategoryButton(
            category: .grammar,
            count: 5,
            isActive: true,
            action: {}
        )
        .environmentObject(AppTheme())

        WritingCategoryButton(
            category: .spelling,
            count: 2,
            isActive: false,
            action: {}
        )
        .environmentObject(AppTheme())
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Suggestion Card") {
    WritingSuggestionCard(
        suggestion: WritingSuggestion(
            category: .grammar,
            issue: "is",
            suggestion: "are",
            explanation: "主詞與動詞的一致性：複數主詞應使用複數動詞",
            position: 0
        ),
        onApply: {},
        onDismiss: {}
    )
    .environmentObject(AppTheme())
    .frame(width: 400)
    .padding()
}
