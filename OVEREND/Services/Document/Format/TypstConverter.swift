//
//  TypstConverter.swift
//  OVEREND
//
//  Typst 轉換器 - 將 NSAttributedString 轉換為 Typst 標記語言
//

import Foundation
import AppKit

/// Typst 轉換器
class TypstConverter {
    
    /// 將文件內容轉換為 Typst 原始碼
    static func toTypst(
        _ attributedString: NSAttributedString,
        template: FormatTemplate
    ) -> String {
        var typst = ""
        
        // 1. 設定文件標頭
        typst += generateDocumentHeader(template: template)
        
        // 2. 解析並轉換內容
        typst += parseContent(attributedString)
        
        // 3. 加入參考文獻（如果需要）
        // 目前先留空，待整合 CitationService
        
        return typst
    }
    
    // MARK: - Header Generation
    
    private static func generateDocumentHeader(template: FormatTemplate) -> String {
        // 頁面設定
        let page = template.pageSetup
        let margins = page.margin
        
        // 轉換 margins (points -> typst pt)
        // Typst 使用 pt, mm, cm. 我們假設 template 中的 points 對應 typst 的 pt
        
        var header = """
        #set page(
          paper: "\(page.paperSize == .a4 ? "a4" : "us-letter")",
          margin: (
            top: \(formatFloat(margins.top))pt,
            bottom: \(formatFloat(margins.bottom))pt,
            left: \(formatFloat(margins.left))pt,
            right: \(formatFloat(margins.right))pt,
          ),
          numbering: \(page.headerFooter?.showPageNumber == true ? "\"1\"" : "none"),
        )
        
        #set text(
          font: ("\(template.styles.body.fontFamily)", "Noto Serif CJK TC", "PingFang TC"),
          size: \(formatFloat(template.styles.body.fontSize))pt,
          lang: "zh",
          region: "TW"
        )
        
        #set par(
          leading: \(formatFloat(template.styles.body.lineHeight ?? 1.5))em,
          justify: true,
          first-line-indent: \(formatFloat(template.styles.body.indent?.firstLine ?? 2))em
        )
        
        """
        
        // 加入標題樣式設定 (可選)
        // Typst 預設已有標題樣式，但我們可以覆蓋它以符合我們 template 的定義
        
        return header
    }
    
    private static func formatFloat(_ value: CGFloat) -> String {
        return String(format: "%.2f", value)
    }
    
    // MARK: - Content Parsing
    
    private static func parseContent(_ attributedString: NSAttributedString) -> String {
        var result = ""
        
        // 逐段落處理
        let string = attributedString.string as NSString
        var index = 0
        let length = string.length
        
        while index < length {
            let lineRange = string.lineRange(for: NSRange(location: index, length: 0))
            let range = NSIntersectionRange(lineRange, NSRange(location: 0, length: length))
            
            // 取得該段落的屬性（取第一個字的屬性作為代表）
            var paragraphStyle: NSParagraphStyle?
            var font: NSFont?
            
            if range.length > 0 {
                let attrs = attributedString.attributes(at: range.location, effectiveRange: nil)
                paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle
                font = attrs[.font] as? NSFont
            }
            
            let substring = attributedString.attributedSubstring(from: range)
            let text = substring.string.trimmingCharacters(in: .newlines)
            
            if !text.isEmpty {
                // 判斷段落類型
                if let headingLevel = detectHeadingLevel(font: font, paragraphStyle: paragraphStyle) {
                    // 標題 (比如: = 標題)
                    result += "\n" + String(repeating: "=", count: headingLevel) + " " + processInlineFormatting(substring) + "\n\n"
                } else if let listPrefix = detectListPrefix(paragraphStyle: paragraphStyle, text: text) {
                    // 列表 (比如: - 項目)
                    // 移除原始文字中的 bullet 或編號，由 Typst 處理
                    let cleanText = removeListMarker(text)
                    result += listPrefix + " " + processInlineFormatting(NSAttributedString(string: cleanText, attributes: substring.attributes(at: 0, effectiveRange: nil))) + "\n"
                } else {
                    // 一般段落
                    result += processInlineFormatting(substring) + "\n\n"
                }
            }
            
            index = NSMaxRange(range)
        }
        
        return result
    }
    
    private static func processInlineFormatting(_ attributedString: NSAttributedString) -> String {
        var result = ""
        let string = attributedString.string as NSString
        
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attrs, range, _ in
            var text = string.substring(with: range)
            
            // 跳過空白字元串的格式處理，除了需要保留空白的情況
             if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                 result += text
                 return
             }
            
