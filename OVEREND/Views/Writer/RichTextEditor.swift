//
//  RichTextEditor.swift
//  OVEREND
//
//  NSTextView 包裝 - 富文字編輯器核心元件（類 Word 體驗）
//

import SwiftUI
import AppKit

/// 富文字編輯器 - NSTextView 的 SwiftUI 包裝，提供類似 Word 的編輯體驗
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    var isEditable: Bool = true
    var onTextChange: ((NSAttributedString) -> Void)?
    var onSelectionChange: ((NSRange, [NSAttributedString.Key: Any]) -> Void)?
    
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
        let defaultFont = NSFont(name: "PingFang TC", size: 14) ?? NSFont.systemFont(ofSize: 14)
        textView.font = defaultFont
        textView.textColor = .textColor
        
        // 啟用格式功能
        textView.usesFontPanel = true
        textView.usesRuler = true  // 啟用標尺以支援對齊和縮排
        textView.importsGraphics = true  // 允許拖放圖片
        
        // 拼字與文法檢查
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false // 中文不需要
        
        // 自動功能（類似 Word）
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticLinkDetectionEnabled = true  // 自動檢測連結
        
        // 智能功能
        textView.smartInsertDeleteEnabled = true
        textView.isAutomaticDataDetectionEnabled = true
        
        // 段落間距優化（類似 Word 預設）
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0  // Word 預設無額外行距
        paragraphStyle.paragraphSpacing = 10  // 段落後間距
        paragraphStyle.lineHeightMultiple = 1.15  // 1.15 倍行高（Word 預設）
        textView.defaultParagraphStyle = paragraphStyle
        
        // 頁面邊距（類似 Word A4 邊距）
        textView.textContainerInset = NSSize(width: 72, height: 72)  // 1 英寸邊距
        
        // 設定代理
        textView.delegate = context.coordinator
        
        // 初始內容
        textView.textStorage?.setAttributedString(attributedString)
        
        // 儲存到 coordinator
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // 防止更新迴圈
        if !context.coordinator.isUpdating {
            let currentText = textView.attributedString()
            if currentText != attributedString {
                context.coordinator.isUpdating = true
                
                // 保存當前選取範圍
                let selectedRange = textView.selectedRange()
                
                textView.textStorage?.setAttributedString(attributedString)
                
                // 恢復選取範圍（如果合法）
                if selectedRange.location <= attributedString.length {
                    textView.setSelectedRange(selectedRange)
                }
                
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
        weak var textView: NSTextView?
        
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
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            let selectedRange = textView.selectedRange()
            let attributes = textView.typingAttributes
            parent.onSelectionChange?(selectedRange, attributes)
        }
    }
}

// MARK: - 格式化功能擴展（類 Word 功能）

extension RichTextEditor {
    
