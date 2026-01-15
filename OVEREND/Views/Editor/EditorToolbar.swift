//
//  EditorToolbar.swift
//  OVEREND
//
//  編輯器工具列元件 - 從 DocumentEditorView 拆分
//

import SwiftUI
import AppKit

// MARK: - 編輯器工具列

struct EditorToolbar: View {
    @ObservedObject var document: Document
    @EnvironmentObject var theme: AppTheme
    
    let onImport: () -> Void
    let onExport: () -> Void
    let isPandocAvailable: Bool
    
    // 格式化回調
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onFontChange: ((String) -> Void)?
    var onBold: (() -> Void)?
    var onItalic: (() -> Void)?
    var onUnderline: (() -> Void)?
    var onAlignLeft: (() -> Void)?
    var onAlignCenter: (() -> Void)?
    var onAlignRight: (() -> Void)?
    var onIncreaseFontSize: (() -> Void)?
    var onDecreaseFontSize: (() -> Void)?
    var onLineSpacing: ((CGFloat) -> Void)?
    var onTextColor: ((NSColor) -> Void)?
    var onHighlight: ((NSColor) -> Void)?
    var onHeading: ((HeadingLevel) -> Void)?
    var onList: ((ListType) -> Void)?
    var onInsert: ((InsertType) -> Void)?
    var onChineseOptimization: ((ChineseOptimizationType) -> Void)?
    var onApplyNCCUFormat: (() -> Void)?
    var onInsertCover: (() -> Void)?
    var onInsertCitationShortcut: (() -> Void)?

    // Undo/Redo 狀態
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    @Binding var currentFont: String
    
    // 側邊欄控制
    @Binding var showCitationSidebar: Bool
    
    // 狀態
    @State private var showColorPicker = false
    @State private var selectedColor: Color = .black
    @State private var selectedHighlightColor: Color = .clear
    @State private var currentHeading: HeadingLevel = .normal

    // 可用字體列表
    struct FontOption: Hashable {
        let name: String
        let displayName: String
    }

    let availableFonts: [FontOption] = [
        FontOption(name: "PMingLiU", displayName: "新細明體"),
        FontOption(name: "Times New Roman", displayName: "Times New Roman"),
        FontOption(name: "Arial", displayName: "Arial"),
        FontOption(name: "Helvetica", displayName: "Helvetica"),
        FontOption(name: "PingFang TC", displayName: "蘋方-繁"),
        FontOption(name: "Heiti TC", displayName: "黑體-繁"),
        FontOption(name: "Kaiti TC", displayName: "楷體-繁"),
        FontOption(name: "Georgia", displayName: "Georgia"),
        FontOption(name: "Courier New", displayName: "Courier New"),
        FontOption(name: "Verdana", displayName: "Verdana")
    ]

