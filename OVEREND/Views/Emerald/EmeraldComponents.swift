//
//  EmeraldComponents.swift
//  OVEREND
//
//  Emerald 共用 UI 元件 - 集中管理重複使用的視圖和修飾符
//

import SwiftUI
import CoreData

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
    
    /// 標準玻璃模糊背景
    func emeraldGlassBackground(opacity: Double = 0.5) -> some View {
        self
            .background(EmeraldTheme.backgroundDark.opacity(opacity))
            .background(.ultraThinMaterial)
    }
    
    /// 卡片樣式背景
    func emeraldCardBackground(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(EmeraldTheme.surfaceDark)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - 通用工具按鈕

struct EmeraldIconButton: View {
    let icon: String
    let size: CGFloat
    var color: Color = EmeraldTheme.textSecondary
    var activeColor: Color = .white
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            MaterialIcon(
                name: icon,
                size: size,
                color: isHovered ? activeColor : color
            )
            .frame(width: size + 14, height: size + 14)
            .background(isHovered ? Color.white.opacity(0.05) : .clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 區塊標題

struct EmeraldSectionTitle: View {
    let title: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                MaterialIcon(name: icon, size: 14, color: EmeraldTheme.textMuted)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(EmeraldTheme.textMuted)
                .textCase(.uppercase)
                .tracking(1)
        }
    }
}

// MARK: - 標籤徽章

struct EmeraldBadge: View {
    let text: String
    var color: Color = EmeraldTheme.primary
    var isInverted: Bool = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(isInverted ? EmeraldTheme.backgroundDark : color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isInverted ? color : color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - 工具列按鈕組

struct EmeraldToolbarGroup: View {
    let content: () -> AnyView
    
    init(@ViewBuilder content: @escaping () -> some View) {
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .padding(4)
        .background(EmeraldTheme.surfaceDark)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - 垂直分隔線

struct EmeraldDivider: View {
    var isVertical: Bool = false
    var length: CGFloat = 24
    
    var body: some View {
        if isVertical {
            Divider()
                .frame(height: length)
                .background(Color.white.opacity(0.1))
        } else {
            Divider()
                .frame(width: length)
                .background(Color.white.opacity(0.1))
        }
    }
}

// MARK: - 空狀態視圖

struct EmeraldEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(EmeraldTheme.primary.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                MaterialIcon(name: icon, size: 28, color: EmeraldTheme.primary)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(EmeraldTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(EmeraldTheme.backgroundDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(EmeraldTheme.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - 搜尋框

struct EmeraldSearchField: View {
    @Binding var text: String
    var placeholder: String = "搜尋..."
    var showEscHint: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            MaterialIcon(name: "search", size: 18, color: EmeraldTheme.textMuted)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 13))
            
            if showEscHint {
                Text("ESC")
                    .font(.system(size: 9))
                    .foregroundColor(EmeraldTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(EmeraldTheme.surfaceDark)
        .cornerRadius(10)
    }
}

// MARK: - 快捷鍵標籤

struct EmeraldShortcutHint: View {
    let key: String
    
    var body: some View {
        Text(key)
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(EmeraldTheme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - 狀態列

struct EmeraldStatusBar: View {
    let items: [String]
    
    var body: some View {
        HStack {
            Text(items.joined(separator: " • "))
                .font(.system(size: 11))
                .foregroundColor(EmeraldTheme.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .emeraldGlassBackground(opacity: 0.8)
    }
}

// MARK: - 主要操作按鈕

struct EmeraldPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    MaterialIcon(name: icon, size: 14, color: EmeraldTheme.primary)
                }
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(EmeraldTheme.primary)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovered ? EmeraldTheme.primary.opacity(0.15) : EmeraldTheme.primary.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? EmeraldTheme.borderAccent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 複選框

struct EmeraldCheckbox: View {
    let isChecked: Bool
    var size: CGFloat = 18
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isChecked ? EmeraldTheme.primary : Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isChecked ? EmeraldTheme.primary : Color.white.opacity(0.2), lineWidth: 1.5)
                )
            
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundColor(EmeraldTheme.backgroundDark)
            }
        }
    }
}

// MARK: - 載入指示器

struct EmeraldLoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(EmeraldTheme.primary, lineWidth: 2)
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
