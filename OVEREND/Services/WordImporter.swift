//
//  WordImporter.swift
//  OVEREND
//
//  Word 文件匯入器
//

import Foundation
import AppKit

/// Word 文件匯入器
class WordImporter {
    
    enum ImportError: Error {
        case fileReadFailed
        case conversionFailed
        case unsupportedFormat
        
        var localizedDescription: String {
            switch self {
            case .fileReadFailed:
                return "無法讀取檔案"
            case .conversionFailed:
                return "格式轉換失敗"
            case .unsupportedFormat:
                return "不支援的檔案格式"
            }
        }
    }
    
    /// 匯入 Word 文件
    static func `import`(
        from url: URL,
        template: FormatTemplate
    ) throws -> NSAttributedString {
        // 1. 檢查檔案格式
        let ext = url.pathExtension.lowercased()
        guard ext == "docx" || ext == "doc" else {
            throw ImportError.unsupportedFormat
        }
        
        // 2. 讀取檔案
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.fileReadFailed
        }
        
        // 3. 轉換成 NSAttributedString（macOS 內建功能）
        // 注意：macOS 使用 .officeOpenXML 來讀取 .docx 文件
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.officeOpenXML
        ]
        
        do {
            let wordContent = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            // 4. 清理 Word 格式
            let cleanedContent = cleanWordFormatting(wordContent)
            
            // 5. 套用範本樣式
            let styledContent = DocumentFormatter.fromHTML(
                convertToHTML(cleanedContent),
                template: template
            )
            
            return styledContent
            
        } catch {
            throw ImportError.conversionFailed
        }
    }
    
    /// 清理 Word 格式（移除多餘樣式）
    private static func cleanWordFormatting(_ attributedString: NSAttributedString) -> NSAttributedString {
        let mutableAttr = NSMutableAttributedString(attributedString: attributedString)
        let length = mutableAttr.length
        
        // 移除 Word 特有的屬性
        let attributesToRemove: [NSAttributedString.Key] = [
            .link,
            .attachment,
            .shadow,
            .ligature,
            .kern,
            .tracking,
            .writingDirection
        ]
        
        for attr in attributesToRemove {
            mutableAttr.removeAttribute(attr, range: NSRange(location: 0, length: length))
        }
        
        // 只保留基本格式屬性
        return mutableAttr
    }
    
    /// 轉換成簡化的 HTML（保留語意標記）
    private static func convertToHTML(_ attributedString: NSAttributedString) -> String {
        var html = ""
        let string = attributedString.string
        let length = attributedString.length
        
        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: length),
            options: []
        ) { attributes, range, _ in
            let substring = (string as NSString).substring(with: range)
            
            // 判斷格式
            var content = substring
            
            if let font = attributes[.font] as? NSFont {
                let fontSize = font.pointSize
                let traits = font.fontDescriptor.symbolicTraits
                
                // 根據大小判斷標題
                if fontSize >= 18 {
                    html += "<h1>\(content)</h1>\n"
                } else if fontSize >= 16 {
                    html += "<h2>\(content)</h2>\n"
                } else if fontSize >= 14 && traits.contains(.bold) {
                    html += "<h3>\(content)</h3>\n"
                } else {
                    // 一般段落
                    if traits.contains(.bold) {
                        content = "<strong>\(content)</strong>"
                    }
                    if traits.contains(.italic) {
                        content = "<em>\(content)</em>"
                    }
                    html += "<p>\(content)</p>\n"
                }
            } else {
                html += "<p>\(content)</p>\n"
            }
        }
        
        return html
    }
}