    /// 套用粗體到選取文字（切換式）
    static func toggleBold(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        // 如果沒有選取，修改 typing attributes
        if range.length == 0 {
            var attrs = textView.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                let newFont = isBold ? 
                    NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask) :
                    NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                attrs[.font] = newFont
                textView.typingAttributes = attrs
            }
            return
        }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            if let font = value as? NSFont {
                let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                let newFont = isBold ?
                    NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask) :
                    NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                textStorage.addAttribute(.font, value: newFont, range: subRange)
            }
        }
        textStorage.endEditing()
    }
    
    /// 套用斜體到選取文字（切換式）
    static func toggleItalic(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        if range.length == 0 {
            var attrs = textView.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                let newFont = isItalic ?
                    NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask) :
                    NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                attrs[.font] = newFont
                textView.typingAttributes = attrs
            }
            return
        }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            if let font = value as? NSFont {
                let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                let newFont = isItalic ?
                    NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask) :
                    NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: newFont, range: subRange)
            }
        }
        textStorage.endEditing()
    }
    
    /// 套用底線到選取文字（切換式）
    static func toggleUnderline(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        if range.length == 0 {
            var attrs = textView.typingAttributes
            let hasUnderline = (attrs[.underlineStyle] as? Int) != nil
            if hasUnderline {
                attrs.removeValue(forKey: .underlineStyle)
            } else {
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            textView.typingAttributes = attrs
            return
        }
        
        textStorage.beginEditing()
        
        // 檢查選取範圍是否已有底線
        var hasUnderline = false
        textStorage.enumerateAttribute(.underlineStyle, in: range) { value, _, stop in
            if value != nil {
                hasUnderline = true
                stop.pointee = true
            }
        }
        
        if hasUnderline {
            textStorage.removeAttribute(.underlineStyle, range: range)
        } else {
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        
        textStorage.endEditing()
    }
    
    /// 設定文字顏色
    static func setTextColor(_ color: NSColor, in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        if range.length == 0 {
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = color
            textView.typingAttributes = attrs
            return
        }
        
        textStorage.beginEditing()
        textStorage.addAttribute(.foregroundColor, value: color, range: range)
        textStorage.endEditing()
    }
    
    /// 設定背景顏色（螢光筆效果）
    static func setHighlightColor(_ color: NSColor, in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        if range.length == 0 {
            var attrs = textView.typingAttributes
            attrs[.backgroundColor] = color
            textView.typingAttributes = attrs
            return
        }
        
        textStorage.beginEditing()
        textStorage.addAttribute(.backgroundColor, value: color, range: range)
        textStorage.endEditing()
    }
    
    /// 設定字體大小
    static func setFontSize(_ size: CGFloat, in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        if range.length == 0 {
            var attrs = textView.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let newFont = NSFont(descriptor: font.fontDescriptor, size: size) ?? font
                attrs[.font] = newFont
                textView.typingAttributes = attrs
            }
            return
        }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            if let font = value as? NSFont {
                let newFont = NSFont(descriptor: font.fontDescriptor, size: size) ?? font
                textStorage.addAttribute(.font, value: newFont, range: subRange)
            }
        }
        textStorage.endEditing()
    }
    
    /// 設定字體
    static func setFontFamily(_ familyName: String, in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        let size: CGFloat = 14
        
        if range.length == 0 {
            var attrs = textView.typingAttributes
            let currentSize = (attrs[.font] as? NSFont)?.pointSize ?? size
            let newFont = NSFont(name: familyName, size: currentSize) ?? NSFont.systemFont(ofSize: currentSize)
            attrs[.font] = newFont
            textView.typingAttributes = attrs
            return
        }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let currentSize = (value as? NSFont)?.pointSize ?? size
            let newFont = NSFont(name: familyName, size: currentSize) ?? NSFont.systemFont(ofSize: currentSize)
            textStorage.addAttribute(.font, value: newFont, range: subRange)
        }
        textStorage.endEditing()
    }
    
    /// 設定文字對齊
    static func setAlignment(_ alignment: NSTextAlignment, in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        
        // 獲取段落範圍
        let paragraphRange = (textStorage.string as NSString).paragraphRange(for: range)
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.paragraphStyle, in: paragraphRange) { value, subRange, _ in
            let paragraphStyle: NSMutableParagraphStyle
            if let existingStyle = value as? NSParagraphStyle {
                paragraphStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
            } else {
                paragraphStyle = NSMutableParagraphStyle()
            }
            
            paragraphStyle.alignment = alignment
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: subRange)
        }
        textStorage.endEditing()
    }
    
    /// 套用標題樣式
    static func applyHeading(level: Int, to textView: NSTextView) {
        let fontSize: CGFloat
        switch level {
        case 1: fontSize = 24
        case 2: fontSize = 20
        case 3: fontSize = 18
        case 4: fontSize = 16
        default: fontSize = 14
        }
        
        setFontSize(fontSize, in: textView)
        toggleBold(in: textView)
    }
    
    /// 插入項目符號列表
    static func toggleBulletList(in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        let paragraphRange = (textStorage.string as NSString).paragraphRange(for: range)
        
        textStorage.beginEditing()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
        
        // 在段落開頭插入項目符號
        if paragraphRange.location < textStorage.length {
            let paragraphStart = paragraphRange.location
            let bullet = "• "
            let bulletAttr = NSAttributedString(string: bullet)
            textStorage.insert(bulletAttr, at: paragraphStart)
        }
        
        textStorage.endEditing()
    }
    
    /// 插入引用標記
    static func insertCitation(_ citation: String, at textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let insertPoint = textView.selectedRange().location
        
        // 引用樣式：藍色文字
        let citationAttr = NSMutableAttributedString(string: "[\(citation)]")
        citationAttr.addAttributes([
            .foregroundColor: NSColor.systemBlue,
            .font: textView.font ?? NSFont.systemFont(ofSize: 14),
            .link: "citation://\(citation)"  // 添加連結屬性以便點擊
        ], range: NSRange(location: 0, length: citationAttr.length))
        
        textStorage.beginEditing()
        textStorage.insert(citationAttr, at: insertPoint)
        textStorage.endEditing()
        
        // 移動游標
        textView.setSelectedRange(NSRange(location: insertPoint + citationAttr.length, length: 0))
    }
    
    /// 獲取當前選取範圍的格式屬性
    static func getCurrentAttributes(from textView: NSTextView) -> [NSAttributedString.Key: Any] {
        let range = textView.selectedRange()
        
        if range.length == 0 {
            return textView.typingAttributes
        }
        
        guard let textStorage = textView.textStorage,
              range.location < textStorage.length else {
            return textView.typingAttributes
        }
        
        return textStorage.attributes(at: range.location, effectiveRange: nil)
    }
    
    /// 檢查當前是否為粗體
    static func isBold(in textView: NSTextView) -> Bool {
        let attrs = getCurrentAttributes(from: textView)
        if let font = attrs[.font] as? NSFont {
            return font.fontDescriptor.symbolicTraits.contains(.bold)
        }
        return false
    }
    
    /// 檢查當前是否為斜體
    static func isItalic(in textView: NSTextView) -> Bool {
        let attrs = getCurrentAttributes(from: textView)
        if let font = attrs[.font] as? NSFont {
            return font.fontDescriptor.symbolicTraits.contains(.italic)
        }
        return false
    }
    
    /// 檢查當前是否有底線
    static func isUnderlined(in textView: NSTextView) -> Bool {
        let attrs = getCurrentAttributes(from: textView)
        return attrs[.underlineStyle] != nil
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = NSAttributedString(string: "這是測試文字\n\n您可以選取文字並套用格式。")
        
        var body: some View {
            RichTextEditor(attributedString: $text)
                .frame(width: 600, height: 400)
        }
    }
    
    return PreviewWrapper()
}
