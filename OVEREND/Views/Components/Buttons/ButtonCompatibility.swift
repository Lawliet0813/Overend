//
//  ButtonCompatibility.swift
//  OVEREND
//
//  按鈕元件兼容性別名 - 遷移過渡期使用
//  
//  使用 CustomButton 統一實現，保持向後兼容
//

import SwiftUI

// MARK: - Primary Button Compatibility

typealias PrimaryButton = _PrimaryButtonCompat

struct _PrimaryButtonCompat: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool
    let fullWidth: Bool
    let size: ButtonSize
    
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
    
    var body: some View {
        CustomButton(
            title,
            icon: icon,
            style: .primary,
            isDisabled: isDisabled,
            fullWidth: fullWidth,
            size: size,
            action: action
        )
    }
}

// MARK: - Secondary Button Compatibility

typealias SecondaryButton = _SecondaryButtonCompat

struct _SecondaryButtonCompat: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool
    let fullWidth: Bool
    let size: ButtonSize
    
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
    
    var body: some View {
        CustomButton(
            title,
            icon: icon,
            style: .secondary,
            isDisabled: isDisabled,
            fullWidth: fullWidth,
            size: size,
            action: action
        )
    }
}

// MARK: - Destructive Button Compatibility

typealias DestructiveButton = _DestructiveButtonCompat

struct _DestructiveButtonCompat: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool
    let fullWidth: Bool
    let size: ButtonSize
    let requiresConfirmation: Bool
    
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
    
    var body: some View {
        CustomButton(
            title,
            icon: icon,
            style: .destructive,
            isDisabled: isDisabled,
            fullWidth: fullWidth,
            size: size,
            requiresConfirmation: requiresConfirmation,
            action: action
        )
    }
}

// MARK: - Icon Button Compatibility

typealias IconButton = _IconButtonCompat

struct _IconButtonCompat: View {
    let icon: String
    let action: () -> Void
    let size: ButtonSize
    let style: IconButtonStyle
    let isDisabled: Bool
    let tooltip: String?
    
    enum IconButtonStyle {
        case standard
        case subtle
        case accent
        case destructive
    }
    
    init(
        icon: String,
        action: @escaping () -> Void,
        size: ButtonSize = .medium,
        style: IconButtonStyle = .standard,
        isDisabled: Bool = false,
        tooltip: String? = nil
    ) {
        self.icon = icon
        self.action = action
        self.size = size
        self.style = style
        self.isDisabled = isDisabled
        self.tooltip = tooltip
    }
    
    var body: some View {
        CustomButton(
            icon: icon,
            style: .icon(convertStyle(style)),
            isDisabled: isDisabled,
            size: size,
            tooltip: tooltip,
            action: action
        )
    }
    
    private func convertStyle(_ style: IconButtonStyle) -> CustomButton.Style.IconStyle {
        switch style {
        case .standard: return .standard
        case .subtle: return .subtle
        case .accent: return .accent
        case .destructive: return .destructive
        }
    }
}
