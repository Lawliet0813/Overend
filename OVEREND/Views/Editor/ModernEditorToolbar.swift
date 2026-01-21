//
//  ModernEditorToolbar.swift
//  OVEREND
//
//  現代化編輯器工具列 - 靈感來自 Claude Writing Assistant
//  整合 AI 文本分析功能
//

import SwiftUI
import AppKit

// MARK: - 現代化編輯器工具列

struct ModernEditorToolbar: View {
    @ObservedObject var document: Document
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 回調函數
    let onImport: () -> Void
    let onExport: () -> Void
    let onUndo: (() -> Void)?
    let onRedo: (() -> Void)?
    let onFontChange: ((String) -> Void)?
    let onBold: (() -> Void)?
    let onItalic: (() -> Void)?
    let onUnderline: (() -> Void)?
    let onAlignLeft: (() -> Void)?
    let onAlignCenter: (() -> Void)?
    let onAlignRight: (() -> Void)?
    let onIncreaseFontSize: (() -> Void)?
    let onDecreaseFontSize: (() -> Void)?
    let onLineSpacing: ((CGFloat) -> Void)?
    let onTextColor: ((NSColor) -> Void)?
    let onHighlight: ((NSColor) -> Void)?
    let onList: ((ListType) -> Void)?
    
    // 綁定狀態
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    @Binding var currentFont: String
    @Binding var showCitationSidebar: Bool
    @Binding var isBoldActive: Bool
    @Binding var isItalicActive: Bool
    @Binding var isUnderlineActive: Bool
    
    // 本地狀態
    @State private var showColorPicker = false
    @State private var showHighlightPicker = false
    @State private var showLineSpacing = false
    @State private var showFontMenu = false
    @State private var wordCount: Int = 0
    @State private var characterCount: Int = 0
    
    // 可用字體
    let availableFonts: [(name: String, display: String)] = [
        ("PMingLiU", "新細明體"),
        ("Times New Roman", "Times New Roman"),
        ("Arial", "Arial"),
        ("Helvetica", "Helvetica"),
        ("PingFang TC", "蘋方-繁"),
        ("Heiti TC", "黑體-繁"),
        ("Kaiti TC", "楷體-繁"),
        ("Georgia", "Georgia")
    ]
    
    // 顏色選項
    let colors: [Color] = [
        .black, .red, .green, .blue, .yellow,
        .purple, .cyan, .orange, .pink, .gray
    ]
    
