//
//  RichTextEditorWrapper.swift
//  OVEREND
//
//  富文本編輯器包裝器 - 使用 NSTextView
//

import SwiftUI
import AppKit

struct RichTextEditorWrapper: NSViewRepresentable {
    @Binding var attributedText: NSMutableAttributedString
    @Binding var selectedRange: NSRange
    let highlights: [WritingTextHighlight]

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // 配置 TextView
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.usesFontPanel = true
        textView.importsGraphics = false
        textView.delegate = context.coordinator

        // 設置字體
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.textColor = .textColor

        // 設置背景和插入點
        textView.backgroundColor = NSColor(white: 0.95, alpha: 1.0)
        textView.insertionPointColor = .textColor

        // 設置邊距
        textView.textContainerInset = NSSize(width: 20, height: 20)

        // 設置文本容器
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.lineBreakMode = .byWordWrapping
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // 更新文本（如果不同）
        if textView.attributedString() != attributedText {
            let savedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)
            textView.setSelectedRange(savedRange)
        }

        // 應用高亮
        applyHighlights(to: textView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorWrapper

        init(_ parent: RichTextEditorWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // 更新 attributedText - 使用 async 避免 Modifying state during view update
            if let textStorage = textView.textStorage {
                let newText = NSMutableAttributedString(attributedString: textStorage)
                DispatchQueue.main.async {
                    self.parent.attributedText = newText
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let range = textView.selectedRange()
            
            // 使用 async 避免 Modifying state during view update
            DispatchQueue.main.async {
                self.parent.selectedRange = range
            }
        }

        // MARK: - Paste Handling

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // 允許正常的文本變更
            return true
        }

        // MARK: - Copy Handling

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            return newSelectedCharRange
        }
    }

    // MARK: - Highlight Application

    private func applyHighlights(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let text = textStorage.string

        // 先清除所有背景色
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.removeAttribute(.backgroundColor, range: fullRange)

        // 應用新的高亮
        for highlight in highlights {
            guard let range = highlight.range else { continue }

            // 轉換 Range<String.Index> 到 NSRange
            let nsRange = NSRange(range, in: text)

            if nsRange.location != NSNotFound,
               nsRange.location + nsRange.length <= textStorage.length {

                let color = NSColor(highlight.color).withAlphaComponent(0.3)
                textStorage.addAttribute(.backgroundColor, value: color, range: nsRange)
            }
        }
    }
}

// MARK: - Preview Helper

#Preview {
    RichTextEditorWrapper(
        attributedText: .constant(NSMutableAttributedString(string: "Hello, World!\n\nThis is a rich text editor with formatting support.")),
        selectedRange: .constant(NSRange(location: 0, length: 0)),
        highlights: []
    )
    .frame(width: 600, height: 400)
}
