//
//  LiquidGlassModifiers.swift
//  OVEREND
//
//  macOS 26 液態玻璃效果修飾器
//

import SwiftUI

// MARK: - 液態玻璃修飾器

/// 液態玻璃卡片效果
struct LiquidGlassCard: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    var cornerRadius: CGFloat = 16
    var showGlow: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 毛玻璃底層
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.cardGlass)
                        .background(theme.glassMaterial)
                    
                    // 液態漸層
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.liquidGradient)
                        .opacity(0.5)
                    
                    // 頂部高光
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(lineWidth: 2)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 1)
            )
            .shadow(color: showGlow ? theme.glowColor : .clear, radius: 20, x: 0, y: 8)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

/// 液態玻璃側邊欄
struct LiquidGlassSidebar: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                // 使用主題定義的液態漸層
                theme.liquidGradient
                    .opacity(theme.isPrideMode ? 0.1 : 1.0) // Pride 模式下稍微降低不透明度以免太花
            )
    }
}

/// 液態玻璃按鈕
struct LiquidGlassButton: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    var isActive: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isActive {
                        if theme.isPrideMode {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.prideGradient)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.accent)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.cardGlass)
                            .background(.ultraThinMaterial)
                    }
                    
                    // 高光
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isActive ? 0.3 : 0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 20)
                                .offset(y: -10)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isActive ? Color.white.opacity(0.3) : theme.glassBorder,
                        lineWidth: 1
                    )
            )
            .shadow(color: isActive ? (theme.isPrideMode ? Color.purple.opacity(0.4) : theme.accent.opacity(0.4)) : .clear, radius: 8, x: 0, y: 4)
    }
}

/// 液態玻璃工具列
struct LiquidGlassToolbar: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    theme.toolbarGlass
                        .background(theme.glassMaterial)
                    
                    // 底部邊框
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(theme.glassBorder)
                            .frame(height: 1)
                    }
                }
            )
    }
}

// MARK: - View 擴展

extension View {
    /// 套用液態玻璃卡片效果
    func liquidGlassCard(cornerRadius: CGFloat = 16, showGlow: Bool = false) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius, showGlow: showGlow))
    }
    
    /// 套用液態玻璃側邊欄效果
    func liquidGlassSidebar() -> some View {
        modifier(LiquidGlassSidebar())
    }
    
    /// 套用液態玻璃按鈕效果
    func liquidGlassButton(isActive: Bool = false) -> some View {
        modifier(LiquidGlassButton(isActive: isActive))
    }
    
    /// 套用液態玻璃工具列效果
    func liquidGlassToolbar() -> some View {
        modifier(LiquidGlassToolbar())
    }
}

// MARK: - 預覽

#Preview {
    VStack(spacing: 20) {
        Text("液態玻璃卡片")
            .padding(20)
            .liquidGlassCard(showGlow: true)
        
        Text("液態玻璃按鈕")
            .liquidGlassButton(isActive: false)
        
        Text("活動按鈕")
            .liquidGlassButton(isActive: true)
    }
    .padding(40)
    .frame(width: 400, height: 300)
    .background(
        LinearGradient(
            colors: [.purple, .blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environmentObject(AppTheme())
}