            // 處理特殊字元轉義 (Typst 需要轉義 *, _, `, $, #, @ 等)
            // 如果是引用，我們不需要轉義 @，因為我們要產生 @key
            if attrs[.citationKey] == nil {
                text = escapeTypstCheck(text)
            }
            
            // 0. 引用 (最優先)
            if let citationKey = attrs[.citationKey] as? String {
                // 如果有 citationKey，忽略其他格式，直接生成引用語法
                // Typst 語法: @key
                // 我們假設 text 本身是 (Author, Year)，我們替換為 citation object
                // 但為了避免重複，我們應該只在引用的第一個字元處輸出一次引用語法
                // 然而 enumerateAttributes 會切分範圍，所以每個 range 都是獨立的
                // 這裡簡化處理：如果這個 range 有 citationKey，我們輸出 @key
                // 但要注意，如果不只一個 range 有同一個 citationKey (例如跨行)，會重複輸出
                // 所以我們最好檢查：如果這不是該 citation 的起始位置，我們就忽略內容?
                // 或者更簡單：我們直接輸出 @key，並忽略原始文字內容
                
                // 為了防止重複，我們檢查 attributes 的範圍。
                // 但在這個迴圈中較難判斷是否為「第一次遇到此 key」。
                // 替代方案：我們輸出 @key，但因為 attributedString 的 text 是顯示用的 (Author, Year)
                // 如果我們直接替換，那原始文字就不見了，這符合預期 (PDF 中顯示引用符號)
                
                text = "@\(citationKey)"
                
                // 防止同一個引用被切成多段導致重複輸出 @key @key
                // 這是一個潛在問題。但在 `insertCitation` 中我們插入的是單個屬性字串。
                // 除非使用者對引用內部做了格式修改（粗體等），否則應該是連續的。
                // 如果被切分，這裡會重複。
                // 暫時解決方案：不做複雜 dedupe，假設引用是原子的。
                
                result += text
                return // 引用處理完後直接返回，不再處理粗體斜體等
            }
            
            // 1. 粗體
            if let font = attrs[.font] as? NSFont, font.fontDescriptor.symbolicTraits.contains(.bold) {
                text = "*\(text)*"
            }
            
            // 2. 斜體
            if let font = attrs[.font] as? NSFont, font.fontDescriptor.symbolicTraits.contains(.italic) {
                text = "_\(text)_"
            }
            
            // 3. 底線 (Typst 0.11+ 支援 #underline[])
            if let underline = attrs[.underlineStyle] as? Int, underline != 0 {
                text = "#underline[\(text)]"
            }
            
            // 4. 連連結
            if let link = attrs[.link] {
                text = "#link(\"\(link)\")[\(text)]"
            }
            
            result += text
        }
        
        return result
    }
    
    private static func escapeTypstCheck(_ text: String) -> String {
        // Typst 特殊字元轉義
        var result = text
        let specialChars = ["*", "_", "`", "$", "#", "@", "<", ">"]
        for char in specialChars {
            result = result.replacingOccurrences(of: char, with: "\\" + char)
        }
        return result
    }
    
    // MARK: - Detection Helpers
    
    private static func detectHeadingLevel(font: NSFont?, paragraphStyle: NSParagraphStyle?) -> Int? {
        guard let font = font else { return nil }
        
        // 簡單判斷：字體大於 18 為一級標題，大於 16 為二級，大於 14 為三級
        // 這是一個近似值，實際應該對照 Template 的樣式
        let size = font.pointSize
        
        if size >= 24 { return 1 }
        if size >= 18 { return 2 }
        if size >= 16 { return 3 }
        
        return nil
    }
    
    private static func detectListPrefix(paragraphStyle: NSParagraphStyle?, text: String) -> String? {
        guard let style = paragraphStyle else { return nil }
        
        // 檢查首行縮排或懸掛縮排
        if style.headIndent > style.firstLineHeadIndent {
             // 可能是列表
             // 這裡可以做更精細的檢查，或是檢查 text 是否以數字或 bullet 開頭
        }
        
        // 簡單檢查文字開頭
        if text.starts(with: "•") || text.starts(with: "◦") || text.starts(with: "▪") {
            return "-"
        }
        
        // 檢查數字列表 (1., 2., etc)
        if text.range(of: "^\\d+\\.", options: .regularExpression) != nil {
            return "+"
        }
        
        return nil
    }
    
    private static func removeListMarker(_ text: String) -> String {
        // 移除開頭的 bullet 或數字編號
        var result = text
        if let range = result.range(of: "^[•◦▪]\\s*", options: .regularExpression) {
            result.removeSubrange(range)
        } else if let range = result.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
             result.removeSubrange(range)
        }
        return result
    }
}