    func getFontDisplayName(_ fontName: String) -> String {
        availableFonts.first { $0.name == fontName }?.displayName ?? fontName
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 1200
            
            VStack(spacing: 0) {
                // 主工具列 - 放大優化
                HStack(spacing: 16) {
                    // 標題 - 放大
                    Text(document.title)
                        .font(theme.fontDisplaySmall)  // 20pt
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    // 引用側邊欄切換 - 增大
                    Button(action: { showCitationSidebar.toggle() }) {
                        Label("參考文獻", systemImage: showCitationSidebar ? "sidebar.right" : "sidebar.left")
                    }
                    .buttonStyle(.bordered)
                    
                    Divider().frame(height: 20)
                    
                    // 匯入
                    Button(action: onImport) {
                        Label("匯入 DOCX", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    
                    // 匯出
                    Button(action: onExport) {
                        Label("匯出", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(theme.toolbarGlass)
                
                Divider()
                
                // 格式化工具列
                HStack(spacing: 8) {
                    // 1. 復原/重作 (Always Visible)
                    SwiftUI.Group {
                        HStack(spacing: 4) {
                            FormatButton(icon: "arrow.uturn.backward", tooltip: "復原 (⌘Z)", action: onUndo, disabled: !canUndo)
                            FormatButton(icon: "arrow.uturn.forward", tooltip: "重作 (⇧⌘Z)", action: onRedo, disabled: !canRedo)
                        }
                        .padding(4)
                        .background(theme.elevated.opacity(0.5))
                        .cornerRadius(6)
                        
                        Divider().frame(height: 20)
                    }
                    
                    // 2. 標題樣式 (Always Visible)
                    Menu {
                        ForEach(HeadingLevel.allCases) { level in
                            Button(action: { 
                                currentHeading = level
                                onHeading?(level) 
                            }) {
                                HStack {
                                    Text(level.displayName)
                                        .font(.system(size: level.fontSize))
                                    if currentHeading == level {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentHeading.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 50, alignment: .leading)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .padding(6)
                        .background(theme.elevated.opacity(0.5))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .help("標題樣式")
                    
                    Divider().frame(height: 20)
                    
                    // 3. 字體與大小 (Compact: Move to More)
                    if !isCompact {
                        fontControls
                        Divider().frame(height: 20)
                    }
                    
                    // 4. 基本格式 (Bold/Italic/Underline) (Always Visible)
                    HStack(spacing: 4) {
                        FormatButton(icon: "bold", tooltip: "粗體 (⌘B)", action: onBold)
                        FormatButton(icon: "italic", tooltip: "斜體 (⌘I)", action: onItalic)
                        FormatButton(icon: "underline", tooltip: "底線 (⌘U)", action: onUnderline)
                    }
                    .padding(4)
                    .background(theme.elevated.opacity(0.5))
                    .cornerRadius(6)
                    
                    Divider().frame(height: 20)
                    
                    // 5. 顏色與螢光筆 (Compact: Simplified)
                    HStack(spacing: 4) {
                        // 文字顏色
                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 24, height: 24)
                            .help("文字顏色")
                            .onChange(of: selectedColor) { newColor in
                                onTextColor?(NSColor(newColor))
                            }
                        
                        // 螢光筆
                        Menu {
                            Button(action: { onHighlight?(.clear) }) {
                                Label("無", systemImage: "slash.circle")
                            }
                            Button(action: { onHighlight?(.yellow) }) {
                                Label("黃色", systemImage: "circle.fill").foregroundColor(.yellow)
                            }
                            Button(action: { onHighlight?(.green) }) {
                                Label("綠色", systemImage: "circle.fill").foregroundColor(.green)
                            }
                            Button(action: { onHighlight?(.cyan) }) {
                                Label("藍色", systemImage: "circle.fill").foregroundColor(.cyan)
                            }
                            Button(action: { onHighlight?(.magenta) }) {
                                Label("粉紅", systemImage: "circle.fill").foregroundColor(.pink)
                            }
                        } label: {
                            Image(systemName: "highlighter")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textPrimary)
                                .frame(width: 24, height: 24)
                        }
                        .menuStyle(.borderlessButton)
                        .help("螢光筆")
                    }
                    .padding(4)
                    .background(theme.elevated.opacity(0.5))
                    .cornerRadius(6)
                    
                    Divider().frame(height: 20)
                    
                    // 6. 清單與對齊 (Compact: Move to More)
                    if !isCompact {
                        listAndAlignControls
                        Divider().frame(height: 20)
                    }
                    
                    // 7. 插入與引用 (Always Visible)
                    HStack(spacing: 4) {
                        // 插入引用快捷鈕
                        Button(action: { onInsertCitationShortcut?() }) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 28, height: 28)
                        .background(theme.elevated.opacity(0.5))
                        .cornerRadius(6)
                        .help("插入引用 (⌘⇧C)")
                        
                        // 插入選單
                        Menu {
                            Button(action: { onInsert?(.image) }) {
                                Label("圖片", systemImage: "photo")
                            }
                            Button(action: { onInsert?(.table) }) {
                                Label("表格", systemImage: "tablecells")
                            }
                            Button(action: { onInsert?(.footnote) }) {
                                Label("腳註", systemImage: "text.alignleft")
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("插入")
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                            }
                            .padding(6)
                            .background(theme.elevated.opacity(0.5))
                            .cornerRadius(6)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    // 8. 中文優化 (Compact: Move to More)
                    if !isCompact {
                        Divider().frame(height: 20)
                        chineseOptimizationMenu
                        
                        Divider().frame(height: 20)
                        nccuTemplateButton
                    }
                    
                    Spacer()
                    
                    // 9. 更多選單 (Compact Only)
                    if isCompact {
                        Menu {
                            // 字體控制
                            Section("字體") {
                                Button("放大字體") { onIncreaseFontSize?() }
                                Button("縮小字體") { onDecreaseFontSize?() }
                                Menu("選擇字體") {
                                    ForEach(availableFonts, id: \.self) { font in
                                        Button(font.displayName) { onFontChange?(font.name) }
                                    }
                                }
                            }
                            
                            // 段落控制
                            Section("段落") {
                                Button("靠左對齊") { onAlignLeft?() }
                                Button("置中對齊") { onAlignCenter?() }
                                Button("靠右對齊") { onAlignRight?() }
                                Button("項目符號") { onList?(.bullet) }
                                Button("編號清單") { onList?(.numbered) }
                            }
                            
                            // 中文優化
                            Section("中文優化") {
                                Button("全形標點轉換") { onChineseOptimization?(.punctuation) }
                                Button("中英文間距") { onChineseOptimization?(.spacing) }
                                Button("轉繁體") { onChineseOptimization?(.toTraditional) }
                                Button("轉簡體") { onChineseOptimization?(.toSimplified) }
                                Button("台灣學術用語檢查") { onChineseOptimization?(.terminology) }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(theme.textPrimary)
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.trailing, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.toolbarGlass)
            }
        }
        .frame(height: 100)
    }
    
    // MARK: - Subviews
    
    private var fontControls: some View {
        HStack(spacing: 8) {
            // 字體選擇器
            Menu {
                ForEach(availableFonts, id: \.self) { font in
                    Button(action: { onFontChange?(font.name) }) {
                        HStack {
                            Text(font.displayName)
                                .font(.custom(font.name, size: 14))
                            if currentFont == font.name {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "textformat")
                        .font(.system(size: 12))
                    Text(getFontDisplayName(currentFont))
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 140)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            .help("字體")

            // 字體大小
            HStack(spacing: 4) {
                FormatButton(icon: "textformat.size.smaller", tooltip: "縮小字體", action: onDecreaseFontSize)
                FormatButton(icon: "textformat.size.larger", tooltip: "放大字體", action: onIncreaseFontSize)
            }
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
        }
    }
    
    private var listAndAlignControls: some View {
        HStack(spacing: 8) {
            // 對齊
            HStack(spacing: 4) {
                FormatButton(icon: "text.alignleft", tooltip: "靠左對齊", action: onAlignLeft)
                FormatButton(icon: "text.aligncenter", tooltip: "置中對齊", action: onAlignCenter)
                FormatButton(icon: "text.alignright", tooltip: "靠右對齊", action: onAlignRight)
            }
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            
            // 清單
            HStack(spacing: 4) {
                FormatButton(icon: "list.bullet", tooltip: "項目符號", action: { onList?(.bullet) })
                FormatButton(icon: "list.number", tooltip: "編號清單", action: { onList?(.numbered) })
            }
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            
            // 行距
            Menu {
                Button("單行 (1.0)") { onLineSpacing?(1.0) }
                Button("1.15 倍") { onLineSpacing?(1.15) }
                Button("1.5 倍") { onLineSpacing?(1.5) }
                Button("雙倍 (2.0)") { onLineSpacing?(2.0) }
            } label: {
                Label("行距", systemImage: "line.3.horizontal")
                    .font(.system(size: 14, weight: .medium))
                    .frame(height: 28)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 60)
            .padding(4)
            .background(theme.elevated.opacity(0.5))
            .cornerRadius(6)
            .help("行距")
        }
    }
    
    private var chineseOptimizationMenu: some View {
        Menu {
            Button("全形標點轉換") { 
                onChineseOptimization?(.punctuation)
            }
            Button("中英文間距自動調整") { 
                onChineseOptimization?(.spacing)
            }
            Menu("繁簡轉換") {
                Button("轉繁體") { onChineseOptimization?(.toTraditional) }
                Button("轉簡體") { onChineseOptimization?(.toSimplified) }
            }
            Button("台灣學術用語檢查") { 
                onChineseOptimization?(.terminology)
            }
        } label: {
            Label("中文優化", systemImage: "character.book.closed.zh")
                .font(.system(size: 12))
                .padding(6)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
    }
    
    private var nccuTemplateButton: some View {
        Menu {
            Button("套用格式") { onApplyNCCUFormat?() }
            Button("插入封面") { onInsertCover?() }
        } label: {
            Label("政大模版", systemImage: "doc.text.image")
                .font(.system(size: 12))
                .padding(6)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
        .help("政大論文模版工具")
    }
}

// MARK: - 格式化按鈕

struct FormatButton: View {
    let icon: String
    let tooltip: String
    var action: (() -> Void)?
    var disabled: Bool = false

    @State private var isHovered = false

    var body: some View {
        Button(action: { action?() }) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .foregroundColor(disabled ? .gray : .white)
        .help(tooltip)
        .disabled(disabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
