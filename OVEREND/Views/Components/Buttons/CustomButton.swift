//
//  CustomButton.swift
//  OVEREND
//
//  統一的按鈕元件系統 - 支援多種樣式
//

import SwiftUI

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

// MARK: - 統一按鈕元件

/// 統一按鈕元件
/// 
/// 使用範例：
/// ```swift
/// CustomButton("保存", icon: "checkmark", style: .primary) { }
/// CustomButton("取消", style: .secondary) { }
/// CustomButton("刪除", icon: "trash", style: .destructive) { }
/// CustomButton(icon: "xmark", style: .icon) { }
/// ```
struct CustomButton: View {
    @EnvironmentObject var theme: AppTheme
    
    // MARK: - 樣式定義
    
    /// 按鈕樣式
    enum Style {
        case primary            // 主要操作：綠色背景
        case secondary          // 次要操作：透明邊框
        case destructive        // 危險操作：紅色背景
        case icon(IconStyle)    // 純圖標按鈕
        
        enum IconStyle {
            case standard       // 標準樣式
            case subtle         // 微妙樣式
            case accent         // 強調色
            case destructive    // 危險操作
        }
    }
    
    // MARK: - 參數
    
    let title: String?
    let icon: String?
    let style: Style
    let action: () -> Void
    var isDisabled: Bool = false
    var fullWidth: Bool = false
    var size: ButtonSize = .medium
    var requiresConfirmation: Bool = false
    var tooltip: String? = nil
    
    // MARK: - 狀態

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var showConfirmation = false
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // MARK: - 初始化
    
