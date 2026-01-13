//
//  AppTheme.swift
//  OVEREND
//
//  主題系統 - Academic Green 設計規範
//  基於 macOS 深色模式優化
//

import SwiftUI
import Combine

/// 應用程式主題（Academic Green 設計系統）
class AppTheme: ObservableObject {
    
    // MARK: - 主色系 (Academic Green)
    
    /// 學術綠 - 主要強調色
    static let academicGreen = "#39D353"
    
    @Published var accentHex: String = academicGreen {
        didSet {
            UserDefaults.standard.set(accentHex, forKey: "appAccentColor")
        }
    }
    
    /// 預設主題色選項
    static let presetColors: [(name: String, hex: String, isGradient: Bool)] = [
        ("學術綠", "#39D353", false),
        ("Apple 藍", "#007AFF", false),
        ("紫羅蘭", "#AF52DE", false),
        ("珊瑚紅", "#FF6B6B", false),
        ("琥珀橙", "#FF9500", false),
        ("靛青藍", "#5856D6", false),
        ("玫瑰粉", "#FF2D55", false),
        ("🏳️‍🌈 彩虹驕傲", "#E40303", true)
    ]
    
    /// Pride 漸層顏色 (更鮮豔的霓虹色系 - 參考圖示)
    static let prideGradientColors: [Color] = [
        Color(hex: "#FF0000"), // Red
        Color(hex: "#FF7F00"), // Orange
        Color(hex: "#FFFF00"), // Yellow
        Color(hex: "#00FF00"), // Green
        Color(hex: "#0000FF"), // Blue
        Color(hex: "#4B0082"), // Indigo
        Color(hex: "#9400D3")  // Violet
    ]
    
    /// 是否使用彩虹驕傲模式
    var isPrideMode: Bool {
        accentHex == "#E40303"
    }
    
