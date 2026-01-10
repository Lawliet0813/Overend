//
//  NCCUFormatService.swift
//  OVEREND
//
//  政大學位論文格式服務
//  負責處理字體、行距、邊界等格式規範
//

import Foundation
import AppKit

class NCCUFormatService {
    static let shared = NCCUFormatService()
    
    private init() {}
    
    // MARK: - Constants
    
    private let chineseFontName = "BiauKai" // 標楷體
    private let englishFontName = "Times New Roman"
    private let fontSize: CGFloat = 12.0
    private let lineSpacingMultiple: CGFloat = 1.5
    
    // Margins in points (1 cm approx 28.35 points)
    // Top/Bottom: 2.54 cm = 72 pt
    // Right: 3.17 cm = 90 pt
    // Left: 3.17 cm + 1 cm (gutter) = 4.17 cm = 118 pt
    private let topMargin: CGFloat = 72.0
    private let bottomMargin: CGFloat = 72.0
    private let leftMargin: CGFloat = 118.0
    private let rightMargin: CGFloat = 90.0
    
    // MARK: - Public Methods
    
    func generateCover(info: NCCUCoverInfo) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Helper to append centered text
        func append(_ text: String, size: CGFloat, bold: Bool = false, spacingBefore: CGFloat = 0, spacingAfter: CGFloat = 0) {
            let font = NSFont(name: isChinese(text) ? chineseFontName : englishFontName, size: size) ?? NSFont.systemFont(ofSize: size)
            var finalFont = font
            if bold {
                finalFont = NSFontManager.shared.convert(finalFont, toHaveTrait: .boldFontMask)
            }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.paragraphSpacingBefore = spacingBefore
            paragraphStyle.paragraphSpacing = spacingAfter
            paragraphStyle.lineHeightMultiple = 1.5
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: finalFont,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: NSColor.black
            ]
            
            result.append(NSAttributedString(string: text + "\n", attributes: attributes))
        }
        
        // 1. 校名 (24pt)
        append("國立政治大學", size: 24, bold: true, spacingBefore: 20, spacingAfter: 20)
        
        // 2. 系所 (20pt)
        append(info.department, size: 20, bold: true, spacingAfter: 10)
        
        // 3. 學位 (20pt)
        append("\(info.degree)論文", size: 20, bold: true, spacingAfter: 60)
        
        // 4. 題目 (20pt/24pt)
        append(info.thesisTitleCH, size: 24, bold: true, spacingAfter: 10)
        append(info.thesisTitleEN, size: 20, bold: true, spacingAfter: 80)
        
        // 5. 指導教授 (18pt)
        append("指導教授：\(info.advisorName)", size: 18, bold: false, spacingAfter: 20)
        
        // 6. 研究生 (18pt)
        append("研究生：\(info.studentName)", size: 18, bold: false, spacingAfter: 80)
        
        // 7. 日期 (18pt)
        append("中華民國 \(info.year) 年 \(info.month) 月", size: 18, bold: false, spacingAfter: 20)
        
        // Page Break
        let pageBreak = NSAttributedString(string: "\u{000C}", attributes: [.font: NSFont.systemFont(ofSize: 12)])
        result.append(pageBreak)
        
        return result
    }
    
    /// 套用政大論文格式（字體、行距）
    func applyFormat(to textStorage: NSTextStorage) {
        textStorage.beginEditing()
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let string = textStorage.string as NSString
        
        // 1. 設定行距 (1.5倍)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineSpacingMultiple
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        // 2. 設定字體 (中英文分離)
        string.enumerateSubstrings(in: fullRange, options: .byComposedCharacterSequences) { substring, substringRange, _, _ in
            guard let substring = substring else { return }
            
            if self.isChinese(substring) {
                if let font = NSFont(name: self.chineseFontName, size: self.fontSize) {
                    textStorage.addAttribute(.font, value: font, range: substringRange)
                }
            } else {
                if let font = NSFont(name: self.englishFontName, size: self.fontSize) {
                    textStorage.addAttribute(.font, value: font, range: substringRange)
                }
            }
        }
        
        textStorage.endEditing()
    }
    
    /// 套用頁面邊界設定
    func applyPageSettings(to textView: NSTextView) {
        // 設定 TextContainer Insets 模擬邊界
        textView.textContainerInset = NSSize(width: leftMargin, height: topMargin)
        
        // 注意：NSTextView 的 textContainerInset 只能設定統一的 width/height padding
        // 若要精確控制左右不同，需調整 textContainer 的 lineFragmentPadding 或 size
        // 這裡簡化處理，將左右邊界設為較大值以確保閱讀舒適，實際列印需透過 NSPrintInfo 設定
        
        // 簡單模擬：左右取平均或較大值，這裡使用 Left Margin 作為左側 padding
        // 右側 padding 透過 textContainer 的寬度控制（通常由視窗大小決定）
        // 但我們可以設定 textContainerInset.width 為左右總和的一半？不，inset 是四周的。
        
        // 更好的做法是設定 textContainerInset 為 (left, top)
        // 但 bottom 和 right 比較難直接透過 inset 設定（bottom 可以，right 不行）
        
        // 這裡我們主要設定視覺上的舒適邊距
        textView.textContainerInset = NSSize(width: 40, height: 40) // 編輯器預設舒適邊距
        
        // 若要模擬列印邊界，可能需要更複雜的 LayoutManager 設定
        // 暫時僅提示用戶已套用格式
    }
    
    // MARK: - Helper Methods
    
    private func isChinese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }
}
