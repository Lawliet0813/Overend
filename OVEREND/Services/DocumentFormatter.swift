//
//  DocumentFormatter.swift
//  OVEREND
//
//  文件格式轉換器 - NSAttributedString ↔ HTML
//

import Foundation
import AppKit

/// 文件格式轉換器
class DocumentFormatter {
    
    // MARK: - NSAttributedString → HTML
    
    /// 將 NSAttributedString 轉換成語意化 HTML
    static func toHTML(
        _ attributedString: NSAttributedString,
        template: FormatTemplate
    ) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="zh-TW">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Document</title>
            <style>
            \(generateCSS(from: template))
            </style>
        </head>
        <body>
        """
        
        // 解析 NSAttributedString 轉換成 HTML 元素
        let content = parseAttributedString(attributedString, template: template)
        html += content
        
        html += """
        </body>
        </html>
        """
        
        return html
    }
    
    // MARK: - HTML → NSAttributedString
    
    /// 從 HTML 載入成 NSAttributedString
    static func fromHTML(
        _ html: String,
        template: FormatTemplate
    ) -> NSAttributedString {
        guard let data = html.data(using: .utf8) else {
            return NSAttributedString()
        }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            // 套用範本樣式
            return applyTemplateStyles(attributedString, template: template)
            
        } catch {
            print("❌ HTML 轉換失敗：\(error)")
            return NSAttributedString()
        }
    }
}

// MARK: - CSS 生成

extension DocumentFormatter {
    /// 從範本生成 CSS
    static func generateCSS(from template: FormatTemplate) -> String {
        let styles = template.styles
        let pageSetup = template.pageSetup
        
        var css = ""
        
        // 頁面設定
        css += """
        @page {
            size: \(pageSetup.paperSize == .a4 ? "A4" : "Letter");
            margin-top: \(pageSetup.margin.top)pt;
            margin-bottom: \(pageSetup.margin.bottom)pt;
            margin-left: \(pageSetup.margin.left)pt;
            margin-right: \(pageSetup.margin.right)pt;
        }
        
        """
        
        // 雙面印刷的頁邊距
        if pageSetup.duplexPrinting,
           let oddLeft = pageSetup.margin.oddPageLeft,
           let evenRight = pageSetup.margin.evenPageRight {
            css += """
            @page :left {
                margin-right: \(evenRight)pt;
            }
            
            @page :right {
                margin-left: \(oddLeft)pt;
            }
            
            """
        }
        
        // 基本 HTML/body 設定 - 啟用自動分頁
        css += """
        html, body {
            width: 100%;
            height: auto;
            margin: 0;
            padding: 0;
            /* 確保內容可以正常分頁 */
            overflow: visible;
        }
        
        /* 強制分頁符號立即作用 */
        .page-break {
            display: block !important;
            page-break-after: always !important;
            break-after: page !important;
            height: 1px !important;
            margin: 0 !important;
            padding: 0 !important;
            border: none !important;
            background: transparent !important;
        }
        
        /* 空白頁樣式 */
        .blank-page {
            display: block !important;
            page-break-after: always !important;
            break-after: page !important;
            min-height: 100vh !important;
            margin: 0 !important;
            padding: 0 !important;
        }
        
        """
        
        // body 樣式
        css += generateTextStyleCSS("body", styles.body)
        
        // 分頁控制規則
        css += """
        /* 避免段落在頁面中間被切斷 */
        p, blockquote {
            orphans: 3;
            widows: 3;
            page-break-inside: avoid;
        }
        
        /* 章節標題避免在頁底出現後立即換頁 */
        h1, h2, h3, h4, h5, h6 {
            page-break-after: avoid;
            page-break-inside: avoid;
        }
        
        /* 章標題（第一章）在新頁面開始 */
        h1.chapter {
            page-break-before: always;
        }
        
        /* 圖表避免被切斷 */
        figure, table {
            page-break-inside: avoid;
        }
        
        /* 封面頁專用樣式 */
        .cover-page {
            page-break-after: always;
            height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            text-align: center;
        }
        
        .cover-top {
            padding-top: 2cm;
        }
        