    // 行距選項
    let lineSpacings: [(value: CGFloat, label: String)] = [
        (1.0, "1.0"),
        (1.15, "1.15"),
        (1.5, "1.5"),
        (2.0, "2.0")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部列：標題 + 功能按鈕
            topBar
            
            Divider()
            
            // 格式化工具列
            formattingToolbar
        }
        .background(theme.elevated)
    }
    
    // MARK: - 頂部列
    
    private var topBar: some View {
        HStack(spacing: 16) {
            // 可編輯標題
            TextField("文件標題", text: Binding(
                get: { document.title },
                set: { newValue in
                    document.title = newValue
                    document.updatedAt = Date()
                    try? viewContext.save()
                }
            ))
            .font(theme.fontDisplaySmall)
            .fontWeight(.semibold)
            .foregroundColor(theme.textPrimary)
            .textFieldStyle(.plain)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // 字數統計
            wordCountBadge
            
            // 番茄鐘
            PomodoroToolbarButton()
                .environmentObject(theme)
            
            Divider().frame(height: 20)
            
            // 引用側邊欄
            ToolbarButton(
                icon: showCitationSidebar ? "sidebar.right" : "sidebar.left",
                label: "參考文獻",
                action: { showCitationSidebar.toggle() }
            )
            
            // 匯入
            ToolbarButton(
                icon: "square.and.arrow.down",
                label: "匯入",
                action: onImport
            )
            
            // 匯出
            Button(action: onExport) {
                Label("匯出", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - 格式化工具列
    
    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 復原/重作
                FormatIconButton(
                    icon: "arrow.uturn.backward",
                    tooltip: "復原",
                    isActive: .constant(false),
                    isDisabled: !canUndo,
                    action: { onUndo?() }
                )
                    
                FormatIconButton(
                    icon: "arrow.uturn.forward",
                    tooltip: "重作",
                    isActive: .constant(false),
                    isDisabled: !canRedo,
                    action: { onRedo?() }
                )
                
                ToolbarSeparator()
                
                // 字體選擇
                fontSelector
                
                // 字體大小
                FormatIconButton(
                    icon: "textformat.size.smaller",
                    tooltip: "縮小字體",
                    isActive: .constant(false),
                    action: { onDecreaseFontSize?() }
                )
                    
                FormatIconButton(
                    icon: "textformat.size.larger",
                    tooltip: "放大字體",
                    isActive: .constant(false),
                    action: { onIncreaseFontSize?() }
                )
                
                ToolbarSeparator()
                
                // 粗體、斜體、底線
                FormatIconButton(
                    icon: "bold",
                    tooltip: "粗體",
                    isActive: $isBoldActive,
                    action: { onBold?() }
                )
                    
                FormatIconButton(
                    icon: "italic",
                    tooltip: "斜體",
                    isActive: $isItalicActive,
                    action: { onItalic?() }
                )
                
                FormatIconButton(
                    icon: "underline",
                    tooltip: "底線",
                    isActive: $isUnderlineActive,
                    action: { onUnderline?() }
                )
                
                ToolbarSeparator()
                
                // 文字顏色
                colorPickerButton
                
                // 螢光筆
                highlightPickerButton
                
                ToolbarSeparator()
                
                // 對齊
                FormatIconButton(
                    icon: "text.alignleft",
                    tooltip: "靠左對齊",
                    isActive: .constant(false),
                    action: { onAlignLeft?() }
                )
                    
                FormatIconButton(
                    icon: "text.aligncenter",
                    tooltip: "置中對齊",
                    isActive: .constant(false),
                    action: { onAlignCenter?() }
                )
                
                FormatIconButton(
                    icon: "text.alignright",
                    tooltip: "靠右對齊",
                    isActive: .constant(false),
                    action: { onAlignRight?() }
                )
                
                ToolbarSeparator()
                
                // 行距
                lineSpacingButton
                
                ToolbarSeparator()
                
                // 列表
                FormatIconButton(
                    icon: "list.bullet",
                    tooltip: "項目符號",
                    isActive: .constant(false),
                    action: { onList?(.bullet) }
                )
                
                FormatIconButton(
                    icon: "list.number",
                    tooltip: "編號列表",
                    isActive: .constant(false),
                    action: { onList?(.numbered) }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 子元件
    
    private var wordCountBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.system(size: 12))
            Text("\(characterCount) 字")
                .font(theme.fontBodySmall)
        }
        .foregroundColor(theme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(theme.card))
        .cornerRadius(8)
        .onAppear {
            updateWordCount()
        }
    }
    
    private var fontSelector: some View {
        Menu {
            ForEach(availableFonts, id: \.name) { font in
                Button(action: {
                    onFontChange?(font.name)
                    currentFont = font.name
                }) {
                    HStack {
                        Text(font.display)
                        if currentFont == font.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(availableFonts.first(where: { $0.name == currentFont })?.display ?? "字體")
                    .font(theme.fontBodySmall)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(theme.card))
            .cornerRadius(8)
        }
    }
    
    private var colorPickerButton: some View {
        Menu {
            ForEach(colors, id: \.self) { color in
                Button(action: {
                    onTextColor?(NSColor(color))
                }) {
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                        Text(colorName(for: color))
                    }
                }
            }
        } label: {
            Image(systemName: "paintpalette")
                .font(.system(size: 14))
                .foregroundColor(theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(Color(theme.card))
                .cornerRadius(8)
        }
    }
    
    private var highlightPickerButton: some View {
        Menu {
            ForEach(colors, id: \.self) { color in
                Button(action: {
                    onHighlight?(NSColor(color.opacity(0.3)))
                }) {
                    HStack {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 16, height: 16)
                        Text(colorName(for: color))
                    }
                }
            }
        } label: {
            Image(systemName: "highlighter")
                .font(.system(size: 14))
                .foregroundColor(theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(Color(theme.card))
                .cornerRadius(8)
        }
    }
    
    private var lineSpacingButton: some View {
        Menu {
            ForEach(lineSpacings, id: \.value) { spacing in
                Button(action: {
                    onLineSpacing?(spacing.value)
                }) {
                    Text("行距 \(spacing.label)")
                }
            }
        } label: {
            Image(systemName: "arrow.up.and.down.text.horizontal")
                .font(.system(size: 14))
                .foregroundColor(theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(Color(theme.card))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateWordCount() {
        if let rtfData = document.rtfData,
           let attributedString = try? NSAttributedString(
            data: rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
           ) {
            let text = attributedString.string
            characterCount = text.count
            wordCount = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }.count
        }
    }
    
    private func colorName(for color: Color) -> String {
        switch color {
        case .black: return "黑色"
        case .red: return "紅色"
        case .green: return "綠色"
        case .blue: return "藍色"
        case .yellow: return "黃色"
        case .purple: return "紫色"
        case .cyan: return "青色"
        case .orange: return "橘色"
        case .pink: return "粉紅"
        case .gray: return "灰色"
        default: return "顏色"
        }
    }
}

// MARK: - 工具列按鈕元件

private struct ToolbarButton: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(theme.fontBodySmall)
        }
        .buttonStyle(.bordered)
    }
}

private struct FormatIconButton: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    let tooltip: String
    @Binding var isActive: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isDisabled ? theme.textTertiary : (isActive ? theme.accent : theme.textPrimary))
                .frame(width: 32, height: 32)
                .background(isActive ? theme.accentLight : theme.card)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(tooltip)
    }
}

private struct ToolbarSeparator: View {
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        Divider()
            .frame(height: 20)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context)
    doc.id = UUID()
    doc.title = "測試文件"
    doc.createdAt = Date()
    doc.updatedAt = Date()
    
    return ModernEditorToolbar(
        document: doc,
        onImport: { },
        onExport: { },
        onUndo: { },
        onRedo: { },
        onFontChange: nil,
        onBold: nil,
        onItalic: nil,
        onUnderline: nil,
        onAlignLeft: nil,
        onAlignCenter: nil,
        onAlignRight: nil,
        onIncreaseFontSize: nil,
        onDecreaseFontSize: nil,
        onLineSpacing: nil,
        onTextColor: nil,
        onHighlight: nil,
        onList: nil,
        canUndo: .constant(true),
        canRedo: .constant(false),
        currentFont: .constant("Arial"),
        showCitationSidebar: .constant(true),
        isBoldActive: .constant(false),
        isItalicActive: .constant(false),
        isUnderlineActive: .constant(false)
    )
    .environmentObject(AppTheme())
    .frame(height: 120)
}
