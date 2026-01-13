//
//  EmeraldTheme.swift
//  OVEREND
//
//  Emerald UI 主題擴展
//

import SwiftUI

// MARK: - Emerald 主題常數

struct EmeraldTheme {
    // 主色
    static let primary = Color(hex: "#25f49d")
    static let primaryDark = Color(hex: "#059669")
    
    // 背景色
    static let backgroundDark = Color(hex: "#10221a")
    static let backgroundDeep = Color(hex: "#0f1512")
    static let surfaceDark = Color(hex: "#1c2e26")
    static let elevated = Color(hex: "#1b271f")
    
    // 文字
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#9cbaad")
    static let textMuted = Color(hex: "#6e8e7a")
    
    // 邊框
    static let border = Color.white.opacity(0.05)
    static let borderAccent = Color(hex: "#25f49d").opacity(0.2)
    
    // 玻璃效果
    static let glassBackground = Color(hex: "#10221a").opacity(0.6)
    static let glassBorder = Color(hex: "#25f49d").opacity(0.15)
}

// MARK: - 玻璃面板修飾符

struct GlassPanelModifier: ViewModifier {
    var isActive: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(EmeraldTheme.glassBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? EmeraldTheme.borderAccent : EmeraldTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func glassPanel(isActive: Bool = false) -> some View {
        modifier(GlassPanelModifier(isActive: isActive))
    }
}

// MARK: - 發光效果

struct GlowModifier: ViewModifier {
    var color: Color = EmeraldTheme.primary
    var radius: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius)
    }
}

extension View {
    func emeraldGlow(radius: CGFloat = 15) -> some View {
        modifier(GlowModifier(radius: radius))
    }
}

// MARK: - 懸停效果按鈕樣式

struct EmeraldButtonStyle: ButtonStyle {
    var isPrimary: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isPrimary ? EmeraldTheme.primary : Color.white.opacity(0.1))
            .foregroundColor(isPrimary ? EmeraldTheme.backgroundDark : .white)
            .fontWeight(isPrimary ? .bold : .medium)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: isPrimary ? EmeraldTheme.primary.opacity(0.3) : .clear, radius: 10)
    }
}

// MARK: - Material Symbol (使用 SF Symbols 替代)

struct MaterialIcon: View {
    let name: String
    var size: CGFloat = 20
    var color: Color = EmeraldTheme.textSecondary
    
    // SF Symbols 對應表
    private var sfSymbolName: String {
        switch name {
        case "menu_book": return "book.closed"
        case "library_books": return "books.vertical"
        case "search": return "magnifyingglass"
        case "schedule": return "clock"
        case "star": return "star"
        case "warning": return "exclamationmark.triangle"
        case "folder": return "folder"
        case "folder_open": return "folder.badge.gearshape"
        case "add": return "plus"
        case "tune": return "slider.horizontal.3"
        case "sort": return "arrow.up.arrow.down"
        case "ios_share": return "square.and.arrow.up"
        case "article": return "doc.text"
        case "edit": return "pencil"
        case "delete": return "trash"
        case "picture_as_pdf": return "doc.richtext"
        case "link": return "link"
        case "download": return "arrow.down.circle"
        case "cloud_sync": return "arrow.triangle.2.circlepath.icloud"
        case "cloud_done": return "checkmark.icloud"
        case "diamond": return "diamond"
        case "chevron_right": return "chevron.right"
        case "subdirectory_arrow_right": return "arrow.turn.down.right"
        case "format_bold": return "bold"
        case "format_italic": return "italic"
        case "format_underlined": return "underline"
        case "format_quote": return "quote.opening"
        case "format_list_bulleted": return "list.bullet"
        case "school": return "graduationcap"
        case "auto_stories": return "book"
        case "edit_note": return "note.text"
        case "settings": return "gearshape"
        case "keyboard_arrow_up": return "chevron.up"
        case "keyboard_arrow_down": return "chevron.down"
        case "ink_highlighter": return "highlighter"
        case "sticky_note_2": return "note"
        case "remove": return "minus"
        case "close": return "xmark"
        case "add_circle": return "plus.circle"
        case "drag_indicator": return "line.3.horizontal"
        default: return name
        }
    }
    
    var body: some View {
        Image(systemName: sfSymbolName)
            .font(.system(size: size))
            .foregroundColor(color)
    }
}

// MARK: - 漸層色彩

extension EmeraldTheme {
    static let gradientPrimary = LinearGradient(
        colors: [primary, Color(hex: "#1ed97f")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientBackground = LinearGradient(
        colors: [Color(hex: "#102a20"), Color(hex: "#050a08")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientAccent = LinearGradient(
        colors: [primary.opacity(0.3), primary.opacity(0.1), .clear],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - 脈動發光效果

struct PulseGlowModifier: ViewModifier {
    @State private var isAnimating = false
    var color: Color = EmeraldTheme.primary
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isAnimating ? 0.6 : 0.2), radius: isAnimating ? 20 : 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func pulseGlow(color: Color = EmeraldTheme.primary) -> some View {
        modifier(PulseGlowModifier(color: color))
    }
}

// MARK: - 流光效果

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        EmeraldTheme.primary.opacity(0.3),
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

struct EmeraldCardModifier: ViewModifier {
    var isHovered: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(EmeraldTheme.surfaceDark.opacity(isHovered ? 0.8 : 0.6))
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovered ? EmeraldTheme.borderAccent : EmeraldTheme.border, lineWidth: 1)
            )
            .shadow(color: isHovered ? EmeraldTheme.primary.opacity(0.2) : .clear, radius: 15)
    }
}

extension View {
    func emeraldCard(isHovered: Bool = false) -> some View {
        modifier(EmeraldCardModifier(isHovered: isHovered))
    }
}

// MARK: - 打字機指示器

struct TypingIndicator: View {
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(EmeraldTheme.primary)
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
