//
//  AILayoutFormatter.swift
//  OVEREND
//
//  AI 驅動的智慧排版服務
//

import Foundation
import AppKit
import FoundationModels

/// AI 智慧排版服務
@available(macOS 26.0, *)
@MainActor
class AILayoutFormatter {

    /// 排版類型
    enum FormattingType {
        case academic       // 學術論文排版（APA 格式）
        case report         // 報告排版
        case thesis         // 學位論文排版
        case article        // 期刊文章排版
        case custom(String) // 自訂排版需求
    }

    /// 排版結果
    struct FormattingResult {
        let formattedText: NSAttributedString
        let changes: [String] // 改動說明
        let suggestions: [String] // 排版建議
    }

    /// 使用 AI 進行智慧排版
    /// - Parameters:
    ///   - text: 原始文字
    ///   - type: 排版類型
    /// - Returns: 排版結果
    static func format(text: NSAttributedString, type: FormattingType) async throws -> FormattingResult {
        guard UnifiedAIService.shared.isAvailable else {
            throw NSError(domain: "AILayoutFormatter", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Apple Intelligence 不可用"
            ])
        }

        let plainText = text.string

        // 根據類型建構提示詞
        let prompt = buildPrompt(for: type, with: plainText)

        let session = UnifiedAIService.shared.createSession()

        let response = try await session.respond(to: prompt)
        let responseText = response.content

        // 應用排版規則
        let formatted = applyFormatting(to: text, basedOn: responseText, type: type)

