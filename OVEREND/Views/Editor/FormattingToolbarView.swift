//
//  FormattingToolbarView.swift
//  OVEREND
//
//  格式化工具欄 - 提供文本格式化選項
//

import SwiftUI
import AppKit

struct FormattingToolbarView: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var viewModel: WritingAssistantViewModel
    @Binding var showColorPicker: Bool
    @Binding var showLinkDialog: Bool
    @State private var showLineSpacing = false
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var selectedHighlightColor: Color = .yellow

    // 字體選項
    private let fonts = [
        "Helvetica Neue",
        "Arial",
        "Times New Roman",
        "Georgia",
        "Courier New",
        "Menlo",
        "SF Pro Display"
    ]

    // 字體大小選項
    private let fontSizes: [CGFloat] = [10, 11, 12, 14, 16, 18, 24, 36]

    // 行距選項
    private let lineSpacings: [(label: String, value: CGFloat)] = [
        ("1.0", 1.0),
        ("1.15", 1.15),
        ("1.5", 1.5),
        ("2.0", 2.0)
    ]

    // 標題選項
    private let headingOptions: [(label: String, fontSize: CGFloat, weight: NSFont.Weight)] = [
        ("內文", 12, .regular),
        ("標題 1", 24, .bold),
        ("標題 2", 18, .bold),
        ("標題 3", 14, .semibold)
    ]

    // 螢光筆顏色
    private let highlightColors: [(name: String, color: Color)] = [
        ("無", .clear),
        ("黃色", .yellow),
        ("綠色", .green),
        ("藍色", .blue.opacity(0.3)),
        ("粉紅", .pink.opacity(0.5)),
        ("橘色", .orange.opacity(0.5))
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // MARK: - 標題樣式選單
                Menu {
                    ForEach(headingOptions.indices, id: \.self) { index in
                        Button(headingOptions[index].label) {
                            applyHeading(index)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("內文")
                            .font(theme.fontBodySmall)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(theme.elevated)
                    .cornerRadius(theme.cornerRadiusSM)
                }
                .help("標題樣式")

                WritingToolbarSeparator()

                // MARK: - 字體選擇
                Menu {
                    ForEach(fonts, id: \.self) { font in
                        Button(font) {
                            viewModel.selectedFontFamily = font
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedFontFamily)
                            .font(theme.fontBodySmall)
                            .lineLimit(1)
                            .frame(maxWidth: 100)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(theme.elevated)
                    .cornerRadius(theme.cornerRadiusSM)
                }
                .help("字體")

                // 字體大小
                Menu {
                    ForEach(fontSizes, id: \.self) { size in
                        Button("\(Int(size))") {
                            viewModel.selectedFontSize = size
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(Int(viewModel.selectedFontSize))")
                            .font(theme.fontBodySmall)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(theme.elevated)
                    .cornerRadius(theme.cornerRadiusSM)
                }
                .help("字體大小")

                WritingToolbarSeparator()

                // MARK: - 基本格式
                // 粗體
                WritingToolbarButton(
                    icon: "bold",
                    action: {
                        viewModel.toggleBold(for: selectedRange)
                    }
                )
                .help("粗體 ⌘B")

                // 斜體
                WritingToolbarButton(
                    icon: "italic",
                    action: {
                        viewModel.toggleItalic(for: selectedRange)
                    }
                )
                .help("斜體 ⌘I")

                // 底線
                WritingToolbarButton(
                    icon: "underline",
                    action: {
                        viewModel.toggleUnderline(for: selectedRange)
                    }
                )
                .help("底線 ⌘U")

                // 刪除線
                WritingToolbarButton(
                    icon: "strikethrough",
                    action: {
                        viewModel.toggleStrikethrough(for: selectedRange)
                    }
                )
                .help("刪除線")

                WritingToolbarSeparator()

                // MARK: - 顏色
                // 文字顏色
                ColorPicker("", selection: Binding(
                    get: { Color(viewModel.selectedTextColor) },
                    set: { viewModel.selectedTextColor = NSColor($0) }
                ))
                .labelsHidden()
                .frame(width: 28, height: 28)
                .help("文字顏色")

                // 螢光筆
                Menu {
                    ForEach(highlightColors, id: \.name) { item in
                        Button {
                            if item.color == .clear {
                                viewModel.removeHighlight(for: selectedRange)
                            } else {
                                viewModel.applyHighlight(NSColor(item.color), for: selectedRange)
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(item.color == .clear ? Color.gray.opacity(0.3) : item.color)
                                    .frame(width: 16, height: 16)
                                Text(item.name)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "highlighter")
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(theme.elevated)
                        .cornerRadius(theme.cornerRadiusSM)
                }
                .help("螢光筆")

                // 連結
                WritingToolbarButton(
                    icon: "link",
                    action: {
                        showLinkDialog = true
                    }
                )
                .help("插入連結")

                WritingToolbarSeparator()

                // MARK: - 對齊
                // 左對齊
                WritingToolbarButton(
                    icon: "text.alignleft",
                    action: {
                        applyAlignment(.left)
                    }
                )
                .help("左對齊")

                // 置中對齊
                WritingToolbarButton(
                    icon: "text.aligncenter",
                    action: {
                        applyAlignment(.center)
                    }
                )
                .help("置中對齊")

                // 右對齊
                WritingToolbarButton(
                    icon: "text.alignright",
                    action: {
                        applyAlignment(.right)
                    }
                )
                .help("右對齊")

                WritingToolbarSeparator()

                // 行距
                Menu {
                    ForEach(lineSpacings, id: \.label) { spacing in
                        Button(spacing.label) {
                            viewModel.lineSpacing = spacing.value
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 28, height: 28)
                }
                .help("行距")

                WritingToolbarSeparator()

                // MARK: - 列表
                // 項目符號列表
                WritingToolbarButton(
                    icon: "list.bullet",
                    action: {
                        viewModel.applyBulletList(for: selectedRange)
                    }
                )
                .help("項目符號列表")

                // 編號列表
                WritingToolbarButton(
                    icon: "list.number",
                    action: {
                        viewModel.applyNumberedList(for: selectedRange)
                    }
                )
                .help("編號列表")

                // 減少縮排
                WritingToolbarButton(
                    icon: "decrease.indent",
                    action: {
                        viewModel.decreaseIndent(for: selectedRange)
                    }
                )
                .help("減少縮排")

                // 增加縮排
                WritingToolbarButton(
                    icon: "increase.indent",
                    action: {
                        viewModel.increaseIndent(for: selectedRange)
                    }
                )
                .help("增加縮排")

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(theme.functional)
    }

    // MARK: - Helper Methods

    private func applyAlignment(_ alignment: NSTextAlignment) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = viewModel.lineSpacing

        viewModel.applyFormatting(
            to: selectedRange,
            attributes: [.paragraphStyle: paragraphStyle]
        )
    }

    private func applyHeading(_ index: Int) {
        guard index < headingOptions.count else { return }
        let option = headingOptions[index]

        if let font = NSFont(name: viewModel.selectedFontFamily, size: option.fontSize) {
            let trait: NSFontTraitMask = option.weight == .bold ? .boldFontMask : []
            let weightedFont = NSFontManager.shared.convert(font, toHaveTrait: trait)
            viewModel.applyFormatting(
                to: selectedRange,
                attributes: [.font: weightedFont]
            )
        }
    }
}

// MARK: - Toolbar Components

struct WritingToolbarButton: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    let action: () -> Void
    var isActive: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(isActive ? .white : theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(isActive ? theme.accent : Color.clear)
                .cornerRadius(theme.cornerRadiusSM)
        }
        .buttonStyle(.plain)
    }
}

struct WritingToolbarSeparator: View {
    @EnvironmentObject var theme: AppTheme

    var body: some View {
        Rectangle()
            .fill(theme.border)
            .frame(width: 1, height: 24)
    }
}

#Preview {
    FormattingToolbarView(
        viewModel: WritingAssistantViewModel(),
        showColorPicker: .constant(false),
        showLinkDialog: .constant(false)
    )
    .environmentObject(AppTheme())
    .frame(width: 1000)
}
