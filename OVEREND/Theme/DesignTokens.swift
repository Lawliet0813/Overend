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

    /// 圓角半徑標準 (Academic Green Design Spec)
    enum CornerRadius {
        /// 小圓角 - 用於輸入框 (8px)
        static let small: CGFloat = 8

        /// 中圓角 - 用於小按鈕 (12px)
        static let medium: CGFloat = 12

        /// 大圓角 - 用於卡片 (24px)
        static let large: CGFloat = 24

        /// 特大圓角 - 用於大區塊 Banner (40px)
        static let xLarge: CGFloat = 40
    }
    
    // MARK: - 圓角系統 V2 (Scholar's Desk)
    
    /// 新版圓角系統 - 更柔和的設計
    enum CornerRadiusV2 {
        /// 超小圓角 - 輸入框、標籤 (6px)
        static let xs: CGFloat = 6
        
        /// 小圓角 - 小按鈕 (8px)
        static let sm: CGFloat = 8
        
        /// 中圓角 - 卡片、列表項 (12px)
        static let md: CGFloat = 12
        
        /// 大圓角 - 面板、Modal (16px)
        static let lg: CGFloat = 16
        
        /// 超大圓角 - 大區塊 (24px)
        static let xl: CGFloat = 24
    }

    // MARK: - 陰影系統

    /// 陰影樣式（增強立體感版本）
    enum Shadow {
        /// 高度 1 - 懸停效果
        /// 用於：按鈕懸停狀態
        static let level1 = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 6,
            x: 0,
            y: 3
        )

        /// 高度 2 - 卡片
        /// 用於：一般卡片、文獻列表項
        static let level2 = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 6
        )

        /// 高度 3 - 浮動面板
        /// 用於：Toast、浮動工具列
        static let level3 = ShadowStyle(
            color: Color.black.opacity(0.18),
            radius: 20,
            x: 0,
            y: 10
        )

        /// 高度 4 - Modal
        /// 用於：對話框、Sheet
        static let level4 = ShadowStyle(
            color: Color.black.opacity(0.22),
            radius: 30,
            x: 0,
            y: 15
        )
        
        /// 高度 5 - 深層浮動（新增）
        /// 用於：彈出菜單、下拉選單
        static let level5 = ShadowStyle(
            color: Color.black.opacity(0.25),
            radius: 40,
            x: 0,
            y: 20
        )

        /// 發光效果 - 用於主色強調
        /// 用於：主要按鈕、重要操作
        static func glow(color: Color) -> ShadowStyle {
            ShadowStyle(
                color: color.opacity(0.5),
                radius: 16,
                x: 0,
                y: 8
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
    
    // MARK: - 間距系統 V2 (Scholar's Desk)
    
    /// 新版間距系統 - 基於 4pt 網格
    enum SpacingV2 {
        /// 超超小間距 - 4pt
        static let xxs: CGFloat = 4
        
        /// 超小間距 - 8pt
        static let xs: CGFloat = 8
        
        /// 小間距 - 12pt
        static let sm: CGFloat = 12
        
        /// 中間距 - 16pt
        static let md: CGFloat = 16
        
        /// 大間距 - 24pt
        static let lg: CGFloat = 24
        
        /// 超大間距 - 32pt
        static let xl: CGFloat = 32
        
        /// 超超大間距 - 48pt
        static let xxl: CGFloat = 48
        
        /// 區段間距 - 64pt
        static let section: CGFloat = 64
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
    
    // MARK: - 字體系統 V2 (Scholar's Desk)
    
    /// 新版字體系統 - 完整的字體階層
    enum TypographyV2 {
        // 標題
        static let displayLarge: Font = .system(size: 32, weight: .bold)
        static let displayMedium: Font = .system(size: 28, weight: .bold)
        static let titleLarge: Font = .system(size: 22, weight: .semibold)
        static let titleMedium: Font = .system(size: 18, weight: .semibold)
        static let titleSmall: Font = .system(size: 16, weight: .semibold)
        
        // 正文
        static let bodyLarge: Font = .system(size: 16, weight: .regular)
        static let bodyMedium: Font = .system(size: 14, weight: .regular)
        static let bodySmall: Font = .system(size: 13, weight: .regular)
        
        // 標籤
        static let labelLarge: Font = .system(size: 14, weight: .medium)
        static let labelMedium: Font = .system(size: 12, weight: .medium)
        static let labelSmall: Font = .system(size: 11, weight: .medium)
        static let caption: Font = .system(size: 10, weight: .regular)
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
    
    // MARK: - 動畫系統 V2 (Scholar's Desk)
    
    /// 新版動畫曲線 - 更流暢的過渡效果
    enum AnimationV2 {
        /// 快速動畫 - 150ms
        static let quick = Animation.easeOut(duration: 0.15)
        
        /// 標準動畫 - 250ms
        static let normal = Animation.easeInOut(duration: 0.25)
        
        /// 流暢動畫 - 350ms
        static let smooth = Animation.easeInOut(duration: 0.35)
        
        /// 彈簧動畫 - 自然的物理效果
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
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