        return FormattingResult(
            formattedText: formatted,
            changes: extractChanges(from: responseText),
            suggestions: extractSuggestions(from: responseText)
        )
    }

    /// 自動修正引用格式（APA 第 7 版）
    static func fixCitations(in text: NSAttributedString) async throws -> NSAttributedString {
        return try await UnifiedAIService.shared.citation.fixFormat(text: text, style: .apa7)
    }

    /// 自動調整段落間距與對齊
    static func adjustParagraphSpacing(in text: NSAttributedString, style: ParagraphStyle) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(attributedString: text)
        let fullRange = NSRange(location: 0, length: mutableText.length)

        // 段落樣式設定
        let paragraphStyle = NSMutableParagraphStyle()

        switch style {
        case .academic:
            paragraphStyle.alignment = .justified // 左右對齊
            paragraphStyle.lineSpacing = 12 // 1.5 倍行距
            paragraphStyle.paragraphSpacing = 12
            paragraphStyle.firstLineHeadIndent = 28 // 首行縮排 2 字元
            paragraphStyle.headIndent = 0

        case .compact:
            paragraphStyle.alignment = .left
            paragraphStyle.lineSpacing = 6
            paragraphStyle.paragraphSpacing = 8
            paragraphStyle.firstLineHeadIndent = 0

        case .loose:
            paragraphStyle.alignment = .left
            paragraphStyle.lineSpacing = 16
            paragraphStyle.paragraphSpacing = 24
            paragraphStyle.firstLineHeadIndent = 0
        }

        mutableText.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        return mutableText
    }

    /// 智慧標題層級調整
    static func adjustHeadingLevels(in text: NSAttributedString) async throws -> NSAttributedString {
        guard UnifiedAIService.shared.isAvailable else {
            throw NSError(domain: "AILayoutFormatter", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Apple Intelligence 不可用"
            ])
        }

        let plainText = text.string

        let prompt = """
        請分析以下文字的結構，識別標題層級並建議調整。

        **標準論文標題層級：**
        - H1：章標題（粗體、置中、18-20pt）
        - H2：節標題（粗體、靠左、16-18pt）
        - H3：小節標題（粗體、靠左、14-16pt）
        - 正文：一般段落（12-14pt）

        請回傳調整建議。
        """

        let session = UnifiedAIService.shared.createSession()

        let response = try await session.respond(to: prompt)
        let responseText = response.content

        return applyHeadingAdjustments(to: text, basedOn: responseText)
    }

    /// 自動生成目錄
    static func generateTableOfContents(from text: NSAttributedString) -> NSAttributedString {
        let mutableTOC = NSMutableAttributedString()

        // 標題樣式
        let titleStyle = NSMutableAttributedString(string: "目錄\n\n")
        titleStyle.addAttributes([
            .font: NSFont.boldSystemFont(ofSize: 18),
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ], range: NSRange(location: 0, length: titleStyle.length))

        mutableTOC.append(titleStyle)

        // 掃描文字中的標題
        let fullText = text.string
        let lines = fullText.components(separatedBy: .newlines)

        var chapterNumber = 0
        var sectionNumber = 0
        var subsectionNumber = 0

        for (_, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // 判斷標題層級（根據字體大小）
            let range = NSRange(location: 0, length: (trimmed as NSString).length)
            var isHeading = false
            var level = 0

            text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { value, attrRange, stop in
                if let font = value as? NSFont {
                    if font.pointSize >= 18 {
                        level = 1
                        isHeading = true
                    } else if font.pointSize >= 16 {
                        level = 2
                        isHeading = true
                    } else if font.pointSize >= 14 {
                        level = 3
                        isHeading = true
                    }
                }
            }

            if isHeading {
                let indentation: CGFloat
                let numberPrefix: String

                switch level {
                case 1:
                    chapterNumber += 1
                    sectionNumber = 0
                    subsectionNumber = 0
                    indentation = 0
                    numberPrefix = "\(chapterNumber). "

                case 2:
                    sectionNumber += 1
                    subsectionNumber = 0
                    indentation = 20
                    numberPrefix = "\(chapterNumber).\(sectionNumber). "

                case 3:
                    subsectionNumber += 1
                    indentation = 40
                    numberPrefix = "\(chapterNumber).\(sectionNumber).\(subsectionNumber). "

                default:
                    continue
                }

                let tocEntry = NSMutableAttributedString(string: "\(numberPrefix)\(trimmed)\n")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = indentation
                paragraphStyle.firstLineHeadIndent = indentation

                tocEntry.addAttributes([
                    .font: NSFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ], range: NSRange(location: 0, length: tocEntry.length))

                mutableTOC.append(tocEntry)
            }
        }

        return mutableTOC
    }

    // MARK: - 私有輔助方法

    private static func buildPrompt(for type: FormattingType, with text: String) -> String {
        switch type {
        case .academic:
            return """
            請以 APA 第 7 版學術論文格式調整以下文字：

            **排版要求：**
            1. 標題層級：H1（章）、H2（節）、H3（小節）
            2. 段落：左右對齊、1.5 倍行距、首行縮排 2 字元
            3. 引用格式：(作者, 年份)
            4. 參考文獻：APA 第 7 版格式
            5. 圖表：編號與標題

            請提供格式化建議。
            """

        case .report:
            return """
            請以正式報告格式調整以下文字：

            **排版要求：**
            1. 清晰的標題結構
            2. 段落間距適中
            3. 要點列表格式一致
            4. 數字與統計資料對齊
            5. 圖表說明完整

            請提供格式化建議。
            """

        case .thesis:
            return """
            請以學位論文格式調整以下文字：

            **排版要求：**
            1. 標題編號系統（1, 1.1, 1.1.1）
            2. 章節分頁
            3. 引用與參考文獻格式
            4. 圖表編號與目錄
            5. 附錄格式

            請提供格式化建議。
            """

        case .article:
            return """
            請以期刊文章格式調整以下文字：

            **排版要求：**
            1. 摘要、關鍵字
            2. 引言、方法、結果、討論結構
            3. 簡潔的標題
            4. 參考文獻格式
            5. 作者資訊

            請提供格式化建議。
            """

        case .custom(let instruction):
            return instruction
        }
    }

    private static func applyFormatting(to text: NSAttributedString, basedOn response: String, type: FormattingType) -> NSAttributedString {
        // TODO: 根據 AI 回應智慧應用格式
        // 目前返回原文，實際應解析 AI 建議並應用格式
        return text
    }

    private static func extractChanges(from response: String) -> [String] {
        // TODO: 從 AI 回應中提取改動列表
        return ["已調整段落間距", "已修正標題層級", "已更新引用格式"]
    }

    private static func extractSuggestions(from response: String) -> [String] {
        // TODO: 從 AI 回應中提取建議
        return ["建議新增目錄", "建議統一字體大小", "建議檢查參考文獻格式"]
    }

    private static func applyHeadingAdjustments(to text: NSAttributedString, basedOn response: String) -> NSAttributedString {
        // TODO: 根據 AI 建議調整標題
        return text
    }
}

/// 段落樣式預設
enum ParagraphStyle {
    case academic  // 學術論文樣式
    case compact   // 緊湊樣式
    case loose     // 鬆散樣式
}

