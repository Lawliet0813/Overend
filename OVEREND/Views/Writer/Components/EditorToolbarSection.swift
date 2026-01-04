//
//  EditorToolbarSection.swift
//  OVEREND
//
//  工具列分組元件 - 視覺化分隔工具列按鈕組
//

import SwiftUI

/// 工具列分組容器
struct EditorToolbarSection<Content: View>: View {
    @EnvironmentObject var theme: AppTheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 2) {
            content
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.15 : 0.3), lineWidth: 1)
        )
    }
}

/// 格式按鈕（增強版）
struct EditorFormatButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let tooltip: String
    var isActive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? theme.accent : theme.textPrimary)
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundColor: Color {
        if isActive {
            return theme.accentLight
        } else if isHovered {
            return theme.itemHover
        } else {
            return .clear
        }
    }
}

/// 段落樣式下拉選單
struct ParagraphStylePicker: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var selectedStyle: ParagraphStyleType
    var onStyleChange: (ParagraphStyleType) -> Void
    
    var body: some View {
        Menu {
            ForEach(ParagraphStyleType.allCases, id: \.self) { style in
                Button(action: {
                    selectedStyle = style
                    onStyleChange(style)
                }) {
                    HStack {
                        Text(style.displayName)
                        if selectedStyle == style {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "paragraphsign")
                    .font(.system(size: 12))
                Text(selectedStyle.displayName)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.itemHover)
            )
        }
        .buttonStyle(.plain)
        .frame(width: 100)
    }
}

/// 段落樣式類型
enum ParagraphStyleType: String, CaseIterable {
    case body = "body"
    case heading1 = "heading1"
    case heading2 = "heading2"
    case heading3 = "heading3"
    case heading4 = "heading4"
    case quote = "quote"
    case code = "code"
    
    var displayName: String {
        switch self {
        case .body: return "內文"
        case .heading1: return "標題 1"
        case .heading2: return "標題 2"
        case .heading3: return "標題 3"
        case .heading4: return "標題 4"
        case .quote: return "引文"
        case .code: return "程式碼"
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .body: return 12
        case .heading1: return 24
        case .heading2: return 20
        case .heading3: return 16
        case .heading4: return 14
        case .quote: return 12
        case .code: return 11
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .body, .quote, .code: return .regular
        case .heading1, .heading2: return .bold
        case .heading3, .heading4: return .semibold
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EditorToolbarSection {
            EditorFormatButton(icon: "bold", tooltip: "粗體") {}
                .environmentObject(AppTheme())
            EditorFormatButton(icon: "italic", tooltip: "斜體", isActive: true) {}
                .environmentObject(AppTheme())
            EditorFormatButton(icon: "underline", tooltip: "底線") {}
                .environmentObject(AppTheme())
        }
        .environmentObject(AppTheme())
        
        ParagraphStylePicker(selectedStyle: .constant(.body)) { _ in }
            .environmentObject(AppTheme())
    }
    .padding()
    .frame(width: 400)
}
