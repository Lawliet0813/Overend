//
//  DestructiveButton.swift
//  OVEREND
//
//  破壞性操作按鈕 - 用於危險操作（刪除、清空、重置等）
//

import SwiftUI

/// 破壞性操作按鈕
/// 特點：紅色背景 + 白色文字 + 警告視覺效果
struct DestructiveButton: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false
    var fullWidth: Bool = false
    var size: ButtonSize = .medium
    var requiresConfirmation: Bool = true

    // MARK: - 狀態

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var showConfirmation = false

    // MARK: - 初始化

    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        size: ButtonSize = .medium,
        requiresConfirmation: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.size = size
        self.requiresConfirmation = requiresConfirmation
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isDisabled {
                if requiresConfirmation {
                    showConfirmation = true
                } else {
                    action()
                }
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
                    .fill(backgroundColor)
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
        .alert("確認操作", isPresented: $showConfirmation) {
            Button("取消", role: .cancel) {}
            Button("確認\(title)", role: .destructive) {
                action()
            }
        } message: {
            Text("此操作無法撤銷，確定要繼續嗎？")
        }
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

    /// 背景顏色
    private var backgroundColor: Color {
        if isDisabled {
            return theme.buttonDisabled
        } else if isHovered {
            return theme.destructive.opacity(0.9)
        } else {
            return theme.destructive
        }
    }

    /// 陰影顏色
    private var shadowColor: Color {
        if isDisabled {
            return .clear
        } else if isHovered {
            return theme.destructive.opacity(0.4)
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

// MARK: - 預覽

#Preview("Destructive Buttons") {
    VStack(spacing: 20) {
        let theme = AppTheme()

        // 標準刪除按鈕（需要確認）
        DestructiveButton("刪除", icon: "trash") {
            print("已刪除")
        }
        .environmentObject(theme)

        // 無圖標
        DestructiveButton("清空") {
            print("已清空")
        }
        .environmentObject(theme)

        // 全寬按鈕
        DestructiveButton("刪除所有", icon: "trash.fill", fullWidth: true) {
            print("刪除所有")
        }
        .environmentObject(theme)

        // 不需要確認
        DestructiveButton("移除", icon: "minus.circle", requiresConfirmation: false) {
            print("已移除（無確認）")
        }
        .environmentObject(theme)

        // 禁用狀態
        DestructiveButton("已禁用", icon: "xmark", isDisabled: true) {
            print("不會執行")
        }
        .environmentObject(theme)

        // 不同尺寸
        HStack(spacing: 12) {
            DestructiveButton("小", size: .small, requiresConfirmation: false) {
                print("小按鈕")
            }
            .environmentObject(theme)

            DestructiveButton("中", size: .medium, requiresConfirmation: false) {
                print("中按鈕")
            }
            .environmentObject(theme)

            DestructiveButton("大", size: .large, requiresConfirmation: false) {
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

            DestructiveButton("刪除", icon: "trash") {
                print("刪除")
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
        DestructiveButton("刪除", icon: "trash") {
            print("已刪除")
        }
        .environmentObject(theme)

        DestructiveButton("刪除所有", icon: "trash.fill", fullWidth: true) {
            print("刪除所有")
        }
        .environmentObject(theme)

        DestructiveButton("已禁用", isDisabled: true) {
            print("不會執行")
        }
        .environmentObject(theme)

        HStack(spacing: 12) {
            SecondaryButton("取消") {
                print("取消")
            }
            .environmentObject(theme)

            DestructiveButton("刪除", icon: "trash") {
                print("刪除")
            }
            .environmentObject(theme)
        }
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
