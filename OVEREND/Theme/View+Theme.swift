//
//  View+Theme.swift
//  OVEREND
//
//  視圖外觀修飾符 - 統一使用 AppTheme
//  遷移自 EmeraldTheme.swift
//

import SwiftUI

// MARK: - 分隔線修飾符

extension View {
    /// 底部細線分隔
    func emeraldBottomBorder() -> some View {
        self.overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    /// 頂部細線分隔
    func emeraldTopBorder() -> some View {
        self.overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    /// 右側細線分隔
    func emeraldRightBorder() -> some View {
        self.overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    /// 左側細線分隔
    func emeraldLeftBorder() -> some View {
        self.overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1),
            alignment: .leading
        )
    }
}

// MARK: - 玻璃面板修飾符

struct EmeraldGlassBackgroundModifier: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    var opacity: Double
    
    func body(content: Content) -> some View {
        content
            .background(theme.emeraldBackground.opacity(opacity))
            .background(.ultraThinMaterial)
    }
}

extension View {
    func emeraldGlassBackground(opacity: Double = 0.5) -> some View {
        modifier(EmeraldGlassBackgroundModifier(opacity: opacity))
    }
}

struct GlassPanelModifier: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    var isActive: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(theme.glassBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(isActive ? theme.accent.opacity(0.2) : theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }
}

extension View {
    func glassPanel(isActive: Bool = false) -> some View {
        modifier(GlassPanelModifier(isActive: isActive))
    }
}

// MARK: - 發光效果

struct GlowModifier: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    var color: Color?
    var radius: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .shadow(color: (color ?? theme.accent).opacity(0.4), radius: radius)
    }
}

extension View {
    func emeraldGlow(color: Color? = nil, radius: CGFloat = 15) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - 懸停效果按鈕樣式

struct ThemeButtonStyle: ButtonStyle {
    // 這裡我們無法直接訪問 EnvironmentObject，所以通常建議在 View 層級傳入或使用 ViewModifier
    // 但為了 ButtonStyle，我們可以使用 Configuration
    // 或是創建一個 ViewWrapper
    
    var theme: AppTheme
    var isPrimary: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isPrimary ? theme.accent : Color.white.opacity(0.1))
            .foregroundColor(isPrimary ? Color(hex: "#0A0A0A") : .white) // Assuming dark background for primary text
            .fontWeight(isPrimary ? .bold : .medium)
            .cornerRadius(DesignTokens.CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: isPrimary ? theme.accent.opacity(0.3) : .clear, radius: 10)
    }
}

// MARK: - 脈動發光效果

struct PulseGlowModifier: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    @State private var isAnimating = false
    var color: Color?
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: (color ?? theme.accent).opacity(isAnimating ? 0.6 : 0.2),
                radius: isAnimating ? 20 : 10
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func pulseGlow(color: Color? = nil) -> some View {
        modifier(PulseGlowModifier(color: color))
    }
}

// MARK: - 流光效果

struct ShimmerModifier: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        theme.accent.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - 浮動效果

struct FloatingModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    var amplitude: CGFloat = 5
    var duration: Double = 2
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    offset = amplitude
                }
            }
    }
}

extension View {
    func floating(amplitude: CGFloat = 5, duration: Double = 2) -> some View {
        modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
}

// MARK: - 懸停縮放效果

struct ScaleOnHoverModifier: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat = 1.05
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func scaleOnHover(_ scale: CGFloat = 1.05) -> some View {
        modifier(ScaleOnHoverModifier(scale: scale))
    }
}

// MARK: - 卡片容器樣式

struct ThemeCardModifier: ViewModifier {
    @EnvironmentObject var theme: AppTheme
    var isHovered: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(theme.surfaceDark.opacity(isHovered ? 0.8 : 0.6))
            .background(.ultraThinMaterial)
            .cornerRadius(DesignTokens.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(isHovered ? theme.accent.opacity(0.2) : theme.border, lineWidth: 1)
            )
            .shadow(color: isHovered ? theme.accent.opacity(0.2) : .clear, radius: 15)
    }
}

extension View {
    func emeraldCard(isHovered: Bool = false) -> some View {
        modifier(ThemeCardModifier(isHovered: isHovered))
    }
}

// MARK: - 打字機指示器

struct TypingIndicator: View {
    @EnvironmentObject var theme: AppTheme
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(theme.accent)
                    .frame(width: 8, height: 8)
                    .opacity(dotOpacity[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    dotOpacity[i] = 1.0
                }
            }
        }
    }
}

// MARK: - 互動式按鈕樣式

/// 增強的互動式按鈕樣式，提供視覺回饋
struct InteractiveButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: AppTheme
    var backgroundColor: Color?
    var foregroundColor: Color?
    var cornerRadius: CGFloat = 8
    var scaleEffect: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor ?? theme.surfaceDark)
            .foregroundColor(foregroundColor ?? theme.textPrimary)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    /// 應用互動式按鈕樣式
    func interactiveButtonStyle(
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self.buttonStyle(InteractiveButtonStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            cornerRadius: cornerRadius
        ))
    }
}
