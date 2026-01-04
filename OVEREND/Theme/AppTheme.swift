//
//  AppTheme.swift
//  OVEREND
//
//  主題系統 - 深色模式專用
//

import SwiftUI
import Combine

/// 應用程式主題（深色模式專用）
class AppTheme: ObservableObject {
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
        ("🏳️‍🌈 彩虹驕傲", "#E40303", true)
    ]
    
    /// Pride 漸層顏色
    static let prideGradientColors: [Color] = [
        Color(hex: "#E40303"),
        Color(hex: "#FF8C00"),
        Color(hex: "#FFED00"),
        Color(hex: "#008026"),
        Color(hex: "#24408E"),
        Color(hex: "#732982"),
        Color(hex: "#E40303")
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
    
    // MARK: - 主色系
    
    /// 主色（可自訂）
    var accent: Color { Color(hex: accentHex) }
    
    /// 淺色主色（用於背景）
    var accentLight: Color { accent.opacity(0.1) }
    
    // MARK: - 背景色（深色模式）
    
    /// 主背景 - Dark Slate Blue
    var background: Color { Color(hex: "#252F3F") }
    
    /// 側邊欄背景
    var sidebar: Color { Color(hex: "#1F2937").opacity(0.9) }
    
    /// 工具列背景
    var toolbar: Color { Color(hex: "#252F3F").opacity(0.8) }
    
    /// 頁面背景
    var page: Color { Color(hex: "#252F3F") }
    
    /// 卡片背景
    var card: Color { Color(hex: "#374151").opacity(0.5) }
    
    // MARK: - 文字色（深色模式）
    
    /// 主要文字 - 柔和白色
    var textPrimary: Color { Color(hex: "#F3F4F6") }
    
    /// 次要文字 - 灰色
    var textMuted: Color { Color(hex: "#9CA3AF") }
    
    /// 強調文字（用於主色背景）
    var textOnAccent: Color { .white }
    
    /// 次要文字色
    var textSecondary: Color { Color.white.opacity(0.7) }
    
    /// 禁用文字色
    var textDisabled: Color { Color.white.opacity(0.3) }
    
    // MARK: - 邊框色
    
    var border: Color { Color.white.opacity(0.1) }
    
    // MARK: - 互動色
    
    var itemHover: Color { Color.white.opacity(0.1) }
    
    var tableRowHover: Color { Color(hex: "#374151").opacity(0.3) }

    // MARK: - 語義化顏色

    var success: Color { Color(hex: "#00D97E") }
    var successBackground: Color { success.opacity(0.1) }

    var warning: Color { Color(hex: "#FF9800") }
    var warningBackground: Color { warning.opacity(0.1) }

    var error: Color { Color(hex: "#F44336") }
    var errorBackground: Color { error.opacity(0.1) }

    var info: Color { Color(hex: "#2196F3") }
    var infoBackground: Color { info.opacity(0.1) }

    var destructive: Color { Color(hex: "#DC3545") }
    var destructiveBackground: Color { destructive.opacity(0.1) }

    // MARK: - 互動狀態顏色

    var buttonDisabled: Color { Color.white.opacity(0.2) }
    var focusBorder: Color { accent }
    var selectedBackground: Color { accent.opacity(0.2) }
    var link: Color { info }
    var divider: Color { Color.white.opacity(0.08) }
    
    // MARK: - 字體尺寸系統
    
    var fontXLarge: CGFloat { 28 }
    var fontLarge: CGFloat { 22 }
    var fontMedium: CGFloat { 18 }
    var fontBody: CGFloat { 15 }
    var fontCaption: CGFloat { 13 }
    var fontMini: CGFloat { 11 }
    
    // MARK: - 字體樣式
    
    func titleFont(size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold)
    }
    
    func bodyFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }
    
    func captionFont(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular)
    }
    
    // MARK: - macOS 26 液態玻璃效果（深色模式）
    
    var glassMaterial: Material { .regular }
    
    var sidebarGlass: Color { Color(hex: "#1F2937").opacity(0.6) }
    
    var cardGlass: Color { Color(hex: "#374151").opacity(0.4) }
    
    var toolbarGlass: Color { Color(hex: "#252F3F").opacity(0.7) }
    
    var glowColor: Color { accent.opacity(0.3) }
    
    var glassBorder: Color { Color.white.opacity(0.1) }
    
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
    
    // MARK: - 向後兼容（保留 isDarkMode 屬性）
    
    /// 始終為深色模式
    var isDarkMode: Bool { true }
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

