//
//  DynamicTagProcessor.swift
//  OVEREND
//
//  動態標籤處理器 - 在 NSAttributedString 中處理 {{TAG}} 替換
//

import Foundation
import AppKit

/// 動態標籤處理器 - 負責解析與替換動態標籤
class DynamicTagProcessor {
    /// 標籤正則表達式：匹配 {{TAG_NAME}}
    private static let tagPattern = #"\{\{([A-Z_\u4e00-\u9fff]+)\}\}"#

    /// 解析並替換文字中的所有動態標籤
    static func process(attributedString: NSAttributedString, metadata: ThesisMetadata) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let text = mutableString.string

        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return attributedString
        }

        // 從後往前替換，避免索引偏移問題
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))

        for match in matches.reversed() {
            guard match.numberOfRanges >= 2 else { continue }

            let fullRange = match.range(at: 0) // 包含 {{ }}
            let tagNameRange = match.range(at: 1) // 只有標籤名稱

            let tagName = (text as NSString).substring(with: tagNameRange)
            let resolvedValue = metadata.resolveTag(tagName)

            // 保留原有的文字屬性（字體、顏色等）
            let attributes = mutableString.attributes(at: fullRange.location, effectiveRange: nil)

            // 創建替換字串（添加特殊標記以便未來識別）
            let replacementString = NSMutableAttributedString(string: resolvedValue, attributes: attributes)

            // 添加自訂屬性以標記這是動態標籤
            replacementString.addAttribute(
                .init("DynamicTag"),
                value: tagName,
                range: NSRange(location: 0, length: replacementString.length)
            )

            // 添加視覺標記（底色）
            replacementString.addAttribute(
                .backgroundColor,
                value: NSColor.systemBlue.withAlphaComponent(0.1),
                range: NSRange(location: 0, length: replacementString.length)
            )

            // 替換
            mutableString.replaceCharacters(in: fullRange, with: replacementString)
        }

        return mutableString
    }

    /// 檢測字串中是否包含動態標籤
    static func containsTags(in text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return false
        }
        return regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) != nil
    }

    /// 提取字串中的所有動態標籤
    static func extractTags(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return []
        }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        return matches.compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            let tagNameRange = match.range(at: 1)
            return (text as NSString).substring(with: tagNameRange)
        }
    }

    /// 還原動態標籤（將解析後的值轉回 {{TAG}}）
    static func restoreTags(attributedString: NSAttributedString) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)

        // 從後往前遍歷，找到所有帶有 DynamicTag 屬性的範圍
        var ranges: [(NSRange, String)] = []

        mutableString.enumerateAttribute(.init("DynamicTag"), in: fullRange, options: .reverse) { value, range, _ in
            if let tagName = value as? String {
                ranges.append((range, tagName))
            }
        }

        // 替換回標籤格式
        for (range, tagName) in ranges {
            let tagString = "{{\(tagName)}}"
            let attributes = mutableString.attributes(at: range.location, effectiveRange: nil)

            // 移除動態標籤相關屬性
            var cleanAttributes = attributes
            cleanAttributes.removeValue(forKey: .init("DynamicTag"))
            cleanAttributes.removeValue(forKey: .backgroundColor)

            let replacementString = NSAttributedString(string: tagString, attributes: cleanAttributes)
            mutableString.replaceCharacters(in: range, with: replacementString)
        }

        return mutableString
    }

    /// 實時監聽並更新動態標籤
    static func setupLiveUpdate(
        for textView: NSTextView,
        metadata: ThesisMetadata,
        updateInterval: TimeInterval = 0.5
    ) -> Timer {
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            guard let textStorage = textView.textStorage else { return }

            // 檢查是否有動態標籤需要更新
            let currentText = textStorage.string
            if containsTags(in: currentText) || hasDynamicTags(in: textStorage) {
                let processedString = process(attributedString: textStorage, metadata: metadata)

                // 只在內容確實改變時更新（避免無限循環）
                if processedString.string != textStorage.string {
                    let selectedRange = textView.selectedRange()

                    textStorage.beginEditing()
                    textStorage.setAttributedString(processedString)
                    textStorage.endEditing()

                    // 恢復選取範圍
                    if selectedRange.location <= textStorage.length {
                        textView.setSelectedRange(selectedRange)
                    }
                }
            }
        }
    }

    /// 檢查 AttributedString 是否包含動態標籤屬性
    private static func hasDynamicTags(in attributedString: NSAttributedString) -> Bool {
        var hasTags = false
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttribute(.init("DynamicTag"), in: fullRange, options: []) { value, _, stop in
            if value != nil {
                hasTags = true
                stop.pointee = true
            }
        }

        return hasTags
    }

    /// 插入動態標籤到游標位置
    static func insertTag(_ tagName: String, into textView: NSTextView, metadata: ThesisMetadata) {
        guard let textStorage = textView.textStorage else { return }

        let selectedRange = textView.selectedRange()
        let tagString = "{{\(tagName)}}"

        // 創建標籤字串
        let attributes = textView.typingAttributes
        let tagAttributedString = NSAttributedString(string: tagString, attributes: attributes)

        // 插入
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: selectedRange, with: tagAttributedString)
        textStorage.endEditing()

        // 移動游標到標籤後面
        let newPosition = selectedRange.location + tagString.count
        textView.setSelectedRange(NSRange(location: newPosition, length: 0))

        // 立即處理以顯示解析結果
        let processedString = process(attributedString: textStorage, metadata: metadata)
        textStorage.setAttributedString(processedString)
    }
}

// MARK: - NSAttributedString.Key 擴展

extension NSAttributedString.Key {
    static let dynamicTag = NSAttributedString.Key("DynamicTag")
}

// MARK: - 便利方法

extension NSAttributedString {
    /// 檢查是否包含動態標籤
    var containsDynamicTags: Bool {
        DynamicTagProcessor.containsTags(in: self.string)
    }

    /// 提取所有動態標籤
    var dynamicTags: [String] {
        DynamicTagProcessor.extractTags(from: self.string)
    }

    /// 處理動態標籤
    func processingTags(with metadata: ThesisMetadata) -> NSAttributedString {
        DynamicTagProcessor.process(attributedString: self, metadata: metadata)
    }
}
