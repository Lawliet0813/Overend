//
//  AppTheme.swift
//  OVEREND
//
//  主題系統 - Scholar's Desk 設計規範
//  基於 macOS 深色模式優化，營造專業學術書房氛圍
//

import SwiftUI
import Combine

/// 應用程式主題（Scholar's Desk 設計系統）
class AppTheme: ObservableObject {
    
    // MARK: - Scholar's Desk 色彩系統
    
    // === 主色系 ===
    /// 墨水藍 - 知識與智慧的象徵
    static let inkBlue = "#2C4A6E"
    
    /// 羊皮紙金 - 學術經典感
    static let parchmentGold = "#D4A84B"
    
    /// 啟發綠 - AI 智能輔助
    static let insightGreen = "#4ADE80"
    
    // === 深色模式背景層次 ===
    /// 最深背景 - 書房深處
    static let backgroundDeep = "#0C1015"
    
    /// 一般背景 - 桌面
    static let backgroundBase = "#121820"
    
    /// 提升背景 - 卡片/面板
    static let backgroundElevated = "#1A232D"
    
    /// 表面 - 互動元素
    static let backgroundSurface = "#232F3E"
    
    // === 文字層次 ===
    /// 標題白 - 高對比標題
    static let textHeading = "#F8FAFC"
    
    /// 正文灰 - 主要內容
    static let textBody = "#CBD5E1"
    
    /// 次要灰 - 說明文字
    static let textMutedHex = "#64748B"
    
    /// 禁用灰 - 不可用元素
    static let textDisabledHex = "#475569"
    
    // === 功能色 ===
    static let semanticSuccess = "#22C55E"
    static let semanticWarning = "#F59E0B"
    static let semanticError = "#EF4444"
    static let semanticInfo = "#3B82F6"
    
    // MARK: - 向下相容（保留 Academic Green）
    
    /// 學術綠 - 主要強調色（向下相容）
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
    
    // MARK: - Scholar's Desk 背景層次
    
    /// 最深背景 - 書房深處
    var backgroundDeepColor: Color { Color(hex: Self.backgroundDeep) }
    
    /// 一般背景 - 桌面
    var backgroundBaseColor: Color { Color(hex: Self.backgroundBase) }
    
    /// 提升背景 - 卡片/面板
    var backgroundElevatedColor: Color { Color(hex: Self.backgroundElevated) }
    
    /// 表面 - 互動元素
    var backgroundSurfaceColor: Color { Color(hex: Self.backgroundSurface) }
    
    // MARK: - 向下相容背景層次 (Background Layers)
    
    /// 底層背景 (Base Background) - 視窗最底層
    var background: Color { backgroundBaseColor }
    
    /// 提升層 (Elevated Layer) - 側邊欄、卡片、彈出視窗
    var elevated: Color { backgroundElevatedColor }
    
    /// 功能層 (Functional Layer) - 頂部數據看板
    var functional: Color { backgroundSurfaceColor }
    
    /// 側邊欄背景
    var sidebar: Color { elevated }
    
    /// 工具列背景
    var toolbar: Color { functional }
    
    /// 頁面背景
    var page: Color { background }
    
    /// 卡片背景
    var card: Color { elevated }
    
    // MARK: - Scholar's Desk 主色系
    
    /// 墨水藍 - 知識與智慧
    var inkBlueColor: Color { Color(hex: Self.inkBlue) }
    
    /// 羊皮紙金 - 學術經典
    var parchmentGoldColor: Color { Color(hex: Self.parchmentGold) }
    
    /// 啟發綠 - AI 智能
    var insightGreenColor: Color { Color(hex: Self.insightGreen) }
    
    // MARK: - Scholar's Desk 文字層次
    
    /// 標題白 - 高對比標題
    var textHeadingColor: Color { Color(hex: Self.textHeading) }
    
    /// 正文灰 - 主要內容
    var textBodyColor: Color { Color(hex: Self.textBody) }
    
    /// 次要灰 - 說明文字
    var textMutedColor: Color { Color(hex: Self.textMutedHex) }
    
    /// 禁用灰 - 不可用元素
    var textDisabledColor: Color { Color(hex: Self.textDisabledHex) }
    
    // MARK: - 向下相容文字色 (Typography Colors)
    
    /// 一級文字 - 標題與主要內容 (Gray-100)
    var textPrimary: Color { textHeadingColor }
    
    /// 二級文字 - 說明、標籤、次要資訊 (Gray-400)
    var textSecondary: Color { textBodyColor }
    
