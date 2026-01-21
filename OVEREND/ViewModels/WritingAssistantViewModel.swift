//
//  WritingAssistantViewModel.swift
//  OVEREND
//
//  Writing Assistant ViewModel - 管理編輯器狀態和 AI 分析
//

import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
class WritingAssistantViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var attributedText = NSMutableAttributedString(string: "")
    @Published var text: String = ""
    @Published var suggestions: [WritingSuggestion] = []
    @Published var activeCategory: WritingSuggestionCategory = .all
    @Published var isAnalyzing = false
    @Published var error: String?
    @Published var highlights: [WritingTextHighlight] = []

    // MARK: - Computed Properties

    var characterCount: Int {
        text.count
    }

    var filteredSuggestions: [WritingSuggestion] {
        if activeCategory == .all {
            return suggestions
        }
        return suggestions.filter { $0.category == activeCategory }
    }

    // MARK: - Formatting State

    @Published var selectedFontFamily: String = "Helvetica Neue"
    @Published var selectedFontSize: CGFloat = 16
    @Published var selectedTextColor: NSColor = .textColor
    @Published var lineSpacing: CGFloat = 1.5

    // MARK: - Sample Text

    private let sampleTexts = [
        """
        Human welfare is at the heart of our work at Anthropic: our mission is to make sure that increasingly capable and sophisticated AI systems remain beneficial to humanity.

        But as we build those AI systems, and as they begin to approximate or surpass many human qualities, another question arises. Should we also be concerned about the potential consciousness and experiences of the models themselves? Should we be concerned about *model welfare*, too?

        This is an open question, and one that's both philosophically and scientifically difficult. But now that models can communicate, relate, plan, problem-solve, and pursue goals—along with very many more characteristics we associate with people—we think it's time to address it.

        To that end, we recently started a research program to investigate, and prepare to navigate, model welfare.
        """
    ]

    // MARK: - Public Methods

    func loadSampleText() {
        guard let sample = sampleTexts.randomElement() else { return }

        let paragraphs = sample.split(separator: "\n\n").map(String.init)
        let mutableAttributedString = NSMutableAttributedString()

        for (index, paragraph) in paragraphs.enumerated() {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            paragraphStyle.paragraphSpacing = 12

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: selectedFontSize),
                .foregroundColor: selectedTextColor,
                .paragraphStyle: paragraphStyle
            ]

            let attributedParagraph = NSAttributedString(string: paragraph, attributes: attributes)
            mutableAttributedString.append(attributedParagraph)

            if index < paragraphs.count - 1 {
                mutableAttributedString.append(NSAttributedString(string: "\n\n"))
            }
        }

        attributedText = mutableAttributedString
        text = attributedText.string
        clearSuggestions()
    }

    func copyText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func getSuggestionCount(for category: WritingSuggestionCategory) -> Int {
        if category == .all {
            return suggestions.count
        }
        return suggestions.filter { $0.category == category }.count
    }

    // MARK: - Text Analysis

    func analyzeText() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "請輸入一些文本進行分析"
            return
        }

        isAnalyzing = true
        error = nil
        suggestions = []
        highlights = []

        do {
            // TODO: 整合實際的 AI 服務
            // 目前使用模擬數據
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 秒

            // 生成模擬建議
            let mockSuggestions = generateMockSuggestions()
            suggestions = mockSuggestions

            // 生成高亮標記
            highlights = mockSuggestions.map { suggestion in
                WritingTextHighlight(
                    range: findTextRange(for: suggestion.issue),
                    color: suggestion.category.color,
                    suggestion: suggestion
                )
            }

        } catch {
            self.error = "分析失敗，請重試"
        }

        isAnalyzing = false
    }

    func applySuggestion(_ suggestion: WritingSuggestion) {
        // 在文本中找到並替換
        if let range = findTextRange(for: suggestion.issue) {
            let nsRange = NSRange(range, in: text)
            attributedText.replaceCharacters(in: nsRange, with: suggestion.suggestion)
            text = attributedText.string
        }

        // 移除已應用的建議
        suggestions.removeAll { $0.id == suggestion.id }
        highlights.removeAll { $0.suggestion.id == suggestion.id }
    }

    func dismissSuggestion(_ suggestion: WritingSuggestion) {
        suggestions.removeAll { $0.id == suggestion.id }
        highlights.removeAll { $0.suggestion.id == suggestion.id }
    }

    func applyAllSuggestions() {
        let suggestionsToApply = suggestions
        for suggestion in suggestionsToApply {
            applySuggestion(suggestion)
        }
    }

    func clearSuggestions() {
        suggestions = []
        highlights = []
        error = nil
    }

    // MARK: - Formatting Methods

    func applyFormatting(to range: NSRange, attributes: [NSAttributedString.Key: Any]) {
        attributedText.addAttributes(attributes, range: range)
    }

    func toggleBold(for range: NSRange) {
        guard range.length > 0 else { return }

        let currentFont = attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
            ?? NSFont.systemFont(ofSize: selectedFontSize)

        let isBold = currentFont.fontDescriptor.symbolicTraits.contains(.bold)
        let newFont: NSFont

        if isBold {
            newFont = NSFont.systemFont(ofSize: currentFont.pointSize, weight: .regular)
        } else {
            newFont = NSFont.systemFont(ofSize: currentFont.pointSize, weight: .bold)
        }

        attributedText.addAttribute(.font, value: newFont, range: range)
    }

    func toggleItalic(for range: NSRange) {
        guard range.length > 0 else { return }

        let currentFont = attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
            ?? NSFont.systemFont(ofSize: selectedFontSize)

        let isItalic = currentFont.fontDescriptor.symbolicTraits.contains(.italic)
        let newFont: NSFont

        if isItalic {
            newFont = NSFont.systemFont(ofSize: currentFont.pointSize)
        } else {
            // Create italic font
            let descriptor = currentFont.fontDescriptor.withSymbolicTraits(.italic)
            newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) ?? currentFont
        }

        attributedText.addAttribute(.font, value: newFont, range: range)
    }

    func toggleUnderline(for range: NSRange) {
        guard range.length > 0 else { return }

        let hasUnderline = attributedText.attribute(.underlineStyle, at: range.location, effectiveRange: nil) != nil

        if hasUnderline {
            attributedText.removeAttribute(.underlineStyle, range: range)
        } else {
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    func toggleStrikethrough(for range: NSRange) {
        guard range.length > 0 else { return }

        let hasStrikethrough = attributedText.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) != nil

        if hasStrikethrough {
            attributedText.removeAttribute(.strikethroughStyle, range: range)
        } else {
            attributedText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    func applyHighlight(_ color: NSColor, for range: NSRange) {
        guard range.length > 0 else { return }
        attributedText.addAttribute(.backgroundColor, value: color, range: range)
    }

    func removeHighlight(for range: NSRange) {
        guard range.length > 0 else { return }
        attributedText.removeAttribute(.backgroundColor, range: range)
    }

    func applyBulletList(for range: NSRange) {
        guard range.length > 0, range.location < attributedText.length else { return }

        let text = attributedText.string as NSString
        let paragraphRange = text.paragraphRange(for: range)
        let paragraphText = text.substring(with: paragraphRange)

        // 如果已經有項目符號，移除它
        if paragraphText.hasPrefix("•\t") {
            attributedText.replaceCharacters(in: NSRange(location: paragraphRange.location, length: 2), with: "")
        } else {
            // 插入項目符號
            let bullet = NSAttributedString(string: "•\t")
            attributedText.insert(bullet, at: paragraphRange.location)

            // 設定段落樣式
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20, options: [:])]
            paragraphStyle.lineSpacing = lineSpacing

            let newRange = NSRange(location: paragraphRange.location, length: paragraphRange.length + 2)
            if newRange.upperBound <= attributedText.length {
                attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: newRange)
            }
        }

        self.text = attributedText.string
    }

    func applyNumberedList(for range: NSRange) {
        guard range.length > 0, range.location < attributedText.length else { return }

        let text = attributedText.string as NSString
        let paragraphRange = text.paragraphRange(for: range)
        let paragraphText = text.substring(with: paragraphRange)

        // 如果已經有編號，移除它
        let numberPattern = #"^\d+\.\t"#
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           regex.firstMatch(in: paragraphText, range: NSRange(location: 0, length: min(5, paragraphText.count))) != nil {
            if let match = regex.firstMatch(in: paragraphText, range: NSRange(location: 0, length: min(5, paragraphText.count))) {
                attributedText.replaceCharacters(in: NSRange(location: paragraphRange.location, length: match.range.length), with: "")
            }
        } else {
            // 插入編號
            let number = NSAttributedString(string: "1.\t")
            attributedText.insert(number, at: paragraphRange.location)

            // 設定段落樣式
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20, options: [:])]
            paragraphStyle.lineSpacing = lineSpacing

            let newRange = NSRange(location: paragraphRange.location, length: paragraphRange.length + 3)
            if newRange.upperBound <= attributedText.length {
                attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: newRange)
            }
        }

        self.text = attributedText.string
    }

    func increaseIndent(for range: NSRange) {
        guard range.location < attributedText.length else { return }

        let text = attributedText.string as NSString
        let paragraphRange = text.paragraphRange(for: range)

        // 取得當前段落樣式
        var currentStyle = attributedText.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
        let mutableStyle = (currentStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()

        // 增加首行和整段縮排
        mutableStyle.firstLineHeadIndent += 20
        mutableStyle.headIndent += 20
        mutableStyle.lineSpacing = lineSpacing

        attributedText.addAttribute(.paragraphStyle, value: mutableStyle, range: paragraphRange)
    }

    func decreaseIndent(for range: NSRange) {
        guard range.location < attributedText.length else { return }

        let text = attributedText.string as NSString
        let paragraphRange = text.paragraphRange(for: range)

        // 取得當前段落樣式
        var currentStyle = attributedText.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
        let mutableStyle = (currentStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()

        // 減少首行和整段縮排（最小為 0）
        mutableStyle.firstLineHeadIndent = max(0, mutableStyle.firstLineHeadIndent - 20)
        mutableStyle.headIndent = max(0, mutableStyle.headIndent - 20)
        mutableStyle.lineSpacing = lineSpacing

        attributedText.addAttribute(.paragraphStyle, value: mutableStyle, range: paragraphRange)
    }

    // MARK: - Private Helper Methods

    private func findTextRange(for searchText: String) -> Range<String.Index>? {
        return text.range(of: searchText)
    }

    private func generateMockSuggestions() -> [WritingSuggestion] {
        var mockSuggestions: [WritingSuggestion] = []

        // 語法錯誤示例
        if text.contains("is") {
            mockSuggestions.append(WritingSuggestion(
                category: .grammar,
                issue: "is",
                suggestion: "are",
                explanation: "主詞與動詞的一致性：複數主詞應使用複數動詞",
                position: 0
            ))
        }

        // 拼寫錯誤示例
        if text.contains("teh") {
            mockSuggestions.append(WritingSuggestion(
                category: .spelling,
                issue: "teh",
                suggestion: "the",
                explanation: "拼寫錯誤：應為 'the'",
                position: 0
            ))
        }

        // 風格建議示例
        if text.contains("very") {
            mockSuggestions.append(WritingSuggestion(
                category: .style,
                issue: "very",
                suggestion: "extremely",
                explanation: "使用更具體的副詞可以增強表達力",
                position: 0
            ))
        }

        // 清晰度建議示例
        if text.contains("make sure") {
            mockSuggestions.append(WritingSuggestion(
                category: .clarity,
                issue: "make sure",
                suggestion: "ensure",
                explanation: "使用更正式的詞彙提高專業性",
                position: 0
            ))
        }

        return mockSuggestions
    }
}

// MARK: - Models
// 數據模型已移至 WritingModels.swift
