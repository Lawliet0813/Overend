//
//  WriterToolbar.swift
//  OVEREND
//
//  格式工具列 - 提供文字格式化按鈕
//

import SwiftUI
import AppKit

/// 格式工具列
struct WriterToolbar: View {
    @Binding var textView: NSTextView?
    var onCitationRequest: () -> Void
    var onGenerateReferences: () -> Void
    var onExport: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            // 格式按鈕群組
            SwiftUI.Group {
                ToolbarButton(icon: "bold", tooltip: "粗體 (⌘B)") {
                    if let tv = textView {
                        RichTextEditor.toggleBold(in: tv)
                    }
                }
                
                ToolbarButton(icon: "italic", tooltip: "斜體 (⌘I)") {
                    if let tv = textView {
                        RichTextEditor.toggleItalic(in: tv)
                    }
                }
                
                ToolbarButton(icon: "underline", tooltip: "底線 (⌘U)") {
                    if let tv = textView {
                        RichTextEditor.toggleUnderline(in: tv)
                    }
                }
            }
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
            
            // 標題按鈕群組
            SwiftUI.Group {
                ToolbarButton(label: "H1", tooltip: "標題 1") {
                    if let tv = textView {
                        RichTextEditor.applyHeading(level: 1, to: tv)
                    }
                }
                
                ToolbarButton(label: "H2", tooltip: "標題 2") {
                    if let tv = textView {
                        RichTextEditor.applyHeading(level: 2, to: tv)
                    }
                }
                
                ToolbarButton(label: "H3", tooltip: "標題 3") {
                    if let tv = textView {
                        RichTextEditor.applyHeading(level: 3, to: tv)
                    }
                }
            }
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
            
            // 引用功能
            SwiftUI.Group {
                ToolbarButton(icon: "quote.bubble", tooltip: "插入引用 (@)") {
                    onCitationRequest()
                }
                
                ToolbarButton(icon: "list.bullet.rectangle", tooltip: "生成參考文獻 (⌘⇧R)") {
                    onGenerateReferences()
                }
            }
            
            Spacer()
            
            // 匯出按鈕
            ToolbarButton(icon: "square.and.arrow.up", tooltip: "匯出") {
                onExport()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

/// 工具列按鈕
struct ToolbarButton: View {
    var icon: String?
    var label: String?
    var tooltip: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            } else if let label = label {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .frame(minWidth: 24)
            }
        }
        .buttonStyle(.borderless)
        .help(tooltip)
        .frame(width: 32, height: 28)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview {
    WriterToolbar(
        textView: .constant(nil),
        onCitationRequest: {},
        onGenerateReferences: {},
        onExport: {}
    )
    .frame(width: 600)
}
