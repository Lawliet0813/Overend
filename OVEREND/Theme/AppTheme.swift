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
    
    // MARK: - 主色系
    
    /// 主色（綠色）
    var accent: Color { Color(hex: "#00D97E") }
    
    /// 淺色主色（用於背景）
    var accentLight: Color { accent.opacity(0.1) }
    
    // MARK: - 背景色
    
    var background: Color {
        isDarkMode ? Color(hex: "#1e1e1e") : Color(hex: "#e5e5e5")
    }
    
    var sidebar: Color {
        isDarkMode ? Color(hex: "#252525").opacity(0.8) : Color(hex: "#f3f3f3").opacity(0.9)
    }
    
    var toolbar: Color {
        isDarkMode ? Color(hex: "#2a2a2a") : .white
    }
    
    var page: Color {
        isDarkMode ? Color(hex: "#2a2a2a") : .white
    }
    
    var card: Color {
        isDarkMode ? Color.white.opacity(0.05) : .white
    }
    
    // MARK: - 文字色
    
    var textPrimary: Color {
        isDarkMode ? Color(hex: "#ececec") : Color(hex: "#1a1a1a")
    }
    
    var textMuted: Color {
        isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.65)
    }
    
    var textOnAccent: Color { .white }
    
    // MARK: - 邊框色
    
    var border: Color {
        isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.1)
    }
    
    // MARK: - 互動色
    
    var itemHover: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }
    
    var tableRowHover: Color {
        isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02)
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
        isDarkMode ? .ultraThinMaterial : .thinMaterial
    }
    
    /// 側邊欄玻璃
    var sidebarGlass: Color {
        isDarkMode 
            ? Color.white.opacity(0.05) 
            : Color.white.opacity(0.7)
    }
    
    /// 卡片玻璃
    var cardGlass: Color {
        isDarkMode 
            ? Color.white.opacity(0.08) 
            : Color.white.opacity(0.85)
    }
    
    /// 工具列玻璃
    var toolbarGlass: Color {
        isDarkMode 
            ? Color.white.opacity(0.06) 
            : Color.white.opacity(0.9)
    }
    
    /// 光暈顏色
    var glowColor: Color {
        accent.opacity(0.3)
    }
    
    /// 玻璃邊框
    var glassBorder: Color {
        isDarkMode 
            ? Color.white.opacity(0.15) 
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

