//
//  CardView.swift
//  OVEREND
//
//  標準卡片組件 - 可復用的卡片容器
//

import SwiftUI

/// 標準卡片組件
/// 特點：圓角 + 背景 + 邊框 + 可選陰影
struct CardView<Content: View>: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var shadowLevel: Int
    var borderWidth: CGFloat
    var showBorder: Bool

    // MARK: - 初始化

    init(
        padding: CGFloat = DesignTokens.Spacing.md,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        shadowLevel: Int = 2,
        borderWidth: CGFloat = 0.5,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowLevel = shadowLevel
        self.borderWidth = borderWidth
        self.showBorder = showBorder
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.card)
            )
            .overlay {
                if showBorder {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.border, lineWidth: borderWidth)
                }
            }
            .applyShadow(level: shadowLevel)
    }
}

/// 懸停卡片組件
/// 特點：懸停時有縮放和陰影提升效果
struct HoverCard<Content: View>: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var action: (() -> Void)?

    // MARK: - 狀態

    @State private var isHovered = false

    // MARK: - 初始化

    init(
        padding: CGFloat = DesignTokens.Spacing.md,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(AnimationSystem.Easing.quick, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var cardContent: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? theme.accent : theme.border, lineWidth: isHovered ? 1.5 : 0.5)
            )
            .applyShadow(level: isHovered ? 3 : 2)
    }
}

/// 玻璃效果卡片組件
/// 特點：毛玻璃效果背景
struct GlassCard<Content: View>: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var material: Material

    // MARK: - 初始化

    init(
        padding: CGFloat = DesignTokens.Spacing.md,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        material: Material? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.material = material ?? .regularMaterial
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - 預覽

#Preview("Standard Cards") {
    VStack(spacing: 20) {
        let theme = AppTheme()

        // 標準卡片
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("標準卡片")
                    .font(.system(size: 16, weight: .bold))
                Text("這是一個標準卡片組件，帶有背景、邊框和陰影。")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
            }
        }
        .environmentObject(theme)

        // 無邊框卡片
        CardView(showBorder: false) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("無邊框卡片")
                    .font(.system(size: 14))
            }
        }
        .environmentObject(theme)

        // 自訂間距和圓角
        CardView(padding: 24, cornerRadius: 16, shadowLevel: 3) {
            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
                Text("自訂卡片")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Hover Cards") {
    VStack(spacing: 20) {
        let theme = AppTheme()

        // 可點擊的懸停卡片
        HoverCard(action: {
            print("卡片被點擊")
        }) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("文獻標題")
                        .font(.system(size: 15, weight: .semibold))
                    Text("作者名稱 · 2024")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
        .environmentObject(theme)

        // 僅懸停效果（不可點擊）
        HoverCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("懸停卡片")
                    .font(.system(size: 16, weight: .bold))
                Text("滑鼠懸停查看效果")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Glass Cards") {
    ZStack {
        // 背景漸層
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            let theme = AppTheme()

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("玻璃卡片")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("毛玻璃效果背景")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .environmentObject(theme)

            GlassCard(material: .ultraThinMaterial) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)

                    Text("超薄玻璃")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
            }
            .environmentObject(theme)
        }
        .padding(40)
    }
    .frame(width: 400, height: 500)
}

#Preview("Dark Mode") {
    let theme = AppTheme()
    
    VStack(spacing: 20) {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("深色模式卡片")
                    .font(.system(size: 16, weight: .bold))
                Text("在深色模式下的外觀")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
            }
        }
        .environmentObject(theme)

        HoverCard(action: {
            print("點擊")
        }) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.blue)
                Text("懸停查看效果")
                    .font(.system(size: 15))
            }
        }
        .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
