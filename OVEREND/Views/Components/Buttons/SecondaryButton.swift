//
//  SecondaryButton.swift
//  OVEREND
//
//  次要操作按鈕 - 用於次要操作（取消、關閉、編輯等）
//

import SwiftUI

/// 次要操作按鈕
/// 特點：透明背景 + 邊框 + 主題文字顏色
struct SecondaryButton: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false
    var fullWidth: Bool = false
    var size: ButtonSize = .medium

    // MARK: - 狀態

    @State private var isHovered = false
    @State private var isPressed = false

    // MARK: - 初始化

    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.size = size
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }
                Text(title)
                    .font(.system(size: size.fontSize, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .stroke(borderColor, lineWidth: borderWidth)
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
    }

    // MARK: - 計算屬性

    /// 縮放比例
    private var scale: CGFloat {
        if isPressed {
            return 0.96
        } else if isHovered {
            return 1.02
        } else {
            return 1.0
        }
    }

    /// 文字顏色
    private var textColor: Color {
        isDisabled ? theme.textDisabled : theme.textPrimary
    }

    /// 背景顏色
    private var backgroundColor: Color {
        if isDisabled {
            return Color.clear
        } else if isHovered {
            return theme.itemHover
        } else {
            return Color.clear
        }
    }

    /// 邊框顏色
    private var borderColor: Color {
        if isDisabled {
            return theme.border.opacity(0.5)
        } else if isHovered {
            return theme.accent
        } else {
            return theme.border
        }
    }

    /// 邊框寬度
    private var borderWidth: CGFloat {
        isHovered ? 1.5 : 1
    }
}

// MARK: - 預覽

#Preview("Secondary Buttons") {
    VStack(spacing: 20) {
        let theme = AppTheme()

        // 標準按鈕
        SecondaryButton("取消", icon: "xmark") {
            print("取消")
        }
        .environmentObject(theme)

        // 無圖標
        SecondaryButton("編輯") {
            print("編輯")
        }
        .environmentObject(theme)

        // 全寬按鈕
        SecondaryButton("匯出", icon: "square.and.arrow.up", fullWidth: true) {
            print("匯出")
        }
        .environmentObject(theme)

        // 禁用狀態
        SecondaryButton("已禁用", icon: "xmark", isDisabled: true) {
            print("不會執行")
        }
        .environmentObject(theme)

        // 不同尺寸
        HStack(spacing: 12) {
            SecondaryButton("小", size: .small) {
                print("小按鈕")
            }
            .environmentObject(theme)

            SecondaryButton("中", size: .medium) {
                print("中按鈕")
            }
            .environmentObject(theme)

            SecondaryButton("大", size: .large) {
                print("大按鈕")
            }
            .environmentObject(theme)
        }

        // 組合使用
        HStack(spacing: 12) {
            SecondaryButton("取消") {
                print("取消")
            }
            .environmentObject(theme)

            PrimaryButton("確認", icon: "checkmark") {
                print("確認")
            }
            .environmentObject(theme)
        }
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Dark Mode") {
    let theme = AppTheme()
    theme.isDarkMode = true

    return VStack(spacing: 20) {
        SecondaryButton("取消", icon: "xmark") {
            print("取消")
        }
        .environmentObject(theme)

        SecondaryButton("匯出", icon: "square.and.arrow.up", fullWidth: true) {
            print("匯出")
        }
        .environmentObject(theme)

        SecondaryButton("已禁用", isDisabled: true) {
            print("不會執行")
        }
        .environmentObject(theme)

        HStack(spacing: 12) {
            SecondaryButton("取消") {
                print("取消")
            }
            .environmentObject(theme)

            PrimaryButton("確認", icon: "checkmark") {
                print("確認")
            }
            .environmentObject(theme)
        }
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
