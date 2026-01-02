//
//  DesignTokens.swift
//  OVEREND
//
//  設計標記系統 - 統一定義所有視覺設計標準
//

import SwiftUI

/// 設計標記系統
/// 提供統一的圓角、陰影、間距、圖標大小等設計標準
struct DesignTokens {

    // MARK: - 圓角系統

    /// 圓角半徑標準
    enum CornerRadius {
        /// 小圓角 - 用於按鈕、輸入框
        static let small: CGFloat = 6

        /// 中圓角 - 用於卡片、Toast
        static let medium: CGFloat = 10

        /// 大圓角 - 用於面板、Modal
        static let large: CGFloat = 16

        /// 特大圓角 - 用於大型容器
        static let xLarge: CGFloat = 20
    }

    // MARK: - 陰影系統

    /// 陰影樣式（參考 Material Design Elevation）
    enum Shadow {
        /// 高度 1 - 懸停效果
        /// 用於：按鈕懸停狀態
        static let level1 = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )

        /// 高度 2 - 卡片
        /// 用於：一般卡片、文獻列表項
        static let level2 = ShadowStyle(
            color: Color.black.opacity(0.10),
            radius: 8,
            x: 0,
            y: 4
        )

        /// 高度 3 - 浮動面板
        /// 用於：Toast、浮動工具列
        static let level3 = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 8
        )

        /// 高度 4 - Modal
        /// 用於：對話框、Sheet
        static let level4 = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 24,
            x: 0,
            y: 12
        )

        /// 發光效果 - 用於主色強調
        /// 用於：主要按鈕、重要操作
        static func glow(color: Color) -> ShadowStyle {
            ShadowStyle(
                color: color.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }

    // MARK: - 間距系統

    /// 8pt 基準網格間距系統
    enum Spacing {
        /// 超超小間距 - 2pt
        /// 用於：緊密相關的元素
        static let xxxs: CGFloat = 2

        /// 超小間距 - 4pt
        /// 用於：標籤與圖標
        static let xxs: CGFloat = 4

        /// 小間距 - 8pt（基準單位）
        /// 用於：元素內部間距
        static let xs: CGFloat = 8

        /// 小中間距 - 12pt
        /// 用於：按鈕內邊距
        static let sm: CGFloat = 12

        /// 中間距 - 16pt（標準間距）
        /// 用於：卡片內邊距、常規元素間距
        static let md: CGFloat = 16

        /// 大間距 - 24pt
        /// 用於：組件之間的間距
        static let lg: CGFloat = 24

        /// 特大間距 - 32pt
        /// 用於：區塊間距
        static let xl: CGFloat = 32

        /// 超大間距 - 48pt
        /// 用於：大區塊間距
        static let xxl: CGFloat = 48

        /// 超超大間距 - 64pt
        /// 用於：頁面級間距
        static let xxxl: CGFloat = 64
    }

    // MARK: - 圖標系統

    /// SF Symbols 圖標大小標準
    enum IconSize {
        /// 小圖標 - 14pt
        /// 用於：按鈕內圖標、輔助圖標
        static let small: CGFloat = 14

        /// 中圖標 - 18pt
        /// 用於：側邊欄圖標、列表圖標
        static let medium: CGFloat = 18

        /// 大圖標 - 24pt
        /// 用於：工具列圖標、主要圖標
        static let large: CGFloat = 24

        /// 特大圖標 - 32pt
        /// 用於：空狀態圖標、強調圖標
        static let xLarge: CGFloat = 32
    }

    // MARK: - 字體系統

    /// 字體大小標準（擴展 AppTheme 的字體定義）
    enum Typography {
        /// 特大標題 - 28pt
        static let largeTitle: CGFloat = 28

        /// 標題 1 - 24pt
        static let title1: CGFloat = 24

        /// 標題 2 - 20pt
        static let title2: CGFloat = 20

        /// 標題 3 - 18pt
        static let title3: CGFloat = 18

        /// 標題行 - 16pt（粗體）
        static let headline: CGFloat = 16

        /// 正文 - 15pt
        static let body: CGFloat = 15

        /// 標注 - 14pt
        static let callout: CGFloat = 14

        /// 副標題 - 13pt
        static let subheadline: CGFloat = 13

        /// 腳註 - 12pt
        static let footnote: CGFloat = 12

        /// 說明文字 - 11pt
        static let caption: CGFloat = 11
    }

    // MARK: - 動畫時長

    /// 過渡動畫時長標準（將在 AnimationSystem 中使用）
    enum Duration {
        /// 即時反饋 - 100ms
        static let instant: Double = 0.1

        /// 快速過渡 - 200ms
        static let fast: Double = 0.2

        /// 標準動畫 - 300ms
        static let normal: Double = 0.3

        /// 慢速強調 - 500ms
        static let slow: Double = 0.5
    }
}

// MARK: - 陰影樣式結構

/// 陰影樣式定義
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View 擴展

extension View {
    /// 應用標準陰影
    /// - Parameter level: 陰影層級（1-4）
    func applyShadow(level: Int) -> some View {
        let shadow: ShadowStyle
        switch level {
        case 1: shadow = DesignTokens.Shadow.level1
        case 2: shadow = DesignTokens.Shadow.level2
        case 3: shadow = DesignTokens.Shadow.level3
        case 4: shadow = DesignTokens.Shadow.level4
        default: shadow = DesignTokens.Shadow.level2
        }

        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// 應用發光陰影
    /// - Parameter color: 發光顏色
    func applyGlowShadow(color: Color) -> some View {
        let shadow = DesignTokens.Shadow.glow(color: color)
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// 應用標準圓角
    /// - Parameter radius: 圓角類型（.small, .medium, .large, .xLarge）
    func applyCornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - 使用範例

/*

 使用範例：

 // 1. 使用圓角
 RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)

 // 2. 使用間距
 VStack(spacing: DesignTokens.Spacing.md) { }
 .padding(DesignTokens.Spacing.lg)

 // 3. 使用陰影
 .applyShadow(level: 2)

 // 4. 使用圖標
 Image(systemName: "heart.fill")
    .font(.system(size: DesignTokens.IconSize.medium))

 // 5. 使用發光效果
 .applyGlowShadow(color: theme.accent)

 */
