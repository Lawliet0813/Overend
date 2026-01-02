//
//  IconButton.swift
//  OVEREND
//
//  純圖標按鈕 - 用於工具列和緊湊界面
//

import SwiftUI

/// 圖標按鈕
struct IconButton: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let icon: String
    let action: () -> Void
    var size: ButtonSize = .medium
    var style: IconButtonStyle = .standard
    var isDisabled: Bool = false
    var tooltip: String? = nil

    // MARK: - 狀態

    @State private var isHovered = false
    @State private var isPressed = false

    // MARK: - 樣式

    enum IconButtonStyle {
        case standard    // 標準樣式
        case subtle      // 微妙樣式（更低調）
        case accent      // 強調色
        case destructive // 危險操作（紅色）
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .scaleEffect(scale)
        .animation(AnimationSystem.Easing.quick, value: isHovered)
        .animation(AnimationSystem.Easing.instant, value: isPressed)
        .onHover { hovering in
            if !isDisabled {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .help(tooltip ?? "")
    }

    // MARK: - 計算屬性

    /// 按鈕大小
    private var buttonSize: CGFloat {
        switch size {
        case .small: return 28
        case .medium: return 32
        case .large: return 40
        }
    }

    /// 縮放比例
    private var scale: CGFloat {
        if isPressed {
            return 0.92
        } else if isHovered {
            return 1.05
        } else {
            return 1.0
        }
    }

    /// 圖標顏色
    private var iconColor: Color {
        if isDisabled {
            return theme.textDisabled
        }

        switch style {
        case .standard:
            return isHovered ? theme.accent : theme.textPrimary
        case .subtle:
            return isHovered ? theme.textPrimary : theme.textMuted
        case .accent:
            return theme.accent
        case .destructive:
            return isHovered ? theme.destructive : theme.textPrimary
        }
    }

    /// 背景顏色
    private var backgroundColor: Color {
        if isDisabled {
            return Color.clear
        }

        if !isHovered {
            return Color.clear
        }

        switch style {
        case .standard, .subtle:
            return theme.itemHover
        case .accent:
            return theme.accent.opacity(0.1)
        case .destructive:
            return theme.destructive.opacity(0.1)
        }
    }
}

// MARK: - 預覽

#Preview("Icon Buttons") {
    VStack(spacing: 24) {
        let theme = AppTheme()

        // 標準樣式
        VStack(alignment: .leading, spacing: 12) {
            Text("標準樣式")
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 12) {
                IconButton(icon: "star", action: { print("Star") })
                    .environmentObject(theme)

                IconButton(icon: "heart", action: { print("Heart") })
                    .environmentObject(theme)

                IconButton(icon: "bookmark", action: { print("Bookmark") })
                    .environmentObject(theme)

                IconButton(icon: "share", action: { print("Share") })
                    .environmentObject(theme)
            }
        }

        // 不同尺寸
        VStack(alignment: .leading, spacing: 12) {
            Text("尺寸")
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 12) {
                IconButton(icon: "gear", action: {}, size: .small)
                    .environmentObject(theme)

                IconButton(icon: "gear", action: {}, size: .medium)
                    .environmentObject(theme)

                IconButton(icon: "gear", action: {}, size: .large)
                    .environmentObject(theme)
            }
        }

        // 不同樣式
        VStack(alignment: .leading, spacing: 12) {
            Text("樣式")
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 12) {
                IconButton(icon: "checkmark", action: {}, style: .standard)
                    .environmentObject(theme)

                IconButton(icon: "ellipsis", action: {}, style: .subtle)
                    .environmentObject(theme)

                IconButton(icon: "plus", action: {}, style: .accent)
                    .environmentObject(theme)

                IconButton(icon: "trash", action: {}, style: .destructive)
                    .environmentObject(theme)
            }
        }

        // 禁用狀態
        VStack(alignment: .leading, spacing: 12) {
            Text("禁用狀態")
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 12) {
                IconButton(icon: "arrow.left", action: {}, isDisabled: true)
                    .environmentObject(theme)

                IconButton(icon: "arrow.right", action: {}, isDisabled: true)
                    .environmentObject(theme)
            }
        }
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Dark Mode") {
    DarkModePreviewWrapper()
}

private struct DarkModePreviewWrapper: View {
    let theme = AppTheme()
    
    init() {
        theme.isDarkMode = true
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                IconButton(icon: "star", action: {})
                    .environmentObject(theme)

                IconButton(icon: "heart", action: {}, style: .accent)
                    .environmentObject(theme)

                IconButton(icon: "trash", action: {}, style: .destructive)
                    .environmentObject(theme)
            }

            HStack(spacing: 12) {
                IconButton(icon: "gear", action: {}, size: .small)
                    .environmentObject(theme)

                IconButton(icon: "gear", action: {}, size: .medium)
                    .environmentObject(theme)

                IconButton(icon: "gear", action: {}, size: .large)
                    .environmentObject(theme)
            }
        }
        .padding(40)
        .frame(width: 400)
        .background(Color(hex: "#1e1e1e"))
    }
}
