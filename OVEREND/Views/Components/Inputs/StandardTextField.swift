//
//  StandardTextField.swift
//  OVEREND
//
//  標準文字輸入框組件
//

import SwiftUI

/// 標準文字輸入框
/// 特點：統一樣式 + 聚焦動畫 + 錯誤狀態
struct StandardTextField: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var errorMessage: String? = nil
    var onCommit: (() -> Void)? = nil

    // MARK: - 狀態

    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    @State private var showError = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.IconSize.small))
                        .foregroundColor(iconColor)
                        .animation(AnimationSystem.Easing.quick, value: isFocused)
                        .animation(AnimationSystem.Easing.quick, value: showError)
                }

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            onCommit?()
                        }
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            onCommit?()
                        }
                }
            }
            .font(.system(size: DesignTokens.Typography.body))
            .foregroundColor(theme.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(AnimationSystem.Easing.quick, value: isFocused)
            .animation(AnimationSystem.Easing.quick, value: isHovered)
            .animation(AnimationSystem.Easing.quick, value: showError)
            .onHover { isHovered = $0 }

            // 錯誤訊息
            if let errorMessage = errorMessage, showError {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.small))
                    Text(errorMessage)
                        .font(.system(size: DesignTokens.Typography.caption))
                }
                .foregroundColor(theme.error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: errorMessage) { newValue in
            withAnimation(AnimationSystem.Easing.spring) {
                showError = newValue != nil
            }
        }
    }

    // MARK: - 計算屬性

    /// 圖標顏色
    private var iconColor: Color {
        if showError {
            return theme.error
        } else if isFocused {
            return theme.accent
        } else {
            return theme.textMuted
        }
    }

    /// 背景顏色
    private var backgroundColor: Color {
        if showError {
            return theme.errorBackground
        } else if isHovered || isFocused {
            return theme.itemHover
        } else {
            return theme.background
        }
    }

    /// 邊框顏色
    private var borderColor: Color {
        if showError {
            return theme.error
        } else if isFocused {
            return theme.focusBorder
        } else {
            return theme.border
        }
    }

    /// 邊框寬度
    private var borderWidth: CGFloat {
        (isFocused || showError) ? 2 : 1
    }
}

/// 搜尋框組件
/// 特點：內建搜尋圖標 + 清除按鈕
struct SearchField: View {
    @EnvironmentObject var theme: AppTheme

    // MARK: - 參數

    let placeholder: String
    @Binding var text: String
    var onSearch: (() -> Void)? = nil

    // MARK: - 狀態

    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundColor(isFocused ? theme.accent : theme.textMuted)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onSearch?()
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.small))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .font(.system(size: DesignTokens.Typography.body))
        .foregroundColor(theme.textPrimary)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(isHovered || isFocused ? theme.itemHover : theme.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .stroke(isFocused ? theme.focusBorder : theme.border, lineWidth: isFocused ? 2 : 1)
        )
        .animation(AnimationSystem.Easing.quick, value: isFocused)
        .animation(AnimationSystem.Easing.quick, value: isHovered)
        .animation(AnimationSystem.Easing.quick, value: text.isEmpty)
        .onHover { isHovered = $0 }
    }
}

// MARK: - 預覽

#Preview("Standard TextFields") {
    VStack(spacing: 24) {
        let theme = AppTheme()
        @State var username = ""
        @State var email = ""
        @State var password = ""
        @State var errorText = ""

        // 標準輸入框
        StandardTextField(placeholder: "使用者名稱", text: $username, icon: "person")
            .environmentObject(theme)

        // Email 輸入框
        StandardTextField(placeholder: "電子郵件", text: $email, icon: "envelope")
            .environmentObject(theme)

        // 密碼輸入框
        StandardTextField(placeholder: "密碼", text: $password, icon: "lock", isSecure: true)
            .environmentObject(theme)

        // 錯誤狀態
        StandardTextField(
            placeholder: "帶錯誤提示",
            text: $errorText,
            icon: "exclamationmark.triangle",
            errorMessage: "此欄位不能為空"
        )
        .environmentObject(theme)

        // 無圖標
        StandardTextField(placeholder: "沒有圖標的輸入框", text: $username)
            .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Search Field") {
    VStack(spacing: 24) {
        let theme = AppTheme()
        @State var searchText1 = ""
        @State var searchText2 = "已輸入文字"

        SearchField(placeholder: "搜尋文獻...", text: $searchText1) {
            print("搜尋：\(searchText1)")
        }
        .environmentObject(theme)

        SearchField(placeholder: "搜尋...", text: $searchText2)
            .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
}

#Preview("Dark Mode") {
    let theme = AppTheme()
    theme.isDarkMode = true

    @State var username = ""
    @State var search = ""
    @State var errorText = "test"

    return VStack(spacing: 24) {
        StandardTextField(placeholder: "使用者名稱", text: $username, icon: "person")
            .environmentObject(theme)

        SearchField(placeholder: "搜尋...", text: $search)
            .environmentObject(theme)

        StandardTextField(
            placeholder: "錯誤狀態",
            text: $errorText,
            errorMessage: "輸入格式不正確"
        )
        .environmentObject(theme)
    }
    .padding(40)
    .frame(width: 400)
    .background(Color(hex: "#1e1e1e"))
}
