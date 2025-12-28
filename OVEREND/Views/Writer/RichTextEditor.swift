//
//  RichTextEditor.swift
//  OVEREND
//
//  NSTextView 包裝 - 富文字編輯器核心元件
//

import SwiftUI
import AppKit

/// 富文字編輯器 - NSTextView 的 SwiftUI 包裝
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    var isEditable: Bool = true
    var onTextChange: ((NSAttributedString) -> Void)?
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        // 基本設定
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = isEditable
        textView.isSelectable = true
        
        // 字體與排版（繁體中文優化）
        textView.font = NSFont(name: "PingFang TC", size: 16) ?? NSFont.systemFont(ofSize: 16)
        textView.textColor = .textColor
        
        // 啟用格式功能
        textView.usesFontPanel = true
        textView.usesRuler = false
        textView.importsGraphics = false
        
        // 拼字與文法檢查
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false // 中文不需要
        
        // 自動功能
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        
        // 段落間距優化
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 12
        textView.defaultParagraphStyle = paragraphStyle
        
        // 邊距
        textView.textContainerInset = NSSize(width: 20, height: 20)
        
        // 設定代理
        textView.delegate = context.coordinator
        
        // 初始內容
        textView.textStorage?.setAttributedString(attributedString)
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // 防止更新迴圈
        if !context.coordinator.isUpdating {
            let currentText = textView.attributedString()
            if currentText != attributedString {
                context.coordinator.isUpdating = true
                textView.textStorage?.setAttributedString(attributedString)
                context.coordinator.isUpdating = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var isUpdating = false
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }
            
            isUpdating = true
            let newValue = textView.attributedString()
            parent.attributedString = newValue
            parent.onTextChange?(newValue)
            isUpdating = false
        }
    }
}

// MARK: - 格式化功能擴展

extension RichTextEditor {
    
    /// 套用粗體到選取文字
    static func applyBold(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            if let font = value as? NSFont {
                let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                textStorage.addAttribute(.font, value: boldFont, range: subRange)
            }
        }
        textStorage.endEditing()
    }
    
    /// 套用斜體到選取文字
    static func applyItalic(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            if let font = value as? NSFont {
                let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: italicFont, range: subRange)
            }
        }
        textStorage.endEditing()
    }
    
    /// 套用底線到選取文字
    static func applyUnderline(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        textStorage.beginEditing()
        textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        textStorage.endEditing()
    }
    
    /// 套用標題樣式
    static func applyHeading(level: Int, to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        let fontSize: CGFloat
        switch level {
        case 1: fontSize = 28
        case 2: fontSize = 24
        case 3: fontSize = 20
        default: fontSize = 16
        }
        
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        
        textStorage.beginEditing()
        textStorage.addAttribute(.font, value: font, range: range)
        textStorage.endEditing()
    }
    
    /// 插入引用標記
    static func insertCitation(_ citation: String, at textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let insertPoint = textView.selectedRange().location
        
        // 引用樣式：灰色背景、圓角效果（透過特殊字符模擬）
        let citationAttr = NSMutableAttributedString(string: "[\(citation)]")
        citationAttr.addAttributes([
            .foregroundColor: NSColor.systemBlue,
            .font: NSFont(name: "PingFang TC", size: 16) ?? NSFont.systemFont(ofSize: 16)
        ], range: NSRange(location: 0, length: citationAttr.length))
        
        textStorage.beginEditing()
        textStorage.insert(citationAttr, at: insertPoint)
        textStorage.endEditing()
        
        // 移動游標
        textView.setSelectedRange(NSRange(location: insertPoint + citationAttr.length, length: 0))
    }
}

#Preview {
    RichTextEditor(attributedString: .constant(NSAttributedString(string: "測試文字\n\n這是第二段落。")))
        .frame(width: 600, height: 400)
}
