//
//  ScholarTheme.swift
//  OVEREND
//
//  Scholar's Desk 主題擴展
//  提供便捷的設計系統存取方法和專用樣式
//

import SwiftUI

/// Scholar's Desk 主題擴展
/// 提供便捷的顏色、樣式存取方法
extension AppTheme {
    
    // MARK: - Scholar's Desk 快捷存取
    
    /// Scholar's Desk 主色系便捷存取
    struct ScholarColors {
        let theme: AppTheme
        
        var inkBlue: Color { theme.inkBlueColor }
        var parchmentGold: Color { theme.parchmentGoldColor }
        var insightGreen: Color { theme.insightGreenColor }
        
        var backgroundDeep: Color { theme.backgroundDeepColor }
        var backgroundBase: Color { theme.backgroundBaseColor }
        var backgroundElevated: Color { theme.backgroundElevatedColor }
        var backgroundSurface: Color { theme.backgroundSurfaceColor }
        
        var textHeading: Color { theme.textHeadingColor }
        var textBody: Color { theme.textBodyColor }
        var textMuted: Color { theme.textMutedColor }
        var textDisabled: Color { theme.textDisabledColor }
    }
    
    /// 取得 Scholar's Desk 色彩
    var scholar: ScholarColors {
        ScholarColors(theme: self)
    }
    
    // MARK: - AI 功能專用樣式
    
    /// AI 功能專用樣式集合
    struct AIStyles {
        let theme: AppTheme
        
        /// AI 主色
        var accentColor: Color { theme.insightGreenColor }
        
        /// AI 背景漸層
        var backgroundGradient: LinearGradient { theme.aiGradient }
        
        /// AI 卡片背景
        var cardBackground: Color {
            theme.backgroundElevatedColor.overlay(
                theme.insightGreenColor.opacity(0.05)
            )
        }
        
        /// AI 邊框色
        var borderColor: Color { theme.insightGreenColor.opacity(0.3) }
        
        /// AI 按鈕樣式
        func buttonStyle() -> some View {
            EmptyView()
                .buttonStyle(AIButtonStyle())
        }
    }
    
    /// 取得 AI 樣式
    var ai: AIStyles {
        AIStyles(theme: self)
    }
    
    // MARK: - 文獻庫專用樣式
    
    /// 文獻庫專用樣式集合
    struct LibraryStyles {
        let theme: AppTheme
        
        /// 文獻庫主色
        var accentColor: Color { theme.inkBlueColor }
        
        /// 文獻庫背景漸層
        var backgroundGradient: LinearGradient { theme.libraryGradient }
        
        /// 文獻庫卡片背景
        var cardBackground: Color {
            theme.backgroundElevatedColor.overlay(
                theme.inkBlueColor.opacity(0.05)
            )
        }
        
        /// 文獻庫邊框色
        var borderColor: Color { theme.inkBlueColor.opacity(0.2) }
        
        /// 重要標記色（使用羊皮紙金）
        var highlightColor: Color { theme.parchmentGoldColor }
    }
    
    /// 取得文獻庫樣式
    var library: LibraryStyles {
        LibraryStyles(theme: self)
    }
    
    // MARK: - 編輯器專用樣式
    
    /// 編輯器專用樣式集合
    struct EditorStyles {
        let theme: AppTheme
        
        /// 編輯器背景
        var background: Color { theme.backgroundDeepColor }
        
        /// 編輯器文字色
        var textColor: Color { theme.textBodyColor }
        
        /// 編輯器標題色
        var headingColor: Color { theme.textHeadingColor }
        
        /// 編輯器選取背景
        var selectionBackground: Color { theme.inkBlueColor.opacity(0.2) }
        
        /// 編輯器行號色
        var lineNumberColor: Color { theme.textMutedColor }
        
        /// 編輯器邊框
        var borderColor: Color { theme.border }
    }
    
    /// 取得編輯器樣式
    var editor: EditorStyles {
        EditorStyles(theme: self)
    }
}

// MARK: - AI 按鈕樣式

/// AI 功能專用按鈕樣式
struct AIButtonStyle: ButtonStyle {
    @EnvironmentObject private var theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignTokens.SpacingV2.md)
            .padding(.vertical, DesignTokens.SpacingV2.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadiusV2.md)
                    .fill(theme.aiGradient)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundStyle(.white)
            .font(DesignTokens.TypographyV2.labelLarge)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignTokens.AnimationV2.quick, value: configuration.isPressed)
    }
}

// MARK: - 使用範例

/*
 使用範例：
 
 // 1. 使用 Scholar's Desk 色彩
 Text("標題")
     .foregroundStyle(theme.scholar.textHeading)
     .background(theme.scholar.backgroundElevated)
 
 // 2. 使用 AI 樣式
 VStack {
     Text("AI 分析")
         .foregroundStyle(theme.ai.accentColor)
 }
 .background(theme.ai.cardBackground)
 .overlay(
     RoundedRectangle(cornerRadius: 12)
         .stroke(theme.ai.borderColor, lineWidth: 1)
 )
 
 // 3. 使用文獻庫樣式
 HStack {
     Image(systemName: "book")
     Text("我的文獻")
 }
 .foregroundStyle(theme.library.accentColor)
 .padding()
 .background(theme.library.cardBackground)
 
 // 4. 使用編輯器樣式
 TextEditor(text: $content)
     .foregroundStyle(theme.editor.textColor)
     .background(theme.editor.background)
 
 // 5. 使用 AI 按鈕
 Button("AI 輔助") {
     // Action
 }
 .buttonStyle(AIButtonStyle())
 .environmentObject(theme)
 
 */
