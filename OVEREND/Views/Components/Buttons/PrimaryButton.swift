//
//  PrimaryButton.swift
//  OVEREND
//
//  主要操作按鈕 - 用於主要操作（新增、確認、保存等）
//

import SwiftUI

/// 主要操作按鈕
/// 特點：綠色背景 + 白色文字 + 發光陰影效果
struct PrimaryButton: View {
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
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundColor(isDisabled ? theme.textDisabled : .white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(isDisabled ? theme.buttonDisabled : theme.accent)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
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

    /// 陰影顏色
    private var shadowColor: Color {
        if isDisabled {
            return .clear
        } else if isHovered {
            return theme.accent.opacity(0.4)
        } else {
            return DesignTokens.Shadow.level2.color
        }
    }

    /// 陰影半徑
    private var shadowRadius: CGFloat {
        if isDisabled {
            return 0
        } else if isHovered {
            return 12
        } else {
            return DesignTokens.Shadow.level2.radius
        }
    }

    /// 陰影 Y 偏移
    private var shadowY: CGFloat {
        if isDisabled {
            return 0
        } else if isHovered {
            return 6
        } else {
            return DesignTokens.Shadow.level2.y
        }
    }
}

// MARK: - 按鈕尺寸

enum ButtonSize {
    case small
    case medium
    case large

    var fontSize: CGFloat {
        switch self {
        case .small: return DesignTokens.Typography.callout
        case .medium: return DesignTokens.Typography.body
        case .large: return DesignTokens.Typography.headline
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return DesignTokens.IconSize.small
        case .medium: return DesignTokens.IconSize.medium
        case .large: return DesignTokens.IconSize.large
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DesignTokens.Spacing.sm
        case .medium: return DesignTokens.Spacing.md
        case .large: return DesignTokens.Spacing.lg
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return DesignTokens.Spacing.xs
        case .medium: return DesignTokens.Spacing.sm
        case .large: return DesignTokens.Spacing.md
        }
    }
}

// MARK: - 預覽

#Preview("Primary Buttons") {
    VStack(spacing: 20) {
        let theme = AppTheme()

        // 標準按鈕
        PrimaryButton("保存", icon: "checkmark") {
            print("保存")
        }
        .environmentObject(theme)

        // 無圖標
        PrimaryButton("確認") {
            print("確認")
        }
        .environmentObject(theme)

        // 全寬按鈕
        PrimaryButton("新增文獻", icon: "plus", fullWidth: true) {
            print("新增")
        }
        .environmentObject(theme)

        // 禁用狀態
        PrimaryButton("已禁用", icon: "xmark", isDisabled: true) {
            print("不會執行")
        }
        .environmentObject(theme)

        // 不同尺寸
        HStack(spacing: 12) {
            PrimaryButton("小", size: .small) {
                print("小按鈕")
            }
            .environmentObject(theme)

            PrimaryButton("中", size: .medium) {
                print("中按鈕")
            }
            .environmentObject(theme)

            PrimaryButton("大", size: .large) {
                print("大按鈕")
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
        PrimaryButton("保存", icon: "checkmark") {
            print("保存")
        }
        .environmentObject(theme)

        PrimaryButton("新增文獻", icon: "plus", fullWidth: true) {
            print("新增")
        }
        .environmentObject(theme)

        PrimaryButton("已禁用", isDisabled: true) {
            print("不會執行")
        }
        .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
