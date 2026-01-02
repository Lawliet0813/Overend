//
//  AppTheme.swift
//  OVEREND
//
//  主題系統 - 深色/淺色模式顏色定義
//

import SwiftUI
import Combine

/// 應用程式主題
class AppTheme: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var accentHex: String = "#007AFF" {
        didSet {
            UserDefaults.standard.set(accentHex, forKey: "appAccentColor")
        }
    }
    
    /// 預設主題色選項
    static let presetColors: [(name: String, hex: String, isGradient: Bool)] = [
        ("Apple 藍", "#007AFF", false),
        ("翠綠色", "#00D97E", false),
        ("紫羅蘭", "#AF52DE", false),
        ("珊瑚紅", "#FF6B6B", false),
        ("琥珀橙", "#FF9500", false),
        ("靛青藍", "#5856D6", false),
        ("湖水綠", "#34C759", false),
        ("玫瑰粉", "#FF2D55", false),
        ("青檸色", "#A8E063", false),
        ("深海藍", "#1E3A5F", false),
        ("🏳️‍🌈 彩虹驕傲", "#E40303", true)  // 使用紅色作為代表色，UI 會顯示漸層
    ]
    
    /// Pride 漸層顏色（增強版）
    static let prideGradientColors: [Color] = [
        Color(hex: "#E40303"),  // 紅
        Color(hex: "#FF8C00"),  // 橙
        Color(hex: "#FFED00"),  // 黃
        Color(hex: "#008026"),  // 綠
        Color(hex: "#24408E"),  // 藍
        Color(hex: "#732982"),  // 紫
        Color(hex: "#E40303")   // 回到紅（循環）
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
        // 從 UserDefaults 載入自訂顏色
        if let savedColor = UserDefaults.standard.string(forKey: "appAccentColor") {
            self.accentHex = savedColor
        }
    }
    
    // MARK: - 主色系
    
    /// 主色（可自訂）
    var accent: Color { Color(hex: accentHex) }
    
    /// 淺色主色（用於背景）
    var accentLight: Color { accent.opacity(0.1) }
    
    // MARK: - 背景色
    
    // MARK: - 背景色
    
    var background: Color {
        // Dark Slate Blue #252F3F
        isDarkMode ? Color(hex: "#252F3F") : Color(hex: "#F5F7FA")
    }
    
    var sidebar: Color {
        // Slightly darker/transparent for sidebar
        isDarkMode ? Color(hex: "#1F2937").opacity(0.9) : Color(hex: "#E5E7EB").opacity(0.9)
    }
    
    var toolbar: Color {
        // Matches background but with transparency for glass effect
        isDarkMode ? Color(hex: "#252F3F").opacity(0.8) : Color.white.opacity(0.9)
    }
    
    var page: Color {
        // Page background
        isDarkMode ? Color(hex: "#252F3F") : .white
    }
    
    var card: Color {
        // Lighter than background for cards
        isDarkMode ? Color(hex: "#374151").opacity(0.5) : .white
    }
    
    // MARK: - 文字色
    
    var textPrimary: Color {
        // Softer white for dark mode
        isDarkMode ? Color(hex: "#F3F4F6") : Color(hex: "#111827")
    }
    
    var textMuted: Color {
        // Muted slate for dark mode
        isDarkMode ? Color(hex: "#9CA3AF") : Color(hex: "#6B7280")
    }
    
    var textOnAccent: Color { .white }
    
    // MARK: - 邊框色
    
    var border: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
    
    // MARK: - 互動色

    var itemHover: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }

    var tableRowHover: Color {
        isDarkMode ? Color(hex: "#374151").opacity(0.3) : Color.black.opacity(0.02)
    }

    // MARK: - 語義化顏色

    /// 成功色
    var success: Color { Color(hex: "#00D97E") }

    /// 成功背景色
    var successBackground: Color { success.opacity(0.1) }

    /// 警告色
    var warning: Color { Color(hex: "#FF9800") }

    /// 警告背景色
    var warningBackground: Color { warning.opacity(0.1) }

    /// 錯誤色
    var error: Color { Color(hex: "#F44336") }

    /// 錯誤背景色
    var errorBackground: Color { error.opacity(0.1) }

    /// 資訊色
    var info: Color { Color(hex: "#2196F3") }

    /// 資訊背景色
    var infoBackground: Color { info.opacity(0.1) }

    /// 破壞性操作色（用於刪除等危險操作）
    var destructive: Color { Color(hex: "#DC3545") }

    /// 破壞性操作背景色
    var destructiveBackground: Color { destructive.opacity(0.1) }

    // MARK: - 互動狀態顏色

    /// 按鈕禁用狀態
    var buttonDisabled: Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2)
    }

    /// 輸入框聚焦邊框
    var focusBorder: Color { accent }

    /// 選中狀態背景
    var selectedBackground: Color {
        isDarkMode ? accent.opacity(0.2) : accent.opacity(0.15)
    }

    /// 次要文字色（用於副標題、說明文字）
    var textSecondary: Color {
        isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    /// 禁用文字色
    var textDisabled: Color {
        isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }

    /// 連結色
    var link: Color { info }

    /// 分隔線顏色
    var divider: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    
    // MARK: - 字體尺寸系統（整體加大）
    
    /// 特大標題（28pt）
    var fontXLarge: CGFloat { 28 }
    
    /// 大標題（22pt）
    var fontLarge: CGFloat { 22 }
    
    /// 中標題（18pt）
    var fontMedium: CGFloat { 18 }
    
    /// 正文（15pt）- 比預設 13pt 大
    var fontBody: CGFloat { 15 }
    
    /// 說明文字（13pt）
    var fontCaption: CGFloat { 13 }
    
    /// 小字（11pt）
    var fontMini: CGFloat { 11 }
    
    // MARK: - 字體樣式
    
    /// 標題字體
    func titleFont(size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold)
    }
    
    /// 正文字體
    func bodyFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }
    
    /// 說明文字字體
    func captionFont(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular)
    }
    
    // MARK: - macOS 26 液態玻璃效果
    
    /// 玻璃材質背景
    var glassMaterial: Material {
        isDarkMode ? .regular : .thin // Use correct Material cases
    }
    
    /// 側邊欄玻璃
    var sidebarGlass: Color {
        isDarkMode 
            ? Color(hex: "#1F2937").opacity(0.6) 
            : Color.white.opacity(0.7)
    }
    
    /// 卡片玻璃
    var cardGlass: Color {
        isDarkMode 
            ? Color(hex: "#374151").opacity(0.4) 
            : Color.white.opacity(0.85)
    }
    
    /// 工具列玻璃
    var toolbarGlass: Color {
        isDarkMode 
            ? Color(hex: "#252F3F").opacity(0.7) 
            : Color.white.opacity(0.9)
    }
    
    /// 光暈顏色
    var glowColor: Color {
        accent.opacity(0.3)
    }
    
    /// 玻璃邊框
    var glassBorder: Color {
        isDarkMode 
            ? Color.white.opacity(0.1) 
            : Color.white.opacity(0.8)
    }
    
    /// 液態漸層
    var liquidGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.15),
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 預覽

#Preview {
    VStack(spacing: 20) {
        let theme = AppTheme()
        
        HStack {
            Circle().fill(theme.accent).frame(width: 40)
            Text("主色 #00D97E")
        }
        
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.background)
                .frame(width: 40, height: 40)
            Text("背景色")
        }
        
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.sidebar)
                .frame(width: 40, height: 40)
            Text("側邊欄色")
        }
    }
    .padding()
}