    /// 文字按鈕初始化
    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        size: ButtonSize = .medium,
        requiresConfirmation: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.size = size
        self.requiresConfirmation = requiresConfirmation
        self.tooltip = nil
        self.action = action
    }
    
    /// 純圖標按鈕初始化
    init(
        icon: String,
        style: Style = .icon(.standard),
        isDisabled: Bool = false,
        size: ButtonSize = .medium,
        tooltip: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = nil
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.fullWidth = false
        self.size = size
        self.requiresConfirmation = false
        self.tooltip = tooltip
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        baseButton
            .overlay(focusRing)
            .help(tooltip ?? "")
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(tooltip ?? "")
            .accessibilityAddTraits(.isButton)
            .confirmationDialog(
                "確認操作",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("確認", role: .destructive) {
                    action()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作無法撤銷")
            }
    }

    private var baseButton: some View {
        Button(action: handleAction) {
            buttonContent
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .focused($isFocused)
        .scaleEffect(scale)
        .animation(reduceMotion ? nil : AnimationSystem.Easing.quick, value: isHovered)
        .animation(reduceMotion ? nil : AnimationSystem.Easing.instant, value: isPressed)
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
    
    // MARK: - 按鈕內容
    
    @ViewBuilder
    private var buttonContent: some View {
        if case .icon = style {
            // 純圖標按鈕 - Liquid Glass 風格
            Image(systemName: icon ?? "")
                .font(.system(size: size.iconSize, weight: .medium))
                .symbolRenderingMode(.hierarchical)  // WWDC25 SF Symbols 風格
                .foregroundStyle(iconColor)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        } else {
            // 文字按鈕 - Liquid Glass 風格
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: fontWeight))
                        .symbolRenderingMode(.hierarchical)  // WWDC25 SF Symbols 風格
                }
                if let title = title {
                    Text(title)
                        .font(.system(size: size.fontSize, weight: fontWeight))
                }
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                ZStack {
                    // Liquid Glass 基底
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(.ultraThinMaterial)
                    
                    // 主色疊加層（主要按鈕才有）
                    if case .primary = style {
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.accent.opacity(0.85))
                    } else if case .destructive = style {
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(theme.destructive.opacity(0.85))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.4 : 0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 1 : 0.5
                    )
            )
            .shadow(
                color: glowShadowColor,
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 4 : 2
            )
        }
    }
    
    // MARK: - 動作處理
    
    private func handleAction() {
        guard !isDisabled else { return }
        
        if requiresConfirmation {
            showConfirmation = true
        } else {
            action()
        }
    }
    
    // MARK: - 計算屬性
    
    /// 字體粗細
    private var fontWeight: Font.Weight {
        switch style {
        case .primary, .destructive:
            return .semibold
        case .secondary:
            return .medium
        case .icon:
            return .medium
        }
    }
    
    /// 按鈕大小（僅圖標按鈕）
    private var buttonSize: CGFloat {
        switch size {
        case .small: return 28
        case .medium: return 32
        case .large: return 40
        }
    }
    
    /// 縮放比例
    private var scale: CGFloat {
        if reduceMotion {
            return 1.0
        }

        if isPressed {
            if case .icon = style {
                return 0.92
            } else {
                return 0.96
            }
        } else if isHovered {
            if case .icon = style {
                return 1.05
            } else {
                return 1.02
            }
        } else {
            return 1.0
        }
    }

    /// 無障礙標籤
    private var accessibilityLabel: String {
        if let title = title {
            return title
        } else if let tooltip = tooltip {
            return tooltip
        } else if let icon = icon {
            // 為常見圖標提供預設標籤
            switch icon {
            case "xmark", "xmark.circle", "xmark.circle.fill":
                return "關閉"
            case "checkmark", "checkmark.circle", "checkmark.circle.fill":
                return "確認"
            case "trash", "trash.fill":
                return "刪除"
            case "pencil", "pencil.circle", "pencil.circle.fill":
                return "編輯"
            case "plus", "plus.circle", "plus.circle.fill":
                return "新增"
            case "minus", "minus.circle", "minus.circle.fill":
                return "移除"
            case "star", "star.fill":
                return "收藏"
            case "heart", "heart.fill":
                return "喜歡"
            case "gear", "gearshape", "gearshape.fill":
                return "設定"
            case "magnifyingglass":
                return "搜尋"
            case "ellipsis", "ellipsis.circle", "ellipsis.circle.fill":
                return "更多選項"
            default:
                return "按鈕"
            }
        } else {
            return "按鈕"
        }
    }

    /// 焦點指示圈
    @ViewBuilder
    private var focusRing: some View {
        if isFocused && !isDisabled {
            if case .icon = style {
                Circle()
                    .strokeBorder(theme.accent, lineWidth: 2)
                    .padding(-2)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isFocused)
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .strokeBorder(theme.accent, lineWidth: 2)
                    .padding(-2)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
    
    /// 文字顏色
    private var textColor: Color {
        if isDisabled {
            return theme.textDisabled
        }
        
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return theme.textPrimary
        case .icon:
            return theme.textPrimary
        }
    }
    
    /// 圖標顏色（純圖標按鈕）
    private var iconColor: Color {
        if isDisabled {
            return theme.textDisabled
        }
        
        if case .icon(let iconStyle) = style {
            switch iconStyle {
            case .standard:
                return theme.textSecondary
            case .subtle:
                return theme.textSecondary.opacity(0.7)
            case .accent:
                return theme.accent
            case .destructive:
                return .red
            }
        }
        
        return theme.textPrimary
    }
    
    /// 背景顏色
    private var backgroundColor: Color {
        if isDisabled {
            if case .icon = style {
                return .clear
            }
            return theme.buttonDisabled
        }
        
        switch style {
        case .primary:
            return theme.accent
        case .destructive:
            return .red
        case .secondary:
            return isHovered ? theme.itemHover : .clear
        case .icon(let iconStyle):
            if isHovered {
                switch iconStyle {
                case .standard, .subtle:
                    return theme.itemHover
                case .accent:
                    return theme.accent.opacity(0.1)
                case .destructive:
                    return Color.red.opacity(0.1)
                }
            }
            return .clear
        }
    }
    
    /// 邊框顏色
    private var borderColor: Color {
        guard case .secondary = style else { return .clear }
        
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
        guard case .secondary = style else { return 0 }
        return isHovered ? 1.5 : 1
    }
    
    /// 陰影顏色
    private var shadowColor: Color {
        if isDisabled {
            return .clear
        }
        
        if case .secondary = style {
            return .clear
        }
        
        if case .icon = style {
            return .clear
        }
        
        if isHovered {
            switch style {
            case .primary:
                return theme.accent.opacity(0.4)
            case .destructive:
                return Color.red.opacity(0.4)
            default:
                return .clear
            }
        }
        
        return DesignTokens.Shadow.level2.color
    }
    
    /// 陰影半徑
    private var shadowRadius: CGFloat {
        if isDisabled {
            return 0
        }
        
        if case .secondary = style {
            return 0
        }
        
        if case .icon = style {
            return 0
        }
        
        return isHovered ? 12 : DesignTokens.Shadow.level2.radius
    }
    
    /// 陰影 Y 偏移
    private var shadowY: CGFloat {
        if isDisabled {
            return 0
        }
        
        if case .secondary = style {
            return 0
        }
        
        if case .icon = style {
            return 0
        }
        
        return isHovered ? 6 : DesignTokens.Shadow.level2.y
    }
    
    /// 發光陰影顏色（Liquid Glass 效果）
    private var glowShadowColor: Color {
        if isDisabled {
            return .clear
        }
        
        switch style {
        case .primary:
            return theme.accent.opacity(isHovered ? 0.5 : 0.3)
        case .destructive:
            return theme.destructive.opacity(isHovered ? 0.5 : 0.3)
        case .secondary:
            return Color.white.opacity(isHovered ? 0.15 : 0.05)
        case .icon:
            return .clear
        }
    }
}

// MARK: - 預覽

#Preview("All Styles") {
    let theme = AppTheme()
    
    VStack(spacing: 20) {
        Text("Primary Buttons").font(.headline)
        HStack(spacing: 12) {
            CustomButton("保存", icon: "checkmark", style: .primary, action: {})
                .environmentObject(theme)
            CustomButton("確認", style: .primary, action: {})
                .environmentObject(theme)
        }
        
        Text("Secondary Buttons").font(.headline)
        HStack(spacing: 12) {
            CustomButton("取消", icon: "xmark", style: .secondary, action: {})
                .environmentObject(theme)
            CustomButton("編輯", style: .secondary, action: {})
                .environmentObject(theme)
        }
        
        Text("Destructive Buttons").font(.headline)
        HStack(spacing: 12) {
            CustomButton("刪除", icon: "trash", style: .destructive, action: {})
                .environmentObject(theme)
        }
        
        Text("Icon Buttons").font(.headline)
        HStack(spacing: 12) {
            CustomButton(icon: "xmark", style: .icon(.standard), action: {})
                .environmentObject(theme)
            CustomButton(icon: "star", style: .icon(.accent), action: {})
                .environmentObject(theme)
        }
    }
    .padding(40)
    .frame(width: 500)
}

#Preview("Dark Mode") {
    let theme = AppTheme()
    
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            CustomButton("保存", icon: "checkmark", style: .primary, action: {})
                .environmentObject(theme)
            CustomButton("取消", style: .secondary, action: {})
                .environmentObject(theme)
        }
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
