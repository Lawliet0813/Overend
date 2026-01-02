//
//  ConfidenceIndicator.swift
//  OVEREND
//
//  AI元數據提取可信度指示器
//

import SwiftUI

/// 可信度指示器
struct ConfidenceIndicator: View {
    @EnvironmentObject var theme: AppTheme

    let confidence: PDFMetadata.MetadataConfidence

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            // 圓點指示器
            Circle()
                .fill(Color(hex: confidence.color))
                .frame(width: 8, height: 8)

            Text(confidence.label)
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            Capsule()
                .fill(Color(hex: confidence.color).opacity(0.1))
        )
    }
}

/// 進度條樣式的可信度指示器
struct ConfidenceProgressIndicator: View {
    @EnvironmentObject var theme: AppTheme

    let confidence: PDFMetadata.MetadataConfidence

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text("AI 可信度")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(theme.textMuted)

                Spacer()

                Text(confidence.label)
                    .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
                    .foregroundColor(Color(hex: confidence.color))
            }

            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.border.opacity(0.3))
                        .frame(height: 4)

                    // 填充
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: confidence.color))
                        .frame(width: geometry.size.width * progressValue, height: 4)
                        .animation(AnimationSystem.Easing.spring, value: progressValue)
                }
            }
            .frame(height: 4)
        }
    }

    private var progressValue: CGFloat {
        switch confidence {
        case .high: return 1.0
        case .medium: return 0.6
        case .low: return 0.3
        }
    }
}

#Preview("Confidence Indicators") {
    VStack(spacing: 24) {
        let theme = AppTheme()

        VStack(alignment: .leading, spacing: 12) {
            Text("徽章樣式")
                .font(.system(size: 14, weight: .bold))

            ConfidenceIndicator(confidence: .high)
                .environmentObject(theme)

            ConfidenceIndicator(confidence: .medium)
                .environmentObject(theme)

            ConfidenceIndicator(confidence: .low)
                .environmentObject(theme)
        }

        Divider()

        VStack(alignment: .leading, spacing: 16) {
            Text("進度條樣式")
                .font(.system(size: 14, weight: .bold))

            ConfidenceProgressIndicator(confidence: .high)
                .environmentObject(theme)

            ConfidenceProgressIndicator(confidence: .medium)
                .environmentObject(theme)

            ConfidenceProgressIndicator(confidence: .low)
                .environmentObject(theme)
        }
    }
    .padding(32)
    .frame(width: 400)
}