    /// 三級文字 - 時間戳、ID、不可點擊元素 (Gray-500)
    var textTertiary: Color { textMutedColor }
    
    /// 次要文字（別名）- 向下相容
    var textMuted: Color { textSecondary }
    
    /// 強調文字（用於主色背景）
    var textOnAccent: Color { .white }
    
    /// 禁用文字色
    var textDisabled: Color { textDisabledColor }
    
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

    var success: Color { Color(hex: Self.semanticSuccess) }
    
    var warning: Color { Color(hex: Self.semanticWarning) }
    
    var error: Color { Color(hex: Self.semanticError) }
    
    var info: Color { Color(hex: Self.semanticInfo) }
    
    // MARK: - Scholar's Desk 特殊漸層
    
    /// AI 功能專用漸層
    var aiGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: Self.insightGreen), Color(hex: "#22D3EE")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 文獻庫專用漸層
    var libraryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: Self.inkBlue), Color(hex: "#1E3A5F")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
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

    var warningBackground: Color { warning.opacity(0.1) }

    var errorBackground: Color { error.opacity(0.1) }

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

#Preview("Scholar's Desk Theme") {
    let theme = AppTheme()
    
    VStack(spacing: 16) {
        // Scholar's Desk 主色系
        VStack(alignment: .leading, spacing: 8) {
            Text("Scholar's Desk 主色系").font(theme.titleFont()).foregroundStyle(theme.textPrimary)
            
            HStack(spacing: 12) {
                Circle().fill(theme.inkBlueColor).frame(width: 32, height: 32)
                Text("墨水藍 \(AppTheme.inkBlue)").foregroundStyle(theme.textSecondary)
            }
            
            HStack(spacing: 12) {
                Circle().fill(theme.parchmentGoldColor).frame(width: 32, height: 32)
                Text("羊皮紙金 \(AppTheme.parchmentGold)").foregroundStyle(theme.textSecondary)
            }
            
            HStack(spacing: 12) {
                Circle().fill(theme.insightGreenColor).frame(width: 32, height: 32)
                Text("啟發綠 \(AppTheme.insightGreen)").foregroundStyle(theme.textSecondary)
            }
        }
        
        Divider().background(theme.border)
        
        // 背景層次
        VStack(spacing: 8) {
            Text("背景層次").font(theme.titleFont(size: 14)).foregroundStyle(theme.textPrimary)
            
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.backgroundDeepColor).frame(width: 32, height: 32)
                Text("書房深處 \(AppTheme.backgroundDeep)").font(theme.captionFont())
            }
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.backgroundBaseColor).frame(width: 32, height: 32)
                Text("桌面 \(AppTheme.backgroundBase)").font(theme.captionFont())
            }
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.backgroundElevatedColor).frame(width: 32, height: 32)
                Text("卡片/面板 \(AppTheme.backgroundElevated)").font(theme.captionFont())
            }
            HStack {
                RoundedRectangle(cornerRadius: 8).fill(theme.backgroundSurfaceColor).frame(width: 32, height: 32)
                Text("互動元素 \(AppTheme.backgroundSurface)").font(theme.captionFont())
            }
        }
        .foregroundStyle(theme.textSecondary)
        
        Divider().background(theme.border)
        
        // 文字層次
        VStack(alignment: .leading, spacing: 4) {
            Text("文字層次").font(theme.titleFont(size: 14)).foregroundStyle(theme.textPrimary)
            Text("標題白 Heading").foregroundStyle(theme.textHeadingColor).font(theme.bodyFont())
            Text("正文灰 Body").foregroundStyle(theme.textBodyColor).font(theme.bodyFont())
            Text("次要灰 Muted").foregroundStyle(theme.textMutedColor).font(theme.captionFont())
            Text("禁用灰 Disabled").foregroundStyle(theme.textDisabledColor).font(theme.captionFont())
        }
        
        Divider().background(theme.border)
        
        // 特殊漸層
        VStack(spacing: 8) {
            Text("特殊漸層").font(theme.titleFont(size: 14)).foregroundStyle(theme.textPrimary)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.aiGradient)
                .frame(height: 32)
                .overlay(Text("AI 功能漸層").font(theme.captionFont()).foregroundStyle(.white))
            
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.libraryGradient)
                .frame(height: 32)
                .overlay(Text("文獻庫漸層").font(theme.captionFont()).foregroundStyle(.white))
        }
    }
    .padding(24)
    .background(theme.background)
    .clipShape(RoundedRectangle(cornerRadius: theme.radiusCard))
}
