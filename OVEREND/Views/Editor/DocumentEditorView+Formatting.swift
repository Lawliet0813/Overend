//
//  DocumentEditorView+Formatting.swift
//  OVEREND
//
//  編輯器格式化方法 - 從 DocumentEditorView 拆分
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 格式化方法擴展

extension DocumentEditorView {
    
    // MARK: - 字體
    
    func applyFont(_ fontName: String) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else {
            currentFont = fontName
            if let font = NSFont(name: fontName, size: 12) {
                textView.typingAttributes[.font] = font
            }
            return
        }

        guard let textStorage = textView.textStorage else { return }

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            guard let currentFont = value as? NSFont else { return }
            let fontSize = currentFont.pointSize
            let traits = currentFont.fontDescriptor.symbolicTraits

            if let newFont = NSFont(name: fontName, size: fontSize) {
                var finalFont = newFont
                if traits.contains(.bold) {
                    finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .boldFontMask)
                }
                if traits.contains(.italic) {
                    finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .italicFontMask)
                }
                textStorage.addAttribute(.font, value: finalFont, range: attrRange)
            }
        }
        textStorage.endEditing()

        currentFont = fontName
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 基本格式
    
    func applyFormat(_ style: FormatStyle) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            guard let currentFont = value as? NSFont else { return }
            
            var newFont: NSFont
            let traits = currentFont.fontDescriptor.symbolicTraits
            
            switch style {
            case .bold:
                if traits.contains(.bold) {
                    newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
                }
            case .italic:
                if traits.contains(.italic) {
                    newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
                }
            case .underline:
                let hasUnderline = textStorage.attribute(.underlineStyle, at: attrRange.location, effectiveRange: nil) != nil
                if hasUnderline {
                    textStorage.removeAttribute(.underlineStyle, range: attrRange)
                } else {
                    textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: attrRange)
                }
                return
            case .strikethrough:
                let hasStrikethrough = textStorage.attribute(.strikethroughStyle, at: attrRange.location, effectiveRange: nil) != nil
                if hasStrikethrough {
                    textStorage.removeAttribute(.strikethroughStyle, range: attrRange)
                } else {
                    textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: attrRange)
                }
                return
            }
            
            textStorage.addAttribute(.font, value: newFont, range: attrRange)
        }
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 對齊
    
    func applyAlignment(_ alignment: NSTextAlignment) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        textStorage.beginEditing()
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 字體大小
    
    func adjustFontSize(by delta: CGFloat) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            guard let currentFont = value as? NSFont else { return }
            let newSize = max(8, currentFont.pointSize + delta)
            let newFont = NSFont(descriptor: currentFont.fontDescriptor, size: newSize) ?? currentFont
            textStorage.addAttribute(.font, value: newFont, range: attrRange)
        }
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 行距
    
    func applyLineSpacing(_ spacing: CGFloat) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = spacing
        
        textStorage.beginEditing()
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("行距已設為 \(spacing) 倍")
    }
    
    // MARK: - 文字顏色
    
    func applyTextColor(_ color: NSColor) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        textStorage.addAttribute(.foregroundColor, value: color, range: range)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 螢光標記
    
    func applyHighlight(_ color: NSColor) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        if color == .clear {
            textStorage.removeAttribute(.backgroundColor, range: range)
        } else {
            textStorage.addAttribute(.backgroundColor, value: color, range: range)
        }
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 標題
    
    func applyHeading(_ level: HeadingLevel) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        let paragraphRange = (textView.string as NSString).paragraphRange(for: range)
        
        guard let textStorage = textView.textStorage else { return }
        
        textStorage.beginEditing()
        
        let font = NSFont.systemFont(ofSize: level.fontSize, weight: level == .normal ? .regular : .bold)
        textStorage.addAttribute(.font, value: font, range: paragraphRange)
        
        let paragraphStyle = NSMutableParagraphStyle()
        if level != .normal {
            paragraphStyle.paragraphSpacing = 12
            paragraphStyle.paragraphSpacingBefore = 6
        }
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
        
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 列表
    
    func applyList(_ type: ListType) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        let paragraphRange = (textView.string as NSString).paragraphRange(for: range)
        
        guard let textStorage = textView.textStorage else { return }
        
        let marker = type == .bullet ? "•\t" : "1.\t"
        
        textStorage.beginEditing()
        
        let currentText = (textView.string as NSString).substring(with: paragraphRange)
        if currentText.hasPrefix("•\t") || currentText.range(of: #"^\d+\.\t"#, options: .regularExpression) != nil {
            // Already has list marker
        } else {
            textStorage.insert(NSAttributedString(string: marker), at: paragraphRange.location)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20, options: [:])]
            
            let newRange = NSRange(location: paragraphRange.location, length: paragraphRange.length + marker.count)
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: newRange)
        }
        
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
    }
    
    // MARK: - 插入元素
    
    func insertElement(_ type: InsertType) {
        guard let textView = textViewRef else { return }
        
        switch type {
        case .image:
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.begin { response in
                if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    attachment.bounds = CGRect(x: 0, y: 0, width: 300, height: 300 * (image.size.height / image.size.width))
                    
                    let attrString = NSAttributedString(attachment: attachment)
                    textView.textStorage?.insert(attrString, at: textView.selectedRange().location)
                    self.saveDocument()
                }
            }
        case .table:
            let tablePlaceholder = "\n| Column 1 | Column 2 |\n| -------- | -------- |\n| Cell 1   | Cell 2   |\n"
            textView.insertText(tablePlaceholder, replacementRange: textView.selectedRange())
            saveDocument()
        case .footnote:
            let footnote = " [^1]"
            textView.insertText(footnote, replacementRange: textView.selectedRange())
            saveDocument()
        }
    }
    
    // MARK: - 中文優化
    
    func applyChineseOptimization(_ type: ChineseOptimizationType) {
        guard let textView = textViewRef else { return }
        let range = textView.selectedRange()
        let replaceRange = range.length > 0 ? range : NSRange(location: 0, length: textView.string.count)
        
        guard let textStorage = textView.textStorage else { return }
        let currentText = (textView.string as NSString).substring(with: replaceRange)
        var newText = currentText
        
        switch type {
        case .punctuation:
            newText = ChineseOptimizationService.shared.convertToFullWidthPunctuation(currentText)
        case .spacing:
            newText = ChineseOptimizationService.shared.adjustSpacing(currentText)
        case .toTraditional:
            newText = ChineseOptimizationService.shared.convertScript(currentText, to: .traditional)
        case .toSimplified:
            newText = ChineseOptimizationService.shared.convertScript(currentText, to: .simplified)
        case .terminology:
            let suggestions = ChineseOptimizationService.shared.checkTerminology(currentText)
            if suggestions.isEmpty {
                ToastManager.shared.showSuccess("未發現需修正的術語")
                return
            }
            for suggestion in suggestions {
                newText = newText.replacingOccurrences(of: suggestion.original, with: suggestion.suggestion)
            }
            ToastManager.shared.showSuccess("已修正 \(suggestions.count) 個術語")
        }
        
        if newText != currentText {
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: replaceRange, with: newText)
            textStorage.endEditing()
            
            attributedText = textView.attributedString()
            saveDocument()
            ToastManager.shared.showSuccess("中文優化完成")
        }
    }
    
    // MARK: - NCCU 格式
    
    func applyNCCUFormat() {
        guard let textView = textViewRef, let textStorage = textView.textStorage else { return }
        
        NCCUFormatService.shared.applyFormat(to: textStorage)
        
        attributedText = textView.attributedString()
        saveDocument()
        ToastManager.shared.showSuccess("已套用政大論文格式")
    }

    // MARK: - AI Rewrite
    
    func applyAIRewrite(_ newText: String) {
        guard let textView = textViewRef else { return }
        
        // 如果有選取文字，替換選取部分；否則替換全文
        let range = textView.selectedRange()
        let replaceRange = range.length > 0 ? range : NSRange(location: 0, length: textView.string.count)
        
        guard let textStorage = textView.textStorage else { return }
        
        // 保持原有格式，只替換文字內容
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        let newAttributed = NSAttributedString(string: newText, attributes: attributes)
        
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: replaceRange, with: newAttributed)
        textStorage.endEditing()
        
        attributedText = textView.attributedString()
        saveDocument()
        
        ToastManager.shared.showSuccess("AI 調整完成")
    }
}