        .cover-middle {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        
        .cover-bottom {
            padding-bottom: 2cm;
        }
        
        /* 空白段落 */
        p.spacer {
            margin: 0;
            padding: 0;
            line-height: 1.5;
        }
        
        /* 列印/PDF 匯出樣式 */
        @media print {
            body {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            
            /* 確保分頁符正常運作 */
            .page-break {
                page-break-after: always !important;
                break-after: page !important;
                display: block !important;
            }
            
            div[style*="page-break-after"] {
                page-break-after: always !important;
                break-after: page !important;
                height: 0;
                margin: 0;
                padding: 0;
            }
        }
        
        /* 分頁符樣式（適用於所有模式） */
        .page-break {
            page-break-after: always;
            break-after: page;
            display: block;
            height: 0;
            margin: 0;
            padding: 0;
            border: none;
            visibility: hidden;
        }
        
        """
        
        // 標題樣式
        css += generateTextStyleCSS("h1.chapter", styles.chapter)
        css += generateTextStyleCSS("h2.section", styles.section)
        css += generateTextStyleCSS("h3.subsection1", styles.subsection1)
        css += generateTextStyleCSS("h4.subsection2", styles.subsection2)
        css += generateTextStyleCSS("h5.subsection3", styles.subsection3)
        
        // 區塊引用樣式
        css += generateBlockquoteCSS(styles.blockquote)
        
        // 引用標記樣式
        css += generateTextStyleCSS("span.citation", styles.citation)
        
        // 圖表樣式
        css += generateFigureCSS(styles.figure)
        css += generateTableCSS(styles.table)
        
        // 註腳樣式
        css += generateTextStyleCSS("span.footnote", styles.footnote)
        
        // 參考文獻樣式
        css += generateTextStyleCSS("p.bibliography", styles.bibliography)
        
        return css
    }
    
    /// 生成文字樣式 CSS
    private static func generateTextStyleCSS(
        _ selector: String,
        _ style: FormatTemplate.TextStyle
    ) -> String {
        var rules: [String] = []
        
        rules.append("font-family: \(style.fontFamily), sans-serif")
        rules.append("font-size: \(style.fontSize)pt")
        
        if let weight = style.fontWeight {
            rules.append("font-weight: \(weight.rawValue)")
        }
        
        if let fontStyle = style.fontStyle {
            rules.append("font-style: \(fontStyle.rawValue)")
        }
        
        if let color = style.color {
            rules.append("color: \(color)")
        }
        
        if let alignment = style.alignment {
            rules.append("text-align: \(alignment.rawValue)")
        }
        
        if let lineHeight = style.lineHeight {
            rules.append("line-height: \(lineHeight)")
        }
        
        if let spacing = style.paragraphSpacing {
            rules.append("margin-top: \(spacing.before)em")
            rules.append("margin-bottom: \(spacing.after)em")
        }
        
        if let indent = style.indent {
            if let firstLine = indent.firstLine {
                rules.append("text-indent: \(firstLine)pt")
            }
            if let left = indent.left {
                rules.append("padding-left: \(left)pt")
            }
            if let right = indent.right {
                rules.append("padding-right: \(right)pt")
            }
        }
        
        return "\(selector) {\n    \(rules.joined(separator: ";\n    "));\n}\n\n"
    }
    
    /// 生成引用區塊 CSS
    private static func generateBlockquoteCSS(_ style: FormatTemplate.BlockStyle) -> String {
        var rules: [String] = []
        
        if let fontFamily = style.fontFamily {
            rules.append("font-family: \(fontFamily), sans-serif")
        }
        
        if let fontSize = style.fontSize {
            rules.append("font-size: \(fontSize)pt")
        }
        
        rules.append("margin-left: \(style.marginLeft)pt")
        rules.append("margin-right: \(style.marginRight)pt")
        
        if let marginTop = style.marginTop {
            rules.append("margin-top: \(marginTop)pt")
        }
        
        if let marginBottom = style.marginBottom {
            rules.append("margin-bottom: \(marginBottom)pt")
        }
        
        if let bgColor = style.backgroundColor {
            rules.append("background-color: \(bgColor)")
        }
        
        if let border = style.borderLeft {
            rules.append("border-left: \(border.width)pt solid \(border.color)")
            rules.append("padding-left: 1em")
        }
        
        return "blockquote {\n    \(rules.joined(separator: ";\n    "));\n}\n\n"
    }
    
    /// 生成圖片 CSS
    private static func generateFigureCSS(_ style: FormatTemplate.FigureStyle) -> String {
        var css = """
        figure {
            text-align: \(style.alignment.rawValue);
            margin: 1em 0;
        }
        
        figure img {
            max-width: 100%;
            height: auto;
        }
        
        """
        
        css += generateTextStyleCSS("figure figcaption", style.captionFont)
        
        return css
    }
    
    /// 生成表格 CSS
    private static func generateTableCSS(_ style: FormatTemplate.TableStyle) -> String {
        var css = """
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1em 0;
        }
        
        """
        
        if let borderColor = style.borderColor, let borderWidth = style.borderWidth {
            css += """
            table, th, td {
                border: \(borderWidth)pt solid \(borderColor);
            }
            
            """
        }
        
        css += generateTextStyleCSS("table caption", style.captionFont)
        css += generateTextStyleCSS("table th", style.headerFont)
        css += generateTextStyleCSS("table td", style.bodyFont)
        
        return css
    }
}

// MARK: - HTML 解析

extension DocumentFormatter {
    /// 解析 NSAttributedString 轉換成 HTML 內容
    private static func parseAttributedString(
        _ attributedString: NSAttributedString,
        template: FormatTemplate
    ) -> String {
        // 🔍 Debug: 檢查輸入內容
        print("🔍 parseAttributedString - 原始長度：\(attributedString.length)")
        print("🔍 parseAttributedString - 純文字長度：\(attributedString.string.count)")
        print("🔍 parseAttributedString - 前 200 字元：\(String(attributedString.string.prefix(200)))")

        let string = attributedString.string

        // 檢查是否為空
        if string.isEmpty {
            print("⚠️ parseAttributedString - 內容為空！")
            return "<p>文件內容為空</p>"
        }

        // 將文字按換行符分割成段落
        let paragraphs = string.components(separatedBy: "\n")
        var html = ""
        var currentCharIndex = 0

        print("🔍 parseAttributedString - 段落數：\(paragraphs.count)")

        // 頁面高度追蹤（用於自動分頁）
        // A4 頁面內容高度 ≈ 600pt (扣除頁邊距後，調整為更合理的分頁)
        let pageContentHeight: CGFloat = 600
        var currentPageHeight: CGFloat = 0
        let lineHeight: CGFloat = 24 // 平均行高（中文適用）

        for (index, paragraph) in paragraphs.enumerated() {
            let paragraphLength = paragraph.count

            // 🔍 Debug: 每 10 個段落輸出一次
            if index % 10 == 0 {
                print("🔍 處理段落 \(index)/\(paragraphs.count) - 長度：\(paragraphLength)")
            }

            // 偵測分頁標記（封面結束或手動分頁符）
            // 分頁符格式: ═══════════════ 分頁 ═══════════════
            if paragraph.contains("封面結束") ||
               paragraph.contains("───────") ||
               (paragraph.contains("分頁") && paragraph.contains("═")) {
                // 🔧 加強分頁符 - 使用多重方式確保跨平台相容
                html += """
                <div class="page-break"></div>
                """
                currentCharIndex += paragraphLength + 1  // +1 for newline
                currentPageHeight = 0 // 重置頁面高度
                continue
            }
            
            // 偵測空白頁標記
            // 空白頁格式: ═══════════════ 空白頁 ═══════════════
            if paragraph.contains("空白頁") && paragraph.contains("═") {
                // 🔧 加強空白頁 - 確保完整一頁 + 分頁
                html += """
                <div class="blank-page"></div>
                """
                currentCharIndex += paragraphLength + 1
                currentPageHeight = 0 // 重置頁面高度
                continue
            }

            if paragraphLength == 0 {
                // 空行 = 段落分隔（但不要太多連續空段落）
                html += "<p class=\"spacer\">&nbsp;</p>\n"
                currentCharIndex += 1  // 只有換行符
                currentPageHeight += lineHeight
                continue
            }
            
            // 安全檢查：確保不超過字串長度
            guard currentCharIndex < attributedString.length else {
                // 索引超出範圍，用純文字方式加入
                html += "<p>\(escapeHTML(paragraph))</p>\n"
                currentCharIndex += paragraphLength + 1
                continue
            }

            // 檢查是否有 NSTextAttachment（LaTeX 公式圖片等）
            // 這些不應該直接轉換為文字
            var hasAttachment = false
            attributedString.enumerateAttribute(
                .attachment,
                in: NSRange(location: currentCharIndex, length: min(paragraphLength, attributedString.length - currentCharIndex)),
                options: []
            ) { value, range, stop in
                if value != nil {
                    hasAttachment = true
                    stop.pointee = true
                }
            }

            // 如果段落包含附件，暫時跳過（或用佔位符）
            if hasAttachment {
                print("⚠️ 段落 \(index) 包含附件，使用純文字輸出")
                html += "<p>\(escapeHTML(paragraph))</p>\n"
                currentCharIndex += paragraphLength + 1
                currentPageHeight += lineHeight
                continue
            }

            // 取得這個段落的屬性
            let attributes = attributedString.attributes(at: currentCharIndex, effectiveRange: nil)

            // 計算段落估計高度
            var estimatedHeight = lineHeight
            if let font = attributes[.font] as? NSFont {
                let fontSize = font.pointSize
                // 標題佔用更多空間
                if fontSize >= 20 {
                    estimatedHeight = fontSize * 2.8 // h1 標題（加大間距）
                } else if fontSize >= 18 {
                    estimatedHeight = fontSize * 2.5 // h2 標題（加大間距）
                } else if fontSize >= 16 {
                    estimatedHeight = fontSize * 2.2 // h3 標題（加大間距）
                } else {
                    // 一般段落：根據行數估計（中文每行約 40-45 字）
                    let lineCount = CGFloat(max(1, paragraphLength / 40))
                    estimatedHeight = lineCount * fontSize * 1.6 // 增加行距係數
                }
            }

            // 檢查是否需要自動分頁
            if currentPageHeight + estimatedHeight > pageContentHeight && currentPageHeight > 100 {
                // 插入自動分頁符
                html += """
                <div class="page-break"></div>
                """
                currentPageHeight = 0
            }

            // 添加段落
            html += wrapParagraphWithTag(paragraph, attributes: attributes, template: template)
            currentPageHeight += estimatedHeight

            currentCharIndex += paragraphLength + 1  // +1 跳過換行符
        }

        // 🔍 Debug: 檢查最終 HTML 輸出
        print("🔍 parseAttributedString - 完成！HTML 長度：\(html.count)")
        print("🔍 parseAttributedString - HTML 前 500 字元：\(String(html.prefix(500)))")

        // 如果 HTML 為空，返回錯誤訊息
        if html.isEmpty {
            print("⚠️ parseAttributedString - HTML 為空！返回佔位內容")
            return "<p>無法解析文件內容</p>"
        }

        return html
    }
    
    /// 根據屬性包裝整個段落
    private static func wrapParagraphWithTag(
        _ text: String,
        attributes: [NSAttributedString.Key: Any],
        template: FormatTemplate
    ) -> String {
        guard let font = attributes[.font] as? NSFont else {
            return "<p>\(escapeHTML(text))</p>\n"
        }
        
        let fontSize = font.pointSize
        let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
        let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
        
        var tag = "p"
        var cssClass = ""
        var inlineStyle = ""
        
        // 根據字體大小判斷標題層級
        if fontSize >= 20 {
            tag = "h1"
            cssClass = "chapter"
        } else if fontSize >= 18 {
            tag = "h2"
            cssClass = "section"
        } else if fontSize >= 16 {
            tag = "h3"
            cssClass = "subsection1"
        } else if fontSize >= 14 && isBold {
            tag = "h4"
            cssClass = "subsection2"
        } else if fontSize >= 14 {
            tag = "h5"
            cssClass = "subsection3"
        }
        
        // 處理對齊方式
        if let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle {
            switch paragraph.alignment {
            case .center:
                inlineStyle += "text-align: center;"
            case .right:
                inlineStyle += "text-align: right;"
            case .justified:
                inlineStyle += "text-align: justify;"
            default:
                break
            }
            
            // 處理縮排（引用）
            if paragraph.firstLineHeadIndent > 20 || paragraph.headIndent > 20 {
                return "<blockquote style=\"\(inlineStyle)\">\(escapeHTML(text))</blockquote>\n"
            }
        }
        
        var content = escapeHTML(text)
        
        // 套用粗體、斜體（只對非標題段落）
        if isBold && tag == "p" {
            content = "<strong>\(content)</strong>"
        }
        
        if isItalic {
            content = "<em>\(content)</em>"
        }
        
        // 組合標籤
        var openTag = "<\(tag)"
        if !cssClass.isEmpty {
            openTag += " class=\"\(cssClass)\""
        }
        if !inlineStyle.isEmpty {
            openTag += " style=\"\(inlineStyle)\""
        }
        openTag += ">"
        
        return "\(openTag)\(content)</\(tag)>\n"
    }
    
    /// 根據字體屬性包裝 HTML 標籤
    private static func wrapWithTag(
        _ text: String,
        font: NSFont,
        attributes: [NSAttributedString.Key: Any]
    ) -> String {
        let fontSize = font.pointSize
        let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
        let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
        
        var tag = "p"
        var cssClass = ""
        
        // 根據字體大小判斷標題層級
        if fontSize >= 18 {
            tag = "h1"
            cssClass = "chapter"
        } else if fontSize >= 16 {
            tag = "h2"
            cssClass = "section"
        } else if fontSize >= 14 && isBold {
            tag = "h3"
            cssClass = "subsection1"
        } else if fontSize >= 14 {
            tag = "h4"
            cssClass = "subsection2"
        }
        
        var content = escapeHTML(text)
        
        // 套用粗體、斜體
        if isBold && tag == "p" {
            content = "<strong>\(content)</strong>"
        }
        
        if isItalic {
            content = "<em>\(content)</em>"
        }
        
        // 檢查是否為引用（透過左右縮排判斷）
        if let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle {
            if paragraph.firstLineHeadIndent > 0 || paragraph.headIndent > 0 {
                return "<blockquote>\(content)</blockquote>\n"
            }
        }
        
        if !cssClass.isEmpty {
            return "<\(tag) class=\"\(cssClass)\">\(content)</\(tag)>\n"
        } else {
            return "<\(tag)>\(content)</\(tag)>\n"
        }
    }
    
    /// 轉義 HTML 特殊字元
    private static func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    /// 套用範本樣式到 NSAttributedString
    private static func applyTemplateStyles(
        _ attributedString: NSAttributedString,
        template: FormatTemplate
    ) -> NSAttributedString {
        let mutableAttr = NSMutableAttributedString(attributedString: attributedString)
        let styles = template.styles
        
        let length = mutableAttr.length
        
        mutableAttr.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: length),
            options: []
        ) { value, range, _ in
            guard let font = value as? NSFont else { return }
            
            // 根據字體大小套用對應範本樣式
            let fontSize = font.pointSize
            var newFont: NSFont?
            
            if fontSize >= 18 {
                newFont = getFontFromStyle(styles.chapter)
            } else if fontSize >= 16 {
                newFont = getFontFromStyle(styles.section)
            } else if fontSize >= 14 {
                newFont = getFontFromStyle(styles.subsection1)
            } else {
                newFont = getFontFromStyle(styles.body)
            }
            
            if let newFont = newFont {
                mutableAttr.addAttribute(.font, value: newFont, range: range)
            }
        }
        
        return mutableAttr
    }
    
    /// 從 TextStyle 建立 NSFont
    private static func getFontFromStyle(_ style: FormatTemplate.TextStyle) -> NSFont? {
        var font = NSFont(name: style.fontFamily, size: style.fontSize)
            ?? NSFont.systemFont(ofSize: style.fontSize)
        
        if let weight = style.fontWeight {
            switch weight {
            case .bold, .heavy:
                font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            default:
                break
            }
        }
        
        if let fontStyle = style.fontStyle, fontStyle == .italic {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        
        return font
    }
}