    /// Pride 漸層
    var prideGradient: LinearGradient {
        LinearGradient(
            colors: Self.prideGradientColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    init() {
        if let savedColor = UserDefaults.standard.string(forKey: "appAccentColor") {
            self.accentHex = savedColor
        }
    }
    
    // MARK: - 主色
    
    /// 主色（可自訂，預設學術綠）
    var accent: Color { Color(hex: accentHex) }
    
    /// 淺色主色（用於 Hover 背景）
    var accentLight: Color { accent.opacity(0.1) }
    
    /// 主色半透明（卡片背景、Hover）
    var accentTranslucent: Color { Color(hex: Self.academicGreen).opacity(0.1) }
    
    // MARK: - 背景層次 (Background Layers)
    
    /// 底層背景 (Base Background) - 視窗最底層
    var background: Color { Color(hex: "#0A0A0A") }
    
    /// 提升層 (Elevated Layer) - 側邊欄、卡片、彈出視窗
    var elevated: Color { Color(hex: "#141414") }
    
    /// 功能層 (Functional Layer) - 頂部數據看板
    var functional: Color { Color(hex: "#111111") }
    
    /// 側邊欄背景
    var sidebar: Color { elevated }
    
    /// 工具列背景
    var toolbar: Color { functional }
    
    /// 頁面背景
    var page: Color { background }
    
    /// 卡片背景
    var card: Color { elevated }
    
    // MARK: - 文字色 (Typography Colors)
    
    /// 一級文字 - 標題與主要內容 (Gray-100)
    var textPrimary: Color { Color(hex: "#F3F4F6") }
    
    /// 二級文字 - 說明、標籤、次要資訊 (Gray-400)
    var textSecondary: Color { Color(hex: "#9CA3AF") }
    
    /// 三級文字 - 時間戳、ID、不可點擊元素 (Gray-500)
    var textTertiary: Color { Color(hex: "#6B7280") }
    
    /// 次要文字（別名）
    var textMuted: Color { textSecondary }
    
    /// 強調文字（用於主色背景）
    var textOnAccent: Color { .white }
    
    /// 禁用文字色
    var textDisabled: Color { Color.white.opacity(0.3) }
    
    // MARK: - 邊框色 (Border/Stroke)
    
    /// 極細微白色半透明邊框
    var border: Color { Color.white.opacity(0.05) }
    
    /// 較明顯邊框
    var borderSubtle: Color { Color.white.opacity(0.08) }
    
    // MARK: - macOS 系統控制色 (System Controls)
    
    /// 關閉按鈕 (Red)
    var systemRed: Color { Color(hex: "#FF5F57") }
    
    /// 最小化按鈕 (Yellow)
    var systemYellow: Color { Color(hex: "#FEBC2E") }
    
    /// 縮放按鈕 (Green)
    var systemGreen: Color { Color(hex: "#28C840") }
    
    // MARK: - 互動色
    
    var itemHover: Color { Color.white.opacity(0.08) }
    
    var tableRowHover: Color { accentTranslucent }

    // MARK: - 語義化顏色

    var success: Color { Color(hex: "#39D353") }  // 使用學術綠
    
    // MARK: - 字體系統 (Typography System)
    
    /// 超大標題 - 頁面主標題
    var fontDisplayLarge: Font { .system(size: 32, weight: .bold) }
    
    /// 大標題 - 區域標題
    var fontDisplayMedium: Font { .system(size: 24, weight: .bold) }
    
    /// 中標題 - 卡片標題
    var fontDisplaySmall: Font { .system(size: 20, weight: .semibold) }
    
    /// 正文大 - 重要內容
    var fontBodyLarge: Font { .system(size: 17, weight: .regular) }
    
    /// 正文中 - 一般內容
    var fontBodyMedium: Font { .system(size: 15, weight: .regular) }
    
    /// 正文小 - 輔助內容
    var fontBodySmall: Font { .system(size: 13, weight: .regular) }
    
    /// 標籤 - 小型標籤、徽章
    var fontLabel: Font { .system(size: 12, weight: .medium) }
    
    /// 側邊欄項目
    var fontSidebarItem: Font { .system(size: 14, weight: .medium) }
    
    /// 按鈕文字
    var fontButton: Font { .system(size: 14, weight: .semibold) }
    
    // MARK: - 間距系統 (Spacing System)
    
    /// 極小間距 (4pt)
    var spacingXS: CGFloat { 4 }
    
    /// 小間距 (8pt)
    var spacingSM: CGFloat { 8 }
    
    /// 中間距 (12pt)
    var spacingMD: CGFloat { 12 }
    
    /// 大間距 (16pt)
    var spacingLG: CGFloat { 16 }
    
    /// 超大間距 (24pt)
    var spacingXL: CGFloat { 24 }
    
    /// 超超大間距 (32pt)
    var spacing2XL: CGFloat { 32 }
    
    // MARK: - 圓角系統 (Corner Radius)
    
    /// 小圓角 - 按鈕、標籤
    var cornerRadiusSM: CGFloat { 6 }
    
    /// 中圓角 - 卡片
    var cornerRadiusMD: CGFloat { 10 }
    
    /// 大圓角 - 面板
    var cornerRadiusLG: CGFloat { 12 }
    
    /// 超大圓角 - Modal
    var cornerRadiusXL: CGFloat { 16 }
    var successBackground: Color { success.opacity(0.1) }

    var warning: Color { Color(hex: "#FEBC2E") }  // 系統黃
    var warningBackground: Color { warning.opacity(0.1) }

    var error: Color { Color(hex: "#FF5F57") }  // 系統紅
    var errorBackground: Color { error.opacity(0.1) }

    var info: Color { Color(hex: "#007AFF") }  // Apple 藍
    var infoBackground: Color { info.opacity(0.1) }

    var destructive: Color { systemRed }
    var destructiveBackground: Color { destructive.opacity(0.1) }

    // MARK: - 互動狀態顏色

    var buttonDisabled: Color { Color.white.opacity(0.15) }
    var focusBorder: Color { accent }
    var selectedBackground: Color { accent.opacity(0.15) }
    var link: Color { info }
    var divider: Color { Color.white.opacity(0.05) }
    
    // MARK: - 圓角系統 (Corner Radius)
    
    /// 大區塊 (Banner) - 40px
    var radiusBanner: CGFloat { 40 }
    
    /// 卡片 (Card) - 24px
    var radiusCard: CGFloat { 24 }
    
    /// 小按鈕 (Button) - 12px
    var radiusButton: CGFloat { 12 }
    
    /// 輸入框 - 8px
    var radiusInput: CGFloat { 8 }
    
    // MARK: - 模糊效果 (Vibrancy)
    
    /// 背景模糊半徑
    var blurRadius: CGFloat { 20 }
    
    // MARK: - 字體尺寸系統
    
    var fontXLarge: CGFloat { 28 }
    var fontLarge: CGFloat { 22 }
    var fontMedium: CGFloat { 18 }
    var fontBody: CGFloat { 15 }
    var fontCaption: CGFloat { 13 }
    var fontMini: CGFloat { 11 }
    
    // MARK: - 字體樣式
    
    /// 標題字體 - SF Pro Display
    func titleFont(size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    
    /// 內文字體 - SF Pro Text
    func bodyFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    /// 說明文字
    func captionFont(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    /// 等寬字體 - SF Mono (用於數據、計時器)
    func monoFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
    
    // MARK: - macOS 液態玻璃效果
    
    var glassMaterial: Material { .ultraThinMaterial }
    
    /// 側邊欄玻璃效果
    var sidebarGlass: Color { elevated.opacity(0.8) }
    
    /// 卡片玻璃效果
    var cardGlass: Color { Color.white.opacity(0.05) }
    
    /// 工具列玻璃效果
    var toolbarGlass: Color { functional.opacity(0.9) }
    
    /// 發光色
    var glowColor: Color { accent.opacity(0.4) }
    
    /// 玻璃邊框
    var glassBorder: Color { border }
    
    /// 液態漸層
    var liquidGradient: LinearGradient {
        if isPrideMode {
            // 彩虹模式使用全彩漸層 - 增強不透明度以匹配參考圖
            return LinearGradient(
                colors: Self.prideGradientColors.map { $0.opacity(0.3) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // 一般模式使用單色漸層
            return LinearGradient(
                colors: [
                    accent.opacity(0.15),
                    Color(hex: "#28C840").opacity(0.1),
                    accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Emerald Settings 設計系統
    
    /// Emerald 主色 (翠綠)
    static let emeraldPrimary = "#25f49d"
    
    /// Emerald 背景色 (深綠)
    static let emeraldBackground = "#10221a"
    
    /// Emerald 主色
    var emerald: Color { Color(hex: Self.emeraldPrimary) }
    
    /// Emerald 背景
    var emeraldBg: Color { Color(hex: Self.emeraldBackground) }
    
    /// 玻璃面板背景
    var glassPanel: Color { Color(hex: Self.emeraldBackground).opacity(0.75) }
    
    /// 玻璃面板邊框
    var glassPanelBorder: Color { Color(hex: Self.emeraldPrimary).opacity(0.2) }
    
    /// Emerald 選中狀態背景
    var emeraldSelected: Color { Color(hex: Self.emeraldPrimary).opacity(0.1) }
    
    /// Emerald 選中狀態邊框
    var emeraldSelectedBorder: Color { Color(hex: Self.emeraldPrimary).opacity(0.2) }
    
    // MARK: - 向後兼容
    
    /// 始終為深色模式
    var isDarkMode: Bool { true }
}

// MARK: - 預覽

#Preview("Academic Green Theme") {
    let theme = AppTheme()
    
    VStack(spacing: 16) {
        // 主色
        HStack(spacing: 12) {
            Circle().fill(theme.accent).frame(width: 32, height: 32)
            Text("學術綠 #39D353").foregroundStyle(theme.textPrimary)
        }
        
        Divider().background(theme.border)
        
        // 背景層次
        VStack(spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.background).frame(width: 32, height: 32)
                Text("底層 #0A0A0A").font(theme.captionFont())
            }
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.elevated).frame(width: 32, height: 32)
                Text("提升層 #141414").font(theme.captionFont())
            }
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.functional).frame(width: 32, height: 32)
                Text("功能層 #111111").font(theme.captionFont())
            }
        }
        .foregroundStyle(theme.textSecondary)
        
        Divider().background(theme.border)
        
        // 文字層次
        Text("一級文字 Primary").foregroundStyle(theme.textPrimary).font(theme.bodyFont())
        Text("二級文字 Secondary").foregroundStyle(theme.textSecondary).font(theme.bodyFont())
        Text("三級文字 Tertiary").foregroundStyle(theme.textTertiary).font(theme.captionFont())
    }
    .padding(24)
    .background(theme.background)
    .clipShape(RoundedRectangle(cornerRadius: theme.radiusCard))
}
