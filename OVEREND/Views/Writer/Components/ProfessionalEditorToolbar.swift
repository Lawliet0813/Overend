//
//  ProfessionalEditorToolbar.swift
//  OVEREND
//
//  專業編輯器工具列 - 類 Word/Notion 格式化工具
//

import SwiftUI
import AppKit

// MARK: - 匯出格式類型

enum ExportType {
    case pdf
    case docx
    case latex
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .docx: return "Word"
        case .latex: return "LaTeX"
        }
    }
}

// MARK: - 專業編輯器工具列

struct ProfessionalEditorToolbar: View {
    @EnvironmentObject var theme: AppTheme
    
    // 工具列狀態
    @Binding var fontSize: CGFloat
    @Binding var isTypewriterMode: Bool
    @Binding var showInspector: Bool
    
    // 格式狀態追蹤
    @State private var isBold = false
    @State private var isItalic = false
    @State private var isUnderline = false
    @State private var isStrikethrough = false
    @State private var currentAlignment: NSTextAlignment = .left
    @State private var selectedFontFamily = "PingFang TC"
    
    // 回調
    var onFormatAction: (FormatAction) -> Void
    var onInsertCitation: () -> Void
    var onExport: ((ExportType) -> Void)?
    
    // 可用字型
    private let fontFamilies = ["PingFang TC", "Helvetica Neue", "Times New Roman", "Georgia", "SF Pro"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 主工具列
            HStack(spacing: 0) {
                // === 左側：字型與大小 ===
                HStack(spacing: 8) {
                    // 字型選擇器
                    Menu {
                        ForEach(fontFamilies, id: \.self) { font in
                            Button(action: { 
                                selectedFontFamily = font
                                onFormatAction(.setFont(font))
                            }) {
                                HStack {
                                    Text(font)
                                        .font(.custom(font, size: 13))
                                    if font == selectedFontFamily {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedFontFamily)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 100)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    
                    // 字體大小
                    HStack(spacing: 2) {
                        Button(action: { 
                            fontSize = max(10, fontSize - 1)
                            onFormatAction(.setFontSize(fontSize))
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(ToolbarIconButtonStyle())
                        
                        Text("\(Int(fontSize))")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 28)
                            .foregroundColor(theme.textPrimary)
                        
                        Button(action: { 
                            fontSize = min(72, fontSize + 1)
                            onFormatAction(.setFontSize(fontSize))
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(ToolbarIconButtonStyle())
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
                }
                
                ToolbarDivider()
                
                // === 文字格式群組 ===
                HStack(spacing: 2) {
                    FormatButton(
                        icon: "bold",
                        label: "B",
                        isActive: isBold,
                        shortcut: "⌘B"
                    ) {
                        isBold.toggle()
                        onFormatAction(.toggleBold)
                    }
                    
                    FormatButton(
                        icon: "italic",
                        label: "I",
                        isActive: isItalic,
                        shortcut: "⌘I"
                    ) {
                        isItalic.toggle()
                        onFormatAction(.toggleItalic)
                    }
                    
                    FormatButton(
                        icon: "underline",
                        label: "U",
                        isActive: isUnderline,
                        shortcut: "⌘U"
                    ) {
                        isUnderline.toggle()
                        onFormatAction(.toggleUnderline)
                    }
                    
                    FormatButton(
                        icon: "strikethrough",
                        label: "S",
                        isActive: isStrikethrough,
                        shortcut: "⇧⌘X"
                    ) {
                        isStrikethrough.toggle()
                        onFormatAction(.toggleStrikethrough)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                
                ToolbarDivider()
                
                // === 文字顏色 ===
                HStack(spacing: 4) {
                    ColorPickerButton(
                        icon: "textformat",
                        color: theme.textPrimary,
                        tooltip: "文字顏色"
                    ) { color in
                        onFormatAction(.setTextColor(color))
                    }
                    
                    ColorPickerButton(
                        icon: "highlighter",
                        color: .yellow,
                        tooltip: "螢光標記"
                    ) { color in
                        onFormatAction(.setHighlight(color))
                    }
                }
                
                ToolbarDivider()
                
                // === 對齊群組 ===
                HStack(spacing: 2) {
                    AlignmentButton(alignment: .left, current: currentAlignment) { 
                        currentAlignment = .left
                        onFormatAction(.setAlignment(.left))
                    }
                    AlignmentButton(alignment: .center, current: currentAlignment) { 
                        currentAlignment = .center
                        onFormatAction(.setAlignment(.center))
                    }
                    AlignmentButton(alignment: .right, current: currentAlignment) { 
                        currentAlignment = .right
                        onFormatAction(.setAlignment(.right))
                    }
                    AlignmentButton(alignment: .justified, current: currentAlignment) { 
                        currentAlignment = .justified
                        onFormatAction(.setAlignment(.justified))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                
                ToolbarDivider()
                
                // === 列表群組 ===
                HStack(spacing: 2) {
                    Button(action: { onFormatAction(.insertBulletList) }) {
                        Image(systemName: "list.bullet")
                    }
                    .buttonStyle(ToolbarIconButtonStyle())
                    .help("項目符號列表")
                    
                    Button(action: { onFormatAction(.insertNumberedList) }) {
                        Image(systemName: "list.number")
                    }
                    .buttonStyle(ToolbarIconButtonStyle())
                    .help("編號列表")
                }
                
                ToolbarDivider()
                
                // === 引用插入 ===
                Button(action: onInsertCitation) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.quote")
                        Text("插入引用")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.accent.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("插入引用 (⌘⇧C)")
                
                ToolbarDivider()
                
                // === 匯出選單 ===
                Menu {
                    Button(action: { onExport?(.pdf) }) {
                        Label("匯出 PDF", systemImage: "doc.richtext")
                    }
                    Button(action: { onExport?(.docx) }) {
                        Label("匯出 Word", systemImage: "doc.text")
                    }
                    Divider()
                    Button(action: { onExport?(.latex) }) {
                        Label("匯出 LaTeX", systemImage: "function")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("匯出")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                .menuStyle(.borderlessButton)
                .help("匯出文件")
                
                Spacer()
                
                // === 右側：模式控制 ===
                HStack(spacing: 12) {
                    // 專注模式
                    Button(action: { isTypewriterMode.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "scope")
                            if isTypewriterMode {
                                Text("專注")
                                    .font(.system(size: 10, weight: .medium))
                            }
                        }
                        .foregroundColor(isTypewriterMode ? theme.accent : theme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isTypewriterMode ? theme.accent.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("打字機專注模式")
                    
                    // Inspector 切換
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) { 
                            showInspector.toggle() 
                        }
                    }) {
                        Image(systemName: "sidebar.right")
                            .foregroundColor(showInspector ? theme.accent : theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("學術助理面板")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: 52)
            .background(.ultraThinMaterial)
            
            // 底部邊框
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }
}

// MARK: - 格式動作枚舉

enum FormatAction {
    case toggleBold
    case toggleItalic
    case toggleUnderline
    case toggleStrikethrough
    case setFont(String)
    case setFontSize(CGFloat)
    case setTextColor(Color)
    case setHighlight(Color)
    case setAlignment(NSTextAlignment)
    case insertBulletList
    case insertNumberedList
}

// MARK: - 輔助元件

struct ToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 10)
    }
}

struct FormatButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let label: String
    var isActive: Bool
    var shortcut: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isActive ? .bold : .regular))
                .italic(icon == "italic")
                .underline(icon == "underline")
                .strikethrough(icon == "strikethrough")
                .foregroundColor(isActive ? theme.accent : theme.textPrimary)
                .frame(width: 28, height: 28)
                .background(isActive ? theme.accent.opacity(0.15) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help("\(iconToLabel(icon)) (\(shortcut))")
    }
    
    private func iconToLabel(_ icon: String) -> String {
        switch icon {
        case "bold": return "粗體"
        case "italic": return "斜體"
        case "underline": return "底線"
        case "strikethrough": return "刪除線"
        default: return icon
        }
    }
}

struct ColorPickerButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let icon: String
    let color: Color
    let tooltip: String
    let onSelect: (Color) -> Void
    
    @State private var selectedColor: Color = .black
    
    var body: some View {
        ColorPicker("", selection: $selectedColor)
            .labelsHidden()
            .frame(width: 28, height: 28)
            .help(tooltip)
            .onChange(of: selectedColor) { _, newColor in
                onSelect(newColor)
            }
    }
}

struct AlignmentButton: View {
    @EnvironmentObject var theme: AppTheme
    
    let alignment: NSTextAlignment
    let current: NSTextAlignment
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: alignmentIcon)
                .font(.system(size: 12))
                .foregroundColor(alignment == current ? theme.accent : theme.textSecondary)
                .frame(width: 26, height: 26)
                .background(alignment == current ? theme.accent.opacity(0.15) : Color.clear)
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
        .help(alignmentLabel)
    }
    
    private var alignmentIcon: String {
        switch alignment {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justified: return "text.justify"
        default: return "text.alignleft"
        }
    }
    
    private var alignmentLabel: String {
        switch alignment {
        case .left: return "靠左對齊"
        case .center: return "置中對齊"
        case .right: return "靠右對齊"
        case .justified: return "左右對齊"
        default: return "對齊"
        }
    }
}

struct ToolbarIconButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(theme.textSecondary)
            .frame(width: 24, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.white.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
    }
}

// MARK: - 預覽

#Preview {
    VStack {
        ProfessionalEditorToolbar(
            fontSize: .constant(16),
            isTypewriterMode: .constant(false),
            showInspector: .constant(true),
            onFormatAction: { _ in },
            onInsertCitation: { }
        )
        
        Spacer()
    }
    .background(Color(hex: "#252F3F"))
    .environmentObject(AppTheme())
}
